# 课程管理系统 API 文档

## 一、项目概述

基于 **Spring Boot 2.7.18 + MyBatis-Plus + MySQL 5.7 + JDK 17** 开发的后端课程管理系统，包含两个核心业务模块：

- **教师端-课程章节管理**：支持无限层级树形章节结构、分页加载更多、递归删除
- **管理员端-学期与课程设置**：学期/课程 CRUD、全局生效配置、角色鉴权

## 二、项目结构

`
course-management/
├── pom.xml                                # Maven 依赖配置
├── init_database.sql                      # 数据库建表脚本
├── .gitignore                             # Git 忽略文件
├── src/main/
│   ├── java/net/lab1024/course/
│   │   ├── CourseApplication.java         # 启动类
│   │   ├── common/
│   │   │   ├── result/Result.java         # 统一返回结果
│   │   │   ├── handler/GlobalExceptionHandler.java  # 全局异常处理
│   │   │   ├── config/
│   │   │   │   ├── MyBatisPlusConfig.java  # MyBatis-Plus 分页插件
│   │   │   │   ├── MyMetaObjectHandler.java  # 自动填充（时间）
│   │   │   │   └── WebMvcConfig.java      # WebMVC 配置
│   │   │   └── interceptor/RoleInterceptor.java  # 角色鉴权拦截器
│   │   └── module/
│   │       ├── teacher/chapter/           # 教师端 - 章节管理
│   │       │   ├── controller/ChapterController.java
│   │       │   ├── service/ChapterService.java
│   │       │   ├── service/impl/ChapterServiceImpl.java
│   │       │   ├── mapper/ChapterMapper.java
│   │       │   ├── entity/Chapter.java
│   │       │   ├── dto/ChapterAddDTO.java
│   │       │   ├── dto/ChapterEditDTO.java
│   │       │   ├── vo/ChapterVO.java
│   │       │   └── vo/ChapterPageVO.java
│   │       └── admin/                     # 管理员端
│   │           ├── semester/              # 学期管理
│   │           ├── course/                # 课程管理
│   │           └── config/                # 系统配置
│   └── resources/
│       └── application.yml               # 应用配置
└── README.md                             # 本文档
`

## 三、接口清单

### 3.1 教师端 - 课程章节管理（请求头 role=teacher）

| 序号 | 接口名称 | 请求URL | 请求方式 | 参数说明 | 返回示例 |
|------|----------|---------|---------|----------|----------|
| 1 | 添加章节 | /api/teacher/chapter/add | POST | courseId(选填,父为0时必填), parentId(必填,顶级传0), chapterName(必填) | {"code":200,"msg":"操作成功"} |
| 2 | 分页查询顶级章节 | /api/teacher/chapter/page | GET | courseId(必填), pageNum(默认1), pageSize(默认10) | {"code":200,"data":{"records":[...],"hasMore":true,...}} |
| 3 | 展开查询子章节 | /api/teacher/chapter/children | GET | parentId(必填) | {"code":200,"data":[...]} |
| 4 | 编辑章节 | /api/teacher/chapter/edit | PUT | id(必填), chapterName(必填) | {"code":200,"msg":"操作成功"} |
| 5 | 删除章节 | /api/teacher/chapter/delete/{id} | DELETE | id(路径参数,必填) | {"code":200,"msg":"删除成功"} |

### 3.2 管理员端 - 学期管理（请求头 role=admin）

| 序号 | 接口名称 | 请求URL | 请求方式 | 参数说明 | 返回示例 |
|------|----------|---------|---------|----------|----------|
| 1 | 新增学期 | /api/admin/semester-course/semester/add | POST | semesterName(必填), startDate(必填,yyyy-MM-dd), endDate(必填) | {"code":200,"msg":"操作成功"} |
| 2 | 编辑学期 | /api/admin/semester-course/semester/edit | PUT | id(必填), semesterName(必填), startDate(必填), endDate(必填) | {"code":200,"msg":"操作成功"} |
| 3 | 学期下拉列表 | /api/admin/semester-course/semester/list | GET | 无 | {"code":200,"data":[...]} |
| 4 | 禁用/启用学期 | /api/admin/semester-course/semester/toggle | PUT | id(必填), enable(布尔,必填) | {"code":200,"msg":"学期已启用"} |

### 3.3 管理员端 - 课程管理（请求头 role=admin）

| 序号 | 接口名称 | 请求URL | 请求方式 | 参数说明 | 返回示例 |
|------|----------|---------|---------|----------|----------|
| 1 | 新增课程 | /api/admin/semester-course/course/add | POST | courseName(必填), courseCode(必填), credit(必填), semesterId(必填) | {"code":200,"msg":"操作成功"} |
| 2 | 编辑课程 | /api/admin/semester-course/course/edit | PUT | id(必填), courseName(必填), courseCode(必填), credit(必填), semesterId(必填) | {"code":200,"msg":"操作成功"} |
| 3 | 课程下拉列表 | /api/admin/semester-course/course/list | GET | semesterId(选填,按学期筛选) | {"code":200,"data":[...]} |
| 4 | 禁用/启用课程 | /api/admin/semester-course/course/toggle | PUT | id(必填), enable(布尔,必填) | {"code":200,"msg":"课程已启用"} |

### 3.4 系统配置接口

| 序号 | 接口名称 | 请求URL | 请求方式 | 角色 | 参数说明 | 返回示例 |
|------|----------|---------|---------|------|----------|----------|
| 1 | 设置生效学期 | /api/admin/semester-course/config/semester | PUT | admin | semesterId(必填) | {"code":200,"msg":"生效学期设置成功"} |
| 2 | 设置生效课程 | /api/admin/semester-course/config/course | PUT | admin | courseId(必填) | {"code":200,"msg":"生效课程设置成功"} |
| 3 | 查询当前配置 | /api/common/config | GET | teacher/admin | 无 | {"code":200,"data":{"semesterId":1,"semesterName":"2025春季",...}} |

## 四、Postman 测试文档

### 4.1 环境配置

1. 打开 Postman，点击左下角 **Environments** -> 点击 **+** 新建环境
2. 环境名称：课程管理系统
3. 添加变量：
   - aseUrl = http://localhost:8080
   - 	eacherRole = 	eacher
   - dminRole = dmin
4. 点击 **Save**

### 4.2 全局请求头设置

1. 点击左侧 Collections -> 点击 **+** 新建 Collection
2. 集合名称：课程管理API
3. 点击集合右侧菜单 **Edit** -> **Headers** 标签页，添加：
   - Key: role, Value: {{role}}
   - Key: Content-Type, Value: application/json

### 4.3 接口测试步骤（教师章节模块）

**步骤1：添加顶级章节**
- Method: POST
- URL: {{baseUrl}}/api/teacher/chapter/add
- Headers: role=teacher, Content-Type=application/json
- Body (raw JSON):
`json
{
    "courseId": 1,
    "parentId": 0,
    "chapterName": "第一章"
}
`

**步骤2：分页查询顶级章节**
- Method: GET
- URL: {{baseUrl}}/api/teacher/chapter/page?courseId=1&pageNum=1&pageSize=10
- Headers: role=teacher

**步骤3：添加子章节**
- POST {{baseUrl}}/api/teacher/chapter/add
- Body: {"parentId": 1, "chapterName": "1.1节"}

**步骤4：展开子章节**
- GET {{baseUrl}}/api/teacher/chapter/children?parentId=1

**步骤5：编辑章节**
- PUT {{baseUrl}}/api/teacher/chapter/edit
- Body: {"id":1, "chapterName":"第一章（更新版）"}

**步骤6：删除章节**
- DELETE {{baseUrl}}/api/teacher/chapter/delete/1

### 4.4 接口测试步骤（管理员模块）

**步骤1：新增学期**
- POST {{baseUrl}}/api/admin/semester-course/semester/add
- Headers: role=admin
- Body: {"semesterName":"2025春季","startDate":"2025-02-24","endDate":"2025-07-04"}

**步骤2：新增课程**
- POST {{baseUrl}}/api/admin/semester-course/course/add
- Headers: role=admin
- Body: {"courseName":"高等数学","courseCode":"MATH101","credit":4,"semesterId":1}

**步骤3：设置生效学期**
- PUT {{baseUrl}}/api/admin/semester-course/config/semester?semesterId=1

**步骤4：设置生效课程**
- PUT {{baseUrl}}/api/admin/semester-course/config/course?courseId=1

**步骤5：查询当前配置**
- GET {{baseUrl}}/api/common/config

### 4.5 响应示例

**成功响应 (200)**
`json
{"code":200,"msg":"操作成功","data":{...}}
`

**失败响应 (500)**
`json
{"code":500,"msg":"系统异常: 学期不存在","data":null}
`

**权限不足 (403)**
`json
{"code":403,"msg":"无权访问教师接口，请使用 teacher 角色","data":null}
`

## 五、项目运行说明

### 5.1 环境要求

| 环境 | 版本 | 说明 |
|------|------|------|
| JDK | 17+ | 必须 JDK 17 及以上 |
| Maven | 3.6+ | 构建工具 |
| MySQL | 5.7+ | 数据库（InnoDB 引擎）|

### 5.2 建库建表步骤

**方式一：命令行导入**
`ash
mysql -u root -p < course-management/init_database.sql
`

**方式二：Navicat/DBeaver/IDEA**
1. 连接 MySQL
2. 打开并执行 init_database.sql

### 5.3 application.yml 数据库配置

`yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/course_management?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver
`

*请根据实际数据库地址、用户名、密码修改上述配置*

### 5.4 启动步骤

**方式一：命令行启动**
`ash
cd course-management
mvn clean package -DskipTests
java -jar target/course-management.jar
`

**方式二：IDEA 启动**
1. File -> Open -> 选择 course-management 目录
2. 等待 Maven 自动下载依赖
3. 运行 CourseApplication.java 的 main 方法

### 5.5 验证方式

浏览器或 Postman 访问：
`
GET http://localhost:8080/api/common/config
`
返回 JSON 数据即表示系统运行正常。

## 六、GitHub 上传步骤

### 6.1 标准 .gitignore 文件

`gitignore
target/
*.jar
*.war
.idea/
*.iml
.classpath
.project
.settings/
.vscode/
.DS_Store
Thumbs.db
*.log
logs/
application-local.yml
application-dev.yml
*.class
`

### 6.2 上传命令

`ash
# 1. 进入项目目录
cd course-management

# 2. 初始化 Git 仓库
git init

# 3. 添加所有文件到暂存区
git add .

# 4. 首次提交
git commit -m "feat: 初始化课程管理系统"

# 5. 关联远程仓库（在 GitHub 先创建空仓库）
git remote add origin https://github.com/你的用户名/course-management.git

# 6. 推送到远程仓库
git push -u origin master
`

### 6.3 后续更新命令

`ash
git status
git add .
git commit -m "feat: 添加XX功能"
git push
`

## 七、核心设计说明

### 7.1 统一返回格式

所有接口统一返回：
`json
{"code": 200, "msg": "操作成功", "data": ...}
`

code=200 成功，code=500 失败，code=403 无权限

### 7.2 角色鉴权机制

通过请求头 ole 校验身份：
- 	eacher -> 仅可访问 /api/teacher/ 前缀接口
- dmin -> 仅可访问 /api/admin/ 前缀接口
- 公共接口 /api/common/ 无需角色校验

### 7.3 树形章节结构

使用 parent_id 实现无限层级，sort 字段控制排序（数值越大越靠后）

### 7.4 MySQL 5.7 兼容说明

- 递归删除在 Java 层通过循环实现，不使用 WITH RECURSIVE
- 所有表使用 InnoDB 引擎、utf8mb4 字符集
- 统一逻辑删除（is_deleted，0=正常 1=删除）
- 自带创建时间、更新时间自动填充
