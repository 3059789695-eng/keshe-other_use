package net.lab1024.sa.admin.module.business.appeal.constant;

/**
 * 复议状态枚举
 */
public enum AppealStatusEnum {

    PENDING(1, "待审核"),
    APPROVED(2, "已通过"),
    REJECTED(3, "已驳回");

    private final Integer value;
    private final String desc;

    AppealStatusEnum(Integer value, String desc) {
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
        for (AppealStatusEnum e : values()) {
            if (e.getValue().equals(value)) {
                return e.getDesc();
            }
        }
        return "未知";
    }
}
