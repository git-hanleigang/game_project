--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-11 18:08:21
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 11:04:47
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/tournament/TrillionChallengeBoxUI.lua
Description: 亿万赢钱挑战 宝箱 UI
--]]
local TrillionChallengeBoxUI = class("TrillionChallengeBoxUI", BaseView)

function TrillionChallengeBoxUI:initDatas(_taskData)
    TrillionChallengeBoxUI.super.initDatas(self)

    self._taskData = _taskData
    self._idx = self._taskData:getTaskOrder()
end

function TrillionChallengeBoxUI:getCsbName()
    return string.format("Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main_box_%d.csb", self._idx)
end

function TrillionChallengeBoxUI:initUI() 
    TrillionChallengeBoxUI.super.initUI(self)

    -- 点数
    self:initPointUI()
    -- 气泡
    self:initBubbleUI()
    -- 宝箱状态
    self:updateBoxState()
end

-- 点数
function TrillionChallengeBoxUI:initPointUI()
    local lbPoint = self:findChild("lb_reward")
    local point = self._taskData:getTaskParam()
    lbPoint:setString(util_formatCoins(point, 3))
end

-- 气泡
function TrillionChallengeBoxUI:initBubbleUI()
    local parnet = self:findChild("node_tip")
    local itemList = self._taskData:getTaskItems()
    local bubbleView = util_createView("GameModule.TrillionChallenge.views.tournament.TrillionChallengeBubbleUI", self._idx, itemList)
    parnet:addChild(bubbleView)
    self._bubbleView = bubbleView
end

-- 宝箱状态
function TrillionChallengeBoxUI:updateBoxState(_taskData)
    if _taskData then
        self._taskData = _taskData
    end
    local bHadCol = self._taskData:checkHadCol()
    local actName = bHadCol and "idle2" or "idle1"
    self:runCsbAction(actName)
end

function TrillionChallengeBoxUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" and self._bubbleView then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self._bubbleView:switchShowState()
    end
end

return TrillionChallengeBoxUI