# OpenClaw 代码调用流程图

> 从 Telegram 消息到截图返回的完整代码调用链

---

## 📊 完整代码调用链

```
┌─────────────────────────────────────────────────────────────────────────┐
│  1️⃣ Telegram Extension - 接收消息                                        │
│  📁 文件: extensions/telegram/src/client.ts                             │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class TelegramClient {                               │
    │    async handleMessage(ctx: Context) {                │
    │      // 1. 解析消息                                    │
    │      const message = this.parseMessage(ctx);          │
    │                                                        │
    │      // 2. 格式化为标准格式                             │
    │      const formatted = {                              │
    │        id: ctx.message.message_id,                    │
    │        channel: 'telegram',                           │
    │        userId: ctx.from.id.toString(),                │
    │        content: ctx.message.text,                     │
    │        timestamp: new Date()                          │
    │      };                                               │
    │                                                        │
    │      // 3. 发送到 Gateway                              │
    │      await this.gateway.send(formatted);              │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 🔌 WebSocket 发送
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2️⃣ Gateway - 路由消息                                                   │
│  📁 文件: src/gateway/server.ts                                          │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class GatewayServer {                                │
    │    async handleMessage(ws: WebSocket, data: any) {    │
    │      // 1. 验证消息格式                                │
    │      const validated = this.validateMessage(data);    │
    │                                                        │
    │      // 2. 路由决策                                    │
    │      const route = this.router.route(validated);      │
    │                                                        │
    │      // 3. 根据类型分发                                │
    │      switch (route.type) {                            │
    │        case 'chat':                                   │
    │          await this.dispatchToAgent(validated);       │
    │          break;                                       │
    │      }                                                │
    │    }                                                  │
    │                                                        │
    │    async dispatchToAgent(message: Message) {           │
    │      // 发送给 Agent                                   │
    │      const agent = this.agents.get(message.userId);   │
    │      await agent.process(message);                    │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 🤖 调用 Agent
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  3️⃣ Agent - 处理消息                                                     │
│  📁 文件: src/agent/index.ts                                             │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class Agent {                                         │
    │    async process(message: Message) {                   │
    │      // 1. 消息解析                                    │
    │      const parsed = await this.parseMessage(message); │
    │                                                        │
    │      // 2. 构建上下文                                  │
    │      const context = await this.buildContext(parsed); │
    │                                                        │
    │      // 3. 调用 LLM                                    │
    │      const response = await this.callLLM(context);    │
    │                                                        │
    │      // 4. 处理工具调用                                │
    │      if (response.toolCalls) {                        │
    │        const results = await this.executeTools(       │
    │          response.toolCalls,                          │
    │          context                                      │
    │        );                                             │
    │                                                        │
    │        // 5. 生成最终响应                              │
    │        return await this.generateResponse(results);   │
    │      }                                                │
    │    }                                                  │
    │                                                        │
    │    async buildContext(message: Message) {              │
    │      // 加载会话历史                                   │
    │      const history = await this.memory.getSession(    │
    │        message.sessionId                              │
    │      );                                               │
    │                                                        │
    │      // 检索相关记忆                                   │
    │      const memories = await this.memory.search(       │
    │        message.content                                │
    │      );                                               │
    │                                                        │
    │      // 匹配技能                                       │
    │      const skills = await this.matchSkills(message);  │
    │                                                        │
    │      return { history, memories, skills };            │
    │    }                                                  │
    │                                                        │
    │    async executeTools(toolCalls: ToolCall[]) {         │
    │      const results = [];                              │
    │                                                        │
    │      for (const call of toolCalls) {                  │
    │        // 检查是否需要 Node 执行                       │
    │        if (call.name.startsWith('screen_')) {         │
    │          const result = await this.executeOnNode(     │
    │            call                                       │
    │          );                                           │
    │          results.push(result);                        │
    │        }                                              │
    │      }                                                │
    │                                                        │
    │      return results;                                  │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 💻 调用 Node
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  4️⃣ Gateway - 路由到 Node                                                │
│  📁 文件: src/gateway/node-router.ts                                     │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class NodeRouter {                                    │
    │    async routeToNode(toolCall: ToolCall) {             │
    │      // 1. 查找可用的 Node                             │
    │      const node = this.findNode(toolCall);            │
    │                                                        │
    │      // 2. 发送命令到 Node                             │
    │      const response = await node.sendCommand({        │
    │        type: 'req',                                   │
    │        id: generateId(),                              │
    │        method: 'screen.record',                       │
    │        params: {                                      │
    │          action: 'capture',                           │
    │          display: 'primary'                           │
    │        }                                              │
    │      });                                              │
    │                                                        │
    │      return response;                                 │
    │    }                                                  │
    │                                                        │
    │    findNode(toolCall: ToolCall): Node {                │
    │      // 查找支持该工具的 Node                          │
    │      return this.nodes.find(node =>                   │
    │        node.caps.includes(toolCall.name)              │
    │      );                                               │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 🔌 WebSocket 发送到 Node
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  5️⃣ Node - 执行截图                                                      │
│  📁 文件: src/node/handlers/screen.ts                                    │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class ScreenHandler {                                 │
    │    async capture(params: ScreenParams) {               │
    │      // 1. 验证权限                                    │
    │      if (!this.hasPermission('screen.record')) {      │
    │        throw new Error('Permission denied');          │
    │      }                                                │
    │                                                        │
    │      // 2. 执行截图                                    │
    │      const filePath = `/tmp/screenshot_${Date.now()}.png`;│
    │                                                        │
    │      // macOS 使用 screencapture 命令                  │
    │      await exec(`screencapture -x ${filePath}`);      │
    │                                                        │
    │      // 3. 读取文件                                    │
    │      const stats = await fs.stat(filePath);           │
    │                                                        │
    │      // 4. 返回结果                                    │
    │      return {                                          │
    │        success: true,                                 │
    │        filePath,                                       │
    │        mimeType: 'image/png',                         │
    │        size: stats.size,                              │
    │        width: 2560,                                   │
    │        height: 1440                                   │
    │      };                                               │
    │    }                                                  │
    │  }                                                    │
    │                                                        │
    │  // Node 主入口                                        │
    │  class NodeClient {                                    │
    │    async handleCommand(command: Command) {             │
    │      const handler = this.handlers.get(command.method);│
    │      return await handler.execute(command.params);    │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 📤 返回结果
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  6️⃣ Agent - 生成响应                                                     │
│  📁 文件: src/agent/response-generator.ts                                │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class ResponseGenerator {                             │
    │    async generate(toolResults: ToolResult[]) {         │
    │      // 1. 构建工具结果消息                            │
    │      const toolMessage = {                            │
    │        role: 'tool',                                  │
    │        content: JSON.stringify(toolResults)           │
    │      };                                               │
    │                                                        │
    │      // 2. 再次调用 LLM                                │
    │      const response = await this.llm.generate({       │
    │        messages: [                                    │
    │          ...context.messages,                         │
    │          assistantMessage,                            │
    │          toolMessage                                  │
    │        ]                                              │
    │      });                                              │
    │                                                        │
    │      // 3. 构建响应                                    │
    │      return {                                         │
    │        text: response.content,                        │
    │        media: {                                       │
    │          type: 'photo',                               │
    │          url: `file://${toolResults[0].filePath}`     │
    │        }                                              │
    │      };                                               │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 📤 发送响应
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  7️⃣ Gateway - 发送到 Telegram Extension                                  │
│  📁 文件: src/gateway/message-sender.ts                                  │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class MessageSender {                                 │
    │    async send(response: Response) {                    │
    │      // 1. 查找目标 Extension                          │
    │      const extension = this.extensions.get('telegram');│
    │                                                        │
    │      // 2. 发送消息                                    │
    │      await extension.send({                           │
    │        to: response.userId,                           │
    │        message: response.text,                        │
    │        media: response.media                          │
    │      });                                              │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ 📱 发送到 Telegram
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  8️⃣ Telegram Extension - 发送消息                                        │
│  📁 文件: extensions/telegram/src/sender.ts                              │
└─────────────────────────────────────────────────────────────────────────┘
                             │
                             │ 📞 调用函数
                             ▼
    ┌──────────────────────────────────────────────────────┐
    │  class TelegramSender {                                │
    │    async send(params: SendParams) {                    │
    │      // 1. 准备消息                                    │
    │      const message = {                                │
    │        chat_id: params.to,                            │
    │        caption: params.message                        │
    │      };                                               │
    │                                                        │
    │      // 2. 如果有媒体文件                              │
    │      if (params.media) {                              │
    │        // 发送图片                                     │
    │        await this.bot.api.sendPhoto(                  │
    │          params.to,                                   │
    │          new InputFile(params.media.url),             │
    │          { caption: params.message }                  │
    │        );                                             │
    │      } else {                                         │
    │        // 发送文本                                     │
    │        await this.bot.api.sendMessage(                │
    │          params.to,                                   │
    │          params.message                               │
    │        );                                             │
    │      }                                                │
    │    }                                                  │
    │  }                                                    │
    └──────────────────────────────────────────────────────┘
                             │
                             │ ✅ 用户收到消息
                             ▼
                         [截图显示在 Telegram]
```

---

## 📁 关键文件路径

### Extension 层
```
extensions/
├── telegram/
│   ├── src/
│   │   ├── client.ts          # 接收消息
│   │   ├── sender.ts           # 发送消息
│   │   └── index.ts            # 扩展入口
│   └── package.json
```

### Gateway 层
```
src/
├── gateway/
│   ├── server.ts               # WebSocket 服务器
│   ├── router.ts               # 路由决策
│   ├── node-router.ts          # Node 路由
│   ├── message-sender.ts       # 消息发送
│   └── protocol/
│       └── schema.ts           # 协议定义
```

### Agent 层
```
src/
├── agent/
│   ├── index.ts                # Agent 主类
│   ├── message-parser.ts       # 消息解析
│   ├── context-builder.ts      # 上下文构建
│   ├── tool-executor.ts        # 工具执行
│   ├── response-generator.ts   # 响应生成
│   └── skills/
│       └── skill-matcher.ts    # 技能匹配
```

### Node 层
```
src/
├── node/
│   ├── client.ts               # Node 客户端
│   ├── handlers/
│   │   ├── screen.ts           # 屏幕操作
│   │   ├── camera.ts           # 相机操作
│   │   └── location.ts         # 位置操作
│   └── permissions.ts          # 权限管理
```

### Memory 层
```
src/
├── memory/
│   ├── index.ts                # Memory 主类
│   ├── session-manager.ts      # 会话管理
│   ├── long-term-memory.ts     # 长期记忆
│   └── vector-store.ts         # 向量存储
```

---

## 🔍 代码调用详解

### 步骤 1: Telegram 接收消息

**文件**: `extensions/telegram/src/client.ts`

```typescript
import { Context } from 'grammy';

export class TelegramClient {
  constructor(private gateway: Gateway) {}

  async handleMessage(ctx: Context) {
    // 解析 Telegram 消息
    const telegramMessage = ctx.message;
    
    // 转换为标准格式
    const standardMessage = {
      id: telegramMessage.message_id.toString(),
      channel: 'telegram',
      userId: ctx.from.id.toString(),
      chatId: ctx.chat.id.toString(),
      content: telegramMessage.text,
      timestamp: new Date(telegramMessage.date * 1000),
      metadata: {
        firstName: ctx.from.first_name,
        lastName: ctx.from.last_name,
        username: ctx.from.username
      }
    };
    
    // 发送到 Gateway
    await this.gateway.send(standardMessage);
  }
}
```

---

### 步骤 2: Gateway 路由消息

**文件**: `src/gateway/server.ts`

```typescript
import WebSocket from 'ws';

export class GatewayServer {
  private agents: Map<string, Agent>;
  private router: Router;

  async handleMessage(ws: WebSocket, data: string) {
    // 解析消息
    const message = JSON.parse(data);
    
    // 验证消息格式
    const validated = await this.validateMessage(message);
    
    // 路由决策
    const route = this.router.route(validated);
    
    // 根据类型分发
    switch (route.type) {
      case 'chat':
        await this.dispatchToAgent(validated);
        break;
      case 'command':
        await this.dispatchToCommand(validated);
        break;
      default:
        console.warn('Unknown message type:', route.type);
    }
  }

  private async dispatchToAgent(message: Message) {
    // 获取或创建 Agent 实例
    let agent = this.agents.get(message.userId);
    
    if (!agent) {
      agent = new Agent(this.config);
      this.agents.set(message.userId, agent);
    }
    
    // 处理消息
    const response = await agent.process(message);
    
    // 发送响应
    await this.sendResponse(message.userId, response);
  }
}
```

---

### 步骤 3: Agent 处理消息

**文件**: `src/agent/index.ts`

```typescript
export class Agent {
  private memory: Memory;
  private llm: LLM;
  private toolExecutor: ToolExecutor;

  async process(message: Message): Promise<Response> {
    // 1. 消息解析
    const parsed = await this.parseMessage(message);
    
    // 2. 构建上下文
    const context = await this.buildContext(parsed);
    
    // 3. 调用 LLM
    const response = await this.llm.generate({
      messages: [
        { role: 'system', content: context.systemPrompt },
        ...context.messages,
        { role: 'user', content: parsed.content }
      ],
      tools: context.tools
    });
    
    // 4. 处理工具调用
    if (response.toolCalls && response.toolCalls.length > 0) {
      const results = await this.executeTools(response.toolCalls, context);
      
      // 5. 生成最终响应
      return await this.generateFinalResponse(results, context);
    }
    
    // 6. 直接返回响应
    return {
      text: response.content,
      media: null
    };
  }

  private async buildContext(message: Message) {
    // 加载会话历史
    const history = await this.memory.getSession(message.sessionId);
    
    // 检索相关记忆
    const memories = await this.memory.search(message.content, {
      topK: 5,
      threshold: 0.7
    });
    
    // 匹配技能
    const skills = await this.matchSkills(message.content);
    
    // 准备工具
    const tools = this.prepareTools(skills);
    
    return {
      systemPrompt: this.getSystemPrompt(),
      messages: history,
      memories,
      skills,
      tools,
      currentUserMessage: message.content
    };
  }

  private async executeTools(toolCalls: ToolCall[], context: Context) {
    const results = [];
    
    for (const call of toolCalls) {
      // 检查工具类型
      if (this.isNodeTool(call.name)) {
        // 需要在 Node 上执行
        const result = await this.executeOnNode(call);
        results.push(result);
      } else {
        // 本地执行
        const result = await this.toolExecutor.execute(call);
        results.push(result);
      }
    }
    
    return results;
  }

  private async executeOnNode(toolCall: ToolCall) {
    // 通过 Gateway 发送到 Node
    const response = await this.gateway.sendToNode({
      type: 'req',
      id: generateId(),
      method: toolCall.name,
      params: toolCall.arguments
    });
    
    return response;
  }
}
```

---

### 步骤 4: Node 执行截图

**文件**: `src/node/handlers/screen.ts`

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';

const execAsync = promisify(exec);

export class ScreenHandler {
  async capture(params: ScreenParams): Promise<ScreenResult> {
    // 1. 验证权限
    if (!this.hasPermission('screen.record')) {
      throw new Error('Permission denied: screen.record');
    }
    
    // 2. 生成文件路径
    const timestamp = Date.now();
    const filePath = `/tmp/screenshot_${timestamp}.png`;
    
    // 3. 执行截图命令
    try {
      // macOS
      await execAsync(`screencapture -x ${filePath}`);
      
      // Linux (需要安装 scrot)
      // await execAsync(`scrot ${filePath}`);
      
      // Windows (需要安装第三方工具)
      // await execAsync(`nircmd.exe savescreenshot ${filePath}`);
    } catch (error) {
      throw new Error(`Screenshot failed: ${error.message}`);
    }
    
    // 4. 获取文件信息
    const stats = await fs.stat(filePath);
    
    // 5. 返回结果
    return {
      success: true,
      filePath,
      mimeType: 'image/png',
      size: stats.size,
      // 实际应用中可以获取实际分辨率
      width: 2560,
      height: 1440
    };
  }
}
```

---

### 步骤 5: 发送响应到 Telegram

**文件**: `extensions/telegram/src/sender.ts`

```typescript
import { InputFile } from 'grammy';

export class TelegramSender {
  constructor(private bot: Bot) {}

  async send(params: SendParams) {
    // 如果有媒体文件
    if (params.media) {
      await this.sendMedia(params);
    } else {
      await this.sendText(params);
    }
  }

  private async sendMedia(params: SendParams) {
    const { to, message, media } = params;
    
    switch (media.type) {
      case 'photo':
        await this.bot.api.sendPhoto(
          to,
          new InputFile(media.url.replace('file://', '')),
          { caption: message }
        );
        break;
        
      case 'video':
        await this.bot.api.sendVideo(
          to,
          new InputFile(media.url.replace('file://', '')),
          { caption: message }
        );
        break;
        
      case 'document':
        await this.bot.api.sendDocument(
          to,
          new InputFile(media.url.replace('file://', '')),
          { caption: message }
        );
        break;
    }
  }

  private async sendText(params: SendParams) {
    await this.bot.api.sendMessage(params.to, params.message);
  }
}
```

---

## 🔄 数据流转

### 消息格式演进

```
1. Telegram 原始消息
{
  message_id: 123,
  from: { id: 8583079349 },
  text: "帮我截图我的桌面"
}

↓

2. 标准消息格式
{
  id: "msg_123",
  channel: "telegram",
  userId: "8583079349",
  content: "帮我截图我的桌面",
  timestamp: "2026-03-13T11:03:00Z"
}

↓

3. Agent 上下文
{
  systemPrompt: "...",
  messages: [...],
  tools: [{ name: "screen_capture", ... }]
}

↓

4. LLM 响应
{
  toolCalls: [{
    name: "screen_capture",
    arguments: { display: "primary" }
  }]
}

↓

5. Node 执行结果
{
  success: true,
  filePath: "/tmp/screenshot_123.png",
  size: 1258291
}

↓

6. 最终响应
{
  text: "好的，我已经帮你截取了桌面截图。",
  media: {
    type: "photo",
    url: "file:///tmp/screenshot_123.png"
  }
}
```

---

## 🎯 调试技巧

### 1. 日志追踪

在每个关键点添加日志：

```typescript
// Telegram Extension
console.log('[Telegram] Received:', message.id);

// Gateway
console.log('[Gateway] Routing to Agent:', message.userId);

// Agent
console.log('[Agent] Processing:', message.content);
console.log('[Agent] LLM Response:', response);
console.log('[Agent] Tool Calls:', toolCalls);

// Node
console.log('[Node] Executing:', command.method);
console.log('[Node] Result:', result);
```

### 2. 断点位置

推荐断点位置：
- `TelegramClient.handleMessage()` - 消息接收
- `GatewayServer.dispatchToAgent()` - 路由决策
- `Agent.process()` - 消息处理
- `Agent.executeTools()` - 工具执行
- `ScreenHandler.capture()` - 截图执行
- `TelegramSender.send()` - 响应发送

### 3. 性能分析

使用 `console.time()` 跟踪耗时：

```typescript
console.time('agent-process');
const response = await agent.process(message);
console.timeEnd('agent-process');
```

---

## 📊 代码统计

| 模块 | 文件数 | 代码行数 | 说明 |
|------|--------|----------|------|
| Telegram Extension | 5 | ~500 | 消息接收和发送 |
| Gateway | 10 | ~1500 | 路由和分发 |
| Agent | 15 | ~3000 | 核心逻辑 |
| Node | 8 | ~1200 | 设备操作 |
| Memory | 6 | ~1000 | 记忆管理 |
| **总计** | **44** | **~7200** | 核心代码 |

---

## 💡 优化建议

### 1. 代码优化
- 使用缓存减少重复计算
- 异步并行处理
- 错误重试机制

### 2. 性能优化
- 连接池管理
- 批量处理消息
- 压缩传输数据

### 3. 可维护性
- 统一错误处理
- 完善日志记录
- 单元测试覆盖

---

**这个代码调用流程图帮助你快速定位和理解每个步骤的实现！** 🚀
