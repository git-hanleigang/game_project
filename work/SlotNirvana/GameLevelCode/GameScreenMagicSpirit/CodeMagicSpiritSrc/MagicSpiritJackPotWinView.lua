local MagicSpiritJackPotWinView = class("MagicSpiritJackPotWinView", util_require("base.BaseView"))

MagicSpiritJackPotWinView.m_isOverAct = false
MagicSpiritJackPotWinView.m_isJumpOver = false

function MagicSpiritJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "MagicSpirit/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

    --挂载钻石
    self.m_Zuanshi = util_createAnimation("MagicSpirit_jackpot_zuanshi.csb")
    self:findChild("zuanshi"):addChild(self.m_Zuanshi)
end

function MagicSpiritJackPotWinView:initViewData(index, coins, callBackFun)
    self.m_index = index
    self.m_coins = coins

    -- self.m_bgSoundId = gLobalSoundManager:playSound("MagicSpiritSounds/MagicSpirit_JackPotWinShow.mp3", false)

    -- self.m_soundId = gLobalSoundManager:playSound("MagicSpiritSounds/MagicSpirit_JackPotWinCoins.mp3", true)
    self:jumpCoins(coins)

    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_coins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 706)
            end

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
        end,
        4
    )

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:runCsbAction("idle", true)
        end
    )

    local imgName = {"MagicSpirit_9", "MagicSpirit_8", "MagicSpirit_7", "MagicSpirit_6", "MagicSpirit_5"}
    for k, v in pairs(imgName) do
        local img = self:findChild(v)
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
    globalData.jackpotRunData:notifySelfJackpot(coins, index)
end

function MagicSpiritJackPotWinView:onEnter()
end

function MagicSpiritJackPotWinView:onExit()
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

function MagicSpiritJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self.m_click == true then
            return
        end

        -- gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirits_Click_Collect.mp3")

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            self:runCsbAction("over")
            performWithDelay(
                self,
                function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,
                1
            )
        end

        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 706)

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end
end

function MagicSpiritJackPotWinView:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (4 * 60) -- 每秒60帧

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
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 706)

                self.m_isJumpOver = true

                if self.m_soundId then
                    gLobalSoundManager:stopAudio(self.m_soundId)
                    self.m_soundId = nil
                end

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 706)
            end
        end
    )
end

return MagicSpiritJackPotWinView
