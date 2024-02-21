---
--MedusaManiaJackpotWinView.lua

local MedusaManiaJackpotWinView = class("MedusaManiaJackpotWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MedusaManiaPublicConfig"

MedusaManiaJackpotWinView.m_machine = nil
MedusaManiaJackpotWinView.m_rewardCoins = 0
MedusaManiaJackpotWinView.m_callFunc = nil
MedusaManiaJackpotWinView.m_cilck = false

function MedusaManiaJackpotWinView:initUI(_m_machine)

    self:createCsbNode("MedusaMania/JackpotWinView.csb")
    
    self.m_machine = _m_machine

    self.m_rewardName = {}
    self.m_rewardName[1] = self:findChild("Node_grand")
    self.m_rewardName[2] = self:findChild("Node_major")
    self.m_rewardName[3] = self:findChild("Node_minor")
    self.m_rewardName[4] = self:findChild("Node_mini")

    self.textReward = self:findChild("m_lb_coins")

    local lightAni = util_createAnimation("MedusaMania_tanban_beiguang.csb")
    self:findChild("beiguang"):addChild(lightAni)
    lightAni:runCsbAction("animation0", true)

    local particleAni = util_createAnimation("MedusaMania_tanban_lizi.csb")
    local particle = particleAni:findChild("Particle_1")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:resetSystem()
    self:findChild("lizi"):addChild(particleAni)

    self.m_RoleSpine = util_spineCreate("Socre_MedusaMania_tanban",true,true)
    self:findChild("ren"):addChild(self.m_RoleSpine)
    util_spinePlay(self.m_RoleSpine,"actionframe",true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function MedusaManiaJackpotWinView:onExit()
    MedusaManiaJackpotWinView.super.onExit(self)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

function MedusaManiaJackpotWinView:refreshRewardType(_reward, mainMachine, _callFunc)
    self.isHide = false
    self.m_jackpotType = _reward[1]
    self:createGrandShare(mainMachine)
    
    self.m_callFunc = _callFunc
    self.m_rewardCoins = _reward[2]
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Coins)
    self:jumpCoins(self.m_rewardCoins)
    -- local strCoins=util_formatCoins(_reward[2],50)
    -- self.textReward:setString(strCoins)
    -- self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},746)
    for i=1, 4 do
        if _reward[1] == i then
            self.m_rewardName[i]:setVisible(true)
        else
            self.m_rewardName[i]:setVisible(false)
        end
    end
    globalData.jackpotRunData:notifySelfJackpot(self.m_rewardCoins, self.m_jackpotType)
end

--默认按钮监听回调
function MedusaManiaJackpotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" and self:getClickState() then
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
                self:updateLabelSize({label=self.textReward,sx=0.8,sy=0.8},850)

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

function MedusaManiaJackpotWinView:hideSelf(hideState)
    if self.isHide then
        return
    end
    self:jackpotViewOver(function()
        self.isHide = hideState
        self:setClickState(false)
        globalData.coinsSoundType = 1
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_OverDialog)
        self:runCsbAction("over", false, function()
            if self.m_callFunc then
                self.m_callFunc()
                self.m_callFunc = nil
            end
            self:setVisible(false)
        end)
    end)
end

function MedusaManiaJackpotWinView:setClickState(_state)
    self.m_cilck = _state
end

function MedusaManiaJackpotWinView:getClickState()
    return self.m_cilck
end

function MedusaManiaJackpotWinView:jumpCoins(coins )
    self.textReward:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        -- print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins
            
            self.textReward:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.textReward,sx=0.8,sy=0.8},850)

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
            -- gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
        else
            self.textReward:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.textReward,sx=0.8,sy=0.8},850)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function MedusaManiaJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MedusaManiaJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotType)
    end
end

function MedusaManiaJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MedusaManiaJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MedusaManiaJackpotWinView
