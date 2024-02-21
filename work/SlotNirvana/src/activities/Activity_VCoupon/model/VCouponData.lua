--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-10 14:10:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-13 10:38:36
FilePath: /SlotNirvana/src/activities/Activity_VCoupon/model/VCouponData.lua
Description: 指定用户分组送指定档位可用优惠券 data
--]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local VCouponData = class("VCouponData", BaseActivityData)

function VCouponData:parseData(_data)
    VCouponData.super.parseData(self, _data)

    self.p_expireAt = tonumber(_data.expireAt)
    self:parseShopItemData(_data.items or {})

    self.p_open = #self.m_itemList > 0
end

function VCouponData:parseShopItemData(_list)
    self.m_itemList = {}
    for i,v in ipairs(_list) do
        local tempData = ShopItem:create()
        tempData:parseData(v)
        table.insert(self.m_itemList, tempData)
    end
end

function VCouponData:getItems()
    return self.m_itemList or {}
end

function VCouponData:isRunning()
    local bRunning = VCouponData.super.isRunning(self)
    if bRunning then
        return self:checkTicketCanUse()
    end
end

-- 是否包含 该活动 优惠劵
function VCouponData:checkTicketCanUse()
    local tickets = globalData.itemsConfig:getCommonTicketList() or {}
    for i=1, #tickets do
        local ticketInfo = tickets[i]

        if ticketInfo and string.find(ticketInfo.p_icon, "VCoupon") then
            return true
        end

    end
        
    return false
end

return VCouponData
