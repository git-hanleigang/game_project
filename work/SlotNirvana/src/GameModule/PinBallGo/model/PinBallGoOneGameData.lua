--[[
    2周年
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseGameModel = require("GameBase.BaseGameModel")
local PinBallGoOneGameData = class("PinBallGoOneGameData",BaseGameModel)

function PinBallGoOneGameData:ctor()
    PinBallGoOneGameData.super.ctor(self)
    -- 剩余时间
    self.p_expire = 0
    -- 到期时间
    self.p_expireAt = 0
end

function PinBallGoOneGameData:parseData(gameData)
    self.p_index = gameData.index
    self.p_keyId = gameData.keyId
    self.p_key = gameData.key
    self.p_price = gameData.price  --价格
    self.p_status = gameData.status --游戏状态:init, playing
    self.p_expire = tonumber(gameData.expire) --剩余时间
    local _expireAt = tonumber(gameData.expireAt)
    if _expireAt >= 0 then
        self.p_expireAt = _expireAt -- 剩余时间
    end
    self.p_mark = not not gameData.mark --是否带付费项
    self.p_pay = not not gameData.pay --是否付过费
    self.p_source = gameData.source --投放来源
    self.p_leftBallCount = gameData.leftBallCount --剩余球数
    --格子奖励
    self.p_cellRewardVec = {}
    if gameData.rewards then
        for i,v in ipairs(gameData.rewards) do
            local oneData = {}
            oneData.cellPos = v.pos --奖励的位置
            oneData.type = v.type --奖励类型 string ITEM,COINS
            oneData.baffle = tonumber(v.baffle) --挡板长度
            oneData.coins = tonumber(v.coins) --奖励金币
            if v.items then
                --奖励物品
                oneData.itemsVec = self:parseRewardItemList(v.items)
            end
            oneData.collect =  not not v.collect --奖励是否已获得或者领取
            self.p_cellRewardVec[v.pos] = oneData
        end
    end
    
    self.p_cellPayRewardVec = {}
    if gameData.payRewards then
        for i,v in ipairs(gameData.payRewards) do
            local oneData = {}
            oneData.cellPos = v.pos --奖励的位置
            oneData.type = v.type --奖励类型 string ITEM,COINS
            oneData.baffle = tonumber(v.baffle) --挡板长度
            oneData.coins = tonumber(v.coins) --奖励金币
            if v.items then
                --奖励物品
                oneData.itemsVec = self:parseRewardItemList(v.items)
            end
            oneData.collect =  not not v.collect --奖励是否已获得或者领取
            self.p_cellPayRewardVec[v.pos] = oneData
        end
    end

    --碰撞球奖励
    self.p_crashBallRewardMap = {}
    if gameData.crashRewards then
        for i,v in ipairs(gameData.crashRewards) do
            local oneData = {}
            oneData.ballId = v.ballId --奖励的位置
            oneData.type = v.type --奖励类型 string ITEM,COINS
            oneData.count = v.count --需要碰撞的次数
            oneData.coins = tonumber(v.coins) --奖励金币
            if v.items then
                --奖励物品
                oneData.itemsVec = self:parseRewardItemList(v.items)
            end
            oneData.collect =  not not v.collect --奖励是否已获得或者领取
            oneData.ballCount = v.ballCount --奖励的球数
            self.p_crashBallRewardMap[oneData.ballId] = oneData
        end
    end

    --付费碰撞球奖励
    self.p_payCrashBallRewardMap = {}
    if gameData.payCrashRewards then
        for i,v in ipairs(gameData.payCrashRewards) do
            local oneData = {}
            oneData.ballId = v.ballId --奖励的位置
            oneData.type = v.type --奖励类型 string ITEM,COINS
            oneData.count = v.count --需要碰撞的次数
            oneData.coins = tonumber(v.coins) --奖励金币
            if v.items then
                --奖励物品
                oneData.itemsVec = self:parseRewardItemList(v.items)
            end
            oneData.collect =  not not v.collect --奖励是否已获得或者领取
            oneData.ballCount = v.ballCount --奖励的球数
            self.p_payCrashBallRewardMap[oneData.ballId] = oneData
        end
    end

    --碰撞的线
    self.p_pinballLineVec = {}
    if gameData.lines then
        for i,v in ipairs(gameData.lines) do
            local oneLine = {}
            --oneLine.gears = v.gears --发射力度档位
            oneLine.line = tonumber(v.line)  --string 碰撞的线
            oneLine.tagetCellPos = v.pos --目标格子
            table.insert(self.p_pinballLineVec, oneLine)
        end
    end

    self.p_payShowCoins = tonumber(gameData.showCoins) --付费购买展示金币
    self.p_payShowItems = {}
    --付费购买展示物品
    if gameData.showItems then
        self.p_payShowItems = self:parseRewardItemList(gameData.showItems)
    end
    --不同档位速度
    self.p_speedVec = {}
    if gameData.speed then
        for i,v in ipairs(gameData.speed) do
            table.insert( self.p_speedVec, tonumber(v))
        end
    end
    --碰撞球命中次数数据
    self.p_hitBallsMap = {}
    if gameData.hitBalls then
        for i,v in ipairs(gameData.hitBalls) do
            local oneBall = {}
            oneBall.ballId = v.ballId --碰撞球id
            oneBall.hitCount = v.hitCount --碰撞球已击中的次数
            self.p_hitBallsMap[oneBall.ballId] = oneBall
        end
    end

    self.p_hitCoins = gameData.coins --已经命中格子的总物品奖励
    self.p_hitItems = {}  --已经命中格子的总物品奖励
    --付费购买展示物品
    if gameData.items then
        self.p_hitItems = self:parseRewardItemList(gameData.items)
    end

    self.p_rewardCollected = not not gameData.collect --最终奖励是否领取
    self.p_payBalls = gameData.payBalls --付费获得球数

end


function  PinBallGoOneGameData:setCrashBallCrashCountByBallId(ballId,crashCount,isAdd)
    if self.p_crashBallData[ballId] then
        local currentCrashCount  = self.p_crashBallData[ballId].currentCrashCount
        if isAdd then
            currentCrashCount = currentCrashCount + crashCount
        else
            currentCrashCount = crashCount
        end
        self.p_crashBallData[ballId].currentCrashCount = currentCrashCount
    end
end

function PinBallGoOneGameData:getGameGainCoinsAndItems()
    local result = {}
    result.coins = 0
    result.items = {}
    for i,reward_c in ipairs(self.p_crashBallRewardVec) do
        local crashBallData = self.p_crashBallData[reward_c.ballId]
        local currentCrashCount = 0
        if crashBallData and crashBallData.currentCrashCount then
            currentCrashCount = crashBallData.currentCrashCount
        end
        
        if currentCrashCount >= reward_c.count then
            result.coins = result.coins + reward_c.coins
            if reward_c.itemsVec then
                for i,oneItem in ipairs(reward_c.itemsVec) do
                    table.insert(result.items,oneItem)
                end
            end
        end
    end
    return result
end

function PinBallGoOneGameData:getExpire()
    return self.p_expire or 0
end

function PinBallGoOneGameData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function PinBallGoOneGameData:setExpireAt(mSec)
    self.p_expireAt = mSec
end

function PinBallGoOneGameData:isPlaying()
    if self.p_status == "INIT" then 
        return false
    elseif self.p_status == "PLAYING" then 
        return true
    end
    if self.m_gemeOver then
        return false
    end
end

-- 未激活 状态
function PinBallGoOneGameData:isIniting()
    return self.p_status == "INIT"
end

-- 1 免费 2 付费
function PinBallGoOneGameData:getGameDataType()
    if self.p_pay then
        return 2
    end
    return 1
end

function PinBallGoOneGameData:getIndex()
    return self.p_index
end

function PinBallGoOneGameData:getPrice()
    return self.p_price
end

function PinBallGoOneGameData:getSource()
    return self.p_source
end

function PinBallGoOneGameData:getBuyKey()
    return self.p_key
end

function PinBallGoOneGameData:isPayGame()
    return self.p_mark
end

function PinBallGoOneGameData:isPaid()
    return self.p_pay
end

function PinBallGoOneGameData:getTargetPos()
    return self.p_pinballLineVec[1].tagetCellPos
end

function PinBallGoOneGameData:getTargetLineID()
    return self.p_pinballLineVec[1].line
end

function PinBallGoOneGameData:getShopItem()
    return {}
end

function PinBallGoOneGameData:isRunning()
    if self:getExpireAt() > 0 then
        if self:getLeftTime() > 0 then
            return self.p_status ~= "FINISH"
        else
            return false
        end
    else
        return false
    end
end

function PinBallGoOneGameData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function PinBallGoOneGameData:parseRewardItemList(_reward)
    -- 通用道具
    local itemsData = {}
    if _reward and #_reward > 0 then 
        for i,v in ipairs(_reward) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function PinBallGoOneGameData:setIsNewGameData(isNew)
    self.p_isNewGameData = isNew
end

function PinBallGoOneGameData:getIsNewGameData()
    return self.p_isNewGameData
end

function PinBallGoOneGameData:setGameOver()
    self.m_gemeOver = true
end

return PinBallGoOneGameData
