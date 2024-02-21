
local FiestaDeMuertosGameBottomNode = class("FiestaDeMuertosGameBottomNode",util_require("views.gameviews.GameBottomNode"))

function FiestaDeMuertosGameBottomNode:createCoinWinEffectUI()
    if self.coinBottomEffectNode ~= nil then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
    end
    if self.coinWinNode ~= nil then
        local effectCsbName ="Socre_FiestaDeMuertos_jiesuan.csb"
        if effectCsbName ~= nil then
            local coinBottomEffectNode,coinBottomEffectAct = util_csbCreate(effectCsbName,true)
            self.coinBottomEffectNode,self.coinBottomEffectAct = coinBottomEffectNode,coinBottomEffectAct
            self.coinWinNode:addChild(coinBottomEffectNode)
            self.coinWinNode:setPositionY(-11)
            coinBottomEffectNode:setVisible(false)
            util_csbPauseForIndex(coinBottomEffectAct,0)
        end
    end
end

function FiestaDeMuertosGameBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil and self.coinBottomEffectAct ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_csbPlayForKey(self.coinBottomEffectAct,"actionframe",false,
        function()
            -- coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

return FiestaDeMuertosGameBottomNode