--[[
    author:JohnnyFred
    time:2019-10-08 19:36:07
]]

local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseGameModel = require("GameBase.BaseGameModel")
local FirstSaleData = class("FirstSaleData", SaleItemConfig, BaseGameModel)

function FirstSaleData:parseData(data, _isNoCoins)
    self.p_items = {}
    FirstSaleData.super.parseData(self, data)
    -- 新首充
    self.p_bagType = data.bagType  -- 首充V3 礼包类型
    self.p_onSale = data.onSale   -- 首充V3 档位状态（是否开启）
    self.p_group = data.group    -- 首充V3 用户分组0旧版收购，1新版首购
    self.p_lastBag = data.lastBag  -- 首充V3 是否是最后一个礼包
    self.p_bagId = data.bagId    -- 首充V3 礼包Id
    self.m_isNoCoins = _isNoCoins

    if data.v3BuyCount then
        self.m_bFirstPay = data.v3BuyCount == 0 -- 首充V3 购买次数 老用户购买过为1，以后累计
    else
        self.m_bFirstPay = self.p_bagType ~= 2
    end
end

function FirstSaleData:getBagType()
    return self.p_bagType
end

function FirstSaleData:isOnSale()
    return self.p_onSale
end

function FirstSaleData:getGroup()
    return self.p_group
end

function FirstSaleData:isLastBag()
    return self.p_lastBag
end

function FirstSaleData:getBagId()
    return self.p_bagId
end

function FirstSaleData:setOnSale(_flag)
    self.p_onSale = _flag
end

function FirstSaleData:setIsNoCoins(_flag)
    self.m_isNoCoins = _flag
end

function FirstSaleData:isNoCoins()
    return self.m_isNoCoins
end

function FirstSaleData:isCanShow()
    if self:getGroup() == 0 and (self:isRunning() or self:isNoCoins())then 
        return true
    elseif self:getGroup() == 1 and self:isRunning() and (self:isOnSale() or self:isNoCoins()) then
        return true
    end

    return false
end

function FirstSaleData:getRequestFirstSaleTpye()
    if self:getGroup() == 1 then 
        if not self:isOnSale() or (self:getLeftTime() <= 0 and not self:isLastBag())  then 
            return 1
        end
    end

    return -1
end

function FirstSaleData:getThemeName()
    return G_REF.FirstCommonSale
end

function FirstSaleData:checkIsFirstSaleType()
    return self.m_bFirstPay
end

return FirstSaleData
