# Git 自动上传脚本 Workflow Breakdown

```mermaid
flowchart TD
    Start([启动脚本]) --> SafeMode[加载安全模式<br>set -e, -u, pipefail]
    SafeMode --> CheckParams{判断是否传参数}
    
    CheckParams -->|有参数 >=2| ProdMode[进入生产模式]
    ProdMode --> SetProdVars[LOCAL_DIR = $1<br>REMOTE_URL = $2<br>BRANCH = $3 或默认 master]
    
    CheckParams -->|无参数| TestMode[进入单元测试兼容模式]
    TestMode --> SetTestVars[LOCAL_DIR = pwd<br>REMOTE_URL = 空<br>BRANCH = 当前分支或默认 master]
    
    SetProdVars --> ChangeDir[cd LOCAL_DIR]
    SetTestVars --> ChangeDir
    
    ChangeDir --> CheckGit{检查是否已初始化<br>Git 仓库}
    CheckGit -->|不存在 .git| GitInit[git init]
    CheckGit -->|已存在| CheckRemote
    
    GitInit --> CheckRemote
    
    CheckRemote{设置远程仓库<br>仅生产模式} -->|REMOTE_URL 不为空| CheckOrigin{检查 origin 是否存在}
    CheckOrigin -->|存在 origin| SetOrigin[git remote set-url origin]
    CheckOrigin -->|不存在 origin| AddOrigin[git remote add origin]
    
    CheckRemote -->|REMOTE_URL 为空| SkipRemote[跳过远程设置]
    SetOrigin --> GitAdd
    AddOrigin --> GitAdd
    SkipRemote --> GitAdd
    
    GitAdd[git add .] --> CheckChanges{检查是否有变更}
    
    CheckChanges -->|无变更| NoChanges[输出<br>没有变更可提交]
    CheckChanges -->|有变更| Commit[git commit -m "auto commit"]
    
    Commit --> CheckOriginExists{检查是否存在<br>远程 origin}
    
    CheckOriginExists -->|存在| Push[git push -u origin BRANCH]
    CheckOriginExists -->|不存在| SkipPush[输出<br>跳过 push]
    
    NoChanges --> OutputDone[输出执行完成信息]
    Push --> OutputDone
    SkipPush --> OutputDone
    
    OutputDone --> End([结束])
