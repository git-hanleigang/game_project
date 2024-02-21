
local WickedBlazeBoottomUiView = class("WickedBlazeBoottomUiView",util_require("views.gameviews.GameBottomNode"))

function WickedBlazeBoottomUiView:updateBetCoin(isLevelUp,isSkipSound)

    WickedBlazeBoottomUiView.super.updateBetCoin(self,isLevelUp,isSkipSound)

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp then
        else
            if self.m_machine then
                self.m_machine:betChangeNotify(isLevelUp)
            end
        end
    end
end

return WickedBlazeBoottomUiView