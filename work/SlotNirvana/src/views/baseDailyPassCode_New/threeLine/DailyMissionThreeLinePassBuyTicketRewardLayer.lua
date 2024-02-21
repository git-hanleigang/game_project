--[[
    --新版每日任务pass主界面 二次提示用户解锁 获取奖励界面
    csc 2022-01-25 
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionThreeLinePassBuyTicketRewardLayer = class("DailyMissionThreeLinePassBuyTicketRewardLayer", BaseLayer)

function DailyMissionThreeLinePassBuyTicketRewardLayer:initCsbNodes()
    -- left
    self.m_labNewPriceLeft = self:findChild("lb_newPrice_Left")

    self.m_nodeReward = self:findChild("node_rewarditem")
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:initDatas()
    DailyMissionThreeLinePassBuyTicketRewardLayer.super.initDatas(self)

    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYPASS_RES_PATH.DailyMissionPass_BuyTicketRewardLayer_ThreeLine)
    self:setPortraitCsbName(DAILYPASS_RES_PATH.DailyMissionPass_BuyTicketRewardLayer_Vertical_ThreeLine)

    self:setPauseSlotsEnabled(true)
end

-- 重写父类方法
function DailyMissionThreeLinePassBuyTicketRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:initView()
    self.m_goodInfo = G_GetMgr(ACTIVITY_REF.NewPassBuy):getPayPassTicketInfo()
    if not self.m_goodInfo then
        return
    end
    local showData = nil
    self:findChild("sp_desc1"):setVisible(false)
    self:findChild("sp_desc2"):setVisible(false)
    self:findChild("sp_desc3"):setVisible(false)

    local tagNode = self:findChild("node_tag")

    if G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():isUnlocked() then
        showData = self.m_goodInfo[2]
        self.m_CheckIndex = 2
        self:findChild("sp_desc3"):setVisible(true)

        -- 折扣
        local beforePrice = showData:getBeforePrice()
        if beforePrice ~= "" and tagNode then
            local goodsInfo = showData:getGoodsInfo()
            local discount = math.floor((1 - tonumber(goodsInfo.price) / tonumber(beforePrice)) * 100)
            local tag = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTag, discount)
            tagNode:addChild(tag)
            tag:playIdle2()
        end
    else
        if G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getCurrIsPayHigh() then
            showData = self.m_goodInfo[1]
            self.m_CheckIndex = 1
            self:findChild("sp_desc2"):setVisible(true)            

            -- 折扣
            local beforePrice = showData:getBeforePrice()
            if beforePrice ~= "" and tagNode then
                local goodsInfo = showData:getGoodsInfo()
                local discount = math.floor((1 - tonumber(goodsInfo.price) / tonumber(beforePrice)) * 100)
                local tag = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTag, discount)
                tagNode:addChild(tag)
                tag:playIdle2()
            end
        else
            showData = self.m_goodInfo[3]
            self.m_CheckIndex = 3
            self:findChild("sp_desc1"):setVisible(true)

            -- 折扣
            local beforePrice = showData:getBeforePrice()
            if beforePrice ~= "" and tagNode then
                local goodsInfo = showData:getGoodsInfo()
                local goodInfo1 = self.m_goodInfo[1]
                local goodInfo2 = self.m_goodInfo[2]
                local beforePrice1 = goodInfo1:getBeforePrice()
                local beforePrice2 = goodInfo2:getBeforePrice()
                local smallPrice = beforePrice1 + beforePrice2
                local discount = math.floor(((1 - (tonumber(goodsInfo.price) / smallPrice))) * 100)
                local tag = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTag, discount)
                tagNode:addChild(tag)
                tag:playIdle2()
            end
        end
    end
    if showData then
        local goodsInfo = showData:getGoodsInfo()
        self.m_labNewPriceLeft:setString("$" .. goodsInfo.price)
    else
        self:findChild("btn_buy1"):setTouchEnabled(false)
    end

    -- 初始化奖励列表
    self:initRewardList()
    
    self:updateBtnBuck()
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:updateBtnBuck()
    local buyType = BUY_TYPE.TRIPLEXPASS_PASSTICKET  
    self:setBtnBuckVisible(self:findChild("btn_buy1"), buyType, nil, {{node = self:findChild("node_newPrice_left"), addX = 20}})
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:initRewardList()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end

    local itemList = {}
    -- 创建同pass奖励额界面相同的 paycell
    local popDisPlayList = actData:getPopUpDisplay()
    for i = 1, #popDisPlayList do
        local payInfo = popDisPlayList[i]
        local payCell = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassRewardCell_ThreeLine, {type = "season", lock = false, onlyShow = true})
        payCell:updateData(payInfo)
        itemList[#itemList + 1] = gLobalItemManager:createOtherItemData(payCell, 1)
    end

    popDisPlayList = actData:getPopUpTriplexDisplay()
    for i = 1, #popDisPlayList do
        local payInfo = popDisPlayList[i]
        local payCell = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PassRewardCell_ThreeLine, {type = "premium", lock = false, onlyShow = true})
        payCell:updateData(payInfo)
        itemList[#itemList + 1] = gLobalItemManager:createOtherItemData(payCell, 1)
    end

    -- --创建通用道具布局
    local size = cc.size(1100, 330)
    local maxConut = 7
    local scale = 0.83
    if globalData.slotRunData.isPortrait then
        size = cc.size(730, 330)
        maxConut = 5
        scale = 0.83
    end
    local listView = gLobalItemManager:createRewardListView(itemList, size, maxConut, {width = 180, height = 180}, scale)
    self.m_nodeReward:addChild(listView)
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_buy1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods()
    end
end

-- 购买等级
function DailyMissionThreeLinePassBuyTicketRewardLayer:buyGoods()
    if not self.m_goodInfo then
        return
    end
    if self.m_purchasing then
        return
    end
    self.m_purchasing = true
    local _index = self.m_CheckIndex

    local goodsInfo = self.m_goodInfo[_index]:getGoodsInfo()
    G_GetMgr(ACTIVITY_REF.NewPass):checkDoUnlockGuide()

    self:sendIapLog(goodsInfo, _index)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.TRIPLEXPASS_PASSTICKET,
        goodsInfo.key,
        goodsInfo.price,
        0,
        0,
        function()
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess()
                self:sendNewPassLog(2, _index)
            else
            end
        end,
        function()
            self.m_purchasing = false
            if self.buyFailed ~= nil then
                self:buyFailed()
            else
            end
        end
    )
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:buySuccess()
    local closeFunc = function()
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_BUY_PASSTICKET, {success = true})
            end
        )
    end
    gLobalViewManager:checkBuyTipList(closeFunc)
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:buyFailed()
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:sendNewPassLog(type, _index)
    if gLobalSendDataManager.getLogNewPass then
        if type == 1 then
            gLobalSendDataManager:getLogNewPass():sendPassLog("Open", nil)
        elseif type == 2 then
            local payType = "Normal"
            if _index == 2 then
                payType = "Adv"
            end
            gLobalSendDataManager:getLogNewPass():sendPassLog("Pay", payType)
        end
    end
end
-- 客户端打点
function DailyMissionThreeLinePassBuyTicketRewardLayer:sendIapLog(_goodsInfo, _index)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "GloryPassTicket"
        goodsInfo.goodsId = _goodsInfo.key
        goodsInfo.goodsPrice = _goodsInfo.price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = "GloryPassTicket"
        if _index == 2 then
            purchaseInfo.purchaseName = "GloryPassAdvance"
        end
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if not actData then
            return
        end
        purchaseInfo.purchaseStatus = actData:getLevel()

        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:onEnter()
    DailyMissionThreeLinePassBuyTicketRewardLayer.super.onEnter(self)
    self:sendNewPassLog(1, nil)
    -- 促销到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_DAILY_TASK_UI_CLOSE
    )
end

function DailyMissionThreeLinePassBuyTicketRewardLayer:closeUI(...)
    if self:isShowing() or self:isHiding() then
        return
    end
    DailyMissionThreeLinePassBuyTicketRewardLayer.super.closeUI(self, ...)
end

return DailyMissionThreeLinePassBuyTicketRewardLayer
