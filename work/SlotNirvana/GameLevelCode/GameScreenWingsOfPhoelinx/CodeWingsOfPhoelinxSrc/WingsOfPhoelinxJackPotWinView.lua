---
--island
--2018年4月12日
--WingsOfPhoelinxJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local WingsOfPhoelinxJackPotWinView = class("WingsOfPhoelinxJackPotWinView", util_require("Levels.BaseLevelDialog"))

WingsOfPhoelinxJackPotWinView.m_isJumpOver = false

function WingsOfPhoelinxJackPotWinView:initUI(data, _machine)
    self.m_click = true

    local resourceFilename = "WingsOfPhoelinx/JackpotOver.csb"
    self:createCsbNode(resourceFilename)
    self.m_isJumpOver = false

    self:createGrandShare(_machine)
end

function WingsOfPhoelinxJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    self.m_jackpotIndex = index
    
    self.m_bgSoundId = gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_Win.mp3",false)

    self.m_soundId = gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},697)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpOverCoins.mp3")
            self.m_soundId = nil
        end
    end,4)





    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"WingsOfPhoelinx_grand1_2","WingsOfPhoelinx_major1_3","WingsOfPhoelinx_minor1_5","WingsOfPhoelinx_mini1_4"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end
    
    
    

    self.m_callFun = callBackFun


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function WingsOfPhoelinxJackPotWinView:onEnter()

    WingsOfPhoelinxJackPotWinView.super.onEnter(self)
end

function WingsOfPhoelinxJackPotWinView:onExit()

    WingsOfPhoelinxJackPotWinView.super.onExit(self)

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
    
end

function WingsOfPhoelinxJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return 
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpOverCoins.mp3")
            self.m_soundId = nil
        end

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true
            self:jackpotViewOver(function()
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
        else
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},697)
            self:jumpCoinsFinish()
        end 
    end
end

function WingsOfPhoelinxJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()


        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},697)
            self:jumpCoinsFinish()
            self.m_isJumpOver = true
            self.m_JumpSound = gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_jump.mp3", true)
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpOverCoins.mp3")
                self.m_soundId = nil
            end


            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},697)
        end
        

    end)
end

--[[
    自动分享 | 手动分享
]]
function WingsOfPhoelinxJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function WingsOfPhoelinxJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function WingsOfPhoelinxJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function WingsOfPhoelinxJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return WingsOfPhoelinxJackPotWinView

