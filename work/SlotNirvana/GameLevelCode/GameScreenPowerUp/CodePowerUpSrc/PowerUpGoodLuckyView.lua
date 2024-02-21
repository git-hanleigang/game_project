---
--xcyy
--2018年5月23日
--PowerUpGoodLuckyView.lua

local PowerUpGoodLuckyView = class("PowerUpGoodLuckyView", util_require("base.BaseView"))
PowerUpGoodLuckyView.m_coinsNum = -1
function PowerUpGoodLuckyView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("PowerUp_win2.csb")
    self:runCsbAction("idle", true)
    self.m_lbs_coins = self:findChild("lbs_coins")
    self.m_lbs_coins:setString(0)
end

function PowerUpGoodLuckyView:initView(winCount)
    self.m_lbs_coins:setVisible(true)
    self.m_coinsNum = winCount
    self.m_lbs_coins:setString(util_formatCoins(self.m_coinsNum, 10))
end

function PowerUpGoodLuckyView:updateWin(winCount,time)
    self.m_lbs_coins:setVisible(true)
    if self.m_coinsNum == winCount then
        self.m_lbs_coins:setString(util_formatCoins(self.m_coinsNum, 10))
        self:updateLabelSize({label=self.m_lbs_coins,sx=1.09,sy=1.09},380)
    else
        self.m_curCoin = self.m_coinsNum
        self.m_coinsNum = winCount
        self.m_lbs_coins:setString(util_formatCoins(self.m_curCoin, 20))
        self.m_lCoinRiseNum = self.m_coinsNum / (60*time) -- 30帧变化完成， 也就是0.5秒

        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_numGrow"..time..".mp3")
        self.m_showCoinUpdateAction =
            schedule(
            self,
            function()
                self.m_curCoin = self.m_curCoin + self.m_lCoinRiseNum
                -- 判断是否到达目标
                if (self.m_lCoinRiseNum <= 0 and self.m_curCoin <= self.m_coinsNum) or (self.m_lCoinRiseNum >= 0 and self.m_curCoin >= self.m_coinsNum) then
                    self.m_curCoin = self.m_coinsNum
                    -- scheduler.unscheduleGlobal(self.m_showCoinHandlerID)
                    -- self.m_showCoinHandlerID = nil
                    self.m_showCoinUpdateAction:stop()
                    self.m_showCoinUpdateAction = nil
                end
                self.m_lbs_coins:setString(util_formatCoins(self.m_curCoin, 10))
                self:updateLabelSize({label=self.m_lbs_coins,sx=1.09,sy=1.09},380)
            end,
            0.017
        )
    end
end

function PowerUpGoodLuckyView:onEnter()
end

function PowerUpGoodLuckyView:onExit()
    if self.m_showCoinUpdateAction then
        self.m_showCoinUpdateAction:stop()
        self.m_showCoinUpdateAction = nil
    end
end

--默认按钮监听回调
function PowerUpGoodLuckyView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

return PowerUpGoodLuckyView
