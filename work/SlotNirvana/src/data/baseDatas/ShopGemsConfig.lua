--
--
local ShopCoinsConfig = require "data.baseDatas.ShopCoinsConfig"
local ShopGemsConfig = class("ShopGemsConfig", ShopCoinsConfig)

function ShopGemsConfig:parseData(data)
    ShopGemsConfig.super.parseData(self, data)
    self.m_buyType = BUY_TYPE.GEM_TYPE
    self.p_originalCoins = nil
    self.p_coins = nil
    self.p_originalGems = tonumber(data.originalGems or 0)
    self.p_gems = tonumber(data.gems or 0)
    if data.clanDiscount then
        self.p_clanDiscount = tonumber(data.clanDiscount) or 0
    end
    if data.storeGiftDiscount then
        self.p_storeGiftDiscount = tonumber(data.storeGiftDiscount) or 0
    end
end

-- 集卡神像章节提供的buff加成
function ShopGemsConfig:getStatueBuffDiscount()
    local statueBuffDis = 0
    if CardSysManager and CardSysManager.getBuffDataByType then
        statueBuffDis = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_GEMSHOP_GEM_BONUS)
    end
    return statueBuffDis
end

-- 获得加成
function ShopGemsConfig:getDiscount()
    local value = 0

    value = value + self:getBaseDiscount()
    value = value + self:getCouponDiscount()
    -- value = value + self:getArenaDiscount()
    value = value + self:getClanDiscount()
    value = value + self:getStoreGiftDiscount()

    local statueBuffDis = self:getStatueBuffDiscount()
    if statueBuffDis > 0 then
        statueBuffDis = (statueBuffDis - 1) * 100
        value = value + math.max(statueBuffDis or 0, 0)
    end

    return value
end

-- 公会段位 折扣优惠
function ShopGemsConfig:getClanDiscount()
    return self.p_clanDiscount or 0
end

-- 折扣送道具
function ShopGemsConfig:getStoreGiftDiscount()
   return self.p_storeGiftDiscount 
end

return ShopGemsConfig
