--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-23 20:04:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-23 20:05:00
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/plinko/PlinkoTaskGameData.lua
Description: 弹珠游戏数据
--]]
local PlinkoTaskGameData = class("PlinkoTaskGameData")
local PlinkoTaskGameRewardData = util_require("GameModule.NewUserExpand.model.plinko.PlinkoTaskGameRewardData")
-- message ExpandCircleTqGame {
--     optional int32 totalTimes = 1;// 总游戏次数
--     repeated int64 rewards = 2;// 奖励列表
--     repeated int64 coinsSum = 3;// 累计金币
--     repeated int32 res = 4;// 底色321 大中小
--     repeated int64 multipleSum = 5;// 累计倍数
--     repeated int32 hitIndex = 6;// 每次命中
--   }
function PlinkoTaskGameData:parseData(_data, _curIdx)
    self.m_totalTimes = _data.totalTimes or 0 -- 总游戏次数
    self:parseRewardList(_data.rewards or {}, _data.res or {}) --奖励列表
    self.m_curPassIdx = _curIdx --当前第几关游戏

    self.m_coinsList = _data.coinsSum or {}
    self.m_hitIdxList = _data.hitIndex or {}

    self.m_coinsSum = tonumber(_data.coinsSum) or 0 -- 累计金币
    self.m_playTimes = _data.playTimes or 0 -- 累计游戏次数
    self:checkUserClientData()
end

function PlinkoTaskGameData:checkUserClientData()
    local clientSaveStr = gLobalDataManager:getStringByField("PlinkoTaskGameDataSaveInfo", "{}")
    local saveInfo = json.decode(clientSaveStr)
    if saveInfo.curPassIdx ~= self.m_curPassIdx then
        gLobalDataManager:setStringByField("PlinkoTaskGameDataSaveInfo", "{}")
        return
    end

    if saveInfo.playTimes then
        self.m_playTimes = saveInfo.playTimes or 0 -- 累计游戏次数
    end
    if saveInfo.coinsSum then
        self.m_coinsSum = tonumber(saveInfo.coinsSum) or 0 -- 累计金币
    end
end

-- 奖励列表
function PlinkoTaskGameData:parseRewardList(_rewardList, _rewardBgList)
    if #_rewardList == 0 or #_rewardList ~= #_rewardBgList then
        return
    end

    self.m_rewardList = {}
    for i=1, #_rewardList do
        local rewardData = PlinkoTaskGameRewardData:create()
        rewardData:parseData(_rewardList[i], _rewardBgList[i])
        table.insert(self.m_rewardList, rewardData)
    end
end

function PlinkoTaskGameData:getRewardList()
    return self.m_rewardList or {}
end
function PlinkoTaskGameData:getTotalTimes()
    return self.m_totalTimes or 0
end
function PlinkoTaskGameData:getPlayTimes()
    return self.m_playTimes or 0
end
function PlinkoTaskGameData:getTotalCoins()
    return self.m_coinsSum or 0
end
function PlinkoTaskGameData:getCurPassIdx()
    return self.m_curPassIdx
end

-- 剩下spin次数
function PlinkoTaskGameData:getLeftSpinCount()
    local totalCount = self:getTotalTimes() 
    local hadPlayCount = self:getPlayTimes()
    local leftCount = math.max(totalCount-hadPlayCount, 0)
    return leftCount
end
function PlinkoTaskGameData:checkCanSpin()
    local leftCount = self:getLeftSpinCount()
    return leftCount > 0
end

function PlinkoTaskGameData:spinUpdateGameData()
    self.m_playTimes = self.m_playTimes + 1
    self.m_coinsSum = tonumber(self.m_coinsList[self.m_playTimes]) or 0 -- 累计金币
end
function PlinkoTaskGameData:getCurHitIdx()
    return (self.m_hitIdxList[self.m_playTimes] or 0) + 1
end

return PlinkoTaskGameData