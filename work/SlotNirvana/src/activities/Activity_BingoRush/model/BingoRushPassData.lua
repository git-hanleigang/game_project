--[[
Author: cxc
Date: 2022-01-27 18:16:04
LastEditTime: 2022-01-27 18:16:23
LastEditors: cxc
Description: bingo 比赛pass数据
FilePath: /SlotNirvana/src/activities/Activity_BingoRush/model/BingoRushPassData.lua
--]]
-- message BingoRushPass {
--     optional string keyId = 1;
--     optional string key = 2; //付费点key
--     optional string price = 3; //价格
--     optional bool unlock = 5; // 是否已解锁
--     repeated BingoRushPassLevel levels = 6; // 各阶段的奖励
--   }
local BingoRushPassData = class("BingoRushPassData")
local BingoRushPassLevelData = require("activities.Activity_BingoRush.model.BingoRushPassLevelData")

function BingoRushPassData:ctor()
    self.m_goodsId = ""
    self.m_price = ""
    self.m_curPoints = 0
    self.m_bUnlock = false
    self.m_levelList = {}
end

function BingoRushPassData:parseData(_curPoints, _data)
    if not _data then
        return
    end

    self.m_goodsId = _data.keyId or ""
    self.m_price = _data.price or ""
    self.m_curPoints = tonumber(_curPoints) or 0
    self.m_bUnlock = _data.unlock

    self.m_levelList = {}
    self:parseLevelList(_data.levels)
end

-- 解析阶段数据
function BingoRushPassData:parseLevelList(_levels)
    if not _levels then
        return
    end

    for i = 1, #_levels do
        local levelData = BingoRushPassLevelData:create(i)
        levelData:parseData(_levels[i], self.m_bUnlock)
        table.insert(self.m_levelList, levelData)
    end

    self:checkCollectCount()
end

function BingoRushPassData:checkCollectCount()
    self.collect_counts = 0
    for _, data in pairs(self.m_levelList) do
        local count = data:getCollectCount(self.m_curPoints)
        self.collect_counts = self.collect_counts + count
    end
end

function BingoRushPassData:getCollectCounts()
    return self.collect_counts
end

function BingoRushPassData:getCanCollect()
    return self.collect_counts > 0
end

-- 付费点key
function BingoRushPassData:getGoodsId()
    return self.m_goodsId
end

-- 价格
function BingoRushPassData:getPrice()
    return self.m_price
end

-- 玩家累计点数
function BingoRushPassData:getScore()
    return self.m_curPoints
end

-- 是否已解锁
function BingoRushPassData:isUnlock()
    return self.m_bUnlock
end
function BingoRushPassData:goUnlock()
    self.m_bUnlock = true
end

-- 各阶段的奖励
function BingoRushPassData:getPhaseList()
    return self.m_levelList
end

----- 报送需要 -----
function BingoRushPassData:getDiscount()
    return -1
end
function BingoRushPassData:getCoins()
    return 0
end
----- 报送需要 -----

return BingoRushPassData
