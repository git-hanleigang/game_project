--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-09 10:41:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-09 11:25:56
FilePath: /SlotNirvana/src/GameModule/FloatView/config/SlotLeftFloatCfg.lua
Description: 关卡左边条配置
--]]
local SlotLeftFloatCfg = {}

-- 子节点显示最大数
SlotLeftFloatCfg.SHOW_MAX_CHILD_COUNT = 5

-- 左边条显示状态
SlotLeftFloatCfg.SHOW_TYPE = {
	FOLD = "FOLD", --折叠
	UNFOLD = "UNFOLD", --展开
}

--游戏内左边活动图标显示顺序
SlotLeftFloatCfg.SpecialEntryOrders = {}
-- 关卡左侧条显示顺序
local tbEntryOrders = {
    "IcebreakerSaleEntryNode",
    "Activity_TreasureHunt",
    "Activity_NoviceTrail",
    "CardStatueGame",
    "CardSeekerGame",
    "ReturnSignEntryNode",
    "LevelRoadEntryNode",
    "Activity_LuckyRace",
    "Activity_JewelMania",
    "Activity_HolidayNewChallenge",
    "Activity_HolidayChallenge",
    "Activity_Minz",
    "Activity_DiyFeature",
    "Activity_DIYFeatureMission",
    "Activity_CrazyWheel",
    "Activity_Zombie",
    -- "GrowthFundEntryNode",
    "HourDealEntryNode",
    "BestDealEntryNode",
    "Activity_ChaseForChips",
    "Activity_PipeConnect",
    "Activity_FactionFight",
    "Activity_DragonChallenge",
    "Activity_SlotTrials",
    "Activity_SpinItem",
    "Activity_BattleMatch",
    "TrillionChallenge", -- 亿万赢钱挑战
    "ClanDuelEntryNode", --公会对决入口
    -- "Activity_FindItem",
    "Activity_OutsideCave",
    "Activity_Bingo",
    "Activity_CoinPusher",
    "Activity_NewCoinPusher",
    "Activity_EgyptCoinPusher",
    "Activity_RichMan",
    "Activity_DinnerLand",
    "Activity_DiningRoom",
    "Activity_Blast",
    "Activity_Word",
    "Activity_Redecor",
    "Activity_Poker",
    "Activity_WorldTrip",
    "Activity_BalloonRush",
    "Activity_Quest",
    "Activity_QuestNewUserCode",
    "SidekicksEntryNode",
    "Leagues",
    "Activity_BattlePass",
    "AvatarFrameSysEntryNode", --头像框系统
    "ClanEntryNode", -- 公会入口属于常驻功能放到前边
    "Activity_NewPass",
}
for key, value in ipairs(tbEntryOrders) do
    SlotLeftFloatCfg.SpecialEntryOrders[value] = key
end

-- 左边条要添加的系统功能 
SlotLeftFloatCfg.SYS_ENTRY_LIST = {
    {refName = G_REF.HourDeal, viewRefKey = "HourDealEntryNode"},
    {refName = G_REF.LeagueCtrl, viewRefKey = "Leagues"},
    {refName = G_REF.CardSeeker, viewRefKey = "CardSeekerGame"},
    {refName = G_REF.AvatarFrame, viewRefKey = "AvatarFrameSysEntryNode"},
    {refName = G_REF.BestDeal, viewRefKey = "BestDealEntryNode"},
    {refName = G_REF.LevelRoad, viewRefKey = "LevelRoadEntryNode"},
    {refName = G_REF.TrillionChallenge, viewRefKey = "TrillionChallenge"},
    {refName = G_REF.Return, viewRefKey = "ReturnSignEntryNode"},
    {refName = G_REF.Sidekicks, viewRefKey = "SidekicksEntryNode"},
}


-- 左边条收起状态：只显示一个入口图标和展开按钮，入口显示顺序为：优先显示有红点的系统图标，当同时存在多个有红点的系统图标时，
-- 鲨鱼游戏＞minz活动 ＞DIY活动＞红蓝对决（个人社交型比赛活动）>公会限时比赛（团体社交型比赛活动）>新关挑战>QUEST>通用大活动>PASS>公会>其他
local BigActEntryNodeConifg = util_require("baseActivity.ActivityExtra.EntryNodeConfig")
local BigActRefNameList = table.keys(BigActEntryNodeConifg.data_config or {})
SlotLeftFloatCfg.SmallEntryShowOrderMap = {}
local tableJoins = function(...)
    local tb = {}
    for _, v in pairs{...} do
        if type(...) == "table" then
            table.insertto(tb, v)
        else
            table.insertto(tb, {v})
        end
    end
    return tb
end 
local entryList = tableJoins(
    {
        "CardStatueGame",
        "CardSeekerGame",
        "Activity_Minz",
        "Activity_DiyFeature",
        "Activity_DIYFeatureMission",
        "Activity_FactionFight",
        "ClanDuelEntryNode",
        "Activity_SlotTrials",
        "Activity_Quest",
    },
    BigActRefNameList,
    {
        "Activity_NewPass",
        "ClanEntryNode",
    }
)
for key, value in ipairs(entryList) do
    SlotLeftFloatCfg.SmallEntryShowOrderMap[value] = key
end

-- 事件
SlotLeftFloatCfg.EVENT_NAME = {
    NOTIFY_SWITCH_LEFT_FLOAT_SHOW_TYPE = "NOTIFY_SWITCH_LEFT_FLOAT_SHOW_TYPE", --改变关卡左边条显示类型
    UPDATE_SLOT_LEFT_ENTRY_VIEW = "UPDATE_SLOT_LEFT_ENTRY_VIEW", -- 更新关卡左边条
}

return SlotLeftFloatCfg