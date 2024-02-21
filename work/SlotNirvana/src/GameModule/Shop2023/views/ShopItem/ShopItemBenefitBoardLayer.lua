local ShopItemBenefitBoardLayer = class("ShopItemBenefitBoardLayer", BaseLayer)

ShopItemBenefitBoardLayer.CELL_ITEM_NUM = 2 -- 每条cell 应该放 n 个道具

function ShopItemBenefitBoardLayer:ctor()
    ShopItemBenefitBoardLayer.super.ctor(self)
    self:setLandscapeCsbName(SHOP_RES_PATH.ItemBenefitBoard)
end
function ShopItemBenefitBoardLayer:initUI(_itemData,_storeType)
    ShopItemBenefitBoardLayer.super.initUI(self)
    self.m_itemData = _itemData
    self.m_storeType = _storeType
    self.m_listCell = {}
    self.m_itemList = clone(_itemData.p_displayList or {})
    if _storeType == SHOP_VIEW_TYPE.HOT then
        self.m_itemList = clone(_itemData:getBenefitDisplayList())
    end
    self:filtrateItem()
    self:updateView()
end

function ShopItemBenefitBoardLayer:initCsbNodes()
    self.m_listView = self:findChild("benefitsView")
end

function ShopItemBenefitBoardLayer:filtrateItem()
    local couponData = G_GetMgr(ACTIVITY_REF.Coupon):getRunningData()
    if couponData and not G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        local itemData = {}
        local couponItems = couponData:getShopGifts()
        for i,v in ipairs(self.m_itemList) do
            local insert = true
            for k,n in ipairs(couponItems) do
                if v.p_id == n.p_id then
                    insert = false
                    break
                end
            end        
            if insert then
                table.insert(itemData, v)
            end
        end
        self.m_itemList = itemData
    end
end

function ShopItemBenefitBoardLayer:updateView()
    self.m_listView:setScrollBarEnabled(false)
    -- 加载list view
    local itemList = self:getItemList()
    local itemCellNum =  (itemList ~= nil and table.nums(itemList) > 0) and #itemList or 0

    -- 计算出应该添加几条 cell
    -- 每行两个任务 ，算出当前一共可以放几行，向上取整数
    local rowSize = math.ceil(itemCellNum / self.CELL_ITEM_NUM) 
    for i = 1 ,rowSize do
        local cell = util_createView(SHOP_CODE_PATH.ItemBenefitBoardCellNode)
        local cellLayout = ccui.Layout:create()
        cellLayout:setContentSize({width = 910, height = 140})
        cellLayout:addChild(cell)
        self.m_listView:pushBackCustomItem(cellLayout)
        table.insert(self.m_listCell,cell)
    end
    -- 获得数据传入创建好的条
    local iSum = 0
    local itemDataInfo = {}
    for i = 1 ,#itemList do
        local itemData = itemList[i]
        if itemData then
            iSum = iSum + 1
            table.insert(itemDataInfo,itemData)
            if iSum == self.CELL_ITEM_NUM or (i == #itemList and iSum == 1) then
                local index = i/iSum == i and rowSize or i/iSum
                self.m_listCell[index]:updateView(itemDataInfo)
                iSum = 0
                itemDataInfo = {}
            end
        end
    end

end

function ShopItemBenefitBoardLayer:getItemList()
    local extraPropList = self.m_itemList
    if extraPropList == nil or #extraPropList <= 0 then
        return nil
    end

    local tipSource = nil
    if self.m_storeType == SHOP_VIEW_TYPE.COIN then
        tipSource = "CoinStoreTip"
    elseif self.m_storeType == SHOP_VIEW_TYPE.GEMS then
        tipSource = "GemStoreTip"
    elseif self.m_storeType == SHOP_VIEW_TYPE.PET then
        tipSource = "CoinStoreTip"
    end
    --获得根据支付金额生成赠送的集卡道具
    local cardItemData = gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, tipSource)
    if cardItemData then    
        table.insert(extraPropList,1,cardItemData)
    end

    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(extraPropList, tipSource, self.m_itemData.p_price)
    end

    return extraPropList
end

function ShopItemBenefitBoardLayer:clickFunc(sender)
    if self.isClose then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        self:closeUI()
    end
end

-- 重写父类方法
function ShopItemBenefitBoardLayer:onShowedCallFunc()

end

function ShopItemBenefitBoardLayer:onEnter()
    ShopItemBenefitBoardLayer.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)
        if self.closeUI then
            self:closeUI() 
        end
    end ,ViewEventType.NOTIFY_SHOPINFO_CLOSE)

    -- 跨天刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                if self.closeUI then
                    self:closeUI() 
                end
            end
        end,
        ViewEventType.NOTIFY_NEWZEROUPDATE
    )
end

return ShopItemBenefitBoardLayer
