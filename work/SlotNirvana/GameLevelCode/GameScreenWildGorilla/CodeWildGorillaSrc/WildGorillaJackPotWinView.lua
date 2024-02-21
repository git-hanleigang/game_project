---
local WildGorillaJackPotWinView = class("WildGorillaJackPotWinView", util_require("base.BaseView"))
-- FIX IOS 139
function WildGorillaJackPotWinView:initUI(data)
    self.m_machine = data

    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "WildGorilla/JackpotOver.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
end

function WildGorillaJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_StrType = "mini"
    if self.m_index == 101 then
        self.m_StrType = "mini"
        self.m_index = 1
    elseif self.m_index == 102 then
        self.m_StrType = "minor"
        self.m_index = 2
    elseif self.m_index == 103 then
        self.m_StrType = "major"
        self.m_index = 3
    elseif self.m_index == 104 then
        self.m_StrType = "grand"
        self.m_index = 4
    end

    self.m_jackpotIndex = 4 - self.m_index + 1
    self:createGrandShare(self.m_machine)
    
    self:findChild("grand"):setVisible(false)
    self:findChild("major"):setVisible(false)
    self:findChild("minor"):setVisible(false)
    self:findChild("mini"):setVisible(false)

    if self.m_index == 4 then
        self:findChild("grand"):setVisible(true)
    elseif self.m_index == 3 then
        self:findChild("major"):setVisible(true)
    elseif self.m_index == 2 then
        self:findChild("minor"):setVisible(true)
    elseif self.m_index == 1 then
        self:findChild("mini"):setVisible(true)
    end

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)
   
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},550)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_jackpot.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function WildGorillaJackPotWinView:jumpCoins(coins )
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
            self:updateLabelSize({label=node,sx=1,sy=1},550)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                self:jumpCoinsFinish()
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_jackpot_over.mp3")
            end
            
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},550)
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
                    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_jackpot_over.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},550)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function WildGorillaJackPotWinView:onEnter()
end

function WildGorillaJackPotWinView:onExit()
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

function WildGorillaJackPotWinView:clickFunc(sender)
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
                self.m_JumpOver = gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_jackpot_over.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},550)
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle",true)
            self:jumpCoinsFinish()
        else
            self:jackpotViewOver(function()
                self.m_click = true
                self:closeUI()
            end)
        end
            
        
        
    end
end

function WildGorillaJackPotWinView:closeUI( )
   
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
function WildGorillaJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function WildGorillaJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function WildGorillaJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function WildGorillaJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WildGorillaJackPotWinView