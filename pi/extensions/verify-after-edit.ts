import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";

const DEFAULT_SCRIPT = ".pi/verify-after-edit";
const CONFIG_FILE = ".pi/verify-after-edit.json";
const DEFAULT_TIMEOUT_MS = 120_000;
const MAX_OUTPUT_CHARS = 24_000;
const DEFAULT_TOOLS = ["edit", "write"];

type Mode = "after-turn" | "after-tool" | "manual";
type FailBehavior = "steer" | "message" | "notify";

type Config = {
	projectRoot: string;
	configPath?: string;
	scriptPath: string;
	mode: Mode;
	timeoutMs: number;
	runOnTools: Set<string>;
	silentOnSuccess: boolean;
	failBehavior: FailBehavior;
	diagnostics: string[];
};

type VerificationResult = {
	ok: boolean;
	code: number | undefined;
	killed: boolean;
	stdout: string;
	stderr: string;
	output: string;
	truncated: boolean;
	scriptPath: string;
	projectRoot: string;
	mode: Mode;
	trigger: string;
	paths: string[];
	error?: string;
};

type RawConfig = {
	script?: unknown;
	mode?: unknown;
	timeoutMs?: unknown;
	runOnTools?: unknown;
	silentOnSuccess?: unknown;
	failBehavior?: unknown;
};

let pendingPaths = new Set<string>();
let dirtyThisTurn = false;
let verificationQueue: Promise<unknown> = Promise.resolve();

function stripAtPrefix(path: string): string {
	return path.startsWith("@") ? path.slice(1) : path;
}

function isInsideRoot(root: string, candidate: string): boolean {
	const rel = relative(root, candidate);
	return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel));
}

async function pathExists(path: string): Promise<boolean> {
	try {
		await stat(path);
		return true;
	} catch {
		return false;
	}
}

async function findProjectRoot(cwd: string): Promise<string | undefined> {
	let current = resolve(cwd);

	while (true) {
		if ((await pathExists(join(current, CONFIG_FILE))) || (await pathExists(join(current, DEFAULT_SCRIPT)))) {
			return current;
		}

		const parent = dirname(current);
		if (parent === current) return undefined;
		current = parent;
	}
}

function parseMode(value: unknown, diagnostics: string[]): Mode {
	if (value === undefined) return "after-turn";
	if (value === "after-turn" || value === "after-tool" || value === "manual") return value;
	diagnostics.push(`Ignoring invalid mode ${JSON.stringify(value)}; expected after-turn, after-tool, or manual.`);
	return "after-turn";
}

function parseFailBehavior(value: unknown, diagnostics: string[]): FailBehavior {
	if (value === undefined) return "steer";
	if (value === "steer" || value === "message" || value === "notify") return value;
	diagnostics.push(`Ignoring invalid failBehavior ${JSON.stringify(value)}; expected steer, message, or notify.`);
	return "steer";
}

function parseTimeout(value: unknown, diagnostics: string[]): number {
	if (value === undefined) return DEFAULT_TIMEOUT_MS;
	if (typeof value === "number" && Number.isFinite(value) && value > 0) return Math.floor(value);
	diagnostics.push(`Ignoring invalid timeoutMs ${JSON.stringify(value)}; expected a positive number.`);
	return DEFAULT_TIMEOUT_MS;
}

function parseRunOnTools(value: unknown, diagnostics: string[]): Set<string> {
	if (value === undefined) return new Set(DEFAULT_TOOLS);
	if (!Array.isArray(value)) {
		diagnostics.push("Ignoring invalid runOnTools; expected an array of tool names.");
		return new Set(DEFAULT_TOOLS);
	}

	const tools = value.filter((item): item is string => typeof item === "string" && item.length > 0);
	if (tools.length === 0) {
		diagnostics.push("Ignoring empty runOnTools; using edit/write.");
		return new Set(DEFAULT_TOOLS);
	}

	return new Set(tools);
}

function resolveProjectPath(projectRoot: string, rawPath: string): string {
	const stripped = stripAtPrefix(rawPath);
	return isAbsolute(stripped) ? resolve(stripped) : resolve(projectRoot, stripped);
}

async function loadConfig(ctx: ExtensionContext): Promise<Config | undefined> {
	const projectRoot = await findProjectRoot(ctx.cwd);
	if (!projectRoot) return undefined;

	const configPath = join(projectRoot, CONFIG_FILE);
	const diagnostics: string[] = [];
	let rawConfig: RawConfig = {};

	if (await pathExists(configPath)) {
		try {
			rawConfig = JSON.parse(await readFile(configPath, "utf8")) as RawConfig;
		} catch (error) {
			diagnostics.push(`Could not parse ${configPath}: ${error instanceof Error ? error.message : String(error)}`);
		}
	}

	const scriptValue = typeof rawConfig.script === "string" && rawConfig.script.trim() ? rawConfig.script.trim() : DEFAULT_SCRIPT;
	const scriptPath = resolveProjectPath(projectRoot, scriptValue);
	if (!isInsideRoot(projectRoot, scriptPath)) {
		diagnostics.push(`Ignoring verifier script outside project root: ${scriptPath}`);
		return undefined;
	}

	if (!(await pathExists(scriptPath))) return undefined;

	return {
		projectRoot,
		configPath: (await pathExists(configPath)) ? configPath : undefined,
		scriptPath,
		mode: parseMode(rawConfig.mode, diagnostics),
		timeoutMs: parseTimeout(rawConfig.timeoutMs, diagnostics),
		runOnTools: parseRunOnTools(rawConfig.runOnTools, diagnostics),
		silentOnSuccess: typeof rawConfig.silentOnSuccess === "boolean" ? rawConfig.silentOnSuccess : true,
		failBehavior: parseFailBehavior(rawConfig.failBehavior, diagnostics),
		diagnostics,
	};
}

function queueVerification<T>(fn: () => Promise<T>): Promise<T> {
	const result = verificationQueue.then(fn, fn);
	verificationQueue = result.catch(() => undefined);
	return result;
}

function pathFromInput(input: Record<string, unknown>): string | undefined {
	const value = input.path;
	return typeof value === "string" && value.length > 0 ? value : undefined;
}

function truncateOutput(output: string): { output: string; truncated: boolean } {
	if (output.length <= MAX_OUTPUT_CHARS) return { output, truncated: false };
	return {
		output: output.slice(output.length - MAX_OUTPUT_CHARS),
		truncated: true,
	};
}

function formatResult(result: VerificationResult): string {
	const lines = [
		result.ok ? "Verification passed after edit." : "Verification failed after edit.",
		"",
		`Script: ${result.scriptPath}`,
		`Project root: ${result.projectRoot}`,
		`Trigger: ${result.trigger}`,
		`Mode: ${result.mode}`,
		`Exit code: ${result.code ?? "unknown"}${result.killed ? " (killed)" : ""}`,
	];

	if (result.paths.length > 0) lines.push(`Changed paths: ${result.paths.join(", ")}`);
	if (result.error) lines.push("", `Error: ${result.error}`);
	if (result.truncated) lines.push("", `[Output truncated to last ${MAX_OUTPUT_CHARS} characters.]`);
	if (result.output.trim().length > 0) lines.push("", "Output:", result.output.trimEnd());

	return lines.join("\n");
}

async function runVerifier(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	config: Config,
	paths: string[],
	trigger: string,
): Promise<VerificationResult> {
	const tempDir = await mkdtemp(join(tmpdir(), "pi-verify-"));
	const pathsFile = join(tempDir, "paths.txt");
	const contextFile = join(tempDir, "context.json");

	const context = {
		trigger,
		mode: config.mode,
		cwd: ctx.cwd,
		projectRoot: config.projectRoot,
		scriptPath: config.scriptPath,
		paths,
	};

	try {
		await writeFile(pathsFile, `${paths.join("\n")}${paths.length > 0 ? "\n" : ""}`, "utf8");
		await writeFile(contextFile, `${JSON.stringify(context, null, 2)}\n`, "utf8");

		const execResult = await pi.exec(
			"env",
			[
				"PI_VERIFY_EVENT=after-edit",
				`PI_VERIFY_MODE=${config.mode}`,
				`PI_VERIFY_TRIGGER=${trigger}`,
				`PI_VERIFY_CWD=${ctx.cwd}`,
				`PI_VERIFY_PROJECT_ROOT=${config.projectRoot}`,
				`PI_VERIFY_SCRIPT=${config.scriptPath}`,
				`PI_VERIFY_CHANGED_PATHS_FILE=${pathsFile}`,
				`PI_VERIFY_CONTEXT_FILE=${contextFile}`,
				"bash",
				config.scriptPath,
			],
			{ cwd: config.projectRoot, signal: ctx.signal, timeout: config.timeoutMs },
		);

		const combined = [execResult.stdout, execResult.stderr].filter((value) => value.length > 0).join("\n");
		const truncated = truncateOutput(combined);

		return {
			ok: execResult.code === 0,
			code: execResult.code,
			killed: execResult.killed,
			stdout: execResult.stdout,
			stderr: execResult.stderr,
			output: truncated.output,
			truncated: truncated.truncated,
			scriptPath: config.scriptPath,
			projectRoot: config.projectRoot,
			mode: config.mode,
			trigger,
			paths,
		};
	} catch (error) {
		return {
			ok: false,
			code: undefined,
			killed: false,
			stdout: "",
			stderr: "",
			output: "",
			truncated: false,
			scriptPath: config.scriptPath,
			projectRoot: config.projectRoot,
			mode: config.mode,
			trigger,
			paths,
			error: error instanceof Error ? error.message : String(error),
		};
	} finally {
		await rm(tempDir, { recursive: true, force: true });
	}
}

function reportTurnResult(pi: ExtensionAPI, ctx: ExtensionContext, config: Config, result: VerificationResult): void {
	const formatted = formatResult(result);

	if (ctx.hasUI) {
		if (result.ok) {
			if (!config.silentOnSuccess) ctx.ui.notify(formatted, "info");
		} else {
			ctx.ui.notify("Verification failed after edit; details were added to the session.", "error");
		}
	}

	if (result.ok || config.failBehavior === "notify") return;

	pi.sendMessage(
		{
			customType: "verification",
			content: formatted,
			display: true,
			details: result,
		},
		{
			deliverAs: config.failBehavior === "steer" ? "steer" : "followUp",
			triggerTurn: config.failBehavior === "steer",
		},
	);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		pendingPaths = new Set();
		dirtyThisTurn = false;

		const config = await loadConfig(ctx);
		if (!ctx.hasUI) return;

		if (!config) {
			ctx.ui.setStatus("verify-after-edit", undefined);
			return;
		}

		ctx.ui.setStatus("verify-after-edit", ctx.ui.theme.fg("accent", `verify: ${config.mode}`));
		if (config.diagnostics.length > 0) ctx.ui.notify(config.diagnostics.join("\n"), "warning");
	});

	pi.on("tool_result", async (event, ctx) => {
		if (event.isError) return undefined;

		const config = await loadConfig(ctx);
		if (!config || config.mode === "manual" || !config.runOnTools.has(event.toolName)) return undefined;

		const changedPath = pathFromInput(event.input);
		if (changedPath) pendingPaths.add(changedPath);
		dirtyThisTurn = true;

		if (config.mode !== "after-tool") return undefined;

		const paths = changedPath ? [changedPath] : [];
		const result = await queueVerification(async () => runVerifier(pi, ctx, config, paths, event.toolName));
		if (ctx.hasUI && !result.ok) ctx.ui.notify("Verification failed after edit.", "error");
		if (result.ok && config.silentOnSuccess) return undefined;

		return {
			content: [
				...event.content,
				{
					type: "text" as const,
					text: `\n\n${formatResult(result)}`,
				},
			],
		};
	});

	pi.on("turn_end", async (_event, ctx) => {
		if (!dirtyThisTurn) return;

		const paths = [...pendingPaths];
		pendingPaths = new Set();
		dirtyThisTurn = false;

		const config = await loadConfig(ctx);
		if (!config || config.mode !== "after-turn") return;

		if (ctx.hasUI) ctx.ui.setStatus("verify-after-edit", ctx.ui.theme.fg("warning", "verify: running"));
		const result = await queueVerification(async () => runVerifier(pi, ctx, config, paths, "turn_end"));
		if (ctx.hasUI) ctx.ui.setStatus("verify-after-edit", ctx.ui.theme.fg(result.ok ? "accent" : "error", `verify: ${result.ok ? "ok" : "failed"}`));

		reportTurnResult(pi, ctx, config, result);
	});

	pi.registerCommand("verify-now", {
		description: "Run this project's .pi/verify-after-edit script",
		handler: async (_args, ctx) => {
			const config = await loadConfig(ctx);
			if (!config) {
				ctx.ui.notify(`No verifier found. Add ${DEFAULT_SCRIPT} to opt in.`, "info");
				return;
			}

			ctx.ui.setStatus("verify-after-edit", ctx.ui.theme.fg("warning", "verify: running"));
			const result = await queueVerification(async () => runVerifier(pi, ctx, config, [], "verify-now"));
			ctx.ui.setStatus("verify-after-edit", ctx.ui.theme.fg(result.ok ? "accent" : "error", `verify: ${result.ok ? "ok" : "failed"}`));
			ctx.ui.notify(formatResult(result), result.ok ? "info" : "error");
		},
	});
}
