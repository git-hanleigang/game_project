--BuzzingHoneyBeeJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local BuzzingHoneyBeeJackPotWinView = class("BuzzingHoneyBeeJackPotWinView", util_require("base.BaseView"))

function BuzzingHoneyBeeJackPotWinView:initUI(data)
    self.m_click = false
    local resourceFilename = "BuzzingHoneyBee/JackpotOver.csb"
    self:createCsbNode(resourceFilename)
    self.m_JumpOver = nil
end

function BuzzingHoneyBeeJackPotWinView:initViewData(machine, coins, callBackFun)
    self.m_index = 1
    local bee = util_spineCreate("BuzzingHoneyBee_dajuese2",true,true)
    self:findChild("bee"):addChild(bee)
    util_spinePlay(bee,"tanban2",true)

    self:createGrandShare(machine)
    self.m_jackpotIndex = 1

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
    self:updateLabelSize({label = node1, sx = 0.93, sy = 1}, 695)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_jackpot_jump.mp3", true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_index)
end

function BuzzingHoneyBeeJackPotWinView:jumpCoins(coins)
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
                    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_jackpot_stop.mp3")
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
                    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_jackpot_stop.mp3")
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

function BuzzingHoneyBeeJackPotWinView:onEnter()
end

function BuzzingHoneyBeeJackPotWinView:onExit()
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

function BuzzingHoneyBeeJackPotWinView:clickFunc(sender)
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
                self.m_JumpOver = gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_jackpot_stop.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 656)
            self:jumpCoinsFinish()
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle", true)
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

function BuzzingHoneyBeeJackPotWinView:closeUI()
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
function BuzzingHoneyBeeJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function BuzzingHoneyBeeJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function BuzzingHoneyBeeJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function BuzzingHoneyBeeJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return BuzzingHoneyBeeJackPotWinView
