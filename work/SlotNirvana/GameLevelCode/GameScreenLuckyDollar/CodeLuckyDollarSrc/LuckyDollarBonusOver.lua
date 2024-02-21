local LuckyDollarBonusOver = class("LuckyDollarBonusOver", util_require("base.BaseView"))

function LuckyDollarBonusOver:initUI(coins)
    self:createCsbNode("LuckyDollar/BonusOver.csb")
    self.m_click = true
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
            self.m_click = false
        end
    )

    local numLab = self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label = numLab, sx = 0.93, sy = 0.93}, 645)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_win.mp3", true)
end

function LuckyDollarBonusOver:jumpCoins(coins)
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
                self:updateLabelSize({label = node,sx = 0.93, sy = 0.93}, 645)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_jump_over.mp3")
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 0.93, sy = 0.93}, 645)
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
                    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_jump_over.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 0.93, sy = 0.93}, 645)
            end
        end,
        5
    )
end

function LuckyDollarBonusOver:setFunCall(_func,_func2)
    self.m_func = function()
        self:runCsbAction(
            "over",
            false,
            function()
                if _func then
                    _func()
                    self:removeFromParent()
                end
            end
        )
        if _func2 then
            _func2()
        end
    end
end

function LuckyDollarBonusOver:onEnter()
end

function LuckyDollarBonusOver:onExit()
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

--默认按钮监听回调
function LuckyDollarBonusOver:clickFunc(sender)
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
                self.m_JumpOver = gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_jump_over.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label = node,sx = 0.93, sy = 0.93}, 645)
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        else
            self.m_click = true
            if self.m_func then
                self.m_func()
            end
        end
    end
end

return LuckyDollarBonusOver
