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

#### 入站消息流程
```
用户消息 → 解析 → 预处理 → 分类 → 路由
```

#### 消息类型
- **文本消息**：直接处理
- **命令消息**：执行特定命令
- **多媒体消息**：图像、音频、文件
- **系统消息**：配对、状态更新

#### 源码实现
```typescript
class MessageHandler {
  async handle(message: Message): Promise<Response> {
    // 1. 解析消息
    const parsed = this.parseMessage(message);
    
    // 2. 预处理
    const preprocessed = await this.preprocess(parsed);
    
    // 3. 分类
    const type = this.classify(preprocessed);
    
    // 4. 路由到对应处理器
    switch (type) {
      case 'text':
        return this.handleText(preprocessed);
      case 'command':
        return this.handleCommand(preprocessed);
      case 'media':
        return this.handleMedia(preprocessed);
      default:
        throw new Error('Unknown message type');
    }
  }
  
  private parseMessage(message: Message): ParsedMessage {
    return {
      id: message.id,
      content: message.content,
      type: message.type,
      channelId: message.channelId,
      userId: message.userId,
      timestamp: message.timestamp
    };
  }
  
  private async preprocess(message: ParsedMessage): Promise<PreprocessedMessage> {
    // 清理文本
    // 提取实体
    // 识别语言
    return {
      ...message,
      cleanedContent: this.cleanText(message.content),
      entities: await this.extractEntities(message.content),
      language: await this.detectLanguage(message.content)
    };
  }
}
```

---

### 2. 上下文构建

#### 上下文组成
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
  
  // Token 统计
  tokenCount: number;
}
```

#### 构建流程
```typescript
class ContextBuilder {
  async build(sessionId: string, userMessage: Message): Promise<ConversationContext> {
    // 1. 加载系统提示
    const systemPrompt = await this.loadSystemPrompt();
    
    // 2. 加载会话历史（并行）
    const [history, memories, skills, preferences] = await Promise.all([
      this.loadHistory(sessionId),
      this.searchMemories(userMessage),
      this.matchSkills(userMessage),
      this.loadPreferences(userMessage.userId)
    ]);
    
    // 3. 准备工具
    const tools = this.prepareTools(skills);
    
    // 4. 构建 context
    const context: ConversationContext = {
      systemPrompt,
      messages: history,
      relevantMemories: memories,
      tools,
      skillContext: this.buildSkillContext(skills),
      userPreferences: preferences,
      tokenCount: 0
    };
    
    // 5. 计算 token 数
    context.tokenCount = this.countTokens(context);
    
    // 6. 压缩（如果超过限制）
    if (context.tokenCount > this.maxTokens) {
      return this.compress(context);
    }
    
    return context;
  }
  
  private async loadHistory(sessionId: string): Promise<Message[]> {
    // 从 Memory 系统加载
    const messages = await this.memory.getSession(sessionId);
    
    // 限制数量
    return messages.slice(-this.maxHistoryMessages);
  }
  
  private async searchMemories(message: Message): Promise<Memory[]> {
    // 向量相似度搜索
    const query = message.content;
    const results = await this.vectorStore.search(query, {
      topK: 5,
      threshold: 0.7
    });
    
    return results;
  }
  
  private async matchSkills(message: Message): Promise<Skill[]> {
    // 基于描述匹配
    const skills = await this.skillMatcher.match(message.content, {
      threshold: 0.7,
      maxSkills: 3
    });
    
    return skills;
  }
  
  private prepareTools(skills: Skill[]): Tool[] {
    // 合并所有工具
    const tools = [
      ...this.builtInTools,
      ...skills.flatMap(s => s.tools)
    ];
    
    // 去重
    return this.deduplicateTools(tools);
  }
  
  private compress(context: ConversationContext): ConversationContext {
    // 智能压缩策略
    // 1. 保留最近的对话
    // 2. 压缩旧消息（摘要）
    // 3. 删除不相关记忆
    
    let messages = context.messages;
    let tokenCount = context.tokenCount;
    
    // 压缩直到满足 token 限制
    while (tokenCount > this.maxTokens && messages.length > 2) {
      // 移除中间的消息
      const removed = messages.splice(1, 1)[0];
      tokenCount -= this.countTokens(removed);
    }
    
    return {
      ...context,
      messages,
      tokenCount
    };
  }
}
```

---

### 3. 模型调用

#### 支持的模式
```typescript
class ModelCaller {
  // 1. 普通调用
  async generate(prompt: string): Promise<string> {
    const response = await this.model.generate({
      messages: [{ role: 'user', content: prompt }],
      temperature: this.config.temperature,
      maxTokens: this.config.maxTokens
    });
    
    return response.content;
  }
  
  // 2. 流式调用
  async *stream(prompt: string): AsyncGenerator<string> {
    const stream = await this.model.stream({
      messages: [{ role: 'user', content: prompt }],
      temperature: this.config.temperature,
      maxTokens: this.config.maxTokens
    });
    
    for await (const chunk of stream) {
      yield chunk.content;
    }
  }
  
  // 3. 工具调用
  async generateWithTools(context: ConversationContext): Promise<Response> {
    let iterations = 0;
    const maxIterations = 5;
    
    while (iterations < maxIterations) {
      // 调用模型
      const response = await this.model.generate({
        messages: [
          { role: 'system', content: context.systemPrompt },
          ...context.messages,
          { role: 'user', content: context.currentUserMessage }
        ],
        tools: context.tools,
        temperature: this.config.temperature
      });
      
      // 检查是否请求工具
      if (response.toolCalls && response.toolCalls.length > 0) {
        // 执行工具
        const toolResults = await this.executeTools(response.toolCalls, context);
        
        // 添加到消息历史
        context.messages.push({
          role: 'assistant',
          content: response.content,
          toolCalls: response.toolCalls
        });
        
        context.messages.push({
          role: 'tool',
          content: JSON.stringify(toolResults)
        });
        
        iterations++;
        continue;
      }
      
      // 没有工具调用，返回最终响应
      return response;
    }
    
    throw new Error('Max iterations exceeded');
  }
}
```

#### 模型选择策略
```typescript
class ModelSelector {
  selectModel(task: Task): Model {
    // 根据任务类型选择模型
    switch (task.type) {
      case 'coding':
        return this.models.get('gpt-4-turbo');
      
      case 'creative':
        return this.models.get('claude-3-opus');
      
      case 'simple':
        return this.models.get('gpt-3.5-turbo');
      
      default:
        return this.models.get(this.config.defaultModel);
    }
  }
  
  // 认知模式配置
  getCognitiveConfig(thinking: 'low' | 'medium' | 'high') {
    switch (thinking) {
      case 'low':
        return {
          temperature: 0.3,
          maxTokens: 1024,
          frequencyPenalty: 0
        };
      
      case 'medium':
        return {
          temperature: 0.7,
          maxTokens: 2048,
          frequencyPenalty: 0.3
        };
      
      case 'high':
        return {
          temperature: 1.0,
          maxTokens: 4096,
          frequencyPenalty: 0.5
        };
    }
  }
}
```

---

### 4. 工具执行

#### 工具调用流程
```
模型请求工具 → 验证权限 → 执行工具 → 返回结果 → 继续对话
```

#### 源码实现
```typescript
class ToolExecutor {
  private tools: Map<string, Tool> = new Map();
  
  registerTool(tool: Tool) {
    this.tools.set(tool.name, tool);
  }
  
  async execute(toolCalls: ToolCall[], context: ConversationContext): Promise<ToolResult[]> {
    const results: ToolResult[] = [];
    
    for (const call of toolCalls) {
      const tool = this.tools.get(call.name);
      
      if (!tool) {
        results.push({
          toolCallId: call.id,
          error: `Tool ${call.name} not found`
        });
        continue;
      }
      
      // 验证权限
      if (!this.hasPermission(context, tool)) {
        results.push({
          toolCallId: call.id,
          error: 'Permission denied'
        });
        continue;
      }
      
      // 验证参数
      const validation = this.validateParameters(tool, call.arguments);
      if (!validation.valid) {
        results.push({
          toolCallId: call.id,
          error: `Invalid parameters: ${validation.errors.join(', ')}`
        });
        continue;
      }
      
      try {
        // 执行工具
        const result = await tool.execute(call.arguments);
        
        results.push({
          toolCallId: call.id,
          result
        });
      } catch (error) {
        results.push({
          toolCallId: call.id,
          error: error.message
        });
      }
    }
    
    return results;
  }
  
  private hasPermission(context: ConversationContext, tool: Tool): boolean {
    // 检查用户权限
    // 检查渠道限制
    // 检查技能权限
    return true;
  }
  
  private validateParameters(tool: Tool, args: any): ValidationResult {
    // 使用 JSON Schema 验证
    const validator = new Validator(tool.parameters);
    return validator.validate(args);
  }
}
```

#### 工具定义示例
```typescript
// 网页搜索工具
const webSearchTool: Tool = {
  name: 'web_search',
  description: '搜索互联网获取信息',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: '搜索关键词'
      },
      count: {
        type: 'number',
        description: '返回结果数量',
        default: 5
      }
    },
    required: ['query']
  },
  execute: async (params) => {
    const results = await searchEngine.search(params.query, {
      count: params.count || 5
    });
    
    return {
      results: results.map(r => ({
        title: r.title,
        url: r.url,
        snippet: r.snippet
      }))
    };
  }
};

// 天气查询工具
const weatherTool: Tool = {
  name: 'get_weather',
  description: '获取指定城市的天气信息',
  parameters: {
    type: 'object',
    properties: {
      city: {
        type: 'string',
        description: '城市名称'
      },
      unit: {
        type: 'string',
        enum: ['celsius', 'fahrenheit'],
        default: 'celsius'
      }
    },
    required: ['city']
  },
  execute: async (params) => {
    const weather = await weatherAPI.get(params.city, params.unit);
    
    return {
      city: params.city,
      temperature: weather.temp,
      condition: weather.condition,
      humidity: weather.humidity
    };
  }
};
```

---

### 5. 响应生成

#### 流式响应实现
```typescript
class ResponseStreamer {
  async stream(
    context: ConversationContext,
    gateway: Gateway
  ): Promise<void> {
    const runId = generateRunId();
    
    // 开始流式生成
    const stream = await this.modelCaller.stream(context);
    
    let fullContent = '';
    let seq = 0;
    
    for await (const chunk of stream) {
      fullContent += chunk;
      seq++;
      
      // 推送流式事件
      gateway.broadcast({
        type: 'event',
        event: 'agent',
        payload: {
          runId,
          seq,
          status: 'streaming',
          content: chunk,
          ts: Date.now()
        }
      });
    }
    
    // 发送完成事件
    gateway.broadcast({
      type: 'event',
      event: 'agent',
      payload: {
        runId,
        seq: seq + 1,
        status: 'complete',
        content: '',
        ts: Date.now()
      }
    });
    
    // 保存到记忆
    await this.saveToMemory(context, fullContent);
  }
  
  private async saveToMemory(context: ConversationContext, response: string) {
    // 保存用户消息
    await this.memory.add({
      sessionId: context.sessionId,
      role: 'user',
      content: context.currentUserMessage
    });
    
    // 保存助手响应
    await this.memory.add({
      sessionId: context.sessionId,
      role: 'assistant',
      content: response
    });
    
    // 提取并保存重要记忆
    const memories = await this.extractMemories(response);
    for (const memory of memories) {
      await this.memory.save(memory);
    }
  }
}
```

---

## 🔄 完整工作流程

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
    ├─ 选择模型
    ├─ 配置参数
    └─ 发送请求
    ↓
[4] 工具执行（如果需要）
    ├─ 验证权限
    ├─ 执行工具
    └─ 返回结果
    ↓
[5] 响应生成
    ├─ 流式输出
    ├─ 推送事件
    └─ 发送给用户
    ↓
[6] 后处理
    ├─ 保存记忆
    ├─ 更新状态
    ├─ 触发事件
    └─ 清理资源
```

### 伪代码实现
```typescript
class Agent {
  async process(userMessage: Message): Promise<void> {
    const runId = generateRunId();
    
    try {
      // 1. 解析消息
      const parsed = await this.messageHandler.handle(userMessage);
      
      // 2. 构建上下文
      const context = await this.contextBuilder.build(
        userMessage.sessionId,
        userMessage
      );
      
      // 3. 模型调用循环
      let iterations = 0;
      const maxIterations = 5;
      
      while (iterations < maxIterations) {
        // 调用模型
        const response = await this.modelCaller.generateWithTools(context);
        
        // 如果有工具调用
        if (response.toolCalls) {
          // 执行工具
          const toolResults = await this.toolExecutor.execute(
            response.toolCalls,
            context
          );
          
          // 添加到上下文
          context.messages.push({
            role: 'assistant',
            toolCalls: response.toolCalls
          });
          
          context.messages.push({
            role: 'tool',
            content: JSON.stringify(toolResults)
          });
          
          iterations++;
          continue;
        }
        
        // 没有工具调用，生成最终响应
        await this.responseStreamer.stream(context, this.gateway);
        break;
      }
      
      // 6. 后处理
      await this.postProcess(context, runId);
      
    } catch (error) {
      // 错误处理
      await this.handleError(error, runId);
    }
  }
  
  private async postProcess(context: ConversationContext, runId: string) {
    // 保存记忆
    await this.memory.saveSession(context.sessionId, context.messages);
    
    // 更新统计
    await this.updateStats(runId);
    
    // 触发事件
    this.eventBus.emit('agent:complete', { runId, context });
  }
}
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
      maxTokens: 4096,
      topP: 1,
      frequencyPenalty: 0,
      presencePenalty: 0
    },
    
    anthropic: {
      model: "claude-3-opus-20240229",
      temperature: 0.7,
      maxTokens: 4096,
      topK: 40
    },
    
    glm: {
      model: "glm-4",
      temperature: 0.7,
      maxTokens: 4096
    }
  },
  
  // 上下文配置
  context: {
    maxTokens: 8000,
    maxHistoryMessages: 20,
    compressionThreshold: 0.9  // 90% 时开始压缩
  },
  
  // 工具配置
  tools: {
    maxIterations: 5,
    timeout: 30000,  // 30 秒
    parallelExecution: true
  }
};
```

### 认知配置
```typescript
// 思考模式
thinking: "low" | "medium" | "high"

// 配置映射
const thinkingConfigs = {
  low: {
    temperature: 0.3,
    maxTokens: 1024,
    responseSpeed: 'fast'
  },
  
  medium: {
    temperature: 0.7,
    maxTokens: 2048,
    responseSpeed: 'balanced'
  },
  
  high: {
    temperature: 1.0,
    maxTokens: 4096,
    responseSpeed: 'thorough'
  }
};
```

---

## 🎨 技能系统集成

### 技能匹配
```typescript
class SkillMatcher {
  private skills: Skill[] = [];
  
  async match(message: string, options: MatchOptions): Promise<Skill[]> {
    // 1. 生成查询向量
    const queryVector = await this.embed(message);
    
    // 2. 计算相似度
    const scores = this.skills.map(skill => ({
      skill,
      score: this.cosineSimilarity(queryVector, skill.vector)
    }));
    
    // 3. 过滤和排序
    const filtered = scores
      .filter(s => s.score >= options.threshold)
      .sort((a, b) => b.score - a.score)
      .slice(0, options.maxSkills);
    
    return filtered.map(f => f.skill);
  }
  
  private cosineSimilarity(a: number[], b: number[]): number {
    // 向量点积 / (|a| * |b|)
    const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
    const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
    const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
    
    return dotProduct / (magnitudeA * magnitudeB);
  }
}
```

### 工具注入
```typescript
class SkillLoader {
  async loadSkill(skillPath: string): Promise<Skill> {
    // 1. 读取 SKILL.md
    const skillMd = await fs.readFile(`${skillPath}/SKILL.md`, 'utf-8');
    
    // 2. 解析元数据
    const metadata = this.parseMetadata(skillMd);
    
    // 3. 加载工具
    const tools = await this.loadTools(skillPath);
    
    // 4. 构建技能对象
    const skill: Skill = {
      name: metadata.name,
      description: metadata.description,
      vector: await this.embed(metadata.description),
      tools,
      context: skillMd
    };
    
    return skill;
  }
  
  private async loadTools(skillPath: string): Promise<Tool[]> {
    // 动态加载工具模块
    const toolPath = `${skillPath}/tools`;
    const files = await fs.readdir(toolPath);
    
    const tools: Tool[] = [];
    
    for (const file of files) {
      if (file.endsWith('.js') || file.endsWith('.ts')) {
        const module = await import(`${toolPath}/${file}`);
        if (module.default && this.isTool(module.default)) {
          tools.push(module.default);
        }
      }
    }
    
    return tools;
  }
}
```

---

## 📊 性能优化

### 1. 上下文压缩
```typescript
class ContextCompressor {
  compress(context: ConversationContext): ConversationContext {
    let messages = [...context.messages];
    let tokenCount = context.tokenCount;
    
    while (tokenCount > this.maxTokens && messages.length > 2) {
      // 策略 1: 移除中间消息
      if (messages.length > 4) {
        const removed = messages.splice(2, 1)[0];
        tokenCount -= this.countTokens(removed);
        continue;
      }
      
      // 策略 2: 压缩旧消息（摘要）
      if (messages.length > 2) {
        const summary = await this.summarize(messages.slice(0, -1));
        messages = [
          { role: 'system', content: `Previous conversation summary: ${summary}` },
          messages[messages.length - 1]
        ];
        tokenCount = this.countTokens(messages);
        continue;
      }
      
      break;
    }
    
    return { ...context, messages, tokenCount };
  }
  
  private async summarize(messages: Message[]): Promise<string> {
    // 使用模型生成摘要
    const prompt = `Summarize the following conversation:\n${messages.map(m => m.content).join('\n')}`;
    return await this.model.generate(prompt, { maxTokens: 200 });
  }
}
```

### 2. 并行处理
```typescript
class ParallelLoader {
  async loadAll(sessionId: string, message: Message): Promise<LoadedData> {
    // 并行加载所有数据
    const [history, memories, skills, preferences] = await Promise.all([
      this.loadHistory(sessionId),
      this.searchMemories(message),
      this.matchSkills(message),
      this.loadPreferences(message.userId)
    ]);
    
    return { history, memories, skills, preferences };
  }
}
```

### 3. 缓存策略
```typescript
class CacheManager {
  private cache = new LRUCache<string, any>({
    max: 1000,
    ttl: 60000  // 1 分钟
  });
  
  async getOrLoad<T>(key: string, loader: () => Promise<T>): Promise<T> {
    // 尝试从缓存获取
    const cached = this.cache.get(key);
    if (cached !== undefined) {
      return cached;
    }
    
    // 加载数据
    const data = await loader();
    
    // 存入缓存
    this.cache.set(key, data);
    
    return data;
  }
}

// 使用示例
const skills = await cacheManager.getOrLoad(
  `skills:${messageHash}`,
  () => skillMatcher.match(message, options)
);
```

---

## 🔍 调试技巧

### 1. 查看上下文
```bash
# 启动时打印上下文
openclaw agent --debug-context

# 查看发送给模型的完整内容
openclaw agent --debug-context --verbose
```

### 2. 工具调用日志
```bash
# 启用工具调用日志
openclaw agent --log-tools

# 查看工具请求和响应
tail -f ~/.openclaw/logs/agent.log | grep "tool_call"
```

### 3. 流式响应
```bash
# 实时查看流式输出
openclaw agent --verbose

# 保存到文件
openclaw agent --verbose > agent.log 2>&1
```

### 4. 性能分析
```bash
# 启用性能分析
openclaw agent --profile

# 查看性能报告
openclaw agent --profile-report
```

---

## 🐛 常见问题

### 1. 响应太慢
**原因**：
- 上下文太大
- 模型响应慢
- 工具执行慢

**解决**：
```typescript
// 优化上下文
context = contextCompressor.compress(context);

// 使用更快的模型
modelSelector.selectModel({ type: 'simple' });

// 优化工具
toolExecutor.setTimeout(5000);  // 5 秒超时
```

### 2. 上下文丢失
**原因**：
- 会话超时
- Memory 系统问题
- Token 限制

**解决**：
```typescript
// 增加会话时长
config.sessionTimeout = 7200000;  // 2 小时

// 检查 Memory 系统
await memory.healthCheck();

// 优化上下文管理
contextBuilder.setMaxTokens(8000);
```

### 3. 工具调用失败
**原因**：
- 权限不足
- 参数错误
- 工具 bug

**解决**：
```typescript
// 检查权限
const hasPermission = await permissionChecker.check(userId, toolName);

// 验证参数
const validation = validateParameters(tool, params);

// 查看日志
const logs = await toolExecutor.getLogs(toolCallId);
```

### 4. 模型调用错误
**原因**：
- API 错误
- 超时
- Token 限制

**解决**：
```typescript
// 重试机制
const response = await retry(
  () => model.generate(prompt),
  { maxRetries: 3, delay: 1000 }
);

// 超时处理
const response = await Promise.race([
  model.generate(prompt),
  timeout(30000)
]);

// Token 限制
if (context.tokenCount > model.maxTokens) {
  context = compressor.compress(context);
}
```

---

## 🔗 相关资源
- [Memory 记忆系统](memory.md)
- [Skills 技能系统](skills.md)
- [工具开发指南](../practice/tool-development.md)
- [Agent 源码](https://github.com/openclaw/openclaw/tree/main/src/agent)

---

**上一章**：[Gateway 网关](gateway.md)  
**下一章**：[Memory 记忆](memory.md)
