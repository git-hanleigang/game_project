--[[
    新版商城 滑动cell 第二货币
]]
local ShopBaseItemCellNode = util_require(SHOP_CODE_PATH.ShopBaseItemCellNode)
local ShopItemCellNodeGems = class("ShopItemCellNodeGems", ShopBaseItemCellNode)

function ShopItemCellNodeGems:initCsbNodes()
    ShopItemCellNodeGems.super.initCsbNodes(self)

    local nodeFirstPay = self:findChild("node_firstPay_banner") -- 首购显示标签
    nodeFirstPay:setVisible(false)
end

-- 子类重写
function ShopItemCellNodeGems:addItemIcon()
    local iconNode = util_createView(SHOP_CODE_PATH.ItemIconNode,SHOP_VIEW_TYPE.GEMS,self.m_index)
    self.m_nodeIcon:addChild(iconNode)
end

-- 子类重写
function ShopItemCellNodeGems:addNumbersNode()
    local numbersNode = util_createView(SHOP_CODE_PATH.ItemGemsNumNode,self.m_itemData,self.m_type, self.m_index)
    self.m_nodeNumber:addChild(numbersNode)
    numbersNode:setName("numberNode")
end

-- 子类重写
function ShopItemCellNodeGems:getCardData()
    local key = "GemStoreItem"
    return gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, key)
end

function ShopItemCellNodeGems:getItemData()
    local itemData = self.m_itemData:getExtraPropList()
    local key
    key = "GemStoreItem"
    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(itemData, key, self.m_itemData.p_price)
    end
    return itemData
end

-- 子类重写
function ShopItemCellNodeGems:getBuyType()
    return self.m_itemData:getBuyType()
end

-- 子类重写
function ShopItemCellNodeGems:getAddCoins()
    return self.m_itemData.p_gems
end

-- 子类重写
function ShopItemCellNodeGems:getShowLuckySpinView()
    return false
end

function ShopItemCellNodeGems:getBuyDataBaseNums(_buyData)
    return _buyData.p_gems
end

return ShopItemCellNodeGems
