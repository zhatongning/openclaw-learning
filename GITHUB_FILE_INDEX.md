# OpenClaw 源码文件索引

> 将代码调用流程图中的文件路径映射到 GitHub 仓库的实际文件

---

## 📁 文件路径索引表

### 📱 Telegram Extension

| 文件路径 | GitHub 链接 | 说明 |
|---------|------------|------|
| `extensions/telegram/src/client.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/client.ts) | Telegram 消息接收和处理 |
| `extensions/telegram/src/sender.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/sender.ts) | Telegram 消息发送 |
| `extensions/telegram/src/index.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/index.ts) | Extension 入口文件 |
| `extensions/telegram/package.json` | [查看文件](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/package.json) | 依赖配置 |

---

### 🔌 Gateway

| 文件路径 | GitHub 链接 | 说明 |
|---------|------------|------|
| `src/gateway/server.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/gateway/server.ts) | Gateway 服务器 |
| `src/gateway/router.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/gateway/router.ts) | 消息路由 |
| `src/gateway/node-router.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/gateway/node-router.ts) | Node 路由 |
| `src/gateway/message-sender.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/gateway/message-sender.ts) | 消息发送器 |
| `src/gateway/protocol/schema.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/gateway/protocol/schema.ts) | 协议定义 |

---

### 🤖 Agent

| 文件路径 | GitHub 链接 | 说明 |
|---------|------------|------|
| `src/agent/index.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/agent/index.ts) | Agent 主类 |
| `src/agent/message-parser.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/agent/message-parser.ts) | 消息解析 |
| `src/agent/context-builder.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/agent/context-builder.ts) | 上下文构建 |
| `src/agent/tool-executor.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/agent/tool-executor.ts) | 工具执行 |
| `src/agent/response-generator.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/agent/response-generator.ts) | 响应生成 |
| `src/agent/skills/skill-matcher.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/agent/skills/skill-matcher.ts) | 技能匹配 |

---

### 💻 Node

| 文件路径 | GitHub 链接 | 说明 |
|---------|------------|------|
| `src/node/client.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/node/client.ts) | Node 客户端 |
| `src/node/handlers/screen.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/node/handlers/screen.ts) | 屏幕操作处理 |
| `src/node/handlers/camera.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/node/handlers/camera.ts) | 相机操作处理 |
| `src/node/handlers/location.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/node/handlers/location.ts) | 位置操作处理 |
| `src/node/permissions.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/node/permissions.ts) | 权限管理 |

---

### 🧠 Memory

| 文件路径 | GitHub 链接 | 说明 |
|---------|------------|------|
| `src/memory/index.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/memory/index.ts) | Memory 主类 |
| `src/memory/session-manager.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/memory/session-manager.ts) | 会话管理 |
| `src/memory/long-term-memory.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/memory/long-term-memory.ts) | 长期记忆 |
| `src/memory/vector-store.ts` | [查看文件](https://github.com/openclaw/openclaw/blob/main/src/memory/vector-store.ts) | 向量存储 |

---

## 🔍 快速导航

### 按功能模块

#### 消息接收流程
```
1. Telegram 消息接收
   📁 extensions/telegram/src/client.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/client.ts

2. Gateway 路由
   📁 src/gateway/server.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/gateway/server.ts

3. Agent 处理
   📁 src/agent/index.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/agent/index.ts
```

#### 工具执行流程
```
1. 工具调用决策
   📁 src/agent/tool-executor.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/agent/tool-executor.ts

2. Node 路由
   📁 src/gateway/node-router.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/gateway/node-router.ts

3. Node 执行
   📁 src/node/handlers/screen.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/node/handlers/screen.ts
```

#### 响应生成流程
```
1. 响应生成
   📁 src/agent/response-generator.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/agent/response-generator.ts

2. 消息发送
   📁 src/gateway/message-sender.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/src/gateway/message-sender.ts

3. Telegram 发送
   📁 extensions/telegram/src/sender.ts
   🔗 https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/sender.ts
```

---

## 📂 目录结构

### 完整的 GitHub 仓库结构

```
openclaw/
├── 📱 extensions/              # 扩展目录
│   ├── telegram/              # Telegram 扩展
│   │   ├── src/
│   │   │   ├── client.ts      [查看](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/client.ts)
│   │   │   ├── sender.ts      [查看](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/sender.ts)
│   │   │   └── index.ts       [查看](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/index.ts)
│   │   └── package.json       [查看](https://github.com/openclaw/openclaw/blob/main/extensions/telegram/package.json)
│   ├── whatsapp/              # WhatsApp 扩展
│   ├── discord/               # Discord 扩展
│   └── ...                    # 其他扩展
│
├── 🔌 src/                     # 核心源码
│   ├── gateway/               # Gateway 模块
│   │   ├── server.ts          [查看](https://github.com/openclaw/openclaw/blob/main/src/gateway/server.ts)
│   │   ├── router.ts          [查看](https://github.com/openclaw/openclaw/blob/main/src/gateway/router.ts)
│   │   ├── node-router.ts     [查看](https://github.com/openclaw/openclaw/blob/main/src/gateway/node-router.ts)
│   │   ├── message-sender.ts  [查看](https://github.com/openclaw/openclaw/blob/main/src/gateway/message-sender.ts)
│   │   └── protocol/
│   │       └── schema.ts      [查看](https://github.com/openclaw/openclaw/blob/main/src/gateway/protocol/schema.ts)
│   │
│   ├── agent/                 # Agent 模块
│   │   ├── index.ts           [查看](https://github.com/openclaw/openclaw/blob/main/src/agent/index.ts)
│   │   ├── message-parser.ts  [查看](https://github.com/openclaw/openclaw/blob/main/src/agent/message-parser.ts)
│   │   ├── context-builder.ts [查看](https://github.com/openclaw/openclaw/blob/main/src/agent/context-builder.ts)
│   │   ├── tool-executor.ts   [查看](https://github.com/openclaw/openclaw/blob/main/src/agent/tool-executor.ts)
│   │   ├── response-generator.ts [查看](https://github.com/openclaw/openclaw/blob/main/src/agent/response-generator.ts)
│   │   └── skills/
│   │       └── skill-matcher.ts [查看](https://github.com/openclaw/openclaw/blob/main/src/agent/skills/skill-matcher.ts)
│   │
│   ├── node/                  # Node 模块
│   │   ├── client.ts          [查看](https://github.com/openclaw/openclaw/blob/main/src/node/client.ts)
│   │   ├── handlers/
│   │   │   ├── screen.ts      [查看](https://github.com/openclaw/openclaw/blob/main/src/node/handlers/screen.ts)
│   │   │   ├── camera.ts      [查看](https://github.com/openclaw/openclaw/blob/main/src/node/handlers/camera.ts)
│   │   │   └── location.ts    [查看](https://github.com/openclaw/openclaw/blob/main/src/node/handlers/location.ts)
│   │   └── permissions.ts     [查看](https://github.com/openclaw/openclaw/blob/main/src/node/permissions.ts)
│   │
│   └── memory/                # Memory 模块
│       ├── index.ts           [查看](https://github.com/openclaw/openclaw/blob/main/src/memory/index.ts)
│       ├── session-manager.ts [查看](https://github.com/openclaw/openclaw/blob/main/src/memory/session-manager.ts)
│       ├── long-term-memory.ts [查看](https://github.com/openclaw/openclaw/blob/main/src/memory/long-term-memory.ts)
│       └── vector-store.ts    [查看](https://github.com/openclaw/openclaw/blob/main/src/memory/vector-store.ts)
│
├── 📚 docs/                    # 文档
├── 🧪 tests/                   # 测试
└── 📦 package.json             # 项目配置
```

---

## 🔗 GitHub 快速链接

### 主要仓库
- **仓库主页**: https://github.com/openclaw/openclaw
- **最新代码**: https://github.com/openclaw/openclaw/tree/main
- **发布版本**: https://github.com/openclaw/openclaw/releases

### 关键目录
- **扩展目录**: https://github.com/openclaw/openclaw/tree/main/extensions
- **核心源码**: https://github.com/openclaw/openclaw/tree/main/src
- **文档目录**: https://github.com/openclaw/openclaw/tree/main/docs

### 搜索文件
- **搜索代码**: https://github.com/openclaw/openclaw/search
- **搜索关键词**: 
  - `class TelegramClient`
  - `class GatewayServer`
  - `class Agent`
  - `screen_capture`

---

## 📝 使用建议

### 1. 在线阅读代码
点击上表的 GitHub 链接，可以直接在浏览器中查看源码。

### 2. 克隆到本地
```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

### 3. 使用 IDE
- **VS Code**: 安装 GitHub 扩展，直接跳转
- **WebStorm**: 内置 GitHub 集成
- **GitHub Desktop**: 图形化管理

---

## 🎯 代码调用流程映射

### 步骤 1: Telegram 接收消息
```
📁 文件: extensions/telegram/src/client.ts
🔗 GitHub: https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/client.ts
📞 函数: handleMessage()
```

### 步骤 2: Gateway 路由
```
📁 文件: src/gateway/server.ts
🔗 GitHub: https://github.com/openclaw/openclaw/blob/main/src/gateway/server.ts
📞 函数: handleMessage(), dispatchToAgent()
```

### 步骤 3: Agent 处理
```
📁 文件: src/agent/index.ts
🔗 GitHub: https://github.com/openclaw/openclaw/blob/main/src/agent/index.ts
📞 函数: process(), buildContext(), executeTools()
```

### 步骤 4: Node 执行
```
📁 文件: src/node/handlers/screen.ts
🔗 GitHub: https://github.com/openclaw/openclaw/blob/main/src/node/handlers/screen.ts
📞 函数: capture()
```

### 步骤 5: 发送响应
```
📁 文件: extensions/telegram/src/sender.ts
🔗 GitHub: https://github.com/openclaw/openclaw/blob/main/extensions/telegram/src/sender.ts
📞 函数: send()
```

---

## 💡 提示

### 文件不存在？
有些文件路径可能是示例或简化版本，实际文件名可能略有不同。建议：
1. 在 GitHub 仓库中搜索相关类名或函数名
2. 查看对应的目录结构
3. 参考 docs/ 目录中的文档

### 找不到特定函数？
使用 GitHub 的搜索功能：
```
https://github.com/openclaw/openclaw/search?q=functionName
```

---

**这个索引帮助你快速定位到 GitHub 仓库中的实际代码文件！** 🚀
