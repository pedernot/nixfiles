import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { realpath } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, isAbsolute, relative, resolve } from "node:path";

type ToolInput = Record<string, unknown>;

const PATH_AUDITED_TOOLS = new Set(["write", "edit"]);
const GUARDED_COMMAND_TOOLS = new Set(["bash", "background_bash"]);
const BUILTIN_READ_ONLY_TOOLS = new Set(["read", "ls", "grep", "find"]);
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

function normalizeCaseForPlatform(path: string): string {
	return process.platform === "darwin" || process.platform === "win32" ? path.toLowerCase() : path;
}

function isInsideRoot(root: string, candidate: string): boolean {
	const normalizedRoot = normalizeCaseForPlatform(root);
	const normalizedCandidate = normalizeCaseForPlatform(candidate);
	const rel = relative(normalizedRoot, normalizedCandidate);
	return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel));
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

function getToolPaths(toolName: string, input: ToolInput): string[] {
	if (!PATH_AUDITED_TOOLS.has(toolName)) return [];
	return extractInputPaths(input);
}

function isCommandRunnerTool(toolName: string, input: ToolInput): boolean {
	return GUARDED_COMMAND_TOOLS.has(toolName) || typeof input.command === "string";
}

async function getCanonicalRoot(ctx: ExtensionContext): Promise<string> {
	return realpath(ctx.cwd).catch(() => resolve(ctx.cwd));
}

async function confirm(ctx: ExtensionContext, title: string, message: string): Promise<boolean> {
	if (!ctx.hasUI) return false;
	return ctx.ui.confirm(title, message);
}

async function confirmOutsidePaths(
	ctx: ExtensionContext,
	toolName: string,
	paths: Array<{ requested: string; resolved: string }>,
): Promise<boolean> {
	const lines = [
		`${toolName} requested path access outside the current working directory.`,
		"",
		`CWD: ${ctx.cwd}`,
		"",
		...paths.flatMap((path) => [`Requested: ${path.requested}`, `Resolved:  ${path.resolved}`, ""]),
		"Allow this tool call?",
	];

	return confirm(ctx, "Allow outside-CWD path access?", lines.join("\n"));
}

async function confirmUnauditedTool(ctx: ExtensionContext, toolName: string, source: string | undefined): Promise<boolean> {
	return confirm(
		ctx,
		"Allow unaudited tool call?",
		[
			`Tool "${toolName}" is not a built-in path-audited implementation${source ? ` (source: ${source})` : ""}.`,
			"cwd-boundary-guard cannot verify whether it will access files outside the current working directory.",
			"",
			`CWD: ${ctx.cwd}`,
			"",
			"Choosing Yes gives this tool call explicit permission to run.",
		].join("\n"),
	);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const root = await getCanonicalRoot(ctx);
		ctx.ui.setStatus("cwd-guard", ctx.ui.theme.fg("accent", "🔒 cwd guard"));
		ctx.ui.notify(`cwd-boundary-guard active. Root: ${root}`, "info");
	});

	pi.on("tool_call", async (event, ctx) => {
		const toolInfo = pi.getAllTools().find((tool) => tool.name === event.toolName);
		const toolSource = toolInfo?.sourceInfo.source;
		const isBuiltInTool = toolSource === "builtin";
		const input = event.input as ToolInput;

		if (isCommandRunnerTool(event.toolName, input)) return undefined;

		if (PATH_AUDITED_TOOLS.has(event.toolName)) {
			const requestedPaths = getToolPaths(event.toolName, input);
			if (requestedPaths.length === 0) {
				return { block: true, reason: "Path-audited tool blocked because no path-like input field was found" };
			}

			const root = await getCanonicalRoot(ctx);
			const outsidePaths: Array<{ requested: string; resolved: string }> = [];

			for (const requested of requestedPaths) {
				const resolved = await canonicalizeForPolicy(resolveInputPath(requested, ctx.cwd));
				if (!isInsideRoot(root, resolved)) {
					outsidePaths.push({ requested, resolved });
				}
			}

			if (outsidePaths.length > 0) {
				const allowed = await confirmOutsidePaths(ctx, event.toolName, outsidePaths);
				if (!allowed) return { block: true, reason: "Outside-CWD path access blocked by cwd-boundary-guard" };
			}

			if (!isBuiltInTool) {
				const allowed = await confirmUnauditedTool(ctx, event.toolName, toolSource);
				if (!allowed) return { block: true, reason: "Unaudited tool implementation blocked by cwd-boundary-guard" };
			}

			return undefined;
		}

		if (BUILTIN_READ_ONLY_TOOLS.has(event.toolName) && isBuiltInTool) return undefined;

		if (!isBuiltInTool) {
			const allowed = await confirmUnauditedTool(ctx, event.toolName, toolSource);
			if (!allowed) return { block: true, reason: "Unaudited tool blocked by cwd-boundary-guard" };
		}

		return undefined;
	});

	pi.registerCommand("cwd-guard", {
		description: "Show cwd-boundary-guard policy",
		handler: async (_args, ctx) => {
			const root = await getCanonicalRoot(ctx);
			ctx.ui.notify(
				[
					"cwd-boundary-guard is active.",
					"",
					`CWD: ${ctx.cwd}`,
					`Canonical root: ${root}`,
					"",
					"Policy:",
					"- Built-in read/ls/grep/find are allowed everywhere.",
					"- Built-in write/edit are allowed only inside CWD unless you confirm outside access.",
					"- Command-runner tools with a command input are delegated to bash-command-guard.",
					"- Non-built-in/unknown tools require confirmation because their filesystem behavior cannot be audited.",
					"- In non-interactive modes, requests that need confirmation are blocked.",
					"- Note: preflight path checks canonicalize existing paths but cannot eliminate all filesystem TOCTOU races.",
				].join("\n"),
				"info",
			);
		},
	});
}
