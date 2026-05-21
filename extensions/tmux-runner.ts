import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { chmod, mkdir, open, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import {
	createBashTool,
	createLocalBashOperations,
	getAgentDir,
	type BashOperations,
	type ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const RUNNER_TITLE = "pi-runner";
const RUN_DIR = join(getAgentDir(), "tmux-runner");
const SHELL_COMMANDS = new Set(["bash", "zsh", "fish", "sh", "dash"]);

let runnerPane: string | undefined;
let queue: Promise<unknown> = Promise.resolve();

function inTmux(): boolean {
	return Boolean(process.env.TMUX && process.env.TMUX_PANE);
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function runQueued<T>(fn: () => Promise<T>): Promise<T> {
	const result = queue.then(fn, fn);
	queue = result.catch(() => undefined);
	return result;
}

function tmux(args: string[], input?: string): Promise<string> {
	return new Promise((resolve, reject) => {
		const child = spawn("tmux", args, {
			stdio: [input === undefined ? "ignore" : "pipe", "pipe", "pipe"],
		});

		if (!child.stdout || !child.stderr) {
			reject(new Error("tmux process streams were not available"));
			return;
		}

		let stdout = "";
		let stderr = "";

		child.stdout.on("data", (data: Buffer) => {
			stdout += data.toString("utf8");
		});

		child.stderr.on("data", (data: Buffer) => {
			stderr += data.toString("utf8");
		});

		child.on("error", reject);
		child.on("close", (code) => {
			if (code === 0) resolve(stdout.trimEnd());
			else reject(new Error(stderr.trim() || `tmux exited with code ${code}`));
		});

		if (input !== undefined) {
			if (!child.stdin) {
				reject(new Error("tmux process stdin was not available"));
				return;
			}
			child.stdin.end(input);
		}
	});
}

async function paneExists(pane: string): Promise<boolean> {
	try {
		await tmux(["display-message", "-p", "-t", pane, "#{pane_id}"]);
		return true;
	} catch {
		return false;
	}
}

async function paneCommand(pane: string): Promise<string | undefined> {
	try {
		return await tmux(["display-message", "-p", "-t", pane, "#{pane_current_command}"]);
	} catch {
		return undefined;
	}
}

async function findExistingRunnerPane(): Promise<string | undefined> {
	const currentPane = process.env.TMUX_PANE;
	if (!currentPane) return undefined;

	const panes = await tmux(["list-panes", "-t", currentPane, "-F", "#{pane_id}\t#{@pi_runner}\t#{pane_dead}"]);

	for (const line of panes.split("\n")) {
		const [paneId, marker, dead] = line.split("\t");
		if (paneId && paneId !== currentPane && marker === "1" && dead !== "1") return paneId;
	}

	return undefined;
}

async function ensureRunnerPane(cwd: string): Promise<string> {
	if (!inTmux()) throw new Error("not running inside tmux");
	if (runnerPane && (await paneExists(runnerPane))) return runnerPane;

	const existing = await findExistingRunnerPane();
	if (existing) {
		runnerPane = existing;
		return existing;
	}

	const pane = await tmux(["split-window", "-h", "-t", process.env.TMUX_PANE!, "-P", "-F", "#{pane_id}", "-c", cwd]);
	runnerPane = pane.trim();

	await tmux(["select-pane", "-t", runnerPane, "-T", RUNNER_TITLE]);
	await tmux(["set-option", "-p", "-t", runnerPane, "@pi_runner", "1"]);
	await tmux([
		"send-keys",
		"-t",
		runnerPane,
		`printf '\\033]2;${RUNNER_TITLE}\\033\\'; cd ${shellQuote(cwd)}; printf '\\n[pi] persistent runner pane ready\\n'`,
		"Enter",
	]);

	if (process.env.TMUX_PANE) await tmux(["select-pane", "-t", process.env.TMUX_PANE]);
	return runnerPane;
}

async function resetRunner(cwd: string): Promise<string> {
	runnerPane = undefined;
	return ensureRunnerPane(cwd);
}

async function currentSessionTarget(): Promise<string> {
	if (!process.env.TMUX_PANE) throw new Error("not running inside tmux");
	return tmux(["display-message", "-p", "-t", process.env.TMUX_PANE, "#{session_id}"]);
}

function envExports(env: NodeJS.ProcessEnv | undefined): string {
	if (!env) return "";

	const ignored = new Set(["TMUX", "TMUX_PANE"]);
	const lines: string[] = [];

	for (const [key, value] of Object.entries(env)) {
		if (value === undefined) continue;
		if (ignored.has(key)) continue;
		if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) continue;
		lines.push(`export ${key}=${shellQuote(value)}`);
	}

	return lines.join("\n");
}

function makeOneShotWrapper(args: {
	id: string;
	command: string;
	commandPath: string;
	cwd: string;
	doneChannel: string;
	env?: NodeJS.ProcessEnv;
	logPath: string;
	statusPath: string;
}): string {
	return `#!/usr/bin/env bash
set +e
LOG=${shellQuote(args.logPath)}
STATUS=${shellQuote(args.statusPath)}
CMD=${shellQuote(args.commandPath)}
CWD=${shellQuote(args.cwd)}
DONE=${shellQuote(args.doneChannel)}
ID=${shellQuote(args.id)}

finish() {
	local status="$1"
	printf '%s' "$status" > "$STATUS"
	printf '\n[pi] done %s exit %s\n' "$ID" "$status"
	tmux wait-for -S "$DONE" >/dev/null 2>&1 || true
	exit "$status"
}

on_interrupt() {
	printf '\n[pi] interrupted %s\n' "$ID"
	finish 130
}

trap on_interrupt INT TERM

printf '\n──── pi bash %s ────\n' "$ID"
printf '$ %s\n' ${shellQuote(args.command)}

{
	cd "$CWD" || exit 1
${envExports(args.env)}
	bash "$CMD"
} 2>&1 | tee "$LOG"
status="\${PIPESTATUS[0]}"
finish "$status"
`;
}

function makeBackgroundWrapper(args: { id: string; command: string; commandPath: string; cwd: string }): string {
	return `#!/usr/bin/env bash
set +e
CMD=${shellQuote(args.commandPath)}
CWD=${shellQuote(args.cwd)}
ID=${shellQuote(args.id)}

printf '\n──── pi background bash %s ────\n' "$ID"
printf '$ %s\n\n' ${shellQuote(args.command)}
cd "$CWD" || exit 1
bash "$CMD"
status="$?"
printf '\n[pi] background command %s exited with %s\n' "$ID" "$status"
printf '[pi] window kept open; press Ctrl-D or type exit to close.\n'
exec bash -i
`;
}

async function pumpLog(logPath: string, offsetRef: { value: number }, onData: (data: Buffer) => void) {
	let handle: Awaited<ReturnType<typeof open>> | undefined;

	try {
		handle = await open(logPath, "r");
		const stat = await handle.stat();
		if (stat.size <= offsetRef.value) return;

		const length = stat.size - offsetRef.value;
		const buffer = Buffer.alloc(length);
		const { bytesRead } = await handle.read(buffer, 0, length, offsetRef.value);
		offsetRef.value += bytesRead;
		if (bytesRead > 0) onData(buffer.subarray(0, bytesRead));
	} catch {
		// The log may not exist yet or may be between writes. Try again on the next tick.
	} finally {
		await handle?.close().catch(() => undefined);
	}
}

function waitForTmuxChannel(channel: string): Promise<void> {
	return new Promise((resolve, reject) => {
		const child = spawn("tmux", ["wait-for", channel], { stdio: "ignore" });
		child.on("error", reject);
		child.on("close", (code) => {
			if (code === 0) resolve();
			else reject(new Error(`tmux wait-for exited with code ${code}`));
		});
	});
}

async function writeScriptPair(args: {
	command: string;
	cwd: string;
	env?: NodeJS.ProcessEnv;
	kind: "oneshot" | "background";
}): Promise<{
	id: string;
	commandPath: string;
	wrapperPath: string;
	logPath: string;
	statusPath: string;
	doneChannel: string;
}> {
	await mkdir(RUN_DIR, { recursive: true });

	const id = randomUUID().slice(0, 8);
	const base = join(RUN_DIR, `${Date.now()}-${id}`);
	const commandPath = `${base}.command.sh`;
	const wrapperPath = `${base}.wrapper.sh`;
	const logPath = `${base}.log`;
	const statusPath = `${base}.status`;
	const doneChannel = `pi-tmux-runner-${process.pid}-${id}`;

	await writeFile(commandPath, args.command, { mode: 0o600 });
	await writeFile(logPath, "", { mode: 0o600 });

	const wrapper =
		args.kind === "oneshot"
			? makeOneShotWrapper({
					id,
					command: args.command,
					commandPath,
					cwd: args.cwd,
					doneChannel,
					env: args.env,
					logPath,
					statusPath,
				})
			: makeBackgroundWrapper({ id, command: args.command, commandPath, cwd: args.cwd });

	await writeFile(wrapperPath, wrapper, { mode: 0o700 });
	await chmod(commandPath, 0o600);
	await chmod(wrapperPath, 0o700);

	return { id, commandPath, wrapperPath, logPath, statusPath, doneChannel };
}

async function runInRunnerPane(
	command: string,
	cwd: string,
	options: {
		onData: (data: Buffer) => void;
		signal?: AbortSignal;
		timeout?: number;
		env?: NodeJS.ProcessEnv;
	},
): Promise<{ exitCode: number | null }> {
	if (!existsSync(cwd)) throw new Error(`Working directory does not exist: ${cwd}\nCannot execute bash commands.`);

	return runQueued(async () => {
		const pane = await ensureRunnerPane(cwd);
		const currentCommand = await paneCommand(pane);

		if (currentCommand && !SHELL_COMMANDS.has(currentCommand)) {
			throw new Error(
				`tmux runner pane ${pane} is busy running ${currentCommand}. Stop it or close the pane before running another bash command.`,
			);
		}

		const scripts = await writeScriptPair({ command, cwd, env: options.env, kind: "oneshot" });
		const offsetRef = { value: 0 };
		let pumping = false;

		const pump = async () => {
			if (pumping) return;
			pumping = true;
			try {
				await pumpLog(scripts.logPath, offsetRef, options.onData);
			} finally {
				pumping = false;
			}
		};

		const pumpTimer = setInterval(() => void pump(), 100);
		let timeoutTimer: NodeJS.Timeout | undefined;
		let abortedOrTimedOut = false;

		const interrupt = async () => {
			abortedOrTimedOut = true;
			await tmux(["send-keys", "-t", pane, "C-c"]).catch(() => undefined);
		};

		const abortPromise = new Promise<never>((_resolve, reject) => {
			if (options.signal) {
				const onAbort = () => {
					void interrupt();
					setTimeout(() => reject(new Error("aborted")), 500);
				};

				if (options.signal.aborted) onAbort();
				else options.signal.addEventListener("abort", onAbort, { once: true });
			}

			if (options.timeout !== undefined && options.timeout > 0) {
				timeoutTimer = setTimeout(() => {
					void interrupt();
					setTimeout(() => reject(new Error(`timeout:${options.timeout}`)), 1000);
				}, options.timeout * 1000);
			}
		});

		try {
			const donePromise = waitForTmuxChannel(scripts.doneChannel);
			await tmux(["send-keys", "-t", pane, `bash ${shellQuote(scripts.wrapperPath)}`, "Enter"]);
			if (process.env.TMUX_PANE) await tmux(["select-pane", "-t", process.env.TMUX_PANE]).catch(() => undefined);

			await Promise.race([donePromise, abortPromise]);
			await pump();

			const statusText = await readFile(scripts.statusPath, "utf8").catch(() => "1");
			const exitCode = Number.parseInt(statusText.trim(), 10);
			return { exitCode: Number.isFinite(exitCode) ? exitCode : 1 };
		} finally {
			if (timeoutTimer) clearTimeout(timeoutTimer);
			clearInterval(pumpTimer);
			await pump();

			if (abortedOrTimedOut) runnerPane = undefined;
		}
	});
}

function createTmuxBashOperations(local: BashOperations): BashOperations {
	return {
		async exec(command, cwd, options) {
			if (!inTmux()) return local.exec(command, cwd, options);
			return runInRunnerPane(command, cwd, options);
		},
	};
}

const backgroundBashSchema = Type.Object({
	command: Type.String({ description: "Bash command to start in a new tmux window" }),
	name: Type.Optional(Type.String({ description: "Optional tmux window name" })),
});

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();
	const local = createLocalBashOperations();
	const operations = createTmuxBashOperations(local);
	const bashTool = createBashTool(cwd, { operations });

	pi.registerTool({
		...bashTool,
		label: "bash (tmux runner)",
	});

	pi.registerTool({
		name: "background_bash",
		label: "background bash (tmux window)",
		description: "Start a long-running bash command in a new tmux window in the current working directory. Use this for dev servers, watchers, and REPLs.",
		promptSnippet: "Start long-running bash commands in new tmux windows",
		parameters: backgroundBashSchema,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (!inTmux()) {
				throw new Error("background_bash requires pi to be running inside tmux.");
			}

			const scripts = await writeScriptPair({ command: params.command, cwd: ctx.cwd, kind: "background" });
			const requestedName = params.name?.trim() || params.command.split(/\s+/).slice(0, 2).join("-") || "task";
			const windowName = `pi:${requestedName}`.replace(/[:\s]+$/g, "").slice(0, 40);
			const sessionTarget = await currentSessionTarget();
			const target = await tmux([
				"new-window",
				"-d",
				"-t",
				sessionTarget,
				"-P",
				"-F",
				"#{window_id}:#{pane_id}",
				"-n",
				windowName,
				"-c",
				ctx.cwd,
				`bash ${shellQuote(scripts.wrapperPath)}`,
			]);

			return {
				content: [
					{
						type: "text",
						text: [`Started background command in tmux window ${windowName}.`, `Target: ${target}`].join("\n"),
					},
				],
				details: { target, windowName, commandFile: scripts.commandPath, wrapperFile: scripts.wrapperPath },
			};
		},
	});

	pi.on("user_bash", () => {
		if (!inTmux()) return undefined;
		return { operations };
	});

	pi.on("session_start", async (_event, ctx) => {
		if (!inTmux()) {
			ctx.ui.setStatus("tmux-runner", ctx.ui.theme.fg("muted", "tmux runner: off"));
			return;
		}

		try {
			const pane = await ensureRunnerPane(ctx.cwd);
			ctx.ui.setStatus("tmux-runner", ctx.ui.theme.fg("accent", `tmux runner: ${pane}`));
		} catch (error) {
			ctx.ui.setStatus("tmux-runner", ctx.ui.theme.fg("warning", "tmux runner: error"));
			ctx.ui.notify(`tmux runner setup failed: ${error instanceof Error ? error.message : error}`, "error");
		}
	});

	pi.registerCommand("tmux-runner", {
		description: "Show or reset the persistent tmux runner pane",
		handler: async (args, ctx) => {
			if (!inTmux()) {
				ctx.ui.notify("Not running inside tmux; bash uses the normal local backend.", "info");
				return;
			}

			try {
				const pane = args.trim() === "reset" ? await resetRunner(ctx.cwd) : await ensureRunnerPane(ctx.cwd);
				ctx.ui.notify(`tmux runner pane: ${pane}`, "info");
				ctx.ui.setStatus("tmux-runner", ctx.ui.theme.fg("accent", `tmux runner: ${pane}`));
			} catch (error) {
				ctx.ui.notify(`tmux runner error: ${error instanceof Error ? error.message : error}`, "error");
			}
		},
	});
}
