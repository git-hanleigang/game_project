--[[
    新版商城 滑动cell 父节点
]]
local ShopBaseItemCellNode = class("ShopBaseItemCellNode", util_require("base.BaseView"))
function ShopBaseItemCellNode:initUI(_type, _index, _shopData, isPortrait)
    self.m_type = _type
    self.m_index = _index
    self.m_itemData = _shopData
    self.m_isPortrait = isPortrait
    self.m_benefitItemList = {}

    self:createCsbNode(self:getCsbName())
    self:updateView()
    self:runCsbAction("idle",true)
end

function ShopBaseItemCellNode:getCsbName()
    if self.m_itemData:isBig() then
        if self.m_isPortrait == true then
            return SHOP_RES_PATH.ItemCell_Big_Vertical
        else
            return SHOP_RES_PATH.ItemCell_Big
        end
    elseif self.m_itemData:isGolden() then
        if self.m_isPortrait == true then
            return SHOP_RES_PATH.ItemCell_Golden_Vertical
        else
            return SHOP_RES_PATH.ItemCell_Golden
        end
    elseif self.m_itemData:isGoldenPet() then
        if self.m_isPortrait == true then
            return SHOP_RES_PATH.ItemCell_PetGolden_Vertical
        else
            return SHOP_RES_PATH.ItemCell_PetGolden
        end
    else
        if self.m_isPortrait == true then
            return SHOP_RES_PATH.ItemCell_Vertical
        else
            return SHOP_RES_PATH.ItemCell
        end
    end
end

function ShopBaseItemCellNode:initCsbNodes()
    -- 读取csb 节点
    self.m_nodeTips = self:findChild("node_tipNode") --
    self.m_nodeExtra = self:findChild("node_extra") --
    self.m_nodeIcon = self:findChild("node_itemIcon") -- 图标icon
    self.m_nodeNumber = self:findChild("node_number") -- 金币 、 钻石 数量
    self.m_nodeNumber_special = self:findChild("node_number_special") -- hotSale 金币 数量
    self.m_nodeCoupon = self:findChild("node_coupon")
    self.m_nodeCardBoost = self:findChild("node_cardBoost")

    self.m_nodeTime = self:findChild("node_recommendedTime")
    self.m_panelSize = self:findChild("layout_touch")
    self.m_btnefitsPanel = self:findChild("btn_benefits_click")

    self.m_luckySpinNode = self:findChild("node_lucky_spin")

    self.m_nodeBuyGuide = self:findChild("node_buyBtnGuide")
    self.m_nodeBtnBuy = self:findChild("node_btnBuy")

    self.m_btnefitsPanel:setSwallowTouches(false)
    self:findChild("btn_benefits_info"):setSwallowTouches(false)
    if self:findChild("btn_benefits_info1") then
        self:findChild("btn_benefits_info1"):setSwallowTouches(false)
    end
    self:addClick(self.m_btnefitsPanel)
end

function ShopBaseItemCellNode:getUpBtnBuyNode()
    return self.m_nodeBuyGuide
end

function ShopBaseItemCellNode:updateView()
    -- 初始化状态
    -- 添加购买按钮
    self:addBtnBuy()
    -- 添加 icon图标
    self:addItemIcon()
    -- 添加numbers
    self:addNumbersNode()
    -- 添加一些可以被刷新的ui
    self:loadDataUI()
end

function ShopBaseItemCellNode:loadDataUI()
    -- 更新按钮价值数据
    self:updatePrice()
    -- 判断是否有 luckyspin
    self:initLuckySpin()
    -- 标签
    self:setMostBestTitile()
    -- 添加奖励道具
    self:addRewardInfo()
    -- 初始化额外加成
    self:initExtra()
    -- 初始化额外加成tips
    self:initExtraTips()
    -- 商城折扣 tips
    self:initTicket()
    -- 首购特殊标签
    self:initFirstBuyUI()
end

function ShopBaseItemCellNode:refreshUiData(_index, _itemData)
    self.m_index = _index
    self.m_itemData = _itemData
    -- 刷新number节点
    local numberNode = self.m_nodeNumber:getChildByName("numberNode")
    if numberNode then
        numberNode:updateItemDataUI(_itemData, self.m_type)
    end
    self:loadDataUI()
end

function ShopBaseItemCellNode:updatePrice()
    if self.m_btnBuy then
        self.m_btnBuy:updatePrice("$" .. self.m_itemData:getPrice())
    end
end

function ShopBaseItemCellNode:updateBtnColor(_isGrey)
    if self.m_btnBuy then
        self.m_btnBuy:updateBtnColor(_isGrey)
    end
end

-- 子类重写
function ShopBaseItemCellNode:addBtnBuy()
    self.m_btnBuy = util_createView("GameModule.Shop2023.views.ShopBase.ShopBaseItemBuy", self:getBuyType(), util_node_handler(self, self.clickBuy))
    self.m_nodeBtnBuy:addChild(self.m_btnBuy)
end

-- 子类重写
function ShopBaseItemCellNode:addItemIcon()
end

-- 子类重写
function ShopBaseItemCellNode:addNumbersNode()
end

function ShopBaseItemCellNode:initLuckySpin()
    if not self.m_luckySpinNode then
        return
    end
    if not self:getShowLuckySpinView() then
        return
    end
    self.m_luckySpinLevel = globalData.shopRunData:getLuckySpinLevel()
    if self:getIsLucky() then
        self.m_isC = 1
        self.m_luckySpinNode:setVisible(true)
        if self.m_luckySpinNode:getChildByName("luckySpinTip") == nil then
            if self:getIsSuper() then
                self.m_isC = 2
            end
            self:addLuckySpinInfo(self.m_isC)
        else
            local c = self.m_isC
            if self:getIsSuper() then
                self.m_isC = 2
            end
            if self.m_isC ~= c then
                local node = self.m_luckySpinNode:getChildByName("luckySpinTip")
                if node and not tolua.isnull(node) then
                    node:removeFromParent()
                end
                self:addLuckySpinInfo(self.m_isC)
            end
        end
    else
        self.m_isC = 0
        self.m_luckySpinNode:setVisible(false)
    end
end

function ShopBaseItemCellNode:addLuckySpinInfo(_type)
    local path = nil
    if _type == 2 then
        path = "shop_title/superspin_special.csb"
    end
    local luckySpinTip = util_createView("GameModule.Shop.shopLuckySpinTip",path)
    luckySpinTip:setName("luckySpinTip")
    self.m_luckySpinNode:addChild(luckySpinTip)
end

function ShopBaseItemCellNode:getIsLucky()
    local luckdata = globalData.luckySpinV2
    local isf = false
    if luckdata and #luckdata:getGearList() > 0 then
        for i,v in ipairs(luckdata:getGearList()) do
            if v.p_index == self.m_itemData.p_id and v.p_remainingTimes > 0 then
                isf = true
                break
            end
        end
    end
    return isf
end

function ShopBaseItemCellNode:getIsSuper()
    local luckdata = globalData.luckySpinV2
    local isf = false
    if luckdata and #luckdata:getGearList() > 0 then
        for i,v in ipairs(luckdata:getGearList()) do
            if v.p_index == self.m_itemData.p_id and v.p_type == "HIGH" then
                isf = true
                break
            end
        end
    end
    return isf
end

function ShopBaseItemCellNode:setMostBestTitile()
    if self.m_type == SHOP_VIEW_TYPE.GEMS then
        self.m_nodeTips:setVisible(false)
        return
    end
    -- 有活动的时候不展示 most popu 标签
    if G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getShopRandomCardIsOpen() then
        if self.m_itemData.p_shopCardDiscount and self.m_itemData.p_shopCardDiscount > 0 then
            self.m_nodeTips:setVisible(false)
            return
        end
    end
    local tag = self.m_itemData.p_tag
    local id = (tag and tag.p_id) and tag.p_id or nil
    if id == TAGTYPE.TAGTYPE_MOST then
        self:findChild("sp_tip_popular"):setVisible(true)
        self:findChild("sp_tip_best"):setVisible(false)
    elseif id == TAGTYPE.TAGTYPE_BEST then
        self:findChild("sp_tip_popular"):setVisible(false)
        self:findChild("sp_tip_best"):setVisible(true)
    else
        self.m_nodeTips:setVisible(false)
    end

    -- 竖版情况下 如果同时存在 折扣跟标签，需要隐藏标签
    if self.m_isPortrait == true then
        if self.m_itemData:getDiscount() > 0 then
            self.m_nodeTips:setVisible(false)
        end
    end
end

function ShopBaseItemCellNode:addRewardInfo()
    for i = #self.m_benefitItemList, 1, -1 do
        local node = self.m_benefitItemList[i]
        node:removeFromParent()
        table.remove(self.m_benefitItemList, i)
    end

    local cardData = self:getCardData()
    local rewardItemDatas = self:getItemData()
    local index = 1
    local offX = 0 --X偏移
    --有卡牌第一个位置放卡牌
    if cardData then
        local cardItem = self:createPropNode(cardData)
        local benefitNode = self:getBenefitNode(index)
        if cardItem then
            benefitNode:addChild(cardItem)
            index = index + 1 --跳过一个
        end
        if self.m_isPortrait == true then
            offX = 0
        end
        table.insert(self.m_benefitItemList, cardItem)
    end

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
function ShopBaseItemCellNode:getCardData()
end

-- 子类重写
function ShopBaseItemCellNode:getItemData()
    return {}
end

function ShopBaseItemCellNode:getBenefitNode(_index)
    return self:findChild("node_benefit_" .. _index)
end

function ShopBaseItemCellNode:createPropNode(_data)
    if _data == nil or _data.p_icon == "Coupon" then
        return nil
    end
    if _data.p_icon == "CashBack" then
        _data:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
    end
    _data = G_GetMgr(G_REF.Shop):getDescShopItemData(_data)
    local propNode = gLobalItemManager:createDescSingleNumNode(_data, ITEM_SIZE_TYPE.TOP)
    if propNode.setIconTouchEnabled then
        propNode:setIconTouchEnabled(false)
    end
    return propNode
end

-- 子类重写：活动打折，位于金币右边
function ShopBaseItemCellNode:initExtra(switchKey)
    if not self.m_itemData.getDiscount then
        if self.m_itemData.__cname then
            release_print("------------------ZQCoinStoreItem:initExtra itemData class name = " .. self.m_itemData.__cname)
        end
    end
    local value = self.m_itemData:getDiscount()
    local showExtraAct = value > 0 and G_GetMgr(G_REF.Shop):getPromomodeOpen()
    if not self.m_ShopExtraNode then
        local extraNode = util_createView(SHOP_CODE_PATH.ItemExtraNode,showExtraAct)
        self.m_nodeExtra:addChild(extraNode)
        self.m_ShopExtraNode = extraNode
    end

    if showExtraAct then
        self.m_ShopExtraNode:setDiscountValue(value)
        if switchKey == "on" then
            self.m_ShopExtraNode:playShow()
        elseif switchKey == "off" then
            self.m_ShopExtraNode:playHide()
        else
            self.m_ShopExtraNode:onShow()
        end
    else
        self.m_ShopExtraNode:playHide()
        --self.m_ShopExtraNode:onHide()
    end
end

-- 子类重写: 额外的活动添加tips ，位于金币上
function ShopBaseItemCellNode:initExtraTips()
end

-- 子类重写：折扣道具
function ShopBaseItemCellNode:initTicket()
    local hasSaleTicket = false
    if self.m_itemData.p_ticketDiscount and self.m_itemData.p_ticketDiscount > 0 then
        hasSaleTicket = true
    end
    local firstBuyDisc = 0
    if self.m_itemData.m_bCoinsType and self.m_itemData.getFirstBuyDiscount then
        -- 金币类型 有商城首购 不显示优惠卷 把优惠劵放到 总折扣显示里
        firstBuyDisc = self.m_itemData:getFirstBuyDiscount()
    end
    if firstBuyDisc > 0 then
        hasSaleTicket = false
    end
    local ticketType = globalData.shopRunData:getTicketType(self.m_type)
    if ticketType == "All" then
        -- 统一档位优惠卷 显示到主界面topUI 单独档位处不用显示
        hasSaleTicket = false
    end

    if hasSaleTicket and G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        if not self.m_ticketItem then
            self.m_ticketItem = util_createView(self:getTicketLuaName())
            self.m_nodeCoupon:addChild(self.m_ticketItem)
        end
        if self.m_ticketItem then
            self.m_ticketItem:updateUI(self.m_itemData)
        end
    else
        if self.m_ticketItem then
            self.m_ticketItem:removeFromParent()
            self.m_ticketItem = nil
        end
    end
end

-- 子类重写：首购特殊标签
function ShopBaseItemCellNode:initFirstBuyUI()
end

-- 子类重写 :如果有不同的ticket 展示的话
function ShopBaseItemCellNode:getTicketLuaName()
    return SHOP_CODE_PATH.ItemTicketNode
end

-- 子类重写
function ShopBaseItemCellNode:getBuyType()
    return ""
end

-- 子类重写
function ShopBaseItemCellNode:getAddCoins()
    return 0
end

-- 子类重写
function ShopBaseItemCellNode:getShowLuckySpinView()
    return true
end

function ShopBaseItemCellNode:getBuyDataBaseNums()
    return self.m_preBuyShowData.p_baseCoins
end

function ShopBaseItemCellNode:getCellContentSize()
    return self.m_panelSize:getContentSize()
end

function ShopBaseItemCellNode:clickFunc(_sender)
    local name = _sender:getName()
    if G_GetMgr(G_REF.Shop):getShopClosedFlag() then
        return
    end
    if name == "btn_benefits_info" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    elseif name == "btn_benefits_click" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local view = util_createView(SHOP_CODE_PATH.ItemBenefitBoardLayer, self.m_itemData, self.m_type)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

function ShopBaseItemCellNode:clickBuy()
    if G_GetMgr(G_REF.Shop):getShopClosedFlag() then
        return
    end    
    -- 触发购买
    self:playBuySound()
    self.m_go = self.m_isC
    self:doBuyLogic()
end

function ShopBaseItemCellNode:playBuySound()
    local buyShopData = self.m_itemData
    if buyShopData == nil then
        return
    end        
    local buckMgr = G_GetMgr(G_REF.ShopBuck)
    if not (buckMgr and buckMgr:canBuyByBuck(self:getBuyType(), buyShopData.p_price)) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end    
end

function ShopBaseItemCellNode:doBuyLogic()
    local buyShopData = self.m_itemData
    if buyShopData == nil then
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

function ShopBaseItemCellNode:checkCouponSwitch()
    if not G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        if self.m_type == 1 then
            self.m_preBuyShowData.p_coins = self.m_preBuyShowData.p_originalCoins
        elseif self.m_type == 2 then
            self.m_preBuyShowData.p_gems = self.m_preBuyShowData.p_originalGems
        end

        local couponData = G_GetMgr(ACTIVITY_REF.Coupon):getRunningData()
        if couponData then
            local itemData = {}
            local couponItems = couponData:getShopGifts()
            for i,v in ipairs(self.m_preBuyShowData.p_displayList) do
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
            self.m_preBuyShowData.p_displayList = itemData
        end
    end
end

function ShopBaseItemCellNode:buySuccess()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYCOINS_SUCCESS)
    if  not tolua.isnull(self) then
       --购买成功 盖戳
        if self.m_go and self.m_go ~= 0 then
            local luckySpinData = {}
            luckySpinData.buyShopData = clone(self.m_preBuyShowData)
            luckySpinData.buyIndex    = self.m_index
            luckySpinData.itemIndex   = self.m_index
            luckySpinData.closeCall   = function(isResetShopLog)
                if  not tolua.isnull(self)  then
                    self:showBuyTip(isResetShopLog)
                end
            end
            if self.m_go == 2 then
                G_GetMgr(G_REF.LuckySpin):showMainV2(luckySpinData)
            else
                G_GetMgr(G_REF.LuckySpin):showMainLayer(luckySpinData)
            end
        else
            self:showBuyTip()
        end
    end
end

function ShopBaseItemCellNode:buyFailed()
    G_GetMgr(ACTIVITY_REF.StayCoupon):addFailTime()
end

function ShopBaseItemCellNode:showBuyTip(isResetShopLog)
    if isResetShopLog then
        --没有购买lucky重置log 修改位置了这里应该不需要先放着
        local goodsInfo, purchaseInfo = G_GetMgr(G_REF.Shop):getLogShopData()
        gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
        gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BUY_STORE_FINISH)

    local view = self:createBuyTipUI()
    if gLobalSendDataManager.getLogPopub then
        if not self.m_clickBtnName then
            self.m_clickBtnName = "loseBtn"
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(view, self.m_clickBtnName, DotUrlType.UrlName, false)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOP_HOTSALE_REFRESH)
    
end

-- 子类可重写
function ShopBaseItemCellNode:createBuyTipUI()
    local view = util_createView("GameModule.Shop.BuyTip")
    local buyType = self:getBuyType()
    local buyDataBaseNums = self:getBuyDataBaseNums(self.m_preBuyShowData)
    view:initBuyTip(
        buyType,
        self.m_preBuyShowData,
        buyDataBaseNums,
        gLobalSaleManager:getLevelUpNum(),
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ShopBaseItemCellNode:onEnter()
    ShopBaseItemCellNode.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.SaleTicket then
                self:initTicket()
            elseif params.name == ACTIVITY_REF.Coupon then
                self:initExtra()
            elseif params.name == ACTIVITY_REF.GemStoreSale then
                self:initExtra()
            elseif params.name == ACTIVITY_REF.GemCoupon then
                self:initExtra()
            elseif params.name == ACTIVITY_REF.StoreSaleRandomCard then
                self:initExtraTips()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:doWitchLogic(params)
        end,
        ViewEventType.NOTIFY_SHOP_PROMO_SWITCH
    )
end

function ShopBaseItemCellNode:doWitchLogic(params)
    if params == "on" then
        self:initExtra("on")
        self:initTicket()
        self:initFirstBuyUI()
    elseif params == "off" then
        self:initExtra("off")
        self:initTicket()
        self:initFirstBuyUI()
    end
end

-- itemcell 扫光
function ShopBaseItemCellNode:playItemCellAction(_callback)
    self:runCsbAction(
        "idle",
        false,
        function()
            if _callback then
                _callback()
            end
        end,
        60
    )
end

function ShopBaseItemCellNode:addTimeNode()
    if self.m_nodeTime then
        self.m_timeNode = util_createView(SHOP_CODE_PATH.RecommendedTimeNode,self.m_itemData)
        self.m_nodeTime:addChild(self.m_timeNode)
    end
end

function ShopBaseItemCellNode:updatePayTimes()
    if self.m_timeNode then
        self.m_timeNode:updatePayTimes(self.m_itemData)
    end
end

function ShopBaseItemCellNode:checkActionTimer()
    -- 推荐位变为商城档位的时候,隐藏掉时间节点
    if self.m_IsShowStorePrice then
        self.m_timeNode:setVisible(false)
    end
    self.m_timeNode:checkActionTimer(self.m_IsShowStorePrice)
end

return ShopBaseItemCellNode
