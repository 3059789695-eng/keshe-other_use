package net.lab1024.sa.admin.module.business.score.constant;

/**
 * 及格状态枚举
 */
public enum PassStatusEnum {

    FAIL(0, "不及格"),
    PASS(1, "及格");

    private final Integer value;
    private final String desc;

    PassStatusEnum(Integer value, String desc) {
        this.value = value;
        this.desc = desc;
    }

    public Integer getValue() {
        return value;
    }

    public String getDesc() {
        return desc;
    }

    public static String getDescByValue(Integer value) {
        for (PassStatusEnum e : values()) {
            if (e.getValue().equals(value)) {
                return e.getDesc();
            }
        }
        return "未知";
    }
}
