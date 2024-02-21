--[[
    DiyFeature 结束促销
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiyFeaturePromotionData = class("DiyFeaturePromotionData", BaseActivityData)
local DiyFeatureData = require("activities.Activity_DiyFeature.model.DiyFeatureData")
local ShopItem = require("data.baseDatas.ShopItem")

--[[
    message DiyFeatureOverSale {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional DiyFeature diyFeature = 4; //diyFeature数据
        optional DiyFeatureSale normalPrice = 5; //低级促销价格
        optional DiyFeatureSale highPrice = 6; //高级促销价格
        optional bool normal = 7; //低级促销开启标识
        optional bool high = 8; //高级促销开启标识
        optional DiyFeatureOverSaleSeniorParam normalSeniorParam = 11; //低级高档促销升级参数
        optional DiyFeatureOverSaleSeniorParam highSeniorParam = 12; //高级高档促销升级参数
    }
    message DiyFeatureOverSaleSeniorParam {
        optional int32 freeGame = 1; // 提升后的freeGame次数
        repeated DiyFeatureBuff buff = 2; // 提升后的buff等级
    }
]]
function DiyFeaturePromotionData:parseData(_data)
    DiyFeaturePromotionData.super.parseData(self, _data)

    if self.p_diyFeature then
        self.p_diyFeature:parseData(_data.diyFeature)
    else
        self.p_diyFeature = DiyFeatureData:create()
        self.p_diyFeature:parseData(_data.diyFeature)
    end
    -- 低级低档促销价格
    self.p_normalPrice = self:parseSale(_data.normalPrice)
    -- 高级低档促销价格
    self.p_highPrice = self:parseSale(_data.highPrice)
    
    --低级促销开启标识
    self.p_normal = _data.normal
    --高级促销开启标识
    self.p_high = _data.high

    -- 低级高档促销价格
    self.p_normalSeniorPrice = self:parseSale(_data.normalSenior)
    -- 高级高档促销价格
    self.p_highSeniorPrice = self:parseSale(_data.highSenior)

    self.m_nomalFreeGame = _data.normalSeniorParam.freeGame
    self.m_nomalLvUpBuff = {}
    if _data.normalSeniorParam.buff and #_data.normalSeniorParam.buff > 0 then
        for index, oneBuff in ipairs(_data.normalSeniorParam.buff) do
            if self.p_diyFeature.p_normalBuffs[oneBuff.buffType].p_level < oneBuff.level then
                table.insert(self.m_nomalLvUpBuff,oneBuff)
            end
        end
    end

    self.m_highFreeGame = _data.highSeniorParam.freeGame
    self.m_highLvUpBuff = {}
    if _data.highSeniorParam.buff and #_data.highSeniorParam.buff > 0 then
        for index, oneBuff in ipairs(_data.highSeniorParam.buff) do
            if self.p_diyFeature.p_highBuffs[oneBuff.buffType].p_level < oneBuff.level then
                table.insert(self.m_highLvUpBuff,oneBuff)
            end
        end
    end
end


-- dif_type 1 普通  2 高级
function DiyFeaturePromotionData:getSaleRewardInfo(dif_type)
    if dif_type == 1 then
        return self.m_nomalFreeGame , self.m_nomalLvUpBuff 
    else
        return self.m_highFreeGame , self.m_highLvUpBuff
    end
end


-- message DiyFeatureSale {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--     optional string coins = 4;
--     repeated ShopItem item = 5;
--     optional int64 buffExpireAt = 6; //buff过期时间
-- }
function DiyFeaturePromotionData:parseSale(_data)
    local saleData = {}
    saleData.p_key = _data.key
    saleData.p_keyId = _data.keyId
    saleData.p_price = _data.price
    saleData.p_coins = toLongNumber(0)
    saleData.p_coins:setNum(_data.coins)
    saleData.p_times = self:parseItems(_data.item)
    return saleData
end

function DiyFeaturePromotionData:parseItems(_items)
    -- 通用道具
    local itemsData = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function DiyFeaturePromotionData:isRunning()
    if self.p_normal or self.p_high then
        return DiyFeaturePromotionData.super.isRunning(self)
    end
    return false
end

function DiyFeaturePromotionData:getNormalSaleData()
    return self.p_normalPrice
end

function DiyFeaturePromotionData:getNormalSeniorSaleData()
    return self.p_normalSeniorPrice
end

function DiyFeaturePromotionData:getHighSaleData()
    return self.p_highPrice
end

function DiyFeaturePromotionData:getHighSeniorSaleData()
    return self.p_highSeniorPrice
end

function DiyFeaturePromotionData:getDiyFeatureData()
    return self.p_diyFeature
end

function DiyFeaturePromotionData:getNormoal()
    return self.p_normal
end

function DiyFeaturePromotionData:getHigh()
    return self.p_high
end

-- _type 1:普通 2:高级
-- _position 1:低档 2:高档
function DiyFeaturePromotionData:getSaleDataByType(_type, _position)
    if _type == 1 then
        if _position == 1 then
            return self:getNormalSaleData()
        else
            return self:getNormalSeniorSaleData()
        end
    elseif _type == 2 then
        if _position == 1 then
            return self:getHighSaleData()
        else
            return self:getHighSeniorSaleData()
        end
    end
end

return DiyFeaturePromotionData
