# 教师信息维护模块接口测试文档

## 1. 基本信息

- 项目路径：`student-manager`
- 接口统一前缀：`/api/teacher`
- 基础地址：`http://localhost:8080`
- 技术栈：Spring Boot 2.7.18、MyBatis-Plus 3.5.5、MySQL、EasyExcel 3.3.4
- 统一返回结构：`{ "code": 200, "message": "success", "data": ... }`
- 服务启动：在 `student-manager` 目录执行 `mvn spring-boot:run`

测试前请确认：

1. `application.yml` 中的 MySQL 连接信息正确。
2. 数据库已存在 `teachers`、`users`、`organizations` 表。
3. 本模块严格适配 `teachers.major_id`，该字段关联 `organizations.id`。
4. `users` 表中有待关联教师账号，`organizations` 表中有学院/专业数据。
5. `teachers` 表中没有重复的 `teacher_no` 或重复的 `id`。

## 2. 分页查询教师列表

接口名称：分页查询教师列表  
请求方式：`GET`  
完整 URL：`http://localhost:8080/api/teacher/page`

请求参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| pageNum | Integer | 否 | 页码，默认 1，最小 1 |
| pageSize | Integer | 否 | 每页条数，默认 10，范围 1-100 |
| teacherNo | String | 否 | 教师编号模糊查询 |
| name | String | 否 | 姓名模糊查询 |

成功返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "records": [
      {
        "id": 1,
        "teacherNo": "T2024001",
        "name": "张三",
        "majorId": 1,
        "majorName": "计算机学院"
      }
    ],
    "total": 1,
    "size": 10,
    "current": 1,
    "pages": 1,
    "orders": [],
    "optimizeCountSql": true,
    "searchCount": true,
    "countId": null,
    "maxLimit": null,
    "hitCount": false
  }
}
```

失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "pageSize 不能大于 100",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `GET`。
2. URL 填写 `http://localhost:8080/api/teacher/page`。
3. 在 `Params` 页签添加 `pageNum=1`、`pageSize=10`，可按需添加 `teacherNo`、`name`。
4. 点击 `Send` 查看分页 JSON。

## 3. 新增教师信息

接口名称：新增教师信息  
请求方式：`POST`  
完整 URL：`http://localhost:8080/api/teacher/add`

请求参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | Integer | 是 | 教师 id，必须对应 `users.id` |
| teacherNo | String | 是 | 教师编号，全局唯一 |
| majorId | Integer | 是 | 专业/学院 id，对应数据库列 `major_id`，必须对应 `organizations.id` |

请求 JSON 示例：

```json
{
  "id": 1001,
  "teacherNo": "T2024001",
  "majorId": 1
}
```

成功返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "教师编号 [T2024001] 已存在",
  "data": null
}
```

参数校验失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "教师 id 不能为空; 学院 id 不能为空",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `POST`。
2. URL 填写 `http://localhost:8080/api/teacher/add`。
3. `Body` 选择 `raw`，右侧格式选择 `JSON`。
4. 粘贴请求 JSON，点击 `Send`。

## 4. 根据 id 查询教师详情

接口名称：根据 id 查询教师详情  
请求方式：`GET`  
完整 URL：`http://localhost:8080/api/teacher/{id}`

请求参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | Integer | 是 | URL 路径中的教师 id |

成功返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1001,
    "teacherNo": "T2024001",
    "majorId": 1
  }
}
```

失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "教师不存在，id=999",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `GET`。
2. URL 填写 `http://localhost:8080/api/teacher/1001`。
3. 点击 `Send`，将 `1001` 替换为实际教师 id 即可测试。

## 5. 编辑教师信息

接口名称：编辑教师信息  
请求方式：`PUT`  
完整 URL：`http://localhost:8080/api/teacher/update`

请求参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | Integer | 是 | 要修改的教师 id |
| teacherNo | String | 是 | 新教师编号，唯一性校验排除当前教师自身 |
| majorId | Integer | 是 | 新专业/学院 id，对应数据库列 `major_id` |

请求 JSON 示例：

```json
{
  "id": 1001,
  "teacherNo": "T2024001-NEW",
  "majorId": 2
}
```

成功返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "教师编号 [T2024001] 已被其他教师使用",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `PUT`。
2. URL 填写 `http://localhost:8080/api/teacher/update`。
3. `Body` 选择 `raw`，右侧格式选择 `JSON`。
4. 粘贴请求 JSON，点击 `Send`。

## 6. 删除教师信息

接口名称：删除教师信息  
请求方式：`DELETE`  
完整 URL：`http://localhost:8080/api/teacher/{id}`

请求参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | Integer | 是 | URL 路径中的教师 id |

成功返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "教师不存在，id=999",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `DELETE`。
2. URL 填写 `http://localhost:8080/api/teacher/1001`。
3. 点击 `Send`。该接口只删除 `teachers` 记录，不会删除 `users` 账号。

## 7. 下载 Excel 导入模板

接口名称：下载 Excel 导入模板  
请求方式：`GET`  
完整 URL：`http://localhost:8080/api/teacher/template`

请求参数说明：无

模板内容说明：

| 教师编号 | 姓名 | 学院名称 |
| --- | --- | --- |
| T2024001 | 张三 | 计算机学院 |

成功返回说明：

- 响应类型：`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- 响应头包含 `Content-Disposition: attachment;filename*=utf-8''...`
- 浏览器或 Postman 可直接下载 `.xlsx` 文件

失败返回 JSON 示例：

```json
{
  "code": 500,
  "message": "Internal error: ...",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `GET`。
2. URL 填写 `http://localhost:8080/api/teacher/template`。
3. 点击 `Send`，再点击响应区域右上角的 `Save Response` 或 `Send and Download` 保存 Excel。

## 8. Excel 批量导入教师

接口名称：Excel 批量导入教师  
请求方式：`POST`  
完整 URL：`http://localhost:8080/api/teacher/import`

请求参数说明：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| file | File | 是 | `form-data` 文件字段，仅支持 `.xlsx` |

Excel 表头必须为：

```text
教师编号  姓名  学院名称
```

示例数据：

```text
教师编号  姓名      学院名称
T2024101  李四      计算机学院
T2024102  王五      软件学院
```

成功返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "successCount": 2,
    "failCount": 0,
    "errors": []
  }
}
```

部分失败返回 JSON 示例：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "successCount": 1,
    "failCount": 2,
    "errors": [
      {
        "rowNum": 3,
        "reason": "教师编号 [T2024001] 已存在"
      },
      {
        "rowNum": 4,
        "reason": "姓名 [未知用户] 在 users 表中不存在；学院名称 [未知学院] 在 organizations 表中不存在"
      }
    ]
  }
}
```

文件错误失败返回 JSON 示例：

```json
{
  "code": 400,
  "message": "Excel 文件为空或无有效数据行",
  "data": null
}
```

Postman 调用说明：

1. 新建 Request，方法选择 `POST`。
2. URL 填写 `http://localhost:8080/api/teacher/import`。
3. `Body` 选择 `form-data`。
4. 添加字段，`Key` 填 `file`，右侧类型切换为 `File`，然后选择本地 `.xlsx` 文件。
5. 点击 `Send`，响应中查看 `successCount`、`failCount` 和 `errors`。

导入校验规则：

- 教师编号不能为空，且不能与库中已有教师编号重复。
- 同一 Excel 内教师编号也不能重复。
- 姓名不能为空，且必须在 `users` 表中唯一匹配；重名会报错。
- 姓名对应的用户不能已经关联其他教师。
- 学院名称不能为空，且必须在 `organizations` 表中存在；重名会报错。
- 只插入校验通过的数据，错误明细按 Excel 数据行号返回，表头不计入行号。
- 完全空行会被忽略，不会计入失败条数。

## 9. pom.xml 核心依赖清单

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.7.18</version>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-boot-starter</artifactId>
        <version>3.5.5</version>
    </dependency>
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>easyexcel</artifactId>
        <version>3.3.4</version>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```
