---
--SpacePupJackpotWinView.lua

local SpacePupJackpotWinView = class("SpacePupJackpotWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "SpacePupPublicConfig"

SpacePupJackpotWinView.m_machine = nil
SpacePupJackpotWinView.m_rewardCoins = 0
SpacePupJackpotWinView.m_callFunc = nil
SpacePupJackpotWinView.m_cilck = false

function SpacePupJackpotWinView:initUI(_m_machine)

    self:createCsbNode("SpacePup/JackpotWinView.csb")
    
    self.m_machine = _m_machine

    self.m_tblDogSpine = {}
    self.m_tblDogSpine[1] = util_spineCreate("Socre_SpacePup_7",true,true)
    self:findChild("langou"):addChild(self.m_tblDogSpine[1])
    util_spinePlay(self.m_tblDogSpine[1],"idle",true)

    self.m_tblDogSpine[2] = util_spineCreate("Socre_SpacePup_8",true,true)
    self:findChild("zigou"):addChild(self.m_tblDogSpine[2])
    util_spinePlay(self.m_tblDogSpine[2],"idle",true)

    self.m_tblDogSpine[3] = util_spineCreate("Socre_SpacePup_9",true,true)
    self:findChild("huanggou"):addChild(self.m_tblDogSpine[3])
    util_spinePlay(self.m_tblDogSpine[3],"idle",true)

    local lightAni = util_createAnimation("SpacePup_JackpotWinView_guang.csb")
    self:findChild("guang"):addChild(lightAni)
    lightAni:runCsbAction("idleframe", true)

    self.m_rewardName = {}
    self.m_rewardName[1] = self:findChild("Node_grand")
    self.m_rewardName[2] = self:findChild("Node_mega")
    self.m_rewardName[3] = self:findChild("Node_major")
    self.m_rewardName[4] = self:findChild("Node_minor")
    self.m_rewardName[5] = self:findChild("Node_mini")

    self.textReward = self:findChild("m_lb_coins")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_particleLoop = {}
    for i=1, 2 do
        self.m_particleLoop[i] = self:findChild("Particle_2_"..i)
        self.m_particleLoop[i]:setPositionType(0)
        self.m_particleLoop[i]:setDuration(-1)
        self.m_particleLoop[i]:resetSystem()
    end

    self.particleTbl = {}
    for i=1, 4 do
        self.particleTbl[i] = self:findChild("Particle_"..i)
    end
    performWithDelay(self.m_scWaitNode, function()
        for i=1, 4 do
            self.particleTbl[i]:resetSystem()
            -- self.particleTbl[i]:stopSystem()
        end
    end, 15/60)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function SpacePupJackpotWinView:onExit()
    SpacePupJackpotWinView.super.onExit(self)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

function SpacePupJackpotWinView:refreshRewardType(_jackpotInfo, _mainMachine, _callFunc)
    self.isHide = false
    local jackpotInfo = _jackpotInfo
    self:createGrandShare(_mainMachine)
    self.m_jackpotType = 5 - jackpotInfo.column
    if jackpotInfo.jackName == "Mini" then
        self.m_jackpotType = 5
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MiniReward)
    elseif jackpotInfo.jackName == "Minor" then
        self.m_jackpotType = 4
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MinorReward)
    elseif jackpotInfo.jackName == "Major" then
        self.m_jackpotType = 3
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MajorReward)
    elseif jackpotInfo.jackName == "Mega" then
        self.m_jackpotType = 2
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_MegaReward)
    elseif jackpotInfo.jackName == "Grand" then
        self.m_jackpotType = 1
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_GrandReward)
    end
    
    self.m_callFunc = _callFunc
    self.m_rewardCoins = jackpotInfo.winCoins
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Coins)
    self:jumpCoins(self.m_rewardCoins)

    for i=1, 5 do
        if self.m_jackpotType == i then
            self.m_rewardName[i]:setVisible(true)
        else
            self.m_rewardName[i]:setVisible(false)
        end
    end
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_rewardCoins, self.m_jackpotType)
end

--默认按钮监听回调
function SpacePupJackpotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" and self:getClickState() then
        local bShare = self:checkShareState()
        if not bShare then
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil

                if self.m_soundId then
                    gLobalSoundManager:stopAudio(self.m_soundId)
                    self.m_soundId = nil
                end
                gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)

                self.textReward:setString(util_formatCoins(self.m_rewardCoins,50))
                self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},645)

                self:jumpCoinsFinish()

                performWithDelay(self.m_scWaitNode,function(  )
                    self:hideSelf(true)
                end,1.5)
            else
                gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
                self:hideSelf(true)
            end
        end
    end
end

function SpacePupJackpotWinView:hideSelf(hideState)
    if self.isHide then
        return
    end
    self:jackpotViewOver(function()
        for i=1, 2 do
            self.m_particleLoop[i]:stopSystem()
        end
        self.isHide = hideState
        self:setClickState(false)
        -- globalData.coinsSoundType = 1
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_DialogOver)
        self:runCsbAction("over", false, function()
            if type(self.m_callFunc) == "function" then
                self.m_callFunc()
            end
            self:removeFromParent()
        end)
    end)
end

function SpacePupJackpotWinView:setClickState(_state)
    self.m_cilck = _state
end

function SpacePupJackpotWinView:getClickState()
    return self.m_cilck
end

function SpacePupJackpotWinView:jumpCoins(coins )
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
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},645)

            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end

            self:jumpCoinsFinish()

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
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},645)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function SpacePupJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function SpacePupJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotType)
    end
end

function SpacePupJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function SpacePupJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return SpacePupJackpotWinView
