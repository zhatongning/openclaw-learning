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

**维护连接**：
- 所有消息渠道的连接
- 客户端的 WebSocket 连接
- 节点的 WebSocket 连接

**特性**：
- 单例模式：每台主机一个 Gateway
- 长期运行：作为守护进程
- 自动重连：断线后自动恢复

### 2. 协议处理

**WebSocket 协议**：
```typescript
// 请求-响应模式
{
  type: "req",
  id: string,
  method: string,
  params: any
}
→
{
  type: "res",
  id: string,
  ok: boolean,
  payload?: any,
  error?: string
}

// 事件推送模式
{
  type: "event",
  event: string,
  payload: any,
  seq?: number
}
```

**主要方法**：
- `health` - 健康检查
- `status` - 系统状态
- `send` - 发送消息
- `agent` - 调用 AI 助手

**主要事件**：
- `tick` - 心跳
- `agent` - AI 助手响应（流式）
- `presence` - 在线状态
- `shutdown` - 关闭通知

### 3. 认证与配对

**设备身份**：
- 每个客户端有唯一的设备 ID
- 新设备需要配对批准
- 批准后颁发设备令牌

**本地信任**：
- Loopback 连接可自动批准
- 非本地连接需要明确批准

**签名验证**：
- 所有连接必须签名 challenge nonce
- 防止中间人攻击

### 4. 会话管理

**客户端类型**：
1. **操作员**（Operator）
   - macOS App、CLI、Web UI
   - 发送控制命令
   - 订阅系统事件

2. **节点**（Node）
   - macOS、iOS、Android 设备
   - 提供设备能力（相机、位置等）
   - 执行远程命令

**会话状态**：
- 在线状态跟踪
- 能力声明（caps）
- 权限管理

### 5. 事件分发

**事件类型**：
```typescript
// 系统事件
{
  event: "health",
  payload: HealthStatus
}

// 聊天事件
{
  event: "chat",
  payload: {
    channelId: string,
    message: Message
  }
}

// AI 助手事件
{
  event: "agent",
  payload: {
    runId: string,
    status: "streaming" | "complete",
    content: string
  }
}
```

---

## 🔌 WebSocket API

### 连接建立

```typescript
// 1. 建立 WebSocket 连接
const ws = new WebSocket('ws://localhost:18789');

// 2. 发送 connect 请求
ws.send(JSON.stringify({
  type: "req",
  id: "1",
  method: "connect",
  params: {
    deviceId: "unique-device-id",
    auth: {
      token: "your-token"
    }
  }
}));

// 3. 接收响应
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === "res" && data.id === "1") {
    if (data.ok) {
      console.log("Connected!", data.payload);
      // payload 包含：presence + health 快照
    } else {
      console.error("Connection failed:", data.error);
    }
  }
};
```

### 订阅事件

```typescript
// 订阅 tick 事件
ws.send(JSON.stringify({
  type: "req",
  id: "2",
  method: "subscribe",
  params: {
    events: ["tick", "agent", "presence"]
  }
}));

// 接收事件
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === "event") {
    console.log(`Event: ${data.event}`, data.payload);
  }
};
```

### 调用 AI 助手

```typescript
// 发送消息给 AI 助手
ws.send(JSON.stringify({
  type: "req",
  id: "3",
  method: "agent",
  params: {
    message: "帮我创建一个 Python 爬虫",
    thinking: "high",
    idempotencyKey: "unique-key"
  }
}));

// 接收流式响应
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === "event" && data.event === "agent") {
    if (data.payload.status === "streaming") {
      process.stdout.write(data.payload.content);
    } else if (data.payload.status === "complete") {
      console.log("\nComplete!");
    }
  }
};
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

---

## 🔒 安全机制

### 1. 认证

**Token 认证**：
- 可选的 `OPENCLAW_GATEWAY_TOKEN`
- 所有连接必须提供匹配的 token

**设备认证**：
- 基于设备 ID
- 需要配对批准
- 签名验证

### 2. 授权

**基于角色的访问控制（RBAC）**：
- **操作员**：完整的控制权限
- **节点**：受限的设备权限

**能力声明**：
- 节点声明自己的能力
- 只能执行声明的命令

### 3. 加密

**本地连接**：
- WebSocket over localhost
- 不需要额外加密

**远程连接**：
- 推荐 Tailscale/VPN
- 或 SSH 隧道
- 支持 TLS（可选）

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

---

## 🐛 常见问题

### 1. 端口被占用

**错误**：`Error: listen EADDRINUSE: address already in use :::18789`

**解决**：
```bash
# 查找占用进程
lsof -i :18789

# 停止旧进程
openclaw gateway --stop
```

### 2. 认证失败

**错误**：`Authentication failed`

**解决**：
- 检查 `OPENCLAW_GATEWAY_TOKEN` 是否正确
- 确认客户端提供的 token 匹配

### 3. 连接断开

**原因**：
- 网络问题
- Gateway 重启
- 认证过期

**解决**：
- 实现自动重连
- 使用心跳保持连接

---

## 🔗 相关资源

- [WebSocket 协议详解](../source-code/websocket-protocol.md)
- [认证机制](../advanced/security.md)
- [性能优化](../advanced/performance.md)

---

**上一章**：[核心概念](../basics/core-concepts.md)  
**下一章**：[Agent 助手](agent.md)
