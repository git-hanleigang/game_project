
local FlamingPompeiiBoottomUiView = class("FlamingPompeiiBoottomUiView",util_require("views.gameviews.GameBottomNode"))

function FlamingPompeiiBoottomUiView:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil and self.coinBottomEffectAct ~= nil then
        -- 重置csb
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

return FlamingPompeiiBoottomUiView