--FiestaDeMuertosJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FiestaDeMuertosJackPotWinView = class("FiestaDeMuertosJackPotWinView", util_require("base.BaseView"))

function FiestaDeMuertosJackPotWinView:initUI(data)
    self.m_click = false
    local resourceFilename = "FiestaDeMuertos/JackPotover.csb"
    self:createCsbNode(resourceFilename)
    self.m_JumpOver = nil
end

function FiestaDeMuertosJackPotWinView:initViewData(jackPot, coins, mainMachine, callBackFun)
    self:createGrandShare(mainMachine)
    self:findChild("grand"):setVisible(false)
    self:findChild("majior"):setVisible(false)
    self:findChild("mini"):setVisible(false)

    if jackPot == "Grand" then
        self:findChild("grand"):setVisible(true)
        self.m_index = 1
    elseif jackPot == "Major" then
        self:findChild("majior"):setVisible(true)
        self.m_index = 2
    elseif jackPot == "Minor" then
        self:findChild("mini"):setVisible(true)
        self.m_index = 3
    end

    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )
    self.m_click = false
    self.m_callFun = callBackFun

    local node1 = self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label = node1, sx = 1, sy = 1}, 656)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_jump.mp3", true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_index)
end

function FiestaDeMuertosJackPotWinView:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (5 * 60) -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = 0

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 656)

                self:jumpCoinsFinish()

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_stop.mp3")
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 634)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_stop.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 656)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function FiestaDeMuertosJackPotWinView:onEnter()
end

function FiestaDeMuertosJackPotWinView:onExit()
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

function FiestaDeMuertosJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return
        end
        local bShare = self:checkShareState()
        if not bShare then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpOver == nil then
                    self.m_JumpOver = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_stop.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 656)
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                end
                self:runCsbAction("idle", true)
                self:jumpCoinsFinish()
            else
                self:jackpotViewOver(function()
                    self.m_click = true
                    self:closeUI()
                end)
            end
        end
    end
end

function FiestaDeMuertosJackPotWinView:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end
    )
end

--[[
    自动分享 | 手动分享
]]
function FiestaDeMuertosJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function FiestaDeMuertosJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_index)
    end
end

function FiestaDeMuertosJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function FiestaDeMuertosJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FiestaDeMuertosJackPotWinView
