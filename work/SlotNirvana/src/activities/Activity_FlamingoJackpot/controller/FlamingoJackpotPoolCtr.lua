--[[
    统一管理 金币jackpot
]]
local FlamingoJackpotPoolCtr = class("FlamingoJackpotPoolCtr", BaseSingleton)

function FlamingoJackpotPoolCtr:init()
    self:initSyncTimes()
    self:startTick()
end

function FlamingoJackpotPoolCtr:initSyncTimes()
    self.m_syncTimes = {}
    for _,_jackpotType in pairs(FlamingoJackpotCfg.JackpotType) do
        self.m_syncTimes[_jackpotType] = 0
    end
end

function FlamingoJackpotPoolCtr:clearSyncTime(_jackpotType)
    if _jackpotType and self.m_syncTimes[_jackpotType] ~= nil then
        self.m_syncTimes[_jackpotType] = 0
    end
end

function FlamingoJackpotPoolCtr:startTick()
    if self.m_schedule ~= nil then
        scheduler.unscheduleGlobal(self.m_schedule)
        self.m_schedule = nil
    end
    -- 播放进度条动画
    local tick = 0
    self.m_schedule =
        scheduler.scheduleUpdateGlobal(
        function(dt)
            tick = tick + dt
            -- 0.08帧触发事件
            if tick >= FlamingoJackpotCfg.JACKPOT_FRAME then
                tick = 0
                self:accSyncTimes()
            end
        end
    )
end

-- 累加时间
function FlamingoJackpotPoolCtr:accSyncTimes()
    for _jackpotType,_ in pairs(self.m_syncTimes) do
        self.m_syncTimes[_jackpotType] = (self.m_syncTimes[_jackpotType] or 0) + FlamingoJackpotCfg.JACKPOT_FRAME
    end    
end

function FlamingoJackpotPoolCtr:getSyncTime(_jackpotType)
    return self.m_syncTimes[_jackpotType] or 0
end

return FlamingoJackpotPoolCtr