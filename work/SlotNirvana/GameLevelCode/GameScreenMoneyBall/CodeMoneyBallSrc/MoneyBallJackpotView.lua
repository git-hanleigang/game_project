---
--xcyy
--2018年5月23日
--MoneyBallView.lua

local MoneyBallJackpotView = class("MoneyBallJackpotView",util_require("base.BaseView"))
local JACKPOT_ID_ARRAY = 
{
    GRAND = 1,
    MAJOR = 2,
    MINOR = 3,
    MINI = 4
}

function MoneyBallJackpotView:initUI(data)
    self.m_machine = data
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "MoneyBall/Jackpotover.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
    
end

function MoneyBallJackpotView:initViewData(coins, jackpot, callBackFun)

    self.m_jackpotIndex = JACKPOT_ID_ARRAY[jackpot]
    self:createGrandShare(self.m_machine)

    self:findChild("GRAND"):setVisible(false)
    self:findChild("MAJOR"):setVisible(false)
    self:findChild("MINOR"):setVisible(false)
    self:findChild("MINI"):setVisible(false)

    self:findChild(jackpot):setVisible(true)

    self:runCsbAction("start",false,function(  )
        -- if self.m_JumpOver == nil then
        --     self.m_JumpOver = gLobalSoundManager:playSound("MoneyBallSounds/sound_Egypt_jackpot_end.mp3")
        -- end
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},632)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("MoneyBallSounds/sound_AZTEC_jackpot_up.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, JACKPOT_ID_ARRAY[jackpot])
end

function MoneyBallJackpotView:jumpCoins(coins )
    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum),"0", math.random(1,5) )
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        -- print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                self:jumpCoinsFinish()
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("MoneyBallSounds/sound_AZTEC_jackpot_end.mp3")
            end

            
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)
        end
    end)
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("MoneyBallSounds/sound_AZTEC_jackpot_end.mp3")
                end
                self:jumpCoinsFinish()
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},624)
            end
        end,
        5
    )
end

function MoneyBallJackpotView:onEnter()
    
end

function MoneyBallJackpotView:onExit()
    if self.m_JumpOver then
        gLobalSoundManager:stopAudio(self.m_JumpOver)
        self.m_JumpOver = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function MoneyBallJackpotView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self:checkShareState() then
            return
        end

        
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then 
                self.m_JumpOver = gLobalSoundManager:playSound("MoneyBallSounds/sound_AZTEC_jackpot_end.mp3")
            end
            self:jumpCoinsFinish()
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle",true)
        else
            self:jackpotViewOver(function()
                self.m_click = true
                sender:setEnabled(false)
                self:closeUI()
            end)
        end

        
        
    end
end

function MoneyBallJackpotView:closeUI( )
    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_window_over.mp3")
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end


--[[
    自动分享 | 手动分享
]]
function MoneyBallJackpotView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function MoneyBallJackpotView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function MoneyBallJackpotView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function MoneyBallJackpotView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MoneyBallJackpotView