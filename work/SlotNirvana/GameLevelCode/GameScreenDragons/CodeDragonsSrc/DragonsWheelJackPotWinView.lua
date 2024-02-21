---
--xcyy
--2018年5月23日
--DragonsWheelJackPotWinViewlua

local DragonsWheelJackPotWinView = class("DragonsWheelJackPotWinView", util_require("base.BaseView"))

function DragonsWheelJackPotWinView:initUI(_machine)
    self.m_machine = _machine
    self:createCsbNode("Dragons_jackpotkuang.csb")
    self.m_startCoins = 0
    local touch = self:findChild("touchPanel")
    if touch then
        self:addClick(touch)
    end
end

function DragonsWheelJackPotWinView:initJackpotType(_type, _coins, _func)
    self.m_type = _type
    self.m_index = 1
    self:findChild("Node_1"):setVisible(true)
    self:findChild("Dragons_TB1_minor"):setVisible(false) --minor
    self:findChild("Dragons_TB1_major"):setVisible(false) --major
    self:findChild("Dragons_TB1_grand"):setVisible(false) --grand
    self:findChild("Dragons_TB1_super"):setVisible(false) --super
    self:findChild("Dragons_TB1_mini"):setVisible(false) --mini
    if _type == "Mini" then
        self:findChild("Dragons_TB1_mini"):setVisible(true)
        self.m_index = 5
    elseif _type == "Super" then
        self:findChild("Dragons_TB1_super"):setVisible(true)
        self.m_index = 2
    elseif _type == "Major" then
        self:findChild("Dragons_TB1_major"):setVisible(true)
        self.m_index = 3
    elseif _type == "Minor" then
        self:findChild("Dragons_TB1_minor"):setVisible(true)
        self.m_index = 4
    elseif _type == "Grand" then
        self:findChild("Dragons_TB1_grand"):setVisible(true)
        self.m_index = 1
    end

    local node = self:findChild("BitmapFontLabel_1")
    globalData.jackpotRunData:notifySelfJackpot(_coins,self.m_index)
    node:setString("")
    self:runCsbAction("start") -- 播放时间线
    self:jumpCoins(_coins)
    self.m_func = _func
    self.m_startCoins = _coins
    self.m_winCoins = _coins
    self.m_click = false
    self.m_JumpSound = gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_jackpot_jump.mp3",true)
end

function DragonsWheelJackPotWinView:jumpCoins(coins)
    self.m_click = true
    local coinRiseNum = (coins - self.m_startCoins) / (5 * 60)
    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = self.m_startCoins

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("BitmapFontLabel_1")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 687)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    self.m_JumpOver = gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_jackpot_over.mp3")
                end
            else
                local node = self:findChild("BitmapFontLabel_1")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 687)
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
                    self.m_JumpOver = gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_jackpot_over.mp3")
                end
            end
            local node = self:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 687)
            performWithDelay(
                self,
                function()
                    if self.m_click == false then
                        self.m_click = true
                        self:runCsbAction(
                            "over",
                            false,
                            function()
                                if self.m_func then
                                    self.m_func()
                                end
                            end
                        )
                    end
                end,
                2.0
            )
        end,
        5
    )
    
end

function DragonsWheelJackPotWinView:onEnter()
end

function DragonsWheelJackPotWinView:onExit()
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

function DragonsWheelJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                self.m_JumpOver = gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_jackpot_over.mp3")
            end
            local node = self:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 687)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle", true)
        end
        self.m_click = true
        performWithDelay(
            self,
            function()
                self:runCsbAction(
                    "over",
                    false,
                    function()
                        if self.m_func then
                            self.m_func()
                        end
                    end
                )
            end,
            2
        )
    end
end

return DragonsWheelJackPotWinView
