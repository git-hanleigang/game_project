---
--WickedWinsJackpotWinView.lua

local WickedWinsMusicConfig = require "WickedWinsPublicConfig"
local WickedWinsJackpotWinView = class("WickedWinsJackpotWinView",util_require("Levels.BaseLevelDialog"))

WickedWinsJackpotWinView.m_machine = nil
WickedWinsJackpotWinView.m_rewardCoins = 0
WickedWinsJackpotWinView.m_callFunc = nil
WickedWinsJackpotWinView.m_cilck = false

function WickedWinsJackpotWinView:initUI(_m_machine)

    self:createCsbNode("WickedWins/JackpotWinView.csb")
    
    self.m_machine = _m_machine
    
    self.m_roleSpine = util_spineCreate("WickedWins_tanban",true,true)
    self:findChild("juese1"):addChild(self.m_roleSpine)

    self.m_rewardName = {}
    self.m_rewardName[1] = self:findChild("mini")
    self.m_rewardName[2] = self:findChild("minor")
    self.m_rewardName[3] = self:findChild("major")
    self.m_rewardName[4] = self:findChild("grand")

    self.textReward = self:findChild("m_lb_coins")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function WickedWinsJackpotWinView:onExit()
    WickedWinsJackpotWinView.super.onExit(self)
end

function WickedWinsJackpotWinView:refreshRewardType(_rewardType, _rewardCoins, mainMachine, _callFunc)
    self:createGrandShare(mainMachine)
    util_spinePlay(self.m_roleSpine,"jackpot_start",false)
    self.m_callFunc = _callFunc
    self.m_rewardCoins = _rewardCoins
    self.m_jackpotIndex = 4 - _rewardType + 1
    -- local strCoins=util_formatCoins(self.m_rewardCoins, 50)
    self.textReward:setString(0)
    self:updateRewardCoins()
    -- self:updateLabelSize({label=self.textReward,sx=1.01,sy=1.0},653)
    for i=1, 4 do
        if _rewardType == i then
            self.m_rewardName[i]:setVisible(true)
        else
            self.m_rewardName[i]:setVisible(false)
        end
    end
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_rewardCoins, self.m_jackpotIndex)
end

function WickedWinsJackpotWinView:updateRewardCoins()
    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Jackpot_RollCoins)
    local delayTime = 1.0
    local addCoins = self.m_rewardCoins/delayTime/60
    local curCoins = 0
    local curRunTime = 0
    util_schedule(self.m_scWaitNode, function()
        curRunTime = curRunTime + 1/60
        if curRunTime < delayTime then
            curCoins = curCoins + addCoins
            local strCoins=util_formatCoins(curCoins, 50)
            self.textReward:setString(strCoins)
            self:updateLabelSize({label=self.textReward,sx=1.01,sy=1.0},653)
        else
            local strCoins=util_formatCoins(self.m_rewardCoins, 50)
            self.textReward:setString(strCoins)
            self:updateLabelSize({label=self.textReward,sx=1.01,sy=1.0},653)
            self.m_scWaitNode:stopAllActions()
            self:setClickState(true)
            self:jumpCoinsFinish()
        end
    end, 1/60)
end
--self.m_lb_coins_big:setString(util_getFromatMoneyStr(self.m_llGrowCoinNum))

--默认按钮监听回调
function WickedWinsJackpotWinView:clickFunc(sender)
    local name = sender:getName()

    if name == "Button" and self:getClickState() then
        self:hideSelf()
    end
end

function WickedWinsJackpotWinView:hideSelf()
    local bShare = self:checkShareState()
    if not bShare then
        self:jackpotViewOver(function()
            self:setClickState(false)
            util_spinePlay(self.m_roleSpine,"jackpot_over",false)
            self:runCsbAction("over", false, function()
                if self.m_callFunc then
                    self.m_callFunc()
                    self.m_callFunc = nil
                end
                self:setVisible(false)
            end)
        end)
    end
end

function WickedWinsJackpotWinView:setSpineIdle()
    util_spinePlay(self.m_roleSpine,"jackpot_idle",true)
end

function WickedWinsJackpotWinView:setClickState(_state)
    self.m_cilck = _state
end

function WickedWinsJackpotWinView:getClickState()
    return self.m_cilck
end

--[[
    自动分享 | 手动分享
]]
function WickedWinsJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WickedWinsJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function WickedWinsJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WickedWinsJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WickedWinsJackpotWinView
