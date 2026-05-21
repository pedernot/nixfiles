import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";
import { createHash } from "node:crypto";
import { chmod, lstat, mkdir, readFile, realpath, rename, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve } from "node:path";

const LEGACY_WHITELIST_FILE = ".pi/bash-command-whitelist.json";
const WHITELIST_DIR = join(getAgentDir(), "bash-command-guard");
const ALLOW_ONCE = "Allow once";
const ALLOW_ALWAYS = "Allow always...";
const DENY = "Deny";
const GUARDED_BASH_TOOLS = new Set(["bash", "background_bash"]);
const SHELL_META_CHARS = new Set(["|", "&", ";", "(", ")", "<", ">", "`", "$", "\n", "\r"]);
const PATH_FIELD_NAMES = new Set([
	"path",
	"paths",
	"file",
	"files",
	"filepath",
	"filepaths",
	"filename",
	"filenames",
	"target",
	"targetpath",
	"destination",
	"destinationpath",
	"dir",
	"dirs",
	"directory",
	"directories",
	"dirname",
	"dirnames",
	"dst",
	"dstpath",
	"from",
	"output",
	"outputpath",
	"source",
	"sourcepath",
	"sources",
	"src",
	"srcpath",
	"to",
]);
const COMMAND_WRAPPERS = new Set(["builtin", "command", "env", "exec", "nohup", "time"]);
const RISKY_NIX_SUBCOMMANDS = new Set(["build", "develop", "run", "shell"]);
const LOCK_STALE_MS = 60_000;

const SAFE_PERSISTENT_EXECUTABLE_NAMES = new Set([
	"date",
	"echo",
	"false",
	"id",
	"printf",
	"pwd",
	"true",
	"uname",
	"whoami",
]);

const RISKY_EXECUTABLE_NAMES = new Set([
	"awk",
	"bun",
	"code",
	"csh",
	"dash",
	"dd",
	"deno",
	"ed",
	"emacs",
	"ex",
	"docker",
	"fish",
	"find",
	"gh",
	"git",
	"husky",
	"kubectl",
	"ksh",
	"lua",
	"make",
	"nano",
	"mysql",
	"nix-build",
	"nix-instantiate",
	"nix-shell",
	"node",
	"npm",
	"nvim",
	"perl",
	"pnpm",
	"podman",
	"pre-commit",
	"psql",
	"php",
	"python",
	"python2",
	"python3",
	"ruby",
	"sed",
	"sh",
	"ssh",
	"sudo",
	"tee",
	"vi",
	"vim",
	"xargs",
	"yarn",
	"zsh",
]);

type ToolInput = Record<string, unknown>;

type PatternLoadResult = {
	exists: boolean;
	patterns: string[];
	diagnostics: string[];
};

type RepositoryPolicy = {
	root: string;
	configPath: string;
	legacyConfigPath: string;
	patterns: string[];
	diagnostics: string[];
};

function normalizeCommand(command: string): string {
	return command.trim();
}

function stripAtPrefix(path: string): string {
	return path.startsWith("@") ? path.slice(1) : path;
}

function expandHome(path: string): string {
	if (path === "~") return homedir();
	if (path.startsWith("~/")) return resolve(homedir(), path.slice(2));
	return path;
}

function resolveInputPath(rawPath: string, cwd: string): string {
	const expanded = expandHome(stripAtPrefix(rawPath));
	return isAbsolute(expanded) ? resolve(expanded) : resolve(cwd, expanded);
}

async function canonicalizeForPolicy(absolutePath: string): Promise<string> {
	let current = absolutePath;

	while (true) {
		try {
			const existingRealPath = await realpath(current);
			const remainder = relative(current, absolutePath);
			return remainder === "" ? existingRealPath : resolve(existingRealPath, remainder);
		} catch {
			const parent = dirname(current);
			if (parent === current) return absolutePath;
			current = parent;
		}
	}
}

function isCaseInsensitivePathPlatform(): boolean {
	return process.platform === "darwin" || process.platform === "win32";
}

function normalizeCaseForPlatform(value: string): string {
	return isCaseInsensitivePathPlatform() ? value.toLowerCase() : value;
}

function escapeRegexChar(char: string): string {
	return char.replace(/[|\\{}()[\]^$+*?.]/g, "\\$&");
}

function escapeGlobLiteral(value: string): string {
	return value.replace(/[\\*?[\]]/g, "\\$&");
}

function escapeRegexClassChar(char: string): string {
	if (char === "\n") return "\\n";
	if (char === "\r") return "\\r";
	if (char === "\\" || char === "]" || char === "^" || char === "-") return `\\${char}`;
	return char;
}

function safeWildcardSource(): string {
	return `[^${[...SHELL_META_CHARS].map(escapeRegexClassChar).join("")}]`;
}

function parseGlobClass(pattern: string, start: number): { source: string; end: number } | undefined {
	let end = start + 1;
	while (end < pattern.length && pattern[end] !== "]") {
		if (pattern[end] === "\\" && end + 1 < pattern.length) end++;
		end++;
	}

	if (end >= pattern.length) return undefined;

	const body = pattern.slice(start + 1, end);
	const negated = body.startsWith("!") || body.startsWith("^");
	const chars = (negated ? body.slice(1) : body).split("").map(escapeRegexClassChar).join("");
	if (chars.length === 0) return undefined;

	return {
		source: negated ? `(?:(?![${chars}])${safeWildcardSource()})` : `[${chars}]`,
		end,
	};
}

function containsUnescapedGlobstar(pattern: string): boolean {
	for (let index = 0; index < pattern.length - 1; index++) {
		if (pattern[index] === "\\") {
			index++;
			continue;
		}
		if (pattern[index] === "*" && pattern[index + 1] === "*") return true;
	}
	return false;
}

function globToRegExp(pattern: string): RegExp {
	if (containsUnescapedGlobstar(pattern)) throw new Error("globstar ** is not supported in bash-command-guard patterns");

	let source = "^";
	const wildcard = safeWildcardSource();

	for (let index = 0; index < pattern.length; index++) {
		const char = pattern[index];

		if (char === "\\" && index + 1 < pattern.length) {
			source += escapeRegexChar(pattern[index + 1]);
			index++;
			continue;
		}

		if (char === "*") {
			source += `${wildcard}*`;
			continue;
		}

		if (char === "?") {
			source += wildcard;
			continue;
		}

		if (char === "[") {
			const parsedClass = parseGlobClass(pattern, index);
			if (parsedClass) {
				source += parsedClass.source;
				index = parsedClass.end;
				continue;
			}
		}

		source += escapeRegexChar(char);
	}

	return new RegExp(`${source}$`, "s");
}

function commandMatchesPattern(command: string, pattern: string): boolean {
	return globToRegExp(pattern).test(command);
}

function firstMatchingPattern(command: string, patterns: string[]): string | undefined {
	return patterns.find((pattern) => {
		try {
			return commandMatchesPattern(command, pattern);
		} catch {
			return false;
		}
	});
}

async function pathExists(path: string): Promise<boolean> {
	try {
		await lstat(path);
		return true;
	} catch {
		return false;
	}
}

async function findRepositoryRoot(cwd: string): Promise<string> {
	const start = await realpath(cwd).catch(() => resolve(cwd));
	let current = start;

	while (true) {
		if (await pathExists(join(current, ".git"))) return current;

		const parent = dirname(current);
		if (parent === current) return start;
		current = parent;
	}
}

function repositoryConfigPath(root: string): string {
	const hash = createHash("sha256").update(root).digest("hex").slice(0, 24);
	return join(WHITELIST_DIR, `${hash}.json`);
}

function tokenizeShellLike(value: string): string[] {
	const tokens: string[] = [];
	let current = "";
	let quote: "'" | '"' | undefined;

	for (let index = 0; index < value.length; index++) {
		const char = value[index];

		if (char === "\\" && index + 1 < value.length) {
			current += value[index + 1];
			index++;
			continue;
		}

		if (quote) {
			if (char === quote) quote = undefined;
			else current += char;
			continue;
		}

		if (char === "'" || char === '"') {
			quote = char;
			continue;
		}

		if (/\s/.test(char)) {
			if (current.length > 0) {
				tokens.push(current);
				current = "";
			}
			continue;
		}

		current += char;
	}

	if (current.length > 0) tokens.push(current);
	return tokens;
}

function isEnvAssignment(token: string): boolean {
	return /^[A-Za-z_][A-Za-z0-9_]*=.*/.test(token);
}

function executableFromTokens(tokens: string[]): string | undefined {
	let index = 0;
	while (index < tokens.length && isEnvAssignment(tokens[index])) index++;

	while (index < tokens.length) {
		const token = basename(tokens[index]).toLowerCase();
		if (!COMMAND_WRAPPERS.has(token)) return tokens[index];

		index++;
		if (token === "env" || token === "time") {
			while (index < tokens.length && (tokens[index].startsWith("-") || isEnvAssignment(tokens[index]))) index++;
		}
	}

	return undefined;
}

function normalizedExecutableName(executable: string): string {
	return basename(executable).toLowerCase();
}

function isRiskyExecutable(name: string): boolean {
	if (RISKY_EXECUTABLE_NAMES.has(name)) return true;
	if (/^python(?:\d+(?:\.\d+)?)?$/.test(name)) return true;
	if (/^node(?:js)?$/.test(name)) return true;
	if (/^(?:ba|c|da|fi|k|z)?sh$/.test(name)) return true;
	return false;
}

function shellMetaCharInPattern(pattern: string): string | undefined {
	return [...pattern].find((char) => SHELL_META_CHARS.has(char));
}

function tokenContainsGlobSyntax(token: string): boolean {
	return /[*?[\]]/.test(token);
}

function validatePatternSafety(pattern: string): string | undefined {
	const trimmed = pattern.trim();
	if (trimmed.length === 0) return "empty patterns are not allowed";
	if (containsUnescapedGlobstar(trimmed)) return "globstar ** is not supported; use a single * wildcard";

	const meta = shellMetaCharInPattern(trimmed);
	if (meta) return `shell metacharacter ${JSON.stringify(meta)} is not allowed in persistent whitelist patterns`;

	const tokens = tokenizeShellLike(trimmed);
	const executable = executableFromTokens(tokens);
	if (!executable) return "pattern must start with a literal command name";
	if (tokenContainsGlobSyntax(executable)) return "the command name must be literal; put wildcards after the command name";

	const commandName = normalizedExecutableName(executable);
	if (isRiskyExecutable(commandName)) {
		return `${commandName} can run or edit arbitrary code; use Allow once instead of a persistent whitelist pattern`;
	}

	if (commandName === "nix" && RISKY_NIX_SUBCOMMANDS.has((tokens[1] ?? "").toLowerCase())) {
		return `nix ${tokens[1]} can run arbitrary commands; use Allow once instead of a persistent whitelist pattern`;
	}

	if (!SAFE_PERSISTENT_EXECUTABLE_NAMES.has(commandName)) {
		return `${commandName} is not in the persistent whitelist allowlist; use Allow once for commands that can read, write, evaluate config, run hooks, contact services, or execute other programs`;
	}

	try {
		globToRegExp(trimmed);
	} catch (error) {
		return error instanceof Error ? error.message : String(error);
	}

	return undefined;
}

function extractInputPaths(input: ToolInput): string[] {
	const paths = new Set<string>();

	for (const [key, value] of Object.entries(input)) {
		const normalizedKey = key.toLowerCase();
		const keyLooksPathLike =
			PATH_FIELD_NAMES.has(normalizedKey) || normalizedKey.endsWith("path") || normalizedKey.endsWith("file");
		if (!keyLooksPathLike) continue;

		if (typeof value === "string" && value.length > 0) paths.add(value);
		else if (Array.isArray(value)) {
			for (const item of value) {
				if (typeof item === "string" && item.length > 0) paths.add(item);
			}
		}
	}

	return [...paths];
}

async function loadPatterns(configPath: string): Promise<PatternLoadResult> {
	let raw: string;
	try {
		raw = await readFile(configPath, "utf8");
	} catch (error) {
		if ((error as { code?: string }).code === "ENOENT") return { exists: false, patterns: [], diagnostics: [] };
		return { exists: false, patterns: [], diagnostics: [`Could not read ${configPath}: ${String(error)}`] };
	}

	try {
		const parsed = JSON.parse(raw) as unknown;
		let candidates: unknown[] | undefined;

		if (Array.isArray(parsed)) candidates = parsed;
		else if (parsed && typeof parsed === "object" && Array.isArray((parsed as { patterns?: unknown }).patterns)) {
			candidates = (parsed as { patterns: unknown[] }).patterns;
		}

		if (!candidates) {
			return { exists: true, patterns: [], diagnostics: [`${configPath} does not contain a patterns array`] };
		}

		const patterns: string[] = [];
		const diagnostics: string[] = [];

		for (const candidate of candidates) {
			if (typeof candidate !== "string") {
				diagnostics.push(`Ignored non-string whitelist entry in ${configPath}`);
				continue;
			}

			const reason = validatePatternSafety(candidate);
			if (reason) {
				diagnostics.push(`Ignored unsafe whitelist pattern ${JSON.stringify(candidate)} in ${configPath}: ${reason}`);
				continue;
			}

			patterns.push(candidate);
		}

		return { exists: true, patterns, diagnostics };
	} catch (error) {
		return { exists: true, patterns: [], diagnostics: [`Could not parse ${configPath}: ${String(error)}`] };
	}
}

async function savePatterns(configPath: string, patterns: string[]): Promise<void> {
	await mkdir(dirname(configPath), { recursive: true });
	const tempPath = `${configPath}.${process.pid}.${Date.now()}.tmp`;
	await writeFile(tempPath, `${JSON.stringify({ patterns }, null, 2)}\n`, { encoding: "utf8", mode: 0o600 });
	await chmod(tempPath, 0o600);
	await rename(tempPath, configPath);
	await chmod(configPath, 0o600).catch(() => undefined);
}

function sleep(ms: number): Promise<void> {
	return new Promise((resolveSleep) => setTimeout(resolveSleep, ms));
}

function processExists(pid: number): boolean {
	try {
		process.kill(pid, 0);
		return true;
	} catch (error) {
		return (error as { code?: string }).code === "EPERM";
	}
}

async function isStaleLock(lockPath: string): Promise<boolean> {
	const ownerPath = join(lockPath, "owner.json");

	try {
		const parsed = JSON.parse(await readFile(ownerPath, "utf8")) as { pid?: unknown; createdAt?: unknown };
		const pid = typeof parsed.pid === "number" ? parsed.pid : undefined;
		const createdAt = typeof parsed.createdAt === "number" ? parsed.createdAt : 0;
		const oldEnough = Date.now() - createdAt > LOCK_STALE_MS;
		return oldEnough && (pid === undefined || !processExists(pid));
	} catch {
		try {
			const stat = await lstat(lockPath);
			return Date.now() - stat.mtimeMs > LOCK_STALE_MS;
		} catch {
			return true;
		}
	}
}

async function withPatternLock<T>(configPath: string, fn: () => Promise<T>): Promise<T> {
	await mkdir(dirname(configPath), { recursive: true });

	const lockPath = `${configPath}.lock`;
	const ownerPath = join(lockPath, "owner.json");
	const start = Date.now();
	let acquired = false;

	while (true) {
		try {
			await mkdir(lockPath, { recursive: false });
			acquired = true;
			try {
				await writeFile(ownerPath, JSON.stringify({ pid: process.pid, createdAt: Date.now() }), {
					encoding: "utf8",
					mode: 0o600,
				});
			} catch (error) {
				await rm(lockPath, { recursive: true, force: true });
				acquired = false;
				throw error;
			}
			break;
		} catch (error) {
			if ((error as { code?: string }).code !== "EEXIST") throw error;
			if (await isStaleLock(lockPath)) {
				await rm(lockPath, { recursive: true, force: true });
				continue;
			}
			if (Date.now() - start > 10_000) throw new Error(`Timed out waiting for whitelist lock ${lockPath}`);
			await sleep(100);
		}
	}

	try {
		return await fn();
	} finally {
		if (acquired) await rm(lockPath, { recursive: true, force: true });
	}
}

async function getRepositoryPolicy(ctx: ExtensionContext): Promise<RepositoryPolicy> {
	const root = await findRepositoryRoot(ctx.cwd);
	const configPath = repositoryConfigPath(root);
	const legacyConfigPath = join(root, LEGACY_WHITELIST_FILE);
	const active = await loadPatterns(configPath);
	const diagnostics = [...active.diagnostics];
	let patterns = active.patterns;

	if (!active.exists && (await pathExists(legacyConfigPath))) {
		const legacy = await loadPatterns(legacyConfigPath);
		diagnostics.push(...legacy.diagnostics);

		if (legacy.patterns.length > 0) {
			await withPatternLock(configPath, async () => {
				if (!(await pathExists(configPath))) await savePatterns(configPath, legacy.patterns);
			});
			patterns = legacy.patterns;
			diagnostics.push(`Migrated ${legacy.patterns.length} safe pattern(s) from ${legacyConfigPath} to ${configPath}`);
		}
	}

	return { root, configPath, legacyConfigPath, patterns, diagnostics };
}

async function addPattern(policy: RepositoryPolicy, pattern: string): Promise<RepositoryPolicy> {
	return withPatternLock(policy.configPath, async () => {
		const loaded = await loadPatterns(policy.configPath);
		const patterns = [...loaded.patterns.filter((existing) => existing !== pattern), pattern];
		await savePatterns(policy.configPath, patterns);
		return { ...policy, patterns, diagnostics: loaded.diagnostics };
	});
}

async function targetsWhitelistFile(ctx: ExtensionContext, input: ToolInput): Promise<boolean> {
	const paths = extractInputPaths(input);
	if (paths.length === 0) return false;

	const policy = await getRepositoryPolicy(ctx);
	const protectedPaths = new Set([
		await canonicalizeForPolicy(policy.configPath),
		await canonicalizeForPolicy(policy.legacyConfigPath),
	]);

	for (const rawPath of paths) {
		const requestedPath = await canonicalizeForPolicy(resolveInputPath(rawPath, ctx.cwd));
		if (protectedPaths.has(requestedPath)) return true;
	}

	return false;
}

function commandMentionsProtectedWhitelist(ctx: ExtensionContext, policy: RepositoryPolicy, command: string): boolean {
	const haystack = normalizeCaseForPlatform(command);
	const needles = [
		policy.configPath,
		dirname(policy.configPath),
		policy.legacyConfigPath,
		dirname(policy.legacyConfigPath),
		relative(ctx.cwd, policy.configPath),
		relative(ctx.cwd, dirname(policy.configPath)),
		relative(ctx.cwd, policy.legacyConfigPath),
		relative(ctx.cwd, dirname(policy.legacyConfigPath)),
		LEGACY_WHITELIST_FILE,
		basename(policy.configPath),
		basename(LEGACY_WHITELIST_FILE),
	]
		.filter((needle) => needle.length > 0 && needle !== ".")
		.map(normalizeCaseForPlatform);

	return needles.some((needle) => haystack.includes(needle));
}

async function promptForProtectedWhitelistCommand(
	ctx: ExtensionContext,
	policy: RepositoryPolicy,
	toolName: string,
	command: string,
): Promise<boolean> {
	if (!ctx.hasUI) return false;

	return ctx.ui.confirm(
		"Allow command mentioning bash whitelist?",
		[
			`The ${toolName} command mentions bash-command-guard's protected whitelist path.`,
			"This is blocked by default because command runners can modify the whitelist outside normal write/edit auditing.",
			"",
			`Whitelist: ${policy.configPath}`,
			`Legacy whitelist: ${policy.legacyConfigPath}`,
			"",
			"Command:",
			command,
			"",
			"Allow this command once?",
		].join("\n"),
	);
}

function isGuardedCommandTool(toolName: string, input: ToolInput): boolean {
	return GUARDED_BASH_TOOLS.has(toolName) || typeof input.command === "string";
}

async function promptForDecision(
	ctx: ExtensionContext,
	policy: RepositoryPolicy,
	toolName: string,
	command: string,
): Promise<"allow-once" | "allow-always" | "deny"> {
	if (!ctx.hasUI) return "deny";

	const choice = await ctx.ui.select(
		[
			"bash-command-guard blocks command-runner tools unless their command matches this repository's whitelist.",
			"",
			`Source: assistant ${toolName} tool`,
			`Repository: ${policy.root}`,
			`Whitelist: ${policy.configPath}`,
			policy.legacyConfigPath === policy.configPath ? "" : `Legacy in-repo whitelist (not used): ${policy.legacyConfigPath}`,
			"",
			"Command:",
			command,
			"",
			"Choose how to handle it:",
		].filter(Boolean).join("\n"),
		[ALLOW_ONCE, ALLOW_ALWAYS, DENY],
	);

	if (choice === ALLOW_ONCE) return "allow-once";
	if (choice === ALLOW_ALWAYS) return "allow-always";
	return "deny";
}

async function promptForPattern(ctx: ExtensionContext, command: string): Promise<string | undefined> {
	if (!ctx.hasUI) return undefined;

	const edited = await ctx.ui.editor(
		[
			"Edit the glob pattern to allow always.",
			"",
			"Examples:",
			"- pwd allows exactly pwd",
			"- echo * allows simple echo commands until a shell control/metacharacter",
			"",
			"Persistent patterns must start with a literal command name from a small safe allowlist.",
			"Wildcards do not match |, &, ;, (, ), <, >, `, $, or newlines.",
			"Shell/interpreter/editor commands (bash, sh, python, node, sed, tee, vim, nano, nix run, etc.) are Allow-once only.",
			"Command-capable programs (git, find, xargs, make, npm/yarn/pnpm, gh, docker/podman, ssh, kubectl, psql/mysql, etc.) are also Allow-once only.",
			"Unknown commands are Allow-once only rather than persistently whitelisted.",
			"The pattern must be safe and must match the current command to be saved.",
		].join("\n"),
		escapeGlobLiteral(command),
	);

	return edited?.trim();
}

async function shouldAllowCommand(
	ctx: ExtensionContext,
	toolName: string,
	rawCommand: string,
): Promise<{ allowed: boolean; reason?: string }> {
	const command = normalizeCommand(rawCommand);
	const policy = await getRepositoryPolicy(ctx);

	if (policy.diagnostics.length > 0 && ctx.hasUI) ctx.ui.notify(policy.diagnostics.join("\n"), "warning");

	if (commandMentionsProtectedWhitelist(ctx, policy, command)) {
		const allowed = await promptForProtectedWhitelistCommand(ctx, policy, toolName, command);
		if (allowed) return { allowed: true, reason: "Allowed once to access bash-command-guard whitelist path" };
		return { allowed: false, reason: "Command mentions the bash-command-guard whitelist path" };
	}

	const matchingPattern = firstMatchingPattern(command, policy.patterns);
	if (matchingPattern) return { allowed: true, reason: `Matched bash whitelist pattern: ${matchingPattern}` };

	const decision = await promptForDecision(ctx, policy, toolName, command);
	if (decision === "allow-once") return { allowed: true, reason: "Allowed once by user" };
	if (decision === "deny") return { allowed: false, reason: "Bash command denied by bash-command-guard" };

	const pattern = await promptForPattern(ctx, command);
	if (!pattern) return { allowed: false, reason: "No bash whitelist pattern entered" };

	const unsafeReason = validatePatternSafety(pattern);
	if (unsafeReason) {
		ctx.ui.notify(`Pattern was not saved because it is unsafe: ${unsafeReason}`, "error");
		return { allowed: false, reason: "Unsafe bash whitelist pattern" };
	}

	try {
		if (!commandMatchesPattern(command, pattern)) {
			ctx.ui.notify("Pattern was not saved because it does not match the current command.", "error");
			return { allowed: false, reason: "Bash whitelist pattern did not match command" };
		}
	} catch (error) {
		ctx.ui.notify(`Pattern was not saved because it is invalid: ${String(error)}`, "error");
		return { allowed: false, reason: "Invalid bash whitelist pattern" };
	}

	await addPattern(policy, pattern);
	ctx.ui.notify(`Added bash whitelist pattern: ${pattern}`, "info");
	return { allowed: true, reason: `Added bash whitelist pattern: ${pattern}` };
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const policy = await getRepositoryPolicy(ctx);
		ctx.ui.setStatus("bash-guard", ctx.ui.theme.fg("accent", "🛡 bash guard"));
		ctx.ui.notify(
			[
				`bash-command-guard active. ${policy.patterns.length} whitelist pattern(s) loaded from ${policy.configPath}`,
				...policy.diagnostics.map((diagnostic) => `Warning: ${diagnostic}`),
			].join("\n"),
			policy.diagnostics.length > 0 ? "warning" : "info",
		);
	});

	pi.on("tool_call", async (event, ctx) => {
		const input = event.input as ToolInput;

		if ((event.toolName === "write" || event.toolName === "edit") && (await targetsWhitelistFile(ctx, input))) {
			return {
				block: true,
				reason: "Direct tool edits to the bash-command-guard whitelist are blocked; use Allow always or edit it manually outside pi.",
			};
		}

		if (!isGuardedCommandTool(event.toolName, input)) return undefined;

		const command = input.command;
		if (typeof command !== "string") {
			return { block: true, reason: "Command-runner tool blocked because command input was not a string" };
		}

		const decision = await shouldAllowCommand(ctx, event.toolName, command);
		if (!decision.allowed) return { block: true, reason: decision.reason };
		return undefined;
	});

	pi.registerCommand("bash-guard", {
		description: "Show bash-command-guard whitelist for this repository",
		handler: async (_args, ctx) => {
			const policy = await getRepositoryPolicy(ctx);
			ctx.ui.notify(
				[
					"bash-command-guard is active.",
					"",
					`Repository: ${policy.root}`,
					`Whitelist: ${policy.configPath}`,
					`Legacy in-repo whitelist: ${policy.legacyConfigPath}`,
					"",
					"Patterns:",
					...(policy.patterns.length > 0 ? policy.patterns.map((pattern) => `- ${pattern}`) : ["- <none>"]),
					...(policy.diagnostics.length > 0 ? ["", "Diagnostics:", ...policy.diagnostics.map((line) => `- ${line}`)] : []),
				].join("\n"),
				policy.diagnostics.length > 0 ? "warning" : "info",
			);
		},
	});
}
