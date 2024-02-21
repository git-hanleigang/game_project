--[[
    单人限时比赛 数据
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local FrostFlameClashData = class("FrostFlameClashData", BaseActivityData)
local ShopItem = require("data.baseDatas.ShopItem")

local stateToType = {
    READY = 1,
    MATCHING = 2,
    GAME = 3,
    REWARD = 4,
}

function FrostFlameClashData:ctor()
    FrostFlameClashData.super.ctor(self)
    self.p_addPoints = 0
end

--[[
    message FlameClash {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional int32 spinTimes = 4; //spin次数
        optional string state = 5; //当前状态 READY(准备)  MATCHING(匹配)  GAME(游戏)  REWARD(结算)
        optional int32 goalDifference = 6; //净胜次数
        optional int32 matchingLeftTime = 7; //匹配剩余秒数
        optional int64 matchingTimeAt = 8; //匹配过期时间
        optional int32 endLeftTime = 9; //比赛剩余秒数
        optional int64 endTimeAt = 10; //比赛过期时间
        optional int32 points = 11; //总积分
        optional int32 gemFailed = 12; //失败保留净胜消耗第二货币数
        optional FlameClashUserInfo userInfo = 13; //玩家信息
        optional FlameClashRival rivalData = 14; //对手数据
        repeated FlameClashStageReward stageRewards = 15; //胜场任务奖励
        repeated FlameClashPointReward pointCoins = 16; //积分进度对应金币值
        repeated FlameClashBuffReward goalBuffs = 17; //胜场进度buff加成
        optional bool rewardRoom = 18; //领取房间标识
        optional string goalBuff = 19; //净胜buff
        optional int32 spinMatchingTimes = 20; //开始匹配spin次数
        optional int32 gameTimes = 21; //游戏次数
        optional int32 failTimes = 22; //失败次数
        optional int64 roomCoins = 23; //领取的房间金币值
        optional int64 signPointCoin = 24; //赢多少金币获取1积分
        optional string lastGoalBuff = 25; //上一次游戏净胜buff
        optional int32 lastGoalDifference = 26; //上一次游戏净胜次数
    }
]]
function FrostFlameClashData:parseData(_data)
    FrostFlameClashData.super.parseData(self, _data)

    self.p_spinTimes = _data.spinTimes --spin次数
    self.p_spinMatchingTimes = _data.spinMatchingTimes --开始匹配spin次数
    if self.p_state and self.p_state ~= _data.state then
        self.p_state_front = self.p_state
    end
    self.p_state = _data.state --当前状态 READY(准备)  MATCHING(匹配)  GAME(游戏中)  REWARD(结算)
    if self.p_isForEnterGame then --首次进入游戏不做表现
        self.p_state_front = self.p_state
    end
    self.p_goalDifference = _data.goalDifference or 0 --净胜次数
    self.p_goalDifference_front = _data.lastGoalDifference or 0 --上一次游戏净胜次数

    self.p_matchingLeftTime = _data.matchingLeftTime --匹配剩余秒数
    self.p_matchingTimeAt = tonumber(_data.matchingTimeAt) --匹配过期时间

    self.p_endLeftTime = _data.endLeftTime --比赛剩余秒数
    self.p_endTimeAt = (tonumber(_data.endTimeAt) or 0) / 1000 --比赛过期时间
    self.p_points = _data.points --总积分
    if not self.p_pointsMy_front then
        self.p_pointsMy_front = self.p_points
    end

    self.p_gemFailed = _data.gemFailed --失败保留净胜消耗第二货币数

    if _data.userInfo then --玩家信息
        self.p_userInfo = self:parseUserInfo(_data.userInfo)
        self.p_userInfo.points = self.p_points
    end

    if _data.rivalData then --对手数据
        self.p_rivalData = self:parseRivalInfo(_data.rivalData)
        if not self.p_pointsRival_front then
            self.p_pointsRival_front = self.p_rivalData.points
        end
    end

    if _data.stageRewards and #_data.stageRewards > 0 then --胜场任务奖励
        self.p_stageRewards = self:parseStageReward(_data.stageRewards)
    end

    if _data.pointCoins and #_data.pointCoins > 0 then --积分进度buff加成
        self.p_pointCoins = self:parsePointReward(_data.pointCoins)
        self.m_baseBattlePoint = self.p_pointCoins[1].point
    end

    if _data.goalBuffs and #_data.goalBuffs > 0 then --胜场进度buff加成
        self.p_goalBuffs = self:parseBuffReward(_data.goalBuffs)
    end

    self.p_rewardRoom = _data.rewardRoom -- 领取房间标识
    self.p_roomBuff = _data.roomBuff -- 房间奖励增加buff
    self.p_goalBuff = _data.goalBuff or "0" -- 净胜buff
    if self.p_goalBuff == "" then
        self.p_goalBuff = "0"
    end

    self.p_goalBuff_Front = _data.lastGoalBuff or "0" -- 净胜buff
    if self.p_goalBuff_Front == "" then
        self.p_goalBuff_Front = "0"
    end

    self.p_gameTimes = tonumber(_data.gameTimes or 0) -- 游戏次数
    self.p_failTimes = tonumber(_data.failTimes or 0) -- 游戏失败次数
    
    self.p_roomCoins = tonumber(_data.roomCoins or 0)
    self.p_signPointCoin = tonumber(_data.signPointCoin or 0) -- 赢多少金币获取1积分

    if not self.m_pointCoinLevel then
        local jackpotInfo = self:getJackpotData()
        self.m_pointCoinLevel = jackpotInfo.index
        self.m_pointCoinLevel_front = jackpotInfo.index
    else
        local jackpotInfo = self:getJackpotData()
        if self.m_pointCoinLevel ~= jackpotInfo.index then
            self.m_pointCoinLevel_front = self.m_pointCoinLevel
        end
        self.m_pointCoinLevel = jackpotInfo.index
    end
    local currentTime = util_getCurrnetTime()
    if self.p_pointsMy_front >= self.m_baseBattlePoint * 0.5 and self.p_pointsRival_front >= self.m_baseBattlePoint * 0.5 then
        if self.p_pointsMy_front >= self.p_pointsRival_front and self.p_points < self.p_rivalData.points then
            self.m_willDoBattleEffect = true
        end
        if not self.m_willDoBattleEffect and self.p_pointsMy_front <=self.p_pointsRival_front and self.p_points > self.p_rivalData.points then
            self.m_willDoBattleEffect = true
        end
        if not self.m_willDoBattleEffect then
            local currentTime = util_getCurrnetTime()
            local saveValue = gLobalDataManager:getNumberByField("FrostFlameClashData_willDoBattleEffect", 0)
            local showIndex = saveValue % 10
            local showTime = saveValue / 10
            if (showTime + 2 * 60)  <= currentTime then
                gLobalDataManager:setNumberByField("FrostFlameClashData_willDoBattleEffect", 0)
                showIndex = 0
            end
            if self.p_points >= (self.p_rivalData.points * 1.5) and (showIndex == 0 or showIndex == 2) then
                self.m_willDoBattleEffect = true
                gLobalDataManager:setNumberByField("FrostFlameClashData_willDoBattleEffect", (showIndex + 1) + currentTime * 10 )
            end
            if not self.m_willDoBattleEffect and self.p_points <= (self.p_rivalData.points * 1.5) and (showIndex < 2) then
                self.m_willDoBattleEffect = true
                gLobalDataManager:setNumberByField("FrostFlameClashData_willDoBattleEffect", (showIndex + 2) + currentTime * 10 )
            end
        end
    end
    if self.p_addPoints <= 0 then
        self.p_addPoints = self.p_points - self.p_pointsMy_front
    end
    self.p_pointsMy_front = self.p_points
    self.m_refreshRivalData = false
    if self.p_rivalData then
        if self.p_addPoints <= 0 and self.p_rivalData.points > self.p_pointsRival_front then
            self.m_refreshRivalData = true
        end
        self.p_pointsRival_front = self.p_rivalData.points
    end
end

--[[
    message FlameClashUserInfo {
        optional string name = 1; //名
        optional string head = 2; //头像
        optional string frame = 3; //头像框
        optional string facebook = 4; //facebook头像
        optional string robotHead = 5; //robot头像
    }
]]
function FrostFlameClashData:parseUserInfo(_data)
    local result = {}
    if _data then
        result.name = _data.name --名
        result.head = _data.head --头像
        result.frame = _data.frame --头像框
        result.facebook = _data.facebook --facebook头像
        result.robotHead = _data.robotHead --robot头像
    end
    return result
end

--[[
    message FlameClashRival {
        optional int32 points = 1; //总积分
        optional string roomBuff = 2; //房间奖励增加buff
        optional FlameClashUserInfo userInfo = 3; //玩家信息
    }
]]
function FrostFlameClashData:parseRivalInfo(_data)
    local result = {}
    if _data then
        result.points = _data.points --总积分
        result.roomBuff = _data.roomBuff --房间奖励增加buff
        result.userInfo = self:parseUserInfo(_data.userInfo)
        result.userInfo.points = result.points
    end
    return result
end

--[[
    message FlameClashStageReward {
    optional int32 stage = 1; //胜场
    optional string type = 2; //类型 COINS ITEM
    optional int64 coins = 3; //金币
    repeated ShopItem item = 4; //物品
    optional bool reward = 5; //是否已领取
}
]]
function FrostFlameClashData:parseStageReward(_data)
    local result = {}
    for i, v in ipairs(_data) do
        local oneReward = {}
        oneReward.stage = v.stage --胜场
        oneReward.type = v.type --类型 COINS ITEM
        oneReward.coins = tonumber(v.coins) --金币
        oneReward.item = self:parseItemsData(v.item) -- 物品
        oneReward.reward = v.reward --是否已领取
        result[i] = oneReward
    end
    return result
end

-- 解析道具数据
function FrostFlameClashData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

--[[
    message FlameClashBuffReward {
        optional int32 num = 1; //进度值
        optional string multiple = 2; //buff倍数 0.1
    }
]]
function FrostFlameClashData:parseBuffReward(_data)
    local result = {}
    for i, v in ipairs(_data) do
        local oneReward = {}
        oneReward.num = v.num --进度值
        oneReward.multiple = tonumber(v.multiple) * 100 --buff倍数 0.1 * 100
        result[i] = oneReward
    end
    return result
end

--[[
    message FlameClashPointReward {
        optional int32 point = 1; //积分值
        optional int64 coins = 2; //金币数
    }
]]
function FrostFlameClashData:parsePointReward(_data)
    local result = {}
    for i, v in ipairs(_data) do
        local oneReward = {}
        oneReward.point = tonumber(v.point) --积分值
        oneReward.coins = tonumber(v.coins) --金币数
        result[i] = oneReward
    end
    return result
end

function FrostFlameClashData:getUserInfo()
    return self.p_userInfo or {}
end

function FrostFlameClashData:getRivalInfo()
    return self.p_rivalData or {}
end

function FrostFlameClashData:getStageRewards()
    return self.p_stageRewards or {}
end

-- 获得净胜次数
function FrostFlameClashData:getGoalDifference()
    return self.p_goalDifference ,self.p_goalDifference_front
end

function FrostFlameClashData:clearFrontGoalDifference()
    self.p_goalDifference_front = self.p_goalDifference
end

-- 获得游戏总次数
function FrostFlameClashData:getGameTimes()
    return self.p_gameTimes or 0
end

-- 获得游戏失败次数
function FrostFlameClashData:getFailTimes()
    return self.p_failTimes or 0
end

-- 获得游戏累计胜利次数
function FrostFlameClashData:getWinTimes()
    local gameTimes = self:getGameTimes()
    local failTimes = self:getFailTimes()
    return gameTimes - failTimes
end

-- 获得领取的房间金币值
function FrostFlameClashData:getRoomCoins()
    return self.p_roomCoins or 0
end

-- 获得金币值 1积分 = xx coins
function FrostFlameClashData:getSignPointCoins()
    return self.p_signPointCoin or 0
end

-- 获得房间总积分
function FrostFlameClashData:getRoomPoints()
    local myPoints = self.p_points or 0
    local rivalPoints = self.p_rivalData.points or 0
    local totalPoints = myPoints + rivalPoints
    return totalPoints
end

-- 获得积分进度对应金币值 {}
function FrostFlameClashData:getPointCoins()
    return self.p_pointCoins or {}
end

-- 获得jackpot数据 通过房间总积分进度 {coins = xx, index = xx, points = xx}
function FrostFlameClashData:getJackpotData()
    local totalPoints = self:getRoomPoints()
    local pointCoins = self:getPointCoins()
    local jackpot = {coins = 0, index = 1, points = 0}
    if #pointCoins > 0 then
        local isFind = false
        for i, v in ipairs(pointCoins) do
            if v.point <= totalPoints then
                jackpot.coins = v.coins
                jackpot.index = i
                jackpot.points = v.point
                isFind = true
            end
        end
        if not isFind then
            local pointCoins = pointCoins[1]
            jackpot = {coins = pointCoins.coins, index = 1, points = pointCoins.point}
        end
    end
    return jackpot
end

-- 获得距离下一等级的积分（下一奖励积分 - 当前房间总积分）
function FrostFlameClashData:getNextPoints()
    local totalPoints = self:getRoomPoints()
    local pointCoins = self:getPointCoins()
    local nextPoints = 0
    local points = 0
    if #pointCoins > 0 then
        local isFind = false
        for i, v in ipairs(pointCoins) do
            if v.point > totalPoints then
                nextPoints = v.point
                isFind = true
                break
            end
        end
        if not isFind then
            local pointCoins = pointCoins[1]
            nextPoints = pointCoins.point
        end
        points = math.max(nextPoints - totalPoints, 0)
    end
    return points
end

function FrostFlameClashData:getCurrentBattleLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self.p_endTimeAt - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function FrostFlameClashData:getSpinTimes()
    return self.p_spinTimes or 0
end

function FrostFlameClashData:getSpinMatchingTimes()
    return self.p_spinMatchingTimes or 0
end

function FrostFlameClashData:getSpinLeftTimes()
    local leftTime = self:getSpinMatchingTimes() - self:getSpinTimes()
    return leftTime
end

-- 获得自己的阵营   1 红火   2 蓝水
function FrostFlameClashData:getMyCamp()
    return  self.p_gameTimes %2 + 1
end

--当前状态 READY(准备)  MATCHING(匹配)  GAME(游戏中)  REWARD(结算)
function FrostFlameClashData:getBattleStateType()
    return stateToType[self.p_state] 
end

-- 净胜buff
function FrostFlameClashData:getGoalBuff()
    return self.p_goalBuff or "0" , self.p_goalBuff_Front or "0"
end

-- 净胜buff列表
function FrostFlameClashData:getGoalBuffs()
    return self.p_goalBuffs or {}
end

--匹配 剩余时间
function FrostFlameClashData:getMatchLeftTime()
    local leftTime = 0
    if self.p_state == "MATCHING" then
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        leftTime = self.p_matchingTimeAt / 1000 - curTime
        leftTime = leftTime > 0 and leftTime or 0
    end
    return leftTime
end

-- 比赛过期时间戳
function FrostFlameClashData:getEndTimeAt()
    return self.p_endTimeAt or 0
end
--总积分
function FrostFlameClashData:getMyPoints()
    return  self.p_points or 0
end

-------------------------------------------------------游戏状态切换-----------------------------------------------------
--第一次进入游戏 刷新数据 不记录状态切换
function FrostFlameClashData:setIsForEnterGame(isForEnterGame)
    self.p_isForEnterGame = not not isForEnterGame
end

function FrostFlameClashData:getIsStateChanged()
    if not self.p_state_front then
        self.p_state_front = self.p_state
    end

return (self.p_state_front ~= self.p_state),stateToType[self.p_state_front],stateToType[self.p_state]
end

function FrostFlameClashData:clearStateChanged()
    self.p_state_front = self.p_state
end

function FrostFlameClashData:getIsWillShowCoinsBar()
    if self.p_state ~= "GAME" then
        self:clearWillShowCoinsBar()
    end
    return self.m_pointCoinLevel_front ~= self.m_pointCoinLevel 
end

function FrostFlameClashData:clearWillShowCoinsBar()
    self.m_pointCoinLevel_front = self.m_pointCoinLevel
end

function FrostFlameClashData:getIsWillDoBattleEffect()
    if self.p_state ~= "GAME" then
        self:clearWillDoBattleEffect()
    end
    if self.m_willDoBattleEffect then
        local curTime = globalData.userRunData.p_serverTime / 1000
        if not self.m_battleEffect_CDTime then
            self.m_battleEffect_CDTime = curTime + 2 * 60
        elseif curTime < self.m_battleEffect_CDTime then
            return false
        else
            self.m_battleEffect_CDTime = curTime + 2 * 60
        end
    end
    return self.m_willDoBattleEffect 
end

function FrostFlameClashData:clearWillDoBattleEffect()
    self.m_willDoBattleEffect = false
end

function FrostFlameClashData:isWillShowResultLayer()
    return self.p_state == "REWARD" -- REWARD(结算)
end

function FrostFlameClashData:getWinOrLose()
    local result = 1 -- 赢
    if not self.p_rewardRoom then
        result = 2 -- 输
    end
    local myPoints = self.p_points or 0
    local rivalPoints = self.p_rivalData.points or 0
    if myPoints < rivalPoints then
        result = 2 -- 输
    end
    return result
end

function FrostFlameClashData:isGaming()
    return self.p_state == "GAME" -- GAME(游戏中)
end

--spin 获得点数
function FrostFlameClashData:getAddPoints()
    return self.p_addPoints
end

function FrostFlameClashData:clearAddPoints()
    self.p_addPoints = 0
end

function FrostFlameClashData:clearFrontGoalBuff()
    self.p_goalBuff_Front = self.p_goalBuff
end

function FrostFlameClashData:getStagePercent()
    local percent = 0
    local stageRewards = self:getStageRewards()
    if #stageRewards > 0 then
        local singlePercent = 100 / #stageRewards
        local maxStage = stageRewards[#stageRewards].stage or 1
        local preStage = 0
        local nextStage = maxStage
        local curStage = self:getWinTimes()
        if curStage >= maxStage then
            percent = 100
        else
            for i, v in ipairs(stageRewards) do
                if curStage > v.stage then
                    percent = percent + singlePercent
                    preStage = v.stage
                else
                    nextStage = v.stage
                    break
                end
            end
            percent = percent + math.floor((curStage - preStage) / (nextStage - preStage) * singlePercent)
        end
    end
    return percent
end

function FrostFlameClashData:isWillRefreshRivalPoints()
    return self.m_refreshRivalData
end

function FrostFlameClashData:isCannotDoReady()
    local result = false
    if self:getLeftTime() <= 20*60 and self.p_state == "READY" then
        result = true
    end
    return result
end
return FrostFlameClashData
