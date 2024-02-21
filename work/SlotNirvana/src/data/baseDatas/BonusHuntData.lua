--[[--
    集卡促销：商店购买双倍送卡活动
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BonusHuntData = class("BonusHuntData", BaseActivityData)

function BonusHuntData:ctor()
    BonusHuntData.super.ctor(self)
end
-- optional string activityId = 1; //活动id
-- optional string activityName = 2; //活动名称
-- repeated string gameIds = 3; //关卡ID
-- optional int64 expireAt = 4; //截止时间
-- optional int64 expire = 5; //剩余时间
-- optional bool completed = 6; //完成标识
-- optional bool reward = 7; //奖励发放标识
-- optional int32 type = 8; //任务类型0：无进度，1：有进度gameId
-- repeated int64 params = 9; //任务参数
-- repeated int64 process = 10; //任务进度
function BonusHuntData:parseData(data)
    BonusHuntData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)
    self.p_expire = tonumber(data.expire)
    if self.p_completed ~= nil and self.p_completed == false and data.completed == true then
        self.p_spinComplete = true
    -- else
    -- self.p_spinComplete = false
    end
    self.p_completed = data.completed
    self.p_gameIds = {}
    for i = 1, #data.gameIds do
        self.p_gameIds[#self.p_gameIds + 1] = tonumber(data.gameIds[i])
    end

    self.p_reward = data.reward
    self.p_type = data.type
    self.p_params = data.params
    self.p_process = data.process
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUSHUNT_UPDATE)
end

function BonusHuntData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function BonusHuntData:isBonusHuntLevel(gameId)
    local isBonusLevel = false
    if not self.p_gameIds then
        return isBonusLevel
    end
    for i = 1, #self.p_gameIds do
        if self.p_gameIds[i] == gameId then
            isBonusLevel = true
            break
        end
    end
    return isBonusLevel
end
-- function BonusHuntData:setExpire(t)
--     self.p_expire = t
-- end
function BonusHuntData:isShowResult()
    return self.p_spinComplete
end

function BonusHuntData:isExist()
    if self.p_expire and self.p_expire > 0 then
        return true
    end
    return false
end

function BonusHuntData:isOpen()
    if not self.p_expireAt then
        return false
    end
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return (self.p_expireAt / 1000) >= curTime
end

return BonusHuntData
