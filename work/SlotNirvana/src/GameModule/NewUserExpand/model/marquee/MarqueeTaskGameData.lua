--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-09 17:17:01
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-09 17:22:06
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/marquee/MarqueeTaskGameData.lua
Description: 跑马灯游戏数据
--]]
local MarqueeTaskGameData = class("MarqueeTaskGameData")
local MarqueeTaskGameRewardData = util_require("GameModule.NewUserExpand.model.marquee.MarqueeTaskGameRewardData")

-- message ExpandCirclePyiGame {
--     optional int32 totalTimes = 1;// 总游戏次数
--     repeated ExpandCirclePyiReward rewards = 2;// 奖励列表
--     repeated int64 coinsSum = 3;// 累计金币
--     repeated int64 multipleSum = 4;// 累计倍数
--     repeated int32 hitIndex = 5;// 每次命中
--   }
function MarqueeTaskGameData:parseData(_data, _curIdx)
    self.m_totalTimes = _data.totalTimes or 0 -- 总游戏次数
    self:parseRewardList(_data.rewards or {}) --奖励列表
    self.m_curPassIdx = _curIdx --当前第几关游戏

    self.m_coinsList = _data.coinsSum or {}
    self.m_mulList = _data.multipleSum or {}
    self.m_hitIdxList = _data.hitIndex or {}

    self.m_coinsSum = 0 -- 累计金币
    self.m_mulSum = 0 -- 累计倍数
    self.m_playTimes = 0 -- 累计游戏次数
    self:checkUserClientData()
end

function MarqueeTaskGameData:checkUserClientData()
    local clientSaveStr = gLobalDataManager:getStringByField("MarqueeTaskGameDataSaveInfo", "{}")
    local saveInfo = json.decode(clientSaveStr)
    if saveInfo.curPassIdx ~= self.m_curPassIdx then
        gLobalDataManager:setStringByField("MarqueeTaskGameDataSaveInfo", "{}")
        return
    end

    if saveInfo.playTimes then
        self.m_playTimes = saveInfo.playTimes or 0 -- 累计游戏次数
    end
    if saveInfo.coinsSum then
        self.m_coinsSum = tonumber(saveInfo.coinsSum) or 0 -- 累计金币
    end
    if saveInfo.multipleSum then
        self.m_mulSum = tonumber(saveInfo.multipleSum) or 0 -- 累计倍数
    end
end

-- 奖励列表
function MarqueeTaskGameData:parseRewardList(_rewardList)
    if #_rewardList == 0 then
        return
    end

    self.m_rewardList = {}
    for i=1, #_rewardList do
        local rewardData = MarqueeTaskGameRewardData:create()
        local serverData = _rewardList[i]        
        rewardData:parseData(serverData)
        table.insert(self.m_rewardList, rewardData)
    end
end

function MarqueeTaskGameData:getRewardList()
    return self.m_rewardList or {}
end
function MarqueeTaskGameData:getTotalTimes()
    return self.m_totalTimes or 0
end
function MarqueeTaskGameData:getPlayTimes()
    return self.m_playTimes or 0
end
function MarqueeTaskGameData:getTotalCoins()
    return self.m_coinsSum or 0
end
function MarqueeTaskGameData:getTotalMulSum()
    return self.m_mulSum or 0
end
function MarqueeTaskGameData:getCurPassIdx()
    return self.m_curPassIdx
end

-- 剩下spin次数
function MarqueeTaskGameData:getLeftSpinCount()
    local totalCount = self:getTotalTimes() 
    local hadPlayCount = self:getPlayTimes()
    local leftCount = math.max(totalCount-hadPlayCount, 0)
    return leftCount
end
function MarqueeTaskGameData:checkCanSpin()
    local leftCount = self:getLeftSpinCount()
    return leftCount > 0
end

function MarqueeTaskGameData:spinUpdateGameData()
    self.m_playTimes = self.m_playTimes + 1
    self.m_coinsSum = tonumber(self.m_coinsList[self.m_playTimes]) or 0 -- 累计金币
    self.m_mulSum = tonumber(self.m_mulList[self.m_playTimes]) or 0 -- 累计倍数
end
function MarqueeTaskGameData:getCurHitIdx()
    return (self.m_hitIdxList[self.m_playTimes] or 0) + 1
end

return MarqueeTaskGameData