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
│  │  ├─ Session Manager                  │   │
│  │  ├─ Message Buffer                   │   │
│  │  └─ Context Cache                    │   │
│  ├──────────────────────────────────────┤   │
│  │  Long-term Memory (长期记忆)          │   │
│  │  ├─ Fact Store                       │   │
│  │  ├─ Decision Store                   │   │
│  │  └─ Preference Store                 │   │
│  ├──────────────────────────────────────┤   │
│  │  Vector Store (向量存储)              │   │
│  │  ├─ Embedding Generator              │   │
│  │  ├─ Vector Index (HNSW)              │   │
│  │  └─ Similarity Search                │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         存储后端                             │
│  SQLite │ LanceDB │ Redis │ 自定义存储     │
└─────────────────────────────────────────────┘
```

---

## 🎯 核心职责

### 1. 短期记忆（Short-term Memory）

#### 作用
- 存储当前会话的对话历史
- 提供快速访问
- 自动过期

#### 数据结构
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
    agentId: string;
    startedAt: Date;
    lastActivity: Date;
  };
  
  // 元数据
  metadata: {
    messageCount: number;
    tokenCount: number;
    avgResponseTime: number;
  };
}

interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
  timestamp: Date;
  metadata?: {
    model?: string;
    tokens?: number;
    toolCalls?: ToolCall[];
  };
}
```

#### 源码实现
```typescript
class ShortTermMemoryManager {
  private sessions: Map<string, Session> = new Map();
  private db: Database;
  private config: MemoryConfig;
  
  constructor(config: MemoryConfig) {
    this.config = config;
    this.db = new Database(config.dbPath);
    this.initDatabase();
  }
  
  // 获取或创建会话
  async getSession(sessionId: string): Promise<Session> {
    // 先从内存查找
    let session = this.sessions.get(sessionId);
    
    if (session) {
      // 检查是否过期
      if (this.isExpired(session)) {
        await this.archiveSession(sessionId);
        session = null;
      } else {
        return session;
      }
    }
    
    // 从数据库加载
    session = await this.loadFromDB(sessionId);
    
    if (session) {
      this.sessions.set(sessionId, session);
      return session;
    }
    
    // 创建新会话
    return this.createSession(sessionId);
  }
  
  // 添加消息
  async addMessage(sessionId: string, message: Message): Promise<void> {
    const session = await this.getSession(sessionId);
    
    // 添加消息
    session.messages.push(message);
    session.metadata.messageCount++;
    session.metadata.tokenCount += message.metadata?.tokens || 0;
    session.context.lastActivity = new Date();
    
    // 持久化
    await this.saveToDB(session);
    
    // 检查是否需要压缩
    if (session.metadata.tokenCount > this.config.maxSessionTokens) {
      await this.compressSession(session);
    }
  }
  
  // 获取消息历史
  async getMessages(sessionId: string, limit?: number): Promise<Message[]> {
    const session = await this.getSession(sessionId);
    
    if (limit) {
      return session.messages.slice(-limit);
    }
    
    return session.messages;
  }
  
  // 压缩会话
  private async compressSession(session: Session): Promise<void> {
    // 保留最近的 N 条消息
    const keepCount = Math.floor(session.messages.length * 0.5);
    const toCompress = session.messages.slice(0, -keepCount);
    
    // 生成摘要
    const summary = await this.generateSummary(toCompress);
    
    // 替换为摘要
    session.messages = [
      {
        role: 'system',
        content: `Previous conversation summary: ${summary}`,
        timestamp: new Date(),
        id: generateId()
      },
      ...session.messages.slice(-keepCount)
    ];
    
    // 更新 token 统计
    session.metadata.tokenCount = this.countTokens(session.messages);
  }
  
  // 过期检查
  private isExpired(session: Session): boolean {
    const elapsed = Date.now() - session.context.lastActivity.getTime();
    return elapsed > this.config.sessionTimeout;
  }
  
  // 归档会话
  private async archiveSession(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    
    if (session) {
      // 保存到归档表
      await this.db.run(`
        INSERT INTO archived_sessions 
        SELECT * FROM sessions WHERE session_id = ?
      `, [sessionId]);
      
      // 从内存移除
      this.sessions.delete(sessionId);
      
      // 删除活跃记录
      await this.db.run(`
        DELETE FROM sessions WHERE session_id = ?
      `, [sessionId]);
    }
  }
}
```

---

### 2. 长期记忆（Long-term Memory）

#### 作用
- 存储重要的事实和决策
- 跨会话持久化
- 提供长期上下文

#### 记忆类型
```typescript
type MemoryType = 
  | 'fact'        // 事实：用户喜欢 Python
  | 'decision'    // 决策：选择了方案 A
  | 'preference'  // 偏好：偏好简洁的回答
  | 'event';      // 事件：完成了某个任务

interface LongTermMemory {
  // 记忆 ID
  id: string;
  
  // 记忆类型
  type: MemoryType;
  
  // 内容
  content: string;
  
  // 重要性（0-1）
  importance: number;
  
  // 来源
  source: {
    sessionId: string;
    messageId: string;
    timestamp: Date;
    userId?: string;
  };
  
  // 元数据
  metadata: {
    tags: string[];
    category: string;
    confidence: number;  // 置信度
    accessCount: number; // 访问次数
    lastAccessed: Date;
  };
  
  // 嵌入向量（用于检索）
  embedding?: number[];
}
```

#### 源码实现
```typescript
class LongTermMemoryManager {
  private db: Database;
  private vectorStore: VectorStore;
  private embedder: Embedder;
  
  constructor(config: MemoryConfig) {
    this.db = new Database(config.dbPath);
    this.vectorStore = new VectorStore(config.vectorConfig);
    this.embedder = new Embedder(config.embeddingModel);
    this.initDatabase();
  }
  
  // 保存记忆
  async save(memory: Omit<LongTermMemory, 'id' | 'embedding'>): Promise<string> {
    const id = generateId();
    
    // 生成嵌入向量
    const embedding = await this.embedder.embed(memory.content);
    
    // 保存到数据库
    await this.db.run(`
      INSERT INTO memories (
        id, type, content, importance,
        session_id, message_id, timestamp, user_id,
        tags, category, confidence
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      id,
      memory.type,
      memory.content,
      memory.importance,
      memory.source.sessionId,
      memory.source.messageId,
      memory.source.timestamp,
      memory.source.userId,
      JSON.stringify(memory.metadata.tags),
      memory.metadata.category,
      memory.metadata.confidence
    ]);
    
    // 添加到向量索引
    await this.vectorStore.add({
      id,
      vector: embedding,
      metadata: {
        type: memory.type,
        content: memory.content,
        importance: memory.importance
      }
    });
    
    return id;
  }
  
  // 检索记忆
  async search(query: string, options: SearchOptions): Promise<MemorySearchResult[]> {
    // 生成查询向量
    const queryVector = await this.embedder.embed(query);
    
    // 向量相似度搜索
    const vectorResults = await this.vectorStore.search(queryVector, {
      topK: options.topK || 5,
      threshold: options.threshold || 0.7,
      filter: options.filter
    });
    
    // 从数据库加载完整记忆
    const memories = await Promise.all(
      vectorResults.map(async (result) => {
        const memory = await this.db.get<LongTermMemory>(`
          SELECT * FROM memories WHERE id = ?
        `, [result.id]);
        
        // 更新访问统计
        await this.updateAccessStats(result.id);
        
        return {
          memory,
          score: result.score
        };
      })
    );
    
    // 按重要性重新排序
    return this.rerank(memories, options);
  }
  
  // 按类型获取
  async getByType(type: MemoryType, userId?: string): Promise<LongTermMemory[]> {
    let query = `SELECT * FROM memories WHERE type = ?`;
    const params: any[] = [type];
    
    if (userId) {
      query += ` AND user_id = ?`;
      params.push(userId);
    }
    
    query += ` ORDER BY importance DESC, timestamp DESC`;
    
    return this.db.all<LongTermMemory>(query, params);
  }
  
  // 更新记忆
  async update(id: string, updates: Partial<LongTermMemory>): Promise<void> {
    const fields: string[] = [];
    const values: any[] = [];
    
    if (updates.content !== undefined) {
      fields.push('content = ?');
      values.push(updates.content);
      
      // 重新生成嵌入向量
      const embedding = await this.embedder.embed(updates.content);
      await this.vectorStore.update(id, { vector: embedding });
    }
    
    if (updates.importance !== undefined) {
      fields.push('importance = ?');
      values.push(updates.importance);
    }
    
    if (updates.metadata !== undefined) {
      fields.push('tags = ?, category = ?');
      values.push(
        JSON.stringify(updates.metadata.tags),
        updates.metadata.category
      );
    }
    
    if (fields.length > 0) {
      values.push(id);
      await this.db.run(`
        UPDATE memories 
        SET ${fields.join(', ')} 
        WHERE id = ?
      `, values);
    }
  }
  
  // 删除记忆
  async delete(id: string): Promise<void> {
    await this.db.run(`DELETE FROM memories WHERE id = ?`, [id]);
    await this.vectorStore.delete(id);
  }
  
  // 更新访问统计
  private async updateAccessStats(id: string): Promise<void> {
    await this.db.run(`
      UPDATE memories 
      SET access_count = access_count + 1,
          last_accessed = ?
      WHERE id = ?
    `, [new Date(), id]);
  }
  
  // 重新排序
  private rerank(
    results: MemorySearchResult[],
    options: SearchOptions
  ): MemorySearchResult[] {
    // 结合相似度和重要性
    return results.sort((a, b) => {
      const scoreA = a.score * 0.7 + a.memory.importance * 0.3;
      const scoreB = b.score * 0.7 + b.memory.importance * 0.3;
      return scoreB - scoreA;
    });
  }
}
```

#### 记忆提取
```typescript
class MemoryExtractor {
  private llm: LLM;
  
  // 从对话中提取重要记忆
  async extractFromConversation(messages: Message[]): Promise<ExtractedMemory[]> {
    const prompt = `
Analyze the following conversation and extract important information that should be remembered.

Conversation:
${messages.map(m => `${m.role}: ${m.content}`).join('\n')}

Extract:
1. Important facts about the user
2. Decisions made
3. User preferences
4. Key events

Format as JSON array:
[
  {
    "type": "fact|decision|preference|event",
    "content": "the information to remember",
    "importance": 0.0-1.0,
    "tags": ["tag1", "tag2"],
    "category": "category"
  }
]
`;

    const response = await this.llm.generate(prompt, {
      temperature: 0.3,
      maxTokens: 1000
    });
    
    try {
      const memories = JSON.parse(response);
      return memories;
    } catch (error) {
      console.error('Failed to parse extracted memories:', error);
      return [];
    }
  }
  
  // 自动保存记忆
  async autoSave(sessionId: string, messages: Message[]): Promise<void> {
    // 提取记忆
    const extracted = await this.extractFromConversation(messages);
    
    // 过滤高置信度的
    const toSave = extracted.filter(m => m.importance >= 0.7);
    
    // 保存
    for (const memory of toSave) {
      await this.memoryManager.save({
        ...memory,
        source: {
          sessionId,
          messageId: messages[messages.length - 1].id,
          timestamp: new Date()
        },
        metadata: {
          tags: memory.tags || [],
          category: memory.category || 'general',
          confidence: memory.importance,
          accessCount: 0,
          lastAccessed: new Date()
        }
      });
    }
  }
}
```

---

### 3. 向量存储（Vector Store）

#### 作用
- 语义搜索
- 相似度检索
- 智能推荐

#### 支持的后端
```typescript
type VectorBackend = 
  | 'sqlite-vec'   // SQLite 向量扩展
  | 'lancedb'      // 嵌入式向量数据库
  | 'pinecone'     // Pinecone 云服务
  | 'custom';      // 自定义实现
```

#### 源码实现
```typescript
class VectorStore {
  private backend: VectorBackend;
  private index: VectorIndex;
  private config: VectorConfig;
  
  constructor(config: VectorConfig) {
    this.config = config;
    this.backend = this.createBackend(config.backend);
    this.index = this.createIndex(config.indexType);
  }
  
  // 添加向量
  async add(item: VectorItem): Promise<void> {
    // 验证向量维度
    if (item.vector.length !== this.config.dimensions) {
      throw new Error(`Vector dimension mismatch: expected ${this.config.dimensions}, got ${item.vector.length}`);
    }
    
    // 添加到索引
    await this.index.add(item.id, item.vector, item.metadata);
    
    // 持久化（如果需要）
    if (this.config.persist) {
      await this.backend.save(item);
    }
  }
  
  // 批量添加
  async addBatch(items: VectorItem[]): Promise<void> {
    // 验证所有向量
    for (const item of items) {
      if (item.vector.length !== this.config.dimensions) {
        throw new Error(`Vector dimension mismatch for item ${item.id}`);
      }
    }
    
    // 批量添加
    await this.index.addBatch(items);
    
    // 持久化
    if (this.config.persist) {
      await this.backend.saveBatch(items);
    }
  }
  
  // 搜索相似向量
  async search(
    query: number[],
    options: SearchOptions
  ): Promise<SearchResult[]> {
    // 验证查询向量
    if (query.length !== this.config.dimensions) {
      throw new Error(`Query vector dimension mismatch`);
    }
    
    // 搜索
    const results = await this.index.search(query, options.topK || 10);
    
    // 过滤低分结果
    const filtered = results.filter(r => r.score >= (options.threshold || 0.0));
    
    // 应用元数据过滤
    if (options.filter) {
      return filtered.filter(r => this.matchesFilter(r.metadata, options.filter));
    }
    
    return filtered;
  }
  
  // 更新向量
  async update(id: string, updates: Partial<VectorItem>): Promise<void> {
    if (updates.vector) {
      await this.index.update(id, updates.vector);
    }
    
    if (updates.metadata) {
      await this.index.updateMetadata(id, updates.metadata);
    }
    
    if (this.config.persist) {
      await this.backend.update(id, updates);
    }
  }
  
  // 删除向量
  async delete(id: string): Promise<void> {
    await this.index.delete(id);
    
    if (this.config.persist) {
      await this.backend.delete(id);
    }
  }
  
  // 创建索引
  private createIndex(type: IndexType): VectorIndex {
    switch (type) {
      case 'hnsw':
        return new HNSWIndex({
          dimensions: this.config.dimensions,
          maxConnections: 16,
          efConstruction: 200
        });
      
      case 'ivf':
        return new IVFIndex({
          dimensions: this.config.dimensions,
          nClusters: 100
        });
      
      case 'flat':
        return new FlatIndex({
          dimensions: this.config.dimensions
        });
      
      default:
        throw new Error(`Unknown index type: ${type}`);
    }
  }
}
```

#### HNSW 索引实现
```typescript
class HNSWIndex implements VectorIndex {
  private layers: Map<number, Layer> = new Map();
  private entryPoint: string | null = null;
  private maxLayer = 0;
  private config: HNSWConfig;
  
  constructor(config: HNSWConfig) {
    this.config = config;
  }
  
  // 添加向量
  async add(id: string, vector: number[], metadata: any): Promise<void> {
    // 计算层级
    const level = this.randomLevel();
    
    // 创建节点
    const node: HNSWNode = {
      id,
      vector,
      metadata,
      level,
      connections: new Map()
    };
    
    // 如果是第一个节点
    if (!this.entryPoint) {
      this.entryPoint = id;
      this.maxLayer = level;
      
      // 初始化层级
      for (let i = 0; i <= level; i++) {
        this.layers.set(i, new Map());
      }
      
      this.layers.get(0).set(id, node);
      return;
    }
    
    // 从入口点开始搜索
    let currentNode = this.layers.get(0).get(this.entryPoint);
    
    // 贪心搜索到插入层级
    for (let lc = this.maxLayer; lc > level; lc--) {
      currentNode = this.greedySearch(currentNode, vector, lc);
    }
    
    // 在每一层插入并建立连接
    for (let lc = Math.min(level, this.maxLayer); lc >= 0; lc--) {
      const neighbors = this.searchLayer(currentNode, vector, lc, this.config.efConstruction);
      
      // 选择连接
      const selected = this.selectNeighbors(neighbors, this.config.maxConnections);
      
      // 建立双向连接
      node.connections.set(lc, selected);
      
      for (const neighbor of selected) {
        const neighborNode = this.layers.get(lc).get(neighbor.id);
        neighborNode.connections.get(lc).push({ id, distance: neighbor.distance });
        
        // 剪枝连接（如果超过最大连接数）
        if (neighborNode.connections.get(lc).length > this.config.maxConnections) {
          neighborNode.connections.set(
            lc,
            this.selectNeighbors(
              neighborNode.connections.get(lc),
              this.config.maxConnections
            )
          );
        }
      }
      
      // 添加到层
      if (!this.layers.has(lc)) {
        this.layers.set(lc, new Map());
      }
      this.layers.get(lc).set(id, node);
      
      // 更新当前节点
      if (lc > 0) {
        currentNode = neighbors[0];
      }
    }
    
    // 更新入口点（如果需要）
    if (level > this.maxLayer) {
      this.entryPoint = id;
      this.maxLayer = level;
    }
  }
  
  // 搜索
  async search(query: number[], k: number): Promise<SearchResult[]> {
    if (!this.entryPoint) {
      return [];
    }
    
    let currentNode = this.layers.get(this.maxLayer).get(this.entryPoint);
    
    // 从顶层向下搜索
    for (let lc = this.maxLayer; lc > 0; lc--) {
      currentNode = this.greedySearch(currentNode, query, lc);
    }
    
    // 在底层搜索
    const results = this.searchLayer(currentNode, query, 0, this.config.efSearch || k * 2);
    
    // 返回 top-k
    return results
      .slice(0, k)
      .map(r => ({
        id: r.id,
        score: 1 / (1 + r.distance),  // 距离转相似度
        metadata: this.layers.get(0).get(r.id).metadata
      }));
  }
  
  // 贪心搜索
  private greedySearch(startNode: HNSWNode, query: number[], level: number): HNSWNode {
    let current = startNode;
    let minDistance = this.distance(current.vector, query);
    
    while (true) {
      let found = false;
      
      const connections = current.connections.get(level) || [];
      for (const conn of connections) {
        const neighbor = this.layers.get(level).get(conn.id);
        const dist = this.distance(neighbor.vector, query);
        
        if (dist < minDistance) {
          minDistance = dist;
          current = neighbor;
          found = true;
          break;
        }
      }
      
      if (!found) break;
    }
    
    return current;
  }
  
  // 层级搜索
  private searchLayer(
    entry: HNSWNode,
    query: number[],
    level: number,
    ef: number
  ): SearchResult[] {
    const visited = new Set<string>();
    const candidates = new PriorityQueue<SearchResult>((a, b) => a.distance - b.distance);
    const results = new PriorityQueue<SearchResult>((a, b) => b.distance - a.distance);
    
    const entryDistance = this.distance(entry.vector, query);
    candidates.push({ id: entry.id, distance: entryDistance });
    results.push({ id: entry.id, distance: entryDistance });
    visited.add(entry.id);
    
    while (!candidates.isEmpty()) {
      const current = candidates.pop();
      const furthest = results.peek();
      
      if (current.distance > furthest.distance) {
        break;
      }
      
      const currentNode = this.layers.get(level).get(current.id);
      const connections = currentNode.connections.get(level) || [];
      
      for (const conn of connections) {
        if (!visited.has(conn.id)) {
          visited.add(conn.id);
          
          const neighbor = this.layers.get(level).get(conn.id);
          const dist = this.distance(neighbor.vector, query);
          
          if (dist < results.peek().distance || results.size() < ef) {
            candidates.push({ id: conn.id, distance: dist });
            results.push({ id: conn.id, distance: dist });
            
            if (results.size() > ef) {
              results.pop();
            }
          }
        }
      }
    }
    
    return results.toArray().sort((a, b) => a.distance - b.distance);
  }
  
  // 距离计算
  private distance(a: number[], b: number[]): number {
    // 欧氏距离
    let sum = 0;
    for (let i = 0; i < a.length; i++) {
      sum += Math.pow(a[i] - b[i], 2);
    }
    return Math.sqrt(sum);
  }
  
  // 随机层级
  private randomLevel(): number {
    const r = Math.random();
    return Math.floor(-Math.log(r) * this.config.levelMultiplier);
  }
  
  // 选择邻居
  private selectNeighbors(
    candidates: SearchResult[],
    maxConnections: number
  ): SearchResult[] {
    // 简单启发式：选择最近的
    return candidates
      .sort((a, b) => a.distance - b.distance)
      .slice(0, maxConnections);
  }
}
```

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

### 记忆配置
```typescript
// memory.config.ts
export default {
  // 短期记忆配置
  shortTerm: {
    enabled: true,
    maxSessions: 1000,
    maxMessagesPerSession: 100,
    maxSessionTokens: 8000,
    sessionTimeout: 3600000,  // 1 小时
    persist: true,
    dbPath: '~/.openclaw/memory.db'
  },
  
  // 长期记忆配置
  longTerm: {
    enabled: true,
    autoExtract: true,
    extractionThreshold: 0.7,
    maxMemories: 100000,
    expirationDays: 365,
    importanceDecay: 0.99,  // 每天衰减
    dbPath: '~/.openclaw/memories.db'
  },
  
  // 向量存储配置
  vector: {
    enabled: true,
    backend: 'lancedb',
    dimensions: 1536,
    embeddingModel: 'text-embedding-3-small',
    indexType: 'hnsw',
    indexConfig: {
      maxConnections: 16,
      efConstruction: 200,
      efSearch: 50
    },
    similarityThreshold: 0.7,
    topK: 5,
    dbPath: '~/.openclaw/vectors.db'
  },
  
  // 嵌入配置
  embedding: {
    model: 'text-embedding-3-small',
    batchSize: 100,
    cache: true,
    cacheSize: 10000
  }
};
```

---

## 📊 性能优化

### 1. 短期记忆优化
```typescript
// LRU 缓存
const sessionCache = new LRUCache<string, Session>({
  max: 100,
  ttl: 60000,  // 1 分钟
  updateAgeOnGet: true
});

// 批量保存
async function batchSave(sessions: Session[]): Promise<void> {
  const statements = sessions.map(s => 
    db.prepare(`INSERT OR REPLACE INTO sessions VALUES (?, ?, ?)`)
      .run(s.id, JSON.stringify(s), Date.now())
  );
  
  await db.batch(statements);
}
```

### 2. 向量检索优化
```typescript
// 量化向量
function quantize(vector: number[]): Int8Array {
  const max = Math.max(...vector.map(Math.abs));
  return new Int8Array(vector.map(v => (v / max) * 127));
}

// 分段索引
class SegmentedIndex {
  private segments: Map<string, VectorIndex> = new Map();
  
  async search(query: number[], options: SearchOptions): Promise<SearchResult[]> {
    // 并行搜索所有分段
    const results = await Promise.all(
      Array.from(this.segments.values()).map(index =>
        index.search(query, { topK: options.topK / this.segments.size })
      )
    );
    
    // 合并和重排序
    return this.mergeAndRerank(results, options.topK);
  }
}
```

### 3. 嵌入缓存
```typescript
class EmbeddingCache {
  private cache = new LRUCache<string, number[]>({
    max: 10000,
    ttl: 86400000  // 24 小时
  });
  
  async embed(text: string): Promise<number[]> {
    const hash = this.hashText(text);
    
    // 尝试从缓存获取
    const cached = this.cache.get(hash);
    if (cached) {
      return cached;
    }
    
    // 生成新嵌入
    const embedding = await this.embedder.embed(text);
    
    // 存入缓存
    this.cache.set(hash, embedding);
    
    return embedding;
  }
  
  private hashText(text: string): string {
    return crypto.createHash('sha256').update(text).digest('hex');
  }
}
```

---

## 🐛 常见问题

### 1. 向量检索不准确
**原因**：
- 嵌入模型不适合
- 向量维度太低
- 相似度阈值太高

**解决**：
```typescript
// 使用更好的嵌入模型
config.embedding.model = 'text-embedding-3-large';

// 增加向量维度
config.vector.dimensions = 3072;

// 调整相似度阈值
config.vector.similarityThreshold = 0.6;
```

### 2. 记忆占用空间大
**原因**：
- 保存了太多记忆
- 向量数据库太大

**解决**：
```typescript
// 设置记忆过期
config.longTerm.expirationDays = 90;

// 定期清理
async function cleanup() {
  // 删除过期记忆
  await db.run(`
    DELETE FROM memories 
    WHERE timestamp < datetime('now', '-90 days')
    OR importance < 0.3
  `);
  
  // 压缩向量索引
  await vectorStore.compact();
}

// 每周运行一次
schedule.scheduleJob('0 0 * * 0', cleanup);
```

### 3. 检索速度慢
**原因**：
- 向量索引未优化
- 数据库查询慢

**解决**：
```typescript
// 使用 HNSW 索引
config.vector.indexType = 'hnsw';
config.vector.indexConfig = {
  maxConnections: 32,
  efConstruction: 400,
  efSearch: 100
};

// 优化数据库
await db.run('CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(type)');
await db.run('CREATE INDEX IF NOT EXISTS idx_memories_user ON memories(user_id)');
await db.run('CREATE INDEX IF NOT EXISTS idx_memories_importance ON memories(importance)');
```

---

## 🔗 相关资源
- [Agent 助手](agent.md)
- [向量数据库对比](../advanced/vector-databases.md)
- [记忆管理最佳实践](../advanced/memory-management.md)
- [Memory 源码](https://github.com/openclaw/openclaw/tree/main/src/memory)

---

**上一章**：[Agent 助手](agent.md)  
**下一章**：[Skills 技能](skills.md)
