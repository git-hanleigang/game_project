--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-01 15:17:25
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-01 15:32:38
FilePath: /SlotNirvana/src/GameModule/FirstSaleMulti/views/FirstSaleMultiLayer.lua
Description: 三档首充 主界面
--]]
local FirstSaleMultiLayer = class("FirstSaleMultiLayer", BaseLayer)
local FirstSaleMultiConfig = util_require("GameModule.FirstSaleMulti.config.FirstSaleMultiConfig")

function FirstSaleMultiLayer:initDatas(_params)
    self.m_data = G_GetMgr(G_REF.FirstSaleMulti):getData()
    self.p_params = _params or {}
    self.m_triggerPosition = self.p_params.pos or "Stroe"
    -- 是否需要弹出广告
    self.m_closePlayAds = self.p_params.playAds or false

    self:setPortraitCsbName("Promotion/FirstMultiSale/Activity/csb/FirstMultiSale_shu.csb")
    self:setLandscapeCsbName("Promotion/FirstMultiSale/Activity/csb/FirstMultiSale.csb")

    self:setKeyBackEnabled(false)
    self:setPauseSlotsEnabled(true)
    self:setName("FirstSaleMultiLayer")
end

function FirstSaleMultiLayer:initCsbNodes()
    self.m_lbTime = self:findChild("lb_time")
end

function FirstSaleMultiLayer:playShowAction()
    gLobalSoundManager:playSound("Promotion/FirstMultiSale/Sounds/firstPayOpen.mp3")
    FirstSaleMultiLayer.super.playShowAction(self, "start")
end

function FirstSaleMultiLayer:onShowedCallFunc()
    FirstSaleMultiLayer.super.onShowedCallFunc(self)
    self:runCsbAction("idle", true)
end

function FirstSaleMultiLayer:initView()
    -- 三档 促销信息
    self:initLevelInfoUI()
    -- 一键购买 信息
    self:initBtnAllUI()
    self:updateBtnState()
    -- 时间
    self.m_scheduler = schedule(self, handler(self, self.updateTimeLbUI), 1)
    self:updateTimeLbUI()
end

 -- 三档 促销信息
function FirstSaleMultiLayer:initLevelInfoUI()
    for i = 1, 3 do
        local levelData = self.m_data:getLevelDataByList(i)

        -- 购买按钮lb
        local lbBtn = self:findChild("lb_buy" .. i)
        local price = levelData:getPrice() 
        -- self:setButtonLabelContent("btn_buy" .. i, "ONLY $ " .. price)
        lbBtn:setString("$" .. price)

        -- 金币
        local coins = levelData:getCoins()
        local lbCoins = self:findChild("lb_coin" .. i)
        lbCoins:setString(util_formatCoins(coins, 9))
        util_alignCenter({
            {node = self:findChild("sp_coin" .. i)},
            {node = lbCoins, alignX = 5}
        })

        -- 道具
        local itemList = levelData:getItemList()
        local nodeReward = self:findChild("node_item"..i)
        local shopItemUI = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP)
        nodeReward:addChild(shopItemUI)
        util_setCascadeOpacityEnabledRescursion(nodeReward:getParent(), true)

        -- 折扣标签
        local discount = levelData:getDiscount()
        local lbDisc = self:findChild("lb_biaoqian" .. i)
        lbDisc:setString("" .. discount .. "%")
    end
end

-- 一键购买 信息
function FirstSaleMultiLayer:initBtnAllUI()
    local levelData = self.m_data:getLevelDataByList(4)
    local price = levelData:getPrice() 
    self:setButtonLabelContent("btn_buyAll", "ONLY $" .. price)
end

-- 促销倒计时
function FirstSaleMultiLayer:updateTimeLbUI()
    local expireAt = self.m_data:getSaleExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    if self.m_lbTime then
        self.m_lbTime:setString(timeStr)
    end
    if bOver then
        self:closeUI()
    end
end

-- 更新按钮状态
function FirstSaleMultiLayer:updateBtnState()
    for i=1, 4 do
        local levelData = self.m_data:getLevelDataByList(i)
        if not levelData then
            return
        end
        local bHadPay = levelData:checkHadPay()
        local visible = not bHadPay

        local btn = self:findChild("btn_buy" .. i)
        if i == 4 then
            btn = self:findChild("btn_buyAll")
            btn:setVisible(visible)
        else
            btn:setEnabled(visible)
        end
    end
end

function FirstSaleMultiLayer:clickFunc(sender)
    local name = sender:getName()
    if self.m_clicking then
        return
    end
    self.m_clicking = true

    if name == "btn_buy1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.FirstSaleMulti):goPurchase(1)
    elseif name == "btn_buy2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.FirstSaleMulti):goPurchase(2)
    elseif name == "btn_buy3" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.FirstSaleMulti):goPurchase(3)
    elseif name == "btn_buyAll" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.FirstSaleMulti):goPurchase(4)
    elseif name == "btn_close" then
        self:closeUI()
    end
end

-- 充值成功
function FirstSaleMultiLayer:onBuySuccessEvt(_levelData)
    -- 服务器会更数据不用客户端判断 结束了
    -- if _levelData and _levelData:isCloseType() then
    --     G_GetMgr(G_REF.FirstSaleMulti):setSaleOver()
    -- end

    self.m_isBuy = true
    if not G_GetMgr(G_REF.FirstSaleMulti):isRunning() then
        local cb = function()
            if tolua.isnull(self) then
                return
            end
            self:closeUI()
        end
        self:showBuyTipView(_levelData, cb)
    else
        self:updateBtnState()
        self:showBuyTipView(_levelData)
    end
    self.m_clicking = false
end

function FirstSaleMultiLayer:showBuyTipView(_levelData, _cb)
    if not _levelData then
        if _cb then
            _cb()
        end
        return
    end

    local view = util_createView("GameModule.Shop.BuyTip")
    local buyType = BUY_TYPE.FIRST_SALE_MULTI
    view:initBuyTip(buyType, _levelData, _levelData:getCoins(), nil, _cb)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 充值失败
function FirstSaleMultiLayer:onBuyFailedEvt()
    self.m_clicking = false
end

function FirstSaleMultiLayer:registerListener()
    FirstSaleMultiLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onBuySuccessEvt", FirstSaleMultiConfig.EVENT_NAME.FIRST_SALE_MULTI_PAY_SUCCESS) -- 充值成功
    gLobalNoticManager:addObserver(self, "onBuyFailedEvt", FirstSaleMultiConfig.EVENT_NAME.FIRST_SALE_MULTI_PAY_FAILD) -- 充值失败
end

function FirstSaleMultiLayer:closeUI(isLog, resultData)
    if self.isClose then
        return
    end
    self.isClose = true
    local triggerPosition = self.m_triggerPosition

    local callBack = function()
        if isLog then
            gLobalSendDataManager:getLogIap():closeIapLogInfo()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS)
        end
        -- 需要把激励视频弹窗加入到队列里
        if self.m_closePlayAds == true then
            --
            self.m_closePlayAds = false
            if not gLobalPushViewControl:isPushingView() then -- 如果之后没有弹窗了..
                if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.CloseSale) then
                    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.CloseSale)
                    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
                    gLobalAdsControl:playVideo(AdsRewardDialogType.Normal, PushViewPosType.CloseSale)
                    gLobalSendDataManager:getLogAds():createPaySessionId()
                    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.CloseSale)
                    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
                end
            else
                if self.p_params.callback then
                    self.p_params.callback()
                else
                    --弹窗逻辑执行下一个事件
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    if triggerPosition ~= "Login" then
                        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                    end
                end
            end
        else
            if self.p_params.callback then
                self.p_params.callback()
            else
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                if triggerPosition ~= "Login" then
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            end
        end

        if not self.m_isBuy then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
        end
    end

    FirstSaleMultiLayer.super.closeUI(self, callBack)
end

return FirstSaleMultiLayer