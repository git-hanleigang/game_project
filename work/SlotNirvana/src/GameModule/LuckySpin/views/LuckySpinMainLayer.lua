--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-05 11:58:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-05 12:09:57
FilePath: /SlotNirvana/src/GameModule/LuckySpin/views/LuckySpinMainLayer.lua
Description: LuckySpin 主界面
--]]
local LuckySpinConfig = util_require("GameModule.LuckySpin.config.LuckySpinConfig")
local LuckySpinMainLayer = class("LuckySpinMainLayer", BaseLayer)

local UI_TYPE = {
    NORMAL = 1,
    SALE_ACT = 2,
    RANDOM_ACT = 3,
    GOLDEN_ACT = 4,
    ITEM_ACT = 5,
}

function LuckySpinMainLayer:ctor()
    LuckySpinMainLayer.super.ctor(self)

    local saleData = globalData.luckySpinSaleData -- 升档促销活动
    local randomData = G_GetMgr(ACTIVITY_REF.LuckySpinRandomCard):getRunningData() -- 送缺卡活动
    local goldenCardData = G_GetMgr(ACTIVITY_REF.LuckySpinGoldenCard):getRunningData() -- 送luckyspin金卡活动
    local specialData = G_GetMgr(ACTIVITY_REF.LuckySpinSpecial):getRunningData() -- 送道具活动

    self.m_uiType = UI_TYPE.NORMAL
    local csbName = "LuckySpin2/LuckySpinLayer.csb"
    if saleData:isExist() then
        -- 升档促销活动
        -- csbName = "LuckySpin2/LuckySpinSaleLayer.csb"
        csbName = "LuckySpin2/LuckySpinUpgradeLayer.csb"
        self.m_uiType = UI_TYPE.SALE_ACT
    elseif randomData then
        -- 送缺卡活动
        csbName = "LuckySpin2/LuckySpinRandomCardLayer.csb"
        self.m_uiType = UI_TYPE.RANDOM_ACT
    elseif goldenCardData then
        -- 送金卡活动
        csbName = "LuckySpin2/LuckySpinGoldenCardLayer.csb"
        self.m_uiType = UI_TYPE.GOLDEN_ACT
    elseif specialData and not specialData:checkNormalComplete() then
        -- 送道具活动
        csbName = "LuckySpin2/LuckySpinSpecial.csb"
        self.m_uiType = UI_TYPE.ITEM_ACT
    end
    self:setLandscapeCsbName(csbName)

    -- 背景音效
    self:setBgm("LuckySpin2Sound/music_LuckySpin_bgm.mp3")
end

function LuckySpinMainLayer:initDatas(_data)
    LuckySpinMainLayer.super.initDatas(self)

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

function LuckySpinMainLayer:onEnter()
    LuckySpinMainLayer.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    util_setCascadeColorEnabledRescursion(self, true)
end

function LuckySpinMainLayer:initCsbNodes()
    LuckySpinMainLayer.super.initCsbNodes(self)
    
    self.m_btnBuy       = self:findChild("btn_buy")
    self.m_btnBuyEnjoy  = self:findChild("btn_buy_enjoy")
    self.m_btnBp        = self:findChild("btn_pb")
    self.m_btnBpEnjoy   = self:findChild("btn_pb_enjoy")
    self.m_btnSpin      = self:findChild("btn_spin")
    self.m_btnClose     = self:findChild("close")
    self.m_btnCollect   = self:findChild("collect")
    self.m_nodeFinger   = self:findChild("Node_shouzhi")

    self.m_nodeBuck     = self:findChild("node_buck")

    self.m_nodeEnjoy    = self:findChild("node_buy_enjoy")
    self.m_nodeEnjoy:setVisible(false)

    if self.m_btnBuyEnjoy then
        local label_1 = self:findChild("label_1")
        self:updateLabelSize({label = label_1, sx = sx, sy = sx}, 145)    
    end

    self:startButtonAnimation("btn_buy", "sweep")
    self:startButtonAnimation("btn_buy_enjoy", "sweep")
    self:startButtonAnimation("collect", "sweep")

    self.m_btnSpin:setTouchEnabled(false)
    self.m_btnCollect:setTouchEnabled(false)
end

function LuckySpinMainLayer:initView()
    -- slot机器
    self:initMachineUI()
    -- 按钮文本
    self:initBtnLbUI()
    -- 断线重连状态
    if self.m_bReconnect then
        self:updateReconectStateUI()
    else
        self:runCsbAction("idle1", true)
    end

    -- logo 图标
    self:initLogoUI()
    -- 活动相关UI
    self:initExActUI()

    self:initBuckTop()
    self:initBuckBtn()
end

function LuckySpinMainLayer:initBuckTop()
    local view = G_GetMgr(G_REF.ShopBuck):createBuckTopNode()
    if view then
        self.m_nodeBuck:addChild(view)
    end
end

function LuckySpinMainLayer:initBuckBtn()
    self:updateBtnBuck(self.m_btnBuy, LuckySpinConfig.BUY_TYPE.NORMAL)
    self:updateBtnBuck(self.m_btnBuyEnjoy, LuckySpinConfig.BUY_TYPE.ENJOY)
end

function LuckySpinMainLayer:updateBtnBuck(_btn, _btnType)
    local buyType = BUY_TYPE.LUCKY_SPIN_TYPE
    self:setBtnBuckVisible(_btn, buyType)
end

-- slot机器
function LuckySpinMainLayer:initMachineUI()
    local parent = self:findChild("reel")
    local view = util_createView("GameModule.LuckySpin.views.GameLuckySpin")
    parent:addChild(view)
    view:setIsEnjoyType(false)
    self.m_slotView = view
end

-- 按钮文本
function LuckySpinMainLayer:initBtnLbUI()
    -- local LanguageKey = "LuckySpinMainLayer:font_qian"
    -- local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "$ %s"
    local price = globalData.luckySpinV2:getPrice()
    local str = string.format("$ %s", price)

    self:setButtonLabelContent("btn_buy", str)

    self:setButtonLabelContent("btn_spin", "SPIN")
    self:setButtonLabelContent("btn_buy_enjoy", str)
end

-- 断线重连状态
function LuckySpinMainLayer:updateReconectStateUI()
    if self.m_btnBp then
        self.m_btnBp:setTouchEnabled(false)
    end
    self.m_btnBuy:setTouchEnabled(false)
    self.m_btnClose:setTouchEnabled(false)
    self.m_btnClose:setVisible(false)
    self.m_btnSpin:setTouchEnabled(true)
    self:addFinger()
    
    self:runCsbAction("idle2", true)
end

-- logo 图标
function LuckySpinMainLayer:initLogoUI()
    local parent = self:findChild("Node_logo")
    local logoNode = util_createAnimation("LuckySpin2/Superspin_logo.csb")
    parent:addChild(logoNode)
    self.m_logoView = logoNode
    self:playLogoStart()
end
function LuckySpinMainLayer:playLogoStart()
    self.m_logoView:playAction("start", false, util_node_handler(self, self.playLogoIdle), 60) 
end
function LuckySpinMainLayer:playLogoIdle()
    self.m_logoView:playAction("idle", false, util_node_handler(self, self.playLogoStart), 60) 
end

-- 活动相关 UI
function LuckySpinMainLayer:initExActUI()
    if self.m_uiType == UI_TYPE.SALE_ACT then
        -- self:initSaleActUI()
        self:initUpgradeUI() -- 升档做了新的，以前的可能不用了，但是代码没有删除
    elseif self.m_uiType == UI_TYPE.RANDOM_ACT then
        self:initRondomActUI()
    elseif self.m_uiType == UI_TYPE.ITEM_ACT then
        self:initSendItemActUI()
    end
end
-- 促销活动特殊 UI
function LuckySpinMainLayer:initSaleActUI()
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
function LuckySpinMainLayer:initRondomActUI()
    local randomData = G_GetMgr(ACTIVITY_REF.LuckySpinRandomCard):getRunningData()
    local cardsNode = self:findChild("node_cards")
    if cardsNode then
        local cardList = {}
        for i = 1, 3 do
            local cardUI = util_createFindView("Activity/LuckySpinRandomCard/LuckySpinRandomCardNode", i)
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
        end
    end
    self.m_buyTipType = ACTIVITY_REF.LuckySpinRandomCard
end

-- 送道具活动特殊 UI
function LuckySpinMainLayer:initSendItemActUI()
    local data = G_GetMgr(ACTIVITY_REF.LuckySpinSpecial):getRunningData()
    if data then
        local itemDataList = {}
        local items = data:getCurrentItem()
        -- 通用道具
        if items and #items > 0 then
            for i, v in ipairs(items) do
                v:setTempData({p_mark = {{ITEM_MARK_TYPE.NONE}}})
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
    
        for i = 1, 2 do
            local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
            local node_item = self:findChild("node_item_" .. i)
            if node_item and itemNode then
                node_item:addChild(itemNode)
            end
        end
    end
end

function LuckySpinMainLayer:initUpgradeUI()
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
    
    local mulSuper_base =  baseData["NORMAL"].same
    local mulSuper_up =  upData["NORMAL"].same

    if not mulSuper_base or not mulSuper_up then
        return
    end

    txtSuper_zi_upgrade:setString("X" .. mulSuper_base)
    lbRaiseMul:setString("X" .. mulSuper_up)

    local labMul = self:findChild("saleLess")
    if labMul ~= nil then
        local mul = upData["NORMAL"].other
        labMul:setString("X" .. mul)
    end
end

function LuckySpinMainLayer:addFinger()
    local fingerNode = util_createAnimation("LuckySpin2/LuckySpinLayer_shouzhi.csb")
    self.m_nodeFinger:addChild(fingerNode)
    fingerNode:playAction("start", true, nil, 60)
end
function LuckySpinMainLayer:delFinger()
    self.m_nodeFinger:removeAllChildren()
end

function LuckySpinMainLayer:clickFunc(sender)
    local name = sender:getName()
    if name ~= "spin" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    if name == "close" then
        if self.m_nodeEnjoy and self.m_nodeEnjoy:isVisible() then
            -- 先享后付
            self:forceCloseUI()
            return
        end

        local bPopEnjoyTip = globalData.luckySpinV2:getIsEnjoy()
        if bPopEnjoyTip then
            G_GetMgr(G_REF.LuckySpin):showEnjoyTipLayer(self)
            return
        end
        self:forceCloseUI()
    elseif name == "btn_buy" then
        self:checkItem()
        gLobalDataManager:setNumberByField("lastBuyLuckySpinID", self.m_buyCellIdx)
        G_GetMgr(G_REF.LuckySpin):goPurchaseV2(LuckySpinConfig.BUY_TYPE.NORMAL)
    elseif name == "btn_buy_enjoy" then
        self:checkItem()
        G_GetMgr(G_REF.LuckySpin):goPurchaseV2(LuckySpinConfig.BUY_TYPE.ENJOY, self.m_buyCellIdx)
    elseif name == "btn_spin" then
        self:setButtonLabelDisEnabled("btn_spin", false)
        self.m_slotView:clickSpin()
        self:delFinger()
    elseif name == "collect" then
        self:collectReward()
    elseif name == "btn_pb" or name == "btn_pb_enjoy" then
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
function LuckySpinMainLayer:checkItem()
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
function LuckySpinMainLayer:collectReward()
    self.m_btnCollect:setTouchEnabled(false)
    local cb = function()
        local levelUpNum = gLobalSaleManager:getLevelUpNum()
        local view = util_createView("GameModule.Shop.BuyTip")
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, "buy", DotUrlType.UrlName, false)
        end
        local baseCoins = self.m_buyShopData.p_baseCoins
        local reconnect = self.m_bReconnect
        view:initBuyTip(
            "LuckySpinMainLayer",
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

function LuckySpinMainLayer:onGameSpinOverEvt(_params)
    local isEnjoy = false
    if self.m_nodeEnjoy and self.m_nodeEnjoy:isVisible() then
        -- 先享后付逻辑 玩家可关闭
        self.m_btnClose:setTouchEnabled(true)
        self.m_btnClose:setVisible(true)
        isEnjoy = true
    end
    local coins = 0
    local mult = 0
    if _params.multiple then
        coins = tonumber(_params.coins)
        mult = _params.multiple
    else
        local spinData = globalData.luckySpinV2
        local itemData = spinData:getCurrentRecod()
        coins = tonumber(itemData.p_coins)
        mult = itemData.p_multiple
    end
    local baseCoins = self.m_buyShopData.p_coins or 0
    local lbBaseCoins = self:findChild("base")
    lbBaseCoins:setString(util_formatCoins(baseCoins, 13))
    self:updateLabelSize({label = lbBaseCoins}, 228)

    local lbMultiple  = self:findChild("multip")
    lbMultiple:setString("X" .. mult)
    local lbTotalCoin = self:findChild("total")
    lbTotalCoin:setString(util_formatCoins(coins, 13))
    util_alignCenter(
        {
            {node = self:findChild("sp_coin")},
            {node = lbTotalCoin, alignX = 5}
        }
    )

    self.m_buyShopData.p_coins = coins
    self.m_oriBuyShopData.p_coins = coins
    self.m_vipPoint = _params.vipPoint
    self.m_clubPoint = _params.clubPoint
    globalData.shopRunData:setLuckySpinLevel(_params.offset)

    -- spin 结束展示 领取信息
    if isEnjoy and self.m_uiType == UI_TYPE.ITEM_ACT then
        self:runCsbAction("idle3", true)
        if self.m_btnCollect:isVisible() then
            self.m_btnCollect:setTouchEnabled(true)
        end
    else
        self:runCsbAction(
            "actionframe2",
            false,
            function()
                self:runCsbAction("idle3", true)
                if self.m_btnCollect:isVisible() then
                    self.m_btnCollect:setTouchEnabled(true)
                end
            end
        )
    end

    local purchaseInfo = {}
    purchaseInfo.purchaseStatus = mult
    local goodsInfo = {}
    goodsInfo.totalCoins = coins - baseCoins
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
end
-- spin 结束 evt
-- function LuckySpinMainLayer:onGameSpinOverEvt(_params)
--     if self.m_nodeEnjoy and self.m_nodeEnjoy:isVisible() then
--         -- 先享后付逻辑 玩家可关闭
--         self.m_btnClose:setTouchEnabled(true)
--         self.m_btnClose:setVisible(true)
--     end
    
--     local spinData = globalData.luckySpinV2
--     local spord = spinData:getRecod()
--     local index = #spord
--     local itemData = spinData:getCurrentRecod()
--     if not itemData then
--         return
--     end
    
--     local baseCoins = self.m_buyShopData.p_coins or 0
--     local lbBaseCoins = self:findChild("base")
--     lbBaseCoins:setString(util_formatCoins(baseCoins, 30))
--     self:updateLabelSize({label = lbBaseCoins}, 228)

--     local lbMultiple  = self:findChild("multip")
--     lbMultiple:setString("X" .. itemData.p_multiple)
--     local lbTotalCoin = self:findChild("total")
--     lbTotalCoin:setString(util_formatCoins(tonumber(itemData.p_coins), 30))
--     util_alignCenter(
--         {
--             {node = self:findChild("sp_coin")},
--             {node = lbTotalCoin, alignX = 5}
--         }
--     )

--     self.m_buyShopData.p_coins = itemData.p_coins
--     self.m_oriBuyShopData.p_coins = itemData.p_coins
--     self.m_vipPoint = _params.vipPoint
--     self.m_clubPoint = _params.clubPoint
--     globalData.shopRunData:setLuckySpinLevel(_params.offset)

--     -- spin 结束展示 领取信息
--     self:runCsbAction(
--         "actionframe2",
--         false,
--         function()
--             self:runCsbAction("idle3", true)
--             if self.m_btnCollect:isVisible() then
--                 self.m_btnCollect:setTouchEnabled(true)
--             end
--         end
--     )

--     local purchaseInfo = {}
--     purchaseInfo.purchaseStatus = itemData.p_multiple
--     local goodsInfo = {}
--     goodsInfo.totalCoins = itemData.p_coins - baseCoins
--     gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
--     gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
-- end

-- 支付成功
function LuckySpinMainLayer:onBuySuccessEvt()
    G_GetMgr(ACTIVITY_REF.Gashapon):setSuccessDoLuckySpin(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BUY_STORE_FINISH)

    if self.m_nodeEnjoy and self.m_nodeEnjoy:isVisible() then
        -- 先享后付逻辑
        self:collectReward()
        return
    end

    -- 切换到 spin 状态
    if self.m_btnBp then
        self.m_btnBp:setTouchEnabled(false)
    end
    self.m_btnBuy:setTouchEnabled(false)
    self.m_btnClose:setTouchEnabled(false)
    self.m_btnClose:setVisible(false)
    
    self:runCsbAction(
        "actionframe1",
        false,
        function()
            self:addFinger()
            self:runCsbAction("idle2", true)
            self.m_btnSpin:setTouchEnabled(true)
        end
    )
end

-- 先享受 spin 逻辑
function LuckySpinMainLayer:onShowEnjoyEvt()
    if self.m_btnBp then
        self.m_btnBp:setTouchEnabled(false)
    end
    self.m_btnBuy:setTouchEnabled(false)
    self.m_btnClose:setTouchEnabled(false)
    self.m_btnClose:setVisible(false)
    self.m_nodeEnjoy:setVisible(true)
    self.m_btnCollect:setVisible(false)
    local showName, idleName = self:getShowEnjoyAnimationName()
    self:runCsbAction(
        showName,
        false,
        function()
            self:addFinger()
            self:runCsbAction(idleName, true)
            self.m_btnSpin:setTouchEnabled(true)
        end
    )
    self.m_slotView:setIsEnjoyType(true)
end

function LuckySpinMainLayer:getShowEnjoyAnimationName()
    if self.m_uiType == UI_TYPE.ITEM_ACT then
        return "actionframe4", "idle5"
    end
    return "actionframe1", "idle2"
end

function LuckySpinMainLayer:registerListener()
    LuckySpinMainLayer.super.registerListener(self) 

    gLobalNoticManager:addObserver(self, "onGameSpinOverEvt", ViewEventType.NOTIFY_LUCKY_SPIN_OVER)
    gLobalNoticManager:addObserver(self, "onBuySuccessEvt", LuckySpinConfig.EVENT_NAME.LUCKY_SPIN_BUY_SUCCESS)
end

function LuckySpinMainLayer:onShowedCallFunc()
    LuckySpinMainLayer.super.onShowedCallFunc(self)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IN_LUCKYSPIN, true)
end

function LuckySpinMainLayer:hideActionCallback()
    LuckySpinMainLayer.super.hideActionCallback(self)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IN_LUCKYSPIN, false)
end

function LuckySpinMainLayer:forceCloseUI()
    local cb = function()
        if self.m_closeCB then
            self.m_closeCB(true)
        end
    end
    self:closeUI(cb)
end

return LuckySpinMainLayer