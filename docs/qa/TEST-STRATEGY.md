# 上线前自动化测试策略

本文件是无人机智慧巡检平台测试策略的唯一真实来源。执行状态只记录在 [TEST-EXECUTION-TRACKING.csv](TEST-EXECUTION-TRACKING.csv)，缺陷只记录在 [BUG-TRACKING.md](BUG-TRACKING.md)，不要在追踪表里复制测试步骤。

## 分层目标

| 层级 | 目标 | 阻断时机 | 主命令 |
| --- | --- | --- | --- |
| PR 快速门禁 | 单仓单元测试、契约测试、生产构建 | 每个 PR | `scripts/quality-gate.ps1 pr` 或 `scripts/quality-gate.sh pr` |
| 跨仓集成门禁 | 前端、DISys、Detection Server、虚拟机场协议和核心链路预检 | 合并前、夜间 | `scripts/quality-gate.ps1 integration` |
| 发布候选门禁 | 全量门禁、E2E、发布报告、P0/P1 缺陷清零 | 生产发布前 | `scripts/quality-gate.ps1 release` |

## 仓库职责

- DISys：认证、租户隔离、航线任务、媒体报告、AI 检测配置、Flyway 迁移安全。
- DroneCloudSystem-web：API 封装、Pinia/composable 行为、检测链路契约、生产构建、Playwright 关键页面。
- DroneCloudSystem_detection-server：HTTP API、鉴权、文件推理状态、模型管理、检测录像清理、多租户隔离。
- DroneCloudSystem_virtual-dock-simulator：MQTT payload、设备拓扑、OSD 数据格式、设备状态机。

## 静态规则

- 前端 `src/views/` 不新增散落 `axios` 或 `fetch` 调用，接口协议必须进入 `src/api/` 或已有 service。
- 检测链路变更必须同步覆盖至少一个相关测试或说明，范围包括前端检测 API、DISys `media`/`wayline`、Detection Server router/client。
- API、部署、配置、回调、WebSocket 或模型契约变更必须更新指定权威文档，而不是只随意修改任一文档。

## 覆盖率推进

第一阶段只统计不阻断。第二阶段对核心模块新增代码设置 70% 变更覆盖率。第三阶段核心业务模块整体覆盖率目标为 80%。
