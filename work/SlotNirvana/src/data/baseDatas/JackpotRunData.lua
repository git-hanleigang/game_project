--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-12 14:15:29
--

local JackpotRunData = class("JackpotRunData")
local BetConfigData = require "data.baseDatas.BetConfigData"
require("socket")
JackpotRunData.p_expireAt = nil -- 失效时间
JackpotRunData.p_maxTotalBets = nil
JackpotRunData.p_jackpotConfigDatas = nil --jackpot基础配置数据

JackpotRunData.m_jackpotPools = nil --jackpot
JackpotRunData.m_jackpotWeights = nil --权重
JackpotRunData.m_jackpotWeightInfos = nil
JackpotRunData.m_userID = nil --检测数据和用户是否匹配

function JackpotRunData:ctor()
end

--读取jackpot基础配置信息 21.11.29 : 修改读取方式 .csv -> .lua
function JackpotRunData:parseJackpotConfig()
    self.p_jackpotConfigDatas = {}
    self.m_jackpotWeights = {}
    self.m_jackpotWeightInfos = {}
    -- 读出lua版的配置
    local jackpotConfig = util_require("data.JackpotConfig")

    for _levelId, _jpList in pairs(jackpotConfig) do
        for _jpId, _jpData in pairs(_jpList) do
            local configData = {}
            configData.p_gameID = tonumber(_levelId) --关卡id
            configData.p_jackpotID = tonumber(_jpId) --jackpotid
            configData.p_name = _jpData[1] --jackpot名字
            configData.p_multiple = tonumber(_jpData[2]) --jackpot倍率
            configData.p_initMin = tonumber(_jpData[3]) --初始最小值
            configData.p_initMax = tonumber(_jpData[4]) --初始最大值
            configData.p_increase = tonumber(_jpData[5]) --增加值
            configData.p_resetMin = tonumber(_jpData[6]) --重置最小值
            configData.p_resetMax = tonumber(_jpData[7]) --重置最大值
            configData.p_resetTime = tonumber(_jpData[8]) --重置参考时间
            configData.p_notifyWeight = tonumber(_jpData[9]) --推送权重

            if _jpData[1] ~= "" and _jpData[2] ~= "" then
                if configData.p_notifyWeight and configData.p_notifyWeight > 0 then
                    self.m_jackpotWeights[#self.m_jackpotWeights + 1] = configData.p_notifyWeight
                    self.m_jackpotWeightInfos[#self.m_jackpotWeightInfos + 1] = {
                        gameID = configData.p_gameID,
                        jackpotID = configData.p_jackpotID
                    }
                end
                if not self.p_jackpotConfigDatas[configData.p_gameID] then
                    self.p_jackpotConfigDatas[configData.p_gameID] = {}
                end
                self.p_jackpotConfigDatas[configData.p_gameID][configData.p_jackpotID] = configData
            end
        end
    end
end

--[[
    @desc: 解析当前等级最大 max bet ，
    time:2019-04-11 23:07:59
    --@totalBets: 
    @return:
]]
function JackpotRunData:parseMaxToalBets(jackpotsData)
    local totalBets = jackpotsData.maxBets

    if not self.p_maxTotalBets then
        self.p_maxTotalBets = {}
    end

    for i = 1, #totalBets do
        local data = totalBets[i]
        local betConfigData = BetConfigData:create()
        betConfigData:parseData(data)
        self.p_maxTotalBets[betConfigData.p_gameID] = betConfigData
    end
    print("...")
end
--[[
    @desc: 根据当前推荐bet 档位信息处理最大档位信息
    time:2019-04-12 14:19:38
    @param machineID 关卡id
    @param machineRecBets 各个推荐bet 档位信息
    @return:
]]
function JackpotRunData:updateMaxBetsWithRecBets(machineID, machineRecBets)
    if not self.p_maxTotalBets then
        return
    end
    local betData = self.p_maxTotalBets[machineID]
    if betData then
        local maxBetData = machineRecBets[#machineRecBets]
        if maxBetData and maxBetData.p_totalBetValue > betData.p_totalBetValue then
            betData.p_gameID = maxBetData.p_gameID
            betData.p_multiple = maxBetData.p_multiple
            betData.p_totalBetValue = maxBetData.p_totalBetValue
            betData.p_unlockAt = maxBetData.p_unlockAt
            betData.p_unlockFeature = maxBetData.p_unlockFeature
            betData.p_unlockJackpot = maxBetData.p_unlockJackpot
            betData.p_betId = maxBetData.p_betId
            betData.p_hideAt = maxBetData.p_hideAt
        end
    end
end

--根据totalbet 和倍数 获取最终金额
function JackpotRunData:getTotalPool(gameID, pool)
    if not self.p_maxTotalBets[gameID] or not self.p_maxTotalBets[gameID].p_totalBetValue then
        -- release_print("JackpotRunData:getTotalPool error gameID"..gameID)
        return 0
    end
    local totalBet = self.p_maxTotalBets[gameID].p_totalBetValue
    local totalPool = math.floor(pool * totalBet)
    return totalPool
end

--获取jackpot索引找不到返回第一个
function JackpotRunData:getJackpotIndex(gameID, jackpotID)
    local jackpotPools = self:getJackpotList(gameID)
    if jackpotPools then
        for index = 1, #jackpotPools do
            local poolData = jackpotPools[index]
            local configData = poolData.p_configData
            if jackpotID == configData.p_jackpotID then
                return index
            end
        end
    end
    return -1
end

--读取jackpot信息
function JackpotRunData:readJackpotData()
    --判断账户是否相同
    if self.m_userID and self.m_userID == globalData.userRunData.userUdid then
        return
    end
    self.m_userID = globalData.userRunData.userUdid
    local jsonStr = gLobalDataManager:getStringByField(globalData.userRunData.userUdid .. "_jackpot", "")
    if jsonStr ~= "" then
        self.m_jackpotPools = cjson.decode(jsonStr)
    end
    if not self.m_jackpotPools then
        self:initFristJackpotPools()
    end
    --刷新jackpot需要重置部分超过时间的
    for gameId, poolDatas in pairs(self.m_jackpotPools) do
        for i = 1, #poolDatas do
            self:refreshJackpotPool(poolDatas[i], false)
        end
    end
end
--保存jackpot信息
function JackpotRunData:saveJackpotData()
    local jsonStr = cjson.encode(self.m_jackpotPools)
    gLobalDataManager:setStringByField(globalData.userRunData.userUdid .. "_jackpot", jsonStr)
end
--初始化首次jackpot
function JackpotRunData:initFristJackpotPools()
    self.m_jackpotPools = {}
    for gameId, jackpotConfigDatas in pairs(self.p_jackpotConfigDatas) do
        local poolDatas = {}
        for jackpotId, configData in pairs(jackpotConfigDatas) do
            local newPoolData = {}
            self:resetJackpotPool(newPoolData, configData)
            poolDatas[#poolDatas + 1] = newPoolData
        end
        self:sordPool(poolDatas)
        self.m_jackpotPools[gameId] = poolDatas
    end
end
--重置jackpot档位信息
function JackpotRunData:resetJackpotPool(poolData, configData)
    if not poolData or not configData then
        return
    end

    if not configData.p_increase or configData.p_increase <= 0 then
        poolData.p_isFresh = false --jackpot倍率是否会发生变化
    else
        poolData.p_isFresh = true --jackpot倍率是否会发生变化
        poolData.p_initTime = socket.gettime() --初始化数据时间
        poolData.p_initPool = math.random(configData.p_initMin * 100, configData.p_initMax * 100) * 0.01 --初始奖池
        poolData.p_resetPool = math.random(configData.p_resetMin * 100, configData.p_resetMax * 100) * 0.01 --重置奖池
    end
    poolData.p_configData = configData --配置数据重置时使用
    poolData.p_order = tonumber(configData.p_jackpotID)
    --jackpot档位排序 目前使用id大小排序、也可以使用默认倍率排序
end
--根据order排序
function JackpotRunData:sordPool(poolDatas)
    table.sort(
        poolDatas,
        function(a, b)
            return a.p_order > b.p_order
        end
    )
end
--获得关卡jackpot数据列表
function JackpotRunData:getJackpotList(gameID)
    if not gameID or not self.m_jackpotPools then
        return
    end
    return self.m_jackpotPools[gameID]
end

--刷新倍率
function JackpotRunData:getJackpotMultiple(poolData, isNotify)
    local currentPool = 0
    local extraPool = 0
    local configData = poolData.p_configData
    --根据时间和增量刷新
    if poolData.p_isFresh then
        --间隔时间
        local spanTime = (socket.gettime() - poolData.p_initTime)
        --根据时间计算jackpot奖池
        currentPool = poolData.p_initPool + spanTime * configData.p_increase
        if currentPool < 0 or currentPool > poolData.p_resetPool then
            --通知他人中奖
            if isNotify then
                --没有权重不通知
                local weight = configData.p_notifyWeight
                if weight and weight > 0 then
                    self:notifyOtherJackpot(configData.p_gameID, configData.p_jackpotID, poolData.p_resetPool)
                end
            end
            --重置
            self:resetJackpotPool(poolData, configData)
            currentPool = poolData.p_initPool
        end
        extraPool = currentPool - configData.p_multiple
    else
        --不刷新使用基础倍率
        currentPool = configData.p_multiple
    end
    return currentPool, extraPool
end

--刷新jackpot奖池数据
function JackpotRunData:refreshJackpotPool(poolData, isNotify, totalBet)
    if not poolData then
        return 0
    end
    local configData = poolData.p_configData

    if type(configData) == "number" then
        return 0
    end

    local currentPool, extraPool = self:getJackpotMultiple(poolData, isNotify)
    local totalReward = 0
    local baseReward = 0
    local extraPool = 0
    if not totalBet then
        --大厅显示totalbet
        totalReward = self:getTotalPool(configData.p_gameID, currentPool)
    else
        --游戏中根据当前totalbet刷新
        totalReward = math.floor(currentPool * totalBet)
        baseReward = math.floor(configData.p_multiple * totalBet)
        extraPool = math.floor(extraPool * totalBet)
    end
    return totalReward, baseReward, extraPool
end

--通知中奖信息
function JackpotRunData:notifySelfJackpot(coins, index)
    local jackpotPools = self:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return
    end
    --重置jackpot档位
    local poolData = jackpotPools[index]
    local configData = poolData.p_configData
    local weight = configData.p_notifyWeight
    self:resetJackpotPool(poolData, configData)
    --没有权重不通知
    if not weight or weight == 0 then
        return
    end
    globalNotifyNodeManager:showNewSelfNotify(coins, index)
end
--根据权重随机中jackpot
function JackpotRunData:notifyRandomJackpot()
    --根据权重随机关卡和jackpot档位
    local weightIndex = util_getIndexForWeightList(self.m_jackpotWeights)
    local info = self.m_jackpotWeightInfos[weightIndex]
    if not info then
        return
    end
    local jackpotPools = self:getJackpotList(info.gameID)
    local index = self:getJackpotIndex(info.gameID, info.jackpotID)
    if not jackpotPools[index] then
        return
    end
    local poolData = jackpotPools[index]
    local configData = poolData.p_configData
    --获得奖金
    local coins = self:refreshJackpotPool(poolData, false)
    --重置jackpot档位
    self:resetJackpotPool(poolData, configData)
    --通知他人中奖
    self:notifyOtherJackpot(info.gameID, info.jackpotID, coins)
end
--通知他人档位
function JackpotRunData:notifyOtherJackpot(gameID, jackpotID, jackpotPool)
    globalNotifyNodeManager:showOtherNotify(gameID, jackpotID, jackpotPool)
end
return JackpotRunData
