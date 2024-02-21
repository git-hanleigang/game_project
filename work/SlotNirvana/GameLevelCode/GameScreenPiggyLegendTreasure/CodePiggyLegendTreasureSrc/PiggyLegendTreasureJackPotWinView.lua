---
--island
--2018年4月12日
--PiggyLegendTreasureJackPotWinView.lua
local PiggyLegendTreasureJackPotWinView = class("PiggyLegendTreasureJackPotWinView", util_require("Levels.BaseLevelDialog"))

PiggyLegendTreasureJackPotWinView.m_isJumpOver = false

function PiggyLegendTreasureJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "PiggyLegendTreasure/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    local jackpotBox = util_spineCreate("Socre_PiggyLegendTreasure_Box", true, true)

    self:findChild("xiangzi"):addChild(jackpotBox)

    util_spinePlay(jackpotBox,"start",false)
    util_spineEndCallFunc(jackpotBox, "start", function()
        util_spinePlay(jackpotBox,"idle",true)
    end)

end

function PiggyLegendTreasureJackPotWinView:initViewData(machine,coins,callBackFun)
    self.m_coins = coins
    self.m_machine = machine
    self:createGrandShare(machine)
    self.m_jackpotIndex = 1
    
    self.m_bgSoundId =  gLobalSoundManager:playSound(self.m_machine.m_musicConfig.Sound_Super_StartView,false)

    self.m_soundId = gLobalSoundManager:playSound(self.m_machine.m_musicConfig.Sound_JackPotWinCoins,true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},650)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        gLobalSoundManager:playSound(self.m_machine.m_musicConfig.Sound_JackPotWinCoins_down)
    end,4)

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    self.m_callFun = callBackFun

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,1)
end

function PiggyLegendTreasureJackPotWinView:onEnter()

    PiggyLegendTreasureJackPotWinView.super.onEnter(self)
end

function PiggyLegendTreasureJackPotWinView:onExit()

    PiggyLegendTreasureJackPotWinView.super.onExit(self)

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

function PiggyLegendTreasureJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        
        gLobalSoundManager:playSound(self.m_machine.m_musicConfig.Sound_Click)

        
        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:runCsbAction("over",false,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end)
                end)
            end
        end 

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},650)
            self:jumpCoinsFinish()

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(self.m_machine.m_musicConfig.Sound_JackPotWinCoins_down)
        end

    end
end

function PiggyLegendTreasureJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins_0")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},650)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(self.m_machine.m_musicConfig.Sound_JackPotWinCoins_down)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},650)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function PiggyLegendTreasureJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function PiggyLegendTreasureJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function PiggyLegendTreasureJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function PiggyLegendTreasureJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return PiggyLegendTreasureJackPotWinView

