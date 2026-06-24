#!/usr/bin/env node
import * as readline from "readline";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

interface MCPServerConfig {
  command: string;
  args: string[];
  env: Record<string, string>;
}

function ask(rl: readline.Interface, question: string): Promise<string> {
  return new Promise((resolve) => rl.question(question, resolve));
}

function upsertJson(
  filePath: string,
  keyPath: string,
  value: unknown
): void {
  let data: Record<string, unknown> = {};
  if (fs.existsSync(filePath)) {
    try {
      data = JSON.parse(fs.readFileSync(filePath, "utf-8"));
    } catch {
      data = {};
    }
  }

  const keys = keyPath.split(".");
  let current = data;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {};
    current = current[keys[i]] as Record<string, unknown>;
  }
  current[keys[keys.length - 1]] = value;

  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + "\n");
}

function injectEnvToProfile(env: Record<string, string>): void {
  const home = os.homedir();
  const profilePath = fs.existsSync(path.join(home, ".zshrc"))
    ? path.join(home, ".zshrc")
    : path.join(home, ".bashrc");

  const lines = Object.entries(env)
    .map(([k, v]) => `export ${k}="${v}"  # RideHermes`)
    .join("\n");
  const marker = "# >>> RideHermes MCP >>>";
  const block = `${marker}\n${lines}\n# <<< RideHermes MCP <<<`;

  let content = "";
  if (fs.existsSync(profilePath)) {
    content = fs.readFileSync(profilePath, "utf-8");
  }
  if (content.includes(marker)) {
    content = content.replace(
      /# >>> RideHermes MCP >>>[\s\S]*# <<< RideHermes MCP <<</,
      block
    );
  } else {
    content += "\n" + block + "\n";
  }
  fs.writeFileSync(profilePath, content);
}

function detectAgents(): {
  name: string;
  path: string;
  installer: (env: Record<string, string>) => void;
}[] {
  const home = os.homedir();
  const agents: {
    name: string;
    path: string;
    installer: (env: Record<string, string>) => void;
  }[] = [];

  // Claude Desktop (macOS)
  const claudeMac = path.join(
    home,
    "Library/Application Support/Claude/claude_desktop_config.json"
  );
  if (fs.existsSync(claudeMac)) {
    agents.push({
      name: "Claude Desktop (macOS)",
      path: claudeMac,
      installer: (env) =>
        upsertJson(claudeMac, "mcpServers.ride-hermes", {
          command: "npx",
          args: ["-y", "ridehermes-mcp-server"],
          env,
        }),
    });
  }

  // Claude Desktop (Linux)
  const claudeLinux = path.join(
    home,
    ".config/Claude/claude_desktop_config.json"
  );
  if (fs.existsSync(claudeLinux)) {
    agents.push({
      name: "Claude Desktop (Linux)",
      path: claudeLinux,
      installer: (env) =>
        upsertJson(claudeLinux, "mcpServers.ride-hermes", {
          command: "npx",
          args: ["-y", "ridehermes-mcp-server"],
          env,
        }),
    });
  }

  // Claude Desktop (Windows)
  const claudeWin = path.join(
    home,
    "AppData/Roaming/Claude/claude_desktop_config.json"
  );
  if (fs.existsSync(claudeWin)) {
    agents.push({
      name: "Claude Desktop (Windows)",
      path: claudeWin,
      installer: (env) =>
        upsertJson(claudeWin, "mcpServers.ride-hermes", {
          command: "npx",
          args: ["-y", "ridehermes-mcp-server"],
          env,
        }),
    });
  }

  // Claude Code
  const ccDir = path.join(home, ".claude");
  const ccConfig = path.join(ccDir, ".mcp.json");
  if (fs.existsSync(ccDir)) {
    agents.push({
      name: "Claude Code",
      path: ccConfig,
      installer: (env) => {
        upsertJson(ccConfig, "mcpServers.ride-hermes", {
          command: "npx",
          args: ["-y", "ridehermes-mcp-server"],
          env,
        });
        injectEnvToProfile(env);
      },
    });
  }

  // openclaw
  const openclawDir = path.join(home, ".openclaw");
  const openclawCfg = path.join(openclawDir, "mcp.json");
  if (fs.existsSync(openclawDir)) {
    agents.push({
      name: "openclaw",
      path: openclawCfg,
      installer: (env) => {
        let servers: unknown[] = [];
        if (fs.existsSync(openclawCfg)) {
          try {
            const data = JSON.parse(fs.readFileSync(openclawCfg, "utf-8"));
            servers = data.servers || [];
          } catch {
            servers = [];
          }
        }
        servers = servers.filter(
          (s: any) => s.name !== "ride-hermes"
        );
        servers.push({
          name: "ride-hermes",
          type: "stdio",
          command: "npx",
          args: ["-y", "ridehermes-mcp-server"],
          env,
        });
        upsertJson(openclawCfg, "servers", servers);
      },
    });
  }

  // hermes
  const hermesDir = path.join(home, ".config/hermes");
  if (fs.existsSync(hermesDir)) {
    agents.push({
      name: "hermes",
      path: hermesDir,
      installer: (env) => {
        injectEnvToProfile(env);
        console.log(
          `  ⚠ hermes: 请手动在 ~/.config/hermes/mcp.yaml 中添加 ride-hermes 配置`
        );
      },
    });
  }

  return agents;
}

/**
 * Read existing credentials from environment variables or shell profile.
 */
function readExistingCredentials(): { apiKey: string; userId: string } {
  const envKey = process.env.RIDEHERMES_API_KEY || "";
  const envId = process.env.RIDEHERMES_USER_ID || "";
  if (envKey && envId) return { apiKey: envKey, userId: envId };

  // Try reading from shell profile
  const home = os.homedir();
  const profilePath = fs.existsSync(path.join(home, ".zshrc"))
    ? path.join(home, ".zshrc")
    : path.join(home, ".bashrc");
  if (fs.existsSync(profilePath)) {
    const content = fs.readFileSync(profilePath, "utf-8");
    const keyMatch = content.match(/RIDEHERMES_API_KEY="([^"]+)"/);
    const idMatch = content.match(/RIDEHERMES_USER_ID="([^"]+)"/);
    if (keyMatch && idMatch) {
      return { apiKey: keyMatch[1], userId: idMatch[1] };
    }
  }
  return { apiKey: "", userId: "" };
}

/**
 * Parse CLI arguments: --api-key, --user-id, --update
 */
function parseArgs(): { apiKey?: string; userId?: string; update: boolean } {
  const argv = process.argv.slice(2);
  const result: { apiKey?: string; userId?: string; update: boolean } = { update: false };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--api-key" && argv[i + 1]) result.apiKey = argv[++i];
    else if (argv[i] === "--user-id" && argv[i + 1]) result.userId = argv[++i];
    else if (argv[i] === "--update") result.update = true;
  }
  return result;
}

export async function main(): Promise<void> {
  const cliArgs = parseArgs();
  const existing = readExistingCredentials();
  const isUpdate = cliArgs.update || (existing.apiKey.length > 0 && !cliArgs.apiKey);

  console.log("\n╔══════════════════════════════════════════════════════════╗");
  console.log(`║  🚗  RideHermes MCP Server v1.2 ${isUpdate ? "(更新模式)" : "(安装模式)"}           ║`);
  console.log("║      让 AI 智能体帮你叫车                                ║");
  console.log("╚══════════════════════════════════════════════════════════╝\n");

  let apiKey = cliArgs.apiKey || "";
  let userId = cliArgs.userId || "";

  // If --update and no CLI args, use existing credentials
  if (isUpdate && !apiKey && !userId && existing.apiKey) {
    console.log(`  ✔ 检测到已有凭证: API Key=${existing.apiKey.slice(0, 10)}...  User ID=${existing.userId}`);
    apiKey = existing.apiKey;
    userId = existing.userId;
  }

  // Interactive prompt if credentials not yet resolved
  if (!apiKey || !userId) {
    console.log("  📋 获取凭证（二选一）：\n");
    console.log("     方式一：RideHermes App");
    console.log("       打开 App →「我的」→「智能体授权」→ 生成 API Key\n");
    console.log("     方式二：管理后台");
    console.log("       https://ride.accseal.cn/admin → 智能体管理 → 生成 API Key\n");
    console.log("     方式三：环境变量（已设置时自动读取）");
    console.log("       export RIDEHERMES_API_KEY=rh_xxx");
    console.log("       export RIDEHERMES_USER_ID=2\n");

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    while (!apiKey.trim()) {
      const hint = existing.apiKey ? ` [回车使用现有: ${existing.apiKey.slice(0, 10)}...]` : " (rh_开头)";
      const input = await ask(rl, `  API Key${hint} : `);
      apiKey = input.trim() || existing.apiKey;
      if (!apiKey) console.log("  ⚠ API Key 不能为空，请重新输入\n");
    }

    while (!userId.trim()) {
      const hint = existing.userId ? ` [回车使用现有: ${existing.userId}]` : " (数字)";
      const input = await ask(rl, `  User ID${hint}     : `);
      userId = input.trim() || existing.userId;
      if (!userId) console.log("  ⚠ User ID 不能为空，请重新输入\n");
    }

    rl.close();
  }

  const envBlock: Record<string, string> = {
    RIDEHERMES_API_KEY: apiKey,
    RIDEHERMES_USER_ID: userId,
  };

  const detected = detectAgents();
  if (detected.length === 0) {
    console.log("\n  未检测到已安装的 AI 智能体。");
    console.log("  手动配置方式：");
    console.log("  1. 设置环境变量：");
    console.log(`     export RIDEHERMES_API_KEY="${apiKey}"`);
    console.log(`     export RIDEHERMES_USER_ID="${userId}"`);
    console.log("  2. 在智能体的 MCP 配置中添加：");
    console.log('     command: npx -y ridehermes-mcp-server');
    console.log("     并注入上述环境变量\n");
    return;
  }

  console.log("\n  Auto-detected:");
  detected.forEach((d) => console.log(`  ✔ ${d.name.padEnd(22)} ${d.path}`));

  console.log("");
  const confirm = await new Promise<string>((resolve) => {
    const rl2 = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    const action = isUpdate ? "更新" : "安装";
    rl2.question(`  确认${action}? [Y/n] `, (ans) => {
      rl2.close();
      resolve(ans.trim().toLowerCase());
    });
  });

  if (confirm && confirm !== "y" && confirm !== "") {
    console.log("  已取消。\n");
    return;
  }

  let installed = 0;
  for (const agent of detected) {
    try {
      agent.installer(envBlock);
      console.log(`  ✔ 已${isUpdate ? "更新" : "写入"} ${agent.name} 配置`);
      installed++;
    } catch (e: any) {
      console.log(`  ✗ ${agent.name} 写入失败: ${e.message}`);
    }
  }

  if (installed > 0) {
    console.log(`\n  ✅ ${isUpdate ? "更新" : "安装"}完成！`);
    console.log("  现在打开你的 AI 智能体，试试：");
    console.log('  "帮我叫一辆快车去北京南站"\n');
  }
}

if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith("setup.js")) {
  main().catch(console.error);
}
