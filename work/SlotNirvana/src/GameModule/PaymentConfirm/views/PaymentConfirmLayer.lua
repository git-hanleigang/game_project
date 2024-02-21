--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-10 15:53:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-10 15:54:25
FilePath: /SlotNirvana/src/GameModule/PaymentConfirm/views/PaymentConfirmLayer.lua
Description: 支付 二次确认弹板
--]]
local PaymentConfirmLayer = class("PaymentConfirmLayer", BaseLayer)

function PaymentConfirmLayer:ctor()
    PaymentConfirmLayer.super.ctor(self)

    self:setKeyBackEnabled(true)
    self:setPauseSlotsEnabled (true)
    self:setExtendData("PaymentConfirmLayer")
    self:setLandscapeCsbName("PaymentConfirm/csd/PaymentConfirmationLayer.csb")
    self:setPortraitCsbName("PaymentConfirm/csd/PaymentConfirmationLayer_shu.csb")
end

function PaymentConfirmLayer:initDatas(_params)
    PaymentConfirmLayer.super.initDatas(self)

    self.m_coins = _params.coins or 0
    self.m_price = _params.price or 0
    self.m_actRefName = _params.actRefName or ""
    self.m_expireAt = _params.expireAt

    self.m_confirmCB = _params.confirmCB
    self.m_cancelCB = _params.cancelCB
end

function PaymentConfirmLayer:initView()
    PaymentConfirmLayer.super.initView(self)
    
    -- 金币
    self:initCoinsUI()
    -- 价格描述
    self:initPriceUI()
    -- 弹板到期时间
    self:checkExpireAt()
end

-- 金币
function PaymentConfirmLayer:initCoinsUI()
    local lbCoins = self:findChild("lb_coins")
    lbCoins:setString(util_getFromatMoneyStr(self.m_coins))

    local alignUIList = {
        {node = self:findChild("sp_coins_icon")},
        {node = lbCoins, alignX = 5}
    }
    util_alignCenter(alignUIList, 0, 1000)
end

-- 价格描述
function PaymentConfirmLayer:initPriceUI()
    local lbPrice = self:findChild("lb_price_desc")
    local formatStr = lbPrice:getString()
    lbPrice:setString(string.format(formatStr, self.m_price))
end

-- 弹板到期时间
function PaymentConfirmLayer:checkExpireAt()
    if not self.m_expireAt then
        return
    end

    self.m_scheduler = schedule(self, function()
        local tiemStr, bOver = util_daysdemaining(self.m_expireAt)
        if bOver then
            self:closeUI()
        end
    end, 1)
end

-- 点击确认 添加蒙版
function PaymentConfirmLayer:addPayMask()
    local blockMask = util_newMaskLayer()
    blockMask:setOpacity(0)
    self:addChild(blockMask, 9999)
    performWithDelay(self, function()
        self:removeMaskUI()
    end, 30)
    self.m_blockMask = blockMask
end
-- 移除蒙版
function PaymentConfirmLayer:removeMaskUI()
    if not self.m_blockMask or tolua.isnull(self.m_blockMask) then
        return
    end

    self.m_blockMask:removeSelf()
    self.m_blockMask = nil
end

function PaymentConfirmLayer:clickFunc(sender)
    local senderName = sender:getName()

    if senderName == "btn_playnow" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_confirmCB then
            self.m_confirmCB()
        end
        self:addPayMask()
    elseif senderName == "btn_close" then
        self:closeUI(self.m_cancelCB)
    end
end

function PaymentConfirmLayer:closeUI(_cb)
    if self.m_bCloseing then
        return
    end
    self.m_bCloseing = true
    -- 隐藏粒子
    self:hidePartiicles()
    self:clearScheduler()
    PaymentConfirmLayer.super.closeUI(self, _cb)
end

-- 清楚定时器
function PaymentConfirmLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function PaymentConfirmLayer:registerListener()
    PaymentConfirmLayer.super.registerListener(self)

    if not self.m_actRefName or self.m_actRefName == "" then
        return
    end

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == self.m_actRefName then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return PaymentConfirmLayer