# 部署到 GitHub Pages 指南

## 方式一：使用 GitHub CLI（推荐）

### 1. 登录 GitHub
```bash
gh auth login
```
选择：
- Where: `GitHub.com`
- Protocol: `HTTPS`
- Authenticate: `Login with a web browser`

### 2. 创建仓库并推送
```bash
cd ~/.openclaw/workspace/tank-battle-mvp
gh repo create tank-battle-mvp --public --source=. --remote=origin --push
```

### 3. 配置 GitHub Pages
```bash
gh repo edit --enable-pages --pages-branch main --pages-path /exports/web
```

或者访问：https://github.com/你的用户名/tank-battle-mvp/settings/pages
- Source: Deploy from a branch
- Branch: `main`
- Folder: `/exports/web`
- 点击 Save

### 4. 等待部署完成（约 1-2 分钟）
访问：https://你的用户名.github.io/tank-battle-mvp/

---

## 方式二：手动创建仓库

### 1. 访问 GitHub 创建仓库
https://github.com/new

- Repository name: `tank-battle-mvp`
- Public
- 不要初始化 README

### 2. 推送代码
```bash
cd ~/.openclaw/workspace/tank-battle-mvp
git remote add origin https://github.com/你的用户名/tank-battle-mvp.git
git push -u origin main
```

### 3. 启用 GitHub Pages
访问：https://github.com/你的用户名/tank-battle-mvp/settings/pages

- Source: Deploy from a branch
- Branch: `main`
- Folder: `/exports/web`
- 点击 Save

### 4. 访问游戏
https://你的用户名.github.io/tank-battle-mvp/

---

## 注意事项

1. **首次部署需要 1-2 分钟**，刷新页面即可
2. **游戏 URL** 会是：`https://你的用户名.github.io/tank-battle-mvp/`
3. **更新游戏**：重新导出 web 版本，提交并推送即可
4. **自定义域名**（可选）：在 Pages 设置中配置

---

## 快速更新游戏

每次修改游戏后：

```bash
cd ~/.openclaw/workspace/tank-battle-mvp

# 重新导出 web 版本
godot --headless --export-release "Web" exports/web/index.html

# 提交并推送
git add exports/web/
git commit -m "Update game"
git push
```

等待 1-2 分钟，刷新页面即可看到更新。
