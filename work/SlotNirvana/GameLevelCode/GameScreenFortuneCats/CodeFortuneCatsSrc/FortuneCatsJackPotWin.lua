---
--island
--2018年4月12日
--FortuneCatsJackPotWin.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FortuneCatsJackPotWin = class("FortuneCatsJackPotWin", util_require("base.BaseView"))

function FortuneCatsJackPotWin:initUI(data)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local resourceFilename = "FortuneCats/JackpotWin.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil
    self.m_index = 1
    self.m_JumpTips = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_tips.mp3")
end

function FortuneCatsJackPotWin:initViewData(index, coins, callBackFun)
    if index == 4 then
        self.m_index = 6
    elseif index == 5 then
        self.m_index = 5
    elseif index == 6 then
        self.m_index = 4
    elseif index == 7 then
        self.m_index = 3
    elseif index == 8 then
        self.m_index = 2
    elseif index == 9 then
        self.m_index = 1
    end
    local num = self:findChild("jackpot_num")
    num:setString(index)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )
    self.m_click = false
    self.m_callFun = callBackFun

    self.m_winCoins = coins
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_jump.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_index)
end

function FortuneCatsJackPotWin:jumpCoins(coins)
    local node = self:findChild("m_lb_coins_0")
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

                local node = self:findChild("m_lb_coins_0")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1.35, sy = 1.35}, 494)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_over.mp3")
                end
            else
                local node = self:findChild("m_lb_coins_0")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1.35, sy = 1.35}, 494)
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
                    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_over.mp3")
                end
                local node = self:findChild("m_lb_coins_0")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1.35, sy = 1.35}, 494)
            end
        end,
        5
    )
end

function FortuneCatsJackPotWin:onEnter()
    
end

function FortuneCatsJackPotWin:onExit()
   
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

function FortuneCatsJackPotWin:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                self.m_JumpOver = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins_0")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1.35, sy = 1.35}, 494)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle", true)
        else
            self.m_click = true
            self:closeUI()
        end
    end
end

function FortuneCatsJackPotWin:closeUI()
    if self.m_JumpTips then
        gLobalSoundManager:stopAudio(self.m_JumpTips)
        self.m_JumpTips = nil
    end
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

return FortuneCatsJackPotWin
