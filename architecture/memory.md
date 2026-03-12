# Memory 记忆系统详解

> Memory 系统负责管理对话历史、长期记忆和向量检索，是 Agent 智能的核心支撑。

---

## 📊 架构位置

```
┌─────────────────────────────────────────────┐
│           Agent 核心服务                     │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         Memory 记忆系统                      │
│  ┌──────────────────────────────────────┐   │
│  │  Short-term Memory (短期记忆)         │   │
│  ├──────────────────────────────────────┤   │
│  │  Long-term Memory (长期记忆)          │   │
│  ├──────────────────────────────────────┤   │
│  │  Vector Store (向量存储)              │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         存储后端                             │
│  SQLite │ LanceDB │ 自定义存储             │
└─────────────────────────────────────────────┘
```

---

## 🎯 核心职责

### 1. 短期记忆（Short-term Memory）

**作用**：
- 存储当前会话的对话历史
- 提供快速访问
- 自动过期

**数据结构**：
```typescript
interface ShortTermMemory {
  // 会话 ID
  sessionId: string;
  
  // 对话历史
  messages: Message[];
  
  // 上下文信息
  context: {
    userId: string;
    channelId: string;
    startedAt: Date;
    lastActivity: Date;
  };
  
  // 元数据
  metadata: {
    messageCount: number;
    tokenCount: number;
  };
}
```

**存储位置**：
- 内存（快速访问）
- SQLite（持久化）

**生命周期**：
- 会话开始时创建
- 持续更新
- 会话结束后归档或删除

---

### 2. 长期记忆（Long-term Memory）

**作用**：
- 存储重要的事实和决策
- 跨会话持久化
- 提供长期上下文

**数据结构**：
```typescript
interface LongTermMemory {
  // 记忆 ID
  id: string;
  
  // 记忆类型
  type: "fact" | "decision" | "preference" | "event";
  
  // 内容
  content: string;
  
  // 重要性
  importance: number; // 0-1
  
  // 来源
  source: {
    sessionId: string;
    timestamp: Date;
    userId?: string;
  };
  
  // 元数据
  metadata: {
    tags: string[];
    category: string;
    accessCount: number;
    lastAccessed: Date;
  };
}
```

**记忆类型**：
1. **Fact（事实）**
   - 用户的偏好
   - 重要的信息
   - 系统配置

2. **Decision（决策）**
   - 重要决定
   - 选择原因
   - 结果反馈

3. **Preference（偏好）**
   - 用户习惯
   - 个性化设置
   - 默认选择

4. **Event（事件）**
   - 重要事件
   - 时间线
   - 里程碑

---

### 3. 向量存储（Vector Store）

**作用**：
- 语义搜索
- 相似度检索
- 智能推荐

**实现**：
```typescript
interface VectorStore {
  // 嵌入向量
  embeddings: number[][];
  
  // 对应的文本
  texts: string[];
  
  // 元数据
  metadata: any[];
  
  // 索引
  index: VectorIndex;
}

// 向量索引
interface VectorIndex {
  // 添加向量
  add(embedding: number[], text: string, metadata: any): void;
  
  // 搜索相似向量
  search(query: number[], k: number): SearchResult[];
  
  // 删除向量
  delete(id: string): void;
}
```

**支持的后端**：
- **sqlite-vec** - SQLite 向量扩展
- **LanceDB** - 嵌入式向量数据库
- **自定义** - 可扩展接口

---

## 🔄 工作流程

### 记忆存储流程

```
新消息到达
    ↓
[1] 提取关键信息
    ├─ 实体识别
    ├─ 关系抽取
    └─ 重要性评估
    ↓
[2] 决定存储类型
    ├─ 临时 → 短期记忆
    ├─ 重要 → 长期记忆
    └─ 可检索 → 向量存储
    ↓
[3] 生成嵌入向量
    └─ 调用嵌入模型
    ↓
[4] 存储到对应系统
    ├─ 更新短期记忆
    ├─ 保存长期记忆
    └─ 添加到向量索引
    ↓
[5] 更新索引和元数据
```

### 记忆检索流程

```
用户查询
    ↓
[1] 生成查询向量
    └─ 调用嵌入模型
    ↓
[2] 向量相似度搜索
    ├─ 搜索向量索引
    └─ 获取 top-k 结果
    ↓
[3] 加载相关记忆
    ├─ 从长期记忆加载
    └─ 合并相似记忆
    ↓
[4] 排序和过滤
    ├─ 按相似度排序
    ├─ 按时间过滤
    └─ 按重要性筛选
    ↓
[5] 返回给 Agent
    └─ 注入到上下文
```

---

## 🛠️ 配置

### 短期记忆配置

```typescript
// memory.config.ts
export default {
  shortTerm: {
    // 最大消息数
    maxMessages: 100,
    
    // 最大 token 数
    maxTokens: 8000,
    
    // 会话超时（毫秒）
    sessionTimeout: 3600000, // 1 小时
    
    // 存储位置
    storage: "sqlite",
    
    // 数据库路径
    dbPath: "~/.openclaw/memory.db"
  }
};
```

### 长期记忆配置

```typescript
export default {
  longTerm: {
    // 自动保存
    autoSave: true,
    
    // 保存阈值
    saveThreshold: {
      importance: 0.7,  // 重要性 >= 0.7
      confidence: 0.8   // 置信度 >= 0.8
    },
    
    // 过期时间（天）
    expirationDays: 365,
    
    // 最大记忆数
    maxMemories: 10000
  }
};
```

### 向量存储配置

```typescript
export default {
  vector: {
    // 后端类型
    backend: "lancedb",  // "sqlite-vec" | "lancedb"
    
    // 嵌入模型
    embeddingModel: "text-embedding-3-small",
    
    // 向量维度
    dimensions: 1536,
    
    // 相似度阈值
    similarityThreshold: 0.7,
    
    // 返回数量
    topK: 5,
    
    // 数据库路径
    dbPath: "~/.openclaw/vectors.db"
  }
};
```

---

## 📊 性能优化

### 1. 短期记忆优化

**压缩策略**：
```typescript
// 智能压缩旧消息
function compressOldMessages(messages: Message[]): Message[] {
  // 保留最近的 N 条
  // 压缩中间的消息（摘要）
  // 删除不重要的消息
}
```

**缓存策略**：
```typescript
// LRU 缓存热门会话
const sessionCache = new LRUCache({
  max: 100,  // 最多缓存 100 个会话
  ttl: 60000 // 1 分钟
});
```

### 2. 向量检索优化

**索引优化**：
```typescript
// 使用 HNSW 索引
const index = new HNSWIndex({
  dimensions: 1536,
  maxConnections: 16,
  efConstruction: 200
});
```

**批量处理**：
```typescript
// 批量添加向量
async function batchAddEmbeddings(items: Item[]) {
  const embeddings = await generateEmbeddings(items.map(i => i.text));
  await index.addBatch(embeddings, items);
}
```

---

## 🔍 使用示例

### 1. 保存记忆

```typescript
// 保存重要事实
await memory.save({
  type: "fact",
  content: "用户喜欢使用 Python 进行数据分析",
  importance: 0.8,
  metadata: {
    tags: ["preference", "programming", "python"],
    category: "user_preference"
  }
});
```

### 2. 检索记忆

```typescript
// 语义搜索
const results = await memory.search({
  query: "用户对编程有什么偏好？",
  topK: 5,
  threshold: 0.7
});

console.log(results);
// [
//   { content: "用户喜欢使用 Python...", score: 0.85 },
//   { content: "用户经常使用 Jupyter...", score: 0.78 },
//   ...
// ]
```

### 3. 更新记忆

```typescript
// 更新记忆重要性
await memory.update(memoryId, {
  importance: 0.9,
  metadata: {
    accessCount: 10,
    lastAccessed: new Date()
  }
});
```

---

## 🐛 常见问题

### 1. 向量检索不准确

**原因**：
- 嵌入模型不适合
- 向量维度太低
- 相似度阈值太高

**解决**：
- 使用更好的嵌入模型
- 增加向量维度
- 调整相似度阈值

### 2. 记忆占用空间大

**原因**：
- 保存了太多记忆
- 向量数据库太大

**解决**：
- 设置记忆过期
- 定期清理旧记忆
- 压缩向量索引

### 3. 检索速度慢

**原因**：
- 向量索引未优化
- 数据库查询慢

**解决**：
- 使用 HNSW 索引
- 优化数据库查询
- 增加缓存

---

## 🔗 相关资源

- [Agent 助手](agent.md)
- [向量数据库对比](../advanced/vector-databases.md)
- [记忆管理最佳实践](../advanced/memory-management.md)

---

**上一章**：[Agent 助手](agent.md)  
**下一章**：[Skills 技能](skills.md)
