--[[
    首充界面折上折
]]
local FirstSaleB_NoCoinsPrice = class("FirstSaleB_NoCoinsPrice", BaseView)

function FirstSaleB_NoCoinsPrice:getCsbName()
    local csbTheme = "Promotion/FirstCommonSale_normal"
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        csbTheme = "Promotion/FirstCommonSale_special"
    end
    return csbTheme .. "/Activity/csb/FirstTimeSaleB_node_price.csb"
end

function FirstSaleB_NoCoinsPrice:initDatas(_data)
    self.m_saleData = _data
end

function FirstSaleB_NoCoinsPrice:initCsbNodes()
    self.m_lb_price = self:findChild("lb_price")
    self.m_lb_price_new = self:findChild("lb_price_new")
    self.m_lb_price:setVisible(false)
end

function FirstSaleB_NoCoinsPrice:initUI()
    FirstSaleB_NoCoinsPrice.super.initUI(self)

    self:initView()
    self:runCsbAction("idle_end", true)
end

function FirstSaleB_NoCoinsPrice:initView()
    self.m_lb_price:setString("$" .. self.m_saleData.p_fakePrice)
    self.m_lb_price_new:setString("$" .. self.m_saleData.p_price)
end

function FirstSaleB_NoCoinsPrice:onEnter()
    FirstSaleB_NoCoinsPrice.super.onEnter(self)

    -- local isAction = gLobalDataManager:getStringByField("firstSaleNoCoinsIsACtion", "", false) --保存的价格
    -- if isAction == "" then
    --     self:runCsbAction("idle_end", true)

    --     -- self:runCsbAction(
    --     --     "start",
    --     --     false,
    --     --     function()
    --     --         self:runCsbAction("idle_end", true)
    --     --     end
    --     -- ,60)

    --     -- gLobalDataManager:setStringByField("firstSaleNoCoinsIsACtion", "isHide")
    -- else
    --     self:runCsbAction("idle_new", false, nil, 60)
    -- end
end

return FirstSaleB_NoCoinsPrice
