--[[
Author: cxc
Date: 2022-01-10 12:13:46
LastEditTime: 2022-01-10 13:57:28
LastEditors: your name
Description: Lottery乐透 挑战活动
FilePath: /SlotNirvana/src/activities/Activity_LotteryChallenge/controller/LotteryChallengeActMgr.lua
--]]
local LotteryChallengeActMgr = class("LotteryChallengeActMgr", BaseActivityControl)
local LotteryChallengeNet = util_require("activities.Activity_LotteryChallenge.net.LotteryChallengeNet")
local LotteryChallengeConfig = util_require("activities.Activity_LotteryChallenge.config.LotteryChallengeConfig")

function LotteryChallengeActMgr:ctor()
    LotteryChallengeActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LotteryChallenge)
end

-- 检查是否有未领奖的
function LotteryChallengeActMgr:checkHadUnGainReward()
    local data = self:getData()
    local taskList = data:getTaskList() 
    local taskCur = data:getTaskCur() --当前完成的任务
    for i, taskData in ipairs(taskList) do
        local taskNeed = taskData:getTaskNeed()
        local bCollected = taskData:isCollected() 
        if taskCur >= taskNeed and not bCollected then
            return true
        end
    end

    return false
end

-- 请求网路领奖
function LotteryChallengeActMgr:sendCollectReq()
    local successFunc = function()
        gLobalNoticManager:postNotification(LotteryChallengeConfig.EVENT_NAME.RECIEVE_COLLECT_LOTTERY_TASK_REWARD)
    end
    LotteryChallengeNet:getInstance():sendCollectReq(successFunc)
end

return LotteryChallengeActMgr
