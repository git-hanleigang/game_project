--[[
]]
local ShopBuckCell = class("ShopBuckCell", BaseView)

function ShopBuckCell:initDatas(_index, _cellData, _discount, _clickBuy)
    self.m_index = _index
    self.m_cellData = _cellData
    self.m_discount = _discount
    self.m_clickBuy = _clickBuy
end

function ShopBuckCell:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "ShopBuck/csb/shop/ShopBuck_Item_V.csb"
    end
    return "ShopBuck/csb/shop/ShopBuck_Item_H.csb"
end

function ShopBuckCell:initCsbNodes()
    self.m_nodeGuide = self:findChild("node_guide")
    self.m_lbBuck = self:findChild("lb_number")
    self.m_spBestValue = self:findChild("sp_bestvalue")
    self.m_nodeDiscount = self:findChild("node_discount")
    self.m_nodeLogo = self:findChild("node_logo")
    self.m_btnBuy = self:findChild("btn_buy")
    self.m_btnBuy:setSwallowTouches(false)

    self:startButtonAnimation("btn_buy", "sweep")
end

function ShopBuckCell:getUpCellGuide()
    return self.m_nodeGuide
end

function ShopBuckCell:initUI()
    ShopBuckCell.super.initUI(self)
    self:initView()
end

function ShopBuckCell:initView()
    self:initBuck()
    self:initPrice()
    self:initDiscount()
    self:initBestValue()
    self:initLogo()
end

function ShopBuckCell:initBuck()
    local buckNum = self.m_cellData:getBuckNum() or 0
    self.m_lbBuck:setString("X" .. buckNum)
end

function ShopBuckCell:initPrice()
    local price = self.m_cellData:getPrice() or 0
    self:setButtonLabelContent("btn_buy", "$" .. price)
end

function ShopBuckCell:initDiscount()
    if self.m_discount and self.m_discount > 0 then
        self.m_nodeDiscount:setVisible(true)
        if not self.m_zhekou then
            self.m_zhekou = util_createView("GameModule.ShopBuck.views.ShopBuckCellDiscount")
            self.m_nodeDiscount:addChild(self.m_zhekou)
        end
        self.m_zhekou:updateNum(self.m_discount)
    else
        self.m_nodeDiscount:setVisible(false)
    end
end

function ShopBuckCell:initBestValue()
    -- self.m_spBestValue:setVisible(self.m_cellData:isBestValue())
    self.m_spBestValue:setVisible(false)
end

function ShopBuckCell:initLogo()
    local logo = util_createAnimation("ShopBuck/csb/shop/ShopBuck_ItemIcon_" .. self.m_index .. ".csb")
    self.m_nodeLogo:addChild(logo)
end

function ShopBuckCell:onEnter()
    ShopBuckCell.super.onEnter(self)
end

function ShopBuckCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        if self.m_clickBuy then
            self.m_clickBuy(self.m_index)
        end
    end
end

return ShopBuckCell