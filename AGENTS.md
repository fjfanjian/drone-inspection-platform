# 无人机智慧巡检平台 — AGENTS.md

三仓库工作区。每个子项目有独立 Git 仓库和详细 `CLAUDE.md`，**先读对应 CLAUDE.md 再动手改代码**。

完整架构文档:`ARCHITECTURE.md`

完成工作后**必须**进行回归测试，确保更改没有影响原业务功能。

### 前端设计原型约束

- 进行任何前端页面、组件、交互或样式更改前，必须先查看并遵循已有设计原型、截图、设计稿或 `DroneCloudSystem-web/DESIGN.md` 中的设计系统规范。
- 若用户提供了截图或原型，最终实现必须以该原型为准，保持布局层级、视觉密度、色彩、间距、圆角、字号、状态样式与交互反馈一致；不得仅实现功能而忽略视觉还原。
- 新增或调整 UI 时优先使用项目已有设计 token、Ant Design Vue 组件和既有业务组件样式，避免硬编码颜色、间距、阴影和临时视觉风格。
- 前端修改完成后，除单元/构建回归外，还必须通过浏览器或 webapp-testing 对目标页面进行可视化检查，确认与设计原型一致且无文字溢出、重叠、错位或响应式破版。

- 生产服务器调试ssh地址：gty@100.102.63.71.各个服务端口与本地一致
- 生产服务器公网ip地址：120.238.190.91
- 除非用户同意，否则 **禁止**在生产服务器上直接修改代码。仓库代码更改需要通过在本地修改并测试完成后，通过github同步

## 仓库拓扑

```
DISys/                        # 后端 — Spring Boot 2.7 / Java 11 / MyBatis-Plus
DroneCloudSystem-web/         # 前端 — Vue 3 / Vite 5 / Pinia / Ant Design Vue 4
DroneCloudSystem_detection-server/  # AI 检测 — Python FastAPI / YOLOv11 / OpenCV
DroneCloudSystem_virtual-dock-simulator/ # 虚拟无人机设备模拟器
```

### 端口矩阵（必须熟记）

| 服务             | 端口                | 协议                  | 启动方式                                       |
| ---------------- | ------------------- | --------------------- | ---------------------------------------------- |
| DISys (后端)     | 6789                | HTTP                  | Docker Compose / Maven                         |
| Detection Server | 8000                | HTTP                  | `python main.py` (conda env: detection-server) |
| Detection Server | 8001                | WebSocket             | 同上，双端口统一启动                           |
| SRS (流媒体)     | 1935 / 8081 / 1985  | RTMP / HTTP-FLV / API | Docker Compose                                 |
| MySQL            | 3306                | TCP                   | Docker Compose (root/root)                     |
| Redis            | 6379                | TCP                   | Docker Compose                                 |
| MinIO            | 9000 / 9001         | HTTP (API / Console)  | Docker Compose                                 |
| EMQX (MQTT)      | 1883 / 8083 / 18083 | MQTT / WS / Dashboard | **宿主机安装**，非 Docker                      |
| 前端 dev         | 3000                | HTTP                  | `npm run dev`                                  |

### 跨服务数据流方向（单向依赖，无循环）

```
前端 ─HTTP──▶ DISys ◀──HTTP回调── Detection Server
前端 ─HTTP──▶ Detection Server
前端 ─WebSocket──▶ Detection Server (:8001)
前端 ─STOMP WS──▶ DISys (:6789)
前端 ─MQTT──▶ EMQX ◀──MQTT── DJI 设备
Detection Server ─HTTP──▶ SRS (拉流/推流)
Detection Server ─HTTP──▶ DISys (会话/告警/媒体注册)
Detection Server ─S3──▶ MinIO (截图/视频/报告)
```

## 跨仓库联调关键点

### 1. 检测链路改任何一环，三个仓库都要核对

改检测会话/报告/告警链路时，必须同步检查：

- `DroneCloudSystem_detection-server/backend_api_client.py` — HTTP 回调 DISys 的接口
- `DISys/.../media/controller/` — 会话注册、报告、媒体回调
- `DroneCloudSystem-web/src/views/DetectionDisplay.vue` — 前端检测面板
- `DroneCloudSystem-web/src/api/detection.js` — 前端检测 API

### 2. 认证 Token 约定

- DISys 和前端之间：Header `x-auth-token`（不是 Bearer）
- Detection Server → DISys：JWT Token，`backend_api_client.py` 的 `AuthTokenManager` 自动刷新（20h 间隔，24h 有效期）
- 前端 Token 存储：`localStorage` 或 `sessionStorage`，前缀 `drone_cloud_`
- 前端 API 调用必须先获取 `workspaceId`：`djiCloudAPI.getCurrentWorkspace()`

### 3. API 路由前缀映射

前端通过 Vite 代理（开发）或 nginx 反代（生产）访问后端：

| 前端代理路径       | 目标            | 前缀               |
| ------------------ | --------------- | ------------------ |
| `/manage/*`        | DISys :6789     | `/manage/api/v1/`  |
| `/wayline/*`       | DISys :6789     | `/wayline/api/v1/` |
| `/media/*`         | DISys :6789     | `/media/api/v1/`   |
| `/map/*`           | DISys :6789     | `/map/api/v1/`     |
| `/control/*`       | DISys :6789     | `/control/api/v1/` |
| `/detection-api/*` | Detection :8000 | `/api/v1/`         |
| `/detection-ws/*`  | Detection :8001 | `/ws`              |

### 4. 响应格式统一

DISys 后端返回：`{ code, message, data }` — 新增接口必须保持同一结构。

## 快速启动命令

```bash
# 后端 (DISys) — 推荐 Docker 一键
cd DISys
docker compose up -d          # 启动全部基础设施
sh scripts/rebuild_and_restart_backend.sh  # 构建并重启后端

# 前端
cd DroneCloudSystem-web
npm run dev                    # 开发 :3000

# AI 检测服务 — 需要 conda 环境
cd DroneCloudSystem_detection-server
conda activate detection-server
python main.py                 # HTTP :8000 + WS :8001
```

## 基础设施注意事项

- **EMQX 在宿主机上运行**（不在 Docker 里），通过 `docker-compose.yml` 的 `extra_hosts: host-gateway` 桥接
- Docker 自定义桥接网络 `192.168.6.0/24`（在 DISys/docker-compose.yml 定义）
- 数据库迁移用 Flyway，baseline-version=3，迁移脚本在 `DISys/source/backend_service/sample/src/main/resources/db/migration/`
- Detection Server 会话状态全内存，**重启即丢失**（已知技术债）

## 已知技术债 & 陷阱

| 问题                                                          | 影响                               | 位置                             |
| ------------------------------------------------------------- | ---------------------------------- | -------------------------------- |
| Detection Server `main.py` 1804行，God Module                 | 维护困难                           | detection-server/main.py         |
| 前端 `store/` 和 `stores/` 两目录并存                         | 迁移遗留，新增 store 应放 `store/` | web/src/store/ vs stores/        |
| 告警规则引擎前端 IndexedDB 实现                               | 无法跨设备同步，数据可能丢失       | web/src/services/alarmRuleEngine |
| Detection Server 无测试文件                                   | 回归风险高                         | detection-server/                |
| 前端 MissionPlanning.vue 6263行 / DetectionDisplay.vue 5278行 | 组件过大                           | web/src/views/                   |
| DISys manage 模块 9037行 / 162文件                            | 最大模块                           | DISys source                     |

## 文档门禁（Conventional Commits + 文档同步）

三个仓库均启用文档门禁。改动影响 API/部署/配置时，必须同步更新：

- `README.md`
- `docs/openapi.yaml`
- `docs/开发交接指南.md`（如有）
- `CHANGELOG.md`

DISys 的 CI (`.github/workflows/check-docs.yml`) + 本地 pre-commit hook 会检查。

## 详细文档索引

每个子项目的 `CLAUDE.md` 是最权威的开发指南，包含完整模块清单、API 路由表、代码约定和常见命令。

- `DISys/CLAUDE.md` — 后端模块架构、Maven 结构、Docker 部署、Flyway 迁移
- `DISys/docs/architecture.md` — 后端架构详细文档（P1/P2/P3）
- `DroneCloudSystem-web/CLAUDE.md` — 前端架构、路由、状态管理、实时通信
- `DroneCloudSystem-web/docs/architecture-analysis.md` — 前端架构详细文档
- `DroneCloudSystem_detection-server/CLAUDE.md` — 检测服务架构、API 端点、ML Pipeline
- `DroneCloudSystem_detection-server/docs/architecture.md` — 检测服务架构详细文档

<!-- headroom:rtk-instructions -->

# RTK (Rust Token Killer) - Token-Optimized Commands

When running shell commands, **always prefix with `rtk`**. This reduces context
usage by 60-90% with zero behavior change. If rtk has no filter for a command,
it passes through unchanged — so it is always safe to use.

## Key Commands

```bash
# Git (59-80% savings)
rtk git status          rtk git diff            rtk git log

# Files & Search (60-75% savings)
rtk ls <path>           rtk read <file>         rtk grep <pattern>
rtk find <pattern>      rtk diff <file>

# Test (90-99% savings) — shows failures only
rtk pytest tests/       rtk cargo test          rtk test <cmd>

# Build & Lint (80-90% savings) — shows errors only
rtk tsc                 rtk lint                rtk cargo build
rtk prettier --check    rtk mypy                rtk ruff check

# Analysis (70-90% savings)
rtk err <cmd>           rtk log <file>          rtk json <file>
rtk summary <cmd>       rtk deps                rtk env

# GitHub (26-87% savings)
rtk gh pr view <n>      rtk gh run list         rtk gh issue list

# Infrastructure (85% savings)
rtk docker ps           rtk kubectl get         rtk docker logs <c>

# Package managers (70-90% savings)
rtk pip list            rtk pnpm install        rtk npm run <script>
```

## Rules

- In command chains, prefix each segment: `rtk git add . && rtk git commit -m "msg"`
- For debugging, use raw command without rtk prefix
- `rtk proxy <cmd>` runs command without filtering but tracks usage
<!-- /headroom:rtk-instructions -->
- ### 代码拆分与可维护性约束
  - 禁止新增“全能型”巨型文件。新增或大改文件前，先判断职责边界：页面负责编排，组件负责展示与交互，composable 负责状态与副作用，service/api 负责业务调用与协议细节。
  - Vue 页面组件不得承载大量业务逻辑。若页面内出现复杂数据处理、WebSocket/MQTT、地图渲染、权限判断、表单流程、轮询、任务状态机等逻辑，应提取到 `composables/`、`services/`、`store/` 或领域组件中。
  - 不允许在 `src/views/` 中直接写散落的 axios/fetch 请求；接口调用必须进入 `src/api/` 或已有业务 API 封装层。
  - 不允许把 Pinia store 写成业务垃圾桶。store 只管理领域状态、派生状态和跨页面动作；UI 展示状态、弹窗状态、临时表单状态优先留在组件或 composable。
  - 单个函数应只做一件事。若函数同时包含数据获取、转换、权限判断、UI 通知、异常处理和状态写入，应拆分为命名清晰的小函数。
  - 出现第三处相似逻辑时必须抽取公共实现；地图渲染、设备状态映射、任务状态映射、时间/坐标/告警格式化等不得复制粘贴。
  - 新增组件时优先设计清晰 props/emits，不直接依赖全局 store 或路由，除非它本身就是页面级容器组件。
  - 文件明显变大时必须主动拆分。软阈值：Vue SFC 超过 400 行、普通 JS/TS 文件超过 300 行、函数超过 80 行、嵌套超过 3 层时，应优先拆分；确需保留必须在代码或回复中说明原因。
  - 不为“复用”过早抽象，但一旦抽象能消除真实重复、隔离副作用、降低页面复杂度，就必须抽取。
  - 每次修改后检查是否引入新的架构倒挂：`views` 不反向承担 service 职责，`components` 不直接拼接 API 协议，`utils` 不塞业务流程。
  - 修改已有臃肿文件时，不得继续往文件底部堆功能；应优先在当前改动范围内顺手拆出稳定边界。
  - 提交前自查：新增代码是否有明确所属层级、是否能被单独测试、是否减少而不是增加页面复杂度。
