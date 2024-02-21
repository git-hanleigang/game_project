--[[
    jackpot 奖池
]]
local CommonJackpotPoolData = class("CommonJackpotPoolData")

function CommonJackpotPoolData:ctor()
end

function CommonJackpotPoolData:parseData(_poolData)
    self.p_key = _poolData.key
    self.p_name = _poolData.name
    self.p_initValue = tonumber(_poolData.value)
    self.p_offset = tonumber(_poolData.offset)

    self:initSyncTime()
end

function CommonJackpotPoolData:getKey()
    return self.p_key
end

function CommonJackpotPoolData:getName()
    return self.p_name
end

function CommonJackpotPoolData:getValue()
    return self.p_initValue
end

function CommonJackpotPoolData:getOffset()
    return self.p_offset
end

-- 用作同步jackpot
function CommonJackpotPoolData:initSyncTime()
    -- print("---- initSyncTime ----", self.p_key, self.m_lastInitValue, self.p_initValue, self.m_lastOffset, self.p_offset)
    local isClearSync = false
    if self.m_lastInitValue == nil then
        self.m_lastInitValue = self.p_initValue
        isClearSync = true
    end
    if self.m_lastOffset == nil then
        self.m_lastOffset = self.p_offset
        isClearSync = true
    end
    if self.m_lastInitValue ~= self.p_initValue or self.m_lastOffset ~= self.p_offset then
        self.m_lastInitValue = self.p_initValue
        self.m_lastOffset = self.p_offset
        isClearSync = true
    end
    if isClearSync then
        G_GetMgr(ACTIVITY_REF.CommonJackpot):getPoolCtr():clearSyncTime(self.p_key)
    end
end

return CommonJackpotPoolData
