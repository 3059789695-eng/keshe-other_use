-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: smart_admin_v3
-- ------------------------------------------------------
-- Server version	8.0.45

-- ============================================================================
-- 智能考试系统 — 完整数据库 v4.0
-- ============================================================================
-- 数据库名：smart_admin_v3
-- 字符集  ：utf8mb4 / utf8mb4_general_ci
-- 引擎    ：InnoDB
-- 兼容版本：MySQL 5.7.8+ / 8.0+
-- 总表数  ：76 张（框架 45 张 + 考试业务 31 张）
-- 更新日期：2026-07-30
--
-- ============================================================================
-- 【给新人的阅读指南】
-- ============================================================================
--
-- 这个数据库分为两大块，按字母排序是故意的，这里按逻辑分组解释：
--
-- ┌─────────────────────────────────────────────────────┐
-- │ 一、框架表（44 张，t_ 前缀）                          │
-- │    Smart Admin 自带，已包含完整 RBAC 功能              │
-- │    核心表：t_employee（用户）、t_role（角色）、         │
-- │    t_menu（菜单/权限点）、t_department（部门）         │
-- │    不要删改这些表，考试业务通过 employee_id 引用用户    │
-- └─────────────────────────────────────────────────────┘
-- ┌─────────────────────────────────────────────────────┐
-- │ 二、考试业务表（32 张，t_ 前缀）                       │
-- │    按功能模块分组，下面是"哪张表对应哪个功能"           │
-- └─────────────────────────────────────────────────────┘
--
--   🏫 基础数据（A-04/A-05）
--     t_semester           学期表
--     t_config             系统配置（框架自带）
--
--   📚 课程模块（S-03/T-07/T-09/T-10/T-11）
--     t_course             课程表
--     t_chapter            课程章节表
--     t_course_offering    开课表（学期+课程+教师）
--     t_course_selection   选课表（学生选课记录）
--     t_course_audience    开课受众范围（哪些班级可参加）← v3.2新增
--     t_enrollment_log     选课/退课操作日志（审计留痕）  ← v3.2新增
--
--   📝 题库模块（T-01/T-02）
--     t_corpus             语料表（上传的教学资料文件）
--     t_question           题目表（单选/多选/判断/简答/论述）
--
--   📋 考试模块（T-03/T-04/S-04/S-05/S-06）
--     t_exam               考试表（考试发布与状态管理）
--     t_exam_question      试卷-题目关联表
--     t_paper_snapshot     试卷快照（发布时存档，防题库变更污染）← v3.2新增
--     t_exam_verification  身份验证表（人脸/声纹+准入令牌）   ← v3.2新增
--     t_student_answer     学生作答记录（含乐观锁 answer_version）
--     t_answer_detail      答案详情（含AI三维评分+草稿draft）
--
--   📊 成绩模块（S-07/S-08/T-05）
--     t_score              原始成绩表（权威分数记录，总分+排名）
--     t_score_report       成绩报告表（展示分+AI建议+三维度，与原始分分离）← v3.2新增
--     t_scoring_rubric     评分标准配置（三维权重+自定义提示词） ← v3.2新增
--
--   🔄 复议模块（S-09/S-10/T-08）
--     t_appeal             复议申请表
--     t_attachment         通用附件表（复议/请假/奖励的证据文件）← v3.2新增
--
--   🔍 监考与异常（T-06）
--     t_monitor_event      监控事件表（切屏/失焦/开控制台等，仅记录事实）← v3.2新增
--     t_abnormal_decision  异常判定表（对事件的判定，支持复核改判）    ← v3.2新增
--
--   📌 成绩登记（T-21~T-24）
--     t_random_check       随机抽查成绩
--     t_unit_test / t_unit_test_score    单元测试
--     t_experiment / t_experiment_score  实验成绩
--     t_attendance_violation             考勤违纪
--
--   👤 生物特征（S-01/S-02/S-05）
--     t_biometric_ref      生物特征引用（存第三方服务模板ID）
--
--   ✋ 请销假 & 奖励（S-10/S-11/T-25/T-26）
--     t_leave_application  请假申请表
--     t_reward_application 奖励申请表
--
-- ============================================================================
-- 【重要设计决策说明】
-- ============================================================================
--
--  1. 为什么"成绩"有两张表（t_score + t_score_report）？
--     → t_score 存原始总分，是权威数据；t_score_report 存展示分（×难度系数）、
--       AI建议、逐题维度评分。前端 S-07 成绩页直接从 t_score_report 渲染，
--       不修改 t_score 的结构。后续扩展报告功能（PDF导出等）不影响核心成绩。
--
--  2. 为什么"异常"拆成两张表（t_monitor_event + t_abnormal_decision）？
--     → 事件（发生了什么）和判定（怎么处理）是两件事。一个切屏事件可能先被
--       自动判定为违规，学生申诉后教师复核改判为误判——两张表可以保留完整
--       判定历史（version 1→2），而不是 UPDATE 覆盖原记录。
--
--  3. t_answer_detail 为什么有 draft字段？
--     → 自动保存的草稿存 draft，正式提交时才写入 user_answer。防止学生未完成
--       的答题被当成正式答案批改。前端每30秒自动保存一次。
--
--  4. answer_version 乐观锁怎么用？
--     → 学生可能同时开两个浏览器标签答题，每次自动保存带着版本号。
--       后端 UPDATE ... SET ... WHERE answer_version = ?。
--       版本号不匹配就拒绝，返回"答案已被其他端覆盖，请刷新"。
--
--  5. 为什么不使用物理外键（FOREIGN KEY）？
--     → ①逻辑删除（deleted_flag）与外键冲突；
--       ②删数据时被外键卡住；
--       ③团队联调时减少互相阻塞。
--       关联关系靠代码校验，不靠数据库约束。
--
-- ============================================================================
-- 【字段约定速查】
-- ============================================================================
--
--  命名       含义                               示例
--  ────────── ────────────────────────────────── ────────────
--  *_id       主键                                score_id
--  *_flag     布尔标记（tinyint(1),0=false/1=true） deleted_flag
--  *_time     时间                                create_time, submit_time
--  *count     计数                                verify_fail_count
--  *score     分数/得分（decimal）                 total_score
--  *status    状态枚举（tinyint）                  status [1:...,2:...]
--  *type      类型枚举（tinyint）                  question_type
--  *url       文件/链接（varchar）                 screenshot_url
--  *json      JSON数据                            question_scores, evidence_urls
--
-- ============================================================================

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `smart_admin_v3`
--

/*!40000 DROP DATABASE IF EXISTS `smart_admin_v3`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `smart_admin_v3` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

USE `smart_admin_v3`;

--
-- Table structure for table `t_answer_detail`
--

DROP TABLE IF EXISTS `t_answer_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_answer_detail` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
  `answer_id` bigint NOT NULL COMMENT '作答记录 ID（关联 t_student_answer）',
  `question_id` bigint NOT NULL COMMENT '题目 ID（关联 t_question）',
  `user_answer` text COMMENT '用户答案文本',
  `draft` text COMMENT '答案草稿（自动保存内容，提交时转入 user_answer。草稿与正式答案分离，防止未提交内容被当作有效答案批改）',
  `voice_record_url` varchar(500) DEFAULT NULL COMMENT '语音答题录音 URL',
  `score` decimal(10,2) DEFAULT NULL COMMENT '原始得分（NULL 表示未批改，规则自动/简单AI给出的初始分）',
  `relevance_score` decimal(5,2) DEFAULT NULL COMMENT '相关性维度得分（AI评分，0-5分制，评估答案紧扣题意的程度。与t_scoring_rubric.dimension_weights配合计算加权分）',
  `knowledge_coverage` decimal(5,2) DEFAULT NULL COMMENT '知识覆盖维度得分（AI评分，0-5分制，评估知识点覆盖完整度）',
  `logic_expression` decimal(5,2) DEFAULT NULL COMMENT '逻辑表达维度得分（AI评分，0-5分制，评估论述逻辑性与表达清晰度）',
  `weighted_score` decimal(10,2) DEFAULT NULL COMMENT '三维加权分（公式：题目满分 × (相关性×权重1 + 覆盖度×权重2 + 逻辑×权重3)，权重从t_scoring_rubric.dimension_weights取）',
  `final_score` decimal(10,2) DEFAULT NULL COMMENT '最终得分（加权分经教师复核调整后的最终分数，作为成绩汇总依据）',
  `ai_feedback` varchar(500) DEFAULT NULL COMMENT 'AI 批改反馈文字（如"要点齐全，表述清晰；缺少对异常处理的说明"）',
  `grade_type` tinyint DEFAULT NULL COMMENT '批改方式 [1:规则自动,2:外部AI服务,3:人工批改]',
  `rubric_id` bigint DEFAULT NULL COMMENT '使用的评分标准 ID（关联 t_scoring_rubric.rubric_id，记录批改时用的哪套评分标准，便于审计追溯）',
  `grade_remark` varchar(1000) DEFAULT NULL COMMENT '教师批注/补充评语（可覆盖或补充 AI 反馈）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_answer_question` (`answer_id`,`question_id`),
  KEY `idx_answer_id` (`answer_id`),
  KEY `idx_question_id` (`question_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='答案详情表（S-06答题保存/S-07成绩展示。含AI三维评分维度：relevance_score相关性/knowledge_coverage知识覆盖/logic_expression逻辑表达。draft字段存自动保存草稿，提交后才转入user_answer）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_answer_detail`
--

LOCK TABLES `t_answer_detail` WRITE;
/*!40000 ALTER TABLE `t_answer_detail` DISABLE KEYS */;
INSERT INTO `t_answer_detail` VALUES (1,1,1,'数据库具有数据独立性，应用程序与数据分离；数据库统一管理减少冗余；支持多用户并发访问并保证数据安全...',NULL,NULL,18.00,4.8,4.5,4.6,18.45,18.40,'要点齐全，表述清晰。相关性高，知识覆盖完整，逻辑严谨。可补充事务管理方面的对比。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(2,1,2,'实体完整性通过主键约束确保每行唯一标识且非空；参照完整性通过外键约束维护表间引用一致；用户定义完整性针对业务规则...',NULL,NULL,16.00,4.3,3.9,4.0,16.19,16.20,'参照完整性论述略简，缺少级联操作的说明。整体框架正确，建议补充外键的CASCADE选项说明。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(3,1,3,'SELECT s.name FROM student s JOIN sc ON s.id = sc.student_id GROUP BY s.id, s.name HAVING COUNT(sc.course_id) > 3;',NULL,NULL,19.00,4.9,4.8,4.7,19.08,19.00,'SQL写法完全正确，表关联合理，分组逻辑清晰。注意可加 ORDER BY 增强输出可读性。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(4,1,4,'① 图书表Book(bid, title, author, isbn) ② 读者表Reader(rid, name, phone) ③ 借阅表Borrow(bid, rid, borrow_date, return_date)，三个表均满足3NF，无传递依赖...',NULL,NULL,17.00,4.5,4.3,4.1,17.14,17.20,'范式判定基本到位，主键外键设计合理。建议补充BCNF的讨论以展现实体设计的深入思考。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(5,1,5,'原子性：事务不可再分，要么全执行要么全不执行；一致性：事务前后数据满足所有约束；隔离性：并发事务之间互不干扰，有四个隔离级别（读未提交、读已提交、可重复读、串行化）；持久性：事务提交后数据永久保存...',NULL,NULL,18.00,4.8,4.5,4.4,18.21,18.20,'ACID四特性解释准确，隔离级别说明完整。逻辑表达流畅，学术表述规范。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(6,2,1,'文件系统数据分散管理、冗余大且缺乏并发控制；数据库集中管理、支持多用户高效访问、数据独立且安全...',NULL,NULL,15.00,4.0,3.5,3.8,14.95,15.00,'基本方向正确，但对数据独立性理解不深，缺少事务与备份恢复的对比论述。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(7,2,2,'实体完整性保证每行不重复，参照完整性保证外键有对应的值...',NULL,NULL,13.00,3.5,3.1,3.3,13.10,13.20,'概念正确但表述过于简略，缺少用户定义完整性的说明和具体SQL示例。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(8,3,1,'数据库管理数据更规范，可以多人同时使用，数据不容易丢失，查询速度快。文件系统就是普通存文件...',NULL,NULL,12.00,3.3,2.8,3.0,11.90,12.00,'答出了多用户和数据安全，但术语不规范，缺少数据独立性、冗余控制等核心概念的学术表述。',2,NULL,NULL,'2026-07-30 01:49:05',NULL),(9,3,3,'SELECT name FROM student WHERE id IN (SELECT student_id FROM sc GROUP BY student_id HAVING COUNT(*) > 3)',NULL,NULL,17.60,4.6,4.3,4.4,17.68,17.60,'使用子查询实现，逻辑正确，写法等价。建议也掌握 JOIN + GROUP BY 的写法以备性能对比。',2,NULL,NULL,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_answer_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_appeal`
--

DROP TABLE IF EXISTS `t_appeal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_appeal` (
  `appeal_id` bigint NOT NULL AUTO_INCREMENT COMMENT '复议 ID',
  `score_id` bigint NOT NULL COMMENT '成绩 ID',
  `answer_detail_id` bigint NOT NULL COMMENT '答案详情 ID（定位到具体题目）',
  `exam_id` bigint NOT NULL COMMENT '考试 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `appeal_reason` varchar(500) NOT NULL COMMENT '复议理由（学生填写，最多500字，必填）',
  `evidence_urls` json DEFAULT NULL COMMENT '证据截图 URL 数组（最多 3 张）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态（系统管理） [1:待审核,2:已通过,3:已驳回]',
  `old_score` decimal(10,2) DEFAULT NULL COMMENT '原题目得分（系统快照，提交复议时自动记录）',
  `new_score` decimal(10,2) DEFAULT NULL COMMENT '复议后得分（教师填写，通过时=新分数，驳回时=NULL）',
  `teacher_remark` varchar(500) DEFAULT NULL COMMENT '教师处理意见（教师填写，必填）',
  `teacher_id` bigint DEFAULT NULL COMMENT '处理教师ID（系统自动记录，t_employee.employee_id）',
  `handle_time` datetime DEFAULT NULL COMMENT '处理时间（系统自动记录）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间（系统自动记录）',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`appeal_id`),
  UNIQUE KEY `uk_detail_appeal` (`answer_detail_id`),
  KEY `idx_status` (`status`),
  KEY `idx_exam_id` (`exam_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='申诉复议表（S-09学生申请复议/S-10查看复议进度/T-08教师处理复议。同一道题不可重复申请，uk_detail_appeal唯一约束保证）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_appeal`
--

LOCK TABLES `t_appeal` WRITE;
/*!40000 ALTER TABLE `t_appeal` DISABLE KEYS */;
INSERT INTO `t_appeal` VALUES (1,1,2,1,4,'参照完整性部分我答了外键的级联规则，应该加分',NULL,2,16.00,16.20,'认可，经复核补0.2分',2,'2025-11-15 10:00:00','2026-07-30 01:49:05',NULL),(2,1,1,1,4,'简答题要点已全覆盖，希望复核',NULL,3,18.00,NULL,'评分合理，维持原分',2,'2025-11-15 10:05:00','2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_appeal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_attendance_violation`
--

DROP TABLE IF EXISTS `t_attendance_violation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_attendance_violation` (
  `violation_id` bigint NOT NULL AUTO_INCREMENT COMMENT '违规 ID',
  `offering_id` bigint NOT NULL COMMENT '开课 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `violation_type` tinyint NOT NULL COMMENT '类型 [1:迟到,2:旷课,3:作弊]',
  `violation_count` int NOT NULL DEFAULT '1' COMMENT '违规次数',
  `zero_score_count` int NOT NULL DEFAULT '0' COMMENT '折合零分个数（迟到1/旷课2/作弊10）',
  `violation_date` date NOT NULL COMMENT '违规日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator_id` bigint NOT NULL COMMENT '登记教师 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`violation_id`),
  KEY `idx_offering_student` (`offering_id`,`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='考勤违纪登记表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_attendance_violation`
--

LOCK TABLES `t_attendance_violation` WRITE;
/*!40000 ALTER TABLE `t_attendance_violation` DISABLE KEYS */;
INSERT INTO `t_attendance_violation` VALUES (1,1,5,1,1,0,'2025-10-13','迟到12分钟',2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_attendance_violation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_biometric_ref`
--

DROP TABLE IF EXISTS `t_biometric_ref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_biometric_ref` (
  `ref_id` bigint NOT NULL AUTO_INCREMENT COMMENT '引用 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `biometric_type` tinyint NOT NULL COMMENT '类型 [1:人脸,2:声纹]',
  `external_template_id` varchar(200) NOT NULL COMMENT '第三方服务的模板 ID',
  `sample_url` varchar(500) DEFAULT NULL COMMENT '样本文件 URL（照片/录音）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态 [1:有效,2:已失效]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`ref_id`),
  UNIQUE KEY `uk_student_type` (`student_id`,`biometric_type`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='生物特征引用表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_biometric_ref`
--

LOCK TABLES `t_biometric_ref` WRITE;
/*!40000 ALTER TABLE `t_biometric_ref` DISABLE KEYS */;
INSERT INTO `t_biometric_ref` VALUES (1,4,1,'FACE_TPL_STU4_001','/bio/face/stu4.jpg',1,'2026-07-30 01:49:05',NULL),(2,5,1,'FACE_TPL_STU5_001','/bio/face/stu5.jpg',1,'2026-07-30 01:49:05',NULL),(3,6,1,'FACE_TPL_STU6_001','/bio/face/stu6.jpg',1,'2026-07-30 01:49:05',NULL),(4,4,2,'VOICE_TPL_STU4_001','/bio/voice/stu4.wav',1,'2026-07-30 01:49:05',NULL),(5,5,2,'VOICE_TPL_STU5_001','/bio/voice/stu5.wav',1,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_biometric_ref` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_category`
--

DROP TABLE IF EXISTS `t_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_category` (
  `category_id` int NOT NULL AUTO_INCREMENT COMMENT '分类id',
  `category_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分类名称',
  `category_type` smallint NOT NULL COMMENT '分类类型',
  `parent_id` int NOT NULL COMMENT '父级id',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `disabled_flag` tinyint NOT NULL DEFAULT '0' COMMENT '是否禁用',
  `deleted_flag` tinyint NOT NULL DEFAULT '0' COMMENT '是否删除',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`category_id`) USING BTREE,
  KEY `idx_parent_id` (`parent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=381 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='分类表，主要用于商品分类';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_category`
--

LOCK TABLES `t_category` WRITE;
/*!40000 ALTER TABLE `t_category` DISABLE KEYS */;
INSERT INTO `t_category` VALUES (1,'手机',1,0,0,0,0,NULL,'2022-10-10 22:27:24','2022-07-14 20:55:15'),(2,'键盘',1,0,0,0,0,NULL,'2022-09-14 21:39:00','2022-07-14 20:55:48'),(3,'自定义1',2,0,0,0,0,NULL,'2022-09-14 22:01:06','2022-07-14 20:56:03'),(4,'自定义2',2,0,0,0,0,NULL,'2022-09-14 22:01:10','2022-07-14 20:56:09'),(351,'鼠标',1,0,0,0,0,NULL,'2022-09-14 21:39:06','2022-09-14 21:39:06'),(352,'苹果',1,1,0,0,0,NULL,'2022-09-14 21:39:25','2022-09-14 21:39:25'),(353,'华为',1,1,0,0,0,NULL,'2022-09-14 21:39:32','2022-09-14 21:39:32'),(354,'IKBC',1,2,0,0,0,NULL,'2022-09-14 21:39:38','2022-09-14 21:39:38'),(355,'双飞燕',1,2,0,0,0,NULL,'2022-09-14 21:39:47','2022-09-14 21:39:47'),(356,'罗技',1,351,0,0,0,NULL,'2022-09-14 21:39:57','2022-09-14 21:39:57'),(357,'小米',1,1,0,0,0,NULL,'2022-10-10 22:27:39','2022-10-10 22:27:39'),(360,'iphone',1,352,0,0,0,NULL,'2023-12-04 21:26:55','2023-12-01 19:54:22');
/*!40000 ALTER TABLE `t_category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_change_log`
--

DROP TABLE IF EXISTS `t_change_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_change_log` (
  `change_log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '更新日志id',
  `update_version` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '版本',
  `type` int NOT NULL COMMENT '更新类型:[1:特大版本功能更新;2:功能更新;3:bug修复]',
  `publish_author` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '发布人',
  `public_date` date NOT NULL COMMENT '发布日期',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '更新内容',
  `link` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '跳转链接',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`change_log_id`) USING BTREE,
  UNIQUE KEY `version_unique` (`update_version`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统更新日志';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_change_log`
--

LOCK TABLES `t_change_log` WRITE;
/*!40000 ALTER TABLE `t_change_log` DISABLE KEYS */;
INSERT INTO `t_change_log` VALUES (2,'v1.1.0',2,'卓大','2020-05-09','SmartAdmin中后台系统 v1.1.0 版本（20200422）正式更新上线，更新内容如下：\n\n1.【新增】增加员工姓名查询\n\n2.【新增】增加文件预览组件\n\n3.【新增】新增四级菜单\n','http://smartadmin.1024lab.net/views/1.x/base/About.html','2022-10-04 21:33:50','2022-10-04 21:33:50'),(8,'v1.0.0',1,'卓大','2019-11-01','SmartAdmin中后台系统 v1.0.0 版本（20191101）正式更新上线，更新内容如下：\n\n1.【新增】人员管理\n\n2.【新增】系统设置\n\n3.【新增】心跳服务\n\n4.【新增】动态加载\n\n5.【新增】缓存策略\n\n6.【新增】定时任务','http://smartadmin.1024lab.net/views/1.x/base/About.html','2022-10-04 21:33:50','2022-10-04 21:33:50'),(9,'v1.2.0',2,'卓大','2020-05-23','SmartAdmin中后台系统 v1.2.0 版本（20200515）正式更新上线，更新内容如下：\n\n1.【新增】增加数据权限\n\n2.【新增】帮助文档',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(10,'v1.2.1',3,'卓大','2020-05-24','SmartAdmin中后台系统 v1.2.1 版本（20200524）正式更新上线，更新内容如下：\n\n1.【修复】四级菜单权限bug\n\n2.【修复】缓存keepalive的Bug\n\n',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(11,'v1.3.0',2,'卓大','2020-06-01','SmartAdmin中后台系统 v1.3.0 版本（20200601）正式更新上线，更新内容如下：\n\n1.【新增】工作台看板功能\n\n2.【新增】天气预报功能\n\n3.【新增】记录上次登录IP功能',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(12,'v1.4.0',2,'卓大','2020-06-06','SmartAdmin中后台系统 v1.4.0 版本（20200606）正式更新上线，更新内容如下：\n\n1.【新增】联系客服功能\n\n2.【新增】意见反馈功能',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(13,'v1.5.0',2,'卓大','2020-06-14','SmartAdmin中后台系统 v1.5.0 版本（20200614）正式更新上线，更新内容如下：\n\n1.【新增】OA系统\n\n2.【新增】通知公告',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(14,'v1.6.0',2,'卓大','2020-06-17','SmartAdmin中后台系统 v1.6.0 版本（20200617）正式更新上线，更新内容如下：\n\n1.【新增】代码生成\n\n2.【新增】通知公告',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(15,'v2.0.0',1,'卓大','2022-10-22','SmartAdmin中后台系统 v2.0.0 版本（20191101）正式更新上线，更新内容如下：\n\n1.【新增】人员管理\n\n2.【新增】系统设置\n\n3.【新增】心跳服务\n\n4.【新增】动态加载\n\n5.【新增】缓存策略\n\n6.【新增】定时任务','http://smartadmin.1024lab.net/views/1.x/base/About.html','2022-10-04 21:33:50','2022-10-04 21:33:50'),(16,'v1.7.0',2,'卓大','2022-10-22','SmartAdmin中后台系统 v1.7.0 版本（20200624）正式更新上线，更新内容如下：\n\n1.【新增】商品管理\n\n2.【新增】商品分类',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50'),(18,'v3.0.0',1,'卓大','2024-01-01','SmartAdmin中后台系统 v3.0.0 版本（20240101）正式更新上线，更新内容如下：\n\n\n1、【新增】权限从SpringSecurity 转成 Sa-Token\n\n2、【新增】增加接口 加密、解密功能\n\n3、【新增】增加网络安全相关功能：登录限制、密码复杂度、最大在线时长等\n\n4、【新增】ant desgin vue 为 4.x 最新版本\n\n5、【新增】升级 vite5\n\n6、【新增】swagger增加knife4j接口文档\n\n7、【优化】后端sa-common 改名为 sa-base\n\n8、【优化】优化官网文档说明\n',NULL,'2022-10-04 21:33:50','2022-10-04 21:33:50');
/*!40000 ALTER TABLE `t_change_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_chapter`
--

DROP TABLE IF EXISTS `t_chapter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_chapter` (
  `chapter_id` bigint NOT NULL AUTO_INCREMENT COMMENT '章节 ID',
  `course_id` bigint NOT NULL COMMENT '所属课程 ID',
  `parent_id` bigint NOT NULL DEFAULT '0' COMMENT '父章节 ID（0 表示顶级章节）',
  `chapter_name` varchar(200) NOT NULL COMMENT '章节名称',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '同级排序',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`chapter_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='课程章节表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_chapter`
--

LOCK TABLES `t_chapter` WRITE;
/*!40000 ALTER TABLE `t_chapter` DISABLE KEYS */;
INSERT INTO `t_chapter` VALUES (1,1,0,'第一章 数据库概论',1,0,'2026-07-30 01:49:05',NULL),(2,1,0,'第二章 关系模型',2,0,'2026-07-30 01:49:05',NULL),(3,1,0,'第三章 SQL语言',3,0,'2026-07-30 01:49:05',NULL),(4,1,0,'第四章 数据库设计',4,0,'2026-07-30 01:49:05',NULL),(5,1,0,'第五章 事务与并发控制',5,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_chapter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_code_generator_config`
--

DROP TABLE IF EXISTS `t_code_generator_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_code_generator_config` (
  `table_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '表名',
  `basic` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '基础命名信息',
  `fields` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '字段列表',
  `insert_and_update` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '新建、修改',
  `delete_info` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '删除',
  `query_fields` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '查询',
  `table_fields` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '列表',
  `detail` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '详情',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`table_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='代码生成器的每个表的配置';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_code_generator_config`
--

LOCK TABLES `t_code_generator_config` WRITE;
/*!40000 ALTER TABLE `t_code_generator_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_code_generator_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_config`
--

DROP TABLE IF EXISTS `t_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_config` (
  `config_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `config_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '参数名字',
  `config_key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '参数key',
  `config_value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '上次修改时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`config_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统配置';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_config`
--

LOCK TABLES `t_config` WRITE;
/*!40000 ALTER TABLE `t_config` DISABLE KEYS */;
INSERT INTO `t_config` VALUES (1,'万能密码','super_password','1024ok','执行示例任务2','2026-07-30 01:50:07','2021-12-16 23:32:46'),(2,'三级等保','level3_protect_config','{\n	\"fileDetectFlag\":true,\n	\"loginActiveTimeoutMinutes\":30,\n	\"loginFailLockMinutes\":30,\n	\"loginFailMaxTimes\":3,\n	\"maxUploadFileSizeMb\":30,\n	\"passwordComplexityEnabled\":true,\n	\"regularChangePasswordMonths\":3,\n	\"regularChangePasswordNotAllowRepeatTimes\":3,\n	\"twoFactorLoginEnabled\":false\n}','SmartJob Sample2 update','2024-09-03 21:49:23','2024-08-13 11:44:49');
/*!40000 ALTER TABLE `t_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_corpus`
--

DROP TABLE IF EXISTS `t_corpus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_corpus` (
  `corpus_id` bigint NOT NULL AUTO_INCREMENT COMMENT '语料 ID',
  `course_id` bigint NOT NULL COMMENT '课程 ID',
  `chapter_id` bigint DEFAULT NULL COMMENT '章节 ID',
  `file_name` varchar(300) NOT NULL COMMENT '文件名',
  `file_type` varchar(20) NOT NULL COMMENT '文件类型 [pdf/word/ppt/txt]',
  `file_url` varchar(500) NOT NULL COMMENT '文件存储 URL',
  `file_size` bigint DEFAULT NULL COMMENT '文件大小（字节）',
  `parse_status` tinyint NOT NULL DEFAULT '1' COMMENT '解析状态 [1:解析中,2:解析成功,3:解析失败]',
  `external_ref_id` varchar(200) DEFAULT NULL COMMENT '外部解析服务返回的引用 ID',
  `fail_reason` varchar(500) DEFAULT NULL COMMENT '解析失败原因',
  `uploader_id` bigint NOT NULL COMMENT '上传教师 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`corpus_id`),
  KEY `idx_course_chapter` (`course_id`,`chapter_id`),
  KEY `idx_parse_status` (`parse_status`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='语料表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_corpus`
--

LOCK TABLES `t_corpus` WRITE;
/*!40000 ALTER TABLE `t_corpus` DISABLE KEYS */;
INSERT INTO `t_corpus` VALUES (1,1,1,'数据库课程大纲.pdf','pdf','/corpus/db/outline.pdf',204800,2,NULL,NULL,2,0,'2026-07-30 01:49:05',NULL),(2,1,2,'第二章讲义.docx','word','/corpus/db/ch2.docx',153600,2,NULL,NULL,2,0,'2026-07-30 01:49:05',NULL),(3,1,3,'SQL实验课件.pptx','ppt','/corpus/db/sql.pptx',512000,2,NULL,NULL,2,0,'2026-07-30 01:49:05',NULL),(4,1,4,'范式参考资料.pdf','pdf','/corpus/db/nf.pdf',307200,2,NULL,NULL,2,0,'2026-07-30 01:49:05',NULL),(5,1,5,'事务补充材料.txt','txt','/corpus/db/txn.txt',102400,2,NULL,NULL,2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_corpus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_course`
--

DROP TABLE IF EXISTS `t_course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_course` (
  `course_id` bigint NOT NULL AUTO_INCREMENT COMMENT '课程 ID',
  `course_name` varchar(200) NOT NULL COMMENT '课程名称',
  `course_code` varchar(50) NOT NULL COMMENT '课程编号（唯一）',
  `credit` decimal(4,1) NOT NULL DEFAULT '0.0' COMMENT '学分',
  `description` varchar(1000) DEFAULT NULL COMMENT '课程简介',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`course_id`),
  UNIQUE KEY `uk_course_code` (`course_code`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='课程表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_course`
--

LOCK TABLES `t_course` WRITE;
/*!40000 ALTER TABLE `t_course` DISABLE KEYS */;
INSERT INTO `t_course` VALUES (1,'数据库原理','CS201',3.5,'关系模型、SQL、事务与并发控制、数据库设计',0,'2026-07-30 01:49:05',NULL),(2,'软件工程','CS301',3.0,'需求分析、系统设计、测试与项目管理',0,'2026-07-30 01:49:05',NULL),(3,'数据结构','CS101',4.0,'线性表、树、图与算法分析',0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_course_offering`
--

DROP TABLE IF EXISTS `t_course_offering`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_course_offering` (
  `offering_id` bigint NOT NULL AUTO_INCREMENT COMMENT '开课 ID',
  `course_id` bigint NOT NULL COMMENT '课程 ID',
  `semester_id` bigint NOT NULL COMMENT '学期 ID',
  `teacher_id` bigint NOT NULL COMMENT '授课教师 ID（t_employee.employee_id）',
  `max_student` int NOT NULL DEFAULT '60' COMMENT '人数上限',
  `current_student` int NOT NULL DEFAULT '0' COMMENT '已选人数',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`offering_id`),
  UNIQUE KEY `uk_course_semester_teacher` (`course_id`,`semester_id`,`teacher_id`),
  KEY `idx_semester_id` (`semester_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='开课表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_course_offering`
--

LOCK TABLES `t_course_offering` WRITE;
/*!40000 ALTER TABLE `t_course_offering` DISABLE KEYS */;
INSERT INTO `t_course_offering` VALUES (1,1,2,2,60,3,0,'2026-07-30 01:49:05',NULL),(2,2,2,2,50,1,0,'2026-07-30 01:49:05',NULL),(3,3,2,3,80,0,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_course_offering` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_course_selection`
--

DROP TABLE IF EXISTS `t_course_selection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_course_selection` (
  `selection_id` bigint NOT NULL AUTO_INCREMENT COMMENT '选课 ID',
  `offering_id` bigint NOT NULL COMMENT '开课 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `select_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '选课时间',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记（退课置 1）[0:正常,1:已退课]',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`selection_id`),
  UNIQUE KEY `uk_offering_student` (`offering_id`,`student_id`),
  KEY `idx_student_id` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='选课表（S-03学生选课/T-07教师查看选课名单。退课时deleted_flag置1，操作留痕到t_enrollment_log）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_course_selection`
--

LOCK TABLES `t_course_selection` WRITE;
/*!40000 ALTER TABLE `t_course_selection` DISABLE KEYS */;
INSERT INTO `t_course_selection` VALUES (1,1,4,'2026-07-30 01:49:05',0,NULL),(2,1,5,'2026-07-30 01:49:05',0,NULL),(3,1,6,'2026-07-30 01:49:05',0,NULL),(4,2,4,'2026-07-30 01:49:05',0,NULL);
/*!40000 ALTER TABLE `t_course_selection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_data_tracer`
--

DROP TABLE IF EXISTS `t_data_tracer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_data_tracer` (
  `data_tracer_id` bigint NOT NULL AUTO_INCREMENT,
  `data_id` bigint NOT NULL COMMENT '各种单据的id',
  `type` int NOT NULL COMMENT '单据类型',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '操作内容',
  `diff_old` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '差异：旧的数据',
  `diff_new` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '差异：新的数据',
  `extra_data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '额外信息',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_type` int NOT NULL COMMENT '用户类型：1 后管用户 ',
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名称',
  `ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'ip',
  `ip_region` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'ip地区',
  `user_agent` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户ua',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`data_tracer_id`) USING BTREE,
  KEY `order_id_order_type` (`data_id`,`type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='各种单据操作记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_data_tracer`
--

LOCK TABLES `t_data_tracer` WRITE;
/*!40000 ALTER TABLE `t_data_tracer` DISABLE KEYS */;
INSERT INTO `t_data_tracer` VALUES (35,10,1,'新增',NULL,NULL,NULL,47,1,'善逸','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36 Edg/109.0.1518.61','2023-10-07 19:02:24','2023-10-07 19:02:24'),(36,11,1,'新增',NULL,NULL,NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 19:55:53','2023-12-01 19:55:53'),(37,12,1,'新增',NULL,NULL,NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 19:57:26','2023-12-01 19:57:26'),(38,11,1,'',NULL,NULL,NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 19:58:09','2023-12-01 19:58:09'),(39,2,3,'修改企业信息','统一社会信用代码:\"1024lab\"<br/>详细地址:\"1024大楼\"<br/>区县名称:\"洛龙区\"<br/>禁用状态:false<br/>类型:有限企业<br/>城市名称:\"洛阳市\"<br/>删除状态:false<br/>联系人:\"卓大\"<br/>省份名称:\"河南省\"<br/>企业logo:\"public/common/fb827d63dda74a60ab8b4f70cc7c7d0a_20221022145641_jpg\"<br/>联系人电话:\"18637925892\"<br/>企业名称:\"1024创新实验室\"<br/>邮箱:\"lab1024@163.com\"','营业执照:\"public/common/59b1ca99b7fe45d78678e6295798a699_20231201200459.jpg\"<br/>统一社会信用代码:\"1024lab1\"<br/>详细地址:\"1024大楼\"<br/>区县名称:\"洛龙区\"<br/>禁用状态:false<br/>类型:外资企业<br/>城市名称:\"洛阳市\"<br/>删除状态:false<br/>联系人:\"卓大1\"<br/>省份名称:\"河南省\"<br/>企业logo:\"\"<br/>联系人电话:\"18637925892\"<br/>企业名称:\"1024创新实验室1\"<br/>邮箱:\"lab1024@163.com\"',NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 20:05:05','2023-12-01 20:05:05'),(40,2,3,'修改企业信息','营业执照:\"public/common/59b1ca99b7fe45d78678e6295798a699_20231201200459.jpg\"<br/>统一社会信用代码:\"1024lab1\"<br/>详细地址:\"1024大楼\"<br/>区县名称:\"洛龙区\"<br/>禁用状态:false<br/>类型:外资企业<br/>城市名称:\"洛阳市\"<br/>删除状态:false<br/>联系人:\"卓大1\"<br/>省份名称:\"河南省\"<br/>企业logo:\"\"<br/>联系人电话:\"18637925892\"<br/>企业名称:\"1024创新实验室1\"<br/>邮箱:\"lab1024@163.com\"','营业执照:\"public/common/59b1ca99b7fe45d78678e6295798a699_20231201200459.jpg\"<br/>统一社会信用代码:\"1024lab\"<br/>详细地址:\"1024大楼\"<br/>区县名称:\"洛龙区\"<br/>禁用状态:false<br/>类型:外资企业<br/>城市名称:\"洛阳市\"<br/>删除状态:false<br/>联系人:\"卓大\"<br/>省份名称:\"河南省\"<br/>企业logo:\"\"<br/>联系人电话:\"18637925892\"<br/>企业名称:\"1024创新实验室\"<br/>邮箱:\"lab1024@163.com\"',NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 20:05:54','2023-12-01 20:05:54'),(41,2,3,'更新银行:<br/>',NULL,NULL,NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 20:09:17','2023-12-01 20:09:17'),(42,2,3,'更新发票：<br/>删除状态:由【false】变更为【】',NULL,NULL,NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36','2023-12-01 20:09:20','2023-12-01 20:09:20'),(49,1,3,'修改企业信息','营业执照:\"public/common/852b7e19bef94af39c1a6156edf47cfb_20221022170332_jpg\"<br/>统一社会信用代码:\"1024lab_block\"<br/>详细地址:\"区块链大楼\"<br/>区县名称:\"洛龙区\"<br/>禁用状态:false<br/>类型:有限企业<br/>城市名称:\"洛阳市\"<br/>删除状态:false<br/>联系人:\"开云\"<br/>省份名称:\"河南省\"<br/>企业logo:\"public/common/f4a76fa720814949a610f05f6f9545bf_20221022170256_jpg\"<br/>联系人电话:\"18637925892\"<br/>企业名称:\"1024创新区块链实验室\"','营业执照:\"public/common/1d89055e5680426280446aff1e7e627c_20240306112451.jpeg\"<br/>统一社会信用代码:\"1024lab_block\"<br/>详细地址:\"区块链大楼\"<br/>区县名称:\"洛龙区\"<br/>禁用状态:false<br/>类型:有限企业<br/>城市名称:\"洛阳市\"<br/>删除状态:false<br/>联系人:\"开云\"<br/>省份名称:\"河南省\"<br/>企业logo:\"public/common/34f5ac0fc097402294aea75352c128f0_20240306112435.png\"<br/>联系人电话:\"18637925892\"<br/>企业名称:\"1024创新区块链实验室\"',NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36','2024-03-06 11:24:55','2024-03-06 11:24:55'),(99,12,1,'',NULL,NULL,NULL,1,1,'管理员','127.0.0.1','0|0|0|内网IP|内网IP','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36','2024-09-03 21:06:32','2024-09-03 21:06:32');
/*!40000 ALTER TABLE `t_data_tracer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_department`
--

DROP TABLE IF EXISTS `t_department`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_department` (
  `department_id` bigint NOT NULL AUTO_INCREMENT COMMENT '部门主键id',
  `department_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '部门名称',
  `manager_id` bigint DEFAULT NULL COMMENT '部门负责人id',
  `parent_id` bigint NOT NULL DEFAULT '0' COMMENT '部门的父级id',
  `sort` int NOT NULL COMMENT '部门排序',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`department_id`) USING BTREE,
  KEY `parent_id` (`parent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='部门';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_department`
--

LOCK TABLES `t_department` WRITE;
/*!40000 ALTER TABLE `t_department` DISABLE KEYS */;
INSERT INTO `t_department` VALUES (1,'1024创新实验室',1,0,1,'2022-10-19 20:17:09','2022-10-19 20:17:09'),(2,'开发部',44,1,1000,'2022-10-19 20:22:23','2022-10-19 20:22:23'),(3,'产品部',2,1,99,'2022-10-21 10:25:30','2022-10-21 10:25:30'),(4,'销售部',64,1,9,'2022-10-21 10:25:47','2022-10-21 10:25:47'),(5,'测试部',48,1,0,'2022-11-05 10:54:18','2022-11-05 10:54:18'),(7,'直播组',44,1,1111,'2024-07-02 19:38:15','2024-07-02 19:38:15'),(8,'抖音组',47,7,0,'2024-07-02 19:39:11','2024-07-02 19:39:11');
/*!40000 ALTER TABLE `t_department` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_dict`
--

DROP TABLE IF EXISTS `t_dict`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_dict` (
  `dict_id` bigint NOT NULL AUTO_INCREMENT COMMENT '字典id',
  `dict_name` varchar(500) COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典名字',
  `dict_code` varchar(500) COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典编码',
  `remark` varchar(1000) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '字典备注',
  `disabled_flag` tinyint NOT NULL DEFAULT '0' COMMENT '禁用状态',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`dict_id`),
  UNIQUE KEY `unique_code` (`dict_code`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='字典表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_dict`
--

LOCK TABLES `t_dict` WRITE;
/*!40000 ALTER TABLE `t_dict` DISABLE KEYS */;
INSERT INTO `t_dict` VALUES (1,'商品地区','GOODS_PLACE','用于商品管理中的商品地区1',0,'2025-03-27 14:42:26','2025-03-31 11:23:03');
/*!40000 ALTER TABLE `t_dict` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_dict_data`
--

DROP TABLE IF EXISTS `t_dict_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_dict_data` (
  `dict_data_id` bigint NOT NULL AUTO_INCREMENT COMMENT '字典数据id',
  `dict_id` bigint NOT NULL COMMENT '字典id',
  `data_value` varchar(500) COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典项值',
  `data_label` varchar(500) COLLATE utf8mb4_general_ci NOT NULL COMMENT '字典项显示名称',
  `data_style` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '字典项样式',
  `remark` varchar(1000) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `sort_order` int NOT NULL COMMENT '排序（越大越靠前）',
  `disabled_flag` tinyint NOT NULL DEFAULT '0' COMMENT '禁用状态',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`dict_data_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='字典数据表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_dict_data`
--

LOCK TABLES `t_dict_data` WRITE;
/*!40000 ALTER TABLE `t_dict_data` DISABLE KEYS */;
INSERT INTO `t_dict_data` VALUES (2,1,'LUO_YANG','洛阳','','sad',2,0,'2025-03-27 15:52:39','2025-03-27 20:53:21'),(3,1,'ZHENG_ZHOU','郑州','','',0,0,'2025-03-27 18:58:16','2025-03-27 20:53:32'),(7,1,'BEI_JING','北京','','',0,0,'2025-03-27 20:53:45','2025-03-27 20:53:45'),(8,1,'SHANG_HAI','上海','','',0,0,'2025-03-27 20:53:45','2025-03-27 20:53:45');
/*!40000 ALTER TABLE `t_dict_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_employee`
--

DROP TABLE IF EXISTS `t_employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_employee` (
  `employee_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `employee_uid` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '员工uuid',
  `login_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录帐号',
  `login_pwd` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录密码',
  `actual_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '员工名称',
  `avatar` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `gender` tinyint(1) NOT NULL DEFAULT '0' COMMENT '性别',
  `phone` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '手机号码',
  `department_id` bigint NOT NULL COMMENT '部门id',
  `position_id` bigint DEFAULT NULL COMMENT '职务ID',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '邮箱',
  `disabled_flag` tinyint unsigned NOT NULL COMMENT '是否被禁用 0否1是',
  `deleted_flag` tinyint unsigned NOT NULL COMMENT '是否删除0否 1是',
  `administrator_flag` tinyint NOT NULL DEFAULT '0' COMMENT '是否为超级管理员: 0 不是，1是',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`employee_id`) USING BTREE,
  UNIQUE KEY `employee_uid_index` (`employee_uid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='员工表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_employee`
--

LOCK TABLES `t_employee` WRITE;
/*!40000 ALTER TABLE `t_employee` DISABLE KEYS */;
INSERT INTO `t_employee` VALUES (1,'cf1e361fd46741f5b2a09335cef50db8','admin','$argon2id$v=19$m=16384,t=2,p=1$d9yQEAhck+haKxP2ZtXocg$NEnw3D2Ly8UbYpy2odATLA4ZflZ1FKJjWCuOGrVE4PM','管理员','public/common/f36e59b20faa4720b225edf81d15727a_20250713220349.jpeg',0,'13500000000',1,3,NULL,0,0,1,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(2,'3c253628b4cb4302a7bb83008a82a415','huke','$argon2id$v=19$m=16384,t=2,p=1$3N9HxhPdydtmqXmTmBUxcw$Yh2jMqQ5qmCC1cgezKtFd5vuH8WirHZh6FPnFS0clEY','胡克',NULL,0,'13123123121',1,4,NULL,0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(44,'5e2a57cd8eff4346be03dc2acfed0d7c','zhuoda','$argon2id$v=19$m=16384,t=2,p=1$Mt02VdlsDNrteY/sBOs2uw$0gI5gfb/D4iLGi6RRlEq/4Qo71cseuz5YZrwiCj3VQI','卓大',NULL,1,'18637925892',1,6,NULL,0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(47,'b031a061076a4732aa0d63989adb1fbc','shanyi','$argon2id$v=19$m=16384,t=2,p=1$lsqZF68KCPkPaF2ShNhtNQ$Zpsv0GLBeau3x0hL0JzpWtnIlNf0hh3+P6Zu5fM6gJw','善逸','public/common/f823b00873684f0a9d31f0d62316cc8e_20240630015141.jpg',1,'17630506613',2,5,NULL,0,0,0,'这个是备注','2025-07-15 10:19:23','2022-10-04 21:33:50'),(48,'e29327485b784211aa9677a9436d2e00','qinjiu','$argon2id$v=19$m=16384,t=2,p=1$ga8Ww+zlLShAzC8o54qftg$3Ete1M8/zzepZqiEV1yNu/U7svMI0EuDWVKZ9X5M1uQ','琴酒',NULL,2,'14112343212',2,6,NULL,0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(63,'cab6922aeeb949a997c93c043b909b05','kaiyun','$argon2id$v=19$m=16384,t=2,p=1$5TZB3BWsbv0FXrgA60+7ag$pnDVVvjE/J0kOet3xLq19fyv1+a/KGqN6B+xsvDluYc','开云',NULL,0,'13112312346',2,5,'ss@qq.com',0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(64,'02ce19c1c707448a81159834a60bbd94','qingye','$argon2id$v=19$m=16384,t=2,p=1$X+M3CF1557PGfLavpWXCPQ$2LsEiOgLFP+VbGA/7TPAbLnkyiLollova6iETB9S/ds','清野',NULL,1,'13123123111',2,4,NULL,0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(65,'e791135b86c34435873f4c9068c0e9ba','feiye','$argon2id$v=19$m=16384,t=2,p=1$cPMw0Xu3dgu4lFX1x+qUvQ$Ol6NktMqi2fGn4Djv+m5ha/DyARWkXA/y784hFVa0rQ','飞叶',NULL,1,'13123123112',4,3,NULL,0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(66,'2954e985557745df844e4c88532cd8a6','luoyi','$argon2id$v=19$m=16384,t=2,p=1$D0lXN4LyhLhtHaKFbS3DRw$0FK9A8F1oT38xqIZvNcu1eWsB5C5vXkwULXhvLxYmK8','罗伊',NULL,1,'13123123142',4,2,NULL,1,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(67,'39cb2c7de94141d6824e9a167912c23d','chuxiao','$argon2id$v=19$m=16384,t=2,p=1$/BdtVk/U5utWvple9bfCQw$eK8JjH+cei7gNQwPDDdP5ACQT3qkYvz5Qk4k016jRpU','初晓',NULL,1,'13123123123',1,2,NULL,1,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50'),(68,'2aaf8c8c393c46b080aca86179388d7e','xuanpeng','$argon2id$v=19$m=16384,t=2,p=1$ldHEjEwCWur/RnSy0JmFJQ$nlhVYiFMELToZ9nXI5QxG4maTV/L7pyPU0GRv3+s+tg','玄朋',NULL,1,'13123123124',1,3,NULL,0,0,0,NULL,'2025-07-15 10:19:23','2022-10-04 21:33:50');
/*!40000 ALTER TABLE `t_employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_exam`
--

DROP TABLE IF EXISTS `t_exam`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_exam` (
  `exam_id` bigint NOT NULL AUTO_INCREMENT COMMENT '考试 ID',
  `offering_id` bigint NOT NULL COMMENT '开课 ID（关联课程+学期+教师）',
  `chapter_id` bigint DEFAULT NULL COMMENT '考核章节 ID',
  `scope_snapshot` json DEFAULT NULL COMMENT '考核范围快照（章节ID+名称，创建时冗余存储，防止章节改名/删除后历史考试范围错乱）',
  `exam_title` varchar(200) NOT NULL COMMENT '考试标题',
  `exam_code` varchar(50) NOT NULL COMMENT '考试代码（唯一标识）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态 [1:草稿,2:已发布,3:进行中,4:已结束,5:暂停]',
  `start_time` datetime NOT NULL COMMENT '开始时间',
  `end_time` datetime NOT NULL COMMENT '截止时间',
  `time_limit` int NOT NULL DEFAULT '60' COMMENT '考试时长（分钟）',
  `total_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总分',
  `pass_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '及格线',
  `difficulty_value` decimal(4,2) DEFAULT NULL COMMENT '总难度值（10-15 可调）',
  `group_rule` varchar(500) DEFAULT NULL COMMENT '组卷规则描述（如"各章至少1题，难度均衡"）',
  `creator_id` bigint NOT NULL COMMENT '创建教师 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`exam_id`),
  UNIQUE KEY `uk_exam_code` (`exam_code`),
  KEY `idx_offering_id` (`offering_id`),
  KEY `idx_status_time` (`status`,`end_time`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='考试表（T-03教师创建考试/S-04学生查看考试任务/S-06参加考试。status字段控制考试生命周期：草稿→已发布→进行中→已结束）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_exam`
--

LOCK TABLES `t_exam` WRITE;
/*!40000 ALTER TABLE `t_exam` DISABLE KEYS */;
INSERT INTO `t_exam` VALUES (1,1,NULL,NULL,'数据库期中考试','EXAM-DB-MID',4,'2025-11-10 09:00:00','2025-11-10 10:30:00',90,100.00,60.00,12.00,NULL,2,0,'2026-07-30 01:49:05',NULL),(2,1,NULL,NULL,'数据库期末考试','EXAM-DB-FINAL',2,'2026-01-08 09:00:00','2026-01-08 11:00:00',120,100.00,60.00,14.00,NULL,2,0,'2026-07-30 01:49:05',NULL),(3,1,3,'[{\"chapter_id\":3,\"chapter_name\":\"第三章 SQL语言\"}]','SQL专项测验','EXAM-DB-SQL',4,'2025-10-15 14:00:00','2025-10-15 14:40:00',40,50.00,30.00,10.00,NULL,2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_exam` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_exam_question`
--

DROP TABLE IF EXISTS `t_exam_question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_exam_question` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
  `exam_id` bigint NOT NULL COMMENT '考试 ID',
  `question_id` bigint NOT NULL COMMENT '题目 ID',
  `source` tinyint NOT NULL DEFAULT '1' COMMENT '题目来源 [1:题库选取,2:外部导入]',
  `score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '该题在试卷中的分值',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '排序顺序',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_exam_question` (`exam_id`,`question_id`),
  KEY `idx_exam_sort` (`exam_id`,`sort_order`),
  KEY `idx_question_id` (`question_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='试卷-题目关联表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_exam_question`
--

LOCK TABLES `t_exam_question` WRITE;
/*!40000 ALTER TABLE `t_exam_question` DISABLE KEYS */;
INSERT INTO `t_exam_question` VALUES (1,1,1,1,20.00,1,'2026-07-30 01:49:05'),(2,1,2,1,20.00,2,'2026-07-30 01:49:05'),(3,1,3,1,20.00,3,'2026-07-30 01:49:05'),(4,1,4,1,20.00,4,'2026-07-30 01:49:05'),(5,1,5,1,20.00,5,'2026-07-30 01:49:05');
/*!40000 ALTER TABLE `t_exam_question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_experiment`
--

DROP TABLE IF EXISTS `t_experiment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_experiment` (
  `experiment_id` bigint NOT NULL AUTO_INCREMENT COMMENT '实验 ID',
  `offering_id` bigint NOT NULL COMMENT '开课 ID',
  `experiment_name` varchar(200) NOT NULL COMMENT '实验名称',
  `experiment_time` date NOT NULL COMMENT '实验日期',
  `experiment_content` varchar(500) DEFAULT NULL COMMENT '实验内容描述',
  `creator_id` bigint NOT NULL COMMENT '创建教师 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`experiment_id`),
  KEY `idx_offering_id` (`offering_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='实验表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_experiment`
--

LOCK TABLES `t_experiment` WRITE;
/*!40000 ALTER TABLE `t_experiment` DISABLE KEYS */;
INSERT INTO `t_experiment` VALUES (1,1,'实验一：SQL查询与多表连接','2025-10-11',NULL,2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_experiment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_experiment_score`
--

DROP TABLE IF EXISTS `t_experiment_score`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_experiment_score` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
  `experiment_id` bigint NOT NULL COMMENT '实验 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `score` decimal(10,2) DEFAULT NULL COMMENT '成绩（NULL 表示未录入）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_experiment_student` (`experiment_id`,`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='实验成绩明细表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_experiment_score`
--

LOCK TABLES `t_experiment_score` WRITE;
/*!40000 ALTER TABLE `t_experiment_score` DISABLE KEYS */;
INSERT INTO `t_experiment_score` VALUES (1,1,4,95.00,'2026-07-30 01:49:05',NULL),(2,1,5,88.00,'2026-07-30 01:49:05',NULL),(3,1,6,92.00,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_experiment_score` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_feedback`
--

DROP TABLE IF EXISTS `t_feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_feedback` (
  `feedback_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `feedback_content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '反馈内容',
  `feedback_attachment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '反馈图片',
  `user_id` bigint NOT NULL COMMENT '创建人id',
  `user_type` int NOT NULL COMMENT '创建人用户类型',
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建人姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`feedback_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='意见反馈';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_feedback`
--

LOCK TABLES `t_feedback` WRITE;
/*!40000 ALTER TABLE `t_feedback` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_file`
--

DROP TABLE IF EXISTS `t_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_file` (
  `file_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `folder_type` tinyint unsigned NOT NULL COMMENT '文件夹类型',
  `file_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '文件名称',
  `file_size` int DEFAULT NULL COMMENT '文件大小',
  `file_key` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件key，用于文件下载',
  `file_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件类型',
  `creator_id` bigint DEFAULT NULL COMMENT '创建人，即上传人',
  `creator_user_type` int DEFAULT NULL COMMENT '创建人用户类型',
  `creator_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人姓名',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '上次更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`file_id`) USING BTREE,
  UNIQUE KEY `uk_file_key` (`file_key`) USING BTREE,
  KEY `module_id_module_type` (`folder_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='文件';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_file`
--

LOCK TABLES `t_file` WRITE;
/*!40000 ALTER TABLE `t_file` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_file` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_goods`
--

DROP TABLE IF EXISTS `t_goods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_goods` (
  `goods_id` int NOT NULL AUTO_INCREMENT,
  `goods_status` int DEFAULT NULL COMMENT '商品状态:[1:预约中,2:售卖中,3:售罄]',
  `category_id` int NOT NULL COMMENT '商品类目',
  `goods_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '商品名称',
  `place` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '产地',
  `price` decimal(10,2) unsigned NOT NULL COMMENT '价格',
  `shelves_flag` tinyint unsigned NOT NULL COMMENT '上架状态',
  `deleted_flag` tinyint unsigned NOT NULL COMMENT '删除状态',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`goods_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='商品';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_goods`
--

LOCK TABLES `t_goods` WRITE;
/*!40000 ALTER TABLE `t_goods` DISABLE KEYS */;
INSERT INTO `t_goods` VALUES (1,1,353,'Mote60','BEI_JING',9999.00,1,0,NULL,'2022-10-21 19:57:49','2021-09-01 22:25:30'),(7,1,352,'iphone15 pro','LUO_YANG',50000.00,1,0,'备注','2024-06-16 09:34:08','2022-10-21 19:58:07'),(8,1,352,'iphone14','ZHENG_ZHOU',150.00,0,0,'','2022-10-21 19:12:49','2022-10-21 19:00:11'),(10,1,357,'小米15','LUO_YANG',7999.00,1,0,'','2023-10-07 19:02:24','2023-10-07 19:02:24'),(11,1,354,'青轴键盘','ZHENG_ZHOU',199.00,1,0,'支持usb','2023-12-01 19:58:09','2023-12-01 19:55:53'),(12,1,356,'罗技双模鼠标','BEI_JING,ZHENG_ZHOU',99.00,0,0,'支持蓝牙','2024-09-03 21:06:32','2023-12-01 19:57:25');
/*!40000 ALTER TABLE `t_goods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_heart_beat_record`
--

DROP TABLE IF EXISTS `t_heart_beat_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_heart_beat_record` (
  `heart_beat_record_id` int NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `project_path` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '项目名称',
  `server_ip` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '服务器ip',
  `process_no` int NOT NULL COMMENT '进程号',
  `process_start_time` datetime NOT NULL COMMENT '进程开启时间',
  `heart_beat_time` datetime NOT NULL COMMENT '心跳时间',
  PRIMARY KEY (`heart_beat_record_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=189 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='公用服务 - 服务心跳';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_heart_beat_record`
--

LOCK TABLES `t_heart_beat_record` WRITE;
/*!40000 ALTER TABLE `t_heart_beat_record` DISABLE KEYS */;
INSERT INTO `t_heart_beat_record` VALUES (188,'C:\\Users\\wwkkqwq\\Desktop\\smart-admin-master\\smart-admin-api-java17-springboot3\\sa-admin','127.0.0.1;192.168.31.11',82976,'2026-07-28 19:06:27','2026-07-30 01:56:43');
/*!40000 ALTER TABLE `t_heart_beat_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_help_doc`
--

DROP TABLE IF EXISTS `t_help_doc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_help_doc` (
  `help_doc_id` bigint NOT NULL AUTO_INCREMENT,
  `help_doc_catalog_id` bigint NOT NULL COMMENT '类型1公告 2动态',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '标题',
  `content_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文本内容',
  `content_html` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'html内容',
  `attachment` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '附件',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `page_view_count` int NOT NULL DEFAULT '0' COMMENT '页面浏览量，传说中的pv',
  `user_view_count` int NOT NULL DEFAULT '0' COMMENT '用户浏览量，传说中的uv',
  `author` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '作者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`help_doc_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='帮助文档';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_help_doc`
--

LOCK TABLES `t_help_doc` WRITE;
/*!40000 ALTER TABLE `t_help_doc` DISABLE KEYS */;
INSERT INTO `t_help_doc` VALUES (32,6,'企业名称该写什么？','需求1：管理公司基本信息，包含：企业名称、Logo、地区、营业执照、联系人 等等，可以 增删拆改需求2：管理公司的银行账户，包含：银行信息、账户名称、账号、类型等，可以 增删拆改需求3：管理公司的发票信息，包含：开票抬头、纳税号、银行账户、开户行、备注等，可以 增删拆改需求4：对于公司信息、银行信息、发票信息 任何的修改，都有记录 数据变动记录；','<ul><li style=\"text-align: start;\">需求1：管理公司基本信息，包含：企业名称、Logo、地区、营业执照、联系人 等等，可以 增删拆改</li><li style=\"text-align: start;\">需求2：管理公司的银行账户，包含：银行信息、账户名称、账号、类型等，可以 增删拆改</li><li style=\"text-align: start;\">需求3：管理公司的发票信息，包含：开票抬头、纳税号、银行账户、开户行、备注等，可以 增删拆改</li><li style=\"text-align: start;\">需求4：对于公司信息、银行信息、发票信息 任何的修改，都有记录 数据变动记录；</li></ul>','',0,55,1,'卓大','2024-07-07 23:15:28','2022-11-22 10:41:48'),(33,6,'谁有权限查看企业信息','需求1：管理公司基本信息，包含：企业名称、Logo、地区、营业执照、联系人 等等，可以 增删拆改需求2：管理公司的银行账户，包含：银行信息、账户名称、账号、类型等，可以 增删拆改需求3：管理公司的发票信息，包含：开票抬头、纳税号、银行账户、开户行、备注等，可以 增删拆改需求4：对于公司信息、银行信息、发票信息 任何的修改，都有记录 数据变动记录；','<ul><li style=\"text-align: start;\">需求1：管理公司基本信息，包含：企业名称、Logo、地区、营业执照、联系人 等等，可以 增删拆改</li><li style=\"text-align: start;\">需求2：管理公司的银行账户，包含：银行信息、账户名称、账号、类型等，可以 增删拆改</li><li style=\"text-align: start;\">需求3：管理公司的发票信息，包含：开票抬头、纳税号、银行账户、开户行、备注等，可以 增删拆改</li><li style=\"text-align: start;\">需求4：对于公司信息、银行信息、发票信息 任何的修改，都有记录 数据变动记录；</li></ul>','',0,13,1,'卓大','2024-04-10 19:36:55','2022-11-22 10:42:19');
/*!40000 ALTER TABLE `t_help_doc` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_help_doc_catalog`
--

DROP TABLE IF EXISTS `t_help_doc_catalog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_help_doc_catalog` (
  `help_doc_catalog_id` bigint NOT NULL AUTO_INCREMENT COMMENT '帮助文档目录',
  `name` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '名称',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序字段',
  `parent_id` bigint NOT NULL COMMENT '父级id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`help_doc_catalog_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='帮助文档-目录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_help_doc_catalog`
--

LOCK TABLES `t_help_doc_catalog` WRITE;
/*!40000 ALTER TABLE `t_help_doc_catalog` DISABLE KEYS */;
INSERT INTO `t_help_doc_catalog` VALUES (6,'企业信息',0,0,'2022-11-05 10:52:40','2022-11-22 10:37:38'),(9,'企业信用',0,6,'2023-12-01 20:16:54','2023-12-01 20:16:54'),(10,'采购文档',0,11,'2023-12-01 20:17:08','2023-12-01 20:17:29'),(11,'进销存',0,0,'2023-12-01 20:17:23','2023-12-01 20:17:23');
/*!40000 ALTER TABLE `t_help_doc_catalog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_help_doc_relation`
--

DROP TABLE IF EXISTS `t_help_doc_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_help_doc_relation` (
  `relation_id` bigint NOT NULL COMMENT '关联id',
  `relation_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '关联名称',
  `help_doc_id` bigint NOT NULL COMMENT '文档id',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`relation_id`,`help_doc_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='帮助文档-关联表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_help_doc_relation`
--

LOCK TABLES `t_help_doc_relation` WRITE;
/*!40000 ALTER TABLE `t_help_doc_relation` DISABLE KEYS */;
INSERT INTO `t_help_doc_relation` VALUES (0,'首页',32,'2023-12-04 13:34:17','2023-12-04 13:34:17'),(0,'首页',33,'2023-12-04 13:34:21','2023-12-04 13:34:21');
/*!40000 ALTER TABLE `t_help_doc_relation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_help_doc_view_record`
--

DROP TABLE IF EXISTS `t_help_doc_view_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_help_doc_view_record` (
  `help_doc_id` bigint NOT NULL COMMENT '通知公告id',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名称',
  `page_view_count` int DEFAULT '0' COMMENT '查看次数',
  `first_ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '首次ip',
  `first_user_agent` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '首次用户设备等标识',
  `last_ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '最后一次ip',
  `last_user_agent` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '最后一次用户设备等标识',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`help_doc_id`,`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='帮助文档-查看记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_help_doc_view_record`
--

LOCK TABLES `t_help_doc_view_record` WRITE;
/*!40000 ALTER TABLE `t_help_doc_view_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_help_doc_view_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_leave_application`
--

DROP TABLE IF EXISTS `t_leave_application`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_leave_application` (
  `leave_id` bigint NOT NULL AUTO_INCREMENT COMMENT '请假 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `offering_id` bigint NOT NULL COMMENT '开课 ID',
  `leave_type` tinyint NOT NULL COMMENT '类型 [1:事假,2:病假]',
  `start_time` datetime NOT NULL COMMENT '开始时间（精确到分钟）',
  `end_time` datetime NOT NULL COMMENT '结束时间（精确到分钟）',
  `reason` varchar(300) DEFAULT NULL COMMENT '请假事由（最多 300 字）',
  `evidence_urls` json DEFAULT NULL COMMENT '证明材料 URL 数组（最多 3 张）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态 [1:待审批,2:已批准,3:已拒绝]',
  `teacher_id` bigint DEFAULT NULL COMMENT '审批教师 ID（t_employee.employee_id）',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批意见',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`leave_id`),
  KEY `idx_student_status` (`student_id`,`status`),
  KEY `idx_offering_id` (`offering_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='请假申请表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_leave_application`
--

LOCK TABLES `t_leave_application` WRITE;
/*!40000 ALTER TABLE `t_leave_application` DISABLE KEYS */;
INSERT INTO `t_leave_application` VALUES (1,4,1,2,'2025-10-20 08:00:00','2025-10-21 18:00:00','感冒发烧需就医',NULL,2,2,'同意，注意休息','2025-10-19 14:00:00','2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_leave_application` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_login_fail`
--

DROP TABLE IF EXISTS `t_login_fail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_login_fail` (
  `login_fail_id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_type` int NOT NULL COMMENT '用户类型',
  `login_name` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录名',
  `login_fail_count` int DEFAULT NULL COMMENT '连续登录失败次数',
  `lock_flag` tinyint DEFAULT '0' COMMENT '锁定状态:1锁定，0未锁定',
  `login_lock_begin_time` datetime DEFAULT NULL COMMENT '连续登录失败锁定开始时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`login_fail_id`) USING BTREE,
  UNIQUE KEY `uid_and_utype` (`user_id`,`user_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='登录失败次数记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_login_fail`
--

LOCK TABLES `t_login_fail` WRITE;
/*!40000 ALTER TABLE `t_login_fail` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_login_fail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_login_log`
--

DROP TABLE IF EXISTS `t_login_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_login_log` (
  `login_log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int NOT NULL COMMENT '用户id',
  `user_type` int NOT NULL COMMENT '用户类型',
  `user_name` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名',
  `login_ip` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户ip',
  `login_ip_region` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户ip地区',
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'user-agent信息',
  `login_device` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录设备',
  `login_result` int NOT NULL COMMENT '登录结果：0成功 1失败 2 退出',
  `remark` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`login_log_id`) USING BTREE,
  KEY `customer_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1905 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户登录日志';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_login_log`
--

LOCK TABLES `t_login_log` WRITE;
/*!40000 ALTER TABLE `t_login_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_login_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_mail_template`
--

DROP TABLE IF EXISTS `t_mail_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_mail_template` (
  `template_code` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_subject` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '模板名称',
  `template_content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '模板内容',
  `template_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '解析类型 string，freemarker',
  `disable_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否禁用',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`template_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mail_template`
--

LOCK TABLES `t_mail_template` WRITE;
/*!40000 ALTER TABLE `t_mail_template` DISABLE KEYS */;
INSERT INTO `t_mail_template` VALUES ('login_verification_code','登录验证码','<!DOCTYPE HTML>\r\n<html>\r\n<head>\r\n  <title>登录提醒</title>\r\n  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>\r\n  <style>\r\n      * {\r\n          font-family: SimSun;\r\n          /* 4号字体 */\r\n          font-size: 18px;\r\n          /* 22磅行间距 */\r\n          line-height: 29px;\r\n      }\r\n\r\n      .main_font_size {\r\n          font-size: 12.0pt;\r\n      }\r\n\r\n      .mainContent {\r\n          line-height: 28px;\r\n      }\r\n\r\n      p {\r\n          margin: 0 auto;\r\n          text-align: justify;\r\n      }\r\n  </style>\r\n\r\n</head>\r\n<body>\r\n<div>\r\n  <div style=\"margin: 0px auto;width: 690px;\">\r\n    <div class=\"mainContent\">\r\n      <h1>验证码</h1>\r\n      <p>请在验证页面输入此验证码</p>\r\n      <p><b>${code}</b></p>\r\n      <p>验证码将于此电子邮件发出 5 分钟后过期。</p>\r\n      <p>如果你未曾提出此请求，可以忽略这封电子邮件。</p>\r\n    </div>\r\n\r\n  </div>\r\n</div>\r\n</body>\r\n</html>','freemarker',0,'2024-08-06 09:13:08','2024-07-28 13:56:06');
/*!40000 ALTER TABLE `t_mail_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_menu`
--

DROP TABLE IF EXISTS `t_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_menu` (
  `menu_id` bigint NOT NULL AUTO_INCREMENT COMMENT '菜单ID',
  `menu_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '菜单名称',
  `menu_type` int NOT NULL COMMENT '类型',
  `parent_id` bigint NOT NULL COMMENT '父菜单ID',
  `sort` int DEFAULT NULL COMMENT '显示顺序',
  `path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '路由地址',
  `component` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件路径',
  `perms_type` int DEFAULT NULL COMMENT '权限类型',
  `api_perms` varchar(5000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '后端权限字符串',
  `web_perms` varchar(5000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '前端权限字符串',
  `icon` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '菜单图标',
  `context_menu_id` bigint DEFAULT NULL COMMENT '功能点关联菜单ID',
  `frame_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否为外链',
  `frame_url` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '外链地址',
  `cache_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否缓存',
  `visible_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT '显示状态',
  `disabled_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '禁用状态',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除状态',
  `create_user_id` bigint NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_user_id` bigint DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`menu_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=301 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='菜单表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_menu`
--

LOCK TABLES `t_menu` WRITE;
/*!40000 ALTER TABLE `t_menu` DISABLE KEYS */;
INSERT INTO `t_menu` VALUES (26,'菜单管理',2,50,1,'/menu/list','/system/menu/menu-list.vue',NULL,NULL,NULL,'CopyOutlined',NULL,0,NULL,1,1,0,0,2,'2021-08-09 15:04:35',1,'2023-12-01 19:39:03'),(40,'删除',3,26,NULL,NULL,NULL,1,'system:menu:batchDelete','system:menu:batchDelete',NULL,26,0,NULL,0,1,0,0,1,'2021-08-12 09:45:56',1,'2023-10-07 18:15:50'),(45,'组织架构',1,0,3,'/organization',NULL,NULL,NULL,NULL,'UserSwitchOutlined',NULL,0,NULL,0,1,0,0,1,'2021-08-12 16:13:27',1,'2024-07-02 19:27:44'),(46,'员工管理',2,45,3,'/organization/employee','/system/employee/index.vue',NULL,NULL,NULL,'AuditOutlined',NULL,0,NULL,0,1,0,0,1,'2021-08-12 16:21:50',1,'2024-07-02 20:15:23'),(47,'商品管理',2,48,1,'/erp/goods/list','/business/erp/goods/goods-list.vue',NULL,NULL,NULL,'AliwangwangOutlined',NULL,0,NULL,1,1,0,0,1,'2021-08-12 17:58:39',1,'2023-12-01 19:33:08'),(48,'商品管理',1,138,3,'/goods',NULL,NULL,NULL,NULL,'BarcodeOutlined',NULL,0,NULL,0,1,0,0,1,'2021-08-12 18:02:59',1,'2024-07-08 13:58:46'),(50,'系统设置',1,0,6,'/setting',NULL,NULL,NULL,NULL,'SettingOutlined',NULL,0,NULL,0,1,0,0,1,'2021-08-13 16:41:33',1,'2023-12-01 19:38:03'),(76,'角色管理',2,45,4,'/organization/role','/system/role/index.vue',NULL,NULL,NULL,'SlidersOutlined',NULL,0,NULL,0,1,0,0,1,'2021-08-26 10:31:00',1,'2024-07-02 20:15:28'),(78,'商品分类',2,48,2,'/erp/catalog/goods','/business/erp/catalog/goods-catalog.vue',NULL,NULL,NULL,'ApartmentOutlined',NULL,0,NULL,1,1,0,0,1,'2022-05-18 23:34:14',1,'2023-12-01 19:33:13'),(79,'自定义分组',2,48,3,'/erp/catalog/custom','/business/erp/catalog/custom-catalog.vue',NULL,NULL,NULL,'AppstoreAddOutlined',NULL,0,NULL,0,1,0,0,1,'2022-05-18 23:37:53',1,'2023-12-01 19:33:16'),(81,'用户操作记录',2,213,6,'/support/operate-log/operate-log-list','/support/operate-log/operate-log-list.vue',NULL,NULL,NULL,'VideoCameraOutlined',NULL,0,NULL,0,1,0,0,1,'2022-05-20 12:37:24',44,'2024-08-13 14:34:10'),(85,'组件演示',2,84,NULL,'/demonstration/index','/support/demonstration/index.vue',NULL,NULL,NULL,'ClearOutlined',NULL,0,NULL,0,1,0,0,1,'2022-05-20 23:16:46',NULL,'2022-05-20 23:16:46'),(86,'添加部门',3,46,1,NULL,NULL,1,'system:department:add','system:department:add',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-26 23:33:37',1,'2023-10-07 18:26:35'),(87,'修改部门',3,46,2,NULL,NULL,1,'system:department:update','system:department:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-26 23:34:11',1,'2023-10-07 18:26:44'),(88,'删除部门',3,46,3,NULL,NULL,1,'system:department:delete','system:department:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-26 23:34:49',1,'2023-10-07 18:26:49'),(91,'添加员工',3,46,NULL,NULL,NULL,1,'system:employee:add','system:employee:add',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:11:38',1,'2023-10-07 18:27:46'),(92,'编辑员工',3,46,NULL,NULL,NULL,1,'system:employee:update','system:employee:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:12:10',1,'2023-10-07 18:27:49'),(93,'禁用启用员工',3,46,NULL,NULL,NULL,1,'system:employee:disabled','system:employee:disabled',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:12:37',1,'2023-10-07 18:27:53'),(94,'调整员工部门',3,46,NULL,NULL,NULL,1,'system:employee:department:update','system:employee:department:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:12:59',1,'2023-10-07 18:27:34'),(95,'重置密码',3,46,NULL,NULL,NULL,1,'system:employee:password:reset','system:employee:password:reset',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:13:30',1,'2023-10-07 18:27:57'),(96,'删除员工',3,46,NULL,NULL,NULL,1,'system:employee:delete','system:employee:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:14:08',1,'2023-10-07 18:28:01'),(97,'添加角色',3,76,NULL,NULL,NULL,1,'system:role:add','system:role:add',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:34:00',1,'2023-10-07 18:42:31'),(98,'删除角色',3,76,NULL,NULL,NULL,1,'system:role:delete','system:role:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:34:19',1,'2023-10-07 18:42:35'),(99,'编辑角色',3,76,NULL,NULL,NULL,1,'system:role:update','system:role:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:34:55',1,'2023-10-07 18:42:44'),(100,'更新数据范围',3,76,NULL,NULL,NULL,1,'system:role:dataScope:update','system:role:dataScope:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:37:03',1,'2023-10-07 18:41:49'),(101,'批量移除员工',3,76,NULL,NULL,NULL,1,'system:role:employee:batch:delete','system:role:employee:batch:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:39:05',1,'2023-10-07 18:43:32'),(102,'移除员工',3,76,NULL,NULL,NULL,1,'system:role:employee:delete','system:role:employee:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:39:21',1,'2023-10-07 18:43:37'),(103,'添加员工',3,76,NULL,NULL,NULL,1,'system:role:employee:add','system:role:employee:add',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:39:38',1,'2023-10-07 18:44:05'),(104,'修改权限',3,76,NULL,NULL,NULL,1,'system:role:menu:update','system:role:menu:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-05-27 00:41:55',1,'2023-10-07 18:44:11'),(105,'添加',3,26,NULL,NULL,NULL,1,'system:menu:add','system:menu:add',NULL,26,0,NULL,0,1,0,0,1,'2022-05-27 00:44:37',1,'2023-10-07 17:35:35'),(106,'编辑',3,26,NULL,NULL,NULL,1,'system:menu:update','system:menu:update',NULL,26,0,NULL,0,1,0,0,1,'2022-05-27 00:44:59',1,'2023-10-07 17:35:48'),(109,'参数配置',2,50,3,'/config/config-list','/support/config/config-list.vue',NULL,NULL,NULL,'AntDesignOutlined',NULL,0,NULL,0,1,0,0,1,'2022-05-27 13:34:41',1,'2022-06-23 16:24:16'),(110,'数据字典',2,50,4,'/setting/dict','/support/dict/index.vue',NULL,NULL,NULL,'BarcodeOutlined',NULL,0,NULL,0,1,0,0,1,'2022-05-27 17:53:00',1,'2022-05-27 18:09:14'),(111,'监控服务',1,0,100,'/monitor',NULL,NULL,NULL,NULL,'BarChartOutlined',NULL,0,NULL,0,1,0,0,1,'2022-06-17 11:13:23',1,'2023-11-28 17:43:56'),(113,'查询',3,112,NULL,NULL,NULL,NULL,NULL,'ad',NULL,NULL,0,NULL,0,1,0,0,1,'2022-06-17 11:31:36',NULL,'2022-06-17 11:31:36'),(114,'运维工具',1,0,200,NULL,NULL,NULL,NULL,NULL,'NodeCollapseOutlined',NULL,0,NULL,0,1,0,1,1,'2022-06-20 10:09:16',1,'2023-12-01 19:36:18'),(117,'Reload',2,50,12,'/hook','/support/reload/reload-list.vue',NULL,NULL,NULL,'ReloadOutlined',NULL,0,NULL,0,1,0,0,1,'2022-06-20 10:16:49',1,'2023-12-01 19:39:17'),(122,'数据库监控',2,111,4,'/support/druid/index',NULL,NULL,NULL,NULL,'ConsoleSqlOutlined',NULL,1,'http://localhost:1024/druid',1,1,0,0,1,'2022-06-20 14:49:33',1,'2023-02-16 19:15:58'),(130,'单号管理',2,50,6,'/support/serial-number/serial-number-list','/support/serial-number/serial-number-list.vue',NULL,NULL,NULL,'NumberOutlined',NULL,0,NULL,0,1,0,0,1,'2022-06-24 14:45:22',1,'2022-06-28 16:23:41'),(132,'公告管理',2,138,2,'/oa/notice/notice-list','/business/oa/notice/notice-list.vue',NULL,NULL,NULL,'SoundOutlined',NULL,0,NULL,1,1,0,0,1,'2022-06-24 18:23:09',1,'2024-07-08 13:58:51'),(133,'缓存管理',2,50,11,'/support/cache/cache-list','/support/cache/cache-list.vue',NULL,NULL,NULL,'BorderInnerOutlined',NULL,0,NULL,0,1,0,0,1,'2022-06-24 18:52:25',1,'2023-12-01 19:39:13'),(138,'功能Demo',1,0,1,NULL,NULL,NULL,NULL,NULL,'BankOutlined',NULL,0,NULL,0,1,0,0,1,'2022-06-24 20:09:18',1,'2024-07-08 13:46:54'),(142,'公告详情',2,132,NULL,'/oa/notice/notice-detail','/business/oa/notice/notice-detail.vue',NULL,NULL,NULL,NULL,NULL,0,NULL,0,0,0,0,1,'2022-06-25 16:38:47',1,'2022-09-14 19:46:17'),(143,'登录登出记录',2,213,5,'/support/login-log/login-log-list','/support/login-log/login-log-list.vue',NULL,NULL,NULL,'LoginOutlined',NULL,0,NULL,0,1,0,0,1,'2022-06-28 15:01:38',44,'2024-08-13 14:33:49'),(144,'企业管理',2,138,1,'/oa/enterprise/enterprise-list','/business/oa/enterprise/enterprise-list.vue',NULL,NULL,NULL,'ShopOutlined',NULL,0,NULL,0,1,0,0,1,'2022-09-14 17:00:07',1,'2024-07-08 13:48:24'),(145,'企业详情',2,138,NULL,'/oa/enterprise/enterprise-detail','/business/oa/enterprise/enterprise-detail.vue',NULL,NULL,NULL,NULL,NULL,0,NULL,0,0,0,0,1,'2022-09-14 18:52:52',1,'2022-11-22 10:39:07'),(147,'帮助文档',2,218,1,'/help-doc/help-doc-manage-list','/support/help-doc/management/help-doc-manage-list.vue',NULL,NULL,NULL,'FolderViewOutlined',NULL,0,NULL,0,1,0,0,1,'2022-09-14 19:59:01',1,'2023-12-01 19:38:23'),(148,'意见反馈',2,218,2,'/feedback/feedback-list','/support/feedback/feedback-list.vue',NULL,NULL,NULL,'CoffeeOutlined',NULL,0,NULL,0,1,0,0,1,'2022-09-14 19:59:52',1,'2023-12-01 19:38:40'),(149,'我的通知',2,132,NULL,'/oa/notice/notice-employee-list','/business/oa/notice/notice-employee-list.vue',NULL,NULL,NULL,NULL,NULL,0,NULL,0,0,0,0,1,'2022-09-14 20:29:41',1,'2022-09-14 20:31:23'),(150,'我的通知公告详情',2,132,NULL,'/oa/notice/notice-employee-detail','/business/oa/notice/notice-employee-detail.vue',NULL,NULL,NULL,NULL,NULL,0,NULL,0,0,0,0,1,'2022-09-14 20:30:25',1,'2022-09-14 20:31:38'),(151,'代码生成',2,0,600,'/support/code-generator','/support/code-generator/code-generator-list.vue',NULL,NULL,NULL,'CoffeeOutlined',NULL,0,NULL,0,1,0,0,1,'2022-09-21 18:25:05',1,'2022-10-22 11:27:58'),(152,'更新日志',2,218,3,'/support/change-log/change-log-list','/support/change-log/change-log-list.vue',NULL,NULL,NULL,'HeartOutlined',NULL,0,NULL,0,1,0,0,44,'2022-10-10 10:31:20',1,'2023-12-01 19:38:51'),(153,'清除缓存',3,133,NULL,NULL,NULL,1,'support:cache:delete','support:cache:delete',NULL,133,0,NULL,0,1,1,0,1,'2022-10-15 22:45:13',1,'2023-10-07 16:22:29'),(154,'获取缓存key',3,133,NULL,NULL,NULL,1,'support:cache:keys','support:cache:keys',NULL,133,0,NULL,0,1,1,0,1,'2022-10-15 22:45:48',1,'2023-10-07 16:22:35'),(156,'查看结果',3,117,NULL,NULL,NULL,1,'support:reload:result','support:reload:result',NULL,117,0,NULL,0,1,0,0,1,'2022-10-15 23:17:23',1,'2023-10-07 14:31:47'),(157,'单号生成',3,130,NULL,NULL,NULL,1,'support:serialNumber:generate','support:serialNumber:generate',NULL,130,0,NULL,0,1,0,0,1,'2022-10-15 23:21:06',1,'2023-10-07 18:22:46'),(158,'生成记录',3,130,NULL,NULL,NULL,1,'support:serialNumber:record','support:serialNumber:record',NULL,130,0,NULL,0,1,0,0,1,'2022-10-15 23:21:34',1,'2023-10-07 18:22:55'),(159,'查询',3,110,NULL,NULL,NULL,1,'support:dict:query','support:dict:query',NULL,110,0,NULL,0,1,0,0,1,'2022-10-15 23:23:51',1,'2025-04-08 19:42:25'),(160,'添加',3,110,NULL,NULL,NULL,1,'support:dict:add','support:dict:add',NULL,110,0,NULL,0,1,0,0,1,'2022-10-15 23:24:05',1,'2025-04-08 19:43:02'),(161,'更新',3,110,NULL,NULL,NULL,1,'support:dict:update','support:dict:update',NULL,110,0,NULL,0,1,0,0,1,'2022-10-15 23:24:34',1,'2025-04-08 19:43:34'),(162,'删除',3,110,NULL,NULL,NULL,1,'support:dict:delete','support:dict:delete',NULL,110,0,NULL,0,1,0,0,1,'2022-10-15 23:24:55',1,'2025-04-08 19:43:52'),(163,'新建',3,109,NULL,NULL,NULL,1,'support:config:add','support:config:add',NULL,109,0,NULL,0,1,0,0,1,'2022-10-15 23:26:56',1,'2023-10-07 18:16:17'),(164,'编辑',3,109,NULL,NULL,NULL,1,'support:config:update','support:config:update',NULL,109,0,NULL,0,1,0,0,1,'2022-10-15 23:27:07',1,'2023-10-07 18:16:24'),(165,'查询',3,47,NULL,NULL,NULL,1,'goods:query','goods:query',NULL,47,0,NULL,0,1,0,0,1,'2022-10-16 19:55:39',1,'2023-10-07 13:58:28'),(166,'新建',3,47,NULL,NULL,NULL,1,'goods:add','goods:add',NULL,47,0,NULL,0,1,0,0,1,'2022-10-16 19:56:00',1,'2023-10-07 13:58:32'),(167,'批量删除',3,47,NULL,NULL,NULL,1,'goods:batchDelete','goods:batchDelete',NULL,47,0,NULL,0,1,0,0,1,'2022-10-16 19:56:15',1,'2023-10-07 13:58:35'),(168,'查询',3,147,11,NULL,NULL,1,'support:helpDoc:query','support:helpDoc:query',NULL,147,0,NULL,0,1,0,0,1,'2022-10-16 20:12:13',1,'2023-10-07 14:05:49'),(169,'新建',3,147,12,NULL,NULL,1,'support:helpDoc:add','support:helpDoc:add',NULL,147,0,NULL,0,1,0,0,1,'2022-10-16 20:12:37',1,'2023-10-07 14:05:56'),(170,'新建目录',3,147,1,NULL,NULL,1,'support:helpDocCatalog:addCategory','support:helpDocCatalog:addCategory',NULL,147,0,NULL,0,1,0,0,1,'2022-10-16 20:12:57',1,'2023-10-07 14:06:38'),(171,'修改目录',3,147,2,NULL,NULL,1,'support:helpDocCatalog:update','support:helpDocCatalog:update',NULL,147,0,NULL,0,1,0,0,1,'2022-10-16 20:13:46',1,'2023-10-07 14:06:49'),(173,'新建',3,78,NULL,NULL,NULL,1,'category:add','category:add',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:02',1,'2023-10-07 13:54:01'),(174,'查询',3,78,NULL,NULL,NULL,1,'category:tree','category:tree',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:22',1,'2023-10-07 13:54:33'),(175,'编辑',3,78,NULL,NULL,NULL,1,'category:update','category:update',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:38',1,'2023-10-07 13:54:18'),(176,'删除',3,78,NULL,NULL,NULL,1,'category:delete','category:delete',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:50',1,'2023-10-07 13:54:27'),(177,'新建',3,79,NULL,NULL,NULL,1,'category:add','custom:category:add',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:02',1,'2023-10-07 13:57:32'),(178,'查询',3,79,NULL,NULL,NULL,1,'category:tree','custom:category:tree',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:22',1,'2023-10-07 13:57:50'),(179,'编辑',3,79,NULL,NULL,NULL,1,'category:update','custom:category:update',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:38',1,'2023-10-07 13:58:02'),(180,'删除',3,79,NULL,NULL,NULL,1,'category:delete','custom:category:delete',NULL,78,0,NULL,0,1,0,0,1,'2022-10-16 20:17:50',1,'2023-10-07 13:58:12'),(181,'查询',3,144,NULL,NULL,NULL,1,'oa:enterprise:query','oa:enterprise:query',NULL,144,0,NULL,0,1,0,0,1,'2022-10-16 20:25:14',1,'2023-10-07 12:00:09'),(182,'新建',3,144,NULL,NULL,NULL,1,'oa:enterprise:add','oa:enterprise:add',NULL,144,0,NULL,0,1,0,0,1,'2022-10-16 20:25:25',1,'2023-10-07 12:00:17'),(183,'编辑',3,144,NULL,NULL,NULL,1,'oa:enterprise:update','oa:enterprise:update',NULL,144,0,NULL,0,1,0,0,1,'2022-10-16 20:25:36',1,'2023-10-07 12:00:38'),(184,'删除',3,144,NULL,NULL,NULL,1,'oa:enterprise:delete','oa:enterprise:delete',NULL,144,0,NULL,0,1,0,0,1,'2022-10-16 20:25:53',1,'2023-10-07 12:00:46'),(185,'查询',3,132,NULL,NULL,NULL,1,'oa:notice:query','oa:notice:query',NULL,132,0,NULL,0,1,0,0,1,'2022-10-16 20:26:38',1,'2023-10-07 11:43:01'),(186,'新建',3,132,NULL,NULL,NULL,1,'oa:notice:add','oa:notice:add',NULL,132,0,NULL,0,1,0,0,1,'2022-10-16 20:27:04',1,'2023-10-07 11:43:07'),(187,'编辑',3,132,NULL,NULL,NULL,1,'oa:notice:update','oa:notice:update',NULL,132,0,NULL,0,1,0,0,1,'2022-10-16 20:27:15',1,'2023-10-07 11:43:12'),(188,'删除',3,132,NULL,NULL,NULL,1,'oa:notice:delete','oa:notice:delete',NULL,132,0,NULL,0,1,0,0,1,'2022-10-16 20:27:23',1,'2023-10-07 11:43:18'),(190,'查询',3,152,NULL,NULL,NULL,1,'','support:changeLog:query',NULL,152,0,NULL,0,1,0,0,1,'2022-10-16 20:28:33',1,'2023-10-07 14:25:05'),(191,'新建',3,152,NULL,NULL,NULL,1,'support:changeLog:add','support:changeLog:add',NULL,152,0,NULL,0,1,0,0,1,'2022-10-16 20:28:46',1,'2023-10-07 14:24:15'),(192,'批量删除',3,152,NULL,NULL,NULL,1,'support:changeLog:batchDelete','support:changeLog:batchDelete',NULL,152,0,NULL,0,1,0,0,1,'2022-10-16 20:29:10',1,'2023-10-07 14:24:22'),(193,'文件管理',2,50,20,'/support/file/file-list','/support/file/file-list.vue',NULL,NULL,NULL,'FolderOpenOutlined',NULL,0,NULL,0,1,0,0,1,'2022-10-21 11:26:11',1,'2022-10-22 11:29:22'),(194,'删除',3,47,NULL,NULL,NULL,1,'goods:delete','goods:delete',NULL,47,0,NULL,0,1,0,0,1,'2022-10-21 20:00:12',1,'2023-10-07 13:58:39'),(195,'修改',3,47,NULL,NULL,NULL,1,'goods:update','goods:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 20:05:23',1,'2023-10-07 13:58:42'),(196,'查看详情',3,145,NULL,NULL,NULL,1,'oa:enterprise:detail','oa:enterprise:detail',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 20:16:47',1,'2023-10-07 11:48:59'),(198,'删除',3,152,NULL,NULL,NULL,1,'support:changeLog:delete','support:changeLog:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 20:42:34',1,'2023-10-07 14:24:32'),(199,'查询',3,109,NULL,NULL,NULL,1,'support:config:query','support:config:query',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 20:45:14',1,'2023-10-07 18:16:27'),(200,'查询',3,193,NULL,NULL,NULL,1,'support:file:query','support:file:query',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 20:47:23',1,'2023-10-07 18:24:43'),(201,'删除',3,147,14,NULL,NULL,1,'support:helpDoc:delete','support:helpDoc:delete',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 21:03:20',1,'2023-10-07 14:07:02'),(202,'更新',3,147,13,NULL,NULL,1,'support:helpDoc:update','support:helpDoc:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 21:03:32',1,'2023-10-07 14:06:56'),(203,'查询',3,143,NULL,NULL,NULL,1,'support:loginLog:query','support:loginLog:query',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-21 21:05:11',1,'2023-10-07 14:27:23'),(204,'查询',3,81,NULL,NULL,NULL,1,'support:operateLog:query','support:operateLog:query',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-22 10:33:31',1,'2023-10-07 14:27:56'),(205,'详情',3,81,NULL,NULL,NULL,1,'support:operateLog:detail','support:operateLog:detail',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-22 10:33:49',1,'2023-10-07 14:28:04'),(206,'心跳监控',2,111,1,'/support/heart-beat/heart-beat-list','/support/heart-beat/heart-beat-list.vue',1,NULL,NULL,'FallOutlined',NULL,0,NULL,0,1,0,0,1,'2022-10-22 10:47:03',1,'2022-10-22 18:32:52'),(207,'更新',3,152,NULL,NULL,NULL,1,'support:changeLog:update','support:changeLog:update',NULL,NULL,0,NULL,0,1,0,0,1,'2022-10-22 11:51:32',1,'2023-10-07 14:24:39'),(212,'查询',3,117,NULL,NULL,NULL,1,'support:reload:query','support:reload:query',NULL,NULL,0,NULL,1,1,1,0,1,'2023-10-07 14:31:36',NULL,'2023-10-07 14:31:36'),(213,'网络安全',1,0,5,NULL,NULL,1,NULL,NULL,'SafetyCertificateOutlined',NULL,0,NULL,1,1,0,0,1,'2023-10-17 19:03:08',1,'2023-12-01 19:38:00'),(214,'登录失败锁定',2,213,4,'/support/login-fail','/support/login-fail/login-fail-list.vue',1,NULL,NULL,'LockOutlined',NULL,0,NULL,1,1,0,0,1,'2023-10-17 19:04:24',44,'2024-08-13 14:16:26'),(215,'接口加解密',2,213,2,'/support/api-encrypt','/support/api-encrypt/api-encrypt-index.vue',1,NULL,NULL,'CodepenCircleOutlined',NULL,0,NULL,1,1,0,0,1,'2023-10-24 11:49:28',44,'2024-08-13 12:00:14'),(216,'导出',3,47,NULL,NULL,NULL,1,'goods:exportGoods','goods:exportGoods',NULL,NULL,0,NULL,1,1,0,0,1,'2023-12-01 19:34:03',NULL,'2023-12-01 19:34:03'),(217,'导入',3,47,3,NULL,NULL,1,'goods:importGoods','goods:importGoods',NULL,NULL,0,NULL,1,1,0,0,1,'2023-12-01 19:34:22',NULL,'2023-12-01 19:34:22'),(218,'文档中心',1,0,4,NULL,NULL,1,NULL,NULL,'FileSearchOutlined',NULL,0,NULL,1,1,0,0,1,'2023-12-01 19:37:28',1,'2023-12-01 19:37:51'),(219,'部门管理',2,45,1,'/organization/department','/system/department/department-list.vue',1,NULL,NULL,'ApartmentOutlined',NULL,0,NULL,0,1,0,0,1,'2024-06-22 16:40:21',1,'2024-07-02 20:15:17'),(221,'定时任务',2,50,25,'/job/list','/support/job/job-list.vue',1,NULL,NULL,'AppstoreOutlined',NULL,0,NULL,1,1,0,0,2,'2024-06-25 17:57:40',2,'2024-06-25 19:49:21'),(228,'职务管理',2,45,2,'/organization/position','/system/position/position-list.vue',1,NULL,NULL,'ApartmentOutlined',NULL,0,NULL,1,1,0,0,1,'2024-06-29 11:11:09',1,'2024-07-02 20:15:11'),(229,'查询任务',3,221,NULL,NULL,NULL,1,'support:job:query','support:job:query',NULL,221,0,NULL,1,1,0,0,2,'2024-06-29 11:14:15',2,'2024-06-29 11:15:00'),(230,'更新任务',3,221,NULL,NULL,NULL,1,'support:job:update','support:job:update',NULL,221,0,NULL,1,1,0,0,2,'2024-06-29 11:15:40',NULL,'2024-06-29 11:15:40'),(231,'执行任务',3,221,NULL,NULL,NULL,1,'support:job:execute','support:job:execute',NULL,221,0,NULL,1,1,0,0,2,'2024-06-29 11:16:03',NULL,'2024-06-29 11:16:03'),(232,'查询记录',3,221,NULL,NULL,NULL,1,'support:job:log:query','support:job:log:query',NULL,221,0,NULL,1,1,0,0,2,'2024-06-29 11:16:37',NULL,'2024-06-29 11:16:37'),(233,'knife4j文档',2,218,4,'/knife4j',NULL,1,NULL,NULL,'FileWordOutlined',NULL,1,'http://localhost:1024/doc.html',1,1,0,0,1,'2024-07-02 20:23:50',1,'2024-07-08 13:49:15'),(234,'swagger文档',2,218,5,'/swagger','http://localhost:1024/swagger-ui/index.html',1,NULL,NULL,'ApiOutlined',NULL,1,'http://localhost:1024/swagger-ui/index.html',1,1,0,0,1,'2024-07-02 20:35:43',1,'2024-07-08 13:49:26'),(250,'三级等保设置',2,213,1,'/support/level3protect/level3-protect-config-index','/support/level3protect/level3-protect-config-index.vue',1,NULL,NULL,'SafetyOutlined',NULL,0,NULL,1,1,0,0,44,'2024-08-13 11:41:02',44,'2024-08-13 11:58:12'),(251,'敏感数据脱敏',2,213,3,'/support/level3protect/data-masking-list','/support/level3protect/data-masking-list.vue',1,NULL,NULL,'FileProtectOutlined',NULL,0,NULL,1,1,0,0,44,'2024-08-13 11:58:00',44,'2024-08-13 11:59:49'),(252,'启用/禁用',3,110,NULL,NULL,NULL,1,'support:dict:updateDisabled','support:dict:updateDisabled',NULL,110,0,NULL,0,1,0,0,1,'2025-04-08 19:44:12',1,'2025-04-08 19:46:03'),(253,'查询字典数据',3,110,NULL,NULL,NULL,1,'support:dictData:query','support:dictData:query',NULL,110,0,NULL,0,1,0,0,1,'2025-04-08 19:46:47',NULL,'2025-04-08 19:46:47'),(254,'添加字典数据',3,110,NULL,NULL,NULL,1,'support:dictData:add','support:dictData:add',NULL,110,0,NULL,0,1,0,0,1,'2025-04-08 19:48:00',NULL,'2025-04-08 19:48:00'),(255,'更新字典数据',3,110,NULL,NULL,NULL,1,'support:dictData:update','support:dictData:update',NULL,110,0,NULL,0,1,0,0,1,'2025-04-08 19:48:19',NULL,'2025-04-08 19:48:19'),(256,'删除字典数据',3,110,NULL,NULL,NULL,1,'support:dictData:delete','support:dictData:delete',NULL,110,0,NULL,0,1,0,0,1,'2025-04-08 19:48:38',NULL,'2025-04-08 19:48:38'),(257,'启用/禁用字典数据',3,110,NULL,NULL,NULL,1,'support:dictData:updateDisabled','support:dictData:updateDisabled',NULL,110,0,NULL,0,1,0,0,1,'2025-04-08 19:48:57',NULL,'2025-04-08 19:48:57'),(258,'查询企业员工',3,145,NULL,NULL,NULL,1,'oa:enterprise:queryEmployee','oa:enterprise:queryEmployee',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:11:46',75,'2025-04-08 21:12:24'),(259,'查询银行信息',3,145,NULL,NULL,NULL,1,'oa:bank:query','oa:bank:query',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:12:40',NULL,'2025-04-08 21:12:40'),(260,'查询发票信息',3,145,NULL,NULL,NULL,1,'oa:invoice:query','oa:invoice:query',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:12:56',NULL,'2025-04-08 21:12:56'),(261,'添加企业员工',3,145,NULL,NULL,NULL,1,'oa:enterprise:addEmployee','oa:enterprise:addEmployee',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:35:34',NULL,'2025-04-08 21:35:34'),(262,'删除企业员工',3,145,NULL,NULL,NULL,1,'oa:enterprise:deleteEmployee','oa:enterprise:deleteEmployee',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:40:17',NULL,'2025-04-08 21:40:17'),(263,'添加银行信息',3,145,NULL,NULL,NULL,1,'oa:bank:add','oa:bank:add',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:45:44',NULL,'2025-04-08 21:45:44'),(264,'更新银行信息',3,145,NULL,NULL,NULL,1,'oa:bank:update','oa:bank:update',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:46:02',NULL,'2025-04-08 21:46:02'),(265,'删除银行信息',3,145,NULL,NULL,NULL,1,'oa:bank:delete','oa:bank:delete',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:46:12',NULL,'2025-04-08 21:46:12'),(266,'添加发票信息',3,145,NULL,NULL,NULL,1,'oa:invoice:add','oa:invoice:add',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:46:30',NULL,'2025-04-08 21:46:30'),(267,'更新发票信息',3,145,NULL,NULL,NULL,1,'oa:invoice:update','oa:invoice:update',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:46:47',NULL,'2025-04-08 21:46:47'),(268,'删除发票信息',3,145,NULL,NULL,NULL,1,'oa:invoice:delete','oa:invoice:delete',NULL,145,0,NULL,0,1,0,0,75,'2025-04-08 21:46:59',NULL,'2025-04-08 21:46:59'),(300,'消息管理',2,50,30,'/message','/support/message/message-list.vue',1,NULL,NULL,'MailOutlined',NULL,0,NULL,0,1,0,0,1,'2025-04-09 14:30:04',1,'2025-04-10 20:19:36');
/*!40000 ALTER TABLE `t_menu` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_message`
--

DROP TABLE IF EXISTS `t_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_message` (
  `message_id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息id',
  `message_type` smallint NOT NULL COMMENT '消息类型',
  `receiver_user_type` int NOT NULL COMMENT '接收者用户类型',
  `receiver_user_id` bigint NOT NULL COMMENT '接收者用户id',
  `data_id` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '相关数据id',
  `title` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '内容',
  `read_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已读',
  `read_time` datetime DEFAULT NULL COMMENT '已读时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`message_id`) USING BTREE,
  KEY `idx_msg` (`message_type`,`receiver_user_type`,`receiver_user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知消息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_message`
--

LOCK TABLES `t_message` WRITE;
/*!40000 ALTER TABLE `t_message` DISABLE KEYS */;
INSERT INTO `t_message` VALUES (1,1,1,1,'null','张三的对公付款单 【3000元】','尊敬的各位技术大佬：\r\n\r\n1024创新实验室技术分享即将隆重举行\r\n\r\n现将有关会议事宜通知如下：\r\n\r\n一、会议内容\r\n\r\n1、研究探讨SmartAdmin的技术体系\r\n\r\n二、会议形式\r\n\r\n大会专题小会分组讨论;\r\n\r\n三、会议时间及地点\r\n\r\n会议报到时间：xxx1年6月14日\r\n\r\n会议报到地点：洛阳市',0,'2024-09-02 23:00:54','2024-06-27 01:14:07','2024-09-03 20:44:19'),(2,2,1,1,'234','刘备的请假单【本周四】','尊敬的各位技术大佬：\r\n\r\n1024创新实验室技术分享即将隆重举行\r\n\r\n现将有关会议事宜通知如下：\r\n\r\n一、会议内容\r\n\r\n1、研究探讨SmartAdmin的技术体系\r\n\r\n二、会议形式\r\n\r\n大会专题小会分组讨论;\r\n\r\n三、会议时间及地点\r\n\r\n会议报到时间：xxx1年6月14日\r\n\r\n会议报到地点：洛阳市',0,'2024-09-02 23:00:50','2024-07-04 16:09:49','2024-09-03 20:44:20'),(3,1,1,1,'23','武松的物资采购单【Macbook Pro】','尊敬的各位技术大佬：\r\n\r\n1024创新实验室技术分享即将隆重举行\r\n\r\n现将有关会议事宜通知如下：\r\n\r\n一、会议内容\r\n\r\n1、研究探讨SmartAdmin的技术体系\r\n\r\n二、会议形式\r\n\r\n大会专题小会分组讨论;\r\n\r\n三、会议时间及地点\r\n\r\n会议报到时间：xxx1年6月14日\r\n\r\n会议报到地点：洛阳市',0,'2024-09-02 23:00:36','2024-07-07 22:03:14','2024-09-03 20:44:21'),(4,1,1,1,'23','孙悟空的出差申请【出差洛阳】','尊敬的各位技术大佬：\r\n\r\n1024创新实验室技术分享即将隆重举行\r\n\r\n现将有关会议事宜通知如下：\r\n\r\n一、会议内容\r\n\r\n1、研究探讨SmartAdmin的技术体系\r\n\r\n二、会议形式\r\n\r\n大会专题小会分组讨论;\r\n\r\n三、会议时间及地点\r\n\r\n会议报到时间：xxx1年6月14日\r\n\r\n会议报到地点：洛阳市',0,'2024-09-02 23:02:53','2024-07-07 22:03:14','2024-09-03 21:43:53');
/*!40000 ALTER TABLE `t_message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_notice`
--

DROP TABLE IF EXISTS `t_notice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_notice` (
  `notice_id` bigint NOT NULL AUTO_INCREMENT,
  `notice_type_id` bigint NOT NULL COMMENT '类型1公告 2动态',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '标题',
  `all_visible_flag` tinyint(1) NOT NULL COMMENT '是否全部可见',
  `scheduled_publish_flag` tinyint(1) NOT NULL COMMENT '是否定时发布',
  `publish_time` datetime NOT NULL COMMENT '发布时间',
  `content_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文本内容',
  `content_html` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'html内容',
  `attachment` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '附件',
  `page_view_count` int NOT NULL DEFAULT '0' COMMENT '页面浏览量，传说中的pv',
  `user_view_count` int NOT NULL DEFAULT '0' COMMENT '用户浏览量，传说中的uv',
  `source` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '来源',
  `author` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '作者',
  `document_number` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '文号，如：1024创新实验室发〔2022〕字第36号',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0',
  `create_user_id` bigint DEFAULT NULL COMMENT '创建人',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notice_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_notice`
--

LOCK TABLES `t_notice` WRITE;
/*!40000 ALTER TABLE `t_notice` DISABLE KEYS */;
INSERT INTO `t_notice` VALUES (49,1,'Spring Boot 3.0.0 首个 RC 发布',1,0,'2024-01-01 20:22:23','Spring Boot 3.0.0 首个 RC 发布\nSpring Boot 3.0 首个 RC 已发布，此外还为两个分支发布了更新：2.7.5 & 2.6.13。\n3.0.0-RC1\n发布公告写道，此版本包含 135 项功能增强、文档改进、依赖升级和 Bugfix。\nSpring Boot 3.0 的开发工作始于实验性的 Spring Native，旨在为 GraalVM 原生镜像提供支持。在该版本中，开发者现在可以使用标准 Spring Boot Maven 或 Gradle 插件将 Spring Boot 应用程序转换为原生可执行文件，而无需任何特殊配置。\n此版本还在参考文档中添加新内容来解释 AOT 处理背后的概念以及如何开始生成第一个 GraalVM 原生镜像。\n除此之外，Spring Boot 3.0 还完成了迁移到 JakartaEE 9 的工作，以及将使用的 Java 版本升级到 Java 17。\n其他新特性：\n为 Spring Data JDBC 提供更灵活的自动配置为 Prometheus 示例提供自动配置增强 Log4j2 功能，包括配置文件支持和环境属性查找\n详情查看 Release Note。\nSpring Boot 2.7.5 和 2.6.13 的更新内容主要是修复错误，优化文档和升级依赖，详情查看 Release Note (2.7.5、2.6.13)。\n相关链接\nSpring Boot 的详细介绍：点击查看Spring Boot 的下载地址：点击下载','<h1 style=\"text-indent: 0px; text-align: start;\"><a href=\"https://www.oschina.net/news/214401/spring-boot-3-0-0-rc1-released\" target=\"_blank\">Spring&nbsp;Boot&nbsp;3.0.0&nbsp;首个&nbsp;RC&nbsp;发布</a></h1><p>Spring&nbsp;Boot&nbsp;3.0 首个&nbsp;RC 已发布，此外还为两个分支发布了更新：2.7.5 & 2.6.13。</p><p>3.0.0-RC1</p><p>发布公告写道，此版本包含 135&nbsp;项功能增强、文档改进、依赖升级和&nbsp;Bugfix。</p><p>Spring&nbsp;Boot&nbsp;3.0&nbsp;的开发工作始于实验性的&nbsp;Spring&nbsp;Native，旨在为&nbsp;GraalVM&nbsp;原生镜像提供支持。在该版本中，开发者现在可以使用标准&nbsp;Spring&nbsp;Boot&nbsp;Maven&nbsp;或&nbsp;Gradle&nbsp;插件将&nbsp;Spring&nbsp;Boot&nbsp;应用程序转换为原生可执行文件，而无需任何特殊配置。</p><p>此版本还在参考文档中添加新内容来解释 AOT&nbsp;处理背后的概念以及如何开始生成第一个&nbsp;GraalVM&nbsp;原生镜像。</p><p>除此之外，Spring&nbsp;Boot&nbsp;3.0&nbsp;还完成了迁移到 JakartaEE&nbsp;9&nbsp;的工作，以及将使用的&nbsp;Java&nbsp;版本升级到&nbsp;Java&nbsp;17。</p><p>其他新特性：</p><p>为&nbsp;Spring&nbsp;Data&nbsp;JDBC&nbsp;提供更灵活的自动配置为&nbsp;Prometheus&nbsp;示例提供自动配置增强&nbsp;Log4j2&nbsp;功能，包括配置文件支持和环境属性查找</p><p>详情查看&nbsp;Release&nbsp;Note。</p><p>Spring&nbsp;Boot&nbsp;2.7.5&nbsp;和&nbsp;2.6.13&nbsp;的更新内容主要是修复错误，优化文档和升级依赖，详情查看&nbsp;Release&nbsp;Note&nbsp;(2.7.5、2.6.13)。</p><p>相关链接</p><p>Spring&nbsp;Boot&nbsp;的详细介绍：点击查看Spring&nbsp;Boot&nbsp;的下载地址：点击下载</p>','',0,0,'开源中国','卓大',NULL,0,1,'2024-03-02 18:53:26','2022-10-22 14:27:33'),(50,1,'Oracle 推出 JDK 8 的直接替代品',1,0,'2024-01-01 20:22:23','Oracle 推出 JDK 8 的直接替代品\n来源: OSCHINA\n编辑: 白开水不加糖\n2022-10-20 08:14:29\n 0\n为了向传统的 Java 8 服务器工作负载提供 Java 17 级别的性能，Oracle 宣布推出 Java SE Subscription Enterprise Performance Pack (Enterprise Performance Pack)。并声称这是 JDK 8 的直接替代品，现已在 MyOracleSupport 上面向所有 Java SE 订阅客户和 Oracle 云基础设施 (OCI) 用户免费提供。\n“Enterprise Performance Pack 为 JDK 8 用户提供了在 JDK 8 和 JDK 17 发布之间的 7 年时间里，为 Java 带来的重大内存管理和性能改进。这些改进包括：现代垃圾回收算法、紧凑字符串、增强的可观察性和数十种其他优化。”\nJava 8 发布于 2014 年，和 Java 17 一样都是长期支持 (LTS) 版本；尽管发布距今已有近九年的历史，但仍被很多开发人员和组织所广泛应用。New Relic 发布的一份 “2022 年 Java 生态系统状况报告” 数据表明，Java 8 仍被 46.45% 的 Java 应用程序在生产中使用。\n根据介绍，Enterprise Performance Pack 在 Intel 和基于 Arm 的系统（如 Ampere Altra）上支持 headless Linux 64 位工作负载。\nOracle 方面称，使用 Enterprise Performance Pack 的客户将可以立即看到以或接近内存或 CPU 容量运行的 JDK 8 工作负载的好处。在 Oracle 自己的产品和云服务进行的测试表明，高负载应用程序的内存和性能都提高了大约 40%。即使没有接近容量运行的 JDK 8 应用程序，也可以会看到高达 5% 的性能提升。\n虽然 Enterprise Performance Pack 中包含的许多改进可以通过默认选项获得，但 Oracle 建议用户还是自己研究文档，以最大限度地提高性能并最大限度地降低内存使用率。例如，通过启用可扩展的低延迟 ZGC 垃圾收集器来提高应用程序响应能力，需要通过 -XX:+UseZGC 选项。','<h3>Oracle&nbsp;推出&nbsp;JDK&nbsp;8&nbsp;的直接替代品</h3><p>来源:&nbsp;OSCHINA</p><p>编辑: 白开水不加糖</p><p>2022-10-20&nbsp;08:14:29</p><p> 0</p><p>为了向传统的&nbsp;Java&nbsp;8&nbsp;服务器工作负载提供&nbsp;Java&nbsp;17&nbsp;级别的性能，Oracle 宣布推出&nbsp;Java&nbsp;SE&nbsp;Subscription&nbsp;Enterprise&nbsp;Performance&nbsp;Pack&nbsp;(Enterprise&nbsp;Performance&nbsp;Pack)。并声称这是 JDK&nbsp;8&nbsp;的直接替代品，现已在 MyOracleSupport 上面向所有&nbsp;Java&nbsp;SE&nbsp;订阅客户和&nbsp;Oracle&nbsp;云基础设施&nbsp;(OCI)&nbsp;用户免费提供。</p><p>“Enterprise&nbsp;Performance&nbsp;Pack&nbsp;为&nbsp;JDK&nbsp;8&nbsp;用户提供了在&nbsp;JDK&nbsp;8&nbsp;和&nbsp;JDK&nbsp;17&nbsp;发布之间的&nbsp;7&nbsp;年时间里，为&nbsp;Java&nbsp;带来的重大内存管理和性能改进。这些改进包括：现代垃圾回收算法、紧凑字符串、增强的可观察性和数十种其他优化。”</p><p>Java&nbsp;8&nbsp;发布于&nbsp;2014&nbsp;年，和&nbsp;Java&nbsp;17&nbsp;一样都是长期支持&nbsp;(LTS)&nbsp;版本；尽管发布距今已有近九年的历史，但仍被很多开发人员和组织所广泛应用。New&nbsp;Relic&nbsp;发布的一份 “2022&nbsp;年&nbsp;Java&nbsp;生态系统状况报告”&nbsp;数据表明，Java&nbsp;8&nbsp;仍被&nbsp;46.45%&nbsp;的&nbsp;Java&nbsp;应用程序在生产中使用。</p><p>根据介绍，Enterprise&nbsp;Performance&nbsp;Pack&nbsp;在&nbsp;Intel&nbsp;和基于&nbsp;Arm&nbsp;的系统（如&nbsp;Ampere&nbsp;Altra）上支持 headless&nbsp;Linux&nbsp;64&nbsp;位工作负载。</p><p>Oracle 方面称，使用&nbsp;Enterprise&nbsp;Performance&nbsp;Pack&nbsp;的客户将可以立即看到以或接近内存或&nbsp;CPU&nbsp;容量运行的&nbsp;JDK&nbsp;8&nbsp;工作负载的好处。在&nbsp;Oracle&nbsp;自己的产品和云服务进行的测试表明，高负载应用程序的内存和性能都提高了大约&nbsp;40%。即使没有接近容量运行的&nbsp;JDK&nbsp;8&nbsp;应用程序，也可以会看到高达&nbsp;5%&nbsp;的性能提升。</p><p>虽然&nbsp;Enterprise&nbsp;Performance&nbsp;Pack&nbsp;中包含的许多改进可以通过默认选项获得，但 Oracle 建议用户还是自己研究文档，以最大限度地提高性能并最大限度地降低内存使用率。例如，通过启用可扩展的低延迟&nbsp;ZGC&nbsp;垃圾收集器来提高应用程序响应能力，需要通过&nbsp;-XX:+UseZGC&nbsp;选项。</p>','',0,0,'OSChina','卓大',NULL,0,1,'2024-01-08 19:02:12','2022-10-22 14:29:56'),(51,1,'Spring Framework 6.0.0 RC2 发布',1,0,'2024-01-01 20:22:23','Spring Framework 6.0.0 RC2 发布\nSpring Framework 6.0.0 发布了第二个 RC 版本。\n新特性\n确保可以在构建时评估 classpath 检查 #29352为 JPA 持久化回调引入 Register 反射提示 #29348检查 @RegisterReflectionForBinding 是否至少指定一个类 #29346为 AOT 引擎设置引入 builder API #29341支持检测正在进行的 AOT 处理 #29340重新组织 HTTP Observation 类型 #29334支持在没有 java.beans.Introspector 的前提下，执行基本属性判断 #29320为BindingReflectionHintsRegistrar 添加 Kotlin 数据类组件支持 #29316将 HttpServiceFactory 和 RSocketServiceProxyFactory 切换到 builder 模型，以便优先进行可编程配置 #29296引入基于 GraalVM FieldValueTransformer API 的 PreComputeFieldFeature#29081在 TestContext 框架中引入 SPI 来处理 ApplicationContext 故障 #28826SimpleEvaluationContext 支持禁用 array 分配 #28808DateTimeFormatterRegistrar 支持默认回退到 ISO 解析 #26985\nSpring Framework 6.0 作为重大更新，要求使用 Java 17 或更高版本，并且已迁移到 Jakarta EE 9+（在 jakarta 命名空间中取代了以前基于 javax 的 EE API），以及对其他基础设施的修改。基于这些变化，Spring Framework 6.0 支持最新 Web 容器，如 Tomcat 10 / Jetty 11，以及最新的持久性框架 Hibernate ORM 6.1。这些特性仅可用于 Servlet API 和 JPA 的 jakarta 命名空间变体。\n值得一提的是，开发者可通过此版本在基于 Spring 的应用中体验 “虚拟线程”（JDK 19 中的预览版 “Project Loom”），查看此文章了解更多细节。现在提供了自定义选项来插入基于虚拟线程的 Executor 实现，目标是在 Project Loom 正式可用时提供 “一等公民” 的配置选项。\n除了上述的变化，Spring Framework 6.0 还包含许多其他改进和特性，例如：\n提供基于 @HttpExchange 服务接口的 HTTP 接口客户端对 RFC 7807 问题详细信息的支持Spring HTTP 客户端提供基于 Micrometer 的可观察性……\n详情查看 Release Note。\n按照发布计划，Spring Framework 6.0 将于 11 月正式 GA。','<h1 style=\"text-indent: 0px; text-align: start;\"><a href=\"https://www.oschina.net/news/214472/spring-framework-6-0-0-rc2-released\" target=\"_blank\">Spring&nbsp;Framework&nbsp;6.0.0&nbsp;RC2&nbsp;发布</a></h1><p style=\"text-indent: 0px; text-align: left;\">Spring&nbsp;Framework&nbsp;6.0.0&nbsp;发布了<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fspring.io%2Fblog%2F2022%2F10%2F20%2Fspring-framework-6-0-0-rc2-available-now\" target=\"_blank\">第二个&nbsp;RC&nbsp;版本</a>。</p><p style=\"text-indent: 0px; text-align: left;\"><strong>新特性</strong></p><ul style=\"text-indent: 0px; text-align: left;\"><li>确保可以在构建时评估&nbsp;classpath&nbsp;检查&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29352\" target=\"_blank\">#29352</a></li><li>为&nbsp;JPA&nbsp;持久化回调引入&nbsp;Register&nbsp;反射提示&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29348\" target=\"_blank\">#29348</a></li><li>检查&nbsp;<span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>@RegisterReflectionForBinding</code></span>&nbsp;是否至少指定一个类&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29346\" target=\"_blank\">#29346</a></li><li>为&nbsp;AOT&nbsp;引擎设置引入&nbsp;builder&nbsp;API&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29341\" target=\"_blank\">#29341</a></li><li>支持检测正在进行的&nbsp;AOT&nbsp;处理&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29340\" target=\"_blank\">#29340</a></li><li>重新组织&nbsp;HTTP&nbsp;Observation&nbsp;类型&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29334\" target=\"_blank\">#29334</a></li><li>支持在没有&nbsp;java.beans.Introspector&nbsp;的前提下，执行基本属性判断&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29320\" target=\"_blank\">#29320</a></li><li>为<span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>BindingReflectionHintsRegistrar</code></span>&nbsp;添加&nbsp;Kotlin&nbsp;数据类组件支持&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29316\" target=\"_blank\">#29316</a></li><li>将&nbsp;HttpServiceFactory&nbsp;和&nbsp;RSocketServiceProxyFactory&nbsp;切换到&nbsp;builder&nbsp;模型，以便优先进行可编程配置&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29296\" target=\"_blank\">#29296</a></li><li>引入基于&nbsp;GraalVM&nbsp;<span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>FieldValueTransformer</code></span>&nbsp;API&nbsp;的&nbsp;<span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>PreComputeFieldFeature</code></span><a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F29081\" target=\"_blank\">#29081</a></li><li>在&nbsp;TestContext&nbsp;框架中引入&nbsp;SPI&nbsp;来处理&nbsp;ApplicationContext&nbsp;故障&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F28826\" target=\"_blank\">#28826</a></li><li>SimpleEvaluationContext&nbsp;支持禁用&nbsp;array&nbsp;分配&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F28808\" target=\"_blank\">#28808</a></li><li>DateTimeFormatterRegistrar&nbsp;支持默认回退到&nbsp;ISO&nbsp;解析&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Fissues%2F26985\" target=\"_blank\">#26985</a></li></ul><p style=\"text-indent: 0px; text-align: left;\"><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">Spring&nbsp;Framework&nbsp;6.0&nbsp;作为重大更新，要求</span><span style=\"color: rgb(51, 51, 51);\"><strong>使用&nbsp;Java&nbsp;17&nbsp;或更高版本</strong></span><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">，并且已迁移到&nbsp;Jakarta&nbsp;EE&nbsp;9+（在&nbsp;</span><span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>jakarta</code></span><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">&nbsp;命名空间中取代了以前基于&nbsp;</span><span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>javax</code></span><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">&nbsp;的&nbsp;EE&nbsp;API），以及对其他基础设施的修改。基于这些变化，Spring&nbsp;Framework&nbsp;6.0&nbsp;支持最新&nbsp;Web&nbsp;容器，如&nbsp;</span><a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Ftomcat.apache.org%2Fwhichversion.html\" target=\"_blank\">Tomcat&nbsp;10</a><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">&nbsp;/&nbsp;</span><a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fwww.eclipse.org%2Fjetty%2Fdownload.php\" target=\"_blank\">Jetty&nbsp;11</a><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">，以及最新的持久性框架&nbsp;</span><a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fhibernate.org%2Form%2Freleases%2F6.1%2F\" target=\"_blank\">Hibernate&nbsp;ORM&nbsp;6.1</a><span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">。这些特性仅可用于&nbsp;Servlet&nbsp;API&nbsp;和&nbsp;JPA&nbsp;的&nbsp;jakarta&nbsp;命名空间变体。</span></p><p style=\"text-indent: 0px; text-align: left;\">值得一提的是，开发者可通过此版本在基于&nbsp;Spring&nbsp;的应用中体验&nbsp;“虚拟线程”（JDK&nbsp;19&nbsp;中的预览版&nbsp;“Project&nbsp;Loom”），<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fspring.io%2Fblog%2F2022%2F10%2F11%2Fembracing-virtual-threads\" target=\"_blank\">查看此文章</a>了解更多细节。现在提供了自定义选项来插入基于虚拟线程的&nbsp;<span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>Executor</code></span>&nbsp;实现，目标是在&nbsp;Project&nbsp;Loom&nbsp;正式可用时提供&nbsp;“一等公民”&nbsp;的配置选项。</p><p style=\"text-indent: 0px; text-align: left;\">除了上述的变化，Spring&nbsp;Framework&nbsp;6.0&nbsp;还包含许多其他改进和特性，例如：</p><ul style=\"text-indent: 0px; text-align: left;\"><li>提供基于&nbsp;<span style=\"color: rgb(51, 51, 51); font-size: 13px;\"><code>@HttpExchange</code></span>&nbsp;服务接口的&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fdocs.spring.io%2Fspring-framework%2Fdocs%2F6.0.0-RC1%2Freference%2Fhtml%2Fintegration.html%23rest-http-interface\" target=\"_blank\">HTTP&nbsp;接口客户端</a></li><li>对&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fdocs.spring.io%2Fspring-framework%2Fdocs%2F6.0.0-RC1%2Freference%2Fhtml%2Fweb.html%23mvc-ann-rest-exceptions\" target=\"_blank\">RFC&nbsp;7807&nbsp;问题详细信息</a>的支持</li><li>Spring&nbsp;HTTP&nbsp;客户端提供基于&nbsp;Micrometer&nbsp;的可观察性</li><li>……</li></ul><p style=\"text-indent: 0px; text-align: left;\"><a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fspring-projects%2Fspring-framework%2Freleases%2Ftag%2Fv6.0.0-RC2\" target=\"_blank\">详情查看&nbsp;Release&nbsp;Note</a>。</p><p style=\"text-indent: 0px; text-align: left;\">按照发布计划，Spring&nbsp;Framework&nbsp;6.0&nbsp;将于&nbsp;11&nbsp;月正式&nbsp;GA。</p>','',0,0,'CSDN','罗伊',NULL,0,1,'2024-01-08 19:02:12','2022-10-22 14:30:45'),(52,1,'Windows Terminal 正式成为 Windows 11 默认终端',1,0,'2024-01-01 20:22:23','今年 7 月 ，微软在 Windows 11 的 Beta 版本测试了将系统默认终端设置为 Windows Terminal 。如今该设置已登录稳定版本，从 Windows 11 22H2 版本开始，Windows Terminal 将正式成为 Windows 11 的默认设置。\n默认终端是在打开命令行应用程序时默认启动的终端模拟器。从 Windows 诞生之日起，其默认终端一直是 Windows 控制台主机 conhost.exe。此次更新则意味着，以后 Windows 11 的所有命令行应用程序都将在 Windows Terminal 中自动打开。\nWindows Terminal 拥有非常多现代化的功能，毕竟它很新（ 2019 年 5 月在 Microsoft Build 上首次发布），吸取了很多现代终端的灵感。它支持多选项卡和窗格、命令面板等现代化的 UI 和操作方式，以及大量的自定义选项，比如目录、配置文件图标、自定义背景图像、配色方案、字体和透明度。\n当然，如果不想用 Windows Terminal，用户也可以在 Windows 设置中的 隐私和安全 > 开发人员页面和 Windows 终端设置 中调整默认终端设置，（此更新使用 “让 Windows 决定” 作为默认选择，即默认采用 Windows Terminal） 。\n此外，如果在更新之前就已设置其他默认终端，此次更新不会覆盖你的偏好。\n关于 Windows 11 默认终端的更多详情可查看微软博客。','<p style=\"text-indent: 0px; text-align: left;\">今年&nbsp;7&nbsp;月&nbsp;，微软在&nbsp;Windows&nbsp;11&nbsp;的&nbsp;Beta&nbsp;版本<a href=\"https://www.oschina.net/news/204429/wt-default-terminal-in-win11-beta-channel\" target=\"\">测试</a>了将系统默认终端设置为&nbsp;Windows&nbsp;Terminal&nbsp;。如今该设置已登录稳定版本，从&nbsp;Windows&nbsp;11&nbsp;22H2&nbsp;版本开始，Windows&nbsp;Terminal&nbsp;将<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fdevblogs.microsoft.com%2Fcommandline%2Fwindows-terminal-is-now-the-default-in-windows-11%2F\" target=\"_blank\">正式成为</a>&nbsp;Windows&nbsp;11&nbsp;的默认设置。</p><p style=\"text-indent: 0px; text-align: left;\">默认终端是在打开命令行应用程序时默认启动的终端模拟器。从&nbsp;Windows&nbsp;诞生之日起，其默认终端一直是&nbsp;Windows&nbsp;控制台主机&nbsp;conhost.exe。此次更新则意味着，以后&nbsp;Windows&nbsp;11&nbsp;的所有命令行应用程序都将在&nbsp;Windows&nbsp;Terminal&nbsp;中自动打开。</p><p style=\"text-indent: 0px; text-align: left;\">Windows&nbsp;Terminal&nbsp;拥有非常多现代化的功能，毕竟它<span style=\"color: rgb(51, 51, 51); background-color: rgb(255, 255, 255);\">很新（&nbsp;2019&nbsp;年&nbsp;5&nbsp;月在&nbsp;Microsoft&nbsp;Build&nbsp;上首次发布），吸取了很多现代终端的灵感。它支持多</span>选项卡和窗格、命令面板等现代化的&nbsp;UI&nbsp;和操作方式，以及大量的自定义选项，比如目录、配置文件图标、自定义背景图像、配色方案、字体和透明度。</p><p style=\"text-indent: 0px; text-align: left;\">当然，如果不想用&nbsp;Windows&nbsp;Terminal，用户也可以在&nbsp;Windows&nbsp;设置中的&nbsp;<em>隐私和安全&nbsp;&gt;&nbsp;开发人员页面和&nbsp;Windows&nbsp;终端设置&nbsp;</em>中调整默认终端设置，（此更新使用&nbsp;“让&nbsp;Windows&nbsp;决定”&nbsp;作为默认选择，即默认采用&nbsp;Windows&nbsp;Terminal）&nbsp;。</p><p style=\"text-indent: 0px; text-align: left;\">此外，如果在更新之前就已设置其他默认终端，此次更新<strong>不会覆盖</strong>你的偏好。</p><p style=\"text-indent: 0px; text-align: left;\">关于&nbsp;Windows&nbsp;11&nbsp;默认终端的更多详情可查看<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fdevblogs.microsoft.com%2Fcommandline%2Fwindows-terminal-is-now-the-default-in-windows-11%2F\" target=\"_blank\">微软博客</a>。</p>','',0,0,'开源中国','善逸',NULL,0,1,'2024-01-08 19:02:12','2022-10-22 14:33:03'),(53,1,'TypeScript 诞生 10 周年',1,0,'2024-01-01 20:22:23','TypeScript 已经诞生 10 年了。10 年前 ——2012 年 10 月 1 日，TypeScript 首次公开亮相。当时主导 TypeScript 开发的 Anders Hejlsberg 这样描述 TypeScript：\n它是 JavaScript 的类型化超集，可被编译成常用的 JavaScript。TypeScript 还可以通过启用丰富的工具体验来极大地帮助提升生产力，与此同时开发者保持不变维护现有的代码，并继续使用喜爱的 JavaScript 库。TypeScript is a typed superset of JavaScript that compiles to idiomatic (normal) JavaScript, can dramatically improve your productivity by enabling rich tooling experiences, all while maintaining your existing code and continuing to use the same JavaScript libraries you already love.\n微软在博客中回顾了 TypeScript 刚亮相时受到的评价，大多数人对它都是持怀疑态度，毕竟这对于许多 JavaScript 开发者来说，试图将静态类型引入 JavaScript 是一个笑话 —— 或是邪恶的阴谋。反对者则直言这是十分愚蠢的想法，他们认为当时已存在可以编译为 JavaScript 的强类型语言，例如 C#、Java 和 C++。他们还吐槽主导 TypeScript 开发的 Anders Hejlsberg 对静态类型有 “迷之执着”。\n当时微软意识到 JavaScript 未来将会被应用到无数场景，而且他们公司内部团队在处理复杂的 JavaScript 代码库时面临着巨大的挑战，所以他们觉得有必要创造强大的工具来帮助编写 JavaScript—— 尤其是针对大型 JavaScript 项目。基于此需求，TypeScript 也确定了自己的定位和特性，它是 JavaScript 的超集，将类型检查和静态分析、显式接口和最佳实践结合到单一语言和编译器中。通过在 JavaScript 上构建，TypeScript 能够更接近目标运行时，同时仅添加支持大型应用程序和大型团队所需的语法糖。\n团队还坚持 TypeScript 要能够与现有的 JavaScript 无缝交互，与 JavaScript 共同进化，并且看上去也和 JavaScript 类似。\nTypeScript 诞生之初的部分设计目标：\n不会对已有的程序增加运行时开销与当前和未来的 ECMAScript 提案保持一致保留所有 JavaScript 代码的运行时行为避免添加表达式类型的语法 (expression-level syntax)使用一致、完全可擦除的结构化类型系统……\n这些目标指导着 TypeScript 的发展方向：关注类型系统，成为 JavaScript 的类型检查器，只添加类型检查所需的语法，避免添加新的运行时语法和行为。\n微软提到，TypeScript 拥有如今的繁荣生态离不开一个重要属性：开源。TypeScript 一开始就是免费且开源 —— 语言规范和编译器都是开源项目，并且以真正开放的方式来运作。事实上，微软当时对外展现出的姿态并不是现在的 “拥抱开源”，所以他们内部并没真正认识到 TypeScript 的开源是如何帮助它走向成功。因此有人认为，TypeScript 在很大程度上引导微软开始更多地转向开源。\n现在，TypeScript 仍在积极发展和迭代改进，并被全球数百万开发者使用。在诸多编程语言排名、指数或开发者调查中，TypeScript 一直位居前列，也是最受欢迎和最常用的编程语言。','<p style=\"text-indent: 0px; text-align: start;\">TypeScript&nbsp;已经诞生&nbsp;10&nbsp;年了。10&nbsp;年前&nbsp;——2012&nbsp;年&nbsp;10&nbsp;月&nbsp;1&nbsp;日，TypeScript&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fweb.archive.org%2Fweb%2F20121003001910%2Fhttps%3A%2F%2Fblogs.msdn.com%2Fb%2Fsomasegar%2Farchive%2F2012%2F10%2F01%2Ftypescript-javascript-development-at-application-scale.aspx\" target=\"_blank\"><strong>首次公开亮相</strong></a>。当时主导&nbsp;TypeScript&nbsp;开发的&nbsp;Anders&nbsp;Hejlsberg&nbsp;这样描述&nbsp;TypeScript：</p><blockquote style=\"text-indent: 0px; text-align: left;\">它是&nbsp;JavaScript&nbsp;的类型化超集，可被编译成常用的&nbsp;JavaScript。TypeScript&nbsp;还可以通过启用丰富的工具体验来极大地帮助提升生产力，与此同时开发者保持不变维护现有的代码，并继续使用喜爱的&nbsp;JavaScript&nbsp;库。TypeScript&nbsp;is&nbsp;a&nbsp;typed&nbsp;superset&nbsp;of&nbsp;JavaScript&nbsp;that&nbsp;compiles&nbsp;to&nbsp;idiomatic&nbsp;(normal)&nbsp;JavaScript,&nbsp;can&nbsp;dramatically&nbsp;improve&nbsp;your&nbsp;productivity&nbsp;by&nbsp;enabling&nbsp;rich&nbsp;tooling&nbsp;experiences,&nbsp;all&nbsp;while&nbsp;maintaining&nbsp;your&nbsp;existing&nbsp;code&nbsp;and&nbsp;continuing&nbsp;to&nbsp;use&nbsp;the&nbsp;same&nbsp;JavaScript&nbsp;libraries&nbsp;you&nbsp;already&nbsp;love.</blockquote><p style=\"text-indent: 0px; text-align: left;\">微软在博客中回顾了&nbsp;TypeScript&nbsp;刚亮相时受到的评价，大多数人对它都是持怀疑态度，毕竟这对于许多&nbsp;JavaScript&nbsp;开发者来说，试图将静态类型引入&nbsp;JavaScript&nbsp;是一个笑话&nbsp;——&nbsp;或是邪恶的阴谋。反对者则直言这是十分愚蠢的想法，他们认为当时已存在可以编译为&nbsp;JavaScript&nbsp;的强类型语言，例如&nbsp;C#、Java&nbsp;和&nbsp;C++。他们还吐槽主导&nbsp;TypeScript&nbsp;开发的&nbsp;Anders&nbsp;Hejlsberg&nbsp;对静态类型有&nbsp;“迷之执着”。</p><p style=\"text-indent: 0px; text-align: start;\">当时微软意识到&nbsp;JavaScript&nbsp;未来将会被应用到无数场景，而且他们公司内部团队在处理复杂的&nbsp;JavaScript&nbsp;代码库时面临着巨大的挑战，所以他们觉得有必要创造强大的工具来帮助编写&nbsp;JavaScript——&nbsp;尤其是针对大型&nbsp;JavaScript&nbsp;项目。基于此需求，TypeScript&nbsp;也确定了自己的定位和特性，它是&nbsp;JavaScript&nbsp;的超集，将类型检查和静态分析、显式接口和最佳实践结合到单一语言和编译器中。通过在&nbsp;JavaScript&nbsp;上构建，TypeScript&nbsp;能够更接近目标运行时，同时仅添加支持大型应用程序和大型团队所需的语法糖。</p><p style=\"text-indent: 0px; text-align: start;\">团队还坚持&nbsp;TypeScript&nbsp;要能够与现有的&nbsp;JavaScript&nbsp;无缝交互，与&nbsp;JavaScript&nbsp;共同进化，并且看上去也和&nbsp;JavaScript&nbsp;类似。</p><p style=\"text-indent: 0px; text-align: start;\">TypeScript&nbsp;诞生之初的部分<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fgithub.com%2Fmicrosoft%2FTypeScript%2Fwiki%2FTypeScript-Design-Goals%2F53ffa9b1802cd8e18dfe4b2cd4e9ef5d4182df10\" target=\"_blank\"><strong>设计目标</strong></a>：</p><ul style=\"text-indent: 0px; text-align: left;\"><li>不会对已有的程序增加运行时开销</li><li>与当前和未来的&nbsp;ECMAScript&nbsp;提案保持一致</li><li>保留所有&nbsp;JavaScript&nbsp;代码的运行时行为</li><li>避免添加表达式类型的语法&nbsp;(expression-level&nbsp;syntax)</li><li>使用一致、完全可擦除的结构化类型系统</li><li>……</li></ul><p style=\"text-indent: 0px; text-align: start;\">这些目标指导着&nbsp;TypeScript&nbsp;的发展方向：关注类型系统，成为&nbsp;JavaScript&nbsp;的类型检查器，只添加类型检查所需的语法，避免添加新的运行时语法和行为。</p><p style=\"text-indent: 0px; text-align: start;\">微软提到，TypeScript&nbsp;拥有如今的繁荣生态离不开一个重要属性：<strong>开源</strong>。TypeScript&nbsp;一开始就是免费且开源&nbsp;——<span style=\"color: rgb(51, 51, 51);\">&nbsp;语言规范和编译器都是开源项目，</span>并且以真正开放的方式来运作。事实上，微软当时对外展现出的姿态并不是现在的&nbsp;“拥抱开源”，所以他们内部并没真正认识到&nbsp;TypeScript&nbsp;的开源是如何帮助它走向成功。因此有人认为，TypeScript&nbsp;在很大程度上引导微软开始更多地转向开源。</p><p style=\"text-indent: 0px; text-align: start;\">现在，TypeScript&nbsp;仍在积极发展和迭代改进，并被全球数百万开发者使用。在诸多编程语言排名、指数或开发者调查中，TypeScript&nbsp;一直位居前列，也是最受欢迎和最常用的编程语言。</p>','',0,0,'开源中国','开云',NULL,0,1,'2024-01-08 19:02:12','2022-10-22 14:34:56'),(54,1,'JetBrains Fleet 公测，下一代 IDE',1,0,'2024-01-01 20:22:23','JetBrains 宣布首次公共预览 Fleet，所有人都可以使用。Fleet 是由 JetBrains 打造的下一代 IDE，于 2021 年首次正式推出。它是一个新的分布式多语言编辑器和 IDE，基于 JetBrains 在后端的 IntelliJ 平台，采用了全新的用户界面和分布式架构从头开始构建。\n下载 Fleet：https://www.jetbrains.com.cn/fleet/download/\n\n公告表示，自从最初宣布 Fleet 以来，有超过 137,000 人报名参加私人预览；官方最初之所以决定从封闭式预览开始，是为了能够以渐进的方式处理反馈。现如今，JetBrains Fleet 仍处于起步阶段，还有大量的工作要做。其向公众开放预览的原因有两个方面：“首先，我们认为让所有注册者再等下去是不对的，但单独邀请这么多人对我们来说也缺乏意义。面向公众开放预览对我们来说更容易。第二，也是最重要的，我们一直是一家以开放态度打造产品的公司。我们不希望 Fleet 在这方面有任何不同。”\nJetBrains 方面提供了一个图表，以显示 Fleet 目前提供支持的语言和技术，以及每个技术的状态。但值得注意的是，Fleet 仍处于早期阶段，有些事情可能无法按预期工作；所以即使有些东西被列为受支持的，也有可能存在问题。\n同时 JetBrains 也强调称，他们并不打算取代其现有的 IDE。\n因此，请不要期望在 Fleet 中看到与我们的 IDE（如 IntelliJ IDEA）完全相同的功能。尽管我们会继续开发 Fleet，我们 IDE 的所有功能也不会出现在其中。Fleet 是我们为开发者提供不同用户体验的一个机会。话虽如此，我们确实希望听到你认为 Fleet 还缺少什么功能的反馈，例如特定的重构选项、工具集成等。我们现有的 IDE 将继续发展。我们对其有很多计划，包括性能改进、新的用户界面、远程开发等等。最后，Fleet 还在底层采用了我们现有工具的智慧，所以这些工具都不会消失。\nJetBrains 透露，在未来几个月他们将致力于稳定 Fleet，并尽可能地解决得到的反馈。同时，将在以下领域开展工作：\n为插件作者提供 API 支持和 SDK–鉴于 Fleet 有一个分布式架构，我们需要努力为插件作者简化工作。 虽然我们保证会为扩展 Fleet 提供一个平台，但也请求大家在这方面多一点耐心。 性能 – 我们希望 Fleet 不仅在内存占用方面，而且在响应时间方面都能表现出色。 有很多地方我们仍然可以提高性能，我们将在这些方面努力。 主题和键盘地图 – 我们知道许多开发者已经习惯了他们现有的编辑器和 IDE，当他们转移到新的 IDE 时，往往会想念他们以前的键盘绑定和主题。 我们将致力于增加对更多主题和键盘映射的支持。 我们当然也会致力于 Vim 的模拟。\n更多详情可查看官方博客。','<p style=\"text-indent: 0px; text-align: left;\">JetBrains&nbsp;<a href=\"https://my.oschina.net/u/5494143/blog/5584325\" target=\"\">宣布</a>首次公共预览&nbsp;<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fwww.jetbrains.com.cn%2Ffleet%2F\" target=\"_blank\">Fleet</a>，所有人都可以使用。Fleet&nbsp;是由&nbsp;JetBrains&nbsp;打造的下一代&nbsp;IDE，于&nbsp;2021&nbsp;年首次正式<a href=\"https://my.oschina.net/u/5494143/blog/5332934\" target=\"\">推出</a>。它是一个新的分布式多语言编辑器和&nbsp;IDE，基于&nbsp;JetBrains&nbsp;在后端的&nbsp;IntelliJ&nbsp;平台，采用了全新的用户界面和分布式架构从头开始构建。</p><p style=\"text-indent: 0px; text-align: left;\"><strong>下载&nbsp;Fleet：</strong><a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fwww.jetbrains.com.cn%2Ffleet%2Fdownload%2F\" target=\"_blank\">https://www.jetbrains.com.cn/fleet/download/</a></p><p style=\"text-indent: 0px; text-align: left;\"><br></p><p style=\"text-indent: 0px; text-align: left;\">公告表示，自从最初宣布&nbsp;Fleet&nbsp;以来，有超过&nbsp;137,000&nbsp;人报名参加私人预览；官方最初之所以决定从封闭式预览开始，是为了能够以渐进的方式处理反馈。现如今，JetBrains&nbsp;Fleet&nbsp;仍处于起步阶段，还有大量的工作要做。其向公众开放预览的原因有两个方面：“首先，我们认为让所有注册者再等下去是不对的，但单独邀请这么多人对我们来说也缺乏意义。面向公众开放预览对我们来说更容易。第二，也是最重要的，我们一直是一家以开放态度打造产品的公司。我们不希望&nbsp;Fleet&nbsp;在这方面有任何不同。”</p><p style=\"text-indent: 0px; text-align: left;\">JetBrains&nbsp;方面提供了一个<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fjb.gg%2Ffleet-feature-matrix\" target=\"_blank\">图表</a>，以显示&nbsp;Fleet&nbsp;目前提供支持的语言和技术，以及每个技术的状态。但值得注意的是，Fleet&nbsp;仍处于早期阶段，有些事情可能无法按预期工作；所以即使有些东西被列为受支持的，也有可能存在问题。</p><p style=\"text-indent: 0px; text-align: left;\">同时&nbsp;JetBrains&nbsp;也强调称，他们并不打算取代其现有的&nbsp;IDE。</p><blockquote style=\"text-indent: 0px; text-align: left;\">因此，请不要期望在&nbsp;Fleet&nbsp;中看到与我们的&nbsp;IDE（如&nbsp;IntelliJ&nbsp;IDEA）完全相同的功能。尽管我们会继续开发&nbsp;Fleet，我们&nbsp;IDE&nbsp;的所有功能也不会出现在其中。Fleet&nbsp;是我们为开发者提供不同用户体验的一个机会。话虽如此，我们确实希望听到你认为&nbsp;Fleet&nbsp;还缺少什么功能的反馈，例如特定的重构选项、工具集成等。我们现有的&nbsp;IDE&nbsp;将继续发展。我们对其有很多计划，包括性能改进、新的用户界面、远程开发等等。最后，Fleet&nbsp;还在底层采用了我们现有工具的智慧，所以这些工具都不会消失。</blockquote><p style=\"text-indent: 0px; text-align: start;\">JetBrains&nbsp;透露，在未来几个月他们将致力于稳定&nbsp;Fleet，并尽可能地解决得到的反馈。同时，将在以下领域开展工作：</p><ul style=\"text-indent: 0px; text-align: left;\"><li><strong>为插件作者提供&nbsp;API&nbsp;支持和&nbsp;SDK</strong>–鉴于&nbsp;Fleet&nbsp;有一个<a href=\"https://www.oschina.net/action/GoToLink?url=https%3A%2F%2Fblog.jetbrains.com%2Fzh-hans%2Ffleet%2F2022%2F01%2Ffleet-below-deck-part-i-architecture-overview%2F\" target=\"_blank\">分布式架构</a>，我们需要努力为插件作者简化工作。&nbsp;虽然我们保证会为扩展&nbsp;Fleet&nbsp;提供一个平台，但也请求大家在这方面多一点耐心。&nbsp;</li><li><strong>性能</strong>&nbsp;–&nbsp;我们希望&nbsp;Fleet&nbsp;不仅在内存占用方面，而且在响应时间方面都能表现出色。&nbsp;有很多地方我们仍然可以提高性能，我们将在这些方面努力。&nbsp;</li><li><strong>主题和键盘地图</strong>&nbsp;–&nbsp;我们知道许多开发者已经习惯了他们现有的编辑器和&nbsp;IDE，当他们转移到新的&nbsp;IDE&nbsp;时，往往会想念他们以前的键盘绑定和主题。&nbsp;我们将致力于增加对更多主题和键盘映射的支持。&nbsp;我们当然也会致力于&nbsp;Vim&nbsp;的模拟。</li></ul><p style=\"text-indent: 0px; text-align: left;\">更多详情可<a href=\"https://my.oschina.net/u/5494143/blog/5584325\" target=\"\">查看官方博客</a>。</p>','',0,0,'CSDN','开云',NULL,0,1,'2024-01-08 19:02:12','2022-10-22 14:36:10'),(55,2,'1024创新实验室 十一放假通知',1,0,'2024-01-01 20:22:23','国庆假期即将来临，根据国务院办公厅关于国庆节的放假安排，废纸信息网安排如下：10月1日至7日放假调休，共7天。\n衷心预祝\n国庆快乐，阖家幸福！','<p style=\"text-indent: 0px; text-align: justify;\">国庆假期即将来临，根据国务院办公厅关于国庆节的放假安排，废纸信息网安排如下：<strong>10月1日至7日放假调休</strong>，共7天。</p><p style=\"text-indent: 0px; text-align: justify;\"><strong>衷心预祝</strong></p><p style=\"text-indent: 0px; text-align: justify;\"><strong>国庆快乐，阖家幸福！</strong></p>','',0,0,'人力行政部','卓大','1024创新实验室发〔2022〕字第36号',0,1,'2024-01-08 19:02:12','2022-10-22 14:37:57'),(56,2,'十月份技术分享会议',1,0,'2024-01-01 20:22:23','尊敬的各位技术大佬：\n1024创新实验室技术分享即将隆重举行\n现将有关会议事宜通知如下：\n一、会议内容\n1、研究探讨SmartAdmin的技术体系\n二、会议形式\n大会专题小会分组讨论;\n三、会议时间及地点\n会议报到时间：xxx1年6月14日\n会议报到地点：洛阳市','<p style=\"text-indent: 0px; text-align: start;\">尊敬的各位技术大佬：</p><p style=\"text-indent: 0px; text-align: start;\">1024创新实验室技术分享即将隆重举行</p><p style=\"text-indent: 0px; text-align: start;\">现将有关会议事宜通知如下：</p><p style=\"text-indent: 0px; text-align: start;\"><strong>一、会议内容</strong></p><p style=\"text-indent: 0px; text-align: start;\">1、研究探讨SmartAdmin的技术体系</p><p style=\"text-indent: 0px; text-align: start;\"><strong>二、会议形式</strong></p><p style=\"text-indent: 0px; text-align: start;\">大会专题小会分组讨论;</p><p style=\"text-indent: 0px; text-align: start;\"><strong>三、会议时间及地点</strong></p><p style=\"text-indent: 0px; text-align: start;\">会议报到时间：xxx1年6月14日</p><p style=\"text-indent: 0px; text-align: start;\">会议报到地点：洛阳市</p>','',0,0,'技术部','开云','1024创新实验室发〔2022〕字第33号',0,1,'2024-01-08 19:02:12','2022-10-22 14:40:45'),(57,2,'关于疫情防控上班通知',1,0,'2024-01-01 20:22:23','近期，国内部分地区疫情频发，多地疫情出现外溢，为有效降低我市疫情输入和传播风险，洛阳市疾病预防控制中心发布疫情防控公众提示：\n一、所有入（返）洛阳人员均需提前3天向目的地社区（村居）、酒店宾馆、接待单位等所属网格进行报备，或通过“洛阳即时通系统”进行自主报备，配合做好健康码和行程码查验、核酸检测、隔离观察和健康监测等相关疫情防控措施。\n二、倡导广大群众减少跨地市出行，避免人群大范围流动引发的疫情传播扩散风险。\n三、对7天内有高风险区旅居史的人员，采取7天集中隔离医学观察；对7天内有中风险区旅居史的人员，采取7天居家隔离医学观察，如不具备居家隔离医学观察条件的，采取集中隔离医学观察。\n四、对疫情发生地出现一定范围社区传播或已实施大范围社区管控措施，基于对疫情输入风险研判结果，对近7天内来自疫情发生地所在县（市、区）的流入人员，参照中风险区旅居史人员的防控要求采取相应措施。\n五、对所有省外入（返）洛阳人员，须持有48小时内核酸检测阴性证明，抵达后进行“5天3检”，每次检测间隔24小时。推广“落地检”，按照“自愿免费即采即走，不限制流动”的原则，抵达我市后，立即进行1次核酸检测。\n六、加强重点机构场所疫情防控，坚持非必要不举办，对确需举办的培训、会展、文艺演出等大型聚集性活动，查验48小时内核酸检测阴性证明；建筑工地等人员密集型单位，查验外省（区、市）返岗人员48小时内核酸检测阴性证明；养老机构、儿童福利机构等查验探访人员48小时内核酸检测阴性证明；对进入宾馆、酒店和旅游景区等人流密集场所时，查验48小时内核酸检测阴性证明。\n七、近期有外出旅行史的人员，请密切关注疫情发生地区公布的病例和无症状感染者流调轨迹信息和中高风险区信息。有涉疫风险的人员要立即向社区（村）、住宿宾馆和单位报告，配合落实隔离医学观察。\n八、发热病人、健康码“黄码”等人员要履行个人防护责任，主动配合健康监测和核酸检测，在未排除感染风险前不出行。\n','<p style=\"text-indent: 0px; text-align: justify;\">近期，国内部分地区疫情频发，多地疫情出现外溢，为有效降低我市疫情输入和传播风险，洛阳市疾病预防控制中心发布疫情防控公众提示：</p><p style=\"text-indent: 0px; text-align: justify;\">一、所有入（返）洛阳人员均需提前3天向目的地社区（村居）、酒店宾馆、接待单位等所属网格进行报备，或通过“洛阳即时通系统”进行自主报备，配合做好健康码和行程码查验、核酸检测、隔离观察和健康监测等相关疫情防控措施。</p><p style=\"text-indent: 0px; text-align: justify;\">二、倡导广大群众减少跨地市出行，避免人群大范围流动引发的疫情传播扩散风险。</p><p style=\"text-indent: 0px; text-align: justify;\">三、对7天内有高风险区旅居史的人员，采取7天集中隔离医学观察；对7天内有中风险区旅居史的人员，采取7天居家隔离医学观察，如不具备居家隔离医学观察条件的，采取集中隔离医学观察。</p><p style=\"text-indent: 0px; text-align: justify;\">四、对疫情发生地出现一定范围社区传播或已实施大范围社区管控措施，基于对疫情输入风险研判结果，对近7天内来自疫情发生地所在县（市、区）的流入人员，参照中风险区旅居史人员的防控要求采取相应措施。</p><p style=\"text-indent: 0px; text-align: justify;\">五、对所有省外入（返）洛阳人员，须持有48小时内核酸检测阴性证明，抵达后进行“5天3检”，每次检测间隔24小时。推广“落地检”，按照“自愿免费即采即走，不限制流动”的原则，抵达我市后，立即进行1次核酸检测。</p><p style=\"text-indent: 0px; text-align: justify;\">六、加强重点机构场所疫情防控，坚持非必要不举办，对确需举办的培训、会展、文艺演出等大型聚集性活动，查验48小时内核酸检测阴性证明；建筑工地等人员密集型单位，查验外省（区、市）返岗人员48小时内核酸检测阴性证明；养老机构、儿童福利机构等查验探访人员48小时内核酸检测阴性证明；对进入宾馆、酒店和旅游景区等人流密集场所时，查验48小时内核酸检测阴性证明。</p><p style=\"text-indent: 0px; text-align: justify;\">七、近期有外出旅行史的人员，请密切关注疫情发生地区公布的病例和无症状感染者流调轨迹信息和中高风险区信息。有涉疫风险的人员要立即向社区（村）、住宿宾馆和单位报告，配合落实隔离医学观察。</p><p style=\"text-indent: 0px; text-align: justify;\">八、发热病人、健康码“黄码”等人员要履行个人防护责任，主动配合健康监测和核酸检测，在未排除感染风险前不出行。</p><p style=\"text-indent: 0px; text-align: justify;\"><br></p>','',0,0,'行政部','卓大','1024创新实验室发〔2022〕字第40号',0,1,'2024-01-08 19:02:12','2022-10-22 14:46:00'),(58,2,'办公室消杀关键位置通知',1,0,'2024-01-01 20:22:23','开展消毒消杀是杀灭病源、切断疫情传播的有效手段，是防控疫情的重要措施。为了切实将新型冠状病毒肺炎疫情防控工作落到实处，守护好辖区居民及工作人员的身体健康和生命安全，青山镇高度重视新型冠状病毒肺炎的消杀工作，将采购的防护服，防护面罩，一次性手套，口罩，84消毒液，酒精消毒液以及喷雾工具等消毒消杀物资，分发到镇级各站所各村（社区），全镇开展消杀工作。','<p><span style=\"color: rgb(93, 93, 93); background-color: rgb(247, 247, 247);\">开展消毒消杀是杀灭病源、切断疫情传播的有效手段，是防控疫情的重要措施。为了切实将新型冠状病毒肺炎疫情防控工作落到实处，守护好辖区居民及工作人员的身体健康和生命安全，青山镇高度重视新型冠状病毒肺炎的消杀工作，将采购的防护服，防护面罩，一次性手套，口罩，84消毒液，酒精消毒液以及喷雾工具等消毒消杀物资，分发到镇级各站所各村（社区），全镇开展消杀工作。</span></p>','',0,0,'行政部','卓大','1024创新实验室发〔2022〕字第26号',0,1,'2024-01-08 19:02:12','2022-10-22 14:47:12'),(59,2,'十月份人事任命通知',1,0,'2024-01-01 20:22:23','1024创新实验室发〔2022〕字第36号\n1024创新实验室发〔2022〕字第36号\n1024创新实验室发〔2022〕字第36号\n1024创新实验室发〔2022〕字第36号\n1024创新实验室发〔2022〕字第36号\n1024创新实验室发〔2022〕字第36号','<p>1024创新实验室发〔2022〕字第36号</p><p>1024创新实验室发〔2022〕字第36号</p><p>1024创新实验室发〔2022〕字第36号</p><p>1024创新实验室发〔2022〕字第36号</p><p>1024创新实验室发〔2022〕字第36号</p><p>1024创新实验室发〔2022〕字第36号</p>','',0,0,'销售部','卓大','1024创新实验室发〔2022〕字第30号',0,1,'2024-01-08 19:02:12','2022-10-22 14:50:11'),(60,2,'1024创新实验室 春节放假通知',1,0,'2024-01-01 20:22:23','春节假期即将来临，根据国务院办公厅关于国庆节的放假安排，废纸信息网安排如下：10月1日至7日放假调休，共7天。\n衷心预祝\n国庆快乐，阖家幸福！','<p style=\"text-indent: 0px; text-align: justify;\">国庆假期即将来临，根据国务院办公厅关于国庆节的放假安排，废纸信息网安排如下：<strong>10月1日至7日放假调休</strong>，共7天。</p><p style=\"text-indent: 0px; text-align: justify;\"><strong>衷心预祝</strong></p><p style=\"text-indent: 0px; text-align: justify;\"><strong>国庆快乐，阖家幸福！</strong></p>','',0,0,'人力行政部','卓大','1024创新实验室发〔2022〕字第36号',0,1,'2024-01-08 19:02:12','2022-10-22 14:37:57');
/*!40000 ALTER TABLE `t_notice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_notice_type`
--

DROP TABLE IF EXISTS `t_notice_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_notice_type` (
  `notice_type_id` bigint NOT NULL AUTO_INCREMENT COMMENT '通知类型',
  `notice_type_name` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '类型名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notice_type_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知类型';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_notice_type`
--

LOCK TABLES `t_notice_type` WRITE;
/*!40000 ALTER TABLE `t_notice_type` DISABLE KEYS */;
INSERT INTO `t_notice_type` VALUES (1,'新闻','2022-08-16 20:29:15','2024-09-03 21:44:42'),(2,'通知','2022-08-16 20:29:20','2022-08-16 20:29:20');
/*!40000 ALTER TABLE `t_notice_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_notice_view_record`
--

DROP TABLE IF EXISTS `t_notice_view_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_notice_view_record` (
  `notice_id` bigint NOT NULL COMMENT '通知公告id',
  `employee_id` bigint NOT NULL COMMENT '员工id',
  `page_view_count` int DEFAULT '0' COMMENT '查看次数',
  `first_ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '首次ip',
  `first_user_agent` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '首次用户设备等标识',
  `last_ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '最后一次ip',
  `last_user_agent` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '最后一次用户设备等标识',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notice_id`,`employee_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知查看记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_notice_view_record`
--

LOCK TABLES `t_notice_view_record` WRITE;
/*!40000 ALTER TABLE `t_notice_view_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_notice_view_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_notice_visible_range`
--

DROP TABLE IF EXISTS `t_notice_visible_range`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_notice_visible_range` (
  `notice_id` bigint NOT NULL COMMENT '资讯id',
  `data_type` tinyint NOT NULL COMMENT '数据类型1员工 2部门',
  `data_id` bigint NOT NULL COMMENT '员工or部门id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_notice_data` (`notice_id`,`data_type`,`data_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通知可见范围';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_notice_visible_range`
--

LOCK TABLES `t_notice_visible_range` WRITE;
/*!40000 ALTER TABLE `t_notice_visible_range` DISABLE KEYS */;
INSERT INTO `t_notice_visible_range` VALUES (63,1,63,'2024-08-09 10:40:32');
/*!40000 ALTER TABLE `t_notice_visible_range` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_oa_bank`
--

DROP TABLE IF EXISTS `t_oa_bank`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_oa_bank` (
  `bank_id` bigint NOT NULL AUTO_INCREMENT COMMENT '银行信息ID',
  `bank_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '开户银行',
  `account_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '账户名称',
  `account_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '账号',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `business_flag` tinyint(1) NOT NULL COMMENT '是否对公',
  `enterprise_id` bigint NOT NULL COMMENT '企业ID',
  `disabled_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '禁用状态',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除状态',
  `create_user_id` bigint NOT NULL COMMENT '创建人ID',
  `create_user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`bank_id`) USING BTREE,
  KEY `idx_enterprise_id` (`enterprise_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='OA银行信息\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_oa_bank`
--

LOCK TABLES `t_oa_bank` WRITE;
/*!40000 ALTER TABLE `t_oa_bank` DISABLE KEYS */;
INSERT INTO `t_oa_bank` VALUES (26,'工商银行','1024创新实验室','1024','基本户',1,2,0,0,1,'管理员','2022-10-22 17:58:43','2022-10-22 17:58:43'),(27,'建设银行','1024创新实验室','10241','其他户',0,2,0,0,1,'管理员','2022-10-22 17:59:19','2022-10-22 17:59:19');
/*!40000 ALTER TABLE `t_oa_bank` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_oa_enterprise`
--

DROP TABLE IF EXISTS `t_oa_enterprise`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_oa_enterprise` (
  `enterprise_id` bigint NOT NULL AUTO_INCREMENT COMMENT '企业ID',
  `enterprise_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '企业名称',
  `enterprise_logo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '企业logo',
  `type` int NOT NULL DEFAULT '1' COMMENT '类型（1:有限公司;2:合伙公司）',
  `unified_social_credit_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '统一社会信用代码',
  `contact` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '联系人',
  `contact_phone` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '联系人电话',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '邮箱',
  `province` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '省份',
  `province_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '省份名称',
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '市',
  `city_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '城市名称',
  `district` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '区县',
  `district_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '区县名称',
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '详细地址',
  `business_license` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '营业执照',
  `disabled_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '禁用状态',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除状态',
  `create_user_id` bigint NOT NULL COMMENT '创建人ID',
  `create_user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`enterprise_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=127 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='OA企业模块\r\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_oa_enterprise`
--

LOCK TABLES `t_oa_enterprise` WRITE;
/*!40000 ALTER TABLE `t_oa_enterprise` DISABLE KEYS */;
INSERT INTO `t_oa_enterprise` VALUES (1,'1024创新区块链实验室','public/common/34f5ac0fc097402294aea75352c128f0_20240306112435.png',1,'1024lab_block','开云','18637925892',NULL,'410000','河南省','410300','洛阳市','410311','洛龙区','区块链大楼','public/common/1d89055e5680426280446aff1e7e627c_20240306112451.jpeg',0,0,1,'管理员','2021-10-22 17:03:35','2022-10-22 17:04:18'),(2,'1024创新实验室','',2,'1024lab','卓大','18637925892','lab1024@163.com','410000','河南省','410300','洛阳市','410311','洛龙区','1024大楼','public/common/59b1ca99b7fe45d78678e6295798a699_20231201200459.jpg',0,0,44,'卓大','2022-10-22 14:57:36','2022-10-22 17:03:57');
/*!40000 ALTER TABLE `t_oa_enterprise` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_oa_enterprise_employee`
--

DROP TABLE IF EXISTS `t_oa_enterprise_employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_oa_enterprise_employee` (
  `enterprise_employee_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `enterprise_id` bigint NOT NULL COMMENT '企业ID',
  `employee_id` bigint NOT NULL COMMENT '员工ID',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`enterprise_employee_id`) USING BTREE,
  UNIQUE KEY `uk_enterprise_employee` (`enterprise_id`,`employee_id`) USING BTREE,
  KEY `idx_employee_id` (`employee_id`) USING BTREE,
  KEY `idx_enterprise_id` (`enterprise_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=159 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='企业关联的员工';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_oa_enterprise_employee`
--

LOCK TABLES `t_oa_enterprise_employee` WRITE;
/*!40000 ALTER TABLE `t_oa_enterprise_employee` DISABLE KEYS */;
INSERT INTO `t_oa_enterprise_employee` VALUES (154,'2','2','2022-10-22 17:57:50','2022-10-22 17:57:50'),(155,'2','44','2022-10-22 17:57:50','2022-10-22 17:57:50');
/*!40000 ALTER TABLE `t_oa_enterprise_employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_oa_invoice`
--

DROP TABLE IF EXISTS `t_oa_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_oa_invoice` (
  `invoice_id` bigint NOT NULL AUTO_INCREMENT COMMENT '发票信息ID',
  `invoice_heads` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '开票抬头',
  `taxpayer_identification_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '纳税人识别号',
  `account_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '银行账户',
  `bank_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '开户行',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `enterprise_id` bigint NOT NULL COMMENT '企业ID',
  `disabled_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '禁用状态',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除状态',
  `create_user_id` bigint NOT NULL COMMENT '创建人ID',
  `create_user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`invoice_id`) USING BTREE,
  KEY `idx_enterprise_id` (`enterprise_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='OA发票信息\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_oa_invoice`
--

LOCK TABLES `t_oa_invoice` WRITE;
/*!40000 ALTER TABLE `t_oa_invoice` DISABLE KEYS */;
INSERT INTO `t_oa_invoice` VALUES (15,'1024创新实验室','1024lab','1024lab','中国银行','123',2,0,0,1,'管理员','2022-10-22 17:59:35','2023-09-27 16:26:07');
/*!40000 ALTER TABLE `t_oa_invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_operate_log`
--

DROP TABLE IF EXISTS `t_operate_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_operate_log` (
  `operate_log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operate_user_id` bigint NOT NULL COMMENT '用户id',
  `operate_user_type` int NOT NULL COMMENT '用户类型',
  `operate_user_name` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名称',
  `module` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '操作模块',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '操作内容',
  `url` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '请求路径',
  `method` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '请求方法',
  `param` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '请求参数',
  `response` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '返回值',
  `ip` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '请求ip',
  `ip_region` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '请求ip地区',
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '请求user-agent',
  `success_flag` tinyint DEFAULT NULL COMMENT '请求结果 0失败 1成功',
  `fail_reason` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '失败原因',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`operate_log_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4499 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='操作记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_operate_log`
--

LOCK TABLES `t_operate_log` WRITE;
/*!40000 ALTER TABLE `t_operate_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_operate_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_password_log`
--

DROP TABLE IF EXISTS `t_password_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_password_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_type` tinyint NOT NULL COMMENT '用户类型',
  `old_password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '旧密码',
  `new_password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '新密码',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `user_and_type_index` (`user_id`,`user_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='密码修改记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_password_log`
--

LOCK TABLES `t_password_log` WRITE;
/*!40000 ALTER TABLE `t_password_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_password_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_position`
--

DROP TABLE IF EXISTS `t_position`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_position` (
  `position_id` bigint NOT NULL AUTO_INCREMENT COMMENT '职务ID',
  `position_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '职务名称',
  `position_level` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职级',
  `sort` int DEFAULT '0' COMMENT '排序',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `deleted_flag` tinyint(1) DEFAULT '0',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`position_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='职务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_position`
--

LOCK TABLES `t_position` WRITE;
/*!40000 ALTER TABLE `t_position` DISABLE KEYS */;
INSERT INTO `t_position` VALUES (3,'技术P7','L1',3,'',0,'2024-06-29 15:57:07','2024-07-15 23:34:35'),(4,'技术P8','L2',1,NULL,0,'2024-07-15 23:34:14','2024-07-15 23:34:23'),(5,'管理M5','L1',4,NULL,0,'2024-07-15 23:34:48','2024-07-15 23:34:48'),(6,'管理M6','L2',5,NULL,0,'2024-07-15 23:35:00','2024-07-15 23:35:00');
/*!40000 ALTER TABLE `t_position` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_question`
--

DROP TABLE IF EXISTS `t_question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_question` (
  `question_id` bigint NOT NULL AUTO_INCREMENT COMMENT '题目 ID',
  `course_id` bigint NOT NULL COMMENT '所属课程 ID',
  `chapter_id` bigint DEFAULT NULL COMMENT '所属章节 ID',
  `question_type` tinyint NOT NULL COMMENT '题型 [1:单选,2:多选,3:判断,4:简答,5:论述]',
  `content` text NOT NULL COMMENT '题目内容（支持 HTML）',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项 A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项 B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项 C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项 D',
  `correct_answer` varchar(100) DEFAULT NULL COMMENT '正确答案（多选如 "ABD"）',
  `reference_points` text COMMENT '参考答案要点（主观题用）',
  `score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '默认分值',
  `difficulty` tinyint NOT NULL DEFAULT '1' COMMENT '难度 [1:简单,2:中等,3:困难]',
  `tag` varchar(100) DEFAULT NULL COMMENT '知识点标签',
  `quote_count` int NOT NULL DEFAULT '0' COMMENT '被试卷引用次数（删除前校验用）',
  `creator_id` bigint NOT NULL COMMENT '创建人 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`question_id`),
  KEY `idx_course_chapter` (`course_id`,`chapter_id`),
  KEY `idx_type_difficulty` (`question_type`,`difficulty`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='题目表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_question`
--

LOCK TABLES `t_question` WRITE;
/*!40000 ALTER TABLE `t_question` DISABLE KEYS */;
INSERT INTO `t_question` VALUES (1,1,1,4,'请简述数据库与文件系统的主要区别。',NULL,NULL,NULL,NULL,NULL,'数据独立性、冗余控制、并发访问、安全性四个维度各占分',10.00,1,'数据库基础',0,2,0,'2026-07-30 01:49:05',NULL),(2,1,2,5,'论述关系模型中三类完整性约束及其作用。',NULL,NULL,NULL,NULL,NULL,'实体完整性、参照完整性、用户定义完整性各占分',20.00,2,'关系模型,完整性',0,2,0,'2026-07-30 01:49:05',NULL),(3,1,3,4,'写出查询\"选修课程超过3门的学生姓名\"的SQL。',NULL,NULL,NULL,NULL,NULL,'正确使用GROUP BY HAVING + 子查询或JOIN',20.00,3,'SQL,分组查询',0,2,0,'2026-07-30 01:49:05',NULL),(4,1,4,5,'为图书馆借阅系统设计满足3NF的关系模式。',NULL,NULL,NULL,NULL,NULL,'主键正确、外键关联合理、范式判定到位各占分',20.00,3,'范式,数据库设计',0,2,0,'2026-07-30 01:49:05',NULL),(5,1,5,4,'解释事务的ACID特性并说明各隔离级别。',NULL,NULL,NULL,NULL,NULL,'ACID四个特性各占分，隔离级别对比各占分',20.00,2,'事务,ACID',0,2,0,'2026-07-30 01:49:05',NULL),(6,1,3,1,'SQL中用于分组的子句是？','ORDER BY','GROUP BY','HAVING','WHERE','B',NULL,2.00,1,'SQL基础',0,2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_random_check`
--

DROP TABLE IF EXISTS `t_random_check`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_random_check` (
  `check_id` bigint NOT NULL AUTO_INCREMENT COMMENT '抽查 ID',
  `offering_id` bigint NOT NULL COMMENT '开课 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `check_type` tinyint NOT NULL COMMENT '类型 [1:课堂提问,2:随堂小测]',
  `score` decimal(5,2) NOT NULL DEFAULT '0.00' COMMENT '成绩（0-5 分）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator_id` bigint NOT NULL COMMENT '登记教师 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`check_id`),
  KEY `idx_offering_student` (`offering_id`,`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='随机抽查成绩表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_random_check`
--

LOCK TABLES `t_random_check` WRITE;
/*!40000 ALTER TABLE `t_random_check` DISABLE KEYS */;
INSERT INTO `t_random_check` VALUES (1,1,4,1,4.50,'回答准确，思路清晰',2,0,'2026-07-30 01:49:05',NULL),(2,1,5,2,3.00,'基本正确，部分知识点遗漏',2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_random_check` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_reload_item`
--

DROP TABLE IF EXISTS `t_reload_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_reload_item` (
  `tag` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '项名称',
  `args` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '参数 可选',
  `identification` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '运行标识',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`tag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='reload项目';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_reload_item`
--

LOCK TABLES `t_reload_item` WRITE;
/*!40000 ALTER TABLE `t_reload_item` DISABLE KEYS */;
INSERT INTO `t_reload_item` VALUES ('system_config','4','234','2024-08-13 14:14:30','2019-04-18 11:48:27');
/*!40000 ALTER TABLE `t_reload_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_reload_result`
--

DROP TABLE IF EXISTS `t_reload_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_reload_result` (
  `tag` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `identification` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '运行标识',
  `args` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `result` tinyint unsigned NOT NULL COMMENT '是否成功 ',
  `exception` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='reload结果';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_reload_result`
--

LOCK TABLES `t_reload_result` WRITE;
/*!40000 ALTER TABLE `t_reload_result` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_reload_result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_reward_application`
--

DROP TABLE IF EXISTS `t_reward_application`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_reward_application` (
  `reward_id` bigint NOT NULL AUTO_INCREMENT COMMENT '奖励 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `reward_type` tinyint NOT NULL COMMENT '类型 [1:题目纠错,2:功能反馈]',
  `related_object` varchar(200) DEFAULT NULL COMMENT '关联对象（题目 ID 或页面模块名）',
  `reward_reason` varchar(300) NOT NULL COMMENT '加分事由（最多 300 字）',
  `evidence_urls` json DEFAULT NULL COMMENT '佐证截图 URL 数组（最多 3 张）',
  `apply_points` decimal(5,2) NOT NULL DEFAULT '0.00' COMMENT '申请加分值',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态 [1:待审批,2:已通过,3:已驳回]',
  `awarded_points` decimal(5,2) DEFAULT NULL COMMENT '实际批准加分',
  `teacher_id` bigint DEFAULT NULL COMMENT '审批教师 ID（t_employee.employee_id）',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批意见/勉励语',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`reward_id`),
  KEY `idx_student_status` (`student_id`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='奖励申请表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_reward_application`
--

LOCK TABLES `t_reward_application` WRITE;
/*!40000 ALTER TABLE `t_reward_application` DISABLE KEYS */;
INSERT INTO `t_reward_application` VALUES (1,4,1,'题目5','发现事务隔离级别描述有误，提供修正建议',NULL,2.00,2,2.00,2,'纠错有效，加2分','2025-12-05 10:00:00','2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_reward_application` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_role`
--

DROP TABLE IF EXISTS `t_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_role` (
  `role_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色名称',
  `role_code` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色编码',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色描述',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`role_id`) USING BTREE,
  UNIQUE KEY `role_code_uni` (`role_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_role`
--

LOCK TABLES `t_role` WRITE;
/*!40000 ALTER TABLE `t_role` DISABLE KEYS */;
INSERT INTO `t_role` VALUES (1,'技术总监',NULL,'','2022-10-19 20:24:09','2019-06-21 12:09:34'),(34,'销售总监','cto','','2023-09-06 19:10:34','2019-08-30 09:30:50'),(35,'总经理',NULL,'','2019-08-30 09:31:05','2019-08-30 09:31:05'),(36,'董事长',NULL,'','2019-08-30 09:31:11','2019-08-30 09:31:11'),(37,'财务',NULL,'','2019-08-30 09:31:16','2019-08-30 09:31:16');
/*!40000 ALTER TABLE `t_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_role_data_scope`
--

DROP TABLE IF EXISTS `t_role_data_scope`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_role_data_scope` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `data_scope_type` int NOT NULL COMMENT '数据范围类型',
  `view_type` int NOT NULL COMMENT '数据可见范围类型',
  `role_id` bigint NOT NULL COMMENT '角色id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色的数据范围';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_role_data_scope`
--

LOCK TABLES `t_role_data_scope` WRITE;
/*!40000 ALTER TABLE `t_role_data_scope` DISABLE KEYS */;
INSERT INTO `t_role_data_scope` VALUES (67,1,2,1,'2024-03-18 20:41:00','2024-03-18 20:41:00');
/*!40000 ALTER TABLE `t_role_data_scope` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_role_employee`
--

DROP TABLE IF EXISTS `t_role_employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_role_employee` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` bigint NOT NULL COMMENT '角色id',
  `employee_id` bigint NOT NULL COMMENT '员工id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_role_employee` (`role_id`,`employee_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=342 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色员工功能表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_role_employee`
--

LOCK TABLES `t_role_employee` WRITE;
/*!40000 ALTER TABLE `t_role_employee` DISABLE KEYS */;
INSERT INTO `t_role_employee` VALUES (325,36,63,'2022-10-19 20:25:26','2022-10-19 20:25:26'),(329,34,72,'2022-11-05 10:56:54','2022-11-05 10:56:54'),(330,36,72,'2022-11-05 10:56:54','2022-11-05 10:56:54'),(333,1,44,'2023-10-07 18:53:29','2023-10-07 18:53:29'),(334,1,47,'2023-10-07 18:55:00','2023-10-07 18:55:00'),(341,1,48,'2024-09-02 23:03:28','2024-09-02 23:03:28');
/*!40000 ALTER TABLE `t_role_employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_role_menu`
--

DROP TABLE IF EXISTS `t_role_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_role_menu` (
  `role_menu_id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `role_id` bigint NOT NULL COMMENT '角色id',
  `menu_id` bigint NOT NULL COMMENT '菜单id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`role_menu_id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE,
  KEY `idx_menu_id` (`menu_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=820 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色-菜单\n';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_role_menu`
--

LOCK TABLES `t_role_menu` WRITE;
/*!40000 ALTER TABLE `t_role_menu` DISABLE KEYS */;
INSERT INTO `t_role_menu` VALUES (236,1,138,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(237,1,132,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(238,1,142,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(239,1,149,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(240,1,150,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(241,1,185,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(242,1,186,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(243,1,187,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(244,1,188,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(245,1,145,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(246,1,196,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(247,1,144,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(248,1,181,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(249,1,183,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(250,1,184,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(251,1,165,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(252,1,47,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(253,1,48,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(254,1,137,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(255,1,166,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(256,1,194,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(257,1,78,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(258,1,173,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(259,1,174,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(260,1,175,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(261,1,176,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(262,1,50,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(263,1,26,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(264,1,40,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(265,1,105,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(266,1,106,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(267,1,109,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(268,1,163,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(269,1,164,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(270,1,199,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(271,1,110,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(272,1,159,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(273,1,160,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(274,1,161,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(275,1,162,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(276,1,130,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(277,1,157,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(278,1,158,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(279,1,133,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(280,1,117,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(281,1,156,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(282,1,193,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(283,1,200,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(284,1,220,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(285,1,45,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(286,1,219,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(287,1,46,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(288,1,91,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(289,1,92,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(290,1,93,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(291,1,94,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(292,1,95,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(293,1,96,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(294,1,86,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(295,1,87,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(296,1,88,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(297,1,76,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(298,1,97,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(299,1,98,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(300,1,99,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(301,1,100,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(302,1,101,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(303,1,102,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(304,1,103,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(305,1,104,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(306,1,213,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(307,1,214,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(308,1,143,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(309,1,203,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(310,1,215,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(311,1,218,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(312,1,147,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(313,1,170,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(314,1,171,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(315,1,168,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(316,1,169,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(317,1,202,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(318,1,201,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(319,1,148,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(320,1,152,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(321,1,190,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(322,1,191,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(323,1,192,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(324,1,198,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(325,1,207,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(326,1,111,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(327,1,206,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(328,1,81,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(329,1,204,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(330,1,205,'2024-06-30 23:21:37','2024-06-30 23:21:37'),(331,1,122,'2024-06-30 23:21:37','2024-06-30 23:21:37');
/*!40000 ALTER TABLE `t_role_menu` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_score`
--

DROP TABLE IF EXISTS `t_score`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_score` (
  `score_id` bigint NOT NULL AUTO_INCREMENT COMMENT '成绩 ID',
  `exam_id` bigint NOT NULL COMMENT '考试 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `total_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总分（所有题目 final_score 之和）',
  `pass_status` tinyint NOT NULL DEFAULT '0' COMMENT '及格状态 [0:不及格,1:及格]',
  `rank_position` int DEFAULT NULL COMMENT '排名',
  `submit_time` datetime DEFAULT NULL COMMENT '交卷时间',
  `grade_time` datetime DEFAULT NULL COMMENT '批改完成时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`score_id`),
  UNIQUE KEY `uk_exam_student_unique` (`exam_id`,`student_id`),
  KEY `idx_exam_score` (`exam_id`,`total_score`),
  KEY `idx_student_id` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='成绩表（原始成绩，权威总分存档。S-07成绩详情页的展示数据在t_score_report取）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_score`
--

LOCK TABLES `t_score` WRITE;
/*!40000 ALTER TABLE `t_score` DISABLE KEYS */;
INSERT INTO `t_score` VALUES (1,1,4,89.00,1,NULL,'2025-11-10 10:25:00','2025-11-12 15:00:00',NULL,'2026-07-30 01:49:05',NULL),(2,1,5,28.20,0,NULL,'2025-11-10 10:30:00','2025-11-12 15:30:00',NULL,'2026-07-30 01:49:05',NULL),(3,1,6,29.60,0,NULL,'2025-11-10 10:15:00','2025-11-12 16:00:00',NULL,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_score` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_semester`
--

DROP TABLE IF EXISTS `t_semester`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_semester` (
  `semester_id` bigint NOT NULL AUTO_INCREMENT COMMENT '学期 ID',
  `semester_name` varchar(100) NOT NULL COMMENT '学期名称（如 2025-2026-2）',
  `start_date` date NOT NULL COMMENT '开始日期',
  `end_date` date NOT NULL COMMENT '结束日期',
  `is_current` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否当前学期 [0:否,1:是]',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`semester_id`),
  KEY `idx_is_current` (`is_current`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='学期表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_semester`
--

LOCK TABLES `t_semester` WRITE;
/*!40000 ALTER TABLE `t_semester` DISABLE KEYS */;
INSERT INTO `t_semester` VALUES (1,'2024-2025-2','2025-02-24','2025-07-11',0,0,'2026-07-30 01:49:05',NULL),(2,'2025-2026-1','2025-09-01','2026-01-16',0,0,'2026-07-30 01:49:05',NULL),(3,'2025-2026-2','2026-02-23','2026-07-05',1,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_semester` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_serial_number`
--

DROP TABLE IF EXISTS `t_serial_number`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_serial_number` (
  `serial_number_id` int NOT NULL,
  `business_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '业务名称',
  `format` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '格式[yyyy]表示年,[mm]标识月,[dd]表示日,[nnn]表示三位数字',
  `rule_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '规则格式。none没有周期, year 年周期, month月周期, day日周期',
  `init_number` int unsigned NOT NULL COMMENT '初始值',
  `step_random_range` int unsigned NOT NULL COMMENT '步长随机数',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `last_number` bigint DEFAULT NULL COMMENT '上次产生的单号, 默认为空',
  `last_time` datetime DEFAULT NULL COMMENT '上次产生的单号时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`serial_number_id`) USING BTREE,
  UNIQUE KEY `key_name` (`business_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='单号生成器定义表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_serial_number`
--

LOCK TABLES `t_serial_number` WRITE;
/*!40000 ALTER TABLE `t_serial_number` DISABLE KEYS */;
INSERT INTO `t_serial_number` VALUES (1,'订单编号','DK[yyyy][mm][dd]NO[nnnnn]','day',1000,10,'DK20201101NO321',1,'2023-12-04 09:16:42','2024-01-08 19:24:46','2021-02-19 14:37:50'),(2,'合同编号','HT[yyyy][mm][dd][nnnnn]-CX','none',1,1,'',8,'2023-12-04 09:54:53','2023-12-04 09:54:52','2021-08-12 20:40:37');
/*!40000 ALTER TABLE `t_serial_number` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_serial_number_record`
--

DROP TABLE IF EXISTS `t_serial_number_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_serial_number_record` (
  `serial_number_id` int NOT NULL,
  `record_date` date NOT NULL COMMENT '记录日期',
  `last_number` bigint NOT NULL DEFAULT '0' COMMENT '最后更新值',
  `last_time` datetime NOT NULL COMMENT '最后更新时间',
  `count` bigint NOT NULL DEFAULT '0' COMMENT '更新次数',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  KEY `uk_generator` (`serial_number_id`,`record_date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='serial_number记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_serial_number_record`
--

LOCK TABLES `t_serial_number_record` WRITE;
/*!40000 ALTER TABLE `t_serial_number_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_serial_number_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_smart_job`
--

DROP TABLE IF EXISTS `t_smart_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_smart_job` (
  `job_id` int NOT NULL AUTO_INCREMENT COMMENT '任务id',
  `job_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务名称',
  `job_class` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务执行类',
  `trigger_type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '触发类型',
  `trigger_value` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '触发配置',
  `enabled_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否开启',
  `param` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '参数',
  `last_execute_time` datetime DEFAULT NULL COMMENT '最后一次执行时间',
  `last_execute_log_id` int DEFAULT NULL COMMENT '最后一次执行记录id',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '描述',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除状态',
  `update_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '更新人',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务配置 @listen';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_smart_job`
--

LOCK TABLES `t_smart_job` WRITE;
/*!40000 ALTER TABLE `t_smart_job` DISABLE KEYS */;
INSERT INTO `t_smart_job` VALUES (1,'示例任务1','net.lab1024.sa.base.module.support.job.sample.SmartJobSample1','cron','10 15 0/1 * * *',1,'执行示例任务1','2025-01-05 19:15:10',7988,1,'执行示例任务1',0,'管理员','2024-06-17 20:00:46','2025-01-08 20:07:51'),(2,'示例任务2','net.lab1024.sa.base.module.support.job.sample.SmartJobSample2','fixed_delay','120',1,'执行示例任务2','2026-07-30 01:58:08',7936,2,'执行示例任务2',0,'管理员','2024-06-18 20:45:35','2026-07-30 01:58:08');
/*!40000 ALTER TABLE `t_smart_job` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_smart_job_log`
--

DROP TABLE IF EXISTS `t_smart_job_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_smart_job_log` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `job_id` int NOT NULL COMMENT '任务id',
  `job_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务名称',
  `param` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '执行参数',
  `success_flag` tinyint(1) NOT NULL COMMENT '是否成功',
  `execute_start_time` datetime NOT NULL COMMENT '执行开始时间',
  `execute_time_millis` int DEFAULT NULL COMMENT '执行时长',
  `execute_end_time` datetime DEFAULT NULL COMMENT '执行结束时间',
  `execute_result` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'ip',
  `process_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '进程id',
  `program_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '程序目录',
  `create_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建人',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`) USING BTREE,
  KEY `idx_job_id` (`job_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7937 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务-执行记录 @listen';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_smart_job_log`
--

LOCK TABLES `t_smart_job_log` WRITE;
/*!40000 ALTER TABLE `t_smart_job_log` DISABLE KEYS */;
INSERT INTO `t_smart_job_log` VALUES (7933,2,'示例任务2','执行示例任务2',1,'2026-07-30 01:50:08',11,'2026-07-30 01:50:08','执行成功,本次处理数据1条','192.168.31.11','82976','C:\\Users\\wwkkqwq\\Desktop\\smart-admin-master\\smart-admin-api-java17-springboot3\\sa-admin','system','2026-07-30 01:50:07'),(7934,2,'示例任务2','执行示例任务2',1,'2026-07-30 01:54:08',5,'2026-07-30 01:54:08','执行成功,本次处理数据1条','192.168.31.11','82976','C:\\Users\\wwkkqwq\\Desktop\\smart-admin-master\\smart-admin-api-java17-springboot3\\sa-admin','system','2026-07-30 01:54:07'),(7935,2,'示例任务2','执行示例任务2',1,'2026-07-30 01:56:08',5,'2026-07-30 01:56:08','执行成功,本次处理数据1条','192.168.31.11','82976','C:\\Users\\wwkkqwq\\Desktop\\smart-admin-master\\smart-admin-api-java17-springboot3\\sa-admin','system','2026-07-30 01:56:08'),(7936,2,'示例任务2','执行示例任务2',1,'2026-07-30 01:58:08',4,'2026-07-30 01:58:08','执行成功,本次处理数据1条','192.168.31.11','82976','C:\\Users\\wwkkqwq\\Desktop\\smart-admin-master\\smart-admin-api-java17-springboot3\\sa-admin','system','2026-07-30 01:58:08');
/*!40000 ALTER TABLE `t_smart_job_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_student_answer`
--

DROP TABLE IF EXISTS `t_student_answer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_student_answer` (
  `answer_id` bigint NOT NULL AUTO_INCREMENT COMMENT '作答记录 ID',
  `exam_id` bigint NOT NULL COMMENT '考试 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态 [1:未验证,2:已验证待开考,3:答题中,4:已提交,5:已批改]',
  `verify_fail_count` int NOT NULL DEFAULT '0' COMMENT '身份验证失败次数',
  `verify_lock_until` datetime DEFAULT NULL COMMENT '验证锁定截止时间',
  `start_answer_time` datetime DEFAULT NULL COMMENT '开始答题时间',
  `last_save_time` datetime DEFAULT NULL COMMENT '最后保存时间（草稿）',
  `answer_version` int NOT NULL DEFAULT '0' COMMENT '答案版本号（乐观锁，每次自动保存+1，保存时校验一致性，防止多端答题互相覆盖）',
  `submit_time` datetime DEFAULT NULL COMMENT '提交时间',
  `ip_address` varchar(50) DEFAULT NULL COMMENT 'IP 地址',
  `device_info` varchar(500) DEFAULT NULL COMMENT '设备信息',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`answer_id`),
  UNIQUE KEY `uk_exam_student` (`exam_id`,`student_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='学生作答记录表（S-05身份验证/S-06答题/自动保存草稿。answer_version乐观锁防多端答题覆盖，每次保存携带版本号校验一致性）';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_student_answer`
--

LOCK TABLES `t_student_answer` WRITE;
/*!40000 ALTER TABLE `t_student_answer` DISABLE KEYS */;
INSERT INTO `t_student_answer` VALUES (1,1,4,5,0,NULL,'2025-11-10 09:01:00',NULL,0,'2025-11-10 10:25:00',NULL,NULL,'2026-07-30 01:49:05',NULL),(2,1,5,5,0,NULL,'2025-11-10 09:00:30',NULL,0,'2025-11-10 10:30:00',NULL,NULL,'2026-07-30 01:49:05',NULL),(3,1,6,5,0,NULL,'2025-11-10 09:02:00',NULL,0,'2025-11-10 10:15:00',NULL,NULL,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_student_answer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_table_column`
--

DROP TABLE IF EXISTS `t_table_column`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_table_column` (
  `table_column_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_type` int NOT NULL COMMENT '用户类型',
  `table_id` int NOT NULL COMMENT '表格id',
  `columns` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '具体的表格列，存入的json',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`table_column_id`) USING BTREE,
  UNIQUE KEY `uni_employee_table` (`user_id`,`table_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='表格的自定义列存储';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_table_column`
--

LOCK TABLES `t_table_column` WRITE;
/*!40000 ALTER TABLE `t_table_column` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_table_column` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_unit_test`
--

DROP TABLE IF EXISTS `t_unit_test`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_unit_test` (
  `test_id` bigint NOT NULL AUTO_INCREMENT COMMENT '测试 ID',
  `offering_id` bigint NOT NULL COMMENT '开课 ID',
  `test_name` varchar(200) NOT NULL COMMENT '测试名称（如 单元测试一）',
  `test_time` date NOT NULL COMMENT '测试日期',
  `test_content` varchar(500) DEFAULT NULL COMMENT '测试内容描述',
  `is_published` tinyint(1) NOT NULL DEFAULT '0' COMMENT '成绩是否已发布 [0:否,1:是]',
  `creator_id` bigint NOT NULL COMMENT '创建教师 ID（t_employee.employee_id）',
  `deleted_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '删除标记 [0:正常,1:已删除]',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`test_id`),
  KEY `idx_offering_id` (`offering_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='单元测试表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_unit_test`
--

LOCK TABLES `t_unit_test` WRITE;
/*!40000 ALTER TABLE `t_unit_test` DISABLE KEYS */;
INSERT INTO `t_unit_test` VALUES (1,1,'第一单元测试-数据库基础','2025-09-30',NULL,0,2,0,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_unit_test` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_unit_test_score`
--

DROP TABLE IF EXISTS `t_unit_test_score`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_unit_test_score` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
  `test_id` bigint NOT NULL COMMENT '测试 ID',
  `student_id` bigint NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `score` decimal(10,2) DEFAULT NULL COMMENT '成绩（NULL 表示未录入）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_test_student` (`test_id`,`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='单元测试成绩明细表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_unit_test_score`
--

LOCK TABLES `t_unit_test_score` WRITE;
/*!40000 ALTER TABLE `t_unit_test_score` DISABLE KEYS */;
INSERT INTO `t_unit_test_score` VALUES (1,1,4,92.00,'2026-07-30 01:49:05',NULL),(2,1,5,85.00,'2026-07-30 01:49:05',NULL),(3,1,6,78.00,'2026-07-30 01:49:05',NULL);
/*!40000 ALTER TABLE `t_unit_test_score` ENABLE KEYS */;
UNLOCK TABLES;

-- ============================================================
-- v3.2 新增表（2026-07-30）
-- ============================================================

--
-- Table structure for table `t_paper_snapshot`
--

DROP TABLE IF EXISTS `t_paper_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_paper_snapshot` (
  `snapshot_id`   bigint         NOT NULL AUTO_INCREMENT COMMENT '快照 ID',
  `exam_id`       bigint         NOT NULL COMMENT '考试 ID',
  `paper_content` json           NOT NULL COMMENT '试卷完整快照（题目ID/题干/选项/分值/答案的JSON数组）',
  `total_points`  decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '试卷总分',
  `generated_at`  datetime       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '快照生成时间',
  `create_time`   datetime       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`snapshot_id`),
  KEY `idx_exam_id` (`exam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='试卷快照表（考试发布时整卷存档，防题库变更污染历史）';

--
-- Table structure for table `t_score_report`
--

DROP TABLE IF EXISTS `t_score_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_score_report` (
  `report_id`           bigint         NOT NULL AUTO_INCREMENT COMMENT '报告 ID',
  `score_id`            bigint         NOT NULL COMMENT '成绩 ID（关联 t_score.score_id）',
  `exam_id`             bigint         NOT NULL COMMENT '考试 ID',
  `student_id`          bigint         NOT NULL COMMENT '学生 ID',
  `display_score`       decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '展示分（原始分×难度系数加权后，前端展示用。与 t_score.total_score 原始分分离）',
  `question_scores`     json           DEFAULT NULL COMMENT '逐题得分明细（JSON：[{questionId,rawScore,maxScore,weightedScore,threeDimension:{relevance,coverage,logic}}...]）',
  `three_dimension_avg` json           DEFAULT NULL COMMENT '三维度平均分（{"relevance":4.3,"coverage":3.8,"logic":4.5}）',
  `overall_suggestion`  text           COMMENT 'AI 整体学习建议（亮点/薄弱点/改进建议，由外部评分服务返回）',
  `model_trace_id`      varchar(200)   DEFAULT NULL COMMENT 'AI 评分服务返回的 trace ID（用于问题追溯）',
  `grade_time`          datetime       DEFAULT NULL COMMENT '批改完成时间',
  `create_time`         datetime       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time`         datetime       DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`report_id`),
  UNIQUE KEY `uk_score_id` (`score_id`),
  KEY `idx_exam_student` (`exam_id`, `student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='成绩报告表（与原始成绩分离，含展示分+AI建议，精准命中S-07）';

--
-- Table structure for table `t_exam_verification`
--

DROP TABLE IF EXISTS `t_exam_verification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_exam_verification` (
  `verify_id`       bigint        NOT NULL AUTO_INCREMENT COMMENT '验证 ID',
  `exam_id`         bigint        NOT NULL COMMENT '考试 ID',
  `student_id`      bigint        NOT NULL COMMENT '学生 ID（t_employee.employee_id）',
  `face_pass_count` int           NOT NULL DEFAULT '0' COMMENT '人脸比对通过张数',
  `voice_score`     decimal(6,3)  DEFAULT NULL COMMENT '声纹相似度（0-1）',
  `passed`          tinyint       NOT NULL DEFAULT '0' COMMENT '是否验证通过 [0:否,1:是]',
  `failed_times`    int           NOT NULL DEFAULT '0' COMMENT '验证失败累计次数',
  `locked_until`    datetime      DEFAULT NULL COMMENT '验证锁定截止时间',
  `verify_token`    varchar(64)   DEFAULT NULL COMMENT '准入令牌（验证通过发放，进入考试需校验）',
  `token_expire_at` datetime      DEFAULT NULL COMMENT '令牌过期时间',
  `create_time`     datetime      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time`     datetime      DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`verify_id`),
  UNIQUE KEY `uk_exam_student_verify` (`exam_id`, `student_id`),
  KEY `idx_verify_token` (`verify_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='考前身份验证状态表（准入令牌防跳过验证）';

--
-- Table structure for table `t_scoring_rubric`
--

DROP TABLE IF EXISTS `t_scoring_rubric`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_scoring_rubric` (
  `rubric_id`         bigint       NOT NULL AUTO_INCREMENT COMMENT '标准 ID',
  `offering_id`       bigint       NOT NULL COMMENT '开课 ID（一门开课一套标准）',
  `teacher_id`        bigint       NOT NULL COMMENT '配置教师 ID',
  `dimension_weights` json         DEFAULT NULL COMMENT '三维权重（{"relevance":0.4,"coverage":0.4,"logic":0.2}）',
  `custom_prompt`     text         COMMENT '自定义评分提示词（传给外部评分服务的评分标准，对应S-09的评分依据展示）',
  `class_name`        varchar(100) DEFAULT NULL COMMENT '班级名称快照（冗余，防止改名后历史显示错乱）',
  `deleted_flag`      tinyint      NOT NULL DEFAULT '0' COMMENT '删除标记',
  `create_time`       datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time`       datetime     DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`rubric_id`),
  UNIQUE KEY `uk_offering` (`offering_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='课程评分标准配置表（三维权重+自定义提示词，对接外部AI评分）';

--
-- Table structure for table `t_monitor_event`
--

DROP TABLE IF EXISTS `t_monitor_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_monitor_event` (
  `event_id`     bigint       NOT NULL AUTO_INCREMENT COMMENT '事件 ID',
  `answer_id`    bigint       NOT NULL COMMENT '作答记录 ID（关联 t_student_answer.answer_id）',
  `exam_id`      bigint       NOT NULL COMMENT '考试 ID',
  `student_id`   bigint       NOT NULL COMMENT '学生 ID',
  `event_type`   tinyint      NOT NULL COMMENT '事件类型 [1:切屏,2:失焦,3:退出全屏,4:开开发者工具,5:人脸离开,6:多人出现,7:声音异常]',
  `severity`     tinyint      NOT NULL DEFAULT '1' COMMENT '严重度 [1:低,2:中,3:高,4:严重]',
  `description`  varchar(500) DEFAULT NULL COMMENT '事件描述（如"切换到浏览器其他标签页 15 秒"）',
  `evidence_url` varchar(500) DEFAULT NULL COMMENT '抓拍截图/证据文件 URL',
  `occurred_at`  datetime     NOT NULL COMMENT '事件发生时间（客户端上报）',
  `received_at`  datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '服务器接收时间（与occurred_at对比可检测客户端时间篡改）',
  `create_time`  datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`event_id`),
  KEY `idx_answer_id` (`answer_id`),
  KEY `idx_exam_student` (`exam_id`, `student_id`),
  KEY `idx_event_type` (`event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='监控事件表（仅记录"发生了什么"，与判定分离，支持事件溯源）';

--
-- Table structure for table `t_abnormal_decision`
--

DROP TABLE IF EXISTS `t_abnormal_decision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_abnormal_decision` (
  `decision_id`   bigint         NOT NULL AUTO_INCREMENT COMMENT '判定 ID',
  `event_id`      bigint         NOT NULL COMMENT '事件 ID（关联 t_monitor_event.event_id，一个事件可有多个判定）',
  `decision`      tinyint        NOT NULL COMMENT '判定结果 [1:确认违规,2:标记误判]',
  `deduct_points` decimal(10,2)  NOT NULL DEFAULT '0.00' COMMENT '扣分值',
  `comment`       varchar(500)   DEFAULT NULL COMMENT '处理意见',
  `handled_by`    bigint         DEFAULT NULL COMMENT '处理教师 ID',
  `handled_at`    datetime       DEFAULT NULL COMMENT '处理时间',
  `version`       int            NOT NULL DEFAULT '1' COMMENT '判定版本号（1=初判,2=复核,每改判一次+1，支持复核改判追溯）',
  `exam_id`       bigint         NOT NULL COMMENT '考试 ID（冗余，便于按考试查询）',
  `create_time`   datetime       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`decision_id`),
  KEY `idx_event_id` (`event_id`),
  KEY `idx_exam_id` (`exam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='异常行为判定表（与事件分离，支持复核改判，事件溯源）';

--
-- Table structure for table `t_course_audience`
--

DROP TABLE IF EXISTS `t_course_audience`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_course_audience` (
  `id`            bigint   NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
  `offering_id`   bigint   NOT NULL COMMENT '开课 ID',
  `department_id` bigint   NOT NULL COMMENT '面向部门/班级 ID（复用框架 t_department.department_id，通过层级实现学院→专业→班级）',
  `deleted_flag`  tinyint  NOT NULL DEFAULT '0' COMMENT '删除标记',
  `create_time`   datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time`   datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_offering` (`offering_id`),
  KEY `idx_department` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='开课受众范围表（控制开课面向哪些部门/班级）';

--
-- Table structure for table `t_attachment`
--

DROP TABLE IF EXISTS `t_attachment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_attachment` (
  `attachment_id` bigint       NOT NULL AUTO_INCREMENT COMMENT '附件 ID',
  `biz_type`      tinyint      NOT NULL COMMENT '业务类型 [1:复议,2:请假,3:奖励]',
  `biz_id`        bigint       NOT NULL COMMENT '业务记录 ID（对应各申请表主键）',
  `file_name`     varchar(200) DEFAULT NULL COMMENT '文件名',
  `file_url`      varchar(500) NOT NULL COMMENT '文件访问 URL',
  `file_type`     varchar(50)  DEFAULT NULL COMMENT '文件类型（如 image/png）',
  `file_size`     bigint       DEFAULT NULL COMMENT '文件大小（字节）',
  `sort_order`    int          NOT NULL DEFAULT '0' COMMENT '排序顺序',
  `create_time`   datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  PRIMARY KEY (`attachment_id`),
  KEY `idx_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='通用附件表（统一管理复议/请假/奖励的附件，替代evidence_urls字段方案）';

--
-- Table structure for table `t_enrollment_log`
--

DROP TABLE IF EXISTS `t_enrollment_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_enrollment_log` (
  `id`          bigint       NOT NULL AUTO_INCREMENT COMMENT '日志 ID',
  `student_id`  bigint       NOT NULL COMMENT '学生 ID',
  `offering_id` bigint       NOT NULL COMMENT '开课 ID',
  `operation`   tinyint      NOT NULL COMMENT '操作类型 [1:选课,2:退课]',
  `reason`      varchar(200) DEFAULT NULL COMMENT '原因说明（退课时填写）',
  `operator_id` bigint       NOT NULL COMMENT '操作人 ID（学生本人或管理员）',
  `create_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_student_time` (`student_id`, `create_time`),
  KEY `idx_offering_time` (`offering_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='选课操作日志表（选课/退课留痕可审计）';

-- ============================================================
-- v3.2 数据校准（quote_count 刷新）
-- ============================================================

UPDATE `t_question` q
LEFT JOIN (
  SELECT `question_id`, COUNT(*) AS ref_count
  FROM `t_exam_question`
  GROUP BY `question_id`
) eq ON q.`question_id` = eq.`question_id`
SET q.`quote_count` = IFNULL(eq.`ref_count`, 0);

-- ============================================================
-- v4.0 新表种子数据（与现有 exam=1 数据联动）
-- ============================================================

-- ----------------------------
-- 1. t_scoring_rubric（评分标准：offering=1，三维权重 4:4:2）
-- ----------------------------
INSERT INTO `t_scoring_rubric` (`offering_id`, `teacher_id`, `dimension_weights`, `custom_prompt`, `class_name`)
VALUES (1, 2, '{"relevance":0.4,"coverage":0.4,"logic":0.2}',
        '请从以下三个维度评分（每题满分20分）：1. 相关性（0-5分制）— 答案是否紧扣题意、不跑题；2. 知识覆盖（0-5分制）— 知识点覆盖是否完整、深度是否足够；3. 逻辑表达（0-5分制）— 论述是否有条理、表达是否清晰。最终得分公式为：题目满分20 × (相关性×0.4 + 覆盖×0.4 + 逻辑×0.2)。',
        '数据库原理-2025秋季班');

-- ----------------------------
-- 2. t_paper_snapshot（考试1的整卷快照）
-- ----------------------------
INSERT INTO `t_paper_snapshot` (`exam_id`, `paper_content`, `total_points`, `generated_at`)
VALUES (1,
        '[{"questionId":1,"type":4,"content":"请简述数据库与文件系统的主要区别。","score":20,"correctAnswer":null,"referencePoints":"数据独立性、冗余控制、并发访问、安全性四个维度各占分"},{"questionId":2,"type":5,"content":"论述关系模型中三类完整性约束及其作用。","score":20,"correctAnswer":null,"referencePoints":"实体完整性、参照完整性、用户定义完整性各占分"},{"questionId":3,"type":4,"content":"写出查询「选修课程超过3门的学生姓名」的SQL。","score":20,"correctAnswer":null,"referencePoints":"正确使用GROUP BY HAVING + 子查询或JOIN"},{"questionId":4,"type":5,"content":"为图书馆借阅系统设计满足3NF的关系模式。","score":20,"correctAnswer":null,"referencePoints":"主键正确、外键关联合理、范式判定到位各占分"},{"questionId":5,"type":4,"content":"解释事务的ACID特性并说明各隔离级别。","score":20,"correctAnswer":null,"referencePoints":"ACID四个特性各占分，隔离级别对比各占分"}]',
        100.00, '2025-11-10 09:00:00');

-- ----------------------------
-- 3. t_score_report（基于 t_score 的三份成绩报告）
-- ----------------------------
INSERT INTO `t_score_report` (`score_id`, `exam_id`, `student_id`, `display_score`, `question_scores`, `three_dimension_avg`, `overall_suggestion`, `model_trace_id`, `grade_time`)
VALUES
(1, 1, 4, 89.00,
 '[{"questionId":1,"rawScore":18.40,"maxScore":20,"weightedScore":18.45,"threeDimension":{"relevance":4.8,"coverage":4.5,"logic":4.6}},{"questionId":2,"rawScore":16.20,"maxScore":20,"weightedScore":16.19,"threeDimension":{"relevance":4.3,"coverage":3.9,"logic":4.0}},{"questionId":3,"rawScore":19.00,"maxScore":20,"weightedScore":19.08,"threeDimension":{"relevance":4.9,"coverage":4.8,"logic":4.7}},{"questionId":4,"rawScore":17.20,"maxScore":20,"weightedScore":17.14,"threeDimension":{"relevance":4.5,"coverage":4.3,"logic":4.1}},{"questionId":5,"rawScore":18.20,"maxScore":20,"weightedScore":18.21,"threeDimension":{"relevance":4.8,"coverage":4.5,"logic":4.4}}]',
 '{"relevance":4.66,"coverage":4.40,"logic":4.36}',
 '整体表现优秀。知识覆盖全面（4.40），特别是SQL实操和ACID理论掌握扎实（第3、5题接近满分）。建议加强：参照完整性中的级联操作细节（第2题扣分较多），以及BCNF的判定方法。继续保持理论结合实践的学习方式。',
 'trace-db-mid-stu4-20251112', '2025-11-12 15:00:00'),

(2, 1, 5, 28.20,
 '[{"questionId":1,"rawScore":15.00,"maxScore":20,"weightedScore":14.95,"threeDimension":{"relevance":4.0,"coverage":3.5,"logic":3.8}},{"questionId":2,"rawScore":13.20,"maxScore":20,"weightedScore":13.10,"threeDimension":{"relevance":3.5,"coverage":3.1,"logic":3.3}}]',
 '{"relevance":3.75,"coverage":3.30,"logic":3.55}',
 '基础知识方向正确，但对数据独立性、事务等核心概念理解不深，缺少学术规范表述。建议：重新复习第1-2章基础理论，重点关注"数据库与文件系统的本质区别"；提交前确认所有题目已作答（本次仅完成2/5题）。',
 'trace-db-mid-stu5-20251112', '2025-11-12 15:30:00'),

(3, 1, 6, 29.60,
 '[{"questionId":1,"rawScore":12.00,"maxScore":20,"weightedScore":11.90,"threeDimension":{"relevance":3.3,"coverage":2.8,"logic":3.0}},{"questionId":3,"rawScore":17.60,"maxScore":20,"weightedScore":17.68,"threeDimension":{"relevance":4.6,"coverage":4.3,"logic":4.4}}]',
 '{"relevance":3.95,"coverage":3.55,"logic":3.70}',
 'SQL实操能力较好（第3题得分高），但理论基础薄弱（第1题术语不规范）。建议：理论题先打框架再展开论述，学习用学术语言替代口语化表达；提交前务必完成全部题目（本次仅完成2/5题）。',
 'trace-db-mid-stu6-20251112', '2025-11-12 16:00:00');

-- ----------------------------
-- 4. t_exam_verification（三位学生的考前身份验证记录）
-- ----------------------------
INSERT INTO `t_exam_verification` (`exam_id`, `student_id`, `face_pass_count`, `voice_score`, `passed`, `failed_times`, `verify_token`, `token_expire_at`)
VALUES
(1, 4, 3, 0.952, 1, 0, 'VT4a7b3c9d1e2f8', '2025-11-10 10:35:00'),
(1, 5, 3, 0.918, 1, 0, 'VT8f2a1c6d4b9e3', '2025-11-10 10:40:00'),
(1, 6, 2, 0.887, 1, 1, 'VT1c5e9f3a7d2b6', '2025-11-10 10:25:00');

-- ----------------------------
-- 5. t_course_audience（开课1面向开发部 = department_id=2）
-- ----------------------------
INSERT INTO `t_course_audience` (`offering_id`, `department_id`)
VALUES (1, 2);

-- ----------------------------
-- 6. t_monitor_event（3 条异常事件示例：切屏 / 人脸离开 / 开开发者工具）
-- ----------------------------
INSERT INTO `t_monitor_event` (`answer_id`, `exam_id`, `student_id`, `event_type`, `severity`, `description`, `evidence_url`, `occurred_at`, `received_at`)
VALUES
-- 对应旧 behavior_id=1：学生4切屏
(1, 1, 4, 1, 2, '切换到浏览器其他标签页约15秒', '/monitor/exam1/stu4_switch.png', '2025-11-10 09:08:00', '2025-11-10 09:08:02'),
-- 对应旧 behavior_id=2：学生5人脸离开
(2, 1, 5, 5, 1, '面部离开摄像头视野约8秒', '/monitor/exam1/stu5_faceaway.png', '2025-11-10 09:13:00', '2025-11-10 09:13:01'),
-- 新增：学生6开开发者工具（旧表行为类型7，演示新体系覆盖全类型）
(3, 1, 6, 4, 3, '按F12打开Chrome开发者工具，持续约20秒后关闭', '/monitor/exam1/stu6_devtools.png', '2025-11-10 09:06:00', '2025-11-10 09:06:03');

-- ----------------------------
-- 7. t_abnormal_decision（对应上述事件的判定）
-- ----------------------------
INSERT INTO `t_abnormal_decision` (`event_id`, `decision`, `deduct_points`, `comment`, `handled_by`, `handled_at`, `version`, `exam_id`)
VALUES
-- 事件1：系统初判违规扣5分
(1, 1, 5.00, '系统自动判定：切屏超15秒，按规则扣5分', NULL, '2025-11-10 09:08:05', 1, 1),
-- 事件2：系统初判待确认（标记误判，不扣分）
(2, 2, 0.00, '系统自动判定：人脸短暂离开，时长<10秒，标记误判', NULL, '2025-11-10 09:13:05', 1, 1),
-- 事件3：系统初判违规，教师复核中
(3, 1, 3.00, '系统自动判定：开开发者工具属严重违规，扣3分。教师待复核', NULL, '2025-11-10 09:06:08', 1, 1);

-- ----------------------------
-- 8. t_attachment（复议相关的证据附件）
-- ----------------------------
INSERT INTO `t_attachment` (`biz_type`, `biz_id`, `file_name`, `file_url`, `file_type`, `file_size`, `sort_order`)
VALUES
(1, 1, '外键知识整理.png', '/appeal/evidence/stu4_fk_summary.png', 'image/png', 153600, 1);

-- ----------------------------
-- 9. t_enrollment_log（选课操作日志）
-- ----------------------------
INSERT INTO `t_enrollment_log` (`student_id`, `offering_id`, `operation`, `reason`, `operator_id`, `create_time`)
VALUES
(4, 1, 1, NULL, 4, '2025-09-03 10:00:00'),
(5, 1, 1, NULL, 5, '2025-09-03 10:05:00'),
(6, 1, 1, NULL, 6, '2025-09-03 14:30:00'),
(4, 2, 1, NULL, 4, '2025-09-04 09:00:00');

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-30  1:58:38
