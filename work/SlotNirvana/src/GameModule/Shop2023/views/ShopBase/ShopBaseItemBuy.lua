--[[
]]

local ShopBaseItemBuy = class("ShopBaseItemBuy", BaseView)

function ShopBaseItemBuy:initDatas(_buyType, _clickBuy)
    self.m_buyType = _buyType
    self.m_clickBuy = _clickBuy
end

function ShopBaseItemBuy:getCsbName()
    return SHOP_RES_PATH.ItemCell_BtnBuy
end

function ShopBaseItemBuy:initCsbNodes()
    self.m_btnBuy = self:findChild("btn_buy")
    self.m_btnBuy:setSwallowTouches(false)

    -- 商城中的按钮是normal2，字体的长度受左右挂件的影响，需要缩放
    local label_1 = self:findChild("label_1")
    self:updateLabelSize({label = label_1, sx = sx, sy = sx}, 130)
end

function ShopBaseItemBuy:initUI()
    ShopBaseItemBuy.super.initUI(self)
    self:initView()
end

function ShopBaseItemBuy:initView()
    self:updateBtnBuck()
end

function ShopBaseItemBuy:updateBtnBuck()
    self:setBtnBuckVisible(self.m_btnBuy, self.m_buyType)    
end

function ShopBaseItemBuy:updatePrice(_priceStr)
    if _priceStr ~= nil then
        self:setButtonLabelContent("btn_buy", _priceStr)
    end
end

function ShopBaseItemBuy:updateBtnColor(_isGrey)
    if _isGrey then
        self.m_btnBuy:setColor(cc.c3b(127, 127, 127)) 
    else
        self.m_btnBuy:setColor(cc.c3b(255, 255, 255))
    end    
end

function ShopBaseItemBuy:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        if self.m_clickBuy then
            self.m_clickBuy()
        end
    end
end

return ShopBaseItemBuy