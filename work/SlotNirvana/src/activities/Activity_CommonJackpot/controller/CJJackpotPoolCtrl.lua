--[[
    统一管理 金币jackpot
]]
local CJJackpotPoolCtrl = class("CJJackpotPoolCtrl", BaseSingleton)

function CJJackpotPoolCtrl:init()
    self:initSyncTimes()
    self:startTick()
end

function CJJackpotPoolCtrl:initSyncTimes()
    self.m_syncTimes = {}
    for k,v in pairs(CommonJackpotCfg.POOL_KEY) do
        self.m_syncTimes[v] = 0
    end
end

function CJJackpotPoolCtrl:clearSyncTime(_key)
    if _key and self.m_syncTimes[_key] ~= nil then
        self.m_syncTimes[_key] = 0
    end
end

function CJJackpotPoolCtrl:startTick()
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
            if tick >= CommonJackpotCfg.JACKPOT_FRAME then
                tick = 0
                self:accSyncTimes()
            end
        end
    )
end

-- 累加时间
function CJJackpotPoolCtrl:accSyncTimes()
    for k,v in pairs(self.m_syncTimes) do
        self.m_syncTimes[k] = (self.m_syncTimes[k] or 0) + CommonJackpotCfg.JACKPOT_FRAME
    end
end

function CJJackpotPoolCtrl:getSyncTime(_key)
    return self.m_syncTimes[_key] or 0
end

return CJJackpotPoolCtrl
