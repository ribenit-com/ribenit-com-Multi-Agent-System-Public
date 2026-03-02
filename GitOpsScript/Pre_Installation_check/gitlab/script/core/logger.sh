#!/bin/bash
# ==========================================
# logger.sh - 彩色日志工具
# 支持 INFO/WARN/ERROR/DEBUG
# ==========================================

# ====== 日志等级 ======
# 默认 INFO，可通过环境变量覆盖
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# ====== 生成时间戳 ======
_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"  # 返回当前时间
}

# ====== 通用日志函数 ======
_log() {
    local level="$1"   # 日志级别
    local color="$2"   # 颜色代码
    shift 2            # 剩余参数为日志内容
    echo -e "$(_timestamp) ${color}[$level]\033[0m $*"  # 输出：时间 + 彩色等级 + 内容
}

# ====== 日志函数封装 ======
log_info()  { _log "INFO"  "\033[36m" "$@"; }   # 青色 INFO
log_warn()  { _log "WARN"  "\033[33m" "$@"; }   # 黄色 WARN
log_error() { _log "ERROR" "\033[31m" "$@"; }   # 红色 ERROR
log_debug() {                                  
    [[ "$LOG_LEVEL" == "DEBUG" ]] && _log "DEBUG" "\033[90m" "$@";  # 灰色 DEBUG
}
