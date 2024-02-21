--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-11 16:30:58
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-11 16:32:10
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/model/PiggyClickerGameData.lua
Description: 快速点击小游戏 游戏数据
--]]
local PiggyClickerGameData = class("PiggyClickerGameData")
local PiggyClickerCalcData = import(".PiggyClickerCalcData")
local PiggyClickerArchiveData = import(".PiggyClickerArchiveData")

function PiggyClickerGameData:ctor()
    self.m_index = 0 -- 序号
    self.m_keyId = "" -- 付费点keyId
    self.m_key = "" --付费点key
    self.m_price = "" -- 价格
    self.m_expireAt = 0 -- 过期时间
    self.m_expire = 0 -- 剩余时间
    self.m_status = "" -- 游戏状态:INIT, PLAYING,FINISH
    self.m_bMarkPay = false -- 是否带付费项
    self.m_bPay = false -- 是否付过费
    self.m_clickDuration = 0 -- 小游戏总时长：秒
    self.m_bReward = false -- 是否已经领过奖
    self.m_curJackpotNum = 0 -- 当前jackpot点数
    self.m_jackpotNeedCount = 0 -- jackpot收集总点数
    self.m_jackpotList = {}-- 点击对应次数出现jackpot的集合
    self.m_freeJackpot = 0 -- 免费jackpot金币总价值
    self.m_payJackpot = 0 -- 付费jackpot金币总价值
    self.m_oneSecondClick = 0 -- 每秒点击次数上限
    self.m_showCoins = 0 -- 付费确认弹板展示用金币
    self.m_showGems = 0 -- 付费确认弹板展示用宝石
    self.m_calcData = PiggyClickerCalcData:create(self)
    self.m_archiveData = PiggyClickerArchiveData:create(self)
end

function PiggyClickerGameData:parseData(_data)
    if not _data then
        return
    end

    self.m_index = tonumber(_data.index) or 0 -- 序号
    self.m_keyId = _data.keyId or "" -- 付费点keyId
    self.m_key = _data.key or "" --付费点key
    self.m_price = _data.price or "" -- 价格
    self.m_expireAt = tonumber(_data.expireAt) or 0 -- 过期时间
    self.m_expire = tonumber(_data.expire) or 0 -- 剩余时间
    self.m_status = _data.status or "" -- 游戏状态:INIT, PLAYING,FINISH
    self.m_bMarkPay = _data.mark -- 是否带付费项
    self.m_bPay = _data.pay -- 是否付过费
    self.m_curJackpotNum = _data.jackpotNum or 0 -- 当前jackpot点数
    self.m_jackpotNeedCount = _data.jackpotRewardCount or 0 -- jackpot收集总点数
    self.m_clickDuration = _data.clickDuration or 0 -- 小游戏总时长：秒
    self.m_bReward = _data.reward -- 是否已经领过奖
    self.m_jackpotList = _data.jackpot or {} -- 点击对应次数出现jackpot的集合
    self.m_freeJackpot = tonumber(_data.freeJackpot) or 0 -- 免费jackpot金币总价值
    self.m_payJackpot = tonumber(_data.payJackpot) or 0 -- 付费jackpot金币总价值
    self.m_oneSecondClick = tonumber(_data.oneSecondClick) or 0 -- 每秒点击次数上限
    self.m_showCoins = tonumber(_data.showCoins) or 0 -- 付费确认弹板展示用金币
    self.m_showGems = tonumber(_data.showGems) or 0 -- 付费确认弹板展示用宝石

    -- 解析计算数据
    self:parseCalcData(_data)
    -- 解析游戏存档数据
    self:parseArchiveData(_data.saveData)
end

-- 解析各种计算系数集合
function PiggyClickerGameData:parseCalcData(_data)
    local calcInfo = {
        clickInterval       = _data.clickInterval or 0, --点击间隔
        coeList             = _data.coe or {}, -- 各种计算系数集合
        freeCoinsMultiply   = tonumber(_data.freeCoinsMultiply) or 0, -- 免费计算金币的值
        freeGemMultiply     = tonumber(_data.freeGemMultiply) or 0, -- 免费计算宝石的值
        payCoinsMultiply    = tonumber(_data.payCoinsMultiply) or 0, -- 付费计算宝石的值
        payGemMultiply      = tonumber(_data.payGemMultiply) or 0, -- 付费计算宝石的值
    }
    self.m_calcData:parseData(calcInfo, self.m_bPay)
end

-- 解析游戏存档数据
function PiggyClickerGameData:parseArchiveData(_saveData)
    local coeIntervalList = self.m_calcData:getCoeIntervalList()
    self.m_archiveData:setOneSecLimitClickCount(self.m_oneSecondClick)
    self.m_archiveData:parseData(_saveData, self.m_clickDuration, coeIntervalList)
end
function PiggyClickerGameData:clearArchiveData()
    self.m_archiveData:reset()
end

-- 序号
function PiggyClickerGameData:getGameIdx()
    return self.m_index
end
--付费点keyId
function PiggyClickerGameData:getKeyId()
    return self.m_keyId
end
--付费点key
function PiggyClickerGameData:getKey()
    return self.m_key 
end
-- 价格
function PiggyClickerGameData:getPrice()
    return self.m_price
end
-- 过期时间
function PiggyClickerGameData:getExpireAt()
    return self.m_expireAt
end
-- 剩余时间
function PiggyClickerGameData:getExpire()
    return self.m_expire
end
-- 游戏状态:INIT, PLAYING,FINISH
function PiggyClickerGameData:getStatus()
    return self.m_status
end
-- 是否带付费项
function PiggyClickerGameData:isMarkPay()
    return self.m_bMarkPay
end
-- 是否付过费
function PiggyClickerGameData:checkGameIsPayStyle()
    return self.m_bPay
end
-- 小游戏总时长：秒
function PiggyClickerGameData:getClickDuration()
    return self.m_clickDuration
end
-- 是否已经领过奖
function PiggyClickerGameData:isReward()
    return self.m_bReward
end
-- jackpot收集总点数
function PiggyClickerGameData:getJackpotProgInfo()
    local clickCount = self.m_archiveData:getTotalClickCount()
    local curIdx = 0
    for _idx, count in ipairs(self.m_jackpotList) do
        if clickCount >= count then
            curIdx = _idx
        else
            break
        end
    end

    local curProgCount = self.m_curJackpotNum + curIdx
    return {curProgCount, self.m_jackpotNeedCount}
end
-- 回去jackpot收集需要的点数
function PiggyClickerGameData:getJackpotProgNeedCount()
    return self.m_jackpotNeedCount
end
-- 点击对应次数出现jackpot的集合
function PiggyClickerGameData:getJackpotList()
    return self.m_jackpotList
end
-- 免费jackpot金币总价值
function PiggyClickerGameData:getFreeJackpot()
    return self.m_freeJackpot
end
-- 付费jackpot金币总价值
function PiggyClickerGameData:getPayJackpot()
    return self.m_payJackpot
end

-- 付费确认弹板展示用金币
function PiggyClickerGameData:getPayShowCoins()
    return self.m_showCoins
end
-- 付费确认弹板展示用宝石
function PiggyClickerGameData:getPayShowGems()
    return self.m_showGems
end


-- 获取 计算系数数据
function PiggyClickerGameData:getCalcData()
    return self.m_calcData
end
-- 获取 游戏存档数据
function PiggyClickerGameData:getArchiveData()
    return self.m_archiveData
end
-- 游戏
function PiggyClickerGameData:checkCanPlay()
    if self.m_expireAt <= globalData.userRunData.p_serverTime then
        return false
    end
    return self.m_status == "INIT" or self.m_status == "PLAYING"
end
function PiggyClickerGameData:checkGamePlaying()
    return self.m_status == "PLAYING"
end

-- 监测本次点击是否触发 jackpot
function PiggyClickerGameData:checkTriggerJackpot(_count)
    for _, count in ipairs(self.m_jackpotList) do
        if _count == count then
            return true
        end
    end
    
    return false
end 

-- 获取 计算本次点击 掉落货币
function PiggyClickerGameData:getCalcHitDropValue()
    local oneSecCount = self.m_archiveData:getOneSecondClickCount()
    if oneSecCount > self.m_oneSecondClick then
        return 0, 0
    end
    local hitCount = self.m_archiveData:getCurIntervalClickCount()
    local curInterVal = self.m_archiveData:getCurIntervalTime()
    local coins, gems = self.m_calcData:calcHitDropValue(hitCount, curInterVal)

    self.m_archiveData:addCoins(coins)
    self.m_archiveData:addGems(gems)

    return coins, gems
end

function PiggyClickerGameData:getCollectVeriyData()
    local data = self.m_archiveData:getCollectVeriyData()
    return data
end

return PiggyClickerGameData