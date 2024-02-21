---
--RedHotDevilsJackpotWinView.lua

local RedHotDevilsJackpotWinView = class("RedHotDevilsJackpotWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "RedHotDevilsPublicConfig"

RedHotDevilsJackpotWinView.m_machine = nil
RedHotDevilsJackpotWinView.m_rewardCoins = 0
RedHotDevilsJackpotWinView.m_callFunc = nil
RedHotDevilsJackpotWinView.m_cilck = false

function RedHotDevilsJackpotWinView:initUI(_m_machine)

    self:createCsbNode("RedHotDevils/JackpotWinView.csb")
    
    self.m_machine = _m_machine

    self.m_tblRoleSpine = {}
    self.m_tblRoleSpine[1] = util_spineCreate("Socre_RedHotDevils_juese",true,true)
    self:findChild("juese"):addChild(self.m_tblRoleSpine[1])
    self.m_tblRoleSpine[1]:setVisible(false)

    self.m_tblRoleSpine[2] = util_spineCreate("Socre_RedHotDevils_9",true,true)
    self:findChild("juese"):addChild(self.m_tblRoleSpine[2])
    self.m_tblRoleSpine[2]:setVisible(false)

    self.m_tblRoleSpine[3] = util_spineCreate("Socre_RedHotDevils_8",true,true)
    self:findChild("juese"):addChild(self.m_tblRoleSpine[3])
    self.m_tblRoleSpine[3]:setVisible(false)

    self.m_tblRoleSpine[4] = util_spineCreate("Socre_RedHotDevils_7",true,true)
    self:findChild("juese"):addChild(self.m_tblRoleSpine[4])
    self.m_tblRoleSpine[4]:setVisible(false)

    self.m_rewardName = {}
    self.m_rewardName[1] = self:findChild("grand")
    self.m_rewardName[2] = self:findChild("major")
    self.m_rewardName[3] = self:findChild("minor")
    self.m_rewardName[4] = self:findChild("mini")

    self.textReward = self:findChild("m_lb_coins")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function RedHotDevilsJackpotWinView:onExit()
    RedHotDevilsJackpotWinView.super.onExit(self)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

function RedHotDevilsJackpotWinView:refreshRewardType(_reward, mainMachine, _callFunc)
    self.isHide = false
    self.m_jackpotType = _reward[1]
    self:createGrandShare(mainMachine)
    for i=1, 4 do
        if _reward[1] == i then
            if i ~= 1 then
                self.m_tblRoleSpine[i]:setSkin("cai")
            end
            self.m_tblRoleSpine[i]:setVisible(true)
            util_spinePlay(self.m_tblRoleSpine[i],"jackpot_start",false)
        else
            self.m_tblRoleSpine[i]:setVisible(false)
        end
    end
    
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
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_rewardCoins, self.m_jackpotType)
end

function RedHotDevilsJackpotWinView:setSpineIdle()
    util_spinePlay(self.m_tblRoleSpine[self.m_jackpotType],"jackpot_idle",true)
end

--默认按钮监听回调
function RedHotDevilsJackpotWinView:clickFunc(sender)
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
                self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},746)

                self:jumpCoinsFinish()

                performWithDelay(self.m_scWaitNode,function(  )
                    self:hideSelf(true)
                end,1.5)
            else
                gLobalSoundManager:playSound(PublicConfig.Music_JackpotOver_Click)
                self:hideSelf(true)
            end
        end
    end
end

function RedHotDevilsJackpotWinView:hideSelf(hideState)
    if self.isHide then
        return
    end
    self:jackpotViewOver(function()
        self.isHide = hideState
        self:setClickState(false)
        util_spinePlay(self.m_tblRoleSpine[self.m_jackpotType],"jackpot_over",false)
        globalData.coinsSoundType = 1
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        self:runCsbAction("over", false, function()
            if self.m_callFunc then
                self.m_callFunc()
                self.m_callFunc = nil
            end
            self:setVisible(false)
        end)
    end)
end

function RedHotDevilsJackpotWinView:setClickState(_state)
    self.m_cilck = _state
end

function RedHotDevilsJackpotWinView:getClickState()
    return self.m_cilck
end

function RedHotDevilsJackpotWinView:jumpCoins(coins )
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
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},746)

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
            self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},746)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function RedHotDevilsJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function RedHotDevilsJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotType)
    end
end

function RedHotDevilsJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function RedHotDevilsJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return RedHotDevilsJackpotWinView
