#!/bin/bash
# 指定解释器为 bash

set -euo pipefail
# -e: 脚本遇到错误立即退出
# -u: 未定义变量使用时报错
# -o pipefail: 管道中任意命令失败都会导致整个管道失败

ENVIRONMENT="${1:-prod}"
# 从第一个参数获取环境变量，如未提供则默认为 prod

MODE="${2:-audit}"
# 从第二个参数获取模式，如未提供则默认为 audit

# JSON 条目数组
json_entries=()
# 用于存储后续检查的 JSON 条目结果

#######################################
# kubectl 抽象层
#######################################
# 逻辑: 封装 kubectl 调用，方便统一管理
# 输入: kubectl 命令及参数
# 输出: kubectl 命令执行结果
kctl() {
  kubectl "$@"
}

#######################################
# 添加 JSON 条目
#######################################
# 逻辑: 将检查结果转换成 JSON 并保存到数组
# 输入: JSON 字符串
# 输出: 无（会追加到 json_entries 数组）
add_entry() {
  json_entries+=("$1")
}

#######################################
# 检查 Namespace
#######################################
# 逻辑: 验证指定 Namespace 是否存在
# 输入: ENVIRONMENT (脚本全局变量)
# 输出: JSON 条目记录 Namespace 状态（存在/不存在/警告）
check_namespace() {
  ns="ns-mid-storage-$ENVIRONMENT"
  # 构造 Namespace 名称，例如 ns-mid-storage-prod

  if kctl get ns "$ns" >/dev/null 2>&1; then
    # 尝试获取 Namespace，成功则存在
    add_entry "{\"resource_type\":\"Namespace\",\"name\":\"$ns\",\"status\":\"存在\"}"
  else
    status=$([[ "$MODE" == "enforce" ]] && echo "警告" || echo "不存在")
    add_entry "{\"resource_type\":\"Namespace\",\"name\":\"$ns\",\"status\":\"$status\"}"
  fi
}

#######################################
# 检查 Service
#######################################
# 逻辑: 验证指定 Service 是否存在于 Namespace 下
# 输入: ENVIRONMENT (脚本全局变量)
# 输出: JSON 条目记录 Service 状态（存在/不存在）
check_service() {
  svc="gitlab"
  if kctl -n "ns-mid-storage-$ENVIRONMENT" get svc "$svc" >/dev/null 2>&1; then
    add_entry "{\"resource_type\":\"Service\",\"name\":\"$svc\",\"status\":\"存在\"}"
  else
    add_entry "{\"resource_type\":\"Service\",\"name\":\"$svc\",\"status\":\"不存在\"}"
  fi
}

#######################################
# 检查 PVC
#######################################
# 逻辑: 验证 Namespace 下的 PVC 是否符合命名规范
# 输入: ENVIRONMENT (脚本全局变量)
# 输出: JSON 条目记录每个 PVC 的命名状态（命名规范/命名不规范）
check_pvc() {
  pvc_list=$(kctl -n "ns-mid-storage-$ENVIRONMENT" get pvc -o name 2>/dev/null || true)
  for pvc in $pvc_list; do
    name=$(basename "$pvc")
    if [[ "$name" =~ ^pvc-.*-[0-9]+$ ]]; then
      status="命名规范"
    else
      status="命名不规范"
    fi
    add_entry "{\"resource_type\":\"PVC\",\"name\":\"$name\",\"status\":\"$status\"}"
  done
}

#######################################
# 检查 Pod
#######################################
# 逻辑: 获取 Namespace 下 Pod 列表并记录状态
# 输入: ENVIRONMENT (脚本全局变量)
# 输出: JSON 条目记录每个 Pod 的状态（Running/Pending/CrashLoopBackOff 等）
check_pod() {
  pod_list=$(kctl -n "ns-mid-storage-$ENVIRONMENT" get pods --no-headers 2>/dev/null || true)
  while read -r line; do
    [[ -z "$line" ]] && continue
    name=$(echo "$line" | awk '{print $1}')
    status=$(echo "$line" | awk '{print $3}')
    add_entry "{\"resource_type\":\"Pod\",\"name\":\"$name\",\"status\":\"$status\"}"
  done <<< "$pod_list"
}

#######################################
# 输出 JSON
#######################################
# 逻辑: 汇总检查结果数组并输出标准 JSON
# 输入: json_entries 数组
# 输出: JSON 数组，包含 Namespace/Service/PVC/Pod 的检查结果
main() {
  check_namespace
  check_service
  check_pvc
  check_pod

  echo "["
  local first=true
  for entry in "${json_entries[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    echo -n "$entry"
  done
  echo
  echo "]"
}

#######################################
# 可执行入口
#######################################
# 逻辑: 判断脚本是否被直接执行，如果是则调用 main
# 输入: 脚本参数
# 输出: main 函数的 JSON 检查结果
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
