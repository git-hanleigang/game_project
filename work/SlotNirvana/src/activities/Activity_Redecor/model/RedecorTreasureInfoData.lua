--[[--
    宝箱数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local RedecorTreasureInfoData = class("RedecorTreasureInfoData")

-- message RedecorateTreasureInfo {
--     optional int32 level = 1;    //宝箱等级
--     optional int32 time = 2;    //锁定时间（分钟）
--   }
function RedecorTreasureInfoData:parseData(_netData)
    self.p_level = _netData.level
    self.p_time = _netData.time
end

-- 宝箱编号（开宝箱时传此编号）
function RedecorTreasureInfoData:getLevel()
    return self.p_level
end
-- 宝箱Id
function RedecorTreasureInfoData:getTime()
    return self.p_time
end

return RedecorTreasureInfoData
