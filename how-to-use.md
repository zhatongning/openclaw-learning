# 如何使用本学习笔记

## 📖 阅读方式

### 在线阅读（推荐）

1. **GitBook 在线版**（即将发布）
   - 访问 GitBook.com
   - 搜索 "OpenClaw 源码学习笔记"
   - 支持评论和标注

2. **GitHub Pages**
   - 访问 GitHub 仓库
   - 启用 GitHub Pages
   - 查看 _book 目录

### 本地阅读

#### 方法 1：GitBook CLI

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/openclaw-learning.git
cd openclaw-learning

# 2. 安装依赖
npm install -g gitbook-cli
gitbook install

# 3. 启动本地服务器
gitbook serve

# 4. 访问
open http://localhost:4000
```

#### 方法 2：直接查看 Markdown

```bash
# 使用你喜欢的 Markdown 编辑器
code .  # VS Code
typora  # Typora
```

## 🎯 学习路径

### 初学者路径（4-6 周）

**第 1 周：基础概念**
- [ ] 阅读项目介绍
- [ ] 理解核心概念
- [ ] 完成快速开始

**第 2 周：架构理解**
- [ ] 学习整体架构
- [ ] 理解 Gateway 作用
- [ ] 了解 Agent 实现

**第 3-4 周：实践应用**
- [ ] 搭建开发环境
- [ ] 创建第一个 Skill
- [ ] 开发简单 Extension

**第 5-6 周：深入理解**
- [ ] 阅读源码分析
- [ ] 理解消息流程
- [ ] 学习协议实现

### 有经验开发者路径（2-4 周）

**第 1 周：快速了解**
- [ ] 浏览整体架构
- [ ] 查看关键组件
- [ ] 理解设计思路

**第 2 周：重点突破**
- [ ] 选择感兴趣的模块
- [ ] 深入源码分析
- [ ] 实践开发

**第 3-4 周：进阶应用**
- [ ] 性能优化
- [ ] 安全机制
- [ ] 贡献代码

## 💡 学习建议

### 1. 边看边做

**不要只看不练**：
- 每看完一章，就动手实践
- 修改代码观察效果
- 记录遇到的问题

**示例**：
```bash
# 看完 Gateway 章节后
cd openclaw-source
openclaw gateway --verbose  # 启动并观察日志
```

### 2. 循序渐进

**不要跳级**：
- 先理解基础再深入
- 不要一开始就看复杂代码
- 打好基础最重要

**建议顺序**：
1. 基础概念 → 架构理解 → 源码分析 → 进阶应用

### 3. 多问多交流

**不要闷头苦学**：
- 加入 Discord 社区
- 在 GitHub 提 Issue
- 和其他学习者讨论

**社区资源**：
- Discord: https://discord.gg/clawd
- GitHub: https://github.com/openclaw/openclaw
- Discussions: https://github.com/openclaw/openclaw/discussions

### 4. 做好笔记

**记录你的学习**：
- 使用这个笔记模板
- 添加你的理解
- 记录遇到的问题和解决方案

**笔记建议**：
```markdown
## 2026-03-12 学习笔记

### 学到了什么
- Gateway 的 WebSocket 协议
- Agent 的消息处理流程

### 遇到的问题
- 问题：WebSocket 连接失败
- 解决：检查端口占用

### 明天计划
- 学习 Memory 系统
- 创建一个简单的 Skill
```

## 🛠️ 实践项目建议

### 初级项目（1-2 周）

1. **天气查询 Skill**
   - 调用天气 API
   - 返回格式化结果
   - 错误处理

2. **简单的计算器 Skill**
   - 解析数学表达式
   - 返回计算结果
   - 支持基本运算

### 中级项目（2-4 周）

1. **GitHub 仓库信息查询 Skill**
   - 调用 GitHub API
   - 显示仓库统计
   - 支持搜索

2. **简单的 Telegram Bot Extension**
   - 接收消息
   - 处理命令
   - 发送响应

### 高级项目（4-8 周）

1. **向量搜索 Skill**
   - 集成向量数据库
   - 实现语义搜索
   - 支持文档索引

2. **自定义渠道 Extension**
   - 选择一个新渠道
   - 实现消息收发
   - 处理特殊事件

## 📚 推荐阅读顺序

### 必读章节

1. **项目介绍** - 了解 OpenClaw 是什么
2. **核心概念** - 理解基础架构
3. **整体架构** - 深入理解设计
4. **消息处理流程** - 理解核心流程

### 选读章节

- **性能优化** - 有一定基础后阅读
- **安全机制** - 对安全感兴趣时阅读
- **测试策略** - 准备贡献代码时阅读

## 🔍 深入学习技巧

### 1. 画图理解

**使用图表帮助理解**：
```
用户 → Telegram → Gateway → Agent → Model
```

**推荐工具**：
- Draw.io
- Excalidraw
- Mermaid

### 2. 调试跟踪

**使用调试工具**：
```bash
# 启动详细日志
openclaw gateway --verbose

# 查看网络请求
# Chrome DevTools → Network → WS
```

### 3. 代码导航

**使用 IDE 功能**：
- VS Code: Ctrl+点击跳转定义
- 查找引用: Shift+F12
- 查看类型定义

### 4. 单元测试

**通过测试理解代码**：
```bash
# 运行测试
npm test

# 运行特定测试
npm test -- gateway.test.ts
```

## 🤝 贡献本笔记

### 如何贡献

1. **发现错误**
   - 提 Issue 描述问题
   - 提 PR 修复错误

2. **补充内容**
   - 添加你的理解
   - 分享实践经验
   - 提供更多示例

3. **改进结构**
   - 优化章节组织
   - 添加更多图表
   - 改进代码示例

### 贡献指南

```bash
# 1. Fork 仓库
# 2. 创建分支
git checkout -b feature/add-new-content

# 3. 修改内容
# 编辑 Markdown 文件

# 4. 提交更改
git add .
git commit -m "Add: new content about XXX"

# 5. 推送分支
git push origin feature/add-new-content

# 6. 创建 Pull Request
```

## 📞 获取帮助

### 官方渠道

- **Discord**: https://discord.gg/clawd
- **GitHub Issues**: https://github.com/openclaw/openclaw/issues
- **GitHub Discussions**: https://github.com/openclaw/openclaw/discussions

### 学习交流

- **评论区**: 在 GitBook 页面底部留言
- **社区论坛**: 参与 OpenClaw 社区讨论
- **私信交流**: 通过 Discord 私信作者

## 🎉 学习成果检验

### 自我评估

完成学习后，问自己：

**基础理解**：
- [ ] 能解释 OpenClaw 是什么
- [ ] 理解 Gateway、Agent、Memory 的作用
- [ ] 知道如何安装和配置

**实践能力**：
- [ ] 能创建简单的 Skill
- [ ] 理解消息处理流程
- [ ] 能调试常见问题

**深入理解**：
- [ ] 理解 WebSocket 协议设计
- [ ] 知道插件加载机制
- [ ] 能优化性能问题

**贡献能力**：
- [ ] 能修复简单 bug
- [ ] 能添加新功能
- [ ] 能编写测试用例

## 📅 学习计划模板

### 周计划

```markdown
## 第 X 周学习计划

### 目标
- 学习 XXX 模块
- 完成 YYY 实践项目

### 每日安排
- 周一: 阅读 XXX 章节
- 周二: 实践 YYY 功能
- 周三: 调试 ZZZ 问题
- 周四: 总结笔记
- 周五: 复习巩固

### 完成情况
- [ ] 完成阅读
- [ ] 完成实践
- [ ] 更新笔记
```

## 🎯 下一步行动

1. **选择学习路径**（初学者/有经验）
2. **设置学习环境**（GitBook CLI）
3. **开始第一章**（项目介绍）
4. **边学边做笔记**
5. **参与社区交流**

---

**祝你学习愉快！** 🎉

记住：**学习是一个过程，不是终点**。保持好奇心，享受学习的乐趣！
