==============================================
Git 自动上传脚本 Workflow Breakdown
==============================================

启动脚本
   ↓
加载安全模式
   - set -e   （命令失败立即退出）
   - set -u   （未定义变量报错）
   - pipefail （管道中任意命令失败则整体失败）
   ↓
判断是否传参数
   ├── 有参数（>=2）
   │     → 进入【生产模式】
   │     → LOCAL_DIR = $1
   │     → REMOTE_URL = $2
   │     → BRANCH = $3（默认 master）
   │
   └── 无参数
         → 进入【单元测试兼容模式】
         → LOCAL_DIR = 当前目录 (pwd)
         → REMOTE_URL = 空
         → BRANCH = 当前分支或默认 master
   ↓
进入目标目录
   - cd LOCAL_DIR
   ↓
检查是否已初始化 Git 仓库
   ├── 如果不存在 .git
   │     → 执行 git init
   └── 如果已存在
         → 跳过
   ↓
设置远程仓库（仅生产模式）
   ├── 如果 REMOTE_URL 不为空
   │     ├── 已存在 origin
   │     │       → git remote set-url origin
   │     └── 不存在 origin
   │             → git remote add origin
   └── 如果 REMOTE_URL 为空
         → 跳过远程设置
   ↓
添加文件到暂存区
   - git add .
   ↓
检查是否有变更
   ├── 无变更
   │     → 输出“没有变更可提交”
   └── 有变更
         → git commit -m "auto commit"
   ↓
检查是否存在远程 origin
   ├── 存在
   │     → git push -u origin BRANCH
   └── 不存在
         → 输出“跳过 push”
   ↓
输出执行完成信息
   ↓
结束
