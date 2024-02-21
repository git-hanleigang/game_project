---
--SpacePupBonusPickWinView.lua

local SpacePupBonusPickWinView = class("SpacePupBonusPickWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "SpacePupPublicConfig"

SpacePupBonusPickWinView.m_machine = nil
SpacePupBonusPickWinView.m_rewardCoins = 0
SpacePupBonusPickWinView.m_callFunc = nil
SpacePupBonusPickWinView.m_cilck = false

function SpacePupBonusPickWinView:initUI(_m_machine)

    self:createCsbNode("SpacePup/PickOver.csb")
    
    self.m_machine = _m_machine

    self.textReward = self:findChild("m_lb_coins")

    local lightAni = util_createAnimation("SpacePup_FreeSpinOver_guang.csb")
    self:findChild("guang"):addChild(lightAni)
    lightAni:runCsbAction("idleframe", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function SpacePupBonusPickWinView:onExit()
    SpacePupBonusPickWinView.super.onExit(self)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

function SpacePupBonusPickWinView:refreshRewardType(_rewardCoins, _callFunc)
    self.isHide = false
    local rewardCoins = _rewardCoins
    
    self.m_callFunc = _callFunc
    self.m_rewardCoins = _rewardCoins
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Coins)
    self:jumpCoins(self.m_rewardCoins)
end

--默认按钮监听回调
function SpacePupBonusPickWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" and self:getClickState() then
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)

            self.textReward:setString(util_formatCoins(self.m_rewardCoins,50))
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},631)

            performWithDelay(self.m_scWaitNode,function(  )
                self:hideSelf(true)
            end,1.5)
        else
            gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
            self:hideSelf(true)
        end
    end
end

function SpacePupBonusPickWinView:hideSelf(hideState)
    if self.isHide then
        return
    end
    self:setClickState(false)
    -- globalData.coinsSoundType = 1
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalSoundManager:playSound(PublicConfig.Music_Pick_OverOver)
    self:runCsbAction("over", false, function()
        if self.m_callFunc then
            self.m_callFunc()
            self.m_callFunc = nil
        end
        self:setVisible(false)
    end)
end

function SpacePupBonusPickWinView:jumpCoins(coins )
    self.textReward:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins
            
            self.textReward:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},631)

            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
        else
            self.textReward:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},631)
        end
    end)
end

function SpacePupBonusPickWinView:setClickState(_state)
    self.m_cilck = _state
end

function SpacePupBonusPickWinView:getClickState()
    return self.m_cilck
end

return SpacePupBonusPickWinView
