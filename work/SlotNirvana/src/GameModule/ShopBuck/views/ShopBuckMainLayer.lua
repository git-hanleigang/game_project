--[[
]]
local ShopBuckMainLayer = class("ShopBuckMainLayer", BaseLayer)

function ShopBuckMainLayer:initDatas()
    self.m_jumpCellIndex = 3
    self.m_percent = 100
    self.m_cellDatas = self:getCellDatas()
    self.m_cellNum = #self.m_cellDatas

    self:setLandscapeCsbName("ShopBuck/csb/shop/ShopBuckLayer_H.csb")
    self:setPortraitCsbName("ShopBuck/csb/shop/ShopBuckLayer_V.csb")

    -- 引导
    self:setHasGuide(true)    
    
    -- 横版item的宽度、高度 
    self.m_itemHWidth = 340
    -- self.m_itemHHeight = 480
    -- 竖版item的宽度、高度
    -- self.m_itemVWidth = 630
    self.m_itemVHeight = 190
end

function ShopBuckMainLayer:initCsbNodes()
    self.m_scrollView = self:findChild("ScrollView_1")
    self.m_scrollContentSize = self.m_scrollView:getContentSize()
    self.m_nodeBuck = self:findChild("node_buck")
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnInfo = self:findChild("btn_info")
end

function ShopBuckMainLayer:initView()
    self:initTopBuck()
    self:initScrollView()
    self:initCells()
end

-- 刘海屏处理
function ShopBuckMainLayer:initBangScreenPos()
    local bangDis = 0
    local bangHeight = GD.util_getBangScreenHeight()
    if globalData.slotRunData.isPortrait == true then
        if bangHeight > 0 then
            bangDis = bangHeight + 5
            -- 向下移动
            local posX, posY = self.m_nodeBuck:getPosition()
            self.m_nodeBuck:setPositionY(posY - bangDis)

            local posX, posY = self.m_btnClose:getPosition()
            self.m_btnClose:setPositionY(posY - bangDis)

            local posX, posY = self.m_btnInfo:getPosition()
            self.m_btnInfo:setPositionY(posY - bangDis)
        end  
    end  
end

function ShopBuckMainLayer:initTopBuck()
    self.m_topBuck = G_GetMgr(G_REF.ShopBuck):createBuckTopNode()
    if self.m_topBuck then
        self.m_nodeBuck:addChild(self.m_topBuck)
    end
end

-- function ShopBuckMainLayer:getTopBuckNode()
--     return self.m_topBuck
-- end

function ShopBuckMainLayer:getTopBuckUpNode()
    if self.m_topBuck then
        return self.m_topBuck:getUpNode()
    end
end

function ShopBuckMainLayer:refreshBuck(_perAdd, _target, _addTime)
    self.m_topBuck:refreshBuck(_perAdd, _target, _addTime)
end

function ShopBuckMainLayer:updateBuck(bucks)
    self.m_topBuck:updateBuck(bucks)
end

function ShopBuckMainLayer:upBuckNode(node)
    local upNode = self:getTopBuckUpNode()
    if not self.m_buckNodeParent and upNode then
        local _node = upNode
        self.m_buckNodeParent = _node:getParent()
        self.m_buckPos = cc.p(_node:getPosition())
        self.m_buckScale = _node:getScale()
        local wdPos = self.m_buckNodeParent:convertToWorldSpace(cc.p(self.m_buckPos))
        local nodePos = node:convertToNodeSpace(wdPos)
        util_changeNodeParent(node, _node, _node:getZOrder())
        local _scale = self.m_csbNode:getScale()
        _node:setScale(_scale)
        _node:setPosition(nodePos)
    end
end

function ShopBuckMainLayer:resetBuckNode()
    local upNode = self:getTopBuckUpNode()
    if self.m_buckNodeParent and upNode then
        util_changeNodeParent(self.m_buckNodeParent, upNode, upNode:getZOrder())
        upNode:setPosition(self.m_buckPos)
        upNode:setScale(self.m_buckScale)
        self.m_buckNodeParent = nil
        self.m_buckPos = nil
        self.m_buckScale = nil
    end
end

function ShopBuckMainLayer:initScrollView()
    -- 设置scrollview innersize
    local cellCount = self.m_cellNum
    if self:isShownAsPortrait() then
        self.m_scrollView:setInnerContainerSize(cc.size(self.m_scrollContentSize.width, cellCount*self.m_itemVHeight))
    else
        self.m_scrollView:setInnerContainerSize(cc.size(cellCount*self.m_itemHWidth, self.m_scrollContentSize.height))
    end
    self.m_scrollView:setScrollBarEnabled(false) 
end

function ShopBuckMainLayer:initCells()
    local cellCount = self.m_cellNum
    local startHX = self.m_itemHWidth/2
    local startHY = self.m_scrollContentSize.height/2
    local startVX = self.m_scrollContentSize.width/2
    local startVY = cellCount*self.m_itemVHeight - self.m_itemVHeight/2
    local discount = self:getDiscount()
    self.m_cells = {}
    for i=1,cellCount do
        local cell = util_createView("GameModule.ShopBuck.views.ShopBuckCell", i, self.m_cellDatas[i], discount, util_node_handler(self,self.clickBuy))
        self.m_scrollView:addChild(cell)
        table.insert(self.m_cells, cell)
        
        if self:isShownAsPortrait() then
            cell:setPosition(cc.p(startVX, startVY - (cellCount - i)*self.m_itemVHeight))
        else
            cell:setPosition(cc.p(startHX + (cellCount - i)*self.m_itemHWidth, startHY))
        end
    end
end

function ShopBuckMainLayer:getUpCellGuide()
    local cell = self.m_cells[self.m_jumpCellIndex]
    if cell then
        local upNode = cell:getUpCellGuide()
        return upNode
    end
    return nil
end

function ShopBuckMainLayer:clickBuy(_index)
    release_print("ShopBuckMainLayer:clickBuy _index=".._index)
    local prData = self:getCellDataByIndex(_index)
    if not prData then
        print("没有档位数据")
        return
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    -- 打点 todo
    local goodsInfo = {}
    goodsInfo.discount = self:getDiscount()
    goodsInfo.goodsId = prData:getKeyId()
    goodsInfo.goodsPrice = prData:getPrice()
    goodsInfo.totalBucks = prData:getBuckNum()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    -- 打点 todo
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "tokenSale"
    purchaseInfo.purchaseName = "tokenSale"
    purchaseInfo.purchaseStatus = "tokenSale" .. _index
    gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)

    -- 刷新存储池
    globalData.iapRunData.p_showData = prData

    self:_addBlockMask()

    self.m_buyBucks = prData:getBuckNum()
    gLobalSaleManager:purchaseActivityGoods(
        "",
        prData:getIndex(),
        BUY_TYPE.BUCK,
        prData:getKeyId(), 
        prData:getPrice(), 
        0, 
        0, 
        function()
            if not tolua.isnull(self) then
                self:buySucc()
            end
        end,
        function()
            if not tolua.isnull(self) then
                self:buyFail()
            end
        end
    )
end

function ShopBuckMainLayer:buySucc()
    release_print("ShopBuckMainLayer:buySucc")
    self:_removeBlockMask()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PURCHASE_BUCK_SUCCESS)
    G_GetMgr(G_REF.ShopBuck):showRewardLayer(self.m_buyBucks)
end

function ShopBuckMainLayer:buyFail()
    release_print("ShopBuckMainLayer:buyFail")
    self:_removeBlockMask()
end

-- function OCChapterMap:getCellPercent(_cellIndex)
--     if self:isShownAsPortrait() then
--         if _stepIndex == 1 then
--             return 100
--         elseif _stepIndex >= self.m_maxStep then
--             return 0
--         else
--             -- float minY = _contentSize.height - _innerContainer->getContentSize().height;
--             -- float h = - minY;
--             -- jumpToDestination(Vec2(_innerContainer->getPosition().x, minY + percent * h / 100.0f));        
    
--             local fixPosY = display.cy -- 定位屏幕中心点
    
--             local stepPos = self.m_stepPosList[_stepIndex]
--             local posY = stepPos.y
--             local minY = self.m_scrollViewH - self.m_innerH
--             local h = - minY
--             local percent = (1 - (posY - fixPosY) / h) * 100
    
--             percent = math.max(0, math.min(percent, 100))
    
--             return percent
--         end
--     else
--         if _chapterIndex == 1 then
--             return 0
--         elseif _chapterIndex >= self.m_chapterMax then
--             return 100
--         else
--             -- float w = _innerContainer->getContentSize().width - _contentSize.width;
--             -- jumpToDestination(Vec2(-(percent * w / 100.0f), _innerContainer->getPosition().y));
    
--             local posX = self.m_chapterPosXList[_chapterIndex] - INNER_OFFSETX
    
--             -- local centerLPos = self.m_scrollView:convertToNodeSpace(cc.p(display.cx, display.cy))
            
--             local contentW = self.m_scrollView:getContentSize().width
--             local percent = (posX - display.cx - INNER_STARTX)/(JewelManiaCfg.InnerW - contentW)
--             return percent
--         end        
--     end
-- end

-- 定位滚动位置
function ShopBuckMainLayer:initScrollPercent()
    self:jumpToPercent(self.m_percent)
end

function ShopBuckMainLayer:jumpToPercent(percent)
    percent = math.min(percent*100, 100)
    if self:isShownAsPortrait() then
        self.m_scrollView:jumpToPercentVertical(percent)
    else
        self.m_scrollView:jumpToPercentHorizontal(percent)
    end
end

function ShopBuckMainLayer:scrollToPercent(percent, scrollTime)
    percent = math.min(percent*100, 100)
    if self:isShownAsPortrait() then
        self.m_scrollView:scrollToPercentVertical(percent, scrollTime, false)
    else
        self.m_scrollView:scrollToPercentHorizontal(percent, scrollTime, false)
    end
end

-- function ShopBuckMainLayer:playShowAction()
--     ShopBuckMainLayer.super.playShowAction(self)
-- end

function ShopBuckMainLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self:updateCuyFlyPos()
    self:checkBuckGuide()
end

function ShopBuckMainLayer:onEnter()
    ShopBuckMainLayer.super.onEnter(self)

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         -- 付费失败
    --         if not tolua.isnull(self) then
    --             self:buyFail()
    --         end
    --     end,
    --     ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    -- )

    -- -- csc 特殊补单逻辑,执行购买成功的动画
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(sender, params)
    --         if not tolua.isnull(self) then
    --             release_print("ShopBuckMainLayer IapEventType.IAP_RetrySuccess 补单")
    --             self:buySucc()
    --         end
    --     end,
    --     IapEventType.IAP_RetrySuccess
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:upBuckNode(params)
        end,
        ViewEventType.NOTIFY_BUCKSHOP_UP_LABEL
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:resetBuckNode()
        end,
        ViewEventType.NOTIFY_BUCKSHOP_RESET_LABEL
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshBuck(params[1], params[2], params[3], params[4])
        end,
        ViewEventType.NOTIFY_BUCKSHOP_FRESH_LABEL
    )
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local bucks = params or G_GetMgr(G_REF.ShopBuck):getBucks()
            self:updateBuck(bucks)
        end,
        ViewEventType.NOTIFY_BUCKSHOP_UPDATE_LABEL
    )    
end

function ShopBuckMainLayer:updateCuyFlyPos()
    local isPortrait = globalData.slotRunData.isPortrait
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:addCollectNodeInfo(FlyType.Buck, self.m_topBuck, "BuckStoreTop", isPortrait)
    end
end

function ShopBuckMainLayer:onEnterFinish()
    ShopBuckMainLayer.super.onEnterFinish(self)
    self:initScrollPercent()
    self:initBangScreenPos()
end

function ShopBuckMainLayer:onExit()
    ShopBuckMainLayer.super.onExit(self)
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("BuckStoreTop")
    end
end

function ShopBuckMainLayer:clickFunc(sender)
    local name = sender:getName()
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
        G_GetMgr(G_REF.ShopBuck):showInfoLayer()
    end
end

function ShopBuckMainLayer:checkBuckGuide()
    local isTrigger = self:triggerBuckGuide()
    if not isTrigger then
        return
    end
    return true
end

function ShopBuckMainLayer:triggerGuideStep(guideName, triggerStepId)
    print("ShopBuckMainLayer:triggerGuideStep", guideName, triggerStepId)
    if guideName == "Buck_BuckStore" then
        G_GetMgr(G_REF.ShopBuck):triggerGuide(self, guideName)
    end
end

function ShopBuckMainLayer:triggerGuideOverOfGuideName(guideName)
    print("ShopBuckMainLayer:triggerGuideOverOfGuideName", guideName)
end

function ShopBuckMainLayer:triggerBuckGuide()
    return G_GetMgr(G_REF.ShopBuck):triggerGuide(self, "Buck_BuckStore")
end

function ShopBuckMainLayer:closeUI(_over)
    ShopBuckMainLayer.super.closeUI(self, _over)
end

function ShopBuckMainLayer:getCellDatas()
    local buckData = G_GetMgr(G_REF.ShopBuck):getRunningData()
    if buckData then
        local prDatas = buckData:getProducts()
        return prDatas
    end
    return nil
end

function ShopBuckMainLayer:getCellDataByIndex(_index)
    local buckData = G_GetMgr(G_REF.ShopBuck):getRunningData()
    if buckData then
        local prData = buckData:getProductByIndex(_index)
        return prData
    end
    return nil
end

-- todo 折扣
function ShopBuckMainLayer:getDiscount()
    local discount = 0
    -- 如果有折扣促销活动，写在这里
    return discount
end

return ShopBuckMainLayer
