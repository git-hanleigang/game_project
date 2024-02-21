--[[--
    钻石商城的钻石数量
]]
local BaseStoreItemNum = util_require("GameModule.Shop.shopItem.BaseStoreItemNum")
local ZQGemStoreItemNum = class("ZQGemStoreItemNum", BaseStoreItemNum)

function ZQGemStoreItemNum:getHasDiscount()
    local originalCoins = self.m_itemData.p_originalGems
    if originalCoins and originalCoins ~= 0 and (originalCoins < self.m_itemData.p_gems) then
        return true
    end    
    return false
end

function ZQGemStoreItemNum:getPlayerDiscount()
    -- 神像buff，额外增加第二货币
    if self.m_itemData and self.m_itemData.getStatueBuffDiscount then
        local statueBuffMul = self.m_itemData:getStatueBuffDiscount() -- 配置的是：1.3
        return statueBuffMul - 1 -- 返回：0.3
    end
    return 0 
end

function ZQGemStoreItemNum:getItemCoins()
    return self.m_itemData.p_originalGems or 0, self.m_itemData.p_gems or 0
end

return ZQGemStoreItemNum
