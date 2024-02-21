---
--island
--2018年4月12日
--PiggyLegendPirateJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PiggyLegendPirateJackPotWinView = class("PiggyLegendPirateJackPotWinView", util_require("Levels.BaseLevelDialog"))


PiggyLegendPirateJackPotWinView.m_isOverAct = false
PiggyLegendPirateJackPotWinView.m_isJumpOver = false

function PiggyLegendPirateJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "PiggyLegendPirate/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    self.m_jackpot_zhu = util_spineCreate("Socre_PiggyLegendPirate_Bonus1", true, true)
    self:findChild("spine_pig"):addChild(self.m_jackpot_zhu)
    util_spinePlay(self.m_jackpot_zhu, "idle", true)  

end

function PiggyLegendPirateJackPotWinView:initViewData(index,coins,callBackFun,machine)
    self.m_index = index
    self.m_coins = coins
    self.m_machine = machine
    self:createGrandShare(machine)
    if index == "grand" then
        self.m_jackpotIndex = 1
    elseif index == "major" then
        self.m_jackpotIndex = 2
    elseif index == "minor" then
        self.m_jackpotIndex = 3
    elseif index == "mini" then
        self.m_jackpotIndex = 4
    end 
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_JackPotWinShow.mp3",false)

    self.m_soundId = gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},720)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_JackPotWinCoins_down.mp3")
    end,4)

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"grand","major","minor","mini"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if v == index then
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

function PiggyLegendPirateJackPotWinView:onEnter()

    PiggyLegendPirateJackPotWinView.super.onEnter(self)
end

function PiggyLegendPirateJackPotWinView:onExit()

    PiggyLegendPirateJackPotWinView.super.onExit(self)

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

function PiggyLegendPirateJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_Click.mp3")

        
        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:runCsbAction("over")
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_machine.m_RESPIN_RUN_TIME = 0.6
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end,25/60)
                end)
            end
        end 


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},720)
            self:jumpCoinsFinish()

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_JackPotWinCoins_down.mp3")

    end
end

function PiggyLegendPirateJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
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

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},720)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_JackPotWinCoins_down.mp3")

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},720)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function PiggyLegendPirateJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function PiggyLegendPirateJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function PiggyLegendPirateJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function PiggyLegendPirateJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return PiggyLegendPirateJackPotWinView

