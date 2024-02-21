--[[--
    宝箱数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local RedecorTreasureData = class("RedecorTreasureData")

-- message RedecorateTreasure {
--     optional int32 order = 1;    //宝箱编号（开宝箱时传此编号）
--     optional int32 treasureId = 2;    //宝箱Id
--     optional int32 level = 3;    //宝箱等级
--     optional int32 costGems = 4;    //第二货币解锁
--     optional int64 coins = 5;    //解锁时间
--     optional int64 gems = 6;    //解锁时间
--     repeated ShopItem items = 7;    //奖励物品
--     optional int32 expire = 8;    //解锁剩余时间（秒）
--     optional int64 expireAt = 9;    //解锁时间
--   }
function RedecorTreasureData:parseData(_netData)
    self.p_order = _netData.order
    self.p_treasureId = _netData.treasureId
    self.p_level = _netData.level
    self.p_costGems = _netData.costGems
    self.p_coins = tonumber(_netData.coins)
    self.p_gems = tonumber(_netData.gems)

    self.p_items = {}
    if _netData.items and next(_netData.items) and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local sData = ShopItem:create()
            sData:parseData(_netData.items[i])
            table.insert(self.p_items, sData)
        end
    end

    self.p_expire = _netData.expire
    self.p_expireAt = tonumber(_netData.expireAt)
end

-- 宝箱编号（开宝箱时传此编号）
function RedecorTreasureData:getOrder()
    return self.p_order
end
-- 宝箱Id
function RedecorTreasureData:getTreasureId()
    return self.p_treasureId
end
-- 宝箱等级
function RedecorTreasureData:getLevel()
    return self.p_level
end
-- 第二货币解锁
function RedecorTreasureData:getCostGems()
    return self.p_costGems
end
-- 奖励金币
function RedecorTreasureData:getCoins()
    return self.p_coins
end
-- 第二货币
function RedecorTreasureData:getGems()
    return self.p_gems
end
-- 奖励物品
function RedecorTreasureData:getItems()
    return self.p_items
end
-- 解锁剩余时间（秒）
function RedecorTreasureData:getExpire()
    return self.p_expire
end
-- 解锁时间
function RedecorTreasureData:getExpireAt()
    return self.p_expireAt
end

return RedecorTreasureData
