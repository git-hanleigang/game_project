
local BuzzingHoneyBeeBoottomUiView = class("BuzzingHoneyBeeBoottomUiView",util_require("views.gameviews.GameBottomNode"))
--fixios0223
function BuzzingHoneyBeeBoottomUiView:updateBetCoin(isLevelUp,isSkipSound)

    BuzzingHoneyBeeBoottomUiView.super.updateBetCoin(self,isLevelUp,isSkipSound)

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp then
        else
            if self.m_machine then
                self.m_machine:betChangeNotify(isLevelUp)
            end
        end
    end
end

return BuzzingHoneyBeeBoottomUiView