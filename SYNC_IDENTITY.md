# 客户端身份与操作员设计

## 当前已有

### 员工体系 ✅
- **Users 表**: `id, username, displayName, passwordHash, role`
- **当前操作员**: `WorkerNotifier` → `WorkerInfo(userId, displayName)` 
- **存储位置**: SharedPreferences (`worker_id` + `worker_name`)
- **称重记录**: `recordedBy` 字段指向 Users.id
- **房间分配**: Rooms 表有 `assignedUserId`

用户每次打开 App 需要选择一个员工身份，之后所有操作都带上这个 userId。

## 需要新增

### 1. Device ID

```
首次启动 → 生成 UUID → 存 SharedPreferences → 永久不变
```

```dart
// lib/utils/device_id.dart
class DeviceId {
  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();          // 如: d4f3a2b1-9c8e-4f5a-a7d2-3e1b8c9f6a2d
      await prefs.setString('device_id', id);
    }
    return id;
  }
}
```

- 卸载 App 后重装会变（正常的）
- 格式: UUID v4
- 用途: 区分同一个人在多台设备上的操作

### 2. 操作日志完整字段

```sql
CREATE TABLE sync_queue (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  op_id        TEXT UNIQUE NOT NULL,    -- UUID，全局唯一，幂等去重用
  device_id    TEXT NOT NULL,           -- 哪台设备
  user_id      INTEGER NOT NULL,        -- 哪个员工（FK → Users.id）
  action       TEXT NOT NULL,           -- add_weight / update_bird / ...
  entity_type  TEXT NOT NULL,           -- weight / bird / room / species / medical
  entity_id    TEXT NOT NULL,           -- 被操作记录的 UUID
  payload      TEXT NOT NULL,           -- JSON: 操作内容
  created_at   INTEGER NOT NULL,        -- 操作时间戳
  synced       INTEGER DEFAULT 0,       -- 0=未同步 1=已同步
  retry_count  INTEGER DEFAULT 0
);
```

### 3. 操作日志示例

```
用户 "张三" 在手机A上称重 小蓝 52.3g
```

```json
{
  "opId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "deviceId": "d4f3a2b1-9c8e-4f5a-a7d2-3e1b8c9f6a2d",
  "userId": 3,
  "action": "add_weight",
  "entityType": "weight",
  "entityId": "w-5e6f7a8b-9c0d-1234-5678-90abcdef1234",
  "payload": {
    "birdId": "bird-uuid-xxx",
    "birdName": "小蓝",
    "weightG": 52.3,
    "isFasting": true,
    "recordedAt": 1711111111
  },
  "createdAt": 1711111111
}
```

## 服务器端怎么用

```
收到 POST /sync → 按 op_id 去重写 PostgreSQL
  ↓
服务端表也记录 device_id + user_id
  ↓
以后可以查：
- 这周谁称的最多？
- 这条记录是谁从哪个手机录的？
- 这台设备最近一次同步是什么时候？
```

## 三层身份总结

| 层级 | 标识 | 存哪里 | 变不变 |
|------|------|--------|--------|
| 设备 | device_id (UUID) | SharedPreferences | 永久 |
| 员工 | user_id (FK→Users) | SharedPreferences + WorkerNotifier | 用户切换时变 |
| 操作 | op_id (UUID) | sync_queue 每行一个 | 一次性的 |
