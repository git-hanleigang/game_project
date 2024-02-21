--[[
Author: cxc
Date: 2022-03-24 10:25:08
LastEditTime: 2022-03-24 10:25:09
LastEditors: cxc
Description: 3日行为付费聚合活动   阶段最后任务节点
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/phaseView/WildChallengeActBaseEndNode.lua
--]]
local WildChallengeActBasePhaseNode = require("activities.Activity_WildChallenge.views.phaseViews.WildChallengeActBasePhaseNode")
local WildChallengeActBaseEndNode = class("WildChallengeActBaseEndNode", WildChallengeActBasePhaseNode)
local Config = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

function WildChallengeActBaseEndNode:checkIsEndPhaseNode()
    return true
end

function WildChallengeActBaseEndNode:updateState(_state, _over)
    self.m_state = _state

    local actName = "idle"
    local colorV = 255
    if _state == Config.TASK_STATE.LOCK then
        -- 未解锁
        self.m_aniLockObj:playAction("idle")
        colorV = 127
    elseif _state == Config.TASK_STATE.UNLOCK then
        -- 解锁
        self.m_aniLockObj:playAction("open", false, function()
            -- 解锁后 (判断完成还是 未完成)
            self:initState()
        end)
    else
    end

    self:runCsbAction(actName, true) 

    self:updateLockVisible()
    self:updateMissionTipVisible()
    self:updateBtnVisible()
    self.m_btn:setColor(cc.c3b(colorV, colorV, colorV))   
end

return WildChallengeActBaseEndNode