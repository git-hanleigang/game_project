-- 排名状态
GD.LuckyRaceRankStatus = {
    Up = "UP",
    Down = "DOWN",
    Same = "SAME"
}

-- 单人限时比赛 相关事件
ViewEventType.NOTIFY_LUCKY_RACE_DATA_REFRESH = "NOTIFY_LUCKY_RACE_DATA_REFRESH" -- 请求接口数据刷新
ViewEventType.NOTIFY_LUCKY_RACE_COLLECT_REWARD = "NOTIFY_LUCKY_RACE_COLLECT_REWARD" -- 收集奖励
ViewEventType.NOTIFY_LUCKY_RACE_BUY_BUFF = "NOTIFY_LUCKY_RACE_BUY_BUFF" -- 购买buff
ViewEventType.NOTIFY_LUCKY_RACE_RANK_UPDATE = "NOTIFY_LUCKY_RACE_RANK_UPDATE" -- 排名更新
ViewEventType.NOTIFY_LUCKY_RACE_CUR_ROUND_ACTIVE = "NOTIFY_LUCKY_RACE_CUR_ROUND_ACTIVE" -- 本轮比赛手动激活成功
