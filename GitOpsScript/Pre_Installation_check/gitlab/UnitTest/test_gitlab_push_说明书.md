graph TD
    Start([启动脚本]) --> Judge{判断是否传参数}
    
    Judge -- 有参数 --> ModeProd[生产模式]
    Judge -- 无参数 --> ModeTest[单元测试模式]
    
    ModeProd --> EnterDir[进入目录]
    ModeTest --> EnterDir
    
    EnterDir --> Init{初始化仓库<br>如果需要}
    Init --> SetRemote{设置远程<br>如果提供}
    
    SetRemote --> GitAdd[git add]
    GitAdd --> GitCommit{git commit<br>如果有变更}
    
    GitCommit --> GitPush{git push<br>如果存在 remote}
    GitPush --> End([结束])

    style ModeProd fill:#f96,stroke:#333,stroke-width:2px
    style ModeTest fill:#bbf,stroke:#333,stroke-width:2px
