--[[
    author:徐袁
    time:2020-12-22 20:48:07
]]
-- 联赛榜单类型
GD.LeagueTopType = {
    League = 1,
    Award = 2,
    Divisions = 3
}

-- 联赛类型
GD.LeagueType = {
    SUMMIT = 1, -- 巅峰赛
    QUALIFIED = 2, -- 最高段位资格赛
    NORMAL = 3, -- 普通比赛
}

-- 排名状态
GD.LeagueRankStatus = {
    Up = "UP",
    Down = "DOWN",
    Same = "SAME"
}

-- 段位名称
GD.LeagueDivisionName = {
    "ROOKIE",
    "EXPERT I",
    "EXPERT II",
    "PRO I",
    "PRO II",
    "PRO III",
    "MASTER I",
    "MASTER II",
    "MASTER III",
    "LEGEND"
}
-- 结算板缩放
GD.LeagueFinalBoardScale = 0.75

-- 相关事件
-- 申请奖励成功
ViewEventType.NOTIFY_LEAGUE_REWARD_SUCCESS = "NOTIFY_LEAGUE_REWARD_SUCCESS"
-- 显示联赛排行榜
ViewEventType.NOTIFY_LEAGUE_RANK_SHOW = "NOTIFY_LEAGUE_RANK_SHOW"
-- 更新联赛排行数据
ViewEventType.NOTIFY_LEAGUE_RANK_UPDATE = "NOTIFY_LEAGUE_RANK_UPDATE"
-- 显示上一赛季排行榜
ViewEventType.NOTIFY_LEAGUE_LAST_SEASON_RANK_UPDATE = "NOTIFY_LEAGUE_LAST_SEASON_RANK_UPDATE"
-- 关闭主界面
ViewEventType.NOTIFY_LEAGUE_CLOSE_MAIN_LAYER = "NOTIFY_LEAGUE_CLOSE_MAIN_LAYER"
-- 检测领取上一赛季奖励
ViewEventType.NOTIFY_LEAGUE_CHECK_COLLECT_LAST_SEASON_REWARD = "NOTIFY_LEAGUE_CHECK_COLLECT_LAST_SEASON_REWARD"
-- 段位变化
ViewEventType.NOTIFY_LEAGUE_DIVISION_CHANGE = "NOTIFY_LEAGUE_DIVISION_CHANGE"
-- Spin获得奖杯
ViewEventType.NOTIFY_LEAGUE_SPIN_GAIN_CUP = "NOTIFY_LEAGUE_SPIN_GAIN_CUP"
-- 关卡比赛引导检查
ViewEventType.NOTIFY_LEAGUE_GUIDE_CHECK = "NOTIFY_LEAGUE_GUIDE_CHECK"
-- 关卡比赛引导步骤
ViewEventType.NOTIFY_LEAGUE_GUIDE_STEP = "NOTIFY_LEAGUE_GUIDE_STEP"
-- 引导结束
ViewEventType.NOTIFY_LEAGUE_GUIDE_OVER = "NOTIFY_LEAGUE_GUIDE_OVER"
-- 隐藏气泡
ViewEventType.NOTIFY_LEAGUE_HIDE_CELL_GIFT_BUBBLE = "NOTIFY_LEAGUE_HIDE_CELL_GIFT_BUBBLE"
-- 关卡比赛促销购买结构
ViewEventType.NOTIFY_LEAGUE_SALE_RESULT = "NOTIFY_LEAGUE_SALE_RESULT"
-- 显示最终排名名次
ViewEventType.NOTIFY_LEAGUE_SHOW_FINAL_RANK = "NOTIFY_LEAGUE_SHOW_FINAL_RANK"
-- 显示开礼盒
ViewEventType.NOTIFY_LEAGUE_SHOW_OPEN_GIFT = "NOTIFY_LEAGUE_SHOW_OPEN_GIFT"

-- 促销新增请求接口的成功失败回调
ViewEventType.NOTIFY_LEAGUE_SALE_SUCCESS = "NOTIFY_LEAGUE_SALE_SUCCESS"
ViewEventType.NOTIFY_LEAGUE_SALE_FAIL = "NOTIFY_LEAGUE_SALE_FAIL"
-- 飞行结束后促销节点特效
ViewEventType.NOTIFY_LEAGUE_LIGHTNING_ARRIVE = "NOTIFY_LEAGUE_LIGHTNING_ARRIVE"
-- 巅峰赛上一期top排名请求成功
ViewEventType.NOTIFY_LEAGUE_SUMMIT_LAST_TOP_RANK_UPDATE = "NOTIFY_LEAGUE_SUMMIT_LAST_TOP_RANK_UPDATE"
-- 跳过爬榜
ViewEventType.NOTIFY_LEAGUE_SKIP_CLIMB = "NOTIFY_LEAGUE_SKIP_CLIMB"
-- 检查显示比赛入口
ViewEventType.NOTIFY_LEAGUE_ENTRY_UPDATE = "NOTIFY_LEAGUE_ENTRY_UPDATE"