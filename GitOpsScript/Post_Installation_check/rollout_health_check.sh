#!/bin/bash
# ===================================================
# 控制器层诊断脚本 — Rollout / Deployment 状态检查
# 版本: v1.0.0
# 功能:
#   - 检查 Deployment / Rollout 是否存在
#   - 检查副本数是否符合期望
#   - 检查更新状态是否正常
#   - 检查 Rollout 健康状态
# ===================================================
set -euo pipefail

NAMESPACE="${NAMESPACE:-ns-gitlab-ha}"
APP_NAME="${APP_NAME:-gitlab}"

# -----------------------------
# 方法定义
# -----------------------------

# 方法: check_rollout_exists
# 目的: 确认 Deployment 或 Rollout 是否存在
check_rollout_exists() {
    echo "🔹 检查 Rollout / Deployment 是否存在..."
    if kubectl -n "$NAMESPACE" get rollout "$APP_NAME" >/dev/null 2>&1; then
        echo "✅ Rollout '$APP_NAME' 存在"
    elif kubectl -n "$NAMESPACE" get deployment "$APP_NAME" >/dev/null 2>&1; then
        echo "✅ Deployment '$APP_NAME' 存在"
    else
        echo "❌ Rollout / Deployment '$APP_NAME' 不存在"
    fi
}

# 方法: check_replicas
# 目的: 确认副本数符合期望，保证服务容量正常
check_replicas() {
    echo "🔹 检查副本数..."
    DESIRED=$(kubectl -n "$NAMESPACE" get deployment "$APP_NAME" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "Unknown")
    AVAILABLE=$(kubectl -n "$NAMESPACE" get deployment "$APP_NAME" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    echo "⚖️ 期望副本数: $DESIRED | 可用副本数: $AVAILABLE"
}

# 方法: check_rollout_status
# 目的: 确认滚动更新 / Rollout 策略是否正常
check_rollout_status() {
    echo "🔹 检查 Rollout 更新状态..."
    if command -v kubectl-argo-rollouts >/dev/null 2>&1; then
        kubectl argo rollouts get rollout "$APP_NAME" -n "$NAMESPACE"
    else
        echo "ℹ️ 未安装 argo-rollouts CLI，跳过详细 Rollout 状态检查"
    fi
}

# 方法: check_rollout_health
# 目的: 确认 Rollout 健康状态，无阻塞或异常
check_rollout_health() {
    echo "🔹 检查 Rollout 健康状态..."
    HEALTH=$(kubectl -n "$NAMESPACE" get deployment "$APP_NAME" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
    echo "❤️ 健康状态: $HEALTH"
}

# 方法: check_rollout_events
# 目的: 查看 Rollout / Deployment 事件，排查 Pod 未就绪或更新失败的原因
check_rollout_events() {
    echo "🔹 查看 Rollout / Deployment 事件..."
    kubectl -n "$NAMESPACE" describe deployment "$APP_NAME" | tail -n 20
}

# -----------------------------
# 主方法
# -----------------------------
run_rollout_diagnostics() {
    echo "================== 控制器层 Rollout 诊断 =================="
    check_rollout_exists
    check_replicas
    check_rollout_status
    check_rollout_health
    check_rollout_events
    echo "================== 诊断完成 ============================="
}

# 调用主方法
run_rollout_diagnostics
