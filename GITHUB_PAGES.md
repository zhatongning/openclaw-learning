# GitHub Pages 部署指南

本项目使用 GitHub Pages 免费托管 GitBook 静态网站。

## 🚀 自动部署（推荐）

### 步骤 1：推送代码到 GitHub

```bash
cd /Users/zha/.openclaw/workspace/openclaw-learning
git add .
git commit -m "✨ 添加 GitHub Pages 自动部署"
git push
```

### 步骤 2：启用 GitHub Pages

1. 访问仓库设置页面
   ```
   https://github.com/zhatongning/openclaw-learning/settings/pages
   ```

2. 在 "Build and deployment" 部分：
   - **Source**: 选择 "GitHub Actions"
   - **Branch**: 不需要选择（会自动部署）

3. 保存设置

### 步骤 3：等待部署

- GitHub Actions 会自动运行
- 大约 2-3 分钟完成部署
- 访问地址：
  ```
  https://zhatongning.github.io/openclaw-learning
  ```

## 📦 手动部署（备用方案）

如果自动部署失败，可以手动构建：

### 方法 1：使用脚本

```bash
# 运行部署脚本
./deploy.sh
```

### 方法 2：手动步骤

```bash
# 1. 安装 GitBook CLI
npm install -g gitbook-cli

# 2. 安装依赖
gitbook install

# 3. 构建静态文件
gitbook build

# 4. 部署到 gh-pages 分支
cd _book
git init
git add .
git commit -m "Deploy to GitHub Pages"
git push -f git@github.com:zhatongning/openclaw-learning.git main:gh-pages
```

## 🎨 自定义域名（可选）

### 使用自定义域名

1. 在项目根目录创建 `CNAME` 文件：
   ```bash
   echo "yourdomain.com" > CNAME
   ```

2. 配置 DNS 记录：
   - **A 记录**：指向 GitHub Pages IP
     - 185.199.108.153
     - 185.199.109.153
     - 185.199.110.153
     - 185.199.111.153
   - 或 **CNAME 记录**：指向 `zhatongning.github.io`

3. 在 GitHub Pages 设置中添加自定义域名

4. 等待 DNS 生效（可能需要几分钟到几小时）

## 🔄 更新内容

### 自动更新（推荐）

每次推送到 `main` 分支，GitHub Actions 会自动重新部署：

```bash
# 修改文件后
git add .
git commit -m "📝 更新内容"
git push
```

### 手动触发部署

在 GitHub Actions 页面手动触发工作流：
```
https://github.com/zhatongning/openclaw-learning/actions
```

## 📊 查看部署状态

### GitHub Actions 日志

访问 Actions 页面查看构建和部署日志：
```
https://github.com/zhatongning/openclaw-learning/actions
```

### 部署历史

在 Pages 设置页面查看部署历史：
```
https://github.com/zhatongning/openclaw-learning/settings/pages
```

## 🐛 常见问题

### 1. 部署失败

**问题**：GitHub Actions 构建失败

**解决**：
- 检查 Actions 日志
- 确认 Node.js 版本正确（22）
- 本地测试构建：`gitbook build`

### 2. 页面 404

**问题**：访问显示 404

**解决**：
- 确认 GitHub Pages 已启用
- 检查是否选择了正确的源（GitHub Actions）
- 等待几分钟让部署完成

### 3. 样式不加载

**问题**：CSS/JS 文件不加载

**解决**：
- 在 `book.json` 中配置 `base` 路径
- 或使用绝对路径引用资源

### 4. 自定义域名不生效

**问题**：域名解析失败

**解决**：
- 检查 DNS 配置
- 确认 CNAME 文件正确
- 等待 DNS 传播

## 📈 性能优化

### 1. 启用缓存

GitHub Actions 已配置 npm 缓存，加速构建。

### 2. 压缩资源

GitBook 会自动压缩 HTML/CSS/JS。

### 3. 使用 CDN

GitHub Pages 自带全球 CDN，无需额外配置。

## 🔒 安全设置

### 1. 强制 HTTPS

在 Pages 设置中启用 "Enforce HTTPS"。

### 2. 自定义 404 页面

创建 `404.md` 文件，GitBook 会自动处理。

## 📱 移动端优化

GitBook 默认响应式设计，适配移动设备。

## 🔗 相关链接

- **在线地址**: https://zhatongning.github.io/openclaw-learning
- **GitHub 仓库**: https://github.com/zhatongning/openclaw-learning
- **Actions**: https://github.com/zhatongning/openclaw-learning/actions
- **Pages 设置**: https://github.com/zhatongning/openclaw-learning/settings/pages

---

**下一步**：推送代码并启用 GitHub Pages！
