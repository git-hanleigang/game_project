--[[
    滚动控制
]]
local ROLL_STAGE = {
    NONE = 0,
    ACC = 1,
    KEEP = 2,
    DEC = 3
}
local LSGameRollControl = class("LSGameRollControl")

function LSGameRollControl:ctor()
    self.m_isStartRoll = false

    self.m_startSpeed = 18 -- 最慢

    self.m_accSpeed = 2 -- 加速度，每次速度变化值
    self.m_accSpeedTime = 60

    self.m_maxSpeed = 4 -- 最快
    self.m_maxSpeedTime = 180

    self.m_decSpeed = 2 -- 减速度，每次速度变化值
    self.m_decSpeedTime = 60

    self.m_rollStage = ROLL_STAGE.NONE
end

function LSGameRollControl:init(_total, _startIndex, _stopIndex)
    self.m_total = _total
    self.m_startIndex = _startIndex or 1
end

function LSGameRollControl:setStopIndex(_stopIndex)
    self.m_stopIndex = _stopIndex + 1 -- 服务器从0开始，需要+1
    self:initRoolTimer()
end

function LSGameRollControl:startRoll(_perCall, _overRoll)
    self.m_perCall = _perCall
    self.m_overRoll = _overRoll

    self.m_curIndex = self.m_startIndex
    self.m_cur = 0
    self.m_stopNums = 0

    self.m_isStartRoll = true
end

function LSGameRollControl:overRoll()
    self.m_isStartRoll = false
    if self.m_overRoll then
        self.m_overRoll()
        self.m_overRoll = nil
    end
    if self.m_schduleCheckTimeID ~= nil then
        scheduler.unscheduleGlobal(self.m_schduleCheckTimeID)
        self.m_schduleCheckTimeID = nil
    end
end

function LSGameRollControl:perRollCall(_frame)
    self.m_cur = self.m_cur + 1
    -- index 回形
    self.m_curIndex = self.m_curIndex + 1
    if self.m_curIndex > self.m_total then
        self.m_curIndex = 1
    end
    print("---- perRollCall ----", _frame, self.m_cur, self.m_curIndex, self.m_stopIndex, self.m_rollStage)
    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/boom.mp3")
    -- 每次回调
    if self.m_perCall then
        self.m_perCall(self.m_curIndex)
    end
    -- 结束
    if self.m_rollStage == ROLL_STAGE.DEC then
        self.m_stopNums = self.m_stopNums + 1
        if self.m_stopNums >= math.floor(self.m_total / 2) and self.m_curIndex == self.m_stopIndex then
            self:overRoll()
        end
    end
end

function LSGameRollControl:initRoolTimer()
    if self.m_schduleCheckTimeID ~= nil then
        scheduler.unscheduleGlobal(self.m_schduleCheckTimeID)
        self.m_schduleCheckTimeID = nil
    end
    local frame = 0
    local interval = 0
    local speed = self.m_startSpeed
    self.m_schduleCheckTimeID =
        scheduler.scheduleGlobal(
        function()
            if self.m_isStartRoll == false then
                return
            end
            frame = frame + 1
            if frame < self.m_accSpeedTime then
                -- 加速阶段
                self.m_rollStage = ROLL_STAGE.ACC
                interval = interval + 1
                if self.m_cur == 0 then
                    interval = 0
                    speed = math.max(self.m_maxSpeed, speed - self.m_accSpeed)
                    self:perRollCall(frame)
                else
                    if interval >= speed then
                        interval = 0
                        speed = math.max(self.m_maxSpeed, speed - self.m_accSpeed)
                        self:perRollCall(frame)
                    end
                end
            elseif frame >= self.m_accSpeedTime and frame < (self.m_accSpeedTime + self.m_maxSpeedTime) then
                -- 匀速阶段
                self.m_rollStage = ROLL_STAGE.KEEP
                interval = interval + 1
                -- print("---- keep", interval, self.m_maxSpeed)
                if interval >= self.m_maxSpeed then
                    interval = 0
                    self:perRollCall(frame)
                end
            elseif frame >= (self.m_accSpeedTime + self.m_maxSpeedTime) then
                -- 减速阶段
                self.m_rollStage = ROLL_STAGE.DEC
                interval = interval + 1
                -- print("---- dec", interval, speed)
                if interval >= speed then
                    interval = 0
                    speed = math.min(self.m_startSpeed, speed + self.m_decSpeed)
                    self:perRollCall(frame)
                end
            end
        end,
        1 / 60
    )
end

function LSGameRollControl:stopSche()
    if self.m_schduleCheckTimeID ~= nil then
        scheduler.unscheduleGlobal(self.m_schduleCheckTimeID)
        self.m_schduleCheckTimeID = nil
    end
end

return LSGameRollControl
