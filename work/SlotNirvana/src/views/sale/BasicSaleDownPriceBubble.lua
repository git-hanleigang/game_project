--[[
    首充界面气泡
    降档时显示的气泡
]]
local BasicSaleDownPriceBubble = class("BasicSaleDownPriceBubble", BaseView)

function BasicSaleDownPriceBubble:getCsbName()
    local csbTheme = "Promotion/FirstCommonSale_normal"
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        csbTheme = "Promotion/FirstCommonSale_special"
    end
    return csbTheme .. "/Activity/FirstTimeSaleLayer_node_qipao_downprice.csb"
end

function BasicSaleDownPriceBubble:closeUI(_overFunc)
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:runCsbAction(
        "over",
        false,
        function()
            if not tolua.isnull(self) and self.removeFromParent then
                self:removeFromParent()
            end
            if _overFunc then
                _overFunc()
            end
        end,
        60
    )
end

function BasicSaleDownPriceBubble:onEnter()
    BasicSaleDownPriceBubble.super.onEnter(self)
    self:runCsbAction(
        "start",
        false,
        function()
            if not tolua.isnull(self) and self.runCsbAction then
                self:runCsbAction("idle", true, nil, 60)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if not tolua.isnull(self) and self.closeUI then
                self:closeUI()
            end
        end,
        3
    )
end

return BasicSaleDownPriceBubble
