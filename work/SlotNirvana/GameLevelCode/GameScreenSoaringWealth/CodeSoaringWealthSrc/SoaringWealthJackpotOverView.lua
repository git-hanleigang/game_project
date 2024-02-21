---
--SoaringWealthJackpotOverView.lua

local SoaringWealthJackpotOverView = class("SoaringWealthJackpotOverView",util_require("Levels.BaseLevelDialog"))

SoaringWealthJackpotOverView.m_machine = nil
SoaringWealthJackpotOverView.m_rewardCoins = 0
SoaringWealthJackpotOverView.m_closeCallFunc = nil
SoaringWealthJackpotOverView.m_cilck = false

function SoaringWealthJackpotOverView:initUI(_m_machine)

    self:createCsbNode("SoaringWealth/JackpotBonusOver.csb")
    
    self.m_machine = _m_machine

    self.textReward = self:findChild("m_lb_coins")
end

function SoaringWealthJackpotOverView:onExit()
    SoaringWealthJackpotOverView.super.onExit(self)
end

function SoaringWealthJackpotOverView:refreshRewardType(_totalReward, _closeCallFunc)
    self.m_closeCallFunc = _closeCallFunc
    self.m_rewardCoins = _totalReward
    local strCoins=util_formatCoins(_totalReward,50)
    self.textReward:setString(strCoins)
    self:updateLabelSize({label=self.textReward,sx=1.0,sy=1.0},575)
end

--默认按钮监听回调
function SoaringWealthJackpotOverView:clickFunc(sender)
    local name = sender:getName()

    if name == "Button_1" and self:getClickState() then
        self:hideSelf()
    end
end

function SoaringWealthJackpotOverView:hideSelf()
    self:setClickState(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {varCoins = self.m_rewardCoins, isPlayEffect = true})
    self:runCsbAction("over", false, function()
        self:setVisible(false)
        if self.m_closeCallFunc then
            self.m_closeCallFunc()
            self.m_closeCallFunc = nil
        end
    end)
end

function SoaringWealthJackpotOverView:setClickState(_state)
    self.m_cilck = _state
end

function SoaringWealthJackpotOverView:getClickState()
    return self.m_cilck
end

return SoaringWealthJackpotOverView
