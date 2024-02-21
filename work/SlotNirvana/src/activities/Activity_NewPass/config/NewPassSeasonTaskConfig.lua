--[[
    @desc: new pass pass 任务
    author:csc
    time:2021-06-23 21:52:56
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local NewPassSeasonTaskConfig = class("NewPassSeasonTaskConfig")
local MissionTaskRunData = require "data.baseDatas.MissionTaskRunData" -- 通用每日任务
-- optional MissionTaskConfig task = 1; //任务信息
-- optional int32 gems = 2;
-- optional int64 passExp = 3;
-- optional bool inCd = 4;
function NewPassSeasonTaskConfig:ctor()
    -- 任务信息
    self.p_taskInfo = MissionTaskRunData:create()
    -- 花费gems
    self.m_gems = 0
    -- 可以获得的pass经验
    self.m_passExp = 0
    -- 是否在cd时间内
    self.m_bCdTime = false
    self.m_refreshGems = 0
end

function NewPassSeasonTaskConfig:parseData(data)
    if not data then
        return
    end
    -- 任务信息
    self.p_taskInfo:parseData(data.task)
    -- 花费gems
    self.m_gems = data.gems
    -- 可以获得的pass经验
    self.m_passExp = tonumber(data.passExp)
    -- 是否在cd时间内
    self.m_bCdTime = data.inCd

    self.m_refreshGems = tonumber(data.refreshGems)

    print("----csc NewPassSeasonTaskConfig parseData over")
end

function NewPassSeasonTaskConfig:getTaskInfo()
    return self.p_taskInfo
end

function NewPassSeasonTaskConfig:getNeedGems()
    return self.m_gems
end

function NewPassSeasonTaskConfig:getPassExp()
    return self.m_passExp
end

function NewPassSeasonTaskConfig:getInCd()
    return self.m_bCdTime
end

function NewPassSeasonTaskConfig:getLeftTimeForPage()
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    local passExpireAt = passActData:getExpireAt()

    local expireAt = (self.p_taskInfo.p_taskExpireAt or 0) / 1000
    local leftTime = math.max(expireAt, 0)
    -- 跟主活动时间做一次比较 取小值
    local leftTime = math.min(passExpireAt,expireAt)
    local dayStr,isOver = util_daysdemaining(leftTime,true)
    return dayStr,isOver
end

function NewPassSeasonTaskConfig:getLeftTime()
    local expireAt = (self.p_taskInfo.p_taskExpireAt or 0) / 1000
    local leftTime = math.max(expireAt, 0)
    local dayTime = leftTime - globalData.userRunData.p_serverTime / 1000
    local weekTime = 0

    if dayTime <= 0 then
        dayTime = 0
    end

    if dayTime == 0 then
        -- 刷新下一个任务
        gLobalDailyTaskManager:sendQuerySeasonMission()
    end
    return dayTime, weekTime
end

return NewPassSeasonTaskConfig
