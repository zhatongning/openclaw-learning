# Gateway 网关详解

> Gateway 是 OpenClaw 的控制平面，负责管理所有消息渠道和客户端连接。

---

## 📊 架构位置

```
┌─────────────────────────────────────────────┐
│            客户端层                          │
│  macOS App │ CLI │ Web UI │ 自动化         │
└─────────────────────────────────────────────┘
                    ↓↑ WebSocket
┌─────────────────────────────────────────────┐
│          Gateway 网关 ⭐                     │
│  ┌─────────────────────────────────────┐   │
│  │ WebSocket Server (Port 18789)       │   │
│  ├─────────────────────────────────────┤   │
│  │ HTTP Server (Canvas + A2UI)         │   │
│ ├─────────────────────────────────────┤   │
│  │ 认证 & 配对                         │   │
│  ├─────────────────────────────────────┤   │
│  │ 协议验证                            │   │
│  ├─────────────────────────────────────┤   │
│  │ 会话管理                            │   │
│  ├─────────────────────────────────────┤   │
│  │ 事件分发                            │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    ↓↑
┌─────────────────────────────────────────────┐
│         消息渠道层                           │
│  Telegram │ WhatsApp │ Discord │ ...       │
└─────────────────────────────────────────────┘
```

---

## 🎯 核心职责

### 1. 连接管理

#### 维护连接
- 所有消息渠道的连接
- 客户端的 WebSocket 连接
- 节点的 WebSocket 连接

#### 特性
- **单例模式**：每台主机一个 Gateway
- **长期运行**：作为守护进程（daemon）
- **自动重连**:断线后自动恢复

#### 源码实现要点

Gateway 使用单例模式确保唯一性:

```typescript
// 伪代码示例
class Gateway {
  private static instance: Gateway;
  
  private constructor() {
    if (Gateway.instance) {
      return Gateway.instance;
    }
    Gateway.instance = this;
  }
  
  // 自动重连逻辑
  private async reconnect() {
    const delay = Math.min(1000, Math.pow(2, this.retryCount));
    try {
      await this.connect();
      this.retryCount = 0;
    } catch (error) {
      setTimeout(() => this.reconnect(), delay);
    }
  }
}
```

---

### 2. 协议处理

#### WebSocket 协议

Gateway 使用 TypeBox 定义强类型协议:

```typescript
// 请求-响应模式
{
  type: "req",
  id: "unique-request-id",
  method: "methodName",
  params: { /* 参数 */ }
}
→
{
  type: "res",
  id: "unique-request-id",
  ok: true,
  payload: { /* 响应数据 */ }
}

// 事件推送模式
{
  type: "event",
  event: "eventName",
  payload: { /* 事件数据 */ },
  seq: 123  // 序列号，用于顺序保证
}
```

#### 主要方法
- `health` - 健康检查
- `status` - 系统状态
- `send` - 发送消息
- `agent` - 调用 AI 助手

#### 主要事件
- `tick` - 心跳事件
- `agent` - AI 助手响应（流式）
- `presence` - 在线状态变化
- `shutdown` - 关闭通知

#### 协议验证
```typescript
// 使用 TypeBox 进行运行时验证
import { TypeCompiler } from '@sinclair/typebox';

const MessageSchema = TypeBox.Object({
  type: TypeBox.Literals('req'),
  id: TypeBox.String(),
  method: TypeBox.String(),
  params: TypeBox.Any()
});

// 验证消息
const isValid = TypeCompiler.Check(MessageSchema, message);
if (!isValid) {
  throw new Error('Invalid message format');
}
```

---

### 3. 认证与配对
#### 设备身份
- 每个客户端有唯一的设备 ID
- 新设备需要配对批准
- 批准后颁发设备令牌

#### 论源码实现
```typescript
class DeviceAuth {
  async authenticate(deviceId: string, challenge: string) {
    // 检查设备是否已配对
    const device = await this.getDevice(deviceId);
    
    if (!device.isPaired) {
      // 需要配对批准
      await this.requestPairing(deviceId);
      throw new Error('Device not paired');
    }
    
    // 验证签名
    const isValid = this.verifySignature(
      device.publicKey,
      challenge
    );
    
    if (!isValid) {
      throw new Error('Invalid signature');
    }
    
    return device;
  }
}
```

#### 本地信任
- **Loopback** 连接可自动批准
- **非本地** 连接需要明确批准

#### 签名验证
```typescript
class SignatureVerifier {
  verify(publicKey: string, challenge: string, signature: string): boolean {
    // 构造验证数据
    const data = challenge + '\n' + this.getTimestamp();
    
    // 验证签名
    const verifier = crypto.createVerify('SHA256');
    verifier.update(publicKey, 'hex');
    verifier.update(data, 'hex');
    verifier.update(signature, 'hex');
    
    return verifier.digest('hex') === signature;
  }
}
```

---

### 4. 会话管理
#### 客户端类型
1. **操作员**（Operator）
   - macOS App、 CLI、 Web UI
   - 发送控制命令
   - 订阅系统事件

2. **节点**（Node）
   - macOS、 iOS、 Android 设备
   - 提供设备能力（相机、位置等）
   - 执行远程命令

#### 会话状态
```typescript
interface Session {
  id: string;
  type: 'operator' | 'node';
  deviceId: string;
  capabilities: string[];
  connectedAt: Date;
  lastActivity: Date;
}

// 会话管理器
class SessionManager {
  private sessions: Map<string, Session> = new Map();
  
  addSession(session: Session) {
    this.sessions.set(session.id, session);
  }
  
  removeSession(sessionId: string) {
    this.sessions.delete(sessionId);
  }
  
  getActiveSessions(): Session[] {
    return Array.from(this.sessions.values())
      .filter(s => s.lastActivity > Date.now() - 60000);
  }
}
```

---

### 5. 事件分发
#### 事件类型
```typescript
// 系统事件
interface SystemEvent {
  event: 'health';
  payload: HealthStatus;
}

// 聊天事件
interface ChatEvent {
  event: 'chat';
  payload: {
    channelId: string;
    message: Message;
  }
}

// AI 助手事件
interface AgentEvent {
  event: 'agent';
  payload: {
    runId: string;
    status: 'streaming' | 'complete';
    content: string;
  }
}
```

#### 事件总线
```typescript
class EventBus {
  private listeners: Map<string, Set<Function>> = new Map();
  
  on(event: string, handler: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event).add(handler);
  }
  
  emit(event: string, data: any) {
    const handlers = this.listeners.get(event);
    if (handlers) {
      handlers.forEach(handler => handler(data));
    }
  }
  
  off(event: string, handler: Function) {
    this.listeners.get(event)?.delete(handler);
  }
}
```

---

## 🔌 WebSocket API

### 连接建立
```typescript
class WebSocketHandler {
  private ws: WebSocket;
  private sessionId: string;
  
  constructor(ws: WebSocket) {
    this.ws = ws;
    this.setupHandlers();
  }
  
  private setupHandlers() {
    this.ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        this.handleMessage(message);
      } catch (error) {
        console.error('Invalid message:', error);
        this.ws.close();
      }
    });
    
    this.ws.on('close', () => {
      this.cleanup();
    });
  }
  
  private async handleMessage(message: any) {
    switch (message.type) {
      case 'req':
        await this.handleRequest(message);
        break;
      case 'event':
        this.handleEvent(message);
        break;
      default:
        this.sendError('Unknown message type');
    }
  }
}
```

### 订阅事件
```typescript
// 订阅系统事件
handler.subscribe({
  events: ['tick', 'agent', 'presence']
});

// 接收事件
eventBus.on('agent', (data) => {
  console.log('Agent event:', data);
});
```

### 调用 AI 助手
```typescript
// 发送消息给 AI 助手
const response = await handler.request({
  method: 'agent',
  params: {
    message: '帮我创建一个 Python 爬虫',
  }
});

// 接收流式响应
eventBus.on('agent', (data) => {
  if (data.status === 'streaming') {
    process.stdout.write(data.content);
  } else if (data.status === 'complete') {
    console.log('\nComplete!');
  }
});
```

---

## 🛠️ 配置
### 启动参数
```bash
openclaw gateway [options]

Options:
  --port <port>           端口号（默认 18789）
  --host <host>           绑定地址（默认 127.0.0.1）
  --token <token>         认证令牌
  --verbose               详细日志
  --reset                 重置状态
```

### 环境变量
```bash
# Gateway 认证令牌
OPENCLAW_GATEWAY_TOKEN=your-secret-token

# 端口号
OPENCLAW_GATEWAY_PORT=18789

# 绑定地址
OPENCLAW_GATEWAY_HOST=0.0.0.0
```

### 配置文件
```yaml
# ~/.openclaw/config.yaml
gateway:
  port: 18789
  host: 127.0.0.1
  token: ${OPENCLAW_GATEWAY_TOKEN}
  maxConnections: 100
  timeout: 30000
```

---

## 🔒 安全机制
### 1. 认证
#### Token 认证
```typescript
class TokenAuth {
  private token: string;
  
  constructor(token: string) {
    this.token = token;
  }
  
  validate(providedToken: string): boolean {
    return this.token === providedToken;
  }
}
```

#### 设备认证
```typescript
class DeviceAuth {
  async authenticate(deviceId: string, signature: string): Promise<Device> {
    // 获取设备信息
    const device = await this.deviceStore.get(deviceId);
    
    // 验证签名
    const isValid = this.verifySignature(
      device.publicKey,
      signature
    );
    
    if (!isValid) {
      throw new Error('Authentication failed');
    }
    
    return device;
  }
}
```

### 2. 授权
#### 基于角色的访问控制（RBAC）
```typescript
enum Role {
  Operator = 'operator',
  Node = 'node'
}

class Authorization {
  private roles: Map<string, string[]> = new Map();
  
  constructor() {
    // 定义角色权限
    this.roles.set('operator', [
      'health',
      'status',
      'send',
      'agent'
    ]);
    
    this.roles.set('node', [
      'camera.snap',
      'location.get'
    ]);
  }
  
  hasPermission(role: Role, permission: string): boolean {
    return this.roles.get(role)?.includes(permission) || false;
  }
}
```

#### 能力声明
```typescript
interface DeviceCapabilities {
  deviceId: string;
  capabilities: string[];
}

// 节点连接时声明能力
{
  type: 'req',
  method: 'connect',
  params: {
    deviceId: 'device-123',
    role: 'node',
    capabilities: ['camera.snap', 'location.get']
  }
}
```

### 3. 加密
#### 本地连接
- WebSocket over localhost
- 不需要额外加密
- 自动信任

#### 远程连接
- **推荐**: Tailscale/VPN
- **备选**: SSH 隧道
- **可选**: TLS

```typescript
// TLS 配置
const tlsOptions = {
  cert: fs.readFileSync('/path/to/cert.pem'),
  key: fs.readFileSync('/path/to/key.pem'),
  ca: fs.readFileSync('/path/to/ca.pem')
};

// 创建安全服务器
const server = https.createServer(tlsOptions);
```

---

## 📊 监控和调试
### 健康检查
```bash
# 通过 WebSocket
openclaw health

# 或直接访问
curl http://localhost:18789/health
```

### 日志
```bash
# 启动时查看日志
openclaw gateway --verbose

# 查看守护进程日志
openclaw logs
```

### 状态
```bash
# 查看状态
openclaw status

# 查看连接的客户端
openclaw clients
```

### 指标
```typescript
// Prometheus 指标
const metrics = {
  connections: gauge({
    name: 'gateway_connections',
    help: 'Active connections'
  }),
  
  messages: counter({
    name: 'gateway_messages_total',
    help: 'Total messages processed'
  }),
  
  latency: histogram({
    name: 'gateway_latency',
    help: 'Message processing latency',
    buckets: [10, 50, 100, 500, 1000]
  })
};
```

---

## 🚀 最佳实践
### 1. 单例运行
```bash
# 使用 launchd/systemd 管理守护进程
openclaw gateway --install-daemon
```

### 2. 安全配置
```bash
# 设置强密码
export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -base64 32)

# 只监听本地
openclaw gateway --host 127.0.0.1
```

### 3. 远程访问
```bash
# 使用 Tailscale（推荐）
tailscale up

# 或 SSH 隧道
ssh -N -L 18789:127.0.0.1:18789 user@host
```

### 4. 性能优化
```typescript
// 连接池配置
const poolConfig = {
  maxConnections: 100,
  idleTimeout: 30000,
  maxMessageSize: 1024 * 1024 // 1MB
};
```

---

## 🐛 常见问题
### 1. 端口被占用
**错误**: `Error: listen EADDRINUSE: address already in use :::18789`

**解决**:
```bash
# 检查端口占用
lsof -i :18789

# 停止旧进程
kill -9 <PID>

# 或使用其他端口
openclaw gateway --port 18790
```

### 2. 认证失败
**错误**: `Authentication failed`

**解决**:
- 检查 `OPENCLAW_GATEWAY_TOKEN` 是否正确
- 确认客户端提供的 token 匹配
- 查看日志获取详细错误

```bash
# 查看日志
openclaw gateway --verbose
```

### 3. 连接断开
**原因**:
- 网络问题
- Gateway 重启
- 认证过期

**解决**:
- 实现自动重连
- 使用心跳保持连接
- 保存会话状态

```typescript
// 自动重连实现
class ReconnectingWebSocket {
  private maxRetries = 5;
  private retryDelay = 1000;
  
  async connect(): Promise<void> {
    for (let i = 0; i < this.maxRetries; i++) {
      try {
        await this.createConnection();
        return;
      } catch (error) {
        console.log(`Connection failed, retry ${i + 1}/${this.maxRetries}`);
        await this.delay(this.retryDelay * Math.pow(2, i));
      }
    }
    throw new Error('Max retries exceeded');
  }
}
```

---

## 🔗 相关资源
- [WebSocket 协议详解](../source-code/websocket-protocol.md)
- [认证机制](../advanced/security.md)
- [性能优化](../advanced/performance.md)
- [Gateway 源码](https://github.com/openclaw/openclaw/tree/main/src/gateway)

