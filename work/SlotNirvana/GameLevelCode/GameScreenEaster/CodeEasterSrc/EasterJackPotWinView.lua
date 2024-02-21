local EasterJackPotWinView = class("EasterJackPotWinView", util_require("base.BaseView"))

function EasterJackPotWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "Easter/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)
end

function EasterJackPotWinView:initViewData(machine, index, coins, callBackFun)
    self:createGrandShare(machine)

    self.m_jackpotIndex = index

    self.m_index = index
    local coinString = self:findChild("m_lb_coins")
    self.m_callFun = callBackFun
    self.m_winCoins = coins

    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_jump.mp3", true)
    self.m_click = true
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:runCsbAction("idle", true)
        end
    )
    local jackpot = {"grand", "major", "minor", "mini"}
    for i = 1, 4 do
        self:findChild("Easter_ui_" .. jackpot[i]):setVisible(false)
        self:findChild("Easter_ui_" .. jackpot[i] .. "1"):setVisible(false)
        self:findChild("Easter_ui_" .. jackpot[i] .. "2"):setVisible(false)
    end
    self:findChild("Easter_ui_" .. jackpot[index]):setVisible(true)
    self:findChild("Easter_ui_" .. jackpot[index] .. "1"):setVisible(true)
    self:findChild("Easter_ui_" .. jackpot[index] .. "2"):setVisible(true)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, index)
end

function EasterJackPotWinView:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (5 * 60)

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

                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 680)
                self:jumpCoinsFinish()

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_over.mp3")
                end
            else
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 680)
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
                    gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_over.mp3")
                end
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 680)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function EasterJackPotWinView:onEnter()
end

function EasterJackPotWinView:onExit()
end

function EasterJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return
        end

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                self.m_JumpOver = gLobalSoundManager:playSound("EasterSounds/sound_Easter_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 680)
            self:jumpCoinsFinish()
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        else
            self.m_click = true

            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:runCsbAction("over")
                    performWithDelay(
                        self,
                        function()
                            if self.m_callFun then
                                self.m_callFun()
                            end
                            self:removeFromParent()
                        end,
                        40/60
                    )
                end)
            end
        end
    end
end


--[[
    自动分享 | 手动分享
]]
function EasterJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function EasterJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function EasterJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function EasterJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return EasterJackPotWinView
