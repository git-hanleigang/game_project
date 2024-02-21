--[[
    公共jackpot网络数据解析
]]
local CommonJackpotLevelData = import(".CommonJackpotLevelData")
local CommonJackpotPoolData = import(".CommonJackpotPoolData")
local CommonJackpotUserData = import(".CommonJackpotUserData")

-- local BaseGameModel = require("GameBase.BaseGameModel")`
local BaseActivityData = require "baseActivity.BaseActivityData"
local CommonJackpotData = class("CommonJackpotData", BaseActivityData)

function CommonJackpotData:ctor()
    CommonJackpotData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CommonJackpot)
    self.m_showExpireAt = nil
end

function CommonJackpotData:isRunning()
    if not CommonJackpotData.super.isRunning(self) then
        return false
    end
    local leftTime = self:getLeftTime()
    if leftTime and leftTime <= 0 then
        return false
    end
    return true
end

function CommonJackpotData:parseData(_netData)
    CommonJackpotData.super.parseData(self, _netData)
end

function CommonJackpotData:parseEnterLevelData(_netData, _levelName)
    self.p_levels = {}
    if _netData.levels and #_netData.levels > 0 then
        for i = 1, #_netData.levels do
            local level = CommonJackpotLevelData:create()
            level:parseData(_netData.levels[i])
            table.insert(self.p_levels, level)
        end
    end

    self.p_coinsPool = {}
    if _netData.coinsPool and #_netData.coinsPool > 0 then
        for i = 1, #_netData.coinsPool do
            local pool = CommonJackpotPoolData:create()
            pool:parseData(_netData.coinsPool[i])
            table.insert(self.p_coinsPool, pool)
        end
    end

    self.m_levelName = _levelName
end

function CommonJackpotData:parseSpinData(_netData)
    -- spin时，同步了当前档位的数据
    -- 这个值要同步p_levels中对应的数据
    if _netData.curLevel ~= nil and _netData.curLevel.key ~= nil then
        local level = self:getLevelDataByKey(_netData.curLevel.key)
        if level then
            level:parseData(_netData.curLevel)
        end
    end

    self.p_coinsPool = {}
    if _netData.coinsPool and #_netData.coinsPool > 0 then
        for i = 1, #_netData.coinsPool do
            local pool = CommonJackpotPoolData:create()
            pool:parseData(_netData.coinsPool[i])
            table.insert(self.p_coinsPool, pool)
        end
    end

    self.p_jillionUser = nil
    if _netData.jillionUser then
        local userData = CommonJackpotUserData:create()
        userData:parseData(_netData.jillionUser)
        self.p_jillionUser = userData
    end

    self.p_gameUser = nil
    if _netData.gameUser then
        local userData = CommonJackpotUserData:create()
        userData:parseData(_netData.gameUser)
        self.p_gameUser = userData
    end
end

function CommonJackpotData:getLevelName()
    return self.m_levelName
end

function CommonJackpotData:getLevels()
    return self.p_levels
end

function CommonJackpotData:getPools()
    return self.p_coinsPool
end

-- 第一个中了respin的人，奖励放在最顶部第九个位置
function CommonJackpotData:getWinUserData(_levelKey)
    if self.p_jillionUser then
        if self.p_jillionUser:getKey() == _levelKey then
            return self.p_jillionUser
        end
    end
    return nil
end

-- 将顶部奖励赢走的人，入口上显示气泡
function CommonJackpotData:getTokenUserData()
    return self.p_gameUser
end

function CommonJackpotData:parsePlayData(_netData)
    self.p_playData = {}
    self.p_playData.coins = tonumber(_netData.coins)
    -- self.p_playData.p_rewards = {}
    -- if _netData.rewards and #_netData.rewards > 0 then
    --     for i = 1, #_netData.rewards do
    --         table.insert(self.p_playData.p_rewards, tonumber(_netData.rewards[i]))
    --     end
    -- end

    self:setPlayWinIndex()
end

function CommonJackpotData:getPlayData()
    return self.p_playData
end

-- 从本档位的rswincount中找到coins所在的index
function CommonJackpotData:setPlayWinIndex()
    local winIndex = nil
    local levelData = self:getCurBetLevelData()
    if levelData then
        local key = levelData:getKey()
        local winUserData = self:getWinUserData(key)
        if winUserData and winUserData:getCoins() == self.p_playData.coins then
            winIndex = CommonJackpotCfg.RESPIN_SHOW_MAX + 1
        else
            winIndex = levelData:getWinAmountIndexByCoin(self.p_playData.coins)
        end
    end
    self.m_playWinIndex = winIndex
    -- self.m_playWinIndex = 9
end

function CommonJackpotData:getPlayWinIndex()
    return self.m_playWinIndex
end

-- 获取结算的金币
function CommonJackpotData:getPlayCoins()
    return self.p_playData and self.p_playData.coins or 0
end

function CommonJackpotData:onRegister()
end

function CommonJackpotData:checkOpenLevel()
    if not CommonJackpotData.super.checkOpenLevel(self) then
        return false
    end
    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end
    local needLevel = self:getUnlockLevel()
    if curLevel < needLevel then
        return false
    end
    return true
end

function CommonJackpotData:clearCurLevelWinAmount()
    local levelData = self:getCurBetLevelData()
    if levelData then
        levelData:clearWinAmount()
    end
end

-- 进关卡必须给的数据，如果没有给数据，默认关卡没有公共Jackpot
function CommonJackpotData:isEnterLevelEffective()
    if self.p_levels and #self.p_levels > 0 then
        return true
    end
    return false
end

function CommonJackpotData:getLevelDataByKey(_key)
    if self.p_levels and #self.p_levels > 0 then
        for i = 1, #self.p_levels do
            local level = self.p_levels[i]
            if level:getKey() == _key then
                return level
            end
        end
    end
    return nil
end

function CommonJackpotData:getLevelDataByName(_name)
    if self.p_levels and #self.p_levels > 0 then
        for i = 1, #self.p_levels do
            local level = self.p_levels[i]
            if level:getName() == _name then
                return level
            end
        end
    end
    return nil
end

function CommonJackpotData:getLevelDataByBet(_bet)
    if self.p_levels and #self.p_levels > 0 then
        local megaLevelData = self:getLevelDataByName(CommonJackpotCfg.LEVEL_NAME.Mega)
        local superLevelData = self:getLevelDataByName(CommonJackpotCfg.LEVEL_NAME.Super)
        local normalLevelData = self:getLevelDataByName(CommonJackpotCfg.LEVEL_NAME.Normal)
        local megaMinBet = megaLevelData:getMinBet()
        local megaMaxBet = megaLevelData:getMaxBet()
        local superMinBet = superLevelData:getMinBet()
        local superMaxBet = superLevelData:getMaxBet()
        
        -- 检查数据有效性
        if megaMinBet > megaMaxBet then
            util_sendToSplunkMsg("CommonJackpotData", "ERROR:megaMinBet > megaMaxBet")
        elseif megaMaxBet > superMinBet then
            util_sendToSplunkMsg("CommonJackpotData", "ERROR:megaMaxBet > superMinBet")
        elseif superMinBet > superMaxBet then
            util_sendToSplunkMsg("CommonJackpotData", "ERROR:superMinBet > superMaxBet")
        end

        if _bet < megaMinBet then
            return normalLevelData
        elseif _bet >= megaMinBet and _bet <= megaMaxBet then
            return megaLevelData
        elseif _bet >= superMinBet then
            return superLevelData
        else
            release_print("!!! check bet list is legal, bet=".._bet)
            return normalLevelData
        end
    end
    -- assert(false, "配置表数据有问题！！！")
end

-- 一个档位只有一个pool
function CommonJackpotData:getPoolByName(_name)
    if self.p_coinsPool and #self.p_coinsPool > 0 then
        for i = 1, #self.p_coinsPool do
            local pool = self.p_coinsPool[i]
            if _name == pool:getName() then
                return pool
            end
        end
    end
    return nil
end

function CommonJackpotData:getPoolByKey(_key)
    if self.p_coinsPool and #self.p_coinsPool > 0 then
        for i = 1, #self.p_coinsPool do
            local pool = self.p_coinsPool[i]
            if _key == pool:getKey() then
                return pool
            end
        end
    end
    return nil
end

function CommonJackpotData:getCurBetLevelData()
    local bet = self:getCurBetVal()
    return self:getLevelDataByBet(bet)
end

-- 当前关卡的bet金币
function CommonJackpotData:getCurBetVal()
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_betsData then
        return globalData.slotRunData:getCurTotalBet() or 0
    end
    return 0
end

-- 当前关卡的最大bet金币
function CommonJackpotData:getMaxBetVal()
    local maxBetData = globalData.slotRunData:getMaxBetData()
    return maxBetData.p_totalBetValue or 0
end

-- 开启等级
function CommonJackpotData:getUnlockLevel()
    return 0 -- globalData.constantData.CHALLENGE_OPEN_LEVEL or 0
end

return CommonJackpotData
