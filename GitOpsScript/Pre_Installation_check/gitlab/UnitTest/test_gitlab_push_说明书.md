<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Git 脚本流程图</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Noto+Sans+SC:wght@400;500;700&display=swap');

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    background: #0d1117;
    font-family: 'Noto Sans SC', sans-serif;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 40px 20px;
  }

  .page {
    width: 100%;
    max-width: 680px;
  }

  h1 {
    font-family: 'JetBrains Mono', monospace;
    color: #58a6ff;
    font-size: 13px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    margin-bottom: 32px;
    display: flex;
    align-items: center;
    gap: 10px;
  }

  h1::before {
    content: '';
    display: block;
    width: 8px;
    height: 8px;
    background: #58a6ff;
    border-radius: 50%;
    box-shadow: 0 0 8px #58a6ff;
  }

  h1::after {
    content: '';
    flex: 1;
    height: 1px;
    background: linear-gradient(to right, #30363d, transparent);
  }

  .flow {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0;
  }

  /* 节点通用 */
  .node {
    width: 100%;
    display: flex;
    justify-content: center;
    position: relative;
  }

  .box {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 14px 28px;
    font-size: 15px;
    color: #e6edf3;
    font-weight: 500;
    text-align: center;
    position: relative;
    transition: border-color 0.2s;
    min-width: 220px;
  }

  .box:hover { border-color: #58a6ff; }

  /* 启动节点 */
  .box.start {
    background: #1f2d3d;
    border-color: #58a6ff;
    color: #58a6ff;
    font-family: 'JetBrains Mono', monospace;
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 0.05em;
    box-shadow: 0 0 20px rgba(88,166,255,0.15);
  }

  /* 普通步骤 */
  .box.step {
    background: #161b22;
    border-color: #30363d;
  }

  /* 条件节点 */
  .diamond-wrap {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
  }

  .diamond {
    background: #1e2a1e;
    border: 1px solid #3fb950;
    border-radius: 8px;
    padding: 14px 28px;
    font-size: 15px;
    color: #3fb950;
    font-weight: 600;
    text-align: center;
    min-width: 220px;
    position: relative;
    box-shadow: 0 0 16px rgba(63,185,80,0.1);
  }

  .branches {
    display: flex;
    justify-content: center;
    gap: 48px;
    width: 100%;
    margin-top: 0;
    position: relative;
  }

  /* 连接线 */
  .arrow {
    display: flex;
    flex-direction: column;
    align-items: center;
    height: 28px;
    justify-content: center;
    position: relative;
  }

  .arrow-line {
    width: 1px;
    flex: 1;
    background: #30363d;
  }

  .arrow-head {
    width: 0;
    height: 0;
    border-left: 5px solid transparent;
    border-right: 5px solid transparent;
    border-top: 7px solid #30363d;
  }

  .arrow-label {
    position: absolute;
    left: 10px;
    top: 50%;
    transform: translateY(-50%);
    font-size: 11px;
    color: #8b949e;
    font-family: 'JetBrains Mono', monospace;
    white-space: nowrap;
  }

  /* 分支区域 */
  .branch {
    display: flex;
    flex-direction: column;
    align-items: center;
    flex: 1;
    max-width: 260px;
    position: relative;
  }

  .branch-line-top {
    width: 1px;
    height: 24px;
    background: #30363d;
  }

  .branch-label {
    font-size: 11px;
    color: #8b949e;
    font-family: 'JetBrains Mono', monospace;
    margin-bottom: 6px;
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .branch-label.yes { color: #3fb950; }
  .branch-label.no  { color: #f85149; }

  .branch-box {
    background: #1a1a2e;
    border: 1px solid #21262d;
    border-radius: 8px;
    padding: 12px 20px;
    font-size: 14px;
    color: #cdd9e5;
    text-align: center;
    width: 100%;
  }

  /* 连接两分支回主线的容器 */
  .merge-arrow {
    display: flex;
    flex-direction: column;
    align-items: center;
    height: 28px;
  }

  /* 可选步骤 */
  .box.optional {
    border-style: dashed;
    border-color: #388bfd55;
    color: #8b949e;
    font-size: 14px;
  }

  .box.optional .opt-tag {
    font-size: 10px;
    font-family: 'JetBrains Mono', monospace;
    background: #1f2d3d;
    color: #388bfd;
    border-radius: 4px;
    padding: 1px 6px;
    margin-left: 8px;
    vertical-align: middle;
  }

  /* 结束节点 */
  .box.end {
    background: #1e1e2e;
    border-color: #a371f7;
    color: #a371f7;
    font-family: 'JetBrains Mono', monospace;
    font-weight: 700;
    box-shadow: 0 0 20px rgba(163,113,247,0.15);
  }

  /* 横向分支连接线 */
  .branch-connector {
    display: flex;
    width: 100%;
    max-width: 560px;
    position: relative;
    height: 0;
  }

  .h-line {
    position: absolute;
    top: 0;
    height: 1px;
    background: #30363d;
  }

  /* 决策块的水平线容器 */
  .split-row {
    display: flex;
    width: 100%;
    max-width: 560px;
    position: relative;
  }

  .split-v {
    width: 1px;
    background: #30363d;
    position: absolute;
    left: 50%;
  }

  /* 大分支容器 */
  .decision-section {
    width: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  /* SVG 连接线 */
  .connector-svg {
    width: 100%;
    max-width: 560px;
    overflow: visible;
  }
</style>
</head>
<body>
<div class="page">
  <h1>Git 脚本流程</h1>

  <div class="flow">

    <!-- 启动 -->
    <div class="node"><div class="box start">▶ 启动脚本</div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- 判断是否传参 -->
    <div class="node"><div class="diamond">判断是否传入参数？</div></div>

    <!-- 分支 SVG 连线 -->
    <svg class="connector-svg" height="60" viewBox="0 0 560 60" xmlns="http://www.w3.org/2000/svg">
      <!-- 中轴往下 -->
      <!-- 左分支线 -->
      <line x1="280" y1="0" x2="100" y2="0" stroke="#30363d" stroke-width="1"/>
      <line x1="100" y1="0" x2="100" y2="40" stroke="#30363d" stroke-width="1"/>
      <polygon points="95,34 105,34 100,42" fill="#30363d"/>
      <!-- 右分支线 -->
      <line x1="280" y1="0" x2="460" y2="0" stroke="#30363d" stroke-width="1"/>
      <line x1="460" y1="0" x2="460" y2="40" stroke="#30363d" stroke-width="1"/>
      <polygon points="455,34 465,34 460,42" fill="#30363d"/>
      <!-- 标签 -->
      <text x="160" y="16" fill="#3fb950" font-size="11" font-family="JetBrains Mono" text-anchor="middle">✓ 有参数</text>
      <text x="390" y="16" fill="#f85149" font-size="11" font-family="JetBrains Mono" text-anchor="middle">✗ 无参数</text>
    </svg>

    <!-- 两个分支盒子 -->
    <div style="display:flex;width:100%;max-width:560px;gap:0;justify-content:space-between;">
      <div style="flex:1;display:flex;flex-direction:column;align-items:center;padding:0 20px;">
        <div class="branch-box" style="border-color:#1a3a1a;background:#1a2a1a;color:#3fb950;font-weight:600;">🏭 生产模式</div>
      </div>
      <div style="flex:1;display:flex;flex-direction:column;align-items:center;padding:0 20px;">
        <div class="branch-box" style="border-color:#3a1a1a;background:#2a1a1a;color:#f85149;font-weight:600;">🧪 单元测试模式</div>
      </div>
    </div>

    <!-- 合并回主线 -->
    <svg class="connector-svg" height="48" viewBox="0 0 560 48" xmlns="http://www.w3.org/2000/svg">
      <line x1="100" y1="0" x2="100" y2="24" stroke="#30363d" stroke-width="1"/>
      <line x1="100" y1="24" x2="280" y2="24" stroke="#30363d" stroke-width="1"/>
      <line x1="460" y1="0" x2="460" y2="24" stroke="#30363d" stroke-width="1"/>
      <line x1="460" y1="24" x2="280" y2="24" stroke="#30363d" stroke-width="1"/>
      <line x1="280" y1="24" x2="280" y2="42" stroke="#30363d" stroke-width="1"/>
      <polygon points="275,36 285,36 280,44" fill="#30363d"/>
    </svg>

    <!-- 进入目录 -->
    <div class="node"><div class="box step">📁 进入目标目录</div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- 初始化仓库 -->
    <div class="node"><div class="box optional">🔧 初始化仓库 <span class="opt-tag">if needed</span></div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- 设置远程 -->
    <div class="node"><div class="box optional">🌐 设置远程 Remote <span class="opt-tag">if provided</span></div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- git add -->
    <div class="node"><div class="box step"><span style="font-family:'JetBrains Mono',monospace;color:#58a6ff;">git add .</span></div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- git commit -->
    <div class="node"><div class="box optional"><span style="font-family:'JetBrains Mono',monospace;color:#58a6ff;">git commit</span> <span class="opt-tag">if changes</span></div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- git push -->
    <div class="node"><div class="box optional"><span style="font-family:'JetBrains Mono',monospace;color:#58a6ff;">git push</span> <span class="opt-tag">if remote exists</span></div></div>

    <div class="arrow"><div class="arrow-line"></div><div class="arrow-head"></div></div>

    <!-- 结束 -->
    <div class="node"><div class="box end">■ 结束</div></div>

  </div>

  <!-- 图例 -->
  <div style="margin-top:40px;display:flex;gap:24px;justify-content:center;flex-wrap:wrap;">
    <div style="display:flex;align-items:center;gap:8px;font-size:12px;color:#8b949e;font-family:'JetBrains Mono',monospace;">
      <div style="width:14px;height:14px;border-radius:3px;background:#161b22;border:1px solid #30363d;"></div> 必须步骤
    </div>
    <div style="display:flex;align-items:center;gap:8px;font-size:12px;color:#8b949e;font-family:'JetBrains Mono',monospace;">
      <div style="width:14px;height:14px;border-radius:3px;background:#161b22;border:1px dashed #388bfd55;"></div> 条件步骤
    </div>
    <div style="display:flex;align-items:center;gap:8px;font-size:12px;color:#8b949e;font-family:'JetBrains Mono',monospace;">
      <div style="width:14px;height:14px;border-radius:3px;background:#1e2a1e;border:1px solid #3fb950;"></div> 判断/分支
    </div>
  </div>
</div>
</body>
</html>
