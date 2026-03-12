# OpenClaw 项目架构分析

> 基于官方文档和源码探索，最后更新：2026-03-12

---

## 📊 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              用户层 (User Layer)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  macOS App  │  iOS App  │  Android App  │  CLI  │  Web UI  │  自动化脚本   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓↑ WebSocket
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Gateway 网关层 (Gateway Layer)                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  WebSocket Server (Port 18789)                                              │
│  ├─ 认证 & 配对 (Authentication & Pairing)                                  │
│  ├─ 协议验证 (Protocol Validation)                                          │
│  ├─ 会话管理 (Session Management)                                           │
│  └─ 事件分发 (Event Dispatch)                                               │
│                                                                              │
│  HTTP Server (Port 18789)                                                   │
│  ├─ Canvas 主机 (/__openclaw__/canvas/)                                     │
│  └─ A2UI 主机 (/__openclaw__/a2ui/)                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                         核心服务层 (Core Services Layer)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  Agent (AI 助手)  │  Memory (记忆系统)  │  Skills (技能)  │  Plugins (插件) │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                         消息渠道层 (Channel Layer)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  Telegram  │  WhatsApp  │  Discord  │  Slack  │  Signal  │  iMessage  │ ...│
│  (grammY)  │ (Baileys)  │ (discord.js)│ (Slack Bolt)│  (Signal CLI)│      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓↑
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AI 模型层 (Model Layer)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  OpenAI  │  Anthropic  │  GLM  │  Gemini  │  本地模型  │  其他              │
│  (OAuth) │  (OAuth)    │(API Key)│ (OAuth) │ (llama.cpp)│                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ 核心组件详解

### 1. Gateway (网关) - 控制平面

**职责**：
- 维护所有消息渠道的连接
- 暴露 WebSocket API 供客户端连接
- 处理认证、配对和权限
- 分发事件和消息

**关键特性**：
- **单例模式**：每台主机只能运行一个 Gateway
- **长期运行**：作为守护进程（daemon）运行
- **协议驱动**：基于 TypeBox 定义的协议，自动生成 JSON Schema

**协议类型**：
```typescript
// 请求-响应模式
{ type: "req", id: string, method: string, params: any }
→ { type: "res", id: string, ok: boolean, payload?: any, error?: string }

// 事件推送模式
{ type: "event", event: string, payload: any, seq?: number }
```

**主要方法**：
- `health` - 健康检查
- `status` - 系统状态
- `send` - 发送消息
- `agent` - 调用 AI 助手
- `system-presence` - 系统状态更新

**主要事件**：
- `tick` - 心跳
- `agent` - AI 助手响应（流式）
- `presence` - 在线状态
- `shutdown` - 关闭通知

---

### 2. Agent (AI 助手) - 智能核心

**职责**：
- 处理用户的自然语言请求
- 管理对话上下文
- 调用技能和工具
- 流式响应

**工作流程**：
```
用户消息 → 消息解析 → 上下文构建 → 模型调用 → 工具执行 → 响应生成
```

**关键模块**：
- **Message Handler** - 消息预处理
- **Context Builder** - 构建对话上下文（包括记忆、技能）
- **Tool Executor** - 执行工具调用
- **Response Streamer** - 流式响应

---

### 3. Memory (记忆系统)

**职责**：
- 短期记忆（会话级）
- 长期记忆（持久化）
- 向量检索（语义搜索）

**存储后端**：
- SQLite（默认）
- LanceDB（向量存储）
- 自定义存储（通过扩展）

**记忆类型**：
```typescript
interface Memory {
  shortTerm: {
    // 当前会话
    messages: Message[];
    context: string;
  };
  
  longTerm: {
    // 持久化
    facts: Fact[];
    preferences: Preference[];
    decisions: Decision[];
  };
  
  vector: {
    // 向量存储
    embeddings: number[][];
    metadata: any[];
  };
}
```

---

### 4. Skills (技能系统)

**职责**：
- 定义特定的能力
- 提供工具接口
- 封装复杂逻辑

**技能结构**：
```
skill-name/
├── SKILL.md              # 技能定义（描述、触发条件、使用指南）
├── index.ts              # 实现（工具、处理逻辑）
└── package.json          # 依赖
```

**关键文件**：`SKILL.md`
```markdown
---
name: skill-name
description: 技能描述
metadata:
  openclaw:
    requires: { anyBins: ["command-name"] }
---

# 技能文档

使用场景、API、示例等。
```

**内置技能**：
- `coding-agent` - 编码助手
- `weather` - 天气查询
- `healthcheck` - 系统健康检查
- `skill-creator` - 创建新技能
- 更多...

---

### 5. Extensions (扩展系统)

**职责**：
- 集成外部服务
- 扩展核心功能
- 添加新渠道

**扩展类型**：
1. **渠道扩展**（Channel Extensions）
   - Telegram、WhatsApp、Discord、Slack 等
   - 实现消息收发、事件监听

2. **功能扩展**（Feature Extensions）
   - `memory-lancedb` - 向量存储
   - `voice-call` - 语音通话
   - `acpx` - ACP 运行时

**扩展结构**：
```
extension-name/
├── src/
│   ├── index.ts          # 入口
│   ├── client.ts         # 客户端
│   ├── handlers.ts       # 消息处理
│   └── types.ts          # 类型定义
├── package.json
└── README.md
```

---

### 6. Channels (消息渠道)

**已支持的渠道**：
- **Telegram** - grammY 框架
- **WhatsApp** - Baileys 库
- **Discord** - discord.js
- **Slack** - Slack Bolt
- **Signal** - Signal CLI
- **iMessage** - BlueBubbles
- **IRC** - IRC 库
- **Microsoft Teams** - Bot Framework
- **Google Chat** - Chat API
- **Matrix** - Matrix SDK
- **Feishu** - Lark SDK
- **LINE** - LINE Bot SDK
- **Mattermost** - Mattermost SDK
- **Nostr** - Nostr 协议
- **Twitch** - Twitch IRC
- **Zalo** - Zalo API
- **WebChat** - 内置 Web UI

**渠道抽象**：
```typescript
interface MessageChannel {
  // 发送消息
  send(message: Message): Promise<void>;
  
  // 事件监听
  on(event: 'message', handler: (msg: Message) => void): void;
  on(event: 'presence', handler: (p: Presence) => void): void;
  
  // 渠道信息
  getInfo(): ChannelInfo;
  
  // 健康检查
  healthCheck(): Promise<HealthStatus>;
}
```

---

### 7. Plugins (插件系统)

**职责**：
- 动态加载功能模块
- 生命周期管理
- 依赖注入

**插件生命周期**：
```
load → initialize → start → [运行中] → stop → unload
```

**插件 API**：
```typescript
interface Plugin {
  name: string;
  version: string;
  
  onLoad(context: PluginContext): Promise<void>;
  onStart(): Promise<void>;
  onStop(): Promise<void>;
  onUnload(): Promise<void>;
}
```

**Plugin SDK**：
- 提供插件开发工具
- 定义标准接口
- 管理插件依赖

---

## 🔄 数据流和通信

### 消息流（用户发送消息）

```
用户 (Telegram)
    ↓
Telegram Extension (grammY)
    ↓ 消息解析
Gateway WebSocket Server
    ↓ 事件分发
Agent (AI 助手)
    ↓ 上下文构建 + 记忆检索
Model Provider (OpenAI/Anthropic/GLM)
    ↓ 生成响应
Agent
    ↓ 工具调用（如果需要）
Skills/Tools
    ↓ 执行结果
Agent
    ↓ 响应生成
Gateway
    ↓ 消息路由
Telegram Extension
    ↓ 发送消息
用户 (Telegram)
```

### 连接生命周期

```
Client                    Gateway
  |                          |
  |---- req:connect -------->|  (1) 建立连接
  |<------ res (ok) ---------|
  |   (hello-ok: 状态快照)   |
  |                          |
  |<------ event:presence ---|  (2) 状态更新
  |<------ event:tick -------|
  |                          |
  |------- req:agent ------->|  (3) 调用助手
  |<------ res:agent --------|  (接受: {runId})
  |<------ event:agent ------|  (流式响应)
  |<------ res:agent --------|  (完成)
  |                          |
  |------- req:send -------->|  (4) 发送消息
  |<------ res (ok) ---------|
```

---

## 🔐 安全和认证

### 配对机制

1. **设备身份**：每个客户端有唯一的设备 ID
2. **配对批准**：新设备需要明确批准
3. **设备令牌**：批准后颁发令牌，用于后续连接
4. **签名验证**：所有连接必须签名 challenge nonce

### 本地信任

- **Loopback** 连接可自动批准（流畅体验）
- **非本地** 连接必须明确批准（安全考虑）

### Gateway Token

- 可选的 `OPENCLAW_GATEWAY_TOKEN` 环境变量
- 所有连接必须提供匹配的 token

### 权限控制

- 基于角色的访问控制（RBAC）
- 节点声明能力（caps）和命令（commands）
- 操作员（operator）vs 节点（node）角色

---

## 🚀 性能和扩展性

### 单例设计

- **一个 Gateway**：避免连接冲突
- **单一 Baileys 会话**：WhatsApp 限制
- **集中式状态管理**：简化同步

### 水平扩展

- 通过增加节点（nodes）扩展能力
- 节点可运行在不同设备上
- Gateway 负责协调和路由

### 事件驱动

- 非阻塞 I/O
- WebSocket 长连接
- 事件推送而非轮询

---

## 📦 目录结构

```
openclaw/
├── dist/                  # 编译后的代码
│   ├── *.js              # 模块文件
│   └── index.js          # 主入口
├── docs/                  # 文档
│   ├── concepts/         # 核心概念
│   ├── gateway/          # Gateway 文档
│   ├── channels/         # 渠道文档
│   └── zh-CN/            # 中文文档
├── extensions/            # 扩展（渠道、功能）
│   ├── telegram/         # Telegram 扩展
│   ├── whatsapp/         # WhatsApp 扩展
│   ├── discord/          # Discord 扩展
│   └── ...               # 其他扩展
├── skills/                # 技能
│   ├── coding-agent/     # 编码助手
│   ├── weather/          # 天气
│   ├── healthcheck/      # 健康检查
│   └── ...               # 其他技能
├── openclaw.mjs          # CLI 入口
├── package.json          # 依赖和脚本
└── README.md             # 项目说明
```

---

## 🛠️ 技术栈

### 核心技术

- **Runtime**: Node.js ≥22
- **Language**: TypeScript
- **Protocol**: WebSocket + JSON
- **Validation**: TypeBox + JSON Schema
- **Build**: tsdown + pnpm

### 关键依赖

- **Express** - HTTP 服务器
- **ws** - WebSocket 实现
- **grammy** - Telegram Bot 框架
- **@whiskeysockets/baileys** - WhatsApp Web API
- **discord.js** - Discord API
- **@slack/bolt** - Slack Bot 框架
- **sharp** - 图像处理
- **pdfjs-dist** - PDF 处理
- **playwright-core** - 浏览器自动化

### 数据存储

- **SQLite** - 本地数据库
- **sqlite-vec** - 向量扩展
- **LanceDB** - 向量存储（可选）

---

## 📚 学习建议

### 初学者路径

1. **阅读文档**：`docs/concepts/` 和 `docs/gateway/`
2. **运行示例**：`openclaw onboard`
3. **创建 Skill**：参考 `skills/weather/`
4. **研究 Extension**：选择感兴趣的渠道

### 进阶路径

1. **深入 Gateway 协议**：`docs/gateway/protocol.md`
2. **研究核心代码**：克隆源码仓库
3. **贡献代码**：从小的 bug 修复开始
4. **创建复杂扩展**：如新的渠道集成

### 高级路径

1. **优化性能**：研究 Gateway 和 Agent 性能
2. **扩展架构**：设计新的插件或技能
3. **安全审计**：研究认证和权限系统
4. **社区贡献**：参与核心功能开发

---

## 🔗 相关资源

- **官方文档**: https://docs.openclaw.ai
- **GitHub**: https://github.com/openclaw/openclaw
- **Discord**: https://discord.gg/clawd
- **DeepWiki**: https://deepwiki.com/openclaw/openclaw

---

## 📝 总结

OpenClaw 的架构设计体现了以下特点：

1. **模块化**：Gateway、Agent、Skills、Extensions 清晰分离
2. **可扩展**：通过插件和技能系统轻松扩展
3. **协议驱动**：基于 TypeBox 和 JSON Schema 的强类型协议
4. **事件驱动**：WebSocket 长连接 + 事件推送
5. **安全可靠**：配对机制、权限控制、本地信任
6. **多渠道**：统一抽象，支持多种消息平台
7. **多模型**：支持多种 AI 模型提供商

这种架构使得 OpenClaw 既适合个人使用，也具备企业级的扩展能力。
