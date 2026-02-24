#!/bin/bash
# ===================================================
# GitOps 层诊断脚本 — ArgoCD 同步 + Pod 状态
# 版本: v1.2.0
# 功能:
#   - 检查 ArgoCD Namespace 是否存在
#   - 检查部署 Namespace 是否存在
#   - 检查 ArgoCD Application 是否存在
#   - 检查 Application 同步状态
#   - 检查 Application 健康状态
#   - 检查 Pod Ready 状态
# ===================================================
set -euo pipefail

ARGO_APP="${ARGO_APP:-gitlab}"
ARGO_NAMESPACE="${ARGO_NAMESPACE:-argocd}"
DEPLOY_NAMESPACE="${DEPLOY_NAMESPACE:-ns-gitlab-ha}"

# -----------------------------
# 方法定义
# -----------------------------

# 方法: check_argocd_namespace
# 目的: 确认 ArgoCD Namespace 存在，否则 ArgoCD 控制器无法运行，应用无法管理
check_argocd_namespace() {
    echo "🔹 检查 ArgoCD Namespace..."
    if kubectl get ns "$ARGO_NAMESPACE" >/dev/null 2>&1; then
        echo "✅ ArgoCD Namespace '$ARGO_NAMESPACE' 存在"
    else
        echo "❌ ArgoCD Namespace '$ARGO_NAMESPACE' 不存在"
    fi
}

# 方法: check_deploy_namespace
# 目的: 确认部署目标 Namespace 存在，否则 Pod 无法创建；不存在时自动创建
check_deploy_namespace() {
    echo "🔹 检查部署 Namespace..."
    if kubectl get ns "$DEPLOY_NAMESPACE" >/dev/null 2>&1; then
        echo "✅ 部署 Namespace '$DEPLOY_NAMESPACE' 存在"
    else
        echo "🔹 创建部署 Namespace '$DEPLOY_NAMESPACE'"
        kubectl create ns "$DEPLOY_NAMESPACE"
        echo "✅ 创建完成"
    fi
}

# 方法: check_application
# 目的: 确认 ArgoCD Application 存在，否则无法进行同步和健康检查
check_application() {
    echo "🔹 检查 ArgoCD Application..."
    if kubectl -n "$ARGO_NAMESPACE" get app "$ARGO_APP" >/dev/null 2>&1; then
        echo "✅ Application '$ARGO_APP' 存在"
    else
        echo "❌ Application '$ARGO_APP' 不存在"
    fi
}

# 方法: check_sync_status
# 目的: 确认应用资源已成功同步到集群，避免配置未下发导致 Pod 异常
check_sync_status() {
    echo "🔹 检查 Application 同步状态..."
    STATUS=$(kubectl -n "$ARGO_NAMESPACE" get app "$ARGO_APP" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    echo "⏱ 同步状态: $STATUS"
}

# 方法: check_health_status
# 目的: 确认同步的资源健康，否则同步成功也可能有异常资源
check_health_status() {
    echo "🔹 检查 Application 健康状态..."
    HEALTH=$(kubectl -n "$ARGO_NAMESPACE" get app "$ARGO_APP" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    echo "❤️ 健康状态: $HEALTH"
}

# 方法: check_pod_ready
# 目的: 确认所有 Pod 已就绪，否则应用可能无法对外提供服务
check_pod_ready() {
    echo "🔹 检查 Pod Ready 状态..."
    PODS=$(kubectl get pods -n "$DEPLOY_NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}={"status.containerStatuses[0].ready}{" "}{end}' 2>/dev/null || echo "")
    echo "📦 Pod Ready: $PODS"
}

# -----------------------------
# 主方法
# -----------------------------
# 方法: run_gitops_diagnostics
# 目的: 统一调用所有检查方法，一次性输出 GitOps 层诊断结果
run_gitops_diagnostics() {
    echo "================== GitOps 层诊断 =================="
    check_argocd_namespace
    check_deploy_namespace
    check_application
    check_sync_status
    check_health_status
    check_pod_ready
    echo "================== 诊断完成 ====================="
}

# 调用主方法
run_gitops_diagnostics
