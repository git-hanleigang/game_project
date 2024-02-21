--[[
    Statue小游戏数据
    author: 徐袁
    time: 2021-03-22 19:52:01
]]
local StatuePickBoxInfo = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickBoxInfo")
local StatuePickGameData = class("StatuePickGameData", BaseSingleton)

function StatuePickGameData:ctor()
    StatuePickGameData.super.ctor(self)
    self.m_isParse = false
    -- 状态
    self.m_status = nil

    -- 到期时间
    self.m_expireAt = 0
    -- 剩余pick次数
    self.m_picks = 0
    -- buy次数
    self.m_buys = 0
    -- 购买价格
    self.m_buyPrices = {}
    -- 箱子奖励
    self.m_boxsReward = {}
    -- 已打开的列表
    -- self.m_openedIndexs = {}

    -- 奖励展示
    self.m_maxCoins = 0
    self.m_maxGems = 0
end

-- 解析数据
function StatuePickGameData:parseData(_data)
    if not _data or not next(_data) then
        return
    end
    self.m_isParse = true

    self.m_expireAt = tonumber(_data.coolDown)
    self.m_status = _data.status
    self.m_picks = _data.playTimes
    self.m_buys = _data.purchaseTimes

    -- 购买价格
    self.m_buyPrices = {}
    for i = 1, #(_data.needGemsCounts or {}) do
        local _count = _data.needGemsCounts[i]
        table.insert(self.m_buyPrices, _count)
    end

    -- 已打开的列表
    -- self.m_openedIndexs = {}
    self.m_boxsReward = {}
    -- 解析宝箱
    for i = 1, #(_data.icons or {}) do
        local rewardItem = StatuePickBoxInfo:create()
        rewardItem:parseData(_data.icons[i])
        self.m_boxsReward["" .. i] = rewardItem

        -- if rewardItem:isOpened() then
        --     self:setOpenedIndex(i)
        -- end
    end

    self.m_maxCoins = tonumber(_data.coins)
    self.m_maxGems = tonumber(_data.gems)
end

function StatuePickGameData:isParseData()
    return self.m_isParse
end

-- 重置时间
function StatuePickGameData:getCooldownTime()
    local cd = math.floor((self.m_expireAt - globalData.userRunData.p_serverTime) / 1000)
    return math.max(cd, 0)
end

function StatuePickGameData:getMaxCoins()
    return self.m_maxCoins
end

function StatuePickGameData:getMaxGems()
    return self.m_maxGems
end

-- 游戏状态
function StatuePickGameData:getGameStatus()
    return self.m_status or StatuePickStatus.FINISH
end

function StatuePickGameData:setGameStatus(_status)
    self.m_status = _status or StatuePickStatus.FINISH
end

function StatuePickGameData:getExpireAt()
    return self.m_expireAt / 1000
end

-- 剩余开启次数
function StatuePickGameData:getPicks()
    return self.m_picks
end

-- 获得箱子信息
function StatuePickGameData:getBoxReward(index)
    return self.m_boxsReward["" .. index]
end

-- 获得已打开箱子的索引列表
-- function StatuePickGameData:getOpenedIndexss()
--     return self.m_openedIndexs
-- end

-- 箱子是否打开
function StatuePickGameData:isOpened(index)
    -- return self.m_openedIndexs["" .. index] or false
    local _boxInfo = self:getBoxReward(index)
    if _boxInfo then
        return _boxInfo:isOpened()
    else
        return false
    end
end

-- 设置打开的索引
-- function StatuePickGameData:setOpenedIndex(index)
--     self.m_openedIndexs["" .. index] = true
-- end

-- 获得所有打开的奖励信息
-- function StatuePickGameData:getOpenedRewards()
--     local _openedRewards = {}
--     for key, value in pairs(self.m_openedIndexs) do
--         local _rewardInfo = self.m_boxsReward[key]
--         if _rewardInfo then
--             table.insert(_openedRewards, _rewardInfo)
--         end
--     end

--     return _openedRewards
-- end

-- 购买次数
function StatuePickGameData:getBuyTimes()
    return self.m_buys
end

-- 是否还有购买次数
function StatuePickGameData:isHasBuyTimes()
    return self.m_buys < #(self.m_buyPrices or {})
end

-- 购买价格
function StatuePickGameData:getBuyPrice()
    if self:isHasBuyTimes() then
        local idx = self.m_buys + 1

        return self.m_buyPrices[idx]
    else
        return nil
    end
end

-- 获取所有未解锁的宝箱的index列表
function StatuePickGameData:getUnopenBoxs()
    local unopenList = {}
    for k, v in pairs(self.m_boxsReward) do
        local index = tonumber(k)
        if not self:isOpened(index) then
            table.insert(unopenList, index)
        end
    end
    return unopenList
end

return StatuePickGameData
