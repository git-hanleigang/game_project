--[[
    长时间不点击发送消息做操作
]]
local NOTOUCH = 5 -- 5秒不操作
local SHAKE_INTERVAL = 2 -- 2秒晃一个箱子
local CSMainTouchControl = class("CSMainTouchControl", BaseSingleton)
function CSMainTouchControl:ctor()
end

function CSMainTouchControl:init(_node)
end

function CSMainTouchControl:startTiming()
    self:clearTimer()
    self:startTimer()
end

function CSMainTouchControl:clearTiming()
    self:clearTimer()
end

function CSMainTouchControl:startTimer()
    local count = 0
    local shakeCount = 0
    self.m_timer =
        scheduler.scheduleGlobal(
        function()
            count = count + 1
            if count == NOTOUCH then
                self:doShake()
            elseif count > NOTOUCH then
                shakeCount = shakeCount + 1
                if shakeCount > SHAKE_INTERVAL then
                    shakeCount = 0
                    self:doShake()
                end
            end
        end,
        1
    )
end

function CSMainTouchControl:clearTimer()
    if self.m_timer ~= nil then
        scheduler.unscheduleGlobal(self.m_timer)
        self.m_timer = nil
    end
end

function CSMainTouchControl:doShake()
    gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_SHAKE_BOX)
end
return CSMainTouchControl
