-- 促销数据
local BaseActivityData = require "baseActivity.BaseActivityData"
local OutsideCaveSaleData = class("OutsideCaveSaleData",BaseActivityData)
-- 常规促销数据
local SaleItemConfig = require "data.baseDatas.SaleItemConfig"
-- 特殊促销数据
local SpecialSaleData = util_require("activities.Activity_OutsideCave.model.OSpecialSaleData")

function OutsideCaveSaleData:ctor()
    self.p_saleItem = nil
    self.p_seleSpecial = nil
end

-- message OutsideCaveSaleConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional SaleItemConfig sale = 4; //常规促销
--     optional OutsideCaveSpecialSale specialSale = 5; //特殊促销
-- }

function OutsideCaveSaleData:parseData(datas)
    if datas then
        OutsideCaveSaleData.super.parseData(self, datas)
        -- self.p_activityId = datas.activityId
        -- self.p_expireAt = datas.expireAt
        -- self.p_expire = datas.expire
        if nil == self.p_saleItem then
            self.p_saleItem = SaleItemConfig:create()
        end
        local config = globalData.GameConfig:getActivityConfigById(datas.activityId)
        if datas.sale and config then
            self.p_saleItem:parseConfigData(config)
            self.p_saleItem:parseData(datas.sale)
            self.p_saleItem:setNovice(false)
        end

        if datas.specialSale then -- 特殊促销
            if nil == self.p_specialSale then
                self.p_specialSale = SpecialSaleData:create()
            end
            self.p_specialSale:parseData(datas.specialSale)
            
        end

    end
end

function OutsideCaveSaleData:getSaleItem()
    return self.p_saleItem
end

function OutsideCaveSaleData:getSpecialSale()
    return self.p_specialSale
end

return OutsideCaveSaleData