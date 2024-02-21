--[[
Author: cxc
Date: 2021-11-18 15:42:36
LastEditTime: 2022-05-09 16:11:41
LastEditors: dinghansheng.local
Description: 乐透数据
FilePath: /SlotNirvana/src/GameModel/Lottery/model/LotteryData.lua
--]]
local LotteryDataPreUserData = util_require("GameModule.Lottery.model.LotteryDataPreUserData")
local ShopItem = util_require("data.baseDatas.ShopItem")
local LotteryData = class("LotteryData")

function LotteryData:parseData(_data)
    self.m_expire = _data.expire
    self.m_expireAt = _data.expireAt
    self.m_closeMinutes = _data.closeMinutes -- 提前多少分钟关闭选号
    if _data.expireAt and _data.closeMinutes then
        self.m_endDrawExireAtSec = math.ceil(_data.expireAt * 0.001) - (_data.closeMinutes * 60)
    end

    self.m_period = string.gsub(_data.period, "-", ".") -- 第几期
    self.m_beginDateStr = _data.begin -- 开始时间 2021.11.22
    self.m_endDateStr = _data["end"] -- 结束时间 2021.11.22
    if self.m_beginDateStr and self.m_endDateStr then
        self.m_timeSectionStr = self.m_beginDateStr .. " - " .. self.m_endDateStr
    end

    self.m_yoursList = _data.numberList -- 本期自己历史选号
    self.m_youWinCoinList = _data.winCoins -- 本期自己选号 赢得金币数量
    self:sortBetList()
    self.m_leftTickets = _data.leftTickets -- 剩余可使用奖券
    self.m_statistics = _data.statistics -- 预测号码
    self.m_collected = _data.collected -- 发奖状态
    self.m_hitNumber = _data.hitNumber -- 头奖号码

    if _data.hitNumber and #_data.hitNumber > 0 then
        if not _data.displayHitNumber or #_data.displayHitNumber <= 0 then
            self:parseHitNumberList(_data.hitNumber)
        end
    end
    self.m_rewards = {} -- 固定奖励
    for i = 1, #(_data.rewards or {}) do
        local coins = _data.rewards[i].coins or 0
        table.insert(self.m_rewards, tonumber(coins))
    end
    self.m_grandPrize = _data.grandPrize -- 大奖池
    self:parseUserInfoList(_data.lastHeadUser) -- 上一期中头奖的人信息
    self.m_lastPeriod = _data.lastPeriod -- 上一期期号
    self.m_lastPerGrandPrize = _data.lastPerGrandPrize -- 上一期头奖总的钱

    ------- 乐透额外送奖活动 数据 -------
    self.m_extraItems = {} -- 乐透送奖-奖励
    self.m_extraPeriod = _data.extraPeriod or "" -- 乐透送奖-期号
    self:parseRewardItems(_data.extraItems)
    ------- 乐透额外送奖活动 数据 -------

    if not self.m_bRunning then
        self.m_bRunning = true
        self:deleteLastPeriodSaveInfo()
    end
    self.m_dispalyHitNumber = _data.displayHitNumber -- 白球乱序头奖号码

    if _data.displayHitNumber and #_data.displayHitNumber > 0 then
        self:parseDisPlayHitNumberList(_data.displayHitNumber)
    end

    -- 新增显示 上一期头奖总钱
    self.m_lastPerGrandPrizeUsd = tonumber(_data.lastPerGrandPrizeUsd) 
end

function LotteryData:parseRewardItems(_items)
    for i = 1, #(_items or {}) do
        local itemData = _items[i]
        local rewardItem = ShopItem:create()
        rewardItem:parseData(itemData)

        table.insert(self.m_extraItems, rewardItem)
    end
end

-- 获取自己的选号列表
function LotteryData:getYoursList()
    return self.m_yoursList or {}
    -- return {"1-2-3-5-6-7", "1-12-3-6-7-8", "1-2-3-5-6-7"}
end
-- 自己选号列表对应 赢得金币数
function LotteryData:getYouWinCoinList()
    return self.m_youWinCoinList or {}
    -- return {100, 3000, 0, 100, 200,0,0,100,0,200,100, 0, 200, 100, 200,0,0,100,0,200,100,0, 200, 100, 200,0,0,100,0,200,100}
end
-- 获取剩余的 奖券
function LotteryData:getLeftTickets()
    return self.m_leftTickets or 0
end
-- 获取预测号码信息
function LotteryData:getStatisticsInfo()
    return self.m_statistics or {}
end
-- 获取 当期领奖状态
function LotteryData:getCollectedStatus()
    return self.m_collected
end

-- 解析头奖号码(服务器发过来是排序的，策划要求打乱顺利，历史记录不用管)
function LotteryData:parseHitNumberList(_numberStr)
    local numberList = string.split(_numberStr, "-")
    if #numberList ~= 6 then
        return
    end
    self.m_hitNumberList = {}
    for i = 5, 1, -1 do
        local idx = util_random(1, i)
        local numberStr = table.remove(numberList, idx)
        table.insert(self.m_hitNumberList, tonumber(numberStr))
    end
    self.m_hitNumberList[6] = tonumber(numberList[1])
end

-- 解析服务器返回的乱序头奖号码
function LotteryData:parseDisPlayHitNumberList(_numberStr)
    local numberList = string.split(_numberStr, "-")
    if #numberList ~= 6 then
        return
    end
    self.m_hitNumberList = {}

    for i = 1, 6 do
        table.insert(self.m_hitNumberList, tonumber(numberList[i]))
    end
end

-- 获取头奖号码
function LotteryData:getHitNumberList()
    return self.m_hitNumberList or {0, 0, 0, 0, 0, 0}
    -- return {1,12,3,6,7,8}
end
-- paytable固定奖励
function LotteryData:getPayTableCoinsList()
    return self.m_rewards or {}
end
-- 奖池金币数据
function LotteryData:setGrandPrize(_grandPrize)
    self.m_grandPrize = _grandPrize
end
-- 当期大奖池
function LotteryData:getGrandPrize()
    return tonumber(self.m_grandPrize) or 0
end
-- 上一期头奖平分后的钱
function LotteryData:getLastPerGrandPrize()
    return tonumber(self.m_lastPerGrandPrize) or 0
end
-- 获取期号
function LotteryData:getCurTimeNumber()
    return self.m_period or ""
end
-- 获取上一期期号
function LotteryData:getLastTimeNumber()
    return self.m_lastPeriod or ""
end
-- 获取 本期开始与结束时间
function LotteryData:getOpenEndTimeStr()
    return self.m_timeSectionStr or ""
end
-- 获取本期结束时间
function LotteryData:getEndChooseTimeAt()
    return self.m_endDrawExireAtSec or 0
end

-- 获取本期开奖日期（string）
function LotteryData:getEndDataStr()
    return self.m_endDateStr or ""
end

-- 检查是否可以领奖
function LotteryData:checkCanCollectReward()
    return self:getCollectedStatus()
end

-- 解析上期领头奖的用户
function LotteryData:parseUserInfoList(_preUserList)
    if not _preUserList or #_preUserList == 0 then
        return
    end

    local userList = {}
    for k, v in ipairs(_preUserList) do
        local data = LotteryDataPreUserData:create()
        data:parseData(v)
        table.insert(userList, data)
    end

    self.m_preUserList = userList
end
-- 获取上期领头奖的用户
function LotteryData:getPreWinUserList()
    return self.m_preUserList or {}
end

function LotteryData:isRunning()
    return self.m_bRunning and globalData.constantData.LOTTERY_OPEN_SIGN
end

-- 获取存储 大奖上涨的 key
function LotteryData:getSaveGrandPrizeKey()
    return "LotteryGrandPrizeKey_"
end

-- 删除上一期存储的 金币上涨 值
function LotteryData:deleteLastPeriodSaveInfo()
    if self.m_lastPeriod and #self.m_lastPeriod > 0 then
        gLobalDataManager:delValueByField("LotteryGrandPrizeKey_" .. self.m_lastPeriod)
    end
end

-- 获取本期 中奖后额外奖励信息
function LotteryData:getLotteryExActRewardInfo()
    local exActInfo = {}
    exActInfo.rewardList = self.m_extraItems or {} -- 乐透送奖-奖励
    exActInfo.period = self.m_extraPeriod or "" -- 乐透送奖-期号

    return exActInfo
end

-- 乐透额外奖励 重置数据
function LotteryData:resetLotteryExActRewardInfo()
    self.m_extraPeriod = ""
    self.m_extraItems = {}
end

-- 乐透上一期头奖的美刀
function LotteryData:getLastPerGrandPrizeUsd()
    return self.m_lastPerGrandPrizeUsd or 0
end

-- 对玩家 选号进行 中奖金额排序
function LotteryData:sortBetList()
    if #self.m_youWinCoinList ~= #self.m_yoursList then
        return
    end

    local temp = {}
    for i=1, #self.m_yoursList do
        local info = {coins = tonumber(self.m_youWinCoinList[i]), number = self.m_yoursList[i]}
        table.insert( temp, info )
    end
    table.sort(temp, function(a, b)
        return a.coins > b.coins
    end)
    
    self.m_sortYouWinCoinList = {}
    self.m_sortYoursList = {}
    for i=1, #temp do
        table.insert(self.m_sortYouWinCoinList, temp[i].coins)
        table.insert(self.m_sortYoursList, temp[i].number)
    end
end
function LotteryData:getSortYoursList()
    return self.m_sortYoursList or {}
end
 
return LotteryData
