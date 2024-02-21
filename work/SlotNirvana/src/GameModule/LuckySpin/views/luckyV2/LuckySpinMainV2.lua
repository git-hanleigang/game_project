--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-05 11:58:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-05 12:09:57
FilePath: /SlotNirvana/src/GameModule/LuckySpin/views/LuckySpinMainLayer.lua
Description: LuckySpin 主界面
--]]
local LuckySpinConfig = util_require("GameModule.LuckySpin.config.LuckySpinConfig")
local LuckySpinMainV2 = class("LuckySpinMainV2", BaseLayer)

local UI_TYPE = {
    NORMAL = 1,
    SALE_ACT = 2,
    RANDOM_ACT = 3,
    GOLDEN_ACT = 4,
    ITEM_ACT = 5,
}

function LuckySpinMainV2:ctor()
    LuckySpinMainV2.super.ctor(self)

    local saleData = globalData.luckySpinSaleData -- 升档促销活动
    local randomData = G_GetMgr(ACTIVITY_REF.FireLuckySpinRandomCard):getRunningData() -- 送缺卡活动
    local goldenCardData = G_GetMgr(ACTIVITY_REF.LuckySpinGoldenCard):getRunningData() -- 送luckyspin金卡活动
    local specialData = G_GetMgr(ACTIVITY_REF.LuckySpinSpecial):getRunningData() -- 送道具活动
    self.m_uiType = UI_TYPE.NORMAL
    local csbName = "LuckySpinNew/LuckySpinLayer.csb"
    if saleData:isExist() then
        -- 升档促销活动
        -- csbName = "LuckySpinNew/LuckySpinSaleLayer.csb"
        csbName = "LuckySpinNew/FireLuckySpinUpgradeLayer.csb"
        self.m_uiType = UI_TYPE.SALE_ACT
    elseif randomData then
        -- 送缺卡活动
        csbName = "LuckySpinNew/FireLuckySpinRandomCardLayer.csb"
        self.m_uiType = UI_TYPE.RANDOM_ACT
    elseif goldenCardData then
        -- 送金卡活动
        csbName = "LuckySpinNew/LuckySpinGoldenCardLayer.csb"
        self.m_uiType = UI_TYPE.GOLDEN_ACT
    elseif specialData and not specialData:checkHighComplete() then
        -- 送道具活动
        csbName = "LuckySpinNew/LuckySpinSpecialMainLayer.csb"
        self.m_uiType = UI_TYPE.ITEM_ACT
    end
    self:setLandscapeCsbName(csbName)

    -- 背景音效
    self:setBgm("LuckySpin2Sound/music_LuckySpin_bgm.mp3")
end

function LuckySpinMainV2:initDatas(_data)
    LuckySpinMainV2.super.initDatas(self)

    self.m_closeCB = _data.closeCall
    self.m_buyCellIdx = _data.buyIndex
    self.m_buyCellItemIdx = _data.itemIndex

    self.m_buyShopData = {}
    self.m_oriBuyShopData = {}
    for k, v in pairs(_data.buyShopData) do
        self.m_buyShopData[k] = v
        self.m_oriBuyShopData[k] = v
    end

    self.m_bReconnect = _data.reconnect
end

function LuckySpinMainV2:onEnter()
    LuckySpinMainV2.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function LuckySpinMainV2:initCsbNodes()
    LuckySpinMainV2.super.initCsbNodes(self)
    
    self.m_btnBuy       = self:findChild("btn_buy")
    self.m_btnBuyEnjoy  = self:findChild("btn_buy_enjoy")
    self.m_btnBp        = self:findChild("btn_pb")
    self.m_btnBpEnjoy   = self:findChild("btn_pb_enjoy")
    self.m_btnSpin      = self:findChild("btn_spin")
    self.m_btnClose     = self:findChild("close")
    self.m_nodeFinger   = self:findChild("node_zi")
    self.m_shou = self:findChild("Node_shouzhi")
    self.m_nodeBuck     = self:findChild("node_buck")

    if self.m_btnBuyEnjoy then
        local label_1 = self:findChild("label_1")
        self:updateLabelSize({label = label_1, sx = sx, sy = sx}, 145)    
    end

    self.m_nodeEnjoy    = self:findChild("node_buy_enjoy")
    if self.m_nodeEnjoy then
        self.m_nodeEnjoy:setVisible(false)
    end

    self.m_btnSpin:setTouchEnabled(false)
end

function LuckySpinMainV2:initView()
    -- slot机器
    self:initMachineUI()
    -- 按钮文本
    self:initBtnLbUI()
    -- 断线重连状态
    if self.m_bReconnect then
        self:updateReconectStateUI()
    else
        self:runCsbAction("idle0", true)
    end

    -- logo 图标
    self:initLogoUI()
    -- 活动相关UI
    self:initExActUI()

    self:initBuckTop()
    self:initBuckBtn()
end

function LuckySpinMainV2:initBuckTop()
    local view = G_GetMgr(G_REF.ShopBuck):createBuckTopNode()
    if view then
        self.m_nodeBuck:addChild(view)
    end
end

function LuckySpinMainV2:initBuckBtn()
    self:updateBtnBuck(self.m_btnBuy, LuckySpinConfig.BUY_TYPE.NORMAL)
    self:updateBtnBuck(self.m_btnBuyEnjoy, LuckySpinConfig.BUY_TYPE.ENJOY)
end

function LuckySpinMainV2:updateBtnBuck(_btn, _btnType)
    local buyType = BUY_TYPE.LUCKY_SPINV2_TYPE
    self:setBtnBuckVisible(_btn, buyType)
end

-- slot机器
function LuckySpinMainV2:initMachineUI()
    local parent = self:findChild("reel")
    local view = util_createView("GameModule.LuckySpin.views.luckyV2.GameLuckySpinV2")
    parent:addChild(view)
    view:setIsEnjoyType(false)
    self.m_slotView = view
end

-- 按钮文本
function LuckySpinMainV2:initBtnLbUI()
    -- local LanguageKey = "LuckySpinMainLayer:font_qian"
    -- local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "$ %s"
    local price = globalData.luckySpinV2:getPrice()
    local str = string.format("$ %s", price)

    self:setButtonLabelContent("btn_buy", str)

    self:setButtonLabelContent("btn_spin", "SPIN")
end

-- 断线重连状态
function LuckySpinMainV2:updateReconectStateUI()
    if self.m_btnBp then
        self.m_btnBp:setTouchEnabled(false)
    end
    self.m_btnBuy:setTouchEnabled(false)
    self.m_btnClose:setTouchEnabled(false)
    self.m_btnClose:setVisible(false)
    self.m_btnSpin:setTouchEnabled(true)
    self:addFinger()
    local spinData = globalData.luckySpinV2
    local spord = spinData:getRecod()
    if #spord <= 0 then
        self:runCsbAction("idle1", true)
        return
    end
    local baseCoins = spinData:getCoins() or 0
    local index = #spord
    local itemData = spinData:getCurrentRecod()
    if not itemData then
        self:runCsbAction("idle1", true)
        return
    end
    self:runCsbAction("idle1", true)
    local abc = tonumber(baseCoins) + tonumber(itemData.p_coins)
    self:upDateCoins(abc)
    local label_mul = self.m_fingerNode:findChild("lb_number_"..index)
    label_mul:setString("X"..itemData.p_multiple)
    local nu = index + 1
    self.m_fingerNode:playAction("start"..nu,false,function()
        if nu ~= 3 then
            self.m_fingerNode:playAction("idle"..nu,true)
        end
    end)
end

-- logo 图标
function LuckySpinMainV2:initLogoUI()
    local parent = self:findChild("Node_logo")
    local logoNode = util_createAnimation("LuckySpinNew/Superspin_logo.csb")
    parent:addChild(logoNode)
    self.m_logoView = logoNode
    self:playLogoStart()
end
function LuckySpinMainV2:playLogoStart()
    self.m_logoView:playAction("start", false, util_node_handler(self, self.playLogoIdle), 60) 
end
function LuckySpinMainV2:playLogoIdle()
    self.m_logoView:playAction("idle", false, util_node_handler(self, self.playLogoStart), 60) 
end

-- 活动相关 UI
function LuckySpinMainV2:initExActUI()
    if self.m_uiType == UI_TYPE.SALE_ACT then
        -- self:initSaleActUI()
        self:initUpgradeUI()
    elseif self.m_uiType == UI_TYPE.RANDOM_ACT then
        self:initRondomActUI()
    elseif self.m_uiType == UI_TYPE.ITEM_ACT then
        local node_item = self:findChild("node_item")
        self:initSendItemActUI(node_item)
    end
end

-- 活动相关 奖励
function LuckySpinMainV2:initExActReward()
    if self.m_uiType == UI_TYPE.ITEM_ACT then
        local node_reward = self.m_fingerNode:findChild("node_reward")
        self:initSendItemActUI(node_reward)
    end
end

-- 促销活动特殊 UI
function LuckySpinMainV2:initSaleActUI()
    local labMul = self:findChild("saleLess")
    if labMul ~= nil then
        local mul = globalData.luckySpinSaleData.p_score["other"]
        labMul:setString("X" .. mul)
    end

    -- 三个一样的 信号 给的倍数
    local mulVaule = globalData.luckySpinSaleData:getThreeSameMulValue()
    local lbRaiseMul = self:findChild("shuzi_multipliers")
    lbRaiseMul:setVisible(mulVaule > 0)
    if tolua.type(lbRaiseMul) == "ccui.TextBMFont" then
        lbRaiseMul:setString("X" .. mulVaule)
    end
end
-- 送缺卡活动特殊 UI
function LuckySpinMainV2:initRondomActUI()
    local randomData = G_GetMgr(ACTIVITY_REF.FireLuckySpinRandomCard):getRunningData()
    local cardsNode = self:findChild("node_cards")
    if cardsNode then
        local cardList = {}
        local cardData = randomData:getLastGearCardsInfo()
        for k,v in pairs(cardData) do
            local cardUI = util_createView("GameModule.LuckySpin.views.luckyV2.LuckySpinRandomCardNode", v)
            if cardUI then
                cardsNode:addChild(cardUI)
                local info = {}
                info.node = cardUI
                info.size = cc.size(140, 140)
                info.anchor = cc.p(0.5, 0.5)
                table.insert(cardList, info)
            end
        end

        if #cardList > 0 then
            util_setCascadeOpacityEnabledRescursion(self, true)
            util_alignCenter(cardList)
            randomData:resetPreSpinCards()
        end
    end
    self.m_buyTipType = ACTIVITY_REF.FireLuckySpinRandomCard
end

-- 送道具活动特殊 UI
function LuckySpinMainV2:initSendItemActUI(_nodeItem)
    local data = G_GetMgr(ACTIVITY_REF.LuckySpinSpecial):getData()
    if data and _nodeItem then
        local itemDataList = {}
        local items = data:getCurrentItem()
        -- 通用道具
        if items and #items > 0 then
            for i, v in ipairs(items) do
                v:setTempData({p_mark = {{ITEM_MARK_TYPE.NONE}}})
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
    
        local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
        if itemNode then
            _nodeItem:addChild(itemNode)
        end
    end
end

function LuckySpinMainV2:initUpgradeUI()
    local txtSuper_zi_upgrade = self:findChild("Super_zi_upgrade")
    local lbRaiseMul = self:findChild("shuzi_multipliers")


    if not txtSuper_zi_upgrade or not lbRaiseMul then
        return
    end

    local baseData = globalData.luckySpinV2.p_score
    local upData = globalData.luckySpinSaleData.p_score

    if not baseData or not upData then
        return
    end
    
    local mulSuper_base =  baseData["HIGH"].jackpot
    local mulSuper_up =  upData["HIGH"].jackpot

    if not mulSuper_base or not mulSuper_up then
        return
    end

    txtSuper_zi_upgrade:setString("X" .. mulSuper_base)
    lbRaiseMul:setString("X" .. mulSuper_up)

    local labMul = self:findChild("saleLess")
    if labMul ~= nil then
        local mul = upData["HIGH"].other
        labMul:setString("X" .. mul)
    end
end

function LuckySpinMainV2:addFinger()
    local fingerNode = util_createAnimation("LuckySpinNew/LuckySpinLayer_zi.csb")
    self.m_nodeFinger:addChild(fingerNode)
    fingerNode:playAction("idle1", true, nil, 60)
    self.m_fingerNode = fingerNode
    self:updataFinger()
    self:addShou()
    self:initExActReward()
end

function LuckySpinMainV2:delFinger()
    self.m_shou:removeAllChildren()
end

function LuckySpinMainV2:addShou()
    local fingerNode = util_createAnimation("LuckySpinNew/LuckySpinLayer_shouzhi.csb")
    self.m_shou:addChild(fingerNode)
    fingerNode:playAction("start", true, nil, 60)
end

function LuckySpinMainV2:updataFinger()
    local coins = tonumber(globalData.luckySpinV2:getCoins())
    self:upDateCoins(coins)
end

function LuckySpinMainV2:upDateCoins(_coins)
    local label_coins = self.m_fingerNode:findChild("lb_coin")
    label_coins:setString(util_formatCoins(_coins, 13))
    local uiList = {
        {node = self.m_fingerNode:findChild("sp_coin")},
        {node = label_coins, alignX = 5}
    }
    util_alignCenter(uiList)
end

function LuckySpinMainV2:clickFunc(sender)
    local name = sender:getName()
    if name ~= "spin" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    if name == "close" then
        self:forceCloseUI()
    elseif name == "btn_buy" then
        self:checkItem()
        gLobalDataManager:setNumberByField("lastBuyLuckySpinID", self.m_buyCellIdx)
        G_GetMgr(G_REF.LuckySpin):goPurchaseV2(LuckySpinConfig.BUY_TYPE.NORMAL)
    elseif name == "btn_buy_enjoy" then
        self:checkItem()
        G_GetMgr(G_REF.LuckySpin):goPurchase(LuckySpinConfig.BUY_TYPE.ENJOY, self.m_buyCellIdx)
    elseif name == "btn_spin" then
        self:setButtonLabelDisEnabled("btn_spin", false)
        self.m_slotView:clickSpin()
        self:delFinger()
    elseif name == "btn_pb" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        --商品附带道具
        local coinData, gemsData = globalData.shopRunData:getShopItemDatas()
        local curBuyShopData = nil
        for i, v in ipairs(coinData) do
            if self.m_buyShopData.p_price == v.p_price then
                curBuyShopData = v
                break
            end
        end

        if curBuyShopData then
            local extraItems = curBuyShopData:getExtraPropList()
            G_GetMgr(G_REF.PBInfo):showPBInfoLayer(curBuyShopData, extraItems)
        end

    end
end

-- 组装道具
function LuckySpinMainV2:checkItem()
    local coinData, gemsData = globalData.shopRunData:getShopItemDatas()
    local curBuyShopData = nil
    for i, v in ipairs(coinData) do
        if self.m_buyShopData.p_price == v.p_price then
            curBuyShopData = v
            break
        end
    end
    if not curBuyShopData then
        return
    end

    -- csc fixbug 2021年08月04日 修改每次点击按钮都会导致 p_num累加
    self.m_buyShopData = {}
    for key, value in pairs(self.m_oriBuyShopData) do
        self.m_buyShopData[key] = clone(value)
    end
    for i, v in ipairs(curBuyShopData.p_displayList) do
        local notOwn = true
        for j, k in ipairs(self.m_buyShopData.p_displayList) do
            if v.p_id == k.p_id then
                k.p_num = k.p_num + v.p_num
                notOwn = false
                break
            end
        end
        if notOwn then
            table.insert(self.m_buyShopData.p_displayList, v)
        end
    end
end

-- 领取奖励
function LuckySpinMainV2:collectReward()
    local cb = function()
        local levelUpNum = gLobalSaleManager:getLevelUpNum()
        local view = util_createView("GameModule.Shop.BuyTip")
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, "buy", DotUrlType.UrlName, false)
        end
        local baseCoins = self.m_buyShopData.p_baseCoins
        local reconnect = self.m_bReconnect
        view:initBuyTip(
            "LuckySpinMainV2",
            self.m_buyShopData,
            baseCoins,
            levelUpNum,
            function()
                if reconnect == true then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_SPIN_RECONNECT)
                end
            end,
            reconnect,
            self.m_vipPoint,
            self.m_clubPoint,
            self.m_buyTipType
        )
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    self:closeUI(cb)
end

function LuckySpinMainV2:compareMulity(data)
    local item = data[1]
    local item1 = data[2]
    if tonumber(item.p_multiple) <= tonumber(item1.p_multiple) then
        return item1
    else
        return item
    end
end
-- spin 结束 evt
function LuckySpinMainV2:onGameSpinOverEvt(_params)
    if self.m_nodeEnjoy and self.m_nodeEnjoy:isVisible() then
        -- 先享后付逻辑 玩家可关闭
        self.m_btnClose:setTouchEnabled(true)
        self.m_btnClose:setVisible(true)
    end
    
    local spinData = globalData.luckySpinV2
    local spord = spinData:getRecod()
    local index = #spord
    local itemData = spinData:getCurrentRecod()
    if not itemData then
        return
    end
    local baseCoins = spinData:getCoins() or 0
    local labc = tonumber(itemData.p_coins) + tonumber(baseCoins)
    self:upDateCoins(labc)
    local label_mul = self.m_fingerNode:findChild("lb_number_"..index)
    label_mul:setString("X"..itemData.p_multiple)
    local nu = index + 1
    self.m_fingerNode:playAction("start"..nu,false,function()
        if nu ~= 3 then
            self.m_fingerNode:playAction("idle"..nu,true)
        end
    end)
    if index == 1 then
        self:setButtonLabelDisEnabled("btn_spin", true)
    else
        local item = self:compareMulity(spord)
        local callback = function()
            self:collectReward()
        end
        self.m_fingerNode:findChild("lb_number_3"):setString("X"..item.p_multiple)
        local labc = tonumber(item.p_coins) + tonumber(baseCoins)
        self:upDateCoins(labc)
        performWithDelay(
            self,
            function()
                self.m_fingerNode:playAction("start4",false,function()
                    local rewardFun = function()
                        item.cc = labc
                        G_GetMgr(G_REF.LuckySpin):showRewards(item, callback)
                    end
                    if self.m_uiType == UI_TYPE.ITEM_ACT then
                        self.m_fingerNode:playAction("start5", false, rewardFun, 60)
                    else
                        rewardFun()
                    end
                end)
            end,
            2
        )
        local baseCoins = self.m_buyShopData.p_coins or 0
        self.m_buyShopData.p_coins = labc
        self.m_oriBuyShopData.p_coins = labc
        self.m_vipPoint = _params.vipPoint
        self.m_clubPoint = _params.clubPoint
        globalData.shopRunData:setLuckySpinLevel(_params.offset)
    
    
        local purchaseInfo = {}
        purchaseInfo.purchaseStatus = item.p_multiple
        local goodsInfo = {}
        goodsInfo.totalCoins = labc
        gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
        gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
    end
end

-- 支付成功
function LuckySpinMainV2:onBuySuccessEvt()
    G_GetMgr(ACTIVITY_REF.Gashapon):setSuccessDoLuckySpin(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BUY_STORE_FINISH)

    -- if self.m_nodeEnjoy and self.m_nodeEnjoy:isVisible() then
    --     -- 先享后付逻辑
    --     self:collectReward()
    --     return
    -- end

    -- 切换到 spin 状态
    if self.m_btnBp then
        self.m_btnBp:setTouchEnabled(false)
    end
    self.m_btnBuy:setTouchEnabled(false)
    self.m_btnClose:setTouchEnabled(false)
    self.m_btnClose:setVisible(false)
    
    self:runCsbAction(
        "start1",
        false,
        function()
            self:addFinger()
            self:runCsbAction("idle1", true)
            self.m_btnSpin:setTouchEnabled(true)
        end
    )
end

function LuckySpinMainV2:registerListener()
    LuckySpinMainV2.super.registerListener(self) 

    gLobalNoticManager:addObserver(self, "onGameSpinOverEvt", ViewEventType.NOTIFY_LUCKY_SPIN_OVER)
    gLobalNoticManager:addObserver(self, "onBuySuccessEvt", LuckySpinConfig.EVENT_NAME.LUCKY_SPIN_BUY_SUCCESS)
end

function LuckySpinMainV2:onShowedCallFunc()
    LuckySpinMainV2.super.onShowedCallFunc(self)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IN_LUCKYSPIN, true)
end

function LuckySpinMainV2:hideActionCallback()
    LuckySpinMainV2.super.hideActionCallback(self)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IN_LUCKYSPIN, false)
end

function LuckySpinMainV2:forceCloseUI()
    local cb = function()
        if self.m_closeCB then
            self.m_closeCB(true)
        end
    end
    self:closeUI(cb)
end

return LuckySpinMainV2