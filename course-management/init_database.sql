-- ===================================================================
-- 课程管理系统 - 数据库建表脚本
-- 数据库版本：MySQL 5.7
-- 字符集：utf8mb4
-- 引擎：InnoDB
-- ===================================================================

-- 创建数据库（如已存在请忽略）
CREATE DATABASE IF NOT EXISTS course_management
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci;

USE course_management;

-- ===================================================================
-- 1. 课程章节表（支持无限层级树形结构）
-- ===================================================================
CREATE TABLE IF NOT EXISTS teacher_chapter (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '章节ID，主键自增',
    parent_id   BIGINT       NOT NULL DEFAULT 0       COMMENT '父章节ID，顶级章节为0',
    course_id   BIGINT       NOT NULL DEFAULT 0       COMMENT '所属课程ID',
    chapter_name VARCHAR(200) NOT NULL                  COMMENT '章节名称',
    sort        INT          NOT NULL DEFAULT 0       COMMENT '排序号，数值越大越靠后',
    is_deleted  TINYINT      NOT NULL DEFAULT 0       COMMENT '逻辑删除：0=正常，1=删除',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id) USING BTREE,
    INDEX idx_parent_id (parent_id) USING BTREE,
    INDEX idx_course_id (course_id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='课程章节表';

-- ===================================================================
-- 2. 学期表
-- ===================================================================
CREATE TABLE IF NOT EXISTS semester (
    id             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '学期ID，主键自增',
    semester_name  VARCHAR(100) NOT NULL                  COMMENT '学期名称',
    start_date     DATE         NOT NULL                  COMMENT '开始日期',
    end_date       DATE         NOT NULL                  COMMENT '结束日期',
    is_deleted     TINYINT      NOT NULL DEFAULT 0       COMMENT '逻辑删除：0=正常（启用），1=删除（禁用）',
    create_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='学期表';

-- ===================================================================
-- 3. 课程表
-- ===================================================================
CREATE TABLE IF NOT EXISTS course (
    id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '课程ID，主键自增',
    course_name   VARCHAR(200) NOT NULL                  COMMENT '课程名称',
    course_code   VARCHAR(50)  NOT NULL                  COMMENT '课程编码',
    credit        INT          NOT NULL DEFAULT 0       COMMENT '学分',
    semester_id   BIGINT       NOT NULL DEFAULT 0       COMMENT '关联学期ID',
    is_deleted    TINYINT      NOT NULL DEFAULT 0       COMMENT '逻辑删除：0=正常（启用），1=删除（禁用）',
    create_time   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id) USING BTREE,
    INDEX idx_semester_id (semester_id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='课程表';

-- ===================================================================
-- 4. 系统配置表（存储全局生效学期、生效课程等配置）
-- ===================================================================
CREATE TABLE IF NOT EXISTS system_config (
    id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键ID，自增',
    config_key   VARCHAR(100) NOT NULL                  COMMENT '配置键',
    config_value VARCHAR(500) NOT NULL DEFAULT ''       COMMENT '配置值',
    config_desc  VARCHAR(200) DEFAULT NULL              COMMENT '配置描述',
    create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id) USING BTREE,
    UNIQUE INDEX uk_config_key (config_key) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='系统配置表';

-- ===================================================================
-- 初始化系统配置数据
-- ===================================================================
INSERT INTO system_config (config_key, config_value, config_desc) VALUES ('active_semester', '', '当前生效学期ID');
INSERT INTO system_config (config_key, config_value, config_desc) VALUES ('active_course', '', '当前生效课程ID');
