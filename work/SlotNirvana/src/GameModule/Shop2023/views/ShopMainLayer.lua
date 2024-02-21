--[[
    新版商城界面
]]
local BaseLayer = util_require("base.BaseLayer")
local ShopMainLayer = class("ShopMainLayer", BaseLayer)
local ShopDailySaleConfig = require "data.baseDatas.ShopDailySaleConfig"


local m_ShopJumpDefaultPer = 1.3
local SHOP_UI_DIS = 20 -- 策划效果上的需求，需要要修改list的坐标
local SHOP_UI_DIS_POR = 120
function ShopMainLayer:ctor()
    ShopMainLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(SHOP_RES_PATH.ShopMainLayer)
    self:setPortraitCsbName(SHOP_RES_PATH.ShopMainLayer_Vertical)

    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)
    -- 不需要做打开关闭动画
    self:setShowActionEnabled(false)
    -- self:setHideActionEnabled(false)
    -- 默认动画不需要背景颜色 ， 用csb 来控制背景颜色
    self:setShowBgOpacity(0)
    -- self:setShownAsPortrait(globalData.slotRunData:isFramePortrait())
    -- 引导
    self:setHasGuide(true)

    self.m_scrollTime = 0.3 -- 从左边滚动到右边的时间
    self.m_uiDis = 0
    self.m_uiWorldDis = 0

end

function ShopMainLayer:initUI(_shopPageIndex, _notPushView)
    self.m_shopPageIndex = _shopPageIndex
    self.m_shopCoinItemsNode = {}
    self.m_shopGemsItemsNode = {}
    self.m_shopHotSaleItemsNode = {}
    self.m_shopPetSaleItemsNode = {}
    self.m_shopItemCellLayoutList = {
        [SHOP_VIEW_TYPE.COIN] = {},
        [SHOP_VIEW_TYPE.GEMS] = {},
        [SHOP_VIEW_TYPE.HOT] = {},
        [SHOP_VIEW_TYPE.PET] = {}
    }
    self.m_jumpToIndex = G_GetMgr(ACTIVITY_REF.ShopDailySale):getStoreJumpToViewIndex()
    self.m_jumpPetToIndex = G_GetMgr(ACTIVITY_REF.ShopDailySale):getStorePetJumpToViewIndex()

    -- 初始化一些外部需要的变量
    globalData.shopRunData:setShopPageIndex(_shopPageIndex)
    G_GetMgr(G_REF.Shop):setShopClosedFlag(false)
    self.m_isPushViewOpenShop = _notPushView
    self.buyShop = false

    -- 设置外部名称检测
    self:setExtendData("ZQCoinStoreLayer") -- 这行代码不能屏蔽

    ShopMainLayer.super.initUI(self)
end

function ShopMainLayer:isPortrait()
    return self.m_isShownAsPortrait or false
end

function ShopMainLayer:initCsbNodes()
    -- 按钮部分
    self.m_btnClose = self:findChild("btn_close")

    -- 节点
    self.m_nodeRecommend = self:findChild("node_tuiJianWei") -- 推荐位node
    self.m_nodeRaipdBtn = self:findChild("node_rapidButton") -- 按钮节点

    self.m_nodeRaipdBtn_left = self:findChild("node_yeqian") -- 按钮节点

    self.m_nodeFreeCoin = self:findChild("node_freeCoin")
    self.m_itemList_coins = self:findChild("ListView_coins")
    self.m_nodeScratchCards = self:findChild("node_scratch_card") --刮刮卡入口节点


    self.m_itemList_pet = self:findChild("ListView_pet")
    self.m_itemList_hot = self:findChild("ListView_offer")
    self.m_itemList_gems = self:findChild("ListView_gems")
    self.m_itemList_pet:setVisible(false)
    self.m_itemList_hot:setVisible(false)
    self.m_itemList_gems:setVisible(false)

    -- topui
    self.m_nodeTopNode = self:findChild("node_Account")

    -- 竖版才有的节点
    self.m_nodeVip = self:findChild("node_vip")
    self.m_nodeStamp = self:findChild("node_stamp")
    self.m_sp_line_coins = self:findChild("sp_line_coins")
    self.m_sp_line_gems  = self:findChild("sp_line_gems")
    self.m_sp_line_offer = self:findChild("sp_line_offer")
    self.m_sp_line_pet = self:findChild("sp_line_pet")

    -- 折扣开关
    self.m_node_PromoMode = self:findChild("node_switch")
    -- 代币
    self.m_node_Buck = self:findChild("node_buck")

    self.m_node_soldOut = self:findChild("node_soldOut")
    self.m_lb_soldOut = self:findChild("lb_soldOut")
    self.m_node_soldOut:setVisible(false)
end

function ShopMainLayer:initView()

    --添加推荐位
    self.m_recommendSize = cc.size(0,0)
    self.m_ticketTopSize = cc.size(0,0) -- 顶部栏 优惠劵大小
    --添加上UI Title
    self:addTopUiStoreTitle()
    --添加下UI 按钮
    self:addRaipdBottomBtnUI()
    --添加左UI 按钮 
    self:addRaipdLeftBtnUI()

    -- self:initItemContentSize()

    -- 初始化列表
    self:initListView()
    --添加 freecoin
    self:addFreeCoinNode()
    --添加 vip -- 竖版
    self:addVipShow()
    --添加luckystamp -- 竖版
    self:addLuckStampTips()
    --添加刮刮卡入口
    -- self:addScratchCardsNode()
    -- 折扣开关
    self:addPromomodeNode()
    -- 代币
    self:addBuckNode()
    -- 到当日零点时间
    self:checkTodayTime()

    self:changeCurrentPage(self.m_shopPageIndex, nil, false)

    -- action 有透明度变化
    util_setCascadeOpacityEnabledRescursion(self:findChild("node_top"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("node_bottom"), true)
end

function ShopMainLayer:addRecommendUI()
    if self.m_recommendeUI == nil then
        self.m_recommendeUI = util_createView(SHOP_CODE_PATH.RecommendedPositionNode, self:isPortrait())
        self.m_nodeRecommend:addChild(self.m_recommendeUI)
        self.m_recommendSize = self.m_recommendeUI:getNodeFrameSize()
    end
end

function ShopMainLayer:addRaipdBottomBtnUI()
    if self.m_raipdBtnUI == nil then
        self.m_raipdBtnUI = util_createView(SHOP_CODE_PATH.RapidPositionBtnNode, self:isPortrait(),false)
        self.m_nodeRaipdBtn:addChild(self.m_raipdBtnUI)
    end
end

function ShopMainLayer:addRaipdLeftBtnUI()
    if self.m_nodeRaipdBtn_left and self.m_raipdLeftBtnUI == nil then
        self.m_raipdLeftBtnUI = util_createView(SHOP_CODE_PATH.RapidLeftPositionBtnNode, self:isPortrait(),true)
        self.m_nodeRaipdBtn_left:addChild(self.m_raipdLeftBtnUI)
    end
end

function ShopMainLayer:getUpCoinNode()
    if self:isPortrait() then
        if self.m_raipdBtnUI then
            return self.m_raipdBtnUI:getUpCoinNode()
        end
    else
        if self.m_raipdLeftBtnUI then
            return self.m_raipdLeftBtnUI:getUpCoinNode()
        end
    end
    return nil
end

function ShopMainLayer:addFreeCoinNode()
    self.shopBonusView = util_createView(SHOP_CODE_PATH.FreeCoinsNode)
    self.m_nodeFreeCoin:addChild(self.shopBonusView)
end

function ShopMainLayer:addScratchCardsNode()
    if not G_GetMgr(ACTIVITY_REF.ScratchCards):isCanShowLayer() then
        return
    end
    local shopScratchCardsNode = util_createView(SHOP_CODE_PATH.ScratchCardsNode, self)
    self.m_nodeScratchCards:addChild(shopScratchCardsNode)
end

function ShopMainLayer:addPromomodeNode()
    local shopPromomodeNode = util_createView(SHOP_CODE_PATH.PromomodeNode, self:isPortrait())
    self.m_node_PromoMode:addChild(shopPromomodeNode)
end

function ShopMainLayer:addBuckNode()
    local buckNode = util_createView(SHOP_CODE_PATH.TopBuckNode, self:isPortrait())
    self.m_node_Buck:addChild(buckNode)
end

function ShopMainLayer:addTopUiStoreTitle()
    -- 新版商城 金币、gems 节点
    self.m_topUiAcoount = util_createView(SHOP_CODE_PATH.TopAccountNode, SHOP_VIEW_TYPE.COIN, self:isPortrait())
    self.m_nodeTopNode:addChild(self.m_topUiAcoount)
    self.m_topUiAcoount:setMainLayerScale(self:findChild("root"):getScale())

    -- 新版商城 商城优惠劵 节点
    local nodeTopCoupon = self:findChild("node_topCoupon")
    self.m_topUiTicket = util_createView(SHOP_CODE_PATH.ShopTopTicketUI, self, self:isPortrait())
    nodeTopCoupon:addChild(self.m_topUiTicket)
    self.m_ticketTopSize = self.m_topUiTicket:getNodeFrameSize()
end

function ShopMainLayer:addVipShow()
    if self.m_nodeVip then
        self.m_vipNextPointsView = util_createView(SHOP_CODE_PATH.VipNode)
        self.m_nodeVip:addChild(self.m_vipNextPointsView)
    end
end

function ShopMainLayer:addLuckStampTips()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        return
    end
    self.m_luckyStampNode = G_GetMgr(G_REF.LuckyStamp):createLuckyStampTip(nil, true, false)
    if self.m_nodeStamp and self.m_luckyStampNode then
        self.m_nodeStamp:addChild(self.m_luckyStampNode)
    end
end

function ShopMainLayer:getUpCellBtnNode()
    local guideIndex = self.m_jumpToIndex or 1
    -- 不引导最低档位，因为最低档位可能在最右侧，npc位置出屏幕了
    guideIndex = guideIndex + 1
    guideIndex = math.min(guideIndex, #self.m_shopCoinItemsNode)
    local cell = self:getCoinCellNode(guideIndex)
    if cell then
        local upNode = cell:getUpBtnBuyNode()
        return upNode
    end
    return nil
end

function ShopMainLayer:initListView()
    self.m_itemList_coins:setItemsMargin(0)
    self.m_itemList_coins:setScrollBarEnabled(false)
    -- self.m_itemList_coins:setScrollDuration( 10 )
    self.m_itemList_coins:setBounceEnabled(true)

    self.m_itemList_hot:setItemsMargin(0)
    self.m_itemList_hot:setScrollBarEnabled(false)
    self.m_itemList_hot:setBounceEnabled(true)

    self.m_itemList_pet:setItemsMargin(0)
    self.m_itemList_pet:setScrollBarEnabled(false)
    self.m_itemList_pet:setBounceEnabled(true)

    self.m_itemList_gems:setItemsMargin(0)
    self.m_itemList_gems:setScrollBarEnabled(false)
    self.m_itemList_gems:setBounceEnabled(true)

    -- if not self:isPortrait() then
    --    -- self.m_uiDis = self.m_uiDis + 40
    -- end

    self.m_itemList_coins:onScroll(
        function(event)
            G_GetMgr(ACTIVITY_REF.StayCoupon):setSlideStatus(true)
            self:listViewOnScroll()
        end
    )
end

-- 设置列表大小
function ShopMainLayer:initItemContentSize()
    -- 列表宽高
    local itemListW = self.m_itemList_coins:getContentSize().width
    local itemListH = self.m_itemList_coins:getContentSize().height
    -- 刘海屏处理
    local bangDis = 0
    local bangHeight = GD.util_getBangScreenHeight()
    if self:isPortrait() then
        if bangHeight > 0 then
            bangDis = bangHeight + 5
            -- 向下移动
            local posX, posY = self:findChild("node_top"):getPosition()
            self:findChild("node_top"):setPositionY(posY - bangDis)
        end
        -- 设置itemList大小
        self.m_itemList_coins:setContentSize(cc.size(itemListW, itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height))
        self.m_itemList_hot:setContentSize(cc.size(itemListW, itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height))
        self.m_itemList_pet:setContentSize(cc.size(itemListW, itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height))
        self.m_itemList_gems:setContentSize(cc.size(itemListW, itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height))
        self.m_sp_line_coins:setPositionY(itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height)
        self.m_sp_line_gems:setPositionY(itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height)
        self.m_sp_line_offer:setPositionY(itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height)
        self.m_sp_line_pet:setPositionY(itemListH - SHOP_UI_DIS_POR - bangDis - self.m_recommendSize.height)
    else
        -- if bangHeight > 0 then
        --     bangDis = bangHeight + 5
        --     -- 向下移动
        --     local posX, posY = self:findChild("Node_leftBtn"):getPosition()
        --     self:findChild("Node_leftBtn"):setPositionX(posX + bangDis)
        -- end
        -- -- 设置itemList大小
        -- self.m_itemList_coins:setContentSize(cc.size(itemListW - bangDis - self.m_recommendSize.width, itemListH))
        -- self.m_itemList_hot:setContentSize(cc.size(itemListW - bangDis - self.m_recommendSize.width, itemListH))
        -- self.m_itemList_gems:setContentSize(cc.size(itemListW - bangDis - self.m_recommendSize.width, itemListH))
        -- local posX, posY =  self.m_sp_line:getPosition()
        -- self.m_sp_line:setPositionX(posX + bangDis)
    end

    -- self.m_itemList_coins:onScroll(
    --     function(event)
    --         self:listViewOnScroll()
    --     end
    -- )
end

-- 更新列表大小
function ShopMainLayer:updateLsitViewSize(_coinsTicketVisible, _gemsTicketVisible)
    self._coinsTicketVisible = self._coinsTicketVisible or false
    self._gemsTicketVisible = self._gemsTicketVisible or false

    if self._coinsTicketVisible ~= _coinsTicketVisible then
        local addH = _coinsTicketVisible and -self.m_ticketTopSize.height or self.m_ticketTopSize.height
        local itemListCoinsSize = self.m_itemList_coins:getContentSize()
        self.m_itemList_coins:setContentSize(itemListCoinsSize.width, itemListCoinsSize.height + addH)
        local spLineCoinsY = self.m_sp_line_coins:getPositionY()
        self.m_sp_line_coins:setPositionY(spLineCoinsY+ addH)
    end

    if self._gemsTicketVisible ~= _gemsTicketVisible then
        local addH = _gemsTicketVisible and -self.m_ticketTopSize.height or self.m_ticketTopSize.height
        local itemListGemsSize = self.m_itemList_gems:getContentSize()
        self.m_itemList_gems:setContentSize(itemListGemsSize.width, itemListGemsSize.height + addH)
        local spLineGemsY = self.m_sp_line_coins:getPositionY()
        self.m_sp_line_gems:setPositionY(spLineGemsY+ addH)
    end
    self._coinsTicketVisible = _coinsTicketVisible
    self._gemsTicketVisible = _gemsTicketVisible
end

function ShopMainLayer:addCellListView(type)
    local itemListW = self.m_itemList_coins:getContentSize().width
    local itemListH = self.m_itemList_coins:getContentSize().height

    if type == SHOP_VIEW_TYPE.COIN and not self.m_initCoinList then
        -- 添加coins的商品的item
        self:addStoreItemsCell(SHOP_VIEW_TYPE.COIN)
        self.m_initCoinList = true
    elseif type == SHOP_VIEW_TYPE.GEMS and not self.m_initGemsList then
        -- 第二货币
        self:addStoreItemsCell(SHOP_VIEW_TYPE.GEMS)
        self.m_initGemsList = true
    elseif type == SHOP_VIEW_TYPE.HOT and not self.m_initHotList then
        -- 热卖
        self:addStoreItemsCell(SHOP_VIEW_TYPE.HOT)
        self.m_initHotList = true
    elseif type == SHOP_VIEW_TYPE.PET and not self.m_initPetList then
        -- 宠物
        self:addStoreItemsCell(SHOP_VIEW_TYPE.PET)
        self.m_initPetList = true
    end
    
    -- 添加boost道具
    -- self:addStoreBoostItems()
end

function ShopMainLayer:addStoreItemsCell(_type)
    local itemList =  self.m_itemList_coins
    if _type == SHOP_VIEW_TYPE.GEMS then
        itemList =  self.m_itemList_gems
    elseif _type == SHOP_VIEW_TYPE.HOT then
        itemList =  self.m_itemList_hot
    elseif _type == SHOP_VIEW_TYPE.PET then
        itemList =  self.m_itemList_pet
    end

    local width = itemList:getContentSize().width
    local height = itemList:getContentSize().height
    local coinsData, gemsData,hotSale,petData = globalData.shopRunData:getShopItemDatas()
    local shopData = nil
    local viewPath = nil
    if _type == SHOP_VIEW_TYPE.COIN then
        shopData = coinsData
        viewPath = SHOP_CODE_PATH.ItemCellNodeCoin
    elseif _type == SHOP_VIEW_TYPE.GEMS then
        shopData = gemsData
        viewPath = SHOP_CODE_PATH.ItemCellNodeGems
    elseif _type == SHOP_VIEW_TYPE.HOT then
        if G_GetMgr(G_REF.MonthlyCard):isCanShowLayer() then
            shopData = hotSale 
        else
            shopData = {}
            for i,v in ipairs(hotSale) do
                if not v:isMonthlyCard() then
                    shopData[#shopData + 1] = v
                end
                
            end
        end

        local bAddScratchEntryCell = G_GetMgr(ACTIVITY_REF.ScratchCards):isCanShowLayer()
        if bAddScratchEntryCell then
            -- 刮刮卡 热卖
            local shopScratchCardConfig = ShopDailySaleConfig:create()
            shopScratchCardConfig:setIsScratchCard(true)
            shopScratchCardConfig:setIndex(#hotSale+1)
            table.insert(shopData, shopScratchCardConfig)
        end

        viewPath = SHOP_CODE_PATH.ItemCellNodeHot
        if not shopData or #shopData <=0 then
            self.m_isHotSaleEmpty = true
        else
            self.m_isHotSaleEmpty = false
        end
    elseif _type == SHOP_VIEW_TYPE.PET then
        shopData = petData
        viewPath = SHOP_CODE_PATH.ItemCellNodePet 
        if not shopData or #shopData <=0 then
            self.m_isPetSaleEmpty = true
        else
            self.m_isPetSaleEmpty = false
        end
    end
    for i = #shopData, 1, -1 do
        local useLuaPath = viewPath
        if shopData[i]:isMonthlyCard() then
            useLuaPath = SHOP_CODE_PATH.ItemCellNodeMonthlyCard 
        elseif shopData[i]:isScratchCard() then
            useLuaPath = SHOP_CODE_PATH.ItemCellNodeScratchCard 
        end
        local layout = ccui.Layout:create()
        local shopItemCell = util_createView(useLuaPath, _type, i, shopData[i], self:isPortrait())

        -- 设置当前 item cell的list占位大小
        local shopItemCellSize = shopItemCell:getCellContentSize()
        if self:isPortrait() then
            layout:setContentSize(cc.size(width, shopItemCellSize.height))
        else
            layout:setContentSize(cc.size(shopItemCellSize.width, height))
        end
        itemList:pushBackCustomItem(layout)
        if not self:isPortrait() then
            shopItemCell:setPositionY(20)
        end
        layout:addChild(shopItemCell)

        if _type == SHOP_VIEW_TYPE.COIN then
            table.insert(self.m_shopCoinItemsNode, {node = shopItemCell, index = i})
            table.insert(self.m_shopItemCellLayoutList[SHOP_VIEW_TYPE.COIN], {node = layout, index = i})
        elseif _type == SHOP_VIEW_TYPE.GEMS then
            table.insert(self.m_shopGemsItemsNode, {node = shopItemCell, index = i})
            table.insert(self.m_shopItemCellLayoutList[SHOP_VIEW_TYPE.GEMS], {node = layout, index = i})
        elseif _type == SHOP_VIEW_TYPE.HOT then
            table.insert(self.m_shopHotSaleItemsNode, {node = shopItemCell, index = shopData[i].m_index})
        elseif _type == SHOP_VIEW_TYPE.PET then
            table.insert(self.m_shopPetSaleItemsNode, {node = shopItemCell, index = shopData[i].m_index})
        end
    end
    -- 竖版因为有按钮区域,需要补充一个按钮区域大的 layout
    if self:isPortrait() then
        local layout = ccui.Layout:create()
        local itemListW = itemList:getContentSize().width
        local btnSize = self.m_raipdBtnUI:getPanelSize()
        layout:setContentSize(cc.size(itemListW, btnSize.height + 98.00))
        itemList:pushBackCustomItem(layout)
    end
end

function ShopMainLayer:getCoinCellNode(_index)
    if self.m_shopCoinItemsNode and #self.m_shopCoinItemsNode > 0 then
        for i = 1, #self.m_shopCoinItemsNode do
            local cell = self.m_shopCoinItemsNode[i]
            if cell.index == _index then
                return cell.node
            end
        end    
    end
    return
end

function ShopMainLayer:listViewOnScroll()
    if not self.m_active then
        local newType = self:checkInRect()
        --self.m_raipdBtnUI:updateBtnStatus(newType)
    end
end

function ShopMainLayer:refreshUI()
    --更新界面 cell 数值
    self:refreshCellNodeUI()
    --更新推荐位显示 （luckystamp 以及 vip）
    self:refreshRecommendeList()
    --更新 免费金币freecoinnode展示
    self:refreshFreeCoinNode()
    --更新vip显示
    if self.m_vipNextPointsView then
        self.m_vipNextPointsView:updatePoints()
    end
    --更新 推荐位上的vip
    if self.m_recommendeUI then
        self.m_recommendeUI:updateVipInfo()
    end
    -- 新版商城 商城优惠劵 节点
    self:refreshTopTicketUI()
end

function ShopMainLayer:refreshTopTicketUI()
    if self.m_topUiTicket then
        self.m_topUiTicket:updateBtnStatus(self.m_currentPageType, true)
    end
end

function ShopMainLayer:refreshRecommendeList()
    if self.m_currentPageType == SHOP_VIEW_TYPE.HOT then
        self.m_itemList_hot:removeAllItems()
        self.m_shopHotSaleItemsNode = {}
        self.m_shopItemCellLayoutList[SHOP_VIEW_TYPE.HOT] = {}
        self:addStoreItemsCell(SHOP_VIEW_TYPE.HOT)
        self.m_node_soldOut:setVisible(not not self.m_isHotSaleEmpty)
    elseif self.m_currentPageType == SHOP_VIEW_TYPE.PET then
        self.m_itemList_pet:removeAllItems()
        self.m_shopPetSaleItemsNode = {}
        self:addStoreItemsCell(SHOP_VIEW_TYPE.PET)
        self.m_node_soldOut:setVisible(not not self.m_isPetSaleEmpty)
    end
end

function ShopMainLayer:refreshCellNodeUI()
    -- if #self.m_shopCoinItemsNode == 0 then
    --     return
    -- end
    -- 刷新coin
    local coinsData, gemsData ,hotSale = globalData.shopRunData:getShopItemDatas()
    if #coinsData > 0 then
        for i, v in ipairs(self.m_shopCoinItemsNode) do
            v.node:refreshUiData(v.index, coinsData[v.index])
        end
    end
    -- 刷新 第二货币
    if #gemsData > 0 then
        for i, v in ipairs(self.m_shopGemsItemsNode) do
            v.node:refreshUiData(v.index, gemsData[v.index])
        end
    end
end

function ShopMainLayer:refreshFreeCoinNode()
    if self.shopBonusView and self.shopBonusView.updateCollectStatus then
        self.shopBonusView:updateCollectStatus()
    end
end

-- 按钮自动检测状态切换
function ShopMainLayer:checkInRect()
    return SHOP_VIEW_TYPE.GEMS
    -- local worldPosF1 = self.m_fengxian1:getParent():convertToWorldSpace(cc.p(self.m_fengxian1:getPosition()))
    -- local localPosF1 = self:findChild("ListView"):convertToNodeSpace(cc.p(worldPosF1))

    -- -- 因为root 缩放的时候,会有小数点的问题，要取整
    -- localPosF1.x = math.floor(localPosF1.x)
    -- localPosF1.y = math.floor(localPosF1.y)
    -- local border = 0 + self.m_uiDis + self.m_uiWorldDis
    -- if self:isPortrait() then
    --     border = border + self.m_fengxian1:getContentSize().height
    --     local listSize = self.m_itemList_coins:getContentSize()
    --     local displayHeight = math.floor(listSize.height) - border
    --     if localPosF1.y >= displayHeight then
    --         return SHOP_VIEW_TYPE.GEMS
    --     elseif localPosF1.y < displayHeight then
    --         return SHOP_VIEW_TYPE.COIN
    --     end
    -- else
    --     if border >= localPosF1.x then
    --         return SHOP_VIEW_TYPE.GEMS
    --     elseif border < localPosF1.x then
    --         return SHOP_VIEW_TYPE.COIN
    --     end
    -- end
end

function ShopMainLayer:jumpToView(_type, _active)
    self.m_active = _active
    self:changeCurrentPage(_type, nil, false)
    self:checkBuckGuide()
end

function ShopMainLayer:changeCurrentPage(_type, _callback, _bounce)
    self.m_currentPageType = _type
    --添加滑动CellList
    self:addCellListView(_type)

    self.m_sp_line_coins:setVisible(_type == SHOP_VIEW_TYPE.COIN)
    self.m_sp_line_gems:setVisible(_type == SHOP_VIEW_TYPE.GEMS)
    self.m_sp_line_offer:setVisible(_type == SHOP_VIEW_TYPE.HOT)
    
    if _type == SHOP_VIEW_TYPE.COIN then
        self.m_itemList_pet:setVisible(false)
        self.m_itemList_hot:setVisible(false)
        self.m_itemList_gems:setVisible(false)
        self.m_itemList_coins:setVisible(true)
        self.m_node_soldOut:setVisible(false) 
    elseif _type == SHOP_VIEW_TYPE.GEMS then
        self.m_itemList_pet:setVisible(false)
        self.m_itemList_hot:setVisible(false)
        self.m_itemList_gems:setVisible(true)
        self.m_itemList_coins:setVisible(false)
        self.m_node_soldOut:setVisible(false) 
    elseif _type == SHOP_VIEW_TYPE.HOT then
        self.m_itemList_pet:setVisible(false)
        self.m_itemList_hot:setVisible(true)
        self.m_itemList_gems:setVisible(false)
        self.m_itemList_coins:setVisible(false)
        self.m_node_soldOut:setVisible(not not self.m_isHotSaleEmpty) 
    elseif _type == SHOP_VIEW_TYPE.PET then
        self.m_itemList_pet:setVisible(true)
        self.m_itemList_hot:setVisible(false)
        self.m_itemList_gems:setVisible(false)
        self.m_itemList_coins:setVisible(false)
        self.m_node_soldOut:setVisible(not not self.m_isPetSaleEmpty) 
        if not self.m_isfirstPet then
            self.m_isfirstPet = true
            self:playPetPageAction(true)
        end
    end
    if self.m_raipdBtnUI then
        self.m_raipdBtnUI:updateBtnStatus(_type)
    end
    if self.m_raipdLeftBtnUI then
        self.m_raipdLeftBtnUI:updateBtnStatus(_type)
    end
    if self.m_topUiTicket then
        self.m_topUiTicket:updateBtnStatus(_type) 
    end
end

-- 跳转定位v2 跳转到推荐单位
function ShopMainLayer:jumpToViewForRecommendIndex(_type, _callback, _bounce)
    local actions = {}
    self.m_shopPageIndex = _type or self.m_shopPageIndex -- 更变shopPageIndex
    if _type == SHOP_VIEW_TYPE.COIN then
        actions = self:playCoinsPageAction(_bounce)
    elseif _type == SHOP_VIEW_TYPE.GEMS then
        actions = self:playGemsPageAction(_bounce)
    end

    if _callback then
        table.insert(actions, _callback)
    end
    local seq = cc.Sequence:create(actions)
    self:runAction(seq)

    if self.m_active then
        performWithDelay(
            self,
            function()
                self.m_active = false
                self:listViewOnScroll()
            end,
            0.5
        )
    end
end

-- 跳转到指定的坐标
function ShopMainLayer:getJumpPercent(_distance, moveNode,_pet)
    local percent = m_ShopJumpDefaultPer
    local innerSize = self.m_itemList_coins:getInnerContainerSize()
    local conSize = self.m_itemList_coins:getContentSize()
    if _pet then
        innerSize = self.m_itemList_pet:getInnerContainerSize()
        conSize = self.m_itemList_pet:getContentSize()
    end
    local moveNodeSize = moveNode and moveNode:getContentSize() or {width = 0, height = 0}
    if self:isPortrait() then
        local maxHeight = innerSize.height - conSize.height
        local posY = _distance
        local moveDis = innerSize.height - posY - moveNodeSize.height - self.m_uiDis
        percent = moveDis * 100 / maxHeight
    else
        local maxWidth = innerSize.width - conSize.width
        local moveDis = _distance - self.m_uiDis
        percent = moveDis * 100 / maxWidth
    end
    return percent
end

-- 打开商城的时候要刷新一下促销数据
function ShopMainLayer:requestSaleData()
    gLobalSendDataManager:getNetWorkFeature():sendQuerySaleConfig(
        function(isTrigger)
            self.m_isTriggerCloseSale = isTrigger
            if self.m_isTriggerCloseSale then
                --如果触发了先不刷新UI等关闭商店在刷新
                globalData.saleRunData:setShowTopeSale(false)
            end
        end
    )
end

-- 进入动画
function ShopMainLayer:enterMainAction()
    -- 底部动画
    local callBottom =
        cc.CallFunc:create(
        function()
            self:enterShowTopBottomUI()
        end
    )
    self:jumpToViewForRecommendIndex(self.m_shopPageIndex, callBottom, true)
end

function ShopMainLayer:enterMainActionOver()
    self:playShopCarnivalAction()
end

function ShopMainLayer:playShopCarnivalAction()
    -- 播放膨胀
    if not tolua.isnull(self.m_expansionView) then
        self.m_expansionView:playStartAction(
            function()
                if not tolua.isnull(self) then
                    -- 检测引导，放到最后
                    self:checkBuckGuide()
                end
            end
        )
    else
        -- 检测引导，放到最后
        self:checkBuckGuide()
    end
end

function ShopMainLayer:playCoinsPageAction(_bounce)
    local percen = 0
    -- 计算应该滑动到的距离
    -- 如果当前是最大金币档位 or 倒数第二 档位的的话 ， 默认滑到头
    local coinsLayoutCellList = self.m_shopItemCellLayoutList[SHOP_VIEW_TYPE.COIN]
    if self.m_jumpToIndex == #coinsLayoutCellList or self.m_jumpToIndex == #coinsLayoutCellList - 1 then
        --需要取分当前是横竖版
        local enterMoveNode = self:getEnterMoveNode(#coinsLayoutCellList)
        local dis = enterMoveNode:getPositionX()
        if self:isPortrait() then
            dis = enterMoveNode:getPositionY()
        end
        percen = self:getJumpPercent(dis, enterMoveNode)
    else
        -- 需要判断当前要到的位置距离的上一个
        percen = self:getJumpPercent(self:getMoveDistanceV2())
    end
    return self:getMoveActionSeq(percen, _bounce) 
end

function ShopMainLayer:playPetPageAction(_bounce)
    local percen = 0
    -- 计算应该滑动到的距离
    -- 如果当前是最大金币档位 or 倒数第二 档位的的话 ， 默认滑到头
    local coinsLayoutCellList = self.m_shopPetSaleItemsNode
    if self.m_jumpPetToIndex == #coinsLayoutCellList or self.m_jumpPetToIndex == #coinsLayoutCellList - 1 then
        --需要取分当前是横竖版
        local enterMoveNode = self:getEnterMoveNode(#coinsLayoutCellList,true)
        local dis = enterMoveNode:getPositionX()
        if self:isPortrait() then
            dis = enterMoveNode:getPositionY()
        end
        percen = self:getJumpPercent(dis, enterMoveNode, true)
    else
        -- 需要判断当前要到的位置距离的上一个
        percen = self:getJumpPercent(self:getMoveDistanceV2(true),nil,true)
    end
    return self:getMoveActionSeq(percen, _bounce) 
end


function ShopMainLayer:playGemsPageAction(_bounce)
    local percen = 0
    -- -- 计算应该滑动到的距离
    -- local gemsLayoutCellList = self.m_shopItemCellLayoutList[SHOP_VIEW_TYPE.GEMS]
    -- -- 如果当前是最大金币档位 or 倒数第二 档位的的话 ， 默认滑到头
    -- if self.m_jumpToIndex == #gemsLayoutCellList or self.m_jumpToIndex == #gemsLayoutCellList - 1 then

    --     local enterMoveNode = self:getEnterMoveNode(#gemsLayoutCellList)
    --     local dis = enterMoveNode:getPositionX()
    --     if self:isPortrait() then
    --         dis = enterMoveNode:getPositionY()
    --     end
    --     percen = self:getJumpPercent(dis, enterMoveNode)
    -- else
    --     -- 需要判断当前要到的位置距离的上一个
    --     percen = self:getJumpPercent(self:getMoveDistanceV2())
    --     percen = percen > 100 and 100 or percen
    -- end
    return self:getMoveActionSeq(percen, _bounce)
end

function ShopMainLayer:getMoveActionSeq(_percen, _bounce)
    local actions = {}
    if not _bounce then
        local call1 =
            cc.CallFunc:create(
            function()
                -- 移动到的位置需要另外计算
                if self.m_shopPageIndex == SHOP_VIEW_TYPE.COIN  then
                    if self:isPortrait() then
                        self.m_itemList_coins:scrollToPercentVertical(_percen, 0.3, false)
                    else
                        self.m_itemList_coins:scrollToPercentHorizontal(_percen, 0.3, false)
                    end
                elseif self.m_shopPageIndex == SHOP_VIEW_TYPE.PET then
                    if self:isPortrait() then
                        self.m_itemList_pet:scrollToPercentVertical(_percen, 0.3, false)
                    else
                        self.m_itemList_pet:scrollToPercentHorizontal(_percen, 0.3, false)
                    end
                else
                    if self:isPortrait() then
                        self.m_itemList_gems:scrollToPercentVertical(_percen, 0.3, false)
                    else
                        self.m_itemList_gems:scrollToPercentHorizontal(_percen, 0.3, false)
                    end
                end
            end
        )
        table.insert(actions, call1)
    else
        local call1 =
            cc.CallFunc:create(
            function()
                -- if self.m_shopPageIndex == SHOP_VIEW_TYPE.COIN then -- 金币商城从右边往左边滑
                --     if self:isPortrait() then
                --         self.m_itemList_coins:jumpToBottom()
                --     else
                --         self.m_itemList_coins:jumpToRight()
                --     end
                -- else
                --     if self:isPortrait() then
                --         self.m_itemList_gems:jumpToBottom()
                --     else
                --         self.m_itemList_gems:jumpToRight()
                --     end
                -- end
            end
        )
        local _scollSec = self.m_scrollTime or 0.3
        local delay1 = cc.DelayTime:create(0.05)
        local call2 =
            cc.CallFunc:create(
            function()
                if self.m_shopPageIndex == SHOP_VIEW_TYPE.COIN then
                    if self:isPortrait() then
                        self.m_itemList_coins:scrollToPercentVertical(_percen, _scollSec, false)
                    else
                        self.m_itemList_coins:scrollToPercentHorizontal(_percen - m_ShopJumpDefaultPer, _scollSec, false)
                    end
                 elseif self.m_shopPageIndex == SHOP_VIEW_TYPE.PET then
                    if self:isPortrait() then
                        self.m_itemList_pet:scrollToPercentVertical(_percen, _scollSec, false)
                    else
                        self.m_itemList_pet:scrollToPercentHorizontal(_percen - m_ShopJumpDefaultPer, _scollSec, false)
                    end
                else
                    if self:isPortrait() then
                        self.m_itemList_gems:scrollToPercentVertical(_percen, _scollSec, false)
                    else
                        self.m_itemList_gems:scrollToPercentHorizontal(_percen - m_ShopJumpDefaultPer, _scollSec, false)
                    end
                end
            end
        )
        local delay2 = cc.DelayTime:create(_scollSec)
        local call3 =
            cc.CallFunc:create(
            function()
                -- 移动到的位置需要另外计算
                if self.m_shopPageIndex == SHOP_VIEW_TYPE.COIN then
                    if self:isPortrait() then
                        -- self.m_itemList_coins:scrollToPercentVertical( _percen,0.3,false )
                    else
                        self.m_itemList_coins:scrollToPercentHorizontal(_percen, _scollSec, false)
                    end
                elseif self.m_shopPageIndex == SHOP_VIEW_TYPE.PET then
                    if self:isPortrait() then
                        -- self.m_itemList_coins:scrollToPercentVertical( _percen,0.3,false )
                    else
                        self.m_itemList_pet:scrollToPercentHorizontal(_percen, _scollSec, false)
                    end
                else
                    if self:isPortrait() then
                        -- self.m_itemList_coins:scrollToPercentVertical( _percen,0.3,false )
                    else
                        self.m_itemList_gems:scrollToPercentHorizontal(_percen, _scollSec, false)
                    end
                end
            end
        )
        table.insert(actions, delay1)
        table.insert(actions, call1)
        table.insert(actions, call2)
        table.insert(actions, delay2)
        table.insert(actions, call3)
    end

    return actions
end

-- v2版本的移动定位
function ShopMainLayer:getMoveDistanceV2(_pet)
    local moveLayoutNode = self:getEnterMoveNode(self.m_jumpToIndex,_pet)
    local layoutSize = moveLayoutNode:getContentSize()
    -- 得到当前 list 的宽
    local width = self.m_itemList_coins:getContentSize().width
    local height = self.m_itemList_coins:getContentSize().height
    if _pet then
        width = self.m_itemList_pet:getContentSize().width
        height = self.m_itemList_pet:getContentSize().height
    end
    local pos = cc.p(moveLayoutNode:getPosition())
    local newDis = 0
    if self:isPortrait() then
        local bottomUiSize = self.m_raipdBtnUI:getPanelSize()
        newDis = pos.y + height - self.m_uiWorldDis - self.m_uiDis - bottomUiSize.height
    else
        newDis = pos.x - width + self.m_uiWorldDis + self.m_uiDis + layoutSize.width
    end
    return newDis
end
-- 获取当前打开动画应该滑到的 layout 节点
-- _index:定位点
function ShopMainLayer:getEnterMoveNode(_index,_pet)
    local moveLayout = nil
    -- 得到要滑动定位的cellnode
    local layoutList = {}
    if _pet then
        layoutList = self.m_shopPetSaleItemsNode
    else
        layoutList = self.m_shopItemCellLayoutList[self.m_shopPageIndex]
    end
    for i = 1, #layoutList do
        local layout = layoutList[i]
        if layout.index == _index then
            moveLayout = layout.node
            break
        end
    end
    return moveLayout or layoutList[1].node
end

function ShopMainLayer:enterShowTopBottomUI()
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle",false)
            self.m_topUiAcoount:resetGlobalFlyCoinNode()
            self:enterMainActionOver()
        end,
        60
    )
end

---------------------------------- 动画队列代码 -----------------------------
function ShopMainLayer:closeUI()
    G_GetMgr(ACTIVITY_REF.StayCoupon):resetData()

    -- 额外的关闭逻辑处理
    G_GetMgr(G_REF.Shop):setShopClosedFlag(true)
    --清理引导log
    gLobalSendDataManager:getLogFeature().m_uiActionSid = nil
    -- 停掉所有动画
    self:stopAllActions()
    local callback = function()
        if not tolua.isnull(self) then
            self:closeEndFunc()
        end
    end
    ShopMainLayer.super.closeUI(self, callback)
end

function ShopMainLayer:closeUI2(callback)
    -- 额外的关闭逻辑处理
    G_GetMgr(G_REF.Shop):setShopClosedFlag(true)
    --清理引导log
    gLobalSendDataManager:getLogFeature().m_uiActionSid = nil
    -- 停掉所有动画
    self:stopAllActions()
    ShopMainLayer.super.closeUI(self, callback)
end

function ShopMainLayer:closeEndFunc()
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():removeUrlKey(self.__cname)
    end

    if gLobalSendDataManager.getLogIap ~= nil then
        gLobalSendDataManager:getLogIap():closeIapLogInfo()
    end

    if self.buyShop == false then
        if self.m_isPushViewOpenShop == true then
            --弹窗逻辑执行下一个事件
            util_nextFrameFunc(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            )
        else
            -- 如果当前是第二货币界面关闭,不弹出后续点位
            util_nextFrameFunc(
                function()
                    if globalData.shopRunData:getShopPageIndex() ~= 2 then
                        gLobalPushViewControl:showView(PushViewPosType.CloseStore)
                    end
                end
            )
        end
    else
        --弹窗逻辑执行下一个事件
        if gLobalActivityManager.isShowActivity and gLobalActivityManager:isShowActivity() then
        --有开启的活动展示不回复暂停
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_CLOSE_STORE)
    end

    globalNoviceGuideManager:attemptShowRepetition()

    if self.m_isTriggerCloseSale then
        globalData.saleRunData:setShowTopeSale(true)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOP_REFRESH_GASHAPON)
end

----------------------------------- 基础方法 -----------------------------------
function ShopMainLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
        G_GetMgr(G_REF.Shop):showRulesLayer()
    end
end

-- 重写父类方法
function ShopMainLayer:onShowedCallFunc()
    -- 膨胀弹框
    local view = self:checkExpansion()
    -- -- 检测引导，放到最后
    -- if not view then
    --     self:checkBuckGuide()
    -- end
end

-- 膨胀弹框
function ShopMainLayer:checkExpansion()
    local levelRoadMgr = G_GetMgr(G_REF.LevelRoad)
    local shopCarnival = G_GetMgr(ACTIVITY_REF.ShopCarnival)
    local limitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost)
    local view = nil
    if levelRoadMgr then
        view = levelRoadMgr:showLevelRoadBoostLogoLayer()
    end
    if not view and shopCarnival and globalData.constantData.NOVICE_SHOP_CARNIVAL_ANI_ACTIVE then
        view = shopCarnival:showMainLayer()
    end
    if not view and limitExpansion then
        view = limitExpansion:showLogoLayer()
    end
    if not view and vipBoost then
        view = vipBoost:showShopVip()
    end
    self.m_expansionView = view
    return view
end

function ShopMainLayer:checkBuckGuide()
    -- if self.m_currentPageType ~= SHOP_VIEW_TYPE.COIN then
    --     return
    -- end
    -- local isTrigger = self:triggerBuckGuide()
    -- if not isTrigger then
    --     return
    -- end
    -- return true
    return false
end

function ShopMainLayer:triggerGuideStep(guideName, triggerStepId)
    print("ShopMainLayer:triggerGuideStep", guideName, triggerStepId)
    if guideName == "Buck_CoinStore" then
        G_GetMgr(G_REF.ShopBuck):triggerGuide(self, guideName)
    end
end

function ShopMainLayer:triggerGuideOverOfGuideName(guideName)
    print("ShopMainLayer:triggerGuideOverOfGuideName", guideName)
end

function ShopMainLayer:triggerBuckGuide()
    return G_GetMgr(G_REF.ShopBuck):triggerGuide(self, "Buck_CoinStore")
end

-- function ShopMainLayer:onEnterFinish()
--     ShopMainLayer.super.onEnterFinish(self)
    
--     -- csc 2022-02-22 做一个1秒的遮罩屏蔽， 防止动画还没做完就点击到 freecoin
--     gLobalViewManager:addLoadingAnima(true, nil, 1)
--     -- csc 2022-02-25 fix 修复bug
--     util_afterDrawCallBack(
--         function()
--             if not tolua.isnull(self) then
--                 self:enterMainAction()
--             end
--         end
--     )
-- end

function ShopMainLayer:onEnter()
    -- self.m_perBgMusicName = gLobalSoundManager:getCurrBgMusicName()
    -- gLobalSoundManager:playBgMusic(DAILYPASS_RES_PATH.PASS_MISSION_BGM_MP3)
    G_GetMgr(G_REF.FirstCommonSale):requestFirstSale()
    gLobalSoundManager:playSound("Sounds/Coinstore_open.mp3")
    ShopMainLayer.super.onEnter(self)

    if self:findChild("ef_xialia") then
        util_setCascadeOpacityEnabledRescursion(self:findChild("ef_xialia"), true)
        util_setCascadeOpacityEnabledRescursion(self:findChild("ef_xialia_0"), true)
    end
    if self.m_nodeRaipdBtn_left then
        util_setCascadeOpacityEnabledRescursion(self.m_nodeRaipdBtn_left, true)
    end

    -- 设置打点
    local _type = BUY_TYPE.STORE_TYPE
    if globalData.shopRunData:getShopPageIndex() == 2 then
        _type = BUY_TYPE.GEM_TYPE
    end
    local goodsInfo, purchaseInfo = G_GetMgr(G_REF.Shop):getLogShopData(_type)
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)

    -- 刷新常规促销数据
    self:requestSaleData()

    -- 监听按钮跳转界面
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                -- if not self.m_active then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                self:jumpToView(params.type, params.active)
                if self.m_topUiTicket then
                    self.m_topUiTicket:noticeMianLayerListViewSize()
                end
            -- end
            end
        end,
        ViewEventType.NOTIFY_NEWSHOP_JUMPTOVIEW
    )

    -- 购买完成关闭弹板后回调
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                -- 更新UI
                self:refreshUI()
            end
        end,
        ViewEventType.NOTIFY_BUYTIP_CLOSE
    )

    -- 购买热卖完成
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                -- 更新UI
                self:refreshRecommendeList()
            end
        end,
        ViewEventType.NOTIFY_SHOP_HOTSALE_REFRESH
    )

    -- 监听购买成功
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                self.buyShop = true
            end
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    -- 跨天刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                -- 更新UI
                self:refreshUI()
            end
        end,
        ViewEventType.NOTIFY_NEWZEROUPDATE
    )

    -- 优惠劵激活
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.success and not tolua.isnull(self) then
                local actions = self:getMoveActionSeq(0, true)
                local seq = cc.Sequence:create(actions)
                self:runAction(seq)
                -- 更新UI
                self:refreshUI()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STAY_COUPON_SHOP_COIN_ACTION)
            end
        end,
        ViewEventType.NOTIFY_STAY_COUPON_REDEEM_TICKET
    )

    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                -- 更新UI
                self:closeUI2()
            end
        end,
        ViewEventType.NOTIFY_NEWSHOP_CLOSE
    )
end

function ShopMainLayer:onEnterFinish()
    ShopMainLayer.super.onEnterFinish(self)

    self:initItemContentSize()
    if self.m_topUiTicket then
        self.m_topUiTicket:noticeMianLayerListViewSize()
    end

    -- csc 2022-02-22 做一个1秒的遮罩屏蔽， 防止动画还没做完就点击到 freecoin
    gLobalViewManager:addLoadingAnima(true, nil, 1)
    -- csc 2022-02-25 fix 修复bug
    util_afterDrawCallBack(
        function()
            if not tolua.isnull(self) then
                self:enterMainAction()
            end
        end
    )
end


function ShopMainLayer:checkTodayTime()
    self:updateLeftTimeUI()
    self.m_scheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
end
function ShopMainLayer:updateLeftTimeUI()
    local leftTime = util_get_today_lefttime()
    if self.m_lb_soldOut then
        self.m_lb_soldOut:setString(util_count_down_str(leftTime))
    end

    G_GetMgr(ACTIVITY_REF.StayCoupon):checkOpenTicket()
end

return ShopMainLayer
