
local ThanksGivingBoottomUiView = class("ThanksGivingBoottomUiView",util_require("views.gameviews.GameBottomNode"))


function ThanksGivingBoottomUiView:updateBetCoin(isLevelUp,isSkipSound)

    ThanksGivingBoottomUiView.super.updateBetCoin(self,isLevelUp,isSkipSound)

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp then
        else
            if self.m_machine then
                self.m_machine:betChangeNotify( isLevelUp)
            end
        end
    end
end

function ThanksGivingBoottomUiView:onEnter()
    ThanksGivingBoottomUiView.super.onEnter(self)
    -- gLobalNoticManager:addObserver(self,function(self,params)
    --     self:updateTotalBet(params[1])
    -- end,"ThanksGivingBoottomUiView_updateTotalBet")
end
return ThanksGivingBoottomUiView