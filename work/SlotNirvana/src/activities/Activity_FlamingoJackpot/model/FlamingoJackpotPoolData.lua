--[[
    jackpot 奖池
]]
local FlamingoJackpotPoolData = class("FlamingoJackpotPoolData")

function FlamingoJackpotPoolData:ctor()
end

function FlamingoJackpotPoolData:parseData(_poolData, _isDelaySync)
-- 客户端的每次变化时间间隔
    local intervalFrameTime = FlamingoJackpotCfg.JACKPOT_FRAME 

    self.p_type = _poolData.type
    self.p_value = tonumber(_poolData.value or 0)
    self.p_offset = math.floor(tonumber(_poolData.offset or 0) * intervalFrameTime)

    -- 初始化事件
    if self.m_lastValue == nil and self.m_lastOffset == nil then
        self.m_lastValue = self.p_value
        self.m_lastOffset = self.p_offset
        G_GetMgr(ACTIVITY_REF.FlamingoJackpot):getPoolCtr():clearSyncTime(self.p_type)
    end

    -- 同步
    if not _isDelaySync then
        self:syncPoolData()
    end
end

function FlamingoJackpotPoolData:getType()
    return self.p_type
end

function FlamingoJackpotPoolData:getValue()
    return self.m_lastValue
end

function FlamingoJackpotPoolData:getOffset()
    return self.m_lastOffset
end

-- 用作同步jackpot
function FlamingoJackpotPoolData:syncPoolData()
    local isClearSync = false
    if self.m_lastValue ~= self.p_value or self.m_lastOffset ~= self.p_offset then
        self.m_lastValue = self.p_value
        self.m_lastOffset = self.p_offset
        isClearSync = true
    end
    if isClearSync then
        G_GetMgr(ACTIVITY_REF.FlamingoJackpot):getPoolCtr():clearSyncTime(self.p_type)
    end
end

return FlamingoJackpotPoolData