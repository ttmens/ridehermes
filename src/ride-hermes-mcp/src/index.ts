#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { HermesClient } from "./hermes-client.js";
import * as sandbox from "./sandbox.js";

const args = process.argv.slice(2);
const isSandbox = args.includes("--sandbox") || process.env.RIDEHERMES_SANDBOX === "true";
const transportType = args.includes("--transport") ? args[args.indexOf("--transport") + 1] : "stdio";
const port = parseInt(args.includes("--port") ? args[args.indexOf("--port") + 1] || "3100" : "3100");

if (args[0] === "setup") {
  const { main } = await import("./setup.js");
  await main();
  process.exit(0);
}

const client = new HermesClient();

if (!isSandbox && !client.hasCredentials()) {
  console.error("╔══════════════════════════════════════════════════════════╗");
  console.error("║  🚗 RideHermes MCP Server v2.0 — 未配置凭证            ║");
  console.error("╠══════════════════════════════════════════════════════════╣");
  console.error("║  运行: npx ridehermes-mcp-server setup                  ║");
  console.error("║  或使用沙箱模式: --sandbox                              ║");
  console.error("╚══════════════════════════════════════════════════════════╝");
  process.exit(1);
}

const server = new McpServer({
  name: "ride-hermes-mcp",
  version: "2.0.0",
});

// === 网约车工具 ===

server.tool(
  "ride_estimate",
  "预估行程费用（返回多车型价格对比）",
  {
    pickup_addr: z.string().describe("上车点地址"),
    dropoff_addr: z.string().describe("下车点地址"),
  },
  async (args) => {
    if (isSandbox) {
      return { content: [{ type: "text", text: JSON.stringify(sandbox.getMockEstimate()) }] };
    }
    const result = await client.estimateMulti(args.pickup_addr, args.dropoff_addr);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "ride_book",
  "叫车：创建出行订单",
  {
    pickup_addr: z.string().describe("上车点地址"),
    dropoff_addr: z.string().describe("下车点地址"),
    car_type: z.number().default(1).describe("1=快车, 2=专车, 3=豪华车"),
  },
  async (args) => {
    if (isSandbox) {
      const order = sandbox.createMockOrder(args.pickup_addr, args.dropoff_addr, args.car_type);
      return { content: [{ type: "text", text: JSON.stringify(order) }] };
    }
    const result = await client.book(args);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "ride_status",
  "查询订单状态",
  { order_id: z.string().describe("订单号") },
  async (args) => {
    if (isSandbox) {
      const order = sandbox.getMockOrder(args.order_id);
      return { content: [{ type: "text", text: JSON.stringify(order || { error: "订单不存在" }) }] };
    }
    const result = await client.status(args.order_id);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "ride_cancel",
  "取消订单",
  { order_id: z.string().describe("订单号"), reason: z.string().optional() },
  async (args) => {
    if (isSandbox) {
      const ok = sandbox.cancelMockOrder(args.order_id);
      return { content: [{ type: "text", text: JSON.stringify({ success: ok }) }] };
    }
    await client.cancel(args.order_id, args.reason);
    return { content: [{ type: "text", text: JSON.stringify({ success: true, message: "订单已取消" }) }] };
  }
);

server.tool(
  "ride_history",
  "查询历史订单",
  { limit: z.number().default(10) },
  async (args) => {
    if (isSandbox) {
      return { content: [{ type: "text", text: JSON.stringify([]) }] };
    }
    const result = await client.history(args.limit);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

// === 地图工具 ===

server.tool(
  "maps_poi_search",
  "搜索地点（POI）",
  { keywords: z.string().describe("关键词"), city: z.string().optional() },
  async (args) => {
    if (isSandbox) {
      const filtered = sandbox.mockPOIs.filter(p => p.name.includes(args.keywords) || p.type.includes(args.keywords));
      return { content: [{ type: "text", text: JSON.stringify(filtered) }] };
    }
    const result = await client.mapsPoiSearch(args.keywords, args.city);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "maps_place_around",
  "搜索附近地点",
  { location: z.string().describe("坐标 lng,lat"), keywords: z.string().optional(), radius: z.number().default(1000) },
  async (args) => {
    if (isSandbox) {
      return { content: [{ type: "text", text: JSON.stringify(sandbox.mockPOIs.slice(0, 3)) }] };
    }
    const result = await client.mapsPlaceAround(args.location, args.keywords, args.radius);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "maps_place_suggestion",
  "输入提示/自动补全",
  { keywords: z.string().describe("关键词"), city: z.string().optional() },
  async (args) => {
    if (isSandbox) {
      const filtered = sandbox.mockPOIs.filter(p => p.name.includes(args.keywords));
      return { content: [{ type: "text", text: JSON.stringify(filtered) }] };
    }
    const result = await client.mapsPlaceSuggestion(args.keywords, args.city);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "maps_static_map",
  "生成静态地图URL",
  { center: z.string().describe("中心点 lng,lat"), zoom: z.number().default(14) },
  async (args) => {
    if (isSandbox) {
      return { content: [{ type: "text", text: JSON.stringify({ url: `https://restapi.amap.com/v3/staticmap?center=${args.center}&zoom=${args.zoom}` }) }] };
    }
    const result = await client.mapsStaticMap(args.center, args.zoom);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "maps_route_plan",
  "路线规划",
  { origin: z.string().describe("起点 lng,lat"), destination: z.string().describe("终点 lng,lat"), mode: z.string().default("driving") },
  async (args) => {
    if (isSandbox) {
      return { content: [{ type: "text", text: JSON.stringify(sandbox.mockRoute) }] };
    }
    const result = await client.mapsRoutePlan(args.origin, args.destination, args.mode);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

// === 启动服务器 ===

if (transportType === "http") {
  // HTTP transport
  const { createServer } = await import("http");
  const { randomUUID } = await import("crypto");
  
  const httpServer = createServer(async (req, res) => {
    if (req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "ok", version: "2.0.0", sandbox: isSandbox }));
      return;
    }
    
    if (req.method !== "POST") {
      res.writeHead(405);
      res.end();
      return;
    }
    
    let body = "";
    req.on("data", chunk => body += chunk);
    req.on("end", async () => {
      try {
        const msg = JSON.parse(body);
        
        if (msg.method === "initialize") {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ jsonrpc: "2.0", id: msg.id, result: { protocolVersion: "2024-11-05", capabilities: { tools: {} }, serverInfo: { name: "ride-hermes-mcp", version: "2.0.0" } } }));
        } else if (msg.method === "tools/list") {
          const tools = [
            { name: "ride_estimate", description: "预估行程费用（多车型）" },
            { name: "ride_book", description: "叫车" },
            { name: "ride_status", description: "查询订单" },
            { name: "ride_cancel", description: "取消订单" },
            { name: "ride_history", description: "历史订单" },
            { name: "maps_poi_search", description: "搜索地点" },
            { name: "maps_place_around", description: "附近搜索" },
            { name: "maps_place_suggestion", description: "输入提示" },
            { name: "maps_static_map", description: "静态地图" },
            { name: "maps_route_plan", description: "路线规划" },
          ];
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ jsonrpc: "2.0", id: msg.id, result: { tools } }));
        } else {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ jsonrpc: "2.0", id: msg.id, result: {} }));
        }
      } catch (e) {
        res.writeHead(400);
        res.end(String(e));
      }
    });
  });
  
  httpServer.listen(port, () => {
    console.log(`🚗 RideHermes MCP Server v2.0 (HTTP) listening on port ${port}${isSandbox ? " [SANDBOX]" : ""}`);
  });
} else {
  // stdio transport (default)
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`🚗 RideHermes MCP Server v2.0 (stdio) started${isSandbox ? " [SANDBOX]" : ""}`);
}
