-- 排行榜基类 倒计时控件

local BaseRankTimer = class("BaseRankTimer", BaseView)

function BaseRankTimer:initUI(csb_path, data)
    if not csb_path or csb_path == "" then
        return
    end
    self:createCsbNode(csb_path)
    util_portraitAdaptPortrait(self.m_csbNode)

    self.m_data = data
    if self.m_data then
        self:onTick()
    end
end

function BaseRankTimer:initCsbNodes()
    self.lb_timer = self:findChild("lb_timer")
end

function BaseRankTimer:getCountDownTimeStr(_leftTime)
    return util_daysdemaining(_leftTime, true)
end

function BaseRankTimer:onTick()
    local function tick()
        local left_time = self.m_data:getExpireAt()
        if left_time < 0 then
            left_time = 0
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
        end
        local timer = self:getCountDownTimeStr(left_time)
        self.lb_timer:setString(timer)
    end

    if not self.schedule_timer then
        self.schedule_timer = util_schedule(self, tick, 1)
    end

    tick()
end

return BaseRankTimer
