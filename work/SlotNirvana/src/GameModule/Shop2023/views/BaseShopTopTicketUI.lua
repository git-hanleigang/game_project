--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-09 18:00:20
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-08 18:48:27
FilePath: /SlotNirvana/src/GameModule/Shop2023/views/BaseShopTopTicketUI.lua
Description: 商城优惠卷  全档位的
--]]
local BaseShopTopTicketUI = class("BaseShopTopTicketUI", BaseView)

function BaseShopTopTicketUI:getCsbName()
    if self._type == SHOP_VIEW_TYPE.COIN then
        return self._bPortrait and SHOP_RES_PATH.CoinsTicketNode_p or SHOP_RES_PATH.CoinsTicketNode
    end
    return self._bPortrait and SHOP_RES_PATH.GemsTicketNode_p or SHOP_RES_PATH.GemsTicketNode
end

-- 初始化节点
function BaseShopTopTicketUI:initCsbNodes()
    self.m_spBg = self:findChild("sp_coupon")
    self.m_lbTime = self:findChild("lb_time")
    self.m_lbCoupon = self:findChild("lb_coupon")
end

function BaseShopTopTicketUI:initDatas(_type, _bPortrait)
    BaseShopTopTicketUI.super.initDatas(self)

    self._type = _type
    self._bPortrait = _bPortrait
    self.m_bVisible = false
end

function BaseShopTopTicketUI:initUI(_type, _bPortrait)
    BaseShopTopTicketUI.super.initUI(self)

    self:updateTicketInfo(_type)
    -- 优惠 劵倒计时
    self:onUpdateSec()
end

-- 更新 优惠卷信息
function BaseShopTopTicketUI:updateTicketInfo(_type)
    local coinData, gemData, hotSaleData = globalData.shopRunData:getShopItemDatas()
    local ticketDisc = 0
    if _type == SHOP_VIEW_TYPE.COIN and coinData and #coinData > 0 then
        ticketDisc = self:getTicketDisc(coinData) 
    elseif _type == SHOP_VIEW_TYPE.GEMS and gemData and #gemData > 0 then
        ticketDisc = self:getTicketDisc(gemData)
    end
    
    self.m_lbCoupon:setString("" .. ticketDisc .. "%")
    self.m_bVisible = ticketDisc > 0 and not self.m_bOver
    self:setVisible(self.m_bVisible)
end

function BaseShopTopTicketUI:onUpdateSec()
    local expireAtCoins,expireAtGems = globalData.shopRunData:getShopTicketExpireTime()
    local expireAt = self._type == SHOP_VIEW_TYPE.COIN and expireAtCoins or expireAtGems
    -- local leftTime = util_getLeftTime(expireAt)
    -- local showStr = ""
    -- if leftTime > 86400 then
    --     -- day
    --     showStr = math.floor(leftTime / 86400)  .. "day"
    -- elseif leftTime > 3600 then
    --     -- hour
    --     showStr = math.floor(leftTime / 3600)  .. "hour"
    -- elseif leftTime > 60 then
    --     -- min
    --     showStr = math.floor(leftTime / 60)  .. "min"
    -- elseif leftTime > 0 then
    --     -- sec
    --     showStr = math.floor(leftTime)  .. "s"
    -- else
    --     -- over
    --     self.m_bOver = true
    --     self.m_bVisible = false
    --     self:setVisible(false)
    -- end
    local showStr, bOver = util_daysdemaining(expireAt* 0.001, true)
    if bOver then
        self.m_bOver = true
        self.m_bVisible = false
        self:setVisible(false)
    end
    self.m_lbTime:setString(showStr)
end

function BaseShopTopTicketUI:getSpBgSize()
    return self.m_spBg:getContentSize()
end

function BaseShopTopTicketUI:isTicketEnabled()
    return self.m_bVisible
end

-- 获取显示的优惠 折扣 （不是所有档位都有优惠卷）
function BaseShopTopTicketUI:getTicketDisc(_list)
    local count = 0
    for i, data in ipairs(_list) do
        count = data:getTicketDiscount()
        if count > 0 then
            return count
        end
    end
    return count
end

return BaseShopTopTicketUI