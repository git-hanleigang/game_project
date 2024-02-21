local UserRate = class("UserRate")
local GLOBALKEY = "global"

UserRate.m_levelsInfo = nil
UserRate.m_levelName = nil

function UserRate:ctor()
    self.m_levelsInfo = {}
end

--释放资源
function UserRate:purge()
end

--进入关卡
function UserRate:enterLevel(level)
    self.m_levelName = level
    if not self.m_levelsInfo[level] then
        self.m_levelsInfo[level] = self:readInfoData(level)
    end

    if not self.m_levelsInfo[GLOBALKEY] then
        self.m_levelsInfo[GLOBALKEY] = self:readInfoData(GLOBALKEY)
    end
end

--离开关卡 或者 进入后台
function UserRate:leaveLevel()
    if not self.m_levelName then
        return
    end
    self:saveInfoData(self.m_levelName)
    self:saveInfoData(GLOBALKEY)
end

--清理关卡数据
function UserRate:clearData()
    self.m_levelsInfo[self.m_levelName].usedCoins = 0
    self.m_levelsInfo[self.m_levelName].coins = 0
    self.m_levelsInfo[self.m_levelName].spinCount = 0
    self.m_levelsInfo[self.m_levelName].freeSpinCount = 0
    self.m_levelsInfo[self.m_levelName].freeSpinCoins = 0
    self.m_levelsInfo[self.m_levelName].rate = 0
    self:saveInfoData(self.m_levelName)
end
--清理全局数据
function UserRate:clearGlobalData()
    self.m_levelsInfo[GLOBALKEY].usedCoins = 0
    self.m_levelsInfo[GLOBALKEY].coins = 0
    self.m_levelsInfo[GLOBALKEY].spinCount = 0
    self.m_levelsInfo[GLOBALKEY].freeSpinCount = 0
    self.m_levelsInfo[GLOBALKEY].freeSpinCoins = 0
    self.m_levelsInfo[GLOBALKEY].rate = 0
    self:saveInfoData(GLOBALKEY)
end

function UserRate:readInfoData(level)
    local info = {}
    info.usedCoins = gLobalDataManager:getNumberByField("UserRate_" .. level .. "_usedCoins", 0)
    info.coins = gLobalDataManager:getNumberByField("UserRate_" .. level .. "_coins", 0)
    info.spinCount = gLobalDataManager:getNumberByField("UserRate_" .. level .. "_spinCount", 0)
    info.freeSpinCount = gLobalDataManager:getNumberByField("UserRate_" .. level .. "_freeSpinCount", 0)
    info.freeSpinCoins = gLobalDataManager:getNumberByField("UserRate_" .. level .. "_freeSpinCoins", 0)
    if info.usedCoins == 0 or info.coins == 0 then
        info.rate = 0
    else
        info.rate = info.coins / info.usedCoins
    end
    return info
end

function UserRate:saveInfoData(level)
    local info = self.m_levelsInfo[level]

    gLobalDataManager:setNumberByField("UserRate_" .. level .. "_usedCoins", "" .. info.usedCoins)
    gLobalDataManager:setNumberByField("UserRate_" .. level .. "_coins", "" .. info.coins)
    gLobalDataManager:setNumberByField("UserRate_" .. level .. "_spinCount", info.spinCount)
    gLobalDataManager:setNumberByField("UserRate_" .. level .. "_freeSpinCount", info.freeSpinCount)
    gLobalDataManager:setNumberByField("UserRate_" .. level .. "_freeSpinCoins", info.freeSpinCoins)
    gLobalDataManager:setNumberByField("UserRate_" .. level .. "_rate", info.rate)
end

--获得关卡数据
function UserRate:getLevelInfo()
    return self.m_levelsInfo[self.m_levelName]
end

--获得累积数据
function UserRate:getGlobalInfo()
    return self.m_levelsInfo[GLOBALKEY]
end

--spin消耗的金币
function UserRate:pushUsedCoins(value)
    -- value 是 LongNumber 类型
    -- self:push("usedCoins", tonumber("" .. value))
    -- self:updateRate()
end
--增加的金币
function UserRate:pushCoins(value)
    -- self:push("coins", value)
    -- self:updateRate()
end
--spin次数
function UserRate:pushSpinCount(value)
    -- self:push("spinCount", value)
end
--freespin次数
function UserRate:pushFreeSpinCount(value)
    -- self:push("freeSpinCount", value)
end
--freespin增加的金币
function UserRate:pushFreeSpinCoins(value)
    -- self:push("freeSpinCoins", value)
end

--更新赔率
function UserRate:updateRate()
    if not self.m_levelName then
        return
    end
    local info = self:getLevelInfo(self.m_levelName)
    local globalInfo = self:getGlobalInfo()

    if info.usedCoins == 0 or info.coins == 0 then
        info.rate = 0
    else
        info.rate = info.coins / info.usedCoins
    end

    if globalInfo.usedCoins == 0 or globalInfo.coins == 0 then
        globalInfo.rate = 0
    else
        globalInfo.rate = globalInfo.coins / globalInfo.usedCoins
    end
end

--放到缓存
function UserRate:push(key, value)
    if not self.m_levelName then
        return
    end
    local info = self:getLevelInfo(self.m_levelName)
    local globalInfo = self:getGlobalInfo()
    info[key] = info[key] + value
    globalInfo[key] = globalInfo[key] + value
end
return UserRate
