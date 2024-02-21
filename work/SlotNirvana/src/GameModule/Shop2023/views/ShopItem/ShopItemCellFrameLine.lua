--[[
    新版商城 滑动cell 分隔符
]]
local ShopItemCellFrameLine = class("ShopItemCellFrameLine", util_require("base.BaseView"))
function ShopItemCellFrameLine:initUI(_type, isPortrait)
    self.m_isPortrait = isPortrait or false
    local csbName = SHOP_RES_PATH.GemLineNode
    if _type == SHOP_VIEW_TYPE.COIN then
    elseif _type == SHOP_VIEW_TYPE.GEMS then
        if self.m_isPortrait then
            csbName = SHOP_RES_PATH.GemLineNode_Vertical
        else
            csbName = SHOP_RES_PATH.GemLineNode
        end
    end
    self:createCsbNode(csbName)

    self:updateView()
end

function ShopItemCellFrameLine:updateView()
end

return ShopItemCellFrameLine
