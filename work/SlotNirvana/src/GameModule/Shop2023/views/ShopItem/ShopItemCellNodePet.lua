--[[
    新版商城 滑动cell 第二货币
]]
local ShopBaseItemCellNode = util_require(SHOP_CODE_PATH.ShopBaseItemCellNode)
local ShopItemCellNodePet = class("ShopItemCellNodePet", ShopBaseItemCellNode)

function ShopItemCellNodePet:initCsbNodes()
    ShopItemCellNodePet.super.initCsbNodes(self)

    local nodeFirstPay = self:findChild("node_firstPay_banner") -- 首购显示标签
    nodeFirstPay:setVisible(false)
    self.m_bg = self:findChild("img_bg")
    self.m_bg1 = self:findChild("img_bg1")
end

function ShopItemCellNodePet:loadDataUI()
    ShopItemCellNodePet.super.loadDataUI(self)
    if self.m_itemData:isPetSale() then
        local node_pet_level = self:findChild("Shop2023_pet_level")
        if node_pet_level then
            local levelNode = util_createView(SHOP_CODE_PATH.ItemPetLevelNode)
            node_pet_level:addChild(levelNode)
        end
    end
    self:updataBg()
end

function ShopItemCellNodePet:updataBg()
    if tonumber(self.m_itemData:getDisPlay()) == 1 then
        self.m_bg:setVisible(true)
        self.m_bg1:setVisible(false)
        self:findChild("sp_benefits_bg"):setVisible(true)
        self:findChild("sp_benefits_bg1"):setVisible(false)
        self:findChild("btn_benefits_info"):setVisible(true)
        self:findChild("btn_benefits_info1"):setVisible(false)
    else
        self.m_bg:setVisible(false)
        self.m_bg1:setVisible(true)
        self:findChild("sp_benefits_bg"):setVisible(false)
        self:findChild("sp_benefits_bg1"):setVisible(true)
        self:findChild("btn_benefits_info"):setVisible(false)
        self:findChild("btn_benefits_info1"):setVisible(true)
    end
end

-- 子类重写
function ShopItemCellNodePet:addItemIcon()
    local iconNode = util_createView(SHOP_CODE_PATH.ItemIconNode,SHOP_VIEW_TYPE.PET,self.m_index)
    if self.m_isPortrait == true then
        iconNode:setPositionX(20)
    end
    self.m_nodeIcon:addChild(iconNode)
end

-- 子类重写
function ShopItemCellNodePet:addNumbersNode()
    if self.m_itemData:getPetNum() and self.m_itemData:getPetNum() > 1 then
        local node = util_createAnimation(SHOP_RES_PATH.ItemNumber)
        local label = node:findChild("shuzi")
        label:setString(self.m_itemData:getPetNum())
        self.m_nodeNumber:addChild(node)
    end
end

-- 子类重写
function ShopItemCellNodePet:getCardData()
    local key = "GemStoreItem"
    return gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, key)
end

function ShopItemCellNodePet:getItemData()
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

function ShopItemCellNodePet:addRewardInfo()
    for i = #self.m_benefitItemList, 1, -1 do
        local node = self.m_benefitItemList[i]
        node:removeFromParent()
        table.remove(self.m_benefitItemList, i)
    end

    local cardData = self:getCardData()
    local rewardItemDatas = clone(self:getItemData())
    local index = 1
    local offX = 0 --X偏移
    --有卡牌第一个位置放卡牌
    -- if cardData then
    --     local cardItem = self:createPropNode(cardData)
    --     local benefitNode = self:getBenefitNode(index)
    --     if cardItem then
    --         benefitNode:addChild(cardItem)
    --         index = index + 1 --跳过一个
    --     end
    --     if self.m_isPortrait == true then
    --         offX = 0
    --     end
    --     table.insert(self.m_benefitItemList, cardItem)
    -- end
    table.insert(rewardItemDatas,2,cardData)

    for i = 1, #rewardItemDatas do
        local data = rewardItemDatas[i]
        local propNode = self:createPropNode(data)
        if propNode then
            local benefitNode = self:getBenefitNode(index)
            if benefitNode then
                benefitNode:addChild(propNode)
                propNode:setPositionX(offX)
                table.insert(self.m_benefitItemList, propNode)
                if self.m_itemData:isBig() and index == 6 then
                    break
                elseif index == 4 then
                    break
                end
            end
            index = index + 1
        end
    end
end

-- 子类重写
function ShopItemCellNodePet:getBuyType()
    return self.m_itemData:getBuyType()
end

-- 子类重写
function ShopItemCellNodePet:getAddCoins()
    return 0
end

-- 子类重写
function ShopItemCellNodePet:getShowLuckySpinView()
    return false
end

function ShopItemCellNodePet:getBuyDataBaseNums(_buyData)
    return 0
end

return ShopItemCellNodePet
