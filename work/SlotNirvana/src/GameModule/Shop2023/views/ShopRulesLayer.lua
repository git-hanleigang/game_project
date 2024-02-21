local ShopRulesLayer = class("ShopRulesLayer", BaseLayer)

function ShopRulesLayer:ctor()
    ShopRulesLayer.super.ctor(self)

    self:setLandscapeCsbName(SHOP_RES_PATH.InfoNode)
    self:setPortraitCsbName(SHOP_RES_PATH.InfoNode_Vertical)
    self:setExtendData("ShopRulesLayer")
end

function ShopRulesLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return ShopRulesLayer
