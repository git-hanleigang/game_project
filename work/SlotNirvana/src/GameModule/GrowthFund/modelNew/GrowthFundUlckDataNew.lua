--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-24 14:41:22
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-24 16:46:26
FilePath: /SlotNirvana/src/GameModule/GrowthFund/modelNew/GrowthFundUlckDataNew.lua
Description: 成长基金数据 新版 付费数据
--]]
local GrowthFundUlckDataNew = class("GrowthFundUlckDataNew")

function GrowthFundUlckDataNew:ctor()
    self.m_bPay = false -- 是否付费
    self.m_key = "" -- 支付相关
    self.m_keyId = "" -- 支付相关
    self.m_price = "" -- 支付相关
    self.m_discount = 0 -- 显示折扣
end

function GrowthFundUlckDataNew:parseData(_data, _idx)
    if not _data then
        return
    end

    self.m_idx = _idx or 1 -- 阶段idx
    self.m_bPay = _data.pay -- 是否付费
    self.m_key = _data.key or "" -- 支付相关
    self.m_keyId = _data.keyId or "" -- 支付相关
    self.m_price = _data.price or "" -- 支付相关
    self.m_discount = _data.discount or 0 -- 显示折扣
end

function GrowthFundUlckDataNew:getIdx()
    return self.m_idx
end
--是否付费
function GrowthFundUlckDataNew:isPay()
    return self.m_bPay
end
--付费点keyId
function GrowthFundUlckDataNew:getKeyId()
    return self.m_keyId
end
--付费点key
function GrowthFundUlckDataNew:getKey()
    return self.m_key 
end
-- 价格
function GrowthFundUlckDataNew:getPrice()
    return self.m_price
end
-- 折扣
function GrowthFundUlckDataNew:getDiscount()
    return self.m_discount
end

return GrowthFundUlckDataNew