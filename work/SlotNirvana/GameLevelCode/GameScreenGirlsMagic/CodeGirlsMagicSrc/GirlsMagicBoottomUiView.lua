
local GirlsMagicBoottomUiView = class("GirlsMagicBoottomUiView",util_require("views.gameviews.GameBottomNode"))


function GirlsMagicBoottomUiView:updateBetCoin(isLevelUp,isSkipSound)

    GirlsMagicBoottomUiView.super.updateBetCoin(self,isLevelUp,isSkipSound)

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp then
        else
            if self.m_machine then
                self.m_machine:betChangeNotify( isLevelUp)
            end
        end
    end
end


return GirlsMagicBoottomUiView