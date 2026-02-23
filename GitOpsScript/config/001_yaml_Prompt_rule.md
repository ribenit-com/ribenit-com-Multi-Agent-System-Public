# AIDD YAML 生成规约 (AIDD-OCS v1.2)

本文件用于约束 AI 生成 YAML 结构，并支持预定义值直接生成。

| 约束项 | 内容 |
| :-- | :-- |
| 生成范围 | AI 只能在 `AIDD_BLOCK` 区块内生成内容 |
| 禁止行为 | 禁止输出解释性文本 / 禁止修改区块标记 / 禁止新增字段 / 禁止改变字段顺序 |

---

## ⚠ 强制结构规则

每个变量必须严格包含五层结构：

```
name
  ├─ id
  ├─ type
  ├─ description
  └─ constraint
        ├─ 参照 rule_BLOCK 区域
        └─ 参照 rule_BLOCK 区域
```

---

## ⚠ 强制字段规则

| 规则 | 说明 |
| :-- | :-- |
| 必填字段 | `constraint` / `type` / `rule` / `error_message` |
| 字段限制 | 不允许出现未定义字段 |
| 变量命名 | 必须大写 + 下划线风格 |
| id 格式 | 必须为 8 位唯一字符串 |

---

## ⚠ 预定义值生成规则

| 规则 | 说明 |
| :-- | :-- |
| 标准值使用 | 所有字段值如有现成标准值，必须原封不动地使用 |
| 不可更改字段 | `id` / `value` / `description` / `rule` |

预定义值格式（必须严格使用）：

```
9f8b7c6a    DB_HOST    string    数据库后端通信地址    check_ip
```

## ⚠ 预定义值生成规则

## rule_BLOCK_START

| 标志 (ID) | 变量名 | 当前值 |
| :--- | :--- | :--- |
| `逻辑说明` | **Logic** | `必须` |
| `禁止行为` | **ProhibitedActions** | `非必须` |
| `正则参考` | **RegexReference** | `非必须` |
| `数值边界` | **ValueLimits** | `非必须` |
| `允许值` | **AllowedValues** | `非必须` |
| `匹配规则` | **MatchingRules** | `非必须` |



```
当然值字段为`必须`  的场景
| `逻辑说明` | **Logic** | `必须` |
是在yaml中必须展示的字段，字段值如有现成标准值，必须原封不动地使用。

当然值字段为`非必须`  的场景 
| `禁止行为` | **ProhibitedActions** | `非必须` |
1. 如果存在的字段，就要展示在yaml中，字段值如有现成标准值，必须原封不动地使用。 
2. 如果不存在，就不展示在yaml中。
```

## rule_BLOCK_END

---

## AIDD_BLOCK_START:variables

```yaml
DB_HOST:
  id: 9f8b7c6a
  value: string
  description: 数据库后端通信地址
  constraint:
    rule: "check_ip"
    error_message: "必须为合法 IPv4 地址"
```

## AIDD_BLOCK_END:variables

---

## 输出行为约束

| 项目 | 要求 |
| :-- | :-- |
| 代码块数量 | 只输出一个 `yaml` 代码块 |
| 额外内容 | 不输出 markdown 解释 / 不输出注释 |
| 结构 | 不改变结构层级 / 不修改区块标记 |
| 字段值 | 严格使用预定义值生成字段内容 |

---

## 违规定义

| 违规情形 |
| :-- |
| 缺少 `constraint` |
| 缺少 `error_message` |
| 出现未知字段 |
| 改变字段顺序 |
| 输出额外说明文字 |
| 生成多个代码块 |
| 使用非预定义值替代已有标准值 |

---

## 版本

```
schema_version: AIDD-OCS-1.2
```
