--[[--
    推荐位商城的金币数量
]]
local ShopBaseItemNum = util_require(SHOP_CODE_PATH.ShopBaseItemNum)
local ShopItemRecommendNumNode = class("ShopItemRecommendNumNode", ShopBaseItemNum)

-- 子类重写
function ShopItemRecommendNumNode:getCsbName()
    if self.m_itemData:isGolden()  then
        return SHOP_RES_PATH.ItemNumber_special
    end
    return SHOP_RES_PATH.ItemNumber
end
-- 重写
function ShopItemRecommendNumNode:initCsbNodes()
    ShopItemRecommendNumNode.super.initCsbNodes(self)
    self.m_baseNumberLabel = self:findChild("lab_cut_rec")
    self.m_linesp = self:findChild("spr_line_rec")
    self.m_nodeBase = self:findChild("node_recommendPos")
end

function ShopItemRecommendNumNode:getHasDiscount()
    local originalCoins = self.m_itemData.p_originalCoins
    if originalCoins and originalCoins ~= 0 and (originalCoins < self.m_itemData.p_coins) then
        return true
    end
    return false
end

function ShopItemRecommendNumNode:getItemNumbers()
    return self.m_itemData.p_originalCoins or 0, self.m_itemData.p_coins or 0
end

function ShopItemRecommendNumNode:initNumbersLb()
    self:findChild("sp_coin"):setVisible(true)

    local sprCoin = self:findChild("sp_coin")
    --local baseCoins, coins = self:getShowNumbers()
    -- if globalData.slotRunData.isPortrait == true then
    --     self.m_currNumberLabel:setPositionY(-10)
    -- end
    -- self.m_currNumberLabel:setString(util_getFromatMoneyStr(coins))
    -- util_alignCenter(
    --     {
    --         {node = sprCoin, alignX = 5},
    --         {node = self.m_currNumberLabel, alignX = 5}
    --     },nil,310
    -- )
    -- -- self:setDisCountNodePos()
    -- self:setBaseNum(baseCoins)
    ShopItemRecommendNumNode.super.initNumbersLb(self)
end

function ShopItemRecommendNumNode:getShowNumbers()
    local coins = self.m_itemData:getCoins()
    --local orginCoin, curCoin = self:getItemNumbers()

    -- -- 特殊逻辑：
    -- local extraMul = self:getExtraMulti()
    -- if extraMul > 0 then
    --     curCoin = curCoin * (1 + extraMul)
    -- end

    return coins, coins
end

function ShopItemRecommendNumNode:setCurNum(coins)
    self.m_coins = coins

    local sprCoin = self:findChild("sp_coin")
    if sprCoin then
        sprCoin:setVisible(true)
    end
    self.m_currNumberLabel:setString(util_getFromatMoneyStr(coins))
    util_alignCenter(
        {
            {node = sprCoin, alignX = 5},
            {node = self.m_currNumberLabel, alignX = 5}
        },
        nil,
        310
    )
end

function ShopItemRecommendNumNode:initView(_itemData)
    self.m_itemData = _itemData

    local baseCoins, coins = self:getShowNumbers()
    self.m_curCoins = baseCoins
    self:setCurNum(self.m_curCoins)
end

return ShopItemRecommendNumNode
