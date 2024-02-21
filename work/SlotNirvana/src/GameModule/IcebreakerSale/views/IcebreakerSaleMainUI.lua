--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-27 16:16:14
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-27 16:51:49
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/views/IcebreakerSaleMainUI.lua
Description: 新版 破冰促销 mainUI
--]]
local IcebreakerSaleMainUI = class("IcebreakerSaleMainUI", BaseLayer)
local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")

function IcebreakerSaleMainUI:initDatas()
    IcebreakerSaleMainUI.super.initDatas(self)

    self.m_data = G_GetMgr(G_REF.IcebreakerSale):getData()
    self.m_rewardList = self.m_data:getRewardList()
    self:setKeyBackEnabled(true)
    self:setPauseSlotsEnabled (true)
    self:setName("IcebreakerSaleMainUI")
    self:setLandscapeCsbName("Activity/csd/IcebreakerSale_MainLayer.csb")
    self:setPortraitCsbName("Activity/csd/IcebreakerSale_MainLayer_Portrait.csb")
end

function IcebreakerSaleMainUI:initCsbNodes()
    self.m_btnBuy = self:findChild("btn_buy")
    self.m_btnClose = self:findChild("btn_close")
end

function IcebreakerSaleMainUI:initView()
    -- 按钮 转态
    self:updateBtnState()
    self:updateBtnLbUI()

    -- 三天道具
    self:initItemUI()
    -- 三天时间
    self:initTimeUnlockUI()
    -- 3天道具领取状态
    self:updateDayColState()
    -- 折扣
    self:initDiscountUI()

    self:runCsbAction("idle", true)
end

-- 折扣
function IcebreakerSaleMainUI:initDiscountUI()
    local bPay = self.m_data:checkHadPay()

    local nodeDiscount = self:findChild("node_label_buy")
    local lbDiscount = self:findChild("lb_label_buy")
    local discount = self.m_data:getDiscount()
    lbDiscount:setString(string.format("-%s%%", discount))
    util_scaleCoinLabGameLayerFromBgWidth(lbDiscount, 80, 1)
    nodeDiscount:setVisible(not bPay)

    local btnPb = self:findChild("btn_pb")
    btnPb:setVisible(not bPay)
end

-- 按钮 价格
function IcebreakerSaleMainUI:updateBtnLbUI()
    local bPay = self.m_data:checkHadPay()
    local str = ""
    if bPay then
        local LanguageKey = "IcebreakerSaleMainUI:btn_buy_col"
        local labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "COLLECT"
        str = labelString
    else
        local LanguageKey = "IcebreakerSaleMainUI:btn_buy"
        local labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "ONLY $ "
        local price = self.m_data:getPrice()
        str = labelString .. price
    end
    self:setButtonLabelContent("btn_buy", str)
end

function IcebreakerSaleMainUI:updateBtnState()
    local bPay = self.m_data:checkHadPay()
    local bEnabled = not bPay
    if bPay then
        local list = self.m_data:checkCanCollectList()
        bEnabled = #list > 0
    end
    
    self:setButtonLabelDisEnabled("btn_buy", bEnabled) 
end

-- 三天道具
function IcebreakerSaleMainUI:initItemUI()
    self.m_rewardUIList = {}
    for i = 1, 3 do
        local node = self:findChild("node_reward_"..i)
        local rewardData = self.m_rewardList[i]
        local view = util_createView("GameModule.IcebreakerSale.views.IcebreakerSaleRewardUI", rewardData)
        node:addChild(view)
        self.m_rewardUIList[i] = view
    end
end

-- 三天时间
function IcebreakerSaleMainUI:initTimeUnlockUI()
    self.m_timeViewList = {}
    for i = 1, 3 do
        local node = self:findChild("node_time_"..i)
        local view = util_createView("GameModule.IcebreakerSale.views.IcebreakerSaleTimeUI")
        node:addChild(view)
        self.m_timeViewList[i] = view
    end

    self.m_scheduler = schedule(self, handler(self, self.updateTimeUnlockUI), 1)
    self:updateTimeUnlockUI()
end
function IcebreakerSaleMainUI:updateTimeUnlockUI()
    for i=1, #self.m_timeViewList do
        local rewardData = self.m_rewardList[i]
        local view = self.m_timeViewList[i]
        local bVisible = view:isVisible()
        local colAt = rewardData:getColTimeAt()
        view:updateTimeUI(colAt)
        local bUpdateVisible = view:isVisible()
        if bVisible and not bUpdateVisible then
            self:updateBtnState()
        end
    end
end

-- 3天道具领取状态
function IcebreakerSaleMainUI:updateDayColState()
    for i = 1, 3 do
        local node = self:findChild("sp_duihao"..i)
        local rewardData = self.m_rewardList[i]
        node:setVisible(rewardData:checkHadCollected())
    end
end

function IcebreakerSaleMainUI:clickFunc(sender)
    local senderName = sender:getName()

    if senderName == "btn_buy" and not self.m_clicking then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local bPay = self.m_data:checkHadPay()
        if bPay then
            self:setButtonLabelDisEnabled("btn_buy", false)
            G_GetMgr(G_REF.IcebreakerSale):sendCollectReq()
        else
            G_GetMgr(G_REF.IcebreakerSale):goPurchase()
        end
        self.m_clicking = true
    elseif senderName == "btn_pb" then
        local price = self.m_data:getPrice()
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer({p_price = price})
    elseif senderName == "btn_close" then
        self:closeUI()
    end
end

function IcebreakerSaleMainUI:closeUI(_cb)
    if self.bClose then
        return
    end
    self.bClose = true

    local cb = function()
        if _cb then
            _cb()
        end
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    end

    IcebreakerSaleMainUI.super.closeUI(self, cb)
end

-- 充值成功
function IcebreakerSaleMainUI:onBuySuccessEvt()
    self.m_rewardList = self.m_data:getRewardList()

    self:updateBtnState()
    self:updateBtnLbUI()
    local nodeDiscount = self:findChild("node_label_buy")
    nodeDiscount:setVisible(false)
    local btnPb = self:findChild("btn_pb")
    btnPb:setVisible(false)

    self:setButtonLabelDisEnabled("btn_buy", false)
    G_GetMgr(G_REF.IcebreakerSale):sendCollectReq()
    self.m_clicking = true
end
-- 充值失败
function IcebreakerSaleMainUI:onBuyFailedEvt()
    self.m_clicking = false
end
--领取成功
function IcebreakerSaleMainUI:onCollectSuccessEvt()
    self.m_rewardList = self.m_data:getRewardList()
    self:updateBtnState()
    self:updateTimeUnlockUI()
    self:updateDayColState()
    self.m_clicking = false
end
--领取失败
function IcebreakerSaleMainUI:onCollectFailedEvt()
    self:updateBtnState()
    self.m_clicking = false
end

function IcebreakerSaleMainUI:registerListener()
    IcebreakerSaleMainUI.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onBuySuccessEvt", IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_SALE_BUY_SUCCESS) -- 充值成功
    gLobalNoticManager:addObserver(self, "onBuyFailedEvt", IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_SALE_BUY_FAILED) -- 充值失败
    gLobalNoticManager:addObserver(self, "onCollectSuccessEvt", IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_COLLECT_SUCCESS) --领取成功
    gLobalNoticManager:addObserver(self, "onCollectFailedEvt", IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_COLLECT_FAILED) --领取失败
    gLobalNoticManager:addObserver(self, "closeUI", IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_OVER) --功能结束
end

return IcebreakerSaleMainUI