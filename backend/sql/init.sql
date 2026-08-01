-- 用户角色分配模块初始化 SQL（数据库名：cas）
-- 如果 cas 数据库已存在，可跳过 CREATE DATABASE / USE。

CREATE DATABASE IF NOT EXISTS cas
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE cas;

-- 1. users 用户表
CREATE TABLE IF NOT EXISTS users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL,
    password      VARCHAR(100) NOT NULL COMMENT '密码(BCrypt)',
    name          VARCHAR(50)  NOT NULL COMMENT '真实姓名',
    email         VARCHAR(100) DEFAULT NULL,
    user_type     VARCHAR(20)  NOT NULL,
    status        TINYINT      DEFAULT 1,
    temp_pwd_flag TINYINT      DEFAULT 0 COMMENT '临时密码标记 0=否 1=是',
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_username (username),
    CONSTRAINT chk_user_type   CHECK (user_type IN ('STUDENT','TEACHER','ADMIN','ASSISTANT')),
    CONSTRAINT chk_user_status CHECK (status IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2. roles 角色表
CREATE TABLE IF NOT EXISTS roles (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL,
    description VARCHAR(200) DEFAULT NULL,
    UNIQUE KEY uk_role_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

-- 3. user_roles 用户-角色关联表
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户-角色关联表';

-- 可选示例角色数据；如果角色已存在可忽略。
INSERT IGNORE INTO roles (name, description) VALUES
    ('管理员', '系统管理员'),
    ('教师', '教师角色'),
    ('学生', '学生角色'),
    ('助教', '助教角色');
