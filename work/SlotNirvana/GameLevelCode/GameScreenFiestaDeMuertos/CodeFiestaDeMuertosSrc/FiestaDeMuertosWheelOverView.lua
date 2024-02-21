--FiestaDeMuertosWheelOverView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FiestaDeMuertosWheelOverView = class("FiestaDeMuertosWheelOverView", util_require("base.BaseView"))

function FiestaDeMuertosWheelOverView:initUI(data)
    self.m_click = true
    local resourceFilename = "FiestaDeMuertos/WheelGameOver.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function FiestaDeMuertosWheelOverView:onEnter()
end

function FiestaDeMuertosWheelOverView:initViewData(coinsData, startCallfun, callBackFun)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
            if startCallfun then
                startCallfun()
            end
        end
    )
    self.m_callFun = callBackFun
    self.m_linkCoins = coinsData.linkCoins
    self.m_totalCoins = coinsData.totalCoins
    local node1 = self:findChild("m_lb_coins_1")
    local node2 = self:findChild("m_lb_coins_2")
    local node3 = self:findChild("m_lb_coins_3")
    node1:setString(util_formatCoins(coinsData.linkCoins, 50))
    node2:setString(util_formatCoins(coinsData.wheelCoins, 50))
    node3:setString(util_formatCoins(coinsData.totalCoins, 50))
    self:updateLabelSize({label = node1, sx = 0.4, sy = 0.4}, 847)
    self:updateLabelSize({label = node2, sx = 0.4, sy = 0.4}, 847)
    self:updateLabelSize({label = node3, sx = 0.4, sy = 0.4}, 847)
    -- performWithDelay(
    --     self,
    --     function()
    --         self.m_click = true
    --         self:closeUI()
    --     end,
    --     4
    -- )
end

function FiestaDeMuertosWheelOverView:showWinMulLab(num, scale)
    local labNum = num .. "X"
    local winMulLab = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelLab", "MulLab")
    winMulLab:setScale(scale)
    winMulLab:setLab(labNum)
    self:findChild("Node_chengbei"):addChild(winMulLab)
    winMulLab:runCsbAction("jiesuan_idle")
    self.m_click = false
    --link赢钱
    local curlinkTotals = self.m_linkCoins
    self.m_linkCoins = self.m_linkCoins * num
    self:jumpCoins("m_lb_coins_1", curlinkTotals, self.m_linkCoins, 1)
    self.m_JumpSound = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_jump.mp3", true)
    --总赢钱
    self.m_curTotalCoins = self.m_totalCoins
    self.m_totalCoins = self.m_totalCoins + self.m_linkCoins - curlinkTotals
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end
--[[
    @desc: 数值跳动
    --@nodeName:跳动的节点名称
	--@curCoins:现在的值
	--@totalCoins:总值
	--@jumpCount: 次数 总共两次

]]
function FiestaDeMuertosWheelOverView:jumpCoins(nodeName, curCoins, totalCoins, jumpCount)
    local node = self:findChild(nodeName)

    local coinRiseNum = totalCoins / (60) -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = curCoins

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curCoins = curCoins + coinRiseNum

            if curCoins >= totalCoins then
                curCoins = totalCoins

                local node = self:findChild(nodeName)
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 0.4, sy = 0.4}, 847)
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_stop.mp3")
                end
                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                    if jumpCount == 1 then
                        self:runCsbAction("jiesuan")

                        self.m_handerIdJump =
                            scheduler.performWithDelayGlobal(
                            function(delay)
                                self.m_JumpSound = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_jump.mp3", true)
                                self:jumpCoins("m_lb_coins_3", self.m_curTotalCoins, self.m_totalCoins, 2)
                            end,
                            20 / 30,
                            "WheelOver"
                        )
                    end
                end
            else
                local node = self:findChild(nodeName)
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 0.4, sy = 0.4}, 847)
            end
        end
    )
    -- performWithDelay(
    --     self,
    --     function()
    --         if self.m_updateCoinHandlerID ~= nil then
    --             if self.m_JumpSound then
    --                 gLobalSoundManager:stopAudio(self.m_JumpSound)
    --                 self.m_JumpSound = nil
    --             end
    --             scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
    --             self.m_updateCoinHandlerID = nil
    --             if jumpCount == 1 then
    --                 gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_bonus_over_jump.mp3")
    --                 self:runCsbAction("jiesuan")
    --                 self.m_handerIdJump =
    --                     scheduler.performWithDelayGlobal(
    --                     function(delay)
    --                         self.m_JumpSound = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_jump.mp3", true)
    --                         self:jumpCoins("m_lb_coins_3", self.m_curTotalCoins, self.m_totalCoins, 2)
    --                     end,
    --                     20 / 30,
    --                     "WheelOver"
    --                 )
    --             end
    --             local node = self:findChild(nodeName)
    --             node:setString(util_formatCoins(totalCoins, 50))
    --             self:updateLabelSize({label = node, sx = 0.4, sy = 0.4}, 847)
    --         end
    --     end,
    --     1
    -- )
end

function FiestaDeMuertosWheelOverView:onExit()
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

    if self.m_handerIdJump ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdJump)
        self.m_handerIdJump = nil
    end
end

function FiestaDeMuertosWheelOverView:clickFunc(sender)
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
                self.m_JumpOver = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_jackpot_stop.mp3")
            end
            if self.m_handerIdJump ~= nil then
                scheduler.unscheduleGlobal(self.m_handerIdJump)
                self.m_handerIdJump = nil
            end
            local node1 = self:findChild("m_lb_coins_1")
            local node3 = self:findChild("m_lb_coins_3")
            node1:setString(util_formatCoins(self.m_linkCoins, 50))
            node3:setString(util_formatCoins(self.m_totalCoins, 50))
            self:updateLabelSize({label = node1, sx = 0.4, sy = 0.4}, 847)
            self:updateLabelSize({label = node3, sx = 0.4, sy = 0.4}, 847)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        else
            self.m_click = true
            self:closeUI()
        end
    end
end

function FiestaDeMuertosWheelOverView:closeUI()
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
return FiestaDeMuertosWheelOverView
