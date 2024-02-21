--[[
    author:{author}
    time:2019-04-18 21:53:40
]]

local MissionTaskRunData = class("MissionTaskRunData")
local CommonRewards = require "data.baseDatas.CommonRewards"
local ShopItem = util_require("data.baseDatas.ShopItem")

MissionTaskRunData.p_taskType = nil         -- 任务类型
MissionTaskRunData.p_taskParams = nil       -- 任务参数
MissionTaskRunData.p_taskRewards = nil      -- 任务奖励
MissionTaskRunData.p_taskBuff = nil         -- 任务Buff
MissionTaskRunData.p_taskPoint = nil        -- 任务点数
MissionTaskRunData.p_taskDescription = nil  -- 任务描述
MissionTaskRunData.p_taskId = nil           -- 任务ID
MissionTaskRunData.p_taskCoin = nil
MissionTaskRunData.p_taskExpireAt = nil     -- 到期时间戳
MissionTaskRunData.p_taskCompleted = nil    -- 是否完成
MissionTaskRunData.p_taskCollected = nil    -- 是否领取
MissionTaskRunData.p_taskProcess = nil      -- 任务进度
MissionTaskRunData.p_difficulty = nil       -- 任务难度
MissionTaskRunData.p_taskExpire = nil       -- 剩余时间
MissionTaskRunData.p_commonReward = nil     -- 任务奖励道具
MissionTaskRunData.p_clanRewards = nil       --任务工会点数奖励

function MissionTaskRunData:ctor( )

end

function MissionTaskRunData:parseData( data )
    self.p_taskType = tonumber(data.type)           -- 任务类型
    self.p_taskParams = data.params                 -- 任务参数
    self.p_taskRewards = data.rewards               -- 任务奖励
    self.p_taskBuff = data.buff                     -- 任务Buff
    self.p_taskPoint = data.points                  -- 任务点数
    self.p_taskDescription = data.description       --  任务描述
    self.p_taskId = data.taskId                     -- 任务ID
    self.p_taskCoin = data.cions
    self.p_taskExpireAt = tonumber(data.expireAt)   -- 到期时间戳
    self.p_taskCompleted = data.completed           -- 是否完成
    self.p_taskCollected = data.collected           -- 是否领取
    self.p_taskProcess = data.process or {}              -- 任务进度
    self.p_difficulty = data.difficulty             -- 任务难度
    self.p_taskExpire = tonumber(data.expire)       -- 剩余时间
    if self.p_vecShowTipOver == nil then
        self.p_vecShowTipOver = {}
    end
    if self.p_vecShowTipOver[self.p_taskDescription] ~= true then
        self.p_vecShowTipOver[self.p_taskDescription] = false
    end
    if data.icon then
        self.p_icon = data.icon                          -- 图标
    end

    -- csc 每日任务返回优化
    if data:HasField("commonReward") then
        local config = CommonRewards:create()
        config:parseData(data.commonReward)
        self.p_commonReward = config
    end

    self.p_clanRewards = {}
    if #data.clanRewards > 0 then
        for i = 1, #data.clanRewards do
            local _item = ShopItem:create()
            _item:parseData(data.clanRewards[i])
            table.insert(self.p_clanRewards, _item)
        end
    end
end

function MissionTaskRunData:getTaskDescription()
    local tipStr = self.p_taskDescription
    if #self.p_taskParams == 1 then
        -- tipStr = string.format(tipStr, util_getFromatMoneyStr(self.p_taskParams[1]))
        tipStr = string.format(tipStr, util_formatCoins(tonumber(self.p_taskParams[1]),3,nil,nil,nil,true))
    elseif #self.p_taskParams == 2 then
        -- tipStr = string.format(tipStr, util_getFromatMoneyStr(self.p_taskParams[1]), util_getFromatMoneyStr(self.p_taskParams[2]))
        tipStr = string.format(tipStr, util_formatCoins(tonumber(self.p_taskParams[1]),3,nil,nil,nil,true), util_formatCoins(tonumber(self.p_taskParams[2]),3,nil,nil,nil,true))
    elseif #self.p_taskParams == 3 then
        tipStr = string.format(tipStr, util_formatCoins(tonumber(self.p_taskParams[1]),3,nil,nil,nil,true), util_formatCoins(tonumber(self.p_taskParams[2]),3,nil,nil,nil,true),util_formatCoins(tonumber(self.p_taskParams[3]),3,nil,nil,nil,true))
    end
    return tipStr
end

function MissionTaskRunData:getTaskSchedule()
    if self.p_taskType == 1006 or self.p_taskType == 1007 or self.p_taskType == 2006 then
        return (self.p_taskProcess[2] or 0), self.p_taskParams[2]
    -- elseif self.p_taskType == 1011 then

    else
        return (self.p_taskProcess[1] or 0), self.p_taskParams[1]
    end
end
--是否是完成可领取状态
function MissionTaskRunData:checkCanCollect()
    if  self.p_taskCompleted == true and self.p_taskCollected == false then
        return true
    end
    return false
end

function MissionTaskRunData:getCommonReward()
    return self.p_commonReward
end

function MissionTaskRunData:getClanReward()
    return self.p_clanRewards
end
return MissionTaskRunData