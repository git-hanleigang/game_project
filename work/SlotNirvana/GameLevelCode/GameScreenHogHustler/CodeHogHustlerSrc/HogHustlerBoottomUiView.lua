
local HogHustlerBoottomUiView = class("HogHustlerBoottomUiView",util_require("views.gameviews.GameBottomNode"))

function HogHustlerBoottomUiView:notifyTopWinCoin(_reduce)
    local reduce = 0
    if _reduce then
        reduce = _reduce
    end
    local curTotalCoin = toLongNumber(globalData.userRunData.coinNum - reduce)
    globalData.coinsSoundType = 1
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, curTotalCoin)
    -- local addWinCoins = self.m_spinWinCount - self.m_addWinCount
    -- if addWinCoins > 0 then
    --     self.m_addWinCount = self.m_addWinCount + addWinCoins
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {varCoins = addWinCoins, isPlayEffect = true})
    -- end
end

function HogHustlerBoottomUiView:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil and self.coinBottomEffectAct ~= nil then
        if not tolua.isnull(self.coinBottomEffectAct) then
            util_resetCsbAction(self.coinBottomEffectAct)
        end
        
        coinBottomEffectNode:setVisible(true)
        util_csbPlayForKey(
            self.coinBottomEffectAct,
            "actionframe",
            false,
            function()
                coinBottomEffectNode:setVisible(false)
                if callBack ~= nil then
                    callBack()
                end
            end
        )
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

return HogHustlerBoottomUiView