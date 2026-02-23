# Shell 脚本说明 · 生成项目全局 YAML 配置

## 概述

| 项目 | 说明 |
|------|------|
| 执行环境 | Ubuntu |
| 输入来源 | `GlobalDoc-config.md` 中的 AIDD_BLOCK 区块 |
| 输出文件 | `global-config.yaml`，供项目全局调用 |
| 用法 | `bash generate_global_config.sh [output_file]` |

---

## 文档结构（写入内容）

```
https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/refs/heads/main/GitOpsScript/GlobalDoc-config.md
```

```
参照↑地址
给我一段Shell代码
执行环境：ubuntu
目的: 参照内容，生成Yaml格式的文件, 供项目全局调用
```

### 1. 约束语义定义区
```html
<!-- AIDD_BLOCK_START:constraint_center_b8e4d1f2c9 -->
中间为项目用参数定义区域
<!-- AIDD_BLOCK_END:constraint_center_b8e4d1f2c9 -->
```

### 2. 变量定义中心

```html
<!-- AIDD_BLOCK_START:a7f3c9d2e1 -->
中间为项目用参数定义区域
<!-- AIDD_BLOCK_END:a7f3c9d2e1 -->
```

---

```
按照如上的规约生成Yaml, yaml的生成模板规约参照↓
https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/refs/heads/main/GitOpsScript/config/001_yaml_Prompt_rule.md
```

> AIDD_BLOCK 标记以 YAML 注释形式原样保留，AI 按标记定位区块，人类在对应区域直接填写 `key: value` 参数。
