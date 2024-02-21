--[[
    新版商城 滑动cell 第二货币
]]
local ShopBaseItemCellNode = util_require(SHOP_CODE_PATH.ShopBaseItemCellNode)
local ShopItemCellNodeMonthlyCard = class("ShopItemCellNodeMonthlyCard", ShopBaseItemCellNode)

function ShopItemCellNodeMonthlyCard:getCsbName()
    if self.m_isPortrait == true then
        return SHOP_RES_PATH.ItemCell_MonthlyCard_Vertical
    else
        return SHOP_RES_PATH.ItemCell_MonthlyCard
    end
end

function ShopItemCellNodeMonthlyCard:updateView()
    
end

function ShopItemCellNodeMonthlyCard:initCsbNodes()
    -- 读取csb 节点
    self.m_panelSize = self:findChild("layout_touch")
end

function ShopItemCellNodeMonthlyCard:refreshUiData(_index, _itemData)
    
end

function ShopItemCellNodeMonthlyCard:clickFunc(_sender)
    local name = _sender:getName()
    if G_GetMgr(G_REF.Shop):getShopClosedFlag() then
        return
    end
    if name == "btn_go" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 触发购买
        G_GetMgr(G_REF.MonthlyCard):showMainLayer()
    end
end

function ShopItemCellNodeMonthlyCard:doWitchLogic(params)
    
end
-- 子类重写
function ShopItemCellNodeMonthlyCard:getShowLuckySpinView()
    return false
end

function ShopItemCellNodeMonthlyCard:initExtra(switchKey)
end

function ShopItemCellNodeMonthlyCard:initTicket()
end

return ShopItemCellNodeMonthlyCard
