
# 🚀 AIDD 驱动开发：AI智能生成-语义约束中心 
 
> **[AI 指令]**：本文件为系统的“唯一真理源”。解析表格数据前，必须优先读取【约束语义定义区】。
> 禁止AI自行猜测逻辑。若变量值违反约束锚点，请通过【项目智能专家】频道报告错误 ID。

# 【config.sh】
 
## ⚖️ 1. 约束语义定义区 (AI 逻辑宪法)
*本区块定义物理边界。点击下方各变量的“约束校验”可快速跳转至此。*
<!-- AIDD_BLOCK_START:constraint_center_b8e4d1f2c9 -->
* <a name="rule_ip"></a> **`check_ip` (IP地址约束)**
    * **逻辑说明**: 必须符合标准 IPv4 格式。
    * **禁止行为**: 严禁包含协议头（http://）、路径、空格或端口号。
    * **正则参考**: `^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$`

* <a name="rule_port"></a> **`port_range` (端口约束)**
    * **逻辑说明**: 系统服务可用端口范围。
    * **数值边界**: `1024` ≤ $x$ ≤ `65535` 的整数。

* <a name="rule_env"></a> **`env_enum` (环境约束)**
    * **逻辑说明**: 严格限定软件运行生命周期。
    * **允许值**: `dev` (开发), `prod` (生产), `test` (测试)。*注意：大小写敏感。* 

* <a name="rule_com"></a> **`com_path` (POS外设串口约束)**
    * **逻辑说明**: 针对收银机边缘设备（打印机、钱箱）的物理路径。
    * **匹配规则**: Windows 下为 `COM` + 数字；Linux 下为 `/dev/ttyS` 或 `/dev/ttyUSB` + 数字。
<!-- AIDD_BLOCK_END:constraint_center_b8e4d1f2c9 -->
---


| 标志 (ID) | 变量名 | 当前值 |
| :--- | :--- | :--- |
| `逻辑说明` | **Logic** | `必须` |
| `禁止行为` | **ProhibitedActions** | `非必须` |
| `正则参考` | **RegexReference** | `非必须` |
| `数值边界` | **ValueLimits** | `非必须` |
| `允许值` | **AllowedValues** | `非必须` |
| `匹配规则` | **MatchingRules** | `非必须` |



## 📋 2. 变量定义中心 (人机交互表)
*修改此表后，系统将自动通过脚本同步至 YAML 及 n8n 工作流。*

<!-- AIDD_BLOCK_START:a7f3c9d2e1 -->
| 标志 (ID) | 变量名 | 字段类型 | 描述说明 | 约束校验 (点击跳转) |
| :--- | :--- | :--- | :--- | :--- |
| `9f8b7c6a` | **DB_HOST** | `String` | 数据库后端通信地址 | [`check_ip`](#rule_ip) |
| `2a4d1e3f` | **DB_PORT** | `int` | 数据库服务监听端口 | [`port_range`](#rule_port) |
| `8e2f5b4a` | **ENV** | `String` | 当前软件运行环境模式 | [`env_enum`](#rule_env) |
| `d3c2b1a0` | **POS_PRINTER** | `String` | **[POS特供]** 打印机串口地址 | [`com_path`](#rule_com) |
<!-- AIDD_BLOCK_END:a7f3c9d2e1 -->
---

## 🛠️ 3. 系统维护说明
1. **快速定位**: 在编辑器中按住 `Ctrl` 点击【约束校验】列的链接，可直接跳转到顶部规则。
2. **全局搜索**: 每一个变量都绑定了唯一的 **UUID (标志ID)**，可直接在代码库中搜索该 ID 实现全链路追踪。
3. **闭环反馈**: 当“智能体运维”检测到 LOG 异常时，会根据 ID 自动回溯至本文件进行逻辑校准。

---
*Last Updated: 2026-02-23 | Powered by AIDD Method*
