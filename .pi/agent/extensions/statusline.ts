import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext, ReadonlyFooterDataProvider } from "@mariozechner/pi-coding-agent";
import type { Component, TUI } from "@mariozechner/pi-tui";
import { truncateToWidth } from "@mariozechner/pi-tui";
import { spawn } from "node:child_process";
import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { basename } from "node:path";

// Claude Code-style statusline for pi.
// Shows model/project/git/cost/time, plus ctx + Codex 5h/weekly subscription limits.

const LIMIT_CACHE = "/tmp/pi-statusline-codex-limits.json";
const LIMIT_CACHE_AGE_MS = 5 * 60 * 1000;
const GIT_CACHE_AGE_MS = 5 * 1000;
const BAR_W = 10;

const RST = "\x1b[0m";
const BOLD = "\x1b[1m";
const DIM = "\x1b[2m";
const RED = "\x1b[91m";
const GRN = "\x1b[32m";
const YLW = "\x1b[33m";
const BLU = "\x1b[34m";
const MAG = "\x1b[35m";
const CYN = "\x1b[36m";
const WHT = "\x1b[37m";
const BGRY = "\x1b[90m";
const SEP = ` ${BGRY}│${RST} `;

type RateLimitWindow = {
	usedPercent: number;
	windowDurationMins: number | null;
	resetsAt: number | null;
};

type RateLimitSnapshot = {
	primary: RateLimitWindow | null;
	secondary: RateLimitWindow | null;
};

type GitStats = {
	dirty: boolean;
	added: number;
	deleted: number;
};

type LimitState = {
	data?: RateLimitSnapshot;
	updatedAt: number;
	loading: boolean;
};

function pickColor(pct: number): string {
	if (pct > 80) return RED;
	if (pct >= 50) return YLW;
	return GRN;
}

function clampPercent(pct: number): number {
	if (!Number.isFinite(pct)) return 0;
	return Math.max(0, Math.min(100, Math.round(pct)));
}

function makeBar(percent: number, width = BAR_W, threshold?: number): string {
	const pct = clampPercent(percent);
	let clr = pickColor(pct);
	let filled = Math.floor((pct * width) / 100);
	if (pct > 0 && filled === 0) filled = 1;
	const empty = width - filled;

	if (threshold !== undefined) {
		const thresholdCell = Math.floor((threshold * width) / 100);
		if (filled > thresholdCell) clr = YLW;
	}

	let bar = filled > 0 ? "━".repeat(filled) : "";
	if (threshold !== undefined) {
		const thresholdCell = Math.floor((threshold * width) / 100);
		let emptyStr = "";
		for (let i = 0; i < empty; i++) {
			const absPos = filled + i;
			emptyStr += absPos === thresholdCell ? "ǀ" : "╌";
		}
		bar += emptyStr;
	} else {
		bar += "╌".repeat(empty);
	}
	return `${clr}${bar}${RST}`;
}

function makeStaleBar(width = BAR_W): string {
	return `${BGRY}${"·".repeat(width)}${RST}`;
}

function formatReset(epochSeconds: number | null | undefined, weekly = false): string {
	if (!epochSeconds || !Number.isFinite(epochSeconds)) return "";
	const d = new Date(epochSeconds * 1000);
	const time = d.toLocaleString(undefined, { hour: "numeric", hour12: true }).toLowerCase().replace(/\s/g, "");
	if (!weekly) return time;
	const day = d.toLocaleString(undefined, { weekday: "short" }).toLowerCase();
	return `${day} ${time}`;
}

function formatDuration(ms: number): string {
	const secs = Math.max(0, Math.floor(ms / 1000));
	if (secs >= 3600) return `${Math.floor(secs / 3600)}h${Math.floor((secs % 3600) / 60)}m`;
	if (secs >= 60) return `${Math.floor(secs / 60)}m${secs % 60}s`;
	return `${secs}s`;
}

function formatContextWindow(tokens: number | undefined): string {
	if (!tokens || !Number.isFinite(tokens)) return "";
	if (tokens >= 1_000_000) return `${(tokens / 1_000_000).toFixed(tokens % 1_000_000 === 0 ? 0 : 1)}m`;
	return `${Math.round(tokens / 1000)}k`;
}

function sessionStartedAt(ctx: ExtensionContext): number {
	const header = ctx.sessionManager.getHeader();
	const ts = header?.timestamp ? Date.parse(header.timestamp) : NaN;
	return Number.isFinite(ts) ? ts : Date.now();
}

function sessionCost(ctx: ExtensionContext): number {
	let cost = 0;
	for (const e of ctx.sessionManager.getBranch()) {
		if (e.type === "message" && e.message.role === "assistant") {
			const msg = e.message as AssistantMessage;
			cost += msg.usage?.cost?.total ?? 0;
		}
	}
	return cost;
}

function modelStyle(ctx: ExtensionContext): { icon: string; color: string; label: string } {
	const model = ctx.model;
	const label = model?.name || model?.id || "pi";
	const id = `${model?.provider ?? ""}/${model?.id ?? ""}/${label}`.toLowerCase();
	if (id.includes("opus")) return { icon: "◆", color: MAG, label };
	if (id.includes("sonnet")) return { icon: "◇", color: BLU, label };
	if (id.includes("haiku")) return { icon: "○", color: CYN, label };
	if (id.includes("codex") || id.includes("gpt")) return { icon: "●", color: WHT, label };
	return { icon: "●", color: WHT, label };
}

function renderLimit(label: "5h" | "wk", win: RateLimitWindow | null | undefined, weekly = false): string {
	if (!win) return `${DIM}${label}${RST} ${makeStaleBar()} ${DIM}—%${RST}`;
	const pct = clampPercent(win.usedPercent);
	const reset = formatReset(win.resetsAt, weekly);
	const lbl = reset ? `${label} ${DIM}${reset}${RST}` : label;
	return `${lbl} ${makeBar(pct)} ${BOLD}${pct}%${RST}`;
}

function readCachedLimits(): RateLimitSnapshot | undefined {
	try {
		if (!existsSync(LIMIT_CACHE)) return undefined;
		const age = Date.now() - statSync(LIMIT_CACHE).mtimeMs;
		if (age > LIMIT_CACHE_AGE_MS) return undefined;
		const parsed = JSON.parse(readFileSync(LIMIT_CACHE, "utf8"));
		return parsed?.rateLimits as RateLimitSnapshot | undefined;
	} catch {
		return undefined;
	}
}

function writeCachedLimits(rateLimits: RateLimitSnapshot): void {
	try {
		writeFileSync(LIMIT_CACHE, JSON.stringify({ rateLimits, fetchedAt: Date.now() }), { mode: 0o600 });
	} catch {
		// best effort
	}
}

async function fetchCodexLimitsViaAppServer(timeoutMs = 8000): Promise<RateLimitSnapshot | undefined> {
	return await new Promise((resolve) => {
		const child = spawn("codex", ["app-server", "--listen", "stdio://"], {
			stdio: ["pipe", "pipe", "ignore"],
		});

		let settled = false;
		let buffer = "";
		const finish = (value: RateLimitSnapshot | undefined) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			child.kill();
			resolve(value);
		};
		const timer = setTimeout(() => finish(undefined), timeoutMs);

		child.on("error", () => finish(undefined));
		child.on("exit", () => finish(undefined));
		child.stdout.on("data", (chunk: Buffer) => {
			buffer += chunk.toString("utf8");
			let newline: number;
			while ((newline = buffer.indexOf("\n")) >= 0) {
				const line = buffer.slice(0, newline).trim();
				buffer = buffer.slice(newline + 1);
				if (!line) continue;
				try {
					const msg = JSON.parse(line);
					if (msg.id === 2) {
						const limits = msg.result?.rateLimits as RateLimitSnapshot | undefined;
						if (limits) writeCachedLimits(limits);
						finish(limits);
					}
				} catch {
					// ignore non-JSON output
				}
			}
		});

		const initialize = {
			jsonrpc: "2.0",
			id: 1,
			method: "initialize",
			params: {
				clientInfo: { name: "pi-statusline", title: null, version: "1.0.0" },
				capabilities: { experimentalApi: true },
			},
		};
		const initialized = { jsonrpc: "2.0", method: "initialized" };
		const readLimits = { jsonrpc: "2.0", id: 2, method: "account/rateLimits/read" };
		child.stdin.write(`${JSON.stringify(initialize)}\n${JSON.stringify(initialized)}\n${JSON.stringify(readLimits)}\n`);
	});
}

function createLimitRefresher(state: LimitState) {
	return async (tui?: TUI) => {
		if (state.loading) return;
		const cached = readCachedLimits();
		if (cached) {
			state.data = cached;
			state.updatedAt = Date.now();
			return;
		}
		state.loading = true;
		try {
			const data = await fetchCodexLimitsViaAppServer();
			if (data) {
				state.data = data;
				state.updatedAt = Date.now();
			}
		} finally {
			state.updatedAt = Date.now();
			state.loading = false;
			tui?.requestRender();
		}
	};
}

async function execText(command: string, args: string[], cwd: string): Promise<string | undefined> {
	return await new Promise((resolve) => {
		const child = spawn(command, args, { cwd, stdio: ["ignore", "pipe", "ignore"] });
		let out = "";
		const timer = setTimeout(() => {
			child.kill();
			resolve(undefined);
		}, 1500);
		child.stdout.on("data", (chunk: Buffer) => (out += chunk.toString("utf8")));
		child.on("error", () => {
			clearTimeout(timer);
			resolve(undefined);
		});
		child.on("close", (code) => {
			clearTimeout(timer);
			resolve(code === 0 ? out : undefined);
		});
	});
}

function createGitRefresher(ctx: ExtensionContext) {
	let stats: GitStats | undefined;
	let last = 0;
	let loading = false;
	const refresh = async (tui?: TUI) => {
		if (loading || Date.now() - last < GIT_CACHE_AGE_MS) return;
		loading = true;
		last = Date.now();
		try {
			const status = await execText("git", ["-c", "core.useBuiltinFSMonitor=false", "status", "--porcelain"], ctx.cwd);
			if (status === undefined) {
				stats = undefined;
				return;
			}
			const numstat = await execText(
				"git",
				["-c", "core.useBuiltinFSMonitor=false", "diff", "--numstat", "HEAD", "--"],
				ctx.cwd,
			);
			let added = 0;
			let deleted = 0;
			for (const line of (numstat ?? "").trim().split("\n")) {
				if (!line) continue;
				const [a, d] = line.split(/\s+/);
				if (/^\d+$/.test(a)) added += Number(a);
				if (/^\d+$/.test(d)) deleted += Number(d);
			}
			stats = { dirty: status.trim().length > 0, added, deleted };
		} finally {
			loading = false;
			tui?.requestRender();
		}
	};
	return { get: () => stats, refresh };
}

class StatuslineFooter implements Component {
	private readonly startedAt: number;
	private readonly git: ReturnType<typeof createGitRefresher>;

	constructor(
		private readonly tui: TUI,
		private readonly ctx: ExtensionContext,
		private readonly footerData: ReadonlyFooterDataProvider,
		private readonly limits: LimitState,
		private readonly refreshLimits: (tui?: TUI) => Promise<void>,
	) {
		this.startedAt = sessionStartedAt(ctx);
		this.git = createGitRefresher(ctx);
		void this.refreshLimits(tui);
		void this.git.refresh(tui);
	}

	invalidate(): void {}

	render(width: number): string[] {
		if ((this.limits.updatedAt === 0 || Date.now() - this.limits.updatedAt > LIMIT_CACHE_AGE_MS) && !this.limits.loading) {
			void this.refreshLimits(this.tui);
		}
		void this.git.refresh(this.tui);

		const model = modelStyle(this.ctx);
		const dirName = basename(this.ctx.cwd) || this.ctx.cwd;
		const cost = sessionCost(this.ctx).toFixed(2);
		const time = formatDuration(Date.now() - this.startedAt);

		const branch = this.footerData.getGitBranch();
		const gitStats = this.git.get();
		const gitStr = branch
			? ` ${BGRY}│${RST} ${MAG}⎇${RST} ${CYN}${branch}${RST}${gitStats?.dirty ? `${YLW}*${RST}` : ""}`
			: "";
		const linesStr = gitStats && (gitStats.added > 0 || gitStats.deleted > 0)
			? ` ${BGRY}│${RST} ${GRN}+${gitStats.added}${RST} ${RED}-${gitStats.deleted}${RST}`
			: "";

		const line1 = `${model.color}${model.icon} ${model.label}${RST}${SEP}${GRN}${BOLD}${dirName}${RST}${gitStr}${SEP}${YLW}$${cost}${RST}${SEP}${BLU}⏱ ${time}${RST}${linesStr}`;

		const usage = this.ctx.getContextUsage();
		const contextWindow = usage?.contextWindow ?? this.ctx.model?.contextWindow;
		const ctxPercent = usage?.percent == null ? 0 : clampPercent(usage.percent);
		const ctxThreshold = contextWindow && contextWindow >= 900_000 ? 20 : undefined;
		const contextSize = formatContextWindow(contextWindow);
		const contextPct = usage?.percent == null ? `${DIM}—%${RST}` : `${BOLD}${ctxPercent}%${RST}`;
		const ctxBar = usage?.percent == null ? makeStaleBar() : makeBar(ctxPercent, BAR_W, ctxThreshold);
		const ctxSizeStr = contextSize ? `${DIM}/${contextSize}${RST}` : "";

		const line2 = `${DIM}ctx${RST} ${ctxBar} ${contextPct}${ctxSizeStr}${SEP}${renderLimit("5h", this.limits.data?.primary)}${SEP}${renderLimit("wk", this.limits.data?.secondary, true)}`;

		return [truncateToWidth(line1, width), truncateToWidth(line2, width)];
	}
}

export default function (pi: ExtensionAPI) {
	const limits: LimitState = { updatedAt: 0, loading: false };
	const refreshLimits = createLimitRefresher(limits);

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((tui, _theme, footerData) => {
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
			const footer = new StatuslineFooter(tui, ctx, footerData, limits, refreshLimits);
			return {
				render: (width: number) => footer.render(width),
				invalidate: () => footer.invalidate(),
				dispose: unsubscribe,
			};
		});
	});

	pi.registerCommand("statusline-refresh", {
		description: "Refresh the pi statusline Codex limit cache",
		handler: async (_args, ctx) => {
			limits.data = undefined;
			limits.updatedAt = 0;
			await refreshLimits();
			ctx.ui.notify(limits.data ? "Statusline limits refreshed" : "Could not refresh Codex limits", limits.data ? "info" : "warning");
		},
	});
}
