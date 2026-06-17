# 无人机智慧巡检平台

平台级文档仓库，用于统一维护三仓库联调场景下的业务文档、跨服务链路说明、联调版本记录和协作约定。

## 适用范围

本仓库不管理各子项目源码，仅管理跨仓库的共享文档与联调资产。

- `DISys/` 继续维护后端代码与后端技术文档
- `DroneCloudSystem-web/` 继续维护前端代码与前端技术文档
- `DroneCloudSystem_detection-server/` 继续维护检测服务代码与服务内部文档

## 文档分层

平台级文档放在根目录 `docs/` 下，解决跨仓库问题。

- `docs/business/`：业务总览、业务流程、业务词汇表、跨服务链路
- `docs/versions/`：联调版本清单、发布对应的三仓库 commit 记录

仓库级文档留在各自子仓库内，解决单仓库实现问题。

- `README.md`：启动、构建、部署
- `docs/openapi.yaml`：接口契约
- `docs/architecture*.md`：本仓库内部架构
- `CHANGELOG.md`：本仓库变更记录

## 当前目录建议

```text
docs/
  business/
    业务总览.md
    业务词汇表.md
    多租户系统业务文档.md
    实时直播与检测流程.md
    告警生成与处理流程.md
    跨服务链路.md
  versions/
    联调版本清单.md
CHANGELOG.md
ARCHITECTURE.md
README.md
```

## 维护规则

- 一个流程只要跨两个及以上仓库，就写入平台级文档。
- 一个变更只影响单个仓库内部实现，就只更新该仓库自己的文档。
- 改动检测、告警、报告、任务、航线、权限、接口路由时，优先检查是否需要同步更新 `docs/business/`。
- 每次形成稳定联调结果后，在 `docs/versions/联调版本清单.md` 记录三仓库对应 commit。

## 平台范围内的主要仓库

- `DISys`：Spring Boot 后端，负责业务主数据、权限、设备管理、媒体与告警持久化
- `DroneCloudSystem-web`：Vue 前端，负责任务编排、飞控展示、检测结果展示与用户交互
- `DroneCloudSystem_detection-server`：FastAPI 检测服务，负责实时检测、离线检测、截图、报告与告警触发
