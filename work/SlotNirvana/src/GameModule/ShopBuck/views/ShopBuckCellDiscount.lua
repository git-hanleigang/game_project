--[[
]]
local ShopBuckCellDiscount = class("ShopBuckCellDiscount", BaseView)

function ShopBuckCellDiscount:initDatas()
end

function ShopBuckCellDiscount:getCsbName()
    return "ShopBuck/csb/shop/ShopBuck_Discount.csb"
end

function ShopBuckCellDiscount:initCsbNodes()
    self.m_lbNum = self:findChild("lb_numberdis")
end

function ShopBuckCellDiscount:initUI()
    ShopBuckCellDiscount.super.initUI(self)
end

function ShopBuckCellDiscount:updateNum(_num)
    self.m_num = _num
    self.m_lbNum:setString(self.m_num)
end

return ShopBuckCellDiscount