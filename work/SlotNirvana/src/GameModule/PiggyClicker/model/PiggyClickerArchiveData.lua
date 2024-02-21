--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-18 11:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-18 11:18:44
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/model/PiggyClickerArchiveData.lua
Description: 快速点击小游戏 归档数据
--]]
local PiggyClickerGameConfig = util_require("GameModule.PiggyClicker.config.PiggyClickerGameConfig")
local PiggyClickerArchiveData = class("PiggyClickerArchiveData")

function PiggyClickerArchiveData:ctor()
    self.__gameTotalTime = 0
    self.__coeIntervalList = {}

    self:reset()
end
function PiggyClickerArchiveData:reset()
    self.m_curIntervalClickCount = 0
    self.m_totalClickCount = 0
    self.m_clickCountList = {}
    self.m_gameState = PiggyClickerGameConfig.GAME_STATE.START
    self.m_leftGameCD = self.__gameTotalTime
    self.m_curIntervalIdx = 0
    self.m_gameDropCoins = 0
    self.m_gameDropGems = 0
    self.m_gainJackpotCoins = 0
    self.m_oneSecondClickInfo = {} --每秒点击次数
end

function PiggyClickerArchiveData:parseData(_jsonStr, _gameTotalTime, _coeIntervalList)
    self.__gameTotalTime = _gameTotalTime
    self.__coeIntervalList = _coeIntervalList
    if not _jsonStr or not string.find(_jsonStr, "{") then
        self.m_leftGameCD = self.__gameTotalTime
        return
    end

    local jsonTable = json.decode(_jsonStr)
    for key, value in pairs(jsonTable) do
        self[key] = value
    end
end

-- 每秒点击次数上限
function PiggyClickerArchiveData:setOneSecLimitClickCount(_limitC)
    self.__oneSecLimitC = _limitC 
end

-- 点击次数
function PiggyClickerArchiveData:addClickCount(_count)
    -- 一秒内点击数
    local hadPlayTime = self.__gameTotalTime - self.m_leftGameCD
    if self.m_oneSecondClickInfo[hadPlayTime] then
        self.m_oneSecondClickInfo[hadPlayTime] = self.m_oneSecondClickInfo[hadPlayTime] + 1
    else
        self.m_oneSecondClickInfo[hadPlayTime] = 1
    end
    if self.m_oneSecondClickInfo[hadPlayTime] > self.__oneSecLimitC then
        -- 点超了不记录了
        return
    end

    -- 总点击数
    self.m_totalClickCount = self.m_totalClickCount + 1
    -- 当前区间点击数
    self.m_curIntervalClickCount = self.m_curIntervalClickCount + 1
    self.m_clickCountList[self.m_curIntervalIdx] = self.m_curIntervalClickCount
end
function PiggyClickerArchiveData:getOneSecondClickCount(_time)
    _time = _time or self.__gameTotalTime - self.m_leftGameCD
    return self.m_oneSecondClickInfo[_time] or 0
end
function PiggyClickerArchiveData:getCurIntervalClickCount()
    return self.m_curIntervalClickCount
end
function PiggyClickerArchiveData:getTotalClickCount()
    return self.m_totalClickCount
end

-- 游戏剩余时间
function PiggyClickerArchiveData:setLeftGameCD(_time)
    self:checkChangeCurInterval(_time)
    self.m_leftGameCD = _time
end
function PiggyClickerArchiveData:getLeftGameCD()
    return self.m_leftGameCD
end

-- 游戏当前状态
function PiggyClickerArchiveData:setGameState(_state)
    self.m_gameState = _state
end
function PiggyClickerArchiveData:getGameState()
    return self.m_gameState
end

-- 游戏掉落金币值
function PiggyClickerArchiveData:addCoins(_coins)
    self.m_gameDropCoins = self.m_gameDropCoins + _coins
end
function PiggyClickerArchiveData:getDropCoins()
    return self.m_gameDropCoins
end
function PiggyClickerArchiveData:setGameOverCoins(_coins)
    self.m_gameDropCoins = tonumber(_coins) or 0
end

-- 游戏掉落钻石值
function PiggyClickerArchiveData:addGems(_gems)
    self.m_gameDropGems = self.m_gameDropGems + _gems
end
function PiggyClickerArchiveData:getDropGems()
    return self.m_gameDropGems
end
function PiggyClickerArchiveData:setGameOverGems(_gems)
    self.m_gameDropGems = tonumber(_gems) or 0
end 

-- 游戏jackpot奖励金币
function PiggyClickerArchiveData:setGameOverJackpotCoins(_coins)
    self.m_gainJackpotCoins = tonumber(_coins) or 0
end
function PiggyClickerArchiveData:getGameOverJackpotCoins()
    return self.m_gainJackpotCoins
end

function PiggyClickerArchiveData:getCurrency(_type)
    local currency = self.m_gameDropCoins
    if _type == PiggyClickerGameConfig.TASK_ITEM_TYPE.GEMS then
        currency = self.m_gameDropGems
    elseif _type == PiggyClickerGameConfig.TASK_ITEM_TYPE.JACKPOT then
        currency = self.m_gainJackpotCoins
    end
    return currency
end

-- 游戏当前所在间隔
function PiggyClickerArchiveData:getCurIntervalTime()
    return self.__coeIntervalList[self.m_curIntervalIdx] or 0
end
function PiggyClickerArchiveData:getIntervalProg()
    local prog = 0
    if #self.__coeIntervalList > 0 then
        prog = self.m_curIntervalIdx / #self.__coeIntervalList
    end

    return prog
end


function PiggyClickerArchiveData:checkChangeCurInterval(_time)
    local hadPlayTime = self.__gameTotalTime - _time
    local idx = 0
    for i=#self.__coeIntervalList, 1, -1 do
        local intervalTime = self.__coeIntervalList[i]
        if hadPlayTime >= intervalTime then
            idx = i
            break
        end
    end
    
    if idx > self.m_curIntervalIdx then
        self.m_curIntervalClickCount = 0
        self.m_clickCountList[idx] = 0
        self.m_curIntervalIdx = idx
    end 
end

-- 获取要存档的数据
function PiggyClickerArchiveData:getCurArchiveData()
    local info = {}
    for key, value in pairs(self) do
        if string.find(key, "m_") then
            info[key] = value
        end
    end
    return json.encode(info)
end

-- 获取结算要验证的数据
function PiggyClickerArchiveData:getCollectVeriyData() 
    return {
        totalClickCount = self.m_totalClickCount,
        clickCountIntervalList = self.m_clickCountList,
        dropCoins = math.floor(self.m_gameDropCoins),
        dropGems = math.floor(self.m_gameDropGems),
    }
end

-- 点击进度
function PiggyClickerArchiveData:getClickCountProg()
    return self.m_totalClickCount / (self.__gameTotalTime * 5)
end

return PiggyClickerArchiveData