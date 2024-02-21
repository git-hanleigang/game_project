--[[
    新版商城 滑动cell 第二货币
]]
local ShopBaseItemCellNode = util_require(SHOP_CODE_PATH.ShopBaseItemCellNode)
local ShopItemCellNodeHotSale = class("ShopItemCellNodeHotSale", ShopBaseItemCellNode)


function ShopItemCellNodeHotSale:updateView()
    ShopItemCellNodeHotSale.super.updateView(self)
    self:addTimeNode()
    local leftBuyTimes = self.m_itemData:getLeftBuyTimes()
    self:updateBtnColor(leftBuyTimes <= 0)
end

function ShopItemCellNodeHotSale:loadDataUI()
    ShopItemCellNodeHotSale.super.loadDataUI(self)
    if self.m_itemData:isPetSale() then
        local node_pet_info = self:findChild("node_pet_info")
        local infoNode = util_createView(SHOP_CODE_PATH.ItemPetInfoNode)
        node_pet_info:addChild(infoNode)

        local node_pet_level = self:findChild("node_pet_level")
        local levelNode = util_createView(SHOP_CODE_PATH.ItemPetLevelNode)
        node_pet_level:addChild(levelNode)
    end
end

function ShopItemCellNodeHotSale:refreshUiData(_index, _itemData)
    self.m_index = _index
    self.m_itemData = _itemData
    -- 刷新number节点
    local numberNode = nil
    if self.m_nodeNumber then
        numberNode = self.m_nodeNumber:getChildByName("numberNode")
    end
    if self.m_nodeNumber_special then
        numberNode = self.m_nodeNumber_special:getChildByName("numberNode")
    end
    if numberNode then
        numberNode:updateItemDataUI(_itemData, self.m_type)
    end
    self:loadDataUI()
    self:updatePayTimes()
    local leftBuyTimes = self.m_itemData:getLeftBuyTimes()
    self:updateBtnColor(leftBuyTimes <= 0)
end

-- 子类重写
function ShopItemCellNodeHotSale:addItemIcon()
    local path = self.m_itemData:getSpecialPath()
    local iconNode = util_createView(SHOP_CODE_PATH.ItemIconNode,SHOP_VIEW_TYPE.HOT,path)
    self.m_nodeIcon:addChild(iconNode)
    self.m_itemIconNode = iconNode
end

-- 子类重写
function ShopItemCellNodeHotSale:addNumbersNode()
    if self.m_nodeNumber then
        local numbersNode = util_createView(SHOP_CODE_PATH.ItemReCommendNumNode,self.m_itemData,self.m_type)
        self.m_nodeNumber:addChild(numbersNode)
        numbersNode:setName("numberNode")
    elseif self.m_nodeNumber_special then
        local numbersNode = util_createView(SHOP_CODE_PATH.ItemReCommendNumNode,self.m_itemData,self.m_type)
        self.m_nodeNumber_special:addChild(numbersNode)
        numbersNode:setName("numberNode")
    end
end

-- 子类重写
function ShopItemCellNodeHotSale:getCardData()
    local key = "GemStoreItem"
    return gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, key)
end

function ShopItemCellNodeHotSale:getItemData()
    local itemData = self.m_itemData:getExtraPropList()
    local key
    key = "GemStoreItem"
    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(itemData, key, self.m_itemData.p_price)
    end
    local newdata = {}
    if itemData and #itemData > 0 then
        for i,v in ipairs(itemData) do
            if string.find(v.p_icon, "Sidekicks_levelUp") then
                table.insert(newdata,v)
            end
            if string.find(v.p_icon, "Sidekicks_starUp") then
                table.insert(newdata,v)
            end
        end
        for i,v in ipairs(itemData) do
            if v.p_icon ~= "Sidekicks_levelUp" and v.p_icon ~= "Sidekicks_starUp" then
                table.insert(newdata,v)
            end
        end
    end
    return newdata
end

-- 子类重写
function ShopItemCellNodeHotSale:getBuyType()
    return self.m_itemData:getBuyType()
end

-- 子类重写
function ShopItemCellNodeHotSale:getAddCoins()
    if  self:getBuyType() == BUY_TYPE.GEM_TYPE then
        return self.m_itemData.p_gems
    else
        return self.m_itemData.p_coins
    end
end

function ShopItemCellNodeHotSale:doWitchLogic(params)
    
end
-- 子类重写
function ShopItemCellNodeHotSale:getShowLuckySpinView()
    return false
end

function ShopItemCellNodeHotSale:getBuyDataBaseNums(_buyData)
    if  self:getBuyType() == BUY_TYPE.GEM_TYPE then
        return _buyData.p_gems
    else
        return _buyData.p_coins
    end
end

function ShopItemCellNodeHotSale:doBuyLogic()
    local buyShopData = self.m_itemData
    if buyShopData == nil then
        return
    end
    local dataleftTime = self.m_itemData:getLeftTime()
    if dataleftTime <= 0 then
        return
    end
    local leftBuyTimes = self.m_itemData:getLeftBuyTimes()
    if leftBuyTimes <= 0 then
        return
    end

    self.m_preBuyShowData = buyShopData
    self:checkCouponSwitch()
    globalData.iapRunData.p_contentId = not G_GetMgr(G_REF.Shop):getPromomodeOpen()
    if self:getBuyType() == BUY_TYPE.StoreHotSale then
        globalData.iapRunData.p_contentId = self.m_itemData:getStoreBuyId()
    end
    G_GetMgr(G_REF.Shop):requestBuyItem(self:getBuyType(), self.m_preBuyShowData, self:getAddCoins(), function ()
        if  not tolua.isnull(self) then
            self:buySuccess()
        end
    end , function ()
        if  not tolua.isnull(self)  then
            self:buyFailed()
        end
    end)
end


return ShopItemCellNodeHotSale
