# 成绩与复议模块 — IDEA 部署启动指南

**开发者：** 王浩哲  
**项目路径：** `桌面/smart-admin-master/smart-admin-api-java17-springboot3`  
**日期：** 2026-07-30

---

## 一、项目当前状态

```
smart-admin-api-java17-springboot3/
├── pom.xml                              ← 父 pom
├── sa-base/                             ← 基础模块（工具类、缓存、文件等）
│   └── src/main/resources/dev/
│       └── sa-base.yaml                 ← 数据库、Redis、端口等配置 ✅ 已配好
└── sa-admin/                            ← 管理模块
    └── src/main/java/net/lab1024/sa/admin/module/
        ├── business/
        │   ├── category/                ← 框架自带示例
        │   ├── goods/                   ← 框架自带示例
        │   ├── oa/                      ← 框架自带示例
        │   ├── score/                   ← ✅ 自定义：成绩管理
        │   └── appeal/                  ← ✅ 自定义：复议管理
        └── system/                      ← RBAC（登录、用户、角色、菜单）
```

### 配置确认（sa-base.yaml）

| 配置项 | 值 | 状态 |
|---|---|---|
| 数据库 | `smart_admin_v3` | ✅ |
| 用户名 | `root` | ✅ |
| 密码 | `123456` | ✅ |
| Redis | `127.0.0.1:6379` / 密码 `pass4Redis` / database 1 | ✅ |
| 端口 | `1024` | ✅ |
| Swagger | `http://localhost:1024/doc.html` | ✅ |

---

## 二、IDEA 启动步骤

### 第 1 步：环境要求

| 工具 | 版本 |
|---|---|
| JDK | **JDK 21**（D:\Program Files\Java），JDK 25 会导致 Lombok 失效 |
| Maven | 仓库路径 `D:\maven-repo`，settings.xml 在 `C:\Users\wwkkqwq\.m2\settings.xml` |

### 第 2 步：用 IDEA 打开项目

1. 打开 IDEA
2. `File → Open`
3. 选择：`C:\Users\wwkkqwq\Desktop\smart-admin-master\smart-admin-api-java17-springboot3`
4. 右侧 Maven 面板点刷新，等待依赖加载完毕

### 第 3 步：设置 JDK

`File → Project Structure → Project`
- SDK：选 **JDK 21**（`D:\Program Files\Java`）
- Language level：17

> 不要用 JDK 25！Lombok 1.18.38 不支持 JDK 25，会导致所有 `@Data` 注解失效，编译报"找不到符号"。

### 第 4 步：确认数据库和 Redis 已启动

```bash
# MySQL
sc query MySQL

# Redis（用禅道自带或其他方式启动）
```

如果 MySQL 没启动：
```bash
net start MySQL
```

### 第 5 步：启动项目

1. 找到 `sa-admin → src/main/java → net.lab1024.sa.admin → AdminApplication.java`
2. 右键 → `Run 'AdminApplication'`
3. 等待控制台出现：

```
Started AdminApplication in X.XXX seconds
```

### 第 6 步：验证启动

浏览器打开：**`http://localhost:1024/doc.html`**

页面**左上角下拉选「业务接口」**，左侧列表往下翻能看到：

| 分组 | 接口 |
|---|---|
| **成绩管理** | `POST /score/score/detail` |
| **复议管理** | `POST /appeal/appeal/submit` |
| **复议管理** | `POST /appeal/appeal/query` |
| **复议管理** | `GET /appeal/appeal/checkSubmitted` |
| **复议管理** | `GET /appeal/appeal/{appealId}` |

---

## 三、可能遇到的问题

### Q1：启动报错 `Profile '@profiles.active@' must start and end with a letter or digit`

**原因：** IntelliJ 不做 Maven 资源过滤，`application.yaml` 里的 `@profiles.active@` 没被替换成 `dev`。

**解决：** 已修复。源文件 `sa-admin/src/main/resources/dev/application.yaml` 和 `target/classes/application.yaml` 中 `spring.profiles.active` 已改为 `dev`。如果重新 Maven build 后被覆盖，手动改回 `dev`。

### Q2：启动报错 `Public Key Retrieval is not allowed`

**原因：** MySQL 8+ 使用 `caching_sha2_password` 认证，JDBC URL 缺 `allowPublicKeyRetrieval=true`。

**解决：** 已修复。`sa-base/src/main/resources/dev/sa-base.yaml` 的 JDBC URL 已加上此参数。

### Q3：端口 1024 被占用

**现象：** `Web server failed to start. Port 1024 was already in use.`

**解决：**
```bash
# 查看占用进程
netstat -ano | findstr 1024

# 杀掉进程（替换 PID）
taskkill /PID <PID> /F
```

或者改端口：编辑 `sa-admin/src/main/resources/dev/application.yaml`，把 `port: 1024` 改成 `1025`。

### Q4：编译报错 "找不到符号"（Lombok 相关）

**原因：** 用了 JDK 25。

**解决：** 切换到 JDK 21（`D:\Program Files\Java`）。JDK 25 与 Lombok 1.18.38 不兼容。

### Q5：Swagger 接口调不通，提示 401 无权限

**原因：** 接口有 `@SaCheckPermission` 注解，需要登录且有对应权限。

**临时测试方案：** 去掉 Controller 方法上的 `@SaCheckPermission` 注解，先调通再加权限。

**正式方案：** 
1. 先调登录接口获取 token
2. Swagger 右上角「Authorize」填入 `Bearer {token}`
3. 在后台管理 → 菜单管理中配置权限点，角色管理中授权

### Q6：Knife4j 页面选错分组看不到接口

切换到页面左上角下拉 **「业务接口」**，不要选「支撑接口(Support)」。

---

## 四、接口测试

### 测试 1：查看成绩详情

```
POST /score/score/detail
{
  "examId": 1
}
```

### 测试 2：提交复议

```
POST /appeal/appeal/submit
{
  "answerDetailId": 1,
  "examId": 1,
  "appealReason": "我对该题评分有异议，理由是..."
}
```

### 测试 3：检查是否已申请

```
GET /appeal/appeal/checkSubmitted?answerDetailId=1
```

### 测试 4：复议记录列表

```
POST /appeal/appeal/query
{
  "pageNum": 1,
  "pageSize": 10
}
```

### 测试 5：复议详情

```
GET /appeal/appeal/{appealId}
```

---

## 五、快速启动检查清单

- [ ] MySQL 运行中
- [ ] Redis 运行中
- [ ] 数据库 `smart_admin_v3` 有表
- [ ] IDEA JDK 选的是 JDK 21（不是 JDK 25）
- [ ] Maven 依赖加载完毕
- [ ] 运行 AdminApplication
- [ ] 控制台输出 `Started AdminApplication in X seconds`
- [ ] 浏览器打开 `http://localhost:1024/doc.html`
- [ ] 左上角选「业务接口」
- [ ] 能看到「成绩管理」和「复议管理」

---

## 六、本次环境调试记录（2026-07-30）

| 问题 | 根因 | 修复 |
|---|---|---|
| 所有 import 红标 | Maven 仓库在 `D:\maven-repo`，IDEA 未识别 | Maven 面板刷新 |
| 编译报找不到 getter/setter | JDK 25 与 Lombok 1.18.38 不兼容 | 切到 JDK 21 |
| AppealService/ScoreService 编译报错 | `SmartRequestUtil.getRequestUser()` 返回 `RequestUser` 接口，代码直接当 `RequestEmployee` 用 | 改用 `AdminRequestUtil.getRequestUser()` |
| 启动报 `@profiles.active@` 非法字符 | IntelliJ 不做 Maven 资源过滤 | 硬编码 `active: dev` |
| 数据库连接报 `Public Key Retrieval` | MySQL 8+ 认证要求 | JDBC URL 加 `allowPublicKeyRetrieval=true` |
| 端口 1024 被占用 | 上次进程未杀干净 | `taskkill` 杀进程后重启 |