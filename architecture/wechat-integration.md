# 微信接入 OpenClaw 技术实现文档

> 调研时间：2026-03-23
> 调研人：OpenClaw Learning Team

## 一、技术架构图

```
用户（微信）              OpenClaw Gateway              AI Agent
   │                          │                           │
   │ ① 发送消息              │                           │
   ├────────────────────────> │                           │
   │                          │                           │
   │               ┌──────────┴──────────┐              │
   │               │  WeChat Channel    │              │
   │               │   Plugin (插件)      │              │
   │               └──────────┬──────────┘              │
   │                          │                           │
   │                          │ ② 消息处理              │
   │                          │  - 权限验证               │
   │                          │  - 消息过滤               │
   │                          │  - 会话路由               │
   │                          │  - 媒体下载               │
   │                          ├──────────────────────────> │
   │                          │                           │
   │                          │ ③ AI 处理                │
   │                          │  - 生成回复               │
   │                          │  - 工具调用               │
   │                          │                           │
   │                          │ ④ 返回回复               │
   │                          │ <──────────────────────────┤
   │                          │                           │
   │ ⑤ 接收回复              │                           │
   │ <─────────────────────────┤                           │
   │                          │                           │

中间件层：WeChatPadPro (iPad 协议)
   ├─ HTTP REST API (发送消息、上传文件)
   ├─ WebSocket (实时消息推送)
   └─ QR 码登录流程
```

### 数据流向说明

1. **入站消息流**：微信用户 → WeChatPadPro → OpenClaw HTTP轮询 → Channel插件 → 权限验证 → AI Agent
2. **出站消息流**：AI Agent → Channel插件 → WeChatPadPro REST API → 微信用户
3. **认证流程**：WeChatPadPro生成QR码 → 用户扫码 → 轮询登录状态 → 建立连接

---

## 二、关键代码实现

### 1. 插件入口

```typescript
const plugin = {
  id: "wechat",
  name: "WeChat",
  description: "WeChat personal account channel plugin (via WeChatPadPro, iPad protocol)",
  configSchema: emptyPluginConfigSchema(),
  
  register(api: OpenClawPluginApi) {
    setWechatRuntime(api.runtime);
    api.registerChannel({ plugin: wechatPlugin });
  },
};
```

### 2. 消息监控核心循环

```typescript
// HTTP 轮询获取新消息
async function monitorSingleWechatAccount(params: {
  cfg: ClawdbotConfig;
  account: ResolvedWechatAccount;
  runtime?: RuntimeEnv;
  abortSignal?: AbortSignal;
}): Promise<void> {
  const pollUrl = `${serverUrl}/message/HttpSyncMsg?key=${token}`;
  
  while (!abortSignal?.aborted) {
    const resp = await fetch(pollUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ Count: 0 }),
      signal: abortSignal,
    });
    
    const data = (await resp.json()) as HttpSyncResponse;
    const items = data?.Data ?? [];
    
    for (const item of items) {
      const msgs = item?.AddMsgs ?? [];
      for (const msg of msgs) {
        handleWechatMessage({ cfg, msg, accountId, runtime, chatHistories });
      }
    }
    
    await new Promise((resolve) => setTimeout(resolve, 2_000)); // 每2秒轮询一次
  }
}
```

### 3. 消息发送实现

```typescript
// 发送文本消息
async function padProSendText(params: {
  serverUrl: string;
  token: string;
  toUserName: string;
  text: string;
  atWxIds?: string[];
}): Promise<{ msgId?: string }> {
  const res = await fetch(
    `${serverUrl}/message/SendTextMessage?key=${token}`,
    {
      method: "POST",
      headers: { "content-type": "application/json", accept: "application/json" },
      body: JSON.stringify({
        MsgItem: [{
          AtWxIDList: atWxIds || [],
          ImageContent: "",
          MsgType: 1,
          TextContent: text,
          ToUserName: toUserName,
        }],
      }),
    }
  );
  // ... 错误处理
}
```

### 4. 消息类型处理

```typescript
const PADPRO_MSG_TEXT = 1;    // 文本消息
const PADPRO_MSG_IMAGE = 3;    // 图片消息
const PADPRO_MSG_VOICE = 34;   // 语音消息
const PADPRO_MSG_VIDEO = 43;   // 视频消息
const PADPRO_MSG_XML = 49;     // XML消息（链接、小程序、引用回复）

// 解析消息上下文
function buildPadProMessageContext(params: {
  msg: WsPadProMessage;
  accountId: string;
  selfWxid?: string;
  log: (msg: string) => void;
}): WechatMessageContext | null {
  const messageType = msg.msg_type;
  const isGroup = msg.from_user_name?.str.endsWith("@chatroom");
  
  // 提取发送者ID和内容
  let senderId: string;
  let rawContent: string;
  
  if (isGroup) {
    const raw = msg.content?.str ?? "";
    const colonNewline = raw.indexOf(":\n");
    senderId = raw.slice(0, colonNewline).trim();
    rawContent = raw.slice(colonNewline + 2);
  } else {
    senderId = msg.from_user_name?.str;
    rawContent = msg.content?.str ?? "";
  }
  
  // XML消息提取引用内容
  if (messageType === PADPRO_MSG_XML && rawContent.includes("<appmsg")) {
    const titleMatch = rawContent.match(/<title>([\s\S]*?)<\/title>/i);
    if (titleMatch) {
      content = titleMatch[1].trim();
    }
    // 提取引用消息...
  }
  
  return { senderId, content, quotedContext, ... };
}
```

### 5. 媒体处理

```typescript
// 下载图片
async function downloadImageFromXml(
  xml: string,
  accountId: string,
  log?: (msg: string) => void,
): Promise<WechatMediaInfo | null> {
  const cdnUrl = 
    extractXmlAttr(xml, "cdnmidimgurl") ??
    extractXmlAttr(xml, "cdnbigimgurl") ??
    extractXmlAttr(xml, "cdnthumburl");
  
  if (cdnUrl) {
    const res = await fetch(cdnUrl, { headers: { accept: "image/*,*/*" } });
    if (res.ok) {
      const contentType = res.headers.get("content-type") ?? "image/jpeg";
      const ext = extensionFromMime(contentType);
      const fileName = `img-${Date.now()}.${ext}`;
      const filePath = path.join(MEDIA_DIR, fileName);
      ensureMediaDir();
      const buf = Buffer.from(await res.arrayBuffer());
      fs.writeFileSync(filePath, buf);
      return { path: filePath, contentType, placeholder: "<media:image>" };
    }
  }
  return null;
}
```

---

## 三、消息流程说明

### 1. 消息接收流程

```
1. WeChatPadPro 接收微信消息
   ↓
2. OpenClaw 通过 HTTP POST /message/HttpSyncMsg 轮询获取
   ↓
3. 消息去重检查（基于消息指纹）
   ↓
4. 解析消息类型和内容
   - 文本 (type=1): 直接提取
   - 图片 (type=3): 提取CDN URL并下载
   - XML (type=49): 解析引用回复、文件信息
   ↓
5. 权限验证
   - DM策略：open/pairing/allowlist/disabled
   - 群组策略：检查群组allowFrom
   - 提及要求：群组中是否@机器人
   ↓
6. 触发前缀过滤（如 "@ai"）
   ↓
7. 会话路由（session.dmScope: per-peer/per-account）
   ↓
8. 构建AI上下文包
   - 消息内容
   - 媒体附件
   - 历史记录
   ↓
9. 分发到AI Agent
   ↓
10. 记录消息到历史
```

### 2. 消息发送流程

```
1. AI Agent生成回复
   ↓
2. Channel插件接收回复
   ↓
3. 解析回复内容
   - 文本内容
   - 媒体URL（MEDIA:/path或http://）
   ↓
4. 文本分块（超过4000字符时）
   ↓
5. 发送处理
   - 纯文本：调用 SendTextMessage
   - 图片：转换为base64，调用 SendImageNewMessage
   - 文件：上传到CDN (UploadFileToCDN)，然后发送 (SendAppMessage)
   ↓
6. 添加回复前缀（如 "🤖 "）
   ↓
7. 通过WeChatPadPro REST API发送
   ↓
8. 返回消息ID
```

### 3. 认证登录流程

```
1. 启动Gateway
   ↓
2. 检查登录状态：GET /login/GetLoginStatus
   ↓
3. 如果未登录：
   a) 获取QR码：POST /login/GetLoginQrCodeNewX
   b) 在终端显示QR码
   ↓
4. 轮询登录状态：GET /login/CheckLoginStatus
   - state=0: 等待扫码
   - state=1: 已扫码，等待确认
   - state=2: 已确认登录
   ↓
5. 登录成功后获取wxid
   ↓
6. 开始消息监控循环
```

---

## 四、配置要求

### 基础配置

```json
{
  "channels": {
    "wechat": {
      "enabled": true,
      "serverUrl": "http://localhost:8849",
      "token": "YOUR_TOKEN_KEY"
    }
  }
}
```

### 完整配置示例

```json
{
  "channels": {
    "wechat": {
      "enabled": true,
      "serverUrl": "http://localhost:8849",
      "token": "YOUR_TOKEN_KEY",
      
      // 访问策略
      "dmPolicy": "pairing",           // open | pairing | allowlist | disabled
      "allowFrom": [],                 // DM白名单
      "groupPolicy": "allowlist",       // open | allowlist | disabled
      "groupAllowFrom": [],            // 群组白名单
      "requireMention": true,           // 群组是否需要@提及
      
      // 触发和显示
      "triggerPrefix": "@ai",          // 消息触发前缀
      "replyPrefix": "🤖 ",           // AI回复前缀
      
      // 限制和调试
      "historyLimit": 10,              // 群组历史记录数
      "mediaMaxMb": 20,               // 最大媒体文件（MB）
      "textChunkLimit": 4000,         // 文本分块限制
      "debugMessages": false,         // 调试消息日志
      
      // 多账户支持
      "accounts": {
        "account2": {
          "enabled": true,
          "serverUrl": "http://localhost:8850",
          "token": "ANOTHER_TOKEN"
        }
      }
    }
  },
  "session": {
    "dmScope": "per-peer"  // per-peer | per-account
  }
}
```

### 依赖要求

1. **WeChatPadPro 服务**
   - 运行在本地或可访问的服务器
   - 默认端口：8849
   - 需要生成 TOKEN_KEY

2. **OpenClaw 安装**
   ```bash
   npm install -g openclaw
   openclaw plugins install @icesword760/openclaw-wechat
   ```

3. **系统依赖**
   - Node.js >= 18
   - qrcode-terminal（自动安装）

---

## 五、限制和注意事项

### 1. 技术限制

#### 消息类型限制
- ✅ **支持：** 文本消息、图片消息、引用回复、文件传输
- ❌ **不支持：** 语音消息（仅占位符）、视频消息（仅占位符）、小程序
- ⚠️ **部分支持：** XML消息（提取标题和引用，忽略复杂结构）

#### 消息长度限制
- 单条文本消息最大：**4000 字符**
- 超长消息自动分块发送（按换行符分割）

#### 群组限制
- 群组中必须 **@提及机器人** 才会响应（可配置 `requireMention: false`）
- 群组消息格式特殊：`sender_wxid:\ncontent`
- 群组无法获取完整成员列表

### 2. 安全限制

#### 认证机制
- **WeChatPadPro TOKEN_KEY** 作为认证凭据
- 没有额外的加密层（依赖HTTPS/TLS）
- TOKEN_KEY 需要安全存储，建议使用环境变量

#### 访问控制
- **DM策略：**
  - `open`: 需要设置 `allowFrom: ["*"]`
  - `pairing`: 用户需先通过配对流程
  - `allowlist`: 仅白名单用户可访问
  - `disabled`: 禁用私信
  
- **群组策略：**
  - `open`: 任何群组（@提及触发）
  - `allowlist`: 仅白名单群组
  - `disabled`: 禁用群组

#### 去重机制
- 使用消息指纹防重复：`accountId:senderId:timestamp:contentHash`
- 重连后可能收到重复消息，自动过滤

### 3. 运行限制

#### 连接稳定性
- 使用 **HTTP轮询** 而非 WebSocket（原计划支持 WS）
- 轮询间隔：**2秒**
- 离线自动重连：30秒重试间隔

#### 并发处理
- 每个账户独立监控循环
- 支持多账户并行运行
- 消息处理是异步的，不会阻塞其他消息

### 4. 企业微信 vs 个人微信

#### 个人微信（WeChatPadPro）
- **协议：** iPad 协议（非官方）
- **实现方式：** 通过 WeChatPadPro 中间件
- **优点：** 支持个人账号，功能完整
- **缺点：** 
  - 非官方协议，可能被微信限制
  - 需要运行中间件服务
  - 不保证长期稳定性

#### 企业微信（未实现）
- **协议：** 官方API
- **实现方式：** 通过企业微信 webhook/API
- **优点：** 官方支持，稳定可靠
- **缺点：** 需要企业认证，仅限企业使用

### 5. 最佳实践建议

1. **安全配置**
   - 使用 `dmPolicy: "pairing"` 默认策略
   - 对敏感群组使用 `groupAllowFrom` 白名单
   - 定期更新 TOKEN_KEY

2. **性能优化**
   - 合理设置 `historyLimit`（默认10）
   - 限制 `mediaMaxMb`（默认20MB）
   - 使用 `triggerPrefix` 减少不必要的AI调用

3. **用户体验**
   - 设置 `replyPrefix` 区分AI回复
   - 在群组中启用 `requireMention`
   - 使用 `triggerPrefix` 避免误触发

4. **调试和监控**
   - 设置 `debugMessages: true` 查看消息日志
   - 监控 `openclaw gateway status`
   - 检查 WeChatPadPro 日志

### 6. 故障排除

#### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| QR码不显示 | WeChatPadPro未运行或token错误 | 检查serverUrl和token |
| 无法登录 | 网络问题或微信限制 | 重试，检查防火墙 |
| 消息不响应 | 权限策略或触发前缀 | 检查dmPolicy、triggerPrefix |
| 图片无法发送 | 文件过大或格式不支持 | 检查mediaMaxMb设置 |
| 重复消息 | 重连导致去重失败 | 检查messageFingerprint逻辑 |

---

## 六、总结

微信接入 OpenClaw 通过 **WeChatPadPro（iPad协议）** 实现个人微信账号的连接，采用 **HTTP轮询** 方式接收消息，通过 **REST API** 发送消息。核心特点包括：

- **灵活的权限控制：** 支持多种DM和群组策略
- **多账户支持：** 可同时管理多个微信账号
- **媒体处理：** 支持图片和文件的双向传输
- **会话隔离：** 每个用户独立的对话上下文
- **可扩展性：** 基于OpenClaw插件架构，易于扩展

主要限制在于依赖非官方协议的 WeChatPadPro，长期稳定性可能受微信反爬机制影响。对于企业级应用，建议使用企业微信官方API实现。

---

## 相关文档

- [OpenClaw 架构概览](./gateway.md)
- [消息处理流程](../MESSAGE_FLOW_DIAGRAM.md)
- [配置指南](../basics/introduction.md)
