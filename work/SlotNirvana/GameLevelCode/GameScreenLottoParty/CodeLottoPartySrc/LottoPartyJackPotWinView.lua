local BaseLevelDialog = util_require("Levels.BaseLevelDialog")
local LottoPartyJackPotWinView = class("LottoPartyJackPotWinView", BaseLevelDialog)

function LottoPartyJackPotWinView:initUI(data)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local resourceFilename = "LottoParty/JackpotOver.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil
end

function LottoPartyJackPotWinView:initViewData(machine, strType, coins, callBackFun)
    self:createGrandShare(machine)
    
    self.m_index = 1
    self.m_StrType = "Minor"
    if strType == "Minor" then
        self.m_StrType = "minor"
        self.m_index = 1
        self.m_jackpotIndex = 3
    elseif strType == "Major" then
        self.m_StrType = "Major"
        self.m_index = 2
        self.m_jackpotIndex = 2
    elseif strType == "Grand" then
        self.m_StrType = "Grand"
        self.m_index = 3
        self.m_jackpotIndex = 1
    end

    self:findChild("grand"):setVisible(false)
    self:findChild("major"):setVisible(false)
    self:findChild("minor"):setVisible(false)

    if self.m_index == 3 then
        self:findChild("grand"):setVisible(true)
    elseif self.m_index == 2 then
        self:findChild("major"):setVisible(true)
    elseif self.m_index == 1 then
        self:findChild("minor"):setVisible(true)
    end

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )

    self.m_callFun = callBackFun

    local node1 = self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label = node1, sx = 0.75, sy = 0.75}, 692)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_jump.mp3", true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, index)
end

function LottoPartyJackPotWinView:jumpCoins(coins)
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
            -- print("++++++++++++  " .. curCoins)

            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
                self:jumpCoinsFinish()

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
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
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function LottoPartyJackPotWinView:onExit()
    
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
    LottoPartyJackPotWinView.super.onExit(self)
end

function LottoPartyJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                self.m_JumpOver = gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            self:jumpCoinsFinish()
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle", true, nil, 60)
        else
            self.m_click = true
            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:closeUI()
                end)
            end
        end
    end
end

function LottoPartyJackPotWinView:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end,
        60
    )
end

--[[
    自动分享 | 手动分享
]]
function LottoPartyJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function LottoPartyJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function LottoPartyJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function LottoPartyJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return LottoPartyJackPotWinView
