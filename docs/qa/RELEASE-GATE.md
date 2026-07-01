# 发布候选门禁

生产发布前必须满足本文件的全部阻断条件。任何例外都必须写入发布报告，并且只能豁免 P2 以下非核心缺陷。

## 必过命令

```bash
scripts/quality-gate.sh release
```

Windows:

```powershell
.\scripts\quality-gate.ps1 release
```

## P0 阻断场景

| 编号 | 场景 | 责任仓库 |
| --- | --- | --- |
| P0-AUTH-001 | 登录、Token、workspace 获取、普通用户越权访问 | DISys, Web |
| P0-TENANT-001 | 跨租户数据读取被拒绝 | DISys, Detection |
| P0-DEVICE-001 | 设备上线/离线、OSD WebSocket/MQTT 状态刷新 | DISys, Web, Simulator |
| P0-WAYLINE-001 | 航线创建、航点保存、任务下发、任务状态流转 | DISys, Web |
| P0-DETECTION-001 | AI 检测配置保存读取、航点触发检测启动/停止 | DISys, Web, Detection |
| P0-MEDIA-001 | 截图、录像、报告上传 MinIO 并回调 DISys | DISys, Detection |
| P0-ALARM-001 | 告警规则触发、告警记录、前端展示、通知降级 | DISys, Web, Detection |
| P0-BUILD-001 | 生产构建产物可启动，前端代理和 nginx 路由正确 | Web, DISys |

## 质量阈值

- 测试执行率：100%。
- 通过率：100%。
- 未关闭 P0/P1 缺陷：0。
- 同一发布候选 E2E 至少连续 2 次通过。
- 生产发布必须产出 `logs/quality-gate/release-test-report.md` 和 `logs/quality-gate/release-test-report.json`。

## 手动豁免

只允许 P2 以下非核心缺陷。豁免项必须记录影响范围、回滚方式、负责人和补测日期。P0/P1 不允许豁免。
