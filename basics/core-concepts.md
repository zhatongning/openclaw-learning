# 核心概念

## 🎯 OpenClaw 的核心组件

OpenClaw 由几个核心组件构成，每个组件都有明确的职责：

```
┌─────────────────────────────────────────────┐
│            用户层 (User Layer)               │
│  macOS App │ iOS │ Android │ CLI │ Web     │
└─────────────────────────────────────────────┘
                    ↓↑ WebSocket
┌─────────────────────────────────────────────┐
│         Gateway 网关层 (Control Plane)       │
│  认证 │ 配对 │ 协议 │ 会话 │ 事件分发        │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         核心服务层 (Core Services)           │
│  Agent │ Memory │ Skills │ Plugins          │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         消息渠道层 (Channel Layer)           │
│  Telegram │ WhatsApp │ Discord │ Slack ...  │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│          AI 模型层 (Model Layer)             │
│  OpenAI │ Anthropic │ GLM │ Gemini          │
└─────────────────────────────────────────────┘
```

---

## 1. Gateway（网关）

**职责**：
- 维护所有消息渠道的连接
- 暴露 WebSocket API
- 处理认证和配对
- 分发事件和消息

**关键特性**：
- 单例模式：每台主机一个 Gateway
- 长期运行：作为守护进程（daemon）
- 协议驱动：基于 TypeBox 定义

**详细说明**：[Gateway 网关](../architecture/gateway.md)

---

## 2. Agent（AI 助手）

**职责**：
- 处理用户的自然语言请求
- 管理对话上下文
- 调用技能和工具
- 流式响应

**工作流程**：
```
用户消息 → 解析 → 上下文构建 → 模型调用 → 工具执行 → 响应生成
```

**详细说明**：[Agent 助手](../architecture/agent.md)

---

## 3. Memory（记忆系统）

**职责**：
- 短期记忆（会话级）
- 长期记忆（持久化）
- 向量检索（语义搜索）

**存储类型**：
- **短期记忆**：当前会话的对话历史
- **长期记忆**：重要的事实和决策
- **向量存储**：用于语义检索的嵌入向量

**详细说明**：[Memory 记忆](../architecture/memory.md)

---

## 4. Skills（技能）

**职责**：
- 定义特定的能力
- 提供工具接口
- 封装复杂逻辑

**结构**：
```
skill-name/
├── SKILL.md              # 技能定义
├── index.ts              # 实现
└── package.json          # 依赖
```

**详细说明**：[Skills 技能](../architecture/skills.md)

---

## 5. Extensions（扩展）

**职责**：
- 集成外部服务
- 扩展核心功能
- 添加新渠道

**类型**：
1. **渠道扩展**：Telegram、WhatsApp、Discord 等
2. **功能扩展**：向量存储、语音通话等

**详细说明**：[Extensions 扩展](../architecture/extensions.md)

---

## 6. Channels（消息渠道）

**支持的渠道**：
- **Telegram** - grammY 框架
- **WhatsApp** - Baileys 库
- **Discord** - discord.js
- **Slack** - Slack Bolt
- **Signal** - Signal CLI
- **iMessage** - BlueBubbles
- 更多...

**统一抽象**：
```typescript
interface MessageChannel {
  send(message: Message): Promise<void>;
  on(event: 'message', handler: (msg: Message) => void): void;
  getInfo(): ChannelInfo;
}
```

---

## 7. Plugins（插件）

**职责**：
- 动态加载功能模块
- 生命周期管理
- 依赖注入

**生命周期**：
```
load → initialize → start → [运行] → stop → unload
```

**详细说明**：[Plugins 插件](../architecture/plugins.md)

---

## 🔄 数据流

### 入站消息流

```
用户 → 渠道 → Gateway → Agent → Memory → Model → 
Agent → Skills → Gateway → 渠道 → 用户
```

### 连接生命周期

```
Client → connect → Gateway (hello-ok) → 
订阅事件 → 请求/响应循环 → 关闭
```

---

## 📚 学习建议

### 初学者路径
1. 理解 Gateway 的作用
2. 学习 Agent 的工作原理
3. 了解 Memory 系统
4. 尝试创建一个简单的 Skill

### 进阶路径
1. 深入研究渠道扩展
2. 理解插件加载机制
3. 学习协议设计
4. 参与核心功能开发

---

## 🔗 相关资源

- [整体架构](../architecture/overview.md)
- [Gateway 详解](../architecture/gateway.md)
- [Agent 详解](../architecture/agent.md)
- [实践指南](../practice/setup.md)
