--[[--
    购买结算界面
    商城购买、促销购买、某些活动购买
]]
local BuyTip = class("BuyTip", BaseLayer)

------------------------------------------------------------------------
-- 工具函数 -------------------------------------------------------------
function BuyTip:initDatas()
    BuyTip.super.initDatas(self)
    self:setLandscapeCsbName(SHOP_RES_PATH.ShopBuyTipLayer)
    self:setPortraitCsbName(SHOP_RES_PATH.ShopBuyTipLayer_Vertical)
    self:setPauseSlotsEnabled(true)

    self.m_flyCoins = true
    self.m_catFoodList = {} --道具猫粮有单独的界面 cxc
    self.m_propsBagList = {} --道具 合0成福袋 有单独的界面 cxc
    self.m_levelRushList = {} --道具 levelRush 有单独的界面 cxc
    self.m_itemList = {} -- 新版buytips 修改需要把所有道具data 信息装起来做成 listview展示
    self.m_lotteryTickets = 0 -- 商城掉落的乐透劵数量 cxc
    self.m_vipPoint = 0
    self.m_baseCoin = toLongNumber(0)
end
-- function BuyTip:getCsbName()
--     local path = nil
--     if globalData.slotRunData.isPortrait then
--         path = "Shop_Res/BuyTip_Portrait.csb"
--     else
--         path = "Shop_Res/BuyTip.csb"
--     end
--     return path
-- end

function BuyTip:getTotalCoin()
    if self.m_storeType == BUY_TYPE.GEM_TYPE then
        local realGems = self.m_buyData.p_gems ~= nil and tonumber(self.m_buyData.p_gems) or 0
        if CardSysManager and CardSysManager.getBuffDataByType then
            local gemMulBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_GEMSHOP_GEM_BONUS)
            if gemMulBuff and gemMulBuff > 0 then
                realGems = realGems * gemMulBuff
            end
        end
        return realGems
    else
        return self.m_buyData.p_coins or 0
    end
end

function BuyTip:getTotalGem()
    local gems = 0
    local itemList = self:getItemList()
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local itemInfo = itemList[i]
            if itemInfo.key == "Gem" then
                gems = gems + itemInfo.data.p_num
            end
        end
    end
    return gems
end

function BuyTip:getVipPoint()
    local point = self.m_vipPoint
    if point and point > 0 then
        local vipPointsBoost = G_GetMgr(ACTIVITY_REF.VipPointsBoost):getRunningData()
        if vipPointsBoost  then
            local curPoints = vipPointsBoost:getLastPoints()
            local multiple = vipPointsBoost:getMultiple()
            if multiple > 0 and curPoints > 0 then
                if curPoints >= point * multiple then
                    point = point + point * multiple
                else
                    point = point + curPoints
                end
            end
        end
    end

    return point
end

function BuyTip:setVipPoint(vipPoint)
    if vipPoint and vipPoint > 0 then
        if self.m_storeType == "LuckySpinMainLayer" and self.m_buyData.p_displayList ~= nil then
            for i = 1, #self.m_buyData.p_displayList do
                local itemData = self.m_buyData.p_displayList[i]
                if itemData.p_item ~= ITEMTYPE.ITEMTYPE_VIPPOINT and string.find(itemData.p_icon, "Vip") then
                    vipPoint = vipPoint + itemData.p_num
                end
            end
        end
        self.m_vipPoint = vipPoint
    elseif self.m_storeType == BUY_TYPE.STORE_TYPE or self.m_storeType == BUY_TYPE.StorePet or self.m_storeType == BUY_TYPE.GEM_TYPE or self.m_storeType == BUY_TYPE.APP_CHARGE or self.m_storeType == BUY_TYPE.SHOP_DAILYSALE then
        local vipPoint = 0
        if self.m_buyData.p_displayList ~= nil then
            for i = 1, #self.m_buyData.p_displayList do
                local itemData = self.m_buyData.p_displayList[i]
                if itemData.p_item == ITEMTYPE.ITEMTYPE_VIPPOINT or string.find(itemData.p_icon, "Vip") then
                    vipPoint = vipPoint + itemData.p_num
                end
            end
        end
        self.m_vipPoint = vipPoint
    else
        self.m_vipPoint = self.m_buyData.p_vipPoint or 0
    end
    if G_GetMgr(ACTIVITY_REF.TripleVip) then
        local data = G_GetMgr(ACTIVITY_REF.TripleVip):getRunningData()
        if data then
            if self.m_vipPoint and self.m_vipPoint > 0 then
                self.m_vipPoint = self.m_vipPoint * 3
            end
        end
    end
end

function BuyTip:getClubPoint()
    return self.m_clubPoints
end

function BuyTip:setClubPoint(clubPoint)
    if clubPoint and clubPoint > 0 then
        self.m_clubPoints = clubPoint
    elseif self.m_storeType ~= BUY_TYPE.STORE_TYPE or self.m_storeType ~= BUY_TYPE.GEM_TYPE or self.m_storeType ~= BUY_TYPE.APP_CHARGE then -- 金币商城没有高倍场点数
        local purchaseData = gLobalItemManager:getCardPurchase(nil, self.m_buyData.p_price)
        self.m_clubPoints = purchaseData and purchaseData.p_clubPoints or 0
    end
end

function BuyTip:getItemList()
    local buyData = self.m_buyData
    local itemList = {}
    --显示普通层
    local storeType = self.m_storeType
    if storeType == "LuckySpinMainLayer" then
        if buyData.p_displayList ~= nil then
            for i = 1, #buyData.p_displayList do
                local itemData = buyData.p_displayList[i]
                if itemData.p_item ~= ITEMTYPE.ITEMTYPE_CLUBPOINT and itemData.p_item ~= ITEMTYPE.ITEMTYPE_VIPPOINT and not string.find(itemData.p_icon, "Vip") then -- vip单独显示
                    local var = itemData.p_num
                    itemList[#itemList + 1] = {key = itemData.p_icon, var = var, char = "+", data = itemData}
                end
            end
        end
    elseif storeType == BUY_TYPE.STORE_TYPE or storeType == BUY_TYPE.GEM_TYPE or storeType == BUY_TYPE.StorePet or storeType == BUY_TYPE.APP_CHARGE or storeType == BUY_TYPE.SHOP_DAILYSALE or storeType == BUY_TYPE.StoreHotSale then
        if buyData.p_displayList ~= nil then
            for i = 1, #buyData.p_displayList do
                local itemData = buyData.p_displayList[i]
                if itemData.p_item ~= ITEMTYPE.ITEMTYPE_CLUBPOINT and itemData.p_item ~= ITEMTYPE.ITEMTYPE_VIPPOINT and not string.find(itemData.p_icon, "Vip") then -- vip单独显示
                    local var = itemData.p_num
                    itemList[#itemList + 1] = {key = itemData.p_icon, var = var, char = "+", data = itemData}
                end
            end
        end
    elseif storeType == BUY_TYPE.SEVEN_DAY or storeType == BUY_TYPE.QUEST_SALE or storeType == BUY_TYPE.BINGO_SALE or storeType == BUY_TYPE.SEVEN_DAY_NO_COIN or storeType == BUY_TYPE.DiyComboDealSale then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
            end
        end
    elseif storeType == BUY_TYPE.LUCKYCHALLENGE_SALE or storeType == BUY_TYPE.ROUTINE_SALE then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                else
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.RICHMAN_SALE then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.BLAST_SALE or storeType == BUY_TYPE.COINPUSHER_SALE or storeType == BUY_TYPE.REDECOR_SALEor or storeType == BUY_TYPE.NEW_COINPUSHER_SALE 
    or storeType == BUY_TYPE.PIPECONNECT_SALE or storeType == BUY_TYPE.EGYPT_COINPUSHER_SALE or storeType == BUY_TYPE.PIPECONNECT_SPECIAL_SALE then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                --itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.MEMORY_FLYING or storeType == BUY_TYPE.NOVICE_MEMORY_FLYING then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.TopSale then
        if buyData.p_saleItems ~= nil and #buyData.p_saleItems > 0 then
            for i = 1, #buyData.p_saleItems do
                local tempItem = buyData.p_saleItems[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.KEEPRECHARGE or storeType == BUY_TYPE.NOVICE_KEEPRECHARGE then
        if buyData and buyData.p_items and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.CHOICE_TYPE or storeType == BUY_TYPE.CHOICE_TYPE_NOVICE or storeType == BUY_TYPE.DiyComboDealSale then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.SHORT_CARD_DRAW_LOW or storeType == BUY_TYPE.SHORT_CARD_DRAW_HIGH then
        -- todo
        -- if buyData.p_items ~= nil and #buyData.p_items > 0 then
        --     for i = 1, #buyData.p_items do
        --         local tempItem = buyData.p_items[i]
        --         if tempItem.p_type == "Item" then
        --             itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
        --         elseif tempItem.p_type == "Buff" then
        --             itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
        --         end
        --     end
        -- end
    elseif storeType == BUY_TYPE.SPECIALSALE_FIRST then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.FIRST_SALE_MULTI then
        if buyData.getItemList then
            local itemLsit = buyData:getItemList()
            for i = 1, #itemLsit do
                local tempItem = itemLsit[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.OUTSIDECAVE_SALE or storeType == BUY_TYPE.OUTSIDECAVE_SPECIAL_SALE then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                elseif tempItem.p_type == "Buff" then
                --itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_buffInfo.buffDuration, char = "+", data = tempItem}
                end
            end
        end
    elseif storeType == BUY_TYPE.HOLIDAY_NEW_STORE_SALE or storeType == BUY_TYPE.LUCKY_CHALLENGEV2_REFRESHSALE_BUY then
        if buyData.p_items ~= nil and #buyData.p_items > 0 then
            for i = 1, #buyData.p_items do
                local tempItem = buyData.p_items[i]
                if tempItem.p_type == "Item" then
                    itemList[#itemList + 1] = {key = tempItem.p_icon, var = tempItem.p_num, char = "+", data = tempItem}
                end
            end
        end
    end
    return itemList
end

-- 增加道具
function BuyTip:addItem(data, mul)
    data = G_GetMgr(G_REF.Shop):getDescShopItemData(data)
    local item = gLobalItemManager:createTipNode(data, nil, mul)
    if item then
        -- csc 2022-02-17 将创建出来的道具文本进行重新修改
        gLobalItemManager:setItemNodeByExtraData(data, item)
        -- csc 2022-01-28 新版商城需要加一个衬底
        local itemBgNode = util_csbCreate(SHOP_RES_PATH.ShopBuyTipItemNode)
        if itemBgNode then
            -- self.m_itemNode:addChild(itemBgNode)
            local nodeItem = itemBgNode:getChildByName("node_item")
            nodeItem:addChild(item)
            self.m_itemList[#self.m_itemList + 1] = gLobalItemManager:createOtherItemData(itemBgNode, 1)
        else
            -- self.m_itemNode:addChild(item)
            self.m_itemList[#self.m_itemList + 1] = gLobalItemManager:createOtherItemData(item, 1)
        end
    end
end

-- 打开界面的来源处
function BuyTip:setSource(source)
    self.m_source = source
end

function BuyTip:getSource()
    return self.m_source
end

-- 是否显示RepeatFreeSpin活动道具
function BuyTip:isRepeatFreeSpinAlive()
    if self.m_storeType == BUY_TYPE.GEM_TYPE then
        return false
    end
    return true
end

-- 工具函数 -------------------------------------------------------------
------------------------------------------------------------------------

function BuyTip:initUI()
    BuyTip.super.initUI(self)
    self:runCsbAction("idle", true, nil, 60)
end

function BuyTip:initCsbNodes()
    -- self:createCsb()

    self.m_rootNode = self:findChild("root")
    self.m_numNode = self:findChild("node_num")
    self.m_itemNode = self:findChild("node_item")
    self.m_titleSp1 = self:findChild("sp_title_1")
    self.m_titleSp2 = self:findChild("sp_title_2")

    self.m_coinLB = self:findChild("m_lb_totalCoin")
    self.m_gemLB = self:findChild("m_lb_totalGem")

    -- self:commonShow(self.m_rootNode)
end

-- function BuyTip:createCsb()
--     local isAutoScale = false
--     if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
--         isAutoScale = false
--     end
--     self:createCsbNode(self:getCsbName(), isAutoScale)
--     util_portraitAdaptLandscape(self.m_csbNode)
-- end

function BuyTip:initBuyTip(storeType, buyData, baseCoin, levelCount, func, reconnect, vipPoint, clubPoint, extraData)
    -- 初始化数据
    self.m_storeType = storeType
    self.m_buyData = buyData or {}
    if baseCoin then
        self.m_baseCoin:setNum(baseCoin)
    end
    -- if baseCoin and iskindof(baseCoin,"LongNumber") then
    --     self.m_baseCoin = baseCoin
    -- else
    --     self.m_baseCoin = baseCoin ~= nil and tonumber(baseCoin) or 0
    -- end
    self.m_levelUpCount = levelCount
    self.m_closeCallFunc = func
    self.m_reconnect = reconnect
    self.m_extraData = extraData

    self:setVipPoint(vipPoint)
    self:setClubPoint(clubPoint)

    if self.m_storeType == "LuckySpinMainLayer" or self.m_storeType == "LuckySpinMainV2" then
        self.m_luckySpin = true
    end

    -- 更新界面流程
    if toLongNumber(self.m_baseCoin) <= toLongNumber(0) then --没有钱的话 不显示钱数  不飞金币
        self.m_numNode:setVisible(false)
        self.m_titleSp2:setVisible(false)
        -- 将item节点位置上提
        local pos = cc.p(self.m_itemNode:getPosition())
        pos.y = pos.y + 60
        self.m_itemNode:setPosition(pos)
    end

    -- 钻石商城不显示二级标题
    if self.m_storeType == BUY_TYPE.GEM_TYPE then
        self.m_titleSp2:setVisible(false)
    end

    -- 检查是否飞金币
    if toLongNumber(self.m_baseCoin) <= toLongNumber(0) then
        self.m_flyCoins = false
    end
    if self.m_storeType == BUY_TYPE.TopSale or self.m_storeType == BUY_TYPE.StoreHotSale or self.m_storeType == BUY_TYPE.DiyComboDealSale or self.m_storeType == BUY_TYPE.FIRST_SALE_MULTI then
        local gems =self:getTotalGem()
        if gems > 0 then
            self.m_flyCoins = true
        end
    end

    self:setLogIap()
    self:updateIcon()
    self:updateTotalCoin()
    self:updateItem()
    self:updateLayout()
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function BuyTip:setLogIap()
    local baseCoin = self.m_baseCoin
    local vipPoint = self:getVipPoint()
    local totalCoins = toLongNumber(self:getTotalCoin())
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local levelInfo = vipData:getVipLevelInfo(preVipLevel)
    local newBaseCoin = 0
    if levelInfo and levelInfo.coinPackages and levelInfo.coinPackages ~= 0 then
        newBaseCoin = baseCoin / levelInfo.coinPackages
    else
        newBaseCoin = baseCoin
    end
    local vipCoins = baseCoin - newBaseCoin
    local otherCoins = totalCoins - baseCoin
    if gLobalSendDataManager.getLogIap ~= nil and gLobalSendDataManager:getLogIap().setAddCoins ~= nil then
        gLobalSendDataManager:getLogIap():setAddCoins(newBaseCoin, vipCoins, otherCoins, vipPoint)
    end
end

function BuyTip:updateIcon()
    local sp_gem = self:findChild("sp_icon_gem")
    local sp_coin = self:findChild("sp_icon_coin")
    if self.m_storeType == BUY_TYPE.GEM_TYPE then
        sp_gem:setVisible(true)
        sp_coin:setVisible(false)
    else
        sp_gem:setVisible(false)
        sp_coin:setVisible(true)
    end
end
function BuyTip:updateTotalCoin()
    local baseCoin = self.m_baseCoin
    local totalCoins = toLongNumber(self:getTotalCoin())
    local bonusCoin = LongNumber.max(totalCoins - baseCoin, toLongNumber(0))
    --总金币
    if toLongNumber(totalCoins) > toLongNumber(0) then
        local labCoin = nil
        if self.m_storeType == BUY_TYPE.GEM_TYPE then
            self.m_coinLB:setVisible(false)
            self.m_gemLB:setVisible(true)
            labCoin = self.m_gemLB
        else
            self.m_coinLB:setVisible(true)
            self.m_gemLB:setVisible(false)
            labCoin = self.m_coinLB
        end
        if labCoin then
            labCoin:setString(util_formatCoins(totalCoins))
            if globalData.slotRunData.isPortrait == true then
                self:updateLabelSize({label = labCoin}, 759)
            else
                self:updateLabelSize({label = labCoin}, 892)
            end
        end
    end
end

function BuyTip:updateItem()
    -- 基础金币
    if toLongNumber(self.m_baseCoin) > toLongNumber(0) then
        if self.m_storeType == BUY_TYPE.GEM_TYPE then
            self:addItem(gLobalItemManager:createLocalItemData("Gem", self.m_baseCoin))
        else
            self:addItem(gLobalItemManager:createLocalItemData("Coins", self.m_baseCoin))
        end
    end
    -- 额外金币
    local totalCoins = toLongNumber(self:getTotalCoin())
    local bonusCoin = LongNumber.max(totalCoins - self.m_baseCoin, toLongNumber(0))
    --local bonusCoin = math.max(totalCoins - self.m_baseCoin, 0)
    if toLongNumber(bonusCoin) > toLongNumber(0) then
        if self.m_storeType == BUY_TYPE.GEM_TYPE then
            -- TODO:MAQUN 额外的钻石也得做，目前缺少资源
            -- self:addItem(gLobalItemManager:createLocalItemData("ExtraGems", bonusCoin))
        elseif self.m_storeType == BUY_TYPE.STORE_TYPE or self.m_storeType ~= BUY_TYPE.APP_CHARGE or self.m_storeType == BUY_TYPE.SHOP_DAILYSALE then
            self:addItem(gLobalItemManager:createLocalItemData("ExtraCoins", bonusCoin))
        elseif self.m_storeType == "LuckySpinMainLayer" then -- csc 2022-02-16 luckyspin 购买也需要把额外获得的金币加上
            self:addItem(gLobalItemManager:createLocalItemData("ExtraCoins", bonusCoin))
        end
    end
    -- vip点
    local vipPoint = self:getVipPoint()
    if vipPoint ~= nil then
        if tonumber(vipPoint) > 0 then
            self:addItem(gLobalItemManager:createLocalItemData("Vip", vipPoint))
        end
    end
    -- 高倍场点
    local clubPoints = self:getClubPoint()
    if clubPoints ~= nil then
        if tonumber(clubPoints) > 0 then
            self:addItem(gLobalItemManager:createLocalItemData("DeluxeClub", clubPoints))
        end
    end
    -- buff
    if globalData.iapRunData.buyBuffItems and #globalData.iapRunData.buyBuffItems > 0 then
        local buyBuffItems = globalData.iapRunData.buyBuffItems
        for i = 1, #buyBuffItems do
            local buffData = buyBuffItems[i]
            if buffData.buffType == BUFFTYPY.BUFFTYPY_DOUBLE_EXP then
                self:addItem(gLobalItemManager:createLocalItemData("DoubleXP", buffData.buffExpire))
            end
        end
        globalData.iapRunData.buyBuffItems = nil
    end

    -- 获取通用奖励数据
    if globalData.saleRunData.getCommonRewardItemList then
        local commonItemList = globalData.saleRunData:getCommonRewardItemList(self:isRepeatFreeSpinAlive(), self.m_buyData.p_price)
        if commonItemList and #commonItemList > 0 then
            for i = 1, #commonItemList do
                local itemInfo = commonItemList[i]
                if self.m_luckySpin then
                    if string.find(itemInfo.key, "LuckyStamp") then -- 盖戳不能乘2，luckyspin的戳类型可能改变
                        self:addItem(itemInfo.data)
                    else
                        self:addItem(itemInfo.data, 2)
                    end
                else
                    if self.m_storeType == BUY_TYPE.TopSale then
                        if string.find(itemInfo.key, "LuckyStamp") then -- 盖戳不能乘2，luckyspin的戳类型可能改变
                            if globalData.saleRunData.getLuckyStampItemData then
                                local data_LS = globalData.saleRunData:getLuckyStampItemData(self.m_buyData.p_price)
                                self:addItem(data_LS)
                            end
                        else
                            self:addItem(itemInfo.data)
                        end
                    else
                        self:addItem(itemInfo.data)
                    end
                end
            end
        end
    end

    -- 道具
    self.m_catFoodList = {}
    self.m_propsBagList = {}
    self.m_levelRushList = {}
    self.m_lotteryTickets = 0
    local itemList = self:getItemList()
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local itemInfo = itemList[i]
            if self.m_luckySpin then
                -- self:addItem(itemInfo.data,2)
                self:addItem(itemInfo.data)
            else
                self:addItem(itemInfo.data)
            end
            -- 高倍场小游戏猫粮会有单独 弹板并且弹板顺序有逻辑
            if string.find(itemInfo.key, "CatFood") then
                itemInfo.data.p_num = itemInfo.var or itemInfo.data.p_num
                table.insert(self.m_catFoodList, itemInfo.data)
            end
            if string.find(itemInfo.key, "Pouch") then
                itemInfo.data.p_num = itemInfo.var or itemInfo.data.p_num
                table.insert(self.m_propsBagList, itemInfo.data)
            end
            if string.find(itemInfo.key, "LuckyFish") then
                itemInfo.data.p_num = itemInfo.var or itemInfo.data.p_num
                table.insert(self.m_levelRushList, itemInfo.data)
            end
            -- 商城掉落的乐透劵数量
            if string.find(itemInfo.key, "Lottery_icon") then
                itemInfo.data.p_num = itemInfo.var or itemInfo.data.p_num
                self.m_lotteryTickets = self.m_lotteryTickets + itemInfo.data.p_num
            end
        end
    end
end

-- 刷新最终布局目前写死了最大显示8个
function BuyTip:updateLayout()
    local count = #self.m_itemList
    if count <= 1 then
        return
    end
    -- csc 2022-02-12 新版商城 buytips 显示逻辑
    local size = cc.size(1100, 400)
    local maxConut = 4
    local scale = 1
    if globalData.slotRunData.isPortrait then
        size = cc.size(730, 400)
        maxConut = 4
        scale = 1
    end
    local rewardListView = gLobalItemManager:createRewardListView(self.m_itemList, size, maxConut, {width = 180, height = 180}, scale, {85, -85}, true)
    if rewardListView then
        local listView = rewardListView:getListView()
        listView:setScrollBarEnabled(false)
        self.m_itemNode:addChild(rewardListView)
    end
end

function BuyTip:nextTrigger()
    local canNext = true
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        canNext = gLobalIAPManager:getCurrRePayStatus()
    end

    if self.m_isForTopSale then
        local bagList,lotteryTickets = G_GetMgr(ACTIVITY_REF.Promotion_TopSale):getRememberBeforeData()
       
        local addlist = {}
        for i,v in ipairs(bagList) do
            local checkOut = false
            for j,bag in ipairs(self.m_propsBagList) do
                if v.p_icon == bag.p_icon then
                    bag.p_num = bag.p_num + v.p_num
                    checkOut = true
                    break
                end
            end
            if not checkOut then
                table.insert(self.m_propsBagList, v)
            end
        end

        self.m_lotteryTickets = self.m_lotteryTickets + lotteryTickets
    end

    -- 猫粮弹板 设置猫粮数据
    local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
    catManager:setPopCatFoodTempList(self.m_catFoodList)

    -- 合成福包弹板
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:setPopPropsBagTempList(self.m_propsBagList)

    -- levelrush 弹板
    gLobalLevelRushManager:setPopLevelRushTempList(self.m_levelRushList)
    -- 商城掉落的乐透劵数量
    G_GetMgr(G_REF.Lottery):setBuyTipDropTickets(self.m_lotteryTickets)

    -- 组装后续需要的结构
    local dataList = {}
    dataList.storeType = self.m_storeType
    dataList.buyData = self.m_buyData
    dataList.bLuckySpin = self.m_luckySpin
    dataList.extraData = self.m_extraData

    if not canNext then
        -- 如果后续还有多笔订单要补的情况下 需要处理一下盖章的流程
        release_print("----csc 还有后续补单,不允许弹出 ----")
        print("----csc 还有后续补单,不允许弹出 ----")
        return
    elseif G_GetMgr(ACTIVITY_REF.Promotion_TopSale):isWillShowTopSale() then
        G_GetMgr(ACTIVITY_REF.Promotion_TopSale):rememberBeforeData(self.m_propsBagList,self.m_lotteryTickets)
        G_GetMgr(ACTIVITY_REF.Promotion_TopSale):showTopSaleView(self.m_reconnect,dataList)
    elseif not self.m_reconnect then
        gLobalViewManager:checkBuyTipList(
            function()
                G_GetMgr(G_REF.Shop):buySuccessDropCard(dataList)
            end
        )
    else
        G_GetMgr(G_REF.Shop):buySuccessDropCard(dataList)
    end
end

function BuyTip:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    local callback = function()
        self:nextTrigger()
    end

    BuyTip.super.closeUI(self, callback)
end

function BuyTip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "Button_1" or "btn_Close" then
        if self.isClose then
            return
        end

        local closeFunc = function()
            if not tolua.isnull(self) then
                if self.m_closeCallFunc then
                    self.m_closeCallFunc()
                end
                self:closeUI()
            end
        end

        -- 购买后如果是钻石刷新界面 csc 2022-02-14 无论是不是购买的钻石商城,都刷新一下钻石
        -- if self.m_storeType == BUY_TYPE.GEM_TYPE then
        --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        -- end

        if self.m_flyCoins then
            self.m_flyCoins = false
            local btnCollect = self:findChild("Button_1")
            btnCollect:setTouchEnabled(false)
            local endPos = globalData.flyCoinsEndPos
            local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
            local addValue = self:getTotalCoin()
            local cuyMgr = G_GetMgr(G_REF.Currency)
            if cuyMgr then
                local cuyType = nil
                local info_Currency = {
                }
                if toLongNumber(addValue) > toLongNumber(0) then
                    cuyType = FlyType.Coin
                    if self.m_storeType == BUY_TYPE.GEM_TYPE then
                        cuyType = FlyType.Gem
                    end
                    table.insert(info_Currency,
                    {cuyType = cuyType, 
                    addValue = addValue,
                    startPos = startPos})
                end

                if self.m_storeType == BUY_TYPE.TopSale or self.m_storeType == BUY_TYPE.StoreHotSale or self.m_storeType == BUY_TYPE.DiyComboDealSale or self.m_storeType == BUY_TYPE.SPECIALSALE_FIRST or self.m_storeType == BUY_TYPE.FIRST_SALE_MULTI then
                    local gems =self:getTotalGem()
                    if gems > 0 then
                        if not cuyType then
                            cuyType = FlyType.Gem
                        end
                        table.insert(info_Currency,
                        {cuyType = FlyType.Gem, 
                        addValue = gems,
                        startPos = startPos})
                    end
                end
                if cuyType then
                    cuyMgr:playFlyCurrency(
                    info_Currency,
                    function()
                        closeFunc()
                    end
                )
                else
                    closeFunc()
                end
            else
                local baseCoins = globalData.topUICoinCount

                local view =
                    gLobalViewManager:pubPlayFlyCoin(
                    startPos,
                    endPos,
                    baseCoins,
                    self:getTotalCoin(),
                    function()
                        closeFunc()
                    end
                )
                view:setName("BuyTipFlyCoins")
            end
        else
            local _tip = gLobalViewManager:getViewByName("BuyTipFlyCoins")
            if not _tip then
                closeFunc()
            end
        end
    end
end

--商城最高档位付费后促销礼包功能 需要记录上一次数据
function BuyTip:setIsForTopSale(isfor)
    self.m_isForTopSale = isfor
end

return BuyTip
