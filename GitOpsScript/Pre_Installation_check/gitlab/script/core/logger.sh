#!/bin/bash                      # 使用 bash 解释器执行脚本

LOG_LEVEL="${LOG_LEVEL:-INFO}"   # 设置日志等级，默认 INFO，可通过环境变量覆盖

_timestamp() {                   # 定义私有函数：生成时间戳
    date +"%Y-%m-%d %H:%M:%S"    # 格式化当前时间
}

_log() {                         # 通用日志函数
    local level="$1"             # 第一个参数：日志级别
    local color="$2"             # 第二个参数：颜色代码
    shift 2                      # 移除前两个参数，剩余参数为日志内容
    echo -e "$( _timestamp ) ${color}[$level]\033[0m $*"  
                                   # 输出：时间 + 彩色等级 + 内容
}

log_info()  { _log "INFO"  "\033[36m" "$@"; }   # 青色 INFO
log_warn()  { _log "WARN"  "\033[33m" "$@"; }   # 黄色 WARN
log_error() { _log "ERROR" "\033[31m" "$@"; }   # 红色 ERROR

log_debug() {                                     # DEBUG 级别日志
    [[ "$LOG_LEVEL" == "DEBUG" ]] &&              # 如果日志等级是 DEBUG
    _log "DEBUG" "\033[90m" "$@";                 # 输出灰色 DEBUG
}
