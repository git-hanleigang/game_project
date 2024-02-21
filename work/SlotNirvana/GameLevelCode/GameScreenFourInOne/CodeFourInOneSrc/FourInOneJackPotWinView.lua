---
--island
--2018年4月12日
--FourInOneJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FourInOneJackPotWinView = class("FourInOneJackPotWinView", util_require("base.BaseView"))


FourInOneJackPotWinView.m_isOverAct = false
FourInOneJackPotWinView.m_isJumpOver = false

function FourInOneJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "FourInOne/JackpotWin.csb"
    self:createCsbNode(resourceFilename)

end

function FourInOneJackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    self.m_index = index
    self.m_coins = coins

    self.m_soundId =  gLobalSoundManager:playSound("FourInOneSounds/FourInOne_JackPotWinShow.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},416)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Wheel_Win_end.mp3")
        end
    end,5)

    self:runCsbAction("start",false,function(  )
        self:createGrandShare(mainMachine)
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"4in1_Grand","4in1_Major","4in1_Minor","4in1_Mini"}
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

function FourInOneJackPotWinView:onEnter()
end

function FourInOneJackPotWinView:onExit()

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    
end

function FourInOneJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        local bShare = self:checkShareState()
        if not bShare then
            gLobalSoundManager:playSound("FourInOneSounds/music_FourInOnes_Click_Collect.mp3")
            if self.m_updateCoinHandlerID == nil then
                self:jackpotViewOver(function()
                    sender:setTouchEnabled(false)
                    self.m_click = true

                    self:runCsbAction("over")
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end,1)
                end)
            else
                local waitTimes = 0
                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                    local node=self:findChild("m_lb_coins")
                    node:setString(util_formatCoins(self.m_coins,50))
                    self:updateLabelSize({label=node,sx=1,sy=1},416)

                    waitTimes = 2
                    self:jumpCoinsFinish()
                end
            end

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
                gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Wheel_Win_end.mp3")
            end
        end
    end
end

function FourInOneJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1,sy=1},416)

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
                gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Wheel_Win_end.mp3")
            end

            self:jumpCoinsFinish()

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},416)
        end
        

    end)
end

--[[
    自动分享 | 手动分享
]]
function FourInOneJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function FourInOneJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_index)
    end
end

function FourInOneJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function FourInOneJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FourInOneJackPotWinView
