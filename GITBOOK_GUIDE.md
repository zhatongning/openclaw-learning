# GitBook 部署指南

本指南帮助你将 OpenClaw 学习笔记发布到 GitBook。

## 📦 安装 GitBook CLI

### 方法 1：使用 npm

```bash
npm install -g gitbook-cli
```

### 方法 2：使用 yarn

```bash
yarn global add gitbook-cli
```

## 🚀 初始化项目

### 1. 进入项目目录

```bash
cd /Users/zha/.openclaw/workspace/openclaw-learning
```

### 2. 安装依赖

```bash
gitbook install
```

### 3. 本地预览

```bash
gitbook serve
```

访问 `http://localhost:4000` 查看效果。

### 4. 构建静态文件

```bash
gitbook build
```

生成的静态文件在 `_book/` 目录。

## 📤 发布到 GitBook.com

### 方法 1：使用 GitBook.com（推荐）

1. **创建 GitBook 账号**
   - 访问 https://www.gitbook.com
   - 注册并登录

2. **创建新书**
   - 点击 "Create new book"
   - 选择 "Import from GitHub" 或 "Upload files"

3. **同步 GitHub 仓库**
   ```bash
   # 初始化 git 仓库
   git init
   git add .
   git commit -m "Initial commit"
   
   # 推送到 GitHub
   git remote add origin https://github.com/yourusername/openclaw-learning.git
   git push -u origin master
   ```

4. **在 GitBook 连接仓库**
   - Settings → GitHub → Connect
   - 选择你的仓库
   - 设置自动同步

### 方法 2：使用 GitBook CLI

```bash
# 登录 GitBook
gitbook login

# 创建新书
gitbook create openclaw-learning

# 发布
gitbook publish
```

## 🔧 高级配置

### 自定义域名

1. 在 GitBook 项目设置中添加自定义域名
2. 配置 DNS CNAME 记录
3. 等待 DNS 生效

### 主题定制

修改 `book.json`：

```json
{
  "plugins": [
    "theme-api",
    "theme-faq"
  ],
  "pluginsConfig": {
    "theme-api": {
      "theme": "dark"
    }
  }
}
```

### 多语言支持

创建 `LANGS.md`：

```markdown
* [English](en/)
* [中文](zh/)
```

## 📝 内容维护

### 更新内容

1. **编辑文档**
   ```bash
   # 编辑 Markdown 文件
   vim basics/introduction.md
   ```

2. **本地预览**
   ```bash
   gitbook serve
   ```

3. **提交更改**
   ```bash
   git add .
   git commit -m "Update introduction"
   git push
   ```

4. **自动部署**
   - GitBook 会自动检测 GitHub 推送
   - 自动重新构建和部署

### 版本管理

```bash
# 创建新版本
git tag v1.0.0
git push origin v1.0.0

# 在 GitBook 中查看不同版本
```

## 🎨 样式定制

### 自定义 CSS

编辑 `styles/website.css`：

```css
/* 示例：修改标题颜色 */
h1 {
    color: #3498db;
    border-bottom: 2px solid #3498db;
}

/* 示例：修改代码块样式 */
pre code {
    background-color: #282c34;
    color: #abb2bf;
}
```

### 自定义模板

创建 `layouts/` 目录，添加自定义模板。

## 📊 分析和统计

### Google Analytics

在 `book.json` 中添加：

```json
{
  "plugins": ["google-analytics"],
  "pluginsConfig": {
    "google-analytics": {
      "token": "UA-XXXXXXXXX-X"
    }
  }
}
```

### 访问统计

使用 `pageview-count` 插件：

```json
{
  "plugins": ["pageview-count"],
  "pluginsConfig": {
    "pageview-count": {
      "position": "top"
    }
  }
}
```

## 🔗 分享和推广

### 社交分享

在 `book.json` 中配置：

```json
{
  "plugins": ["sharing-plus"],
  "pluginsConfig": {
    "sharing": {
      "weibo": true,
      "qq": true,
      "qzone": true
    }
  }
}
```

### 生成分享链接

```bash
# 在 GitBook 项目页面
Settings → Sharing → Generate Link
```

## 🐛 常见问题

### 1. 构建失败

**问题**：`gitbook build` 失败

**解决**：
```bash
# 清除缓存
gitbook clean

# 重新安装依赖
gitbook install

# 再次构建
gitbook build
```

### 2. 插件安装失败

**问题**：某些插件安装失败

**解决**：
```bash
# 使用淘宝镜像
npm config set registry https://registry.npm.taobao.org

# 重新安装
gitbook install
```

### 3. 样式不生效

**问题**：自定义 CSS 不生效

**解决**：
- 检查 `book.json` 中的 `styles` 配置
- 清除浏览器缓存
- 使用 `gitbook serve` 重新启动

### 4. GitHub 同步失败

**问题**：GitBook 无法同步 GitHub 仓库

**解决**：
- 检查 GitHub 权限设置
- 确保 webhook 配置正确
- 手动触发同步

## 📚 更多资源

- [GitBook 官方文档](https://docs.gitbook.com)
- [GitBook CLI 文档](https://github.com/GitbookIO/gitbook-cli)
- [GitBook 插件市场](https://plugins.gitbook.com)
- [GitBook 社区](https://community.gitbook.com)

## 🎯 下一步

1. ✅ 完成基础文档编写
2. ✅ 发布到 GitBook.com
3. ⬜ 添加更多实践案例
4. ⬜ 收集读者反馈
5. ⬜ 持续更新内容

---

**需要帮助？** 
- 查看 [GitBook 官方文档](https://docs.gitbook.com)
- 在 [GitHub Issues](https://github.com/yourusername/openclaw-learning/issues) 提问
- 加入 [Discord 社区](https://discord.gg/clawd) 讨论
