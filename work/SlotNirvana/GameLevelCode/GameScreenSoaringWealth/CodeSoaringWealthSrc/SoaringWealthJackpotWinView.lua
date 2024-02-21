---
--SoaringWealthJackpotWinView.lua

local SoaringWealthJackpotWinView = class("SoaringWealthJackpotWinView",util_require("Levels.BaseLevelDialog"))
local SoaringWealthMusicConfig = require "CodeSoaringWealthSrc.SoaringWealthMusicConfig"

SoaringWealthJackpotWinView.m_machine = nil
SoaringWealthJackpotWinView.m_rewardCoins = 0
SoaringWealthJackpotWinView.m_callFunc = nil
SoaringWealthJackpotWinView.m_clickStateFunc = nil
SoaringWealthJackpotWinView.m_cilck = false

function SoaringWealthJackpotWinView:initUI(_m_machine)

    self:createCsbNode("SoaringWealth/JackpotWinView.csb")
    
    self.m_machine = _m_machine

    self.m_dragonSpine = util_spineCreate("Socre_SoaringWealth_Wild",true,true)
    self:findChild("long"):addChild(self.m_dragonSpine)

    self.m_rewardName = {}
    self.m_rewardName[1] = self:findChild("Mini")
    self.m_rewardName[2] = self:findChild("Minor")
    self.m_rewardName[3] = self:findChild("Major")
    self.m_rewardName[4] = self:findChild("Mega")
    self.m_rewardName[5] = self:findChild("Grand")

    self.textReward = self:findChild("m_lb_coins")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function SoaringWealthJackpotWinView:onExit()
    SoaringWealthJackpotWinView.super.onExit(self)
end

function SoaringWealthJackpotWinView:refreshRewardType(_reward, _clickStateFunc, _callFunc)
    self:createGrandShare(self.m_machine)
    self.m_callFunc = _callFunc
    self.m_clickStateFunc = _clickStateFunc
    self.m_rewardCoins = _reward[2]
    local strCoins=util_formatCoins(_reward[2],50)
    self.textReward:setString(strCoins)
    self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},577)
    
    for i=1, 5 do
        if _reward[1] == i then
            self.m_rewardName[i]:setVisible(true)
        else
            self.m_rewardName[i]:setVisible(false)
        end
    end
    util_spinePlay(self.m_dragonSpine,"start",false)
    performWithDelay(self.m_scWaitNode, function()
        util_spinePlay(self.m_dragonSpine,"idle_tanban",true)
    end, 30/30)
    
    self.jackpotIndex = 5 - _reward[1] + 1
    
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_rewardCoins, self.jackpotIndex)
end

--默认按钮监听回调
function SoaringWealthJackpotWinView:clickFunc(sender)
    local name = sender:getName()

    if name == "Button_1" and self:getClickState() then
        self:hideSelf()
    end
end

function SoaringWealthJackpotWinView:hideSelf()
    local bShare = self:checkShareState()
    if not bShare then
        self:jackpotViewOver(function()
            self:setClickState(false)
            gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_jackpotOver)
            self:runCsbAction("over", false, function()
                if self.m_callFunc then
                    self.m_callFunc()
                    self.m_callFunc = nil
                end
                if self.m_clickStateFunc then
                    self.m_clickStateFunc()
                    self.m_clickStateFunc = nil
                end
                self:setVisible(false)
            end)
        end)
    end
end

function SoaringWealthJackpotWinView:setJumpCoinsOver()
    self:jumpCoinsFinish()
end

function SoaringWealthJackpotWinView:setClickState(_state)
    self.m_cilck = _state
end

function SoaringWealthJackpotWinView:getClickState()
    return self.m_cilck
end

--[[
    自动分享 | 手动分享
]]
function SoaringWealthJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function SoaringWealthJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.jackpotIndex)
    end
end

function SoaringWealthJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function SoaringWealthJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return SoaringWealthJackpotWinView
