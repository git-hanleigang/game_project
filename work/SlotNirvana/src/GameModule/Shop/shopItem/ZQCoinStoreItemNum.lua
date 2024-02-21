--[[--
    金币商城的金币数量
]]
local BaseStoreItemNum = util_require("GameModule.Shop.shopItem.BaseStoreItemNum")
local ZQCoinStoreItemNum = class("ZQCoinStoreItemNum", BaseStoreItemNum)

function ZQCoinStoreItemNum:getHasDiscount()
    local originalCoins = self.m_itemData.p_originalCoins
    if originalCoins and originalCoins ~= 0 and (originalCoins < self.m_itemData.p_coins) then
        return true
    end
    return false
end

function ZQCoinStoreItemNum:getItemCoins()
    return self.m_itemData.p_originalCoins or 0, self.m_itemData.p_coins or 0
end

return ZQCoinStoreItemNum
