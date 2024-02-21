--[[--
    简略礼盒
]]
local RedecorSimpleTreasureData = class("RedecorSimpleTreasureData")
-- message RedecorateSimpleTreasure {
--     optional int32 order = 1;    //宝箱编号（开宝箱时传此编号）
--     optional int32 treasureId = 2;    //宝箱Id
--     optional int32 level = 3;    //宝箱等级
--     optional int32 costGems = 4;    //第二货币解锁
--   }
function RedecorSimpleTreasureData:parseData(_netData)
    self.p_order = _netData.order
    self.p_treasureId = _netData.treasureId
    self.p_level = _netData.level
    self.p_costGems = _netData.costGems
end

-- 宝箱编号（开宝箱时传此编号）
function RedecorSimpleTreasureData:getOrder()
    return self.p_order
end
-- 宝箱Id
function RedecorSimpleTreasureData:getTreasureId()
    return self.p_treasureId
end
-- 宝箱等级
function RedecorSimpleTreasureData:getLevel()
    return self.p_level
end
-- 第二货币解锁
function RedecorSimpleTreasureData:getCostGems()
    return self.p_costGems
end

return RedecorSimpleTreasureData
