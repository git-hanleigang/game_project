----
-- 基础弹窗
--
local ExitGameContent = class("ExitGameContent", util_require("base.BaseView"))
function ExitGameContent:initUI(func)
    self:createCsbNode("Dialog/ExitGameContent.csb")
    self.m_cash_reward_coin = self:findChild("cash_reward_coin")
    self.m_cash_reward_sp = self:findChild("cash_reward_sp")
    self.m_func = func
    self.m_collect = self:findChild("collect")
    self:addClick(self.m_collect)
    self:initCashBonus()
end

function ExitGameContent:initCashBonus()
    local leftTime = 0
    local rewardTime = 0
    if globalData.device then
        local rewardid, rewardTime1 = globalData.device:GetEarliestRewardTime()
        rewardTime = rewardTime1
        local currentTime = os.time()
        leftTime = rewardTime1 - currentTime
        if leftTime <= 0 then
            leftTime = 0
            self.m_cash_reward_sp:setVisible(true)
            self.m_cash_reward_coin:setVisible(false)
        else
            self.m_cash_reward_sp:setVisible(false)
            self.m_cash_reward_coin:setVisible(true)
            local leftTimeStr = util_count_down_str(leftTime)
            self.m_cash_reward_coin:setString(leftTimeStr)
        end
        local leftTimeStr = util_count_down_str(leftTime)
        self.m_cash_reward_coin:setString(leftTimeStr)
    end
    local setTime = function()
        local currentTime = os.time()
        leftTime = rewardTime - currentTime
        if leftTime <= 0 then
            leftTime = 0
            if self.m_ExitGame then
                self:stopAction(self.m_ExitGame)
                self.m_ExitGame = nil
            end
            self.m_cash_reward_sp:setVisible(true)
            self.m_cash_reward_coin:setVisible(false)
            self.m_isReward = true
        else
            self.m_cash_reward_sp:setVisible(false)
            self.m_cash_reward_coin:setVisible(true)
            local leftTimeStr = util_count_down_str(leftTime)
            self.m_cash_reward_coin:setString(leftTimeStr)
        end
    end
    self.m_ExitGame =
        schedule(
        self,
        function()
            setTime()
        end,
        1
    )
end

function ExitGameContent:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    -- 尝试重新连接 network
    if name == "collect" then
        if self.m_isReward then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            local cashBonusView = util_createView("views.cashBonus.cashBonusMain.CashBonusMainView")
            cashBonusView:setCloseFunc(
                function()
                end
            )
            gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
            -- local device = require "views.cashBonus.Device_CashBonus"

            if self.m_func then
                self.m_func()
            end
        end
    end
end
return ExitGameContent
