--[[--
    轮盘 单个扇面数据
]]
local RedecorSimpleTreasureData = import(".RedecorSimpleTreasureData")
local ShopItem = util_require("data.baseDatas.ShopItem")
local RedecorWheelData = class("RedecorWheelData")

-- message RedecorateWheel {
--     optional int32 cellId = 1;    //序号
--     optional string rewardType = 2; //奖励类型
--     optional int64 rewardCoins = 3;    //奖励基础金币
--     optional int64 rewardGems = 4;    //奖励钻石
--     repeated ShopItem rewardItems = 5;    //奖励物品
--     repeated RedecorateSimpleTreasure rewardTreasure = 6;    //奖励宝箱
--   }

function RedecorWheelData:parseData(_netData)
    self.p_cellId = _netData.cellId
    self.p_rewardType = _netData.rewardType
    self.p_rewardCoins = tonumber(_netData.rewardCoins)
    self.p_rewardGems = tonumber(_netData.rewardGems)

    self.p_rewardItems = {}
    if _netData.rewardItems and #_netData.rewardItems > 0 then
        for i = 1, #_netData.rewardItems do
            local rData = ShopItem:create()
            rData:parseData(_netData.rewardItems[i])
            table.insert(self.p_rewardItems, rData)
        end
    end

    self.m_rewardTreasure = {}
    if _netData.rewardTreasure and #_netData.rewardTreasure > 0 then
        for i = 1, #_netData.rewardTreasure do
            local rData = RedecorSimpleTreasureData:create()
            rData:parseData(_netData.rewardTreasure[i])
            table.insert(self.m_rewardTreasure, rData)
        end
    end
end

-- 序号
function RedecorWheelData:getCellId()
    return self.p_cellId
end
-- 奖励类型
function RedecorWheelData:getRewardType()
    return self.p_rewardType
end
-- 奖励基础金币
function RedecorWheelData:getRewardCoins()
    return self.p_rewardCoins
end
-- 奖励钻石
function RedecorWheelData:getRewardGems()
    return self.p_rewardGems
end
-- 奖励物品
function RedecorWheelData:getRewardItems()
    return self.p_rewardItems
end
-- 奖励宝箱
function RedecorWheelData:getRewardTreasure()
    return self.m_rewardTreasure
end

function RedecorWheelData:isGoldenReward()
    if self:getRewardType() == "NODE" then
        return true
    end
    return false
end

function RedecorWheelData:isEmptyReward()
    if self:getRewardType() == "EMPTY" then
        return true
    end
    return false
end

return RedecorWheelData
