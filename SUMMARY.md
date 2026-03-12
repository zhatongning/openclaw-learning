# OpenClaw 源码学习笔记

* [首页](README.md)
* [如何使用](how-to-use.md)

---

## 📚 基础篇

* [项目介绍](basics/introduction.md)
  * 什么是 OpenClaw
  * 为什么学习
  * 技术栈
  
* [核心概念](basics/core-concepts.md)
  * Gateway 网关
  * Agent 助手
  * Memory 讋忆
  * Skills 技能
  * Extensions 扩展

---

## 🏗️ 架构篇
* [整体架构](architecture/overview.md)
  * 架构图
  * 核心组件
  * 数据流
  
* [Gateway 网关详解](architecture/gateway.md)
  * 核心职责
  * WebSocket 协议
  * 认证与配对
  * 会话管理
  * 事件分发
  * 配置与安全
  
* [Agent 助手详解](architecture/agent.md)
  * 消息处理
  * 上下文构建
  * 模型调用
  * 工具执行
  * 响应生成
  * 技能集成
  
* [Memory 记忆详解](architecture/memory.md)
  * 短期记忆
  * 长期记忆
  * 向量存储
  * HNSW 索引
  * 配置与优化

---

## 🎯 学习路径

### 初学者路径
1. [项目介绍](basics/introduction.md) - 了解 OpenClaw
2. [核心概念](basics/core-concepts.md) - 理解基础概念
3. [整体架构](architecture/overview.md) - 掌握整体设计
4. [Gateway 网关](architecture/gateway.md) - 深入控制平面
5. [Agent 助手](architecture/agent.md) - 学习智能核心
6. [Memory 记忆](architecture/memory.md) - 了解记忆系统

### 有经验者路径
1. [整体架构](architecture/overview.md) - 快速了解
2. [Gateway 网关](architecture/gateway.md) - 选择感兴趣的模块
3. [Agent 助手](architecture/agent.md) - 深入实现细节
4. [Memory 记忆](architecture/memory.md) - 优化性能

---

## 🔗 相关链接
* [OpenClaw 官方文档](https://docs.openclaw.ai)
* [GitHub 仓库](https://github.com/openclaw/openclaw)
* [Discord 社区](https://discord.gg/clawd)
* [本项目 GitHub](https://github.com/zhatongning/openclaw-learning)
