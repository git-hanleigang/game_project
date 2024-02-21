--[[
    首充界面气泡
    充值去广告
]]
local BasicSaleAdsBubble = class("BasicSaleAdsBubble", BaseView)

function BasicSaleAdsBubble:getCsbName()
    local csbTheme = "Promotion/FirstCommonSale_normal"
    if globalData.constantData.FIRST_COMMON_SALE_SPECIAL_THEME then
        csbTheme = "Promotion/FirstCommonSale_special"
    end
    return csbTheme .. "/Activity/csb/FirstTimeSale_qipao.csb"
end

function BasicSaleAdsBubble:playStart(_startCall)
    self:runCsbAction(
        "start",
        false,
        function()
            if not tolua.isnull(self) and self.runCsbAction then
                self:runCsbAction("idle", true, nil, 60)
            end
            if _startCall then
                _startCall()
            end
        end
    )
end

function BasicSaleAdsBubble:onEnter()
    BasicSaleAdsBubble.super.onEnter(self)
end

return BasicSaleAdsBubble
