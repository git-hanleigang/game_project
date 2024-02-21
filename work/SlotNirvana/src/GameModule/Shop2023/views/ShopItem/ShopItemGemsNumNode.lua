--[[--
    钻石商城的钻石数量
]]
local ShopBaseItemNum = util_require(SHOP_CODE_PATH.ShopBaseItemNum)
local ShopItemGemsNumNode = class("ShopItemGemsNumNode", ShopBaseItemNum)

function ShopItemGemsNumNode:getHasDiscount()
    local originalCoins = self.m_itemData.p_originalGems
    if originalCoins and originalCoins ~= 0 and (originalCoins < self.m_itemData.p_gems) then
        return true
    end    
    return false
end

function ShopItemGemsNumNode:getPlayerDiscount()
    -- 神像buff，额外增加第二货币
    if self.m_itemData and self.m_itemData.getStatueBuffDiscount then
        local statueBuffMul = self.m_itemData:getStatueBuffDiscount() -- 配置的是：1.3
        return statueBuffMul - 1 -- 返回：0.3
    end
    return 0 
end

function ShopItemGemsNumNode:getItemNumbers()
    return self.m_itemData.p_originalGems or 0, self.m_itemData.p_gems or 0
end

-- function ShopItemGemsNumNode:initNumbersLb()
--     local baseNums, nums = self:getShowNumbers()
--     self.m_currNumberLabel:setString(util_getFromatMoneyStr(nums))
--     -- self:setDisCountNodePos()
--     self:setBaseNum(baseNums)
-- end

function ShopItemGemsNumNode:setCurNum(nums)
    self.m_coins = nums
    self.m_currNumberLabel:setString(util_getFromatMoneyStr(nums))
end

return ShopItemGemsNumNode
