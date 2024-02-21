local UserAction = class("UserAction")

function UserAction:ctor(obj,t,callFunc)
    self._t = t*0.001
    self._callFunc = callFunc

    local function onNodeEvent(event)
        if "exit" == event then
            self:stop()
        end
    end
    obj:registerScriptHandler(onNodeEvent)
    self._obj = obj
end

function UserAction:run()
    self._beginClock = 0
    self._i = 0
    local scheduler = cc.Director:getInstance():getScheduler()
    self.schedulerID =
        scheduler:scheduleScriptFunc(
        function(dt)
            if not self._obj or tolua.isnull(self._obj) then
                self:stop()
                return
            end
            self._i  = self._i + 1
            if self._beginClock - self._t >= 0 then
                self._callFunc(1)
                self:stop()
                return
            end
            self._callFunc(1 - (self._t - self._beginClock)/self._t)
            self._beginClock = self._beginClock + dt
        end,
        0,
        false
    )
    self._callFunc(0)
end

function UserAction:stop()
    if self.schedulerID then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self.schedulerID)
        self.schedulerID = nil
    end
    if not self._obj and tolua.isnull(self._obj) then
        return
    end
    self._callFunc(1)
end

return UserAction