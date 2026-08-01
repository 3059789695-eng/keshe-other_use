# user-role-assignment

用户角色分配模块，采用 Spring Boot 2 + MyBatis-Plus + MySQL，标准三层架构，统一返回 `Result`，全局异常处理，分配角色使用事务保证先删后插原子性。

## 技术栈

- JDK 8+
- Spring Boot 2.7.18
- MyBatis-Plus 3.5.5
- MySQL
- Maven

## 目录结构

```text
user-role-assignment/
├─ pom.xml
├─ sql/init.sql
├─ docs/接口测试文档.md
└─ src/main/
   ├─ java/com/course/userrole/
   │  ├─ UserRoleApplication.java
   │  ├─ common/          Result、PageResult、BusinessException、全局异常处理
   │  ├─ config/          MyBatis-Plus 分页配置
   │  ├─ controller/      UserRoleController
   │  ├─ dto/             分配角色请求参数
   │  ├─ entity/          User、Role、UserRole
   │  ├─ mapper/          UserMapper、RoleMapper、UserRoleMapper
   │  ├─ service/         接口与实现
   │  └─ vo/              角色、用户分页返回对象
   └─ resources/
      ├─ application.yml
      └─ mapper/          自定义 XML 联表查询
```

## 配置说明

默认数据库为 `cas`，连接地址在 `src/main/resources/application.yml` 中配置：

```yaml
url: jdbc:mysql://localhost:3306/cas?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true
```

按本机 MySQL 账号修改 `username` 和 `password`，然后执行 `sql/init.sql` 初始化表结构。

## 启动

```bash
mvn spring-boot:run
```

启动后接口统一前缀为：

```text
http://localhost:8080/api/user-role
```

## 接口一览

| 方法 | URL | 说明 |
| --- | --- | --- |
| GET | `/api/user-role/roles` | 查询所有角色 |
| GET | `/api/user-role/user/{userId}/roles` | 查询用户已拥有的角色 ID |
| POST | `/api/user-role/user/{userId}/roles` | 为用户分配角色 |
| GET | `/api/user-role/users` | 分页查询用户及角色信息 |

详细参数和 Postman 示例见 [接口测试文档](docs/接口测试文档.md)。

## 说明

当前 `roles` 表没有 `role_code` 字段，因此角色列表接口中的 `roleCode` 暂以 `roleName` 返回；如果后续新增 `role_code` 字段，只需修改 `RoleMapper.xml` 的查询字段即可。
