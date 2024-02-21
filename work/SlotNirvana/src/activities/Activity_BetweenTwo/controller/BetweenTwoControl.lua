--二选一购买活动
local BetweenTwoControl = class("BetweenTwoControl", BaseActivityControl)

-- 构造函数
function BetweenTwoControl:ctor()
    BetweenTwoControl.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.BetweenTwo)
end
-- 获取 活动数据
function BetweenTwoControl:getActData()
    if self.m_actData then
        return self.m_actData
    end
    self.m_actData = self:getRunningData()
    return self.m_actData
end
-- 获取 活动数据
function BetweenTwoControl:getSaleData()
    local data = self:getActData()
    if data then
        return data:getSaleItem()
    end
end
--获取促销数据中的道具
-- cxc 2021-03-19 10:53:26 二选一的 卡片显示逻辑 cardResult or 促销数据里的道具卡(只配一个)
function BetweenTwoControl:getSaleRewardItem() 
    local data = self:getActData()
    if data then
        return data:getSaleRewardItem()
    end
end

--获取卡片信息
function BetweenTwoControl:getCardResult()
    local data = self:getActData()
    if data then
        return data:getCardResult()
    end
end

--获取水果id
function BetweenTwoControl:getFruitId(index)
    local data = self:getActData()
    if data then
        return data:getFruitId(index)
    end
    return -1
end
--是否没有购买过
function BetweenTwoControl:isFirst()
    local data = self:getActData()
    if data then
        return data:isFirst()
    end
    return false
end
--是否完成
function BetweenTwoControl:isCompleted()
    local data = self:getActData()
    if data then
        return data:isActivityFinish()
    end
    return false
end
-- 获取 活动是否结束le
function BetweenTwoControl:isOverGame()
    local actData = self:getData()
    if not actData or actData:getLeftTime()== 0 then
        return true
    end
    return false
end
--是否完成变暗
function BetweenTwoControl:checkDark(fruitId)
    if not self:isCompleted() then
        return false
    end
    local data = self:getActData()
    if data and not data:isSelect(fruitId) then
        --存在数据并且不是选择的水果变暗
        return true
    end
    return false
end
function BetweenTwoControl:setMainLayer(view)
    self.m_mainView = view
    self:initIapLog()
end
function BetweenTwoControl:clearMainLayer()
    self.m_mainView = nil
    self.m_removeWaiting = nil
    self.m_winMaskLayer = nil
    self.bl_onBuy = false
    self.m_index = nil
end

--显示主界面
function BetweenTwoControl:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    
    local view = util_createFindView("Activity/Activity_BetweenTwo")
    gLobalViewManager:showUI(view)
end
--遮罩
function BetweenTwoControl:addMaskLayer()
    if tolua.isnull(self.m_mainView) then
        return
    end
    if not self.m_winMaskLayer then
        self.m_winMaskLayer = util_newMaskLayer()
        self.m_mainView:addLightMask(self.m_winMaskLayer)
    end
end
--清空遮罩
function BetweenTwoControl:removeMaskLayer()
    if tolua.isnull(self.m_mainView) then
        return
    end
    if self.m_removeWaiting then
        return
    end
    if self.m_winMaskLayer and not tolua.isnull(self.m_winMaskLayer) then
        self.m_removeWaiting = true
        self.m_winMaskLayer:runAction(cc.FadeOut:create(0.5))
        performWithDelay(self.m_mainView,function()
            self.m_removeWaiting = nil
            self.m_winMaskLayer:removeFromParent()
            self.m_winMaskLayer = nil
        end,0.5)
    end
end
--食物高亮
function BetweenTwoControl:playFoodLight(index)
    if tolua.isnull(self.m_mainView) then
        return
    end
    self.m_mainView:playFoodLight(index)
    self:addMaskLayer()
end
--取消高亮
function BetweenTwoControl:hideFoodLight(index)
    if tolua.isnull(self.m_mainView) then
        return
    end
    self.m_mainView:hideFoodLight(index)
    self:removeMaskLayer()
end

--显示提示
function BetweenTwoControl:showStoreItemTip()
    local saleData = self:getSaleData()
    if not saleData then
        return
    end
    local itemList = gLobalItemManager:checkAddLocalItemList(saleData)
    local view = util_createView("Activity.BetweenCode.BetweenTwoTips", itemList)
    self.m_mainView:addChild(view)
    view:setPosition(display.center)
end
--初始化打点信息
function BetweenTwoControl:initIapLog()
    local goodsInfo = {}
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "limitBuy"
    purchaseInfo.purchaseName = "SweetSale"
    purchaseInfo.purchaseStatus = ""
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo,nil,nil,self)
end
--购买水果
function BetweenTwoControl:buyFruit(index)
    local saleData = self:getSaleData()
    if not saleData then
        return
    end
    if self.bl_onBuy then
        return
    end
    self.bl_onBuy = true
    self.m_index = index
    local fruitId = self:getFruitId(index)
    local discounts = 0
    local goodsInfo = {}
    goodsInfo.goodsId = saleData.p_key
    goodsInfo.goodsPrice = saleData.p_price
    goodsInfo.discount = discounts
    goodsInfo.totalCoins = saleData.p_coins
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    local purchaseInfo = {}
    purchaseInfo.purchaseStatus = index-1
    gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
    gLobalSaleManager:setBuyVippoint(saleData.p_vipPoint)
    gLobalSaleManager:purchaseActivityGoods(
        saleData.p_activityId,
        fruitId,
        BUY_TYPE.BETWEENTWO_SALE,
        saleData.p_key, 
        saleData.p_price, 
        saleData.p_coins, 
        discounts, 
        function()
            self:buySuccess()
        end,
        function()
            self:buyFailed()
        end
    )
end
--购买成功
function BetweenTwoControl:buySuccess()
    self.bl_onBuy = false
    local saleData = self:getSaleData()
    if not saleData then
        return
    end
    --购买成功提示界面
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local view = util_createView("GameModule.Shop.BuyTip")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btnBuy", DotUrlType.UrlName, false)
    end
    --view:setSource("Activity_BetweenTwo")
    view:initBuyTip(
        BUY_TYPE.BETWEENTWO_SALE,
        saleData,
        saleData.p_originalCoins,
        levelUpNum
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
end

--购买失败
function BetweenTwoControl:buyFailed()
    self.bl_onBuy = false
    self.m_index = nil
end

--尝试刷新二选一活动界面
function BetweenTwoControl:checkUpdateMainView(nextFunc)
    self.m_nextFunc = nextFunc
    if not tolua.isnull(self.m_mainView) then
        if self:isFirst() or self:isCompleted() then
            self.m_mainView:playCompleted(self.m_index)
            local _data = self:getActData()
            if _data and self:isCompleted() then
                --关闭大厅轮播展示图
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TIMEOUT, {id = _data:getID(), name = _data:getRefName()}) 
            end 
        else
            self.m_mainView:playFaild(self.m_index)
        end
    else
        self:checkDropCard()
    end
end
--检测是否掉卡
function BetweenTwoControl:checkDropCard()
    if CardSysManager:needDropCards("Double Sale") == true then
        CardSysManager:doDropCards("Double Sale",self.m_nextFunc)
    elseif self.m_nextFunc then
        self.m_nextFunc()
        self.m_nextFunc = nil
    end
end
return BetweenTwoControl
