# Agent 助手详解

> Agent 是 OpenClaw 的智能核心，负责处理用户请求、管理对话上下文和生成响应。

---

## 📊 架构位置

```
┌─────────────────────────────────────────────┐
│         Gateway 网关层                       │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│           Agent 核心服务                     │
│  ┌──────────────────────────────────────┐   │
│  │  Message Handler (消息处理器)         │   │
│  ├──────────────────────────────────────┤   │
│  │  Context Builder (上下文构建器)       │   │
│  ├──────────────────────────────────────┤   │
│  │  Tool Executor (工具执行器)           │   │
│  ├──────────────────────────────────────┤   │
│  │  Response Streamer (响应流式器)       │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         Memory 记忆系统                      │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         AI 模型层                            │
│  OpenAI │ Anthropic │ GLM │ Gemini         │
└─────────────────────────────────────────────┘
```

---

## 🎯 核心职责

### 1. 消息处理

**入站消息流程**：
```
用户消息 → 解析 → 预处理 → 分类 → 路由
```

**消息类型**：
- **文本消息**：直接处理
- **命令消息**：执行特定命令
- **多媒体消息**：图像、音频、文件
- **系统消息**：配对、状态更新

### 2. 上下文构建

**上下文组成**：
```typescript
interface ConversationContext {
  // 系统提示
  systemPrompt: string;
  
  // 会话历史
  messages: Message[];
  
  // 记忆检索
  relevantMemories: Memory[];
  
  // 可用工具
  tools: Tool[];
  
  // 技能上下文
  skillContext?: SkillContext;
  
  // 用户偏好
  userPreferences?: Preferences;
}
```

**构建流程**：
1. **加载会话历史**
   - 从 Memory 系统检索
   - 限制 token 数量

2. **检索相关记忆**
   - 向量相似度搜索
   - 提取相关事实和决策

3. **加载技能**
   - 匹配相关技能
   - 注入技能上下文

4. **准备工具**
   - 列出可用工具
   - 定义工具 schema

### 3. 模型调用

**支持的模式**：
```typescript
// 1. 普通调用
const response = await model.generate(prompt);

// 2. 流式调用
for await (const chunk of model.stream(prompt)) {
  process.stdout.write(chunk);
}

// 3. 工具调用
const response = await model.generate(prompt, {
  tools: availableTools
});

// 如果模型请求工具
if (response.toolCalls) {
  const results = await executeTools(response.toolCalls);
  const finalResponse = await model.generate(prompt, {
    tools: availableTools,
    toolResults: results
  });
}
```

### 4. 工具执行

**工具调用流程**：
```
模型请求工具 → 验证权限 → 执行工具 → 返回结果 → 继续对话
```

**工具类型**：
1. **内置工具**
   - 网页搜索
   - 图像生成
   - 文件操作

2. **技能工具**
   - 天气查询
   - 编码助手
   - 系统控制

3. **渠道工具**
   - 发送消息
   - 上传文件
   - 管理群组

### 5. 响应生成

**流式响应**：
```typescript
// 通过 WebSocket 推送流式响应
gateway.broadcast({
  type: "event",
  event: "agent",
  payload: {
    runId: "run-123",
    status: "streaming",
    content: "这是流式响应的内容..."
  }
});

// 完成后发送最终响应
gateway.broadcast({
  type: "event",
  event: "agent",
  payload: {
    runId: "run-123",
    status: "complete",
    summary: "任务完成"
  }
});
```

---

## 🔄 工作流程

### 完整流程图

```
用户消息
    ↓
[1] 消息解析
    ├─ 提取文本
    ├─ 识别意图
    └─ 确定渠道
    ↓
[2] 上下文构建
    ├─ 加载会话历史
    ├─ 检索相关记忆
    ├─ 匹配技能
    └─ 准备工具
    ↓
[3] 模型调用
    ├─ 发送请求
    └─ 接收响应
    ↓
[4] 工具执行（如果需要）
    ├─ 验证权限
    ├─ 执行工具
    └─ 返回结果
    ↓
[5] 响应生成
    ├─ 流式输出
    └─ 发送给用户
    ↓
[6] 后处理
    ├─ 保存记忆
    ├─ 更新状态
    └─ 触发事件
```

---

## 🛠️ 配置

### 模型配置

```typescript
// agents.config.ts
export default {
  models: {
    default: "openai:gpt-4",
    fallback: "anthropic:claude-3",
    
    openai: {
      model: "gpt-4-turbo-preview",
      temperature: 0.7,
      maxTokens: 4096
    },
    
    anthropic: {
      model: "claude-3-opus-20240229",
      temperature: 0.7,
      maxTokens: 4096
    }
  }
};
```

### 认知配置

```typescript
// 思考模式
thinking: "low" | "medium" | "high"

// low: 快速响应，简单任务
// medium: 平衡模式，大多数情况
// high: 深度思考，复杂任务
```

---

## 🎨 技能系统集成

### 技能匹配

```typescript
// 1. 基于描述匹配
const skills = matchSkills(userMessage, {
  threshold: 0.7,
  maxSkills: 3
});

// 2. 读取 SKILL.md
const skillContext = loadSkillContext(skill);

// 3. 注入到上下文
context.skillContext = skillContext;
context.tools.push(...skill.tools);
```

### 工具定义

```typescript
// 技能提供的工具
interface SkillTool {
  name: string;
  description: string;
  parameters: JSONSchema;
  execute: (params: any) => Promise<any>;
}

// 示例：天气查询工具
const weatherTool: SkillTool = {
  name: "get_weather",
  description: "获取指定城市的天气信息",
  parameters: {
    type: "object",
    properties: {
      city: {
        type: "string",
        description: "城市名称"
      }
    },
    required: ["city"]
  },
  execute: async (params) => {
    const weather = await fetchWeather(params.city);
    return weather;
  }
};
```

---

## 📊 性能优化

### 1. 上下文压缩

```typescript
// 限制 token 数量
const MAX_CONTEXT_TOKENS = 8000;

// 智能裁剪
function trimContext(messages: Message[]): Message[] {
  // 保留最近的对话
  // 压缩旧消息
  // 删除不相关内容
}
```

### 2. 并行处理

```typescript
// 并行加载上下文
const [history, memories, skills] = await Promise.all([
  loadHistory(sessionId),
  searchMemories(query),
  matchSkills(message)
]);
```

### 3. 缓存策略

```typescript
// 缓存常用数据
const cache = new LRUCache({
  max: 1000,
  ttl: 60000 // 1 分钟
});

// 缓存技能描述
// 缓存工具 schema
// 缓存用户偏好
```

---

## 🔍 调试技巧

### 1. 查看上下文

```bash
# 启动时打印上下文
openclaw agent --debug-context

# 查看发送给模型的完整内容
```

### 2. 工具调用日志

```bash
# 启用工具调用日志
openclaw agent --log-tools

# 查看工具请求和响应
```

### 3. 流式响应

```bash
# 实时查看流式输出
openclaw agent --verbose
```

---

## 🐛 常见问题

### 1. 响应太慢

**原因**：
- 上下文太大
- 模型响应慢
- 工具执行慢

**解决**：
- 压缩上下文
- 使用更快的模型
- 优化工具性能

### 2. 上下文丢失

**原因**：
- 会话超时
- Memory 系统问题
- Token 限制

**解决**：
- 增加会话时长
- 检查 Memory 系统
- 优化上下文管理

### 3. 工具调用失败

**原因**：
- 权限不足
- 参数错误
- 工具 bug

**解决**：
- 检查权限配置
- 验证参数 schema
- 查看工具日志

---

## 🔗 相关资源

- [Memory 记忆系统](memory.md)
- [Skills 技能系统](skills.md)
- [工具开发指南](../practice/tool-development.md)

---

**上一章**：[Gateway 网关](gateway.md)  
**下一章**：[Memory 记忆](memory.md)
