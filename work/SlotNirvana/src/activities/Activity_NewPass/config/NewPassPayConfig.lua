--[[
    @desc: new pass 付费配置
    author:csc
    time:2021-06-23 21:52:56
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local NewPassPayConfig = class("NewPassPayConfig")

-- optional string key = 1;//付费Key
-- optional string keyId = 2;//付费标识
-- optional string price = 3;//价格
-- repeated ShopItem rewardItems = 4;//奖励
-- optional string originPrice = 5;//原始价格
-- optional int32 discount = 6;//折扣
-- optional int64 addVipPoints = 10;//增加VIP点数
-- optional int32 upLevels = 11; // 可买等级数量
-- optional string worthDisplay = 12; // 价值预览
-- optional string coinWorthDiplay = 13; //  额外金币价值预览
-- optional int64 expPercent = 14;// 购买该档位了，经验加成百分比 triplexPass独有
-- optional string beforePrice = 15;//折扣前价格
function NewPassPayConfig:ctor()
    -- 付费Key
    self.m_key = ""
    -- 付费标识
    self.m_keyId = ""
    -- 价格
    self.m_price = 0
    -- 奖励
    self.m_rewards = {}
    -- 原始价格
    self.m_originalPrice = ""
    -- 折扣
    self.m_discount = 0
    -- 增加VIP点数
    self.m_vipPoints = 0
    -- 可购买的等级
    self.m_buyLevel = 0
    -- 价值预览
    self.m_worthDisplay = 0
    -- 金币价值预览
    self.m_coinWorthDisplay = 0

    -- 购买该档位了，经验加成百分比
    self.m_expPercent = 0

    self.m_beforePrice = ""
end

function NewPassPayConfig:parseData(data)
    if not data then
        return
    end

    -- 付费Key
    self.m_key = data.key
    -- 付费标识
    self.m_keyId = data.keyId
    -- 价格
    self.m_price = data.price
    -- 原始价格
    self.m_originalPrice = data.originPrice
    -- 折扣
    self.m_discount = data.discount
    -- 增加VIP点数
    self.m_vipPoints = tonumber(data.addVipPoints)
    -- 可购买的等级
    self.m_buyLevel = data.upLevels

    self.m_worthDisplay = data.worthDisplay

    self.m_coinWorthDisplay = data.coinWorthDiplay

    self.m_beforePrice = data.beforePrice

    if #data.rewardItems > 0 then
        for i = 1, #data.rewardItems do
            local _item = ShopItem:create()
            _item:parseData(data.rewardItems[i])
            table.insert(self.m_rewards, _item)
        end
    end
    if data.expPercent then
        self.m_expPercent = data.expPercent
    end
end

function NewPassPayConfig:getGoodsInfo()
    return {key = self.m_key,keyId = self.m_keyId, price = self.m_price , discount = self.m_discount, vipPoints = self.m_vipPoints}
end

function NewPassPayConfig:getBuyLevel()
    return self.m_buyLevel
end

function NewPassPayConfig:getOriginalPrice()
    return self.m_originalPrice
end

function NewPassPayConfig:getRewards()
    return self.m_rewards
end

function NewPassPayConfig:getWorthDisPlay()
    return self.m_worthDisplay or ""
end

function NewPassPayConfig:getCoinWorthDisPlay()
    return self.m_coinWorthDisplay or ""
end

-- 购买该档位了，经验加成百分比
function NewPassPayConfig:getExpPercent()
    return self.m_expPercent or 0
end

function NewPassPayConfig:getBeforePrice()
    return self.m_beforePrice or ""
end

return NewPassPayConfig
