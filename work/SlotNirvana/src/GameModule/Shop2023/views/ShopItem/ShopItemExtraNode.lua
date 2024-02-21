local ShopItemExtraNode = class("ShopItemExtraNode",util_require("base.BaseView"))


function ShopItemExtraNode:initDatas(isShow)
    self.m_initShow = isShow
end

function ShopItemExtraNode:initUI()
    self:createCsbNode(SHOP_RES_PATH.ItemExtraNode)

    self.m_isShowed = false
    self.m_isHided = false
    if self.m_initShow then
        self:onShow()
    else
        self:onHide()
    end
end

function ShopItemExtraNode:setDiscountValue(value)
    self:findChild("lb_extra"):setString(tostring(value) .. "%")    
end

function ShopItemExtraNode:onShow()
    self.m_isShowed = true
    self:runCsbAction("idle2",false)
end

function ShopItemExtraNode:playShow()
    if self.m_isShowed then
        return
    end
    self:runCsbAction("start",false,function ()
        self.m_isShowed = true
        self.m_isHided = false
        self:runCsbAction("idle2",false)
    end)

end

function ShopItemExtraNode:playHide()
    if self.m_isHided then
        return
    end
    self:runCsbAction("over",false,function ()
        self:runCsbAction("idle1",false)
        self.m_isShowed = false
        self.m_isHided = true
    end)
end

function ShopItemExtraNode:onHide()
    self.m_isHided = true
    self:runCsbAction("idle1",false)
end

return ShopItemExtraNode