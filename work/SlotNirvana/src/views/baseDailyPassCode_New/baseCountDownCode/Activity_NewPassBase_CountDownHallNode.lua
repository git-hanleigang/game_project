
local HallNode = util_require("views.lobby.HallNode")
local Activity_NewPassBase_CountDownHallNode = class("Activity_NewPassBase_CountDownHallNode", HallNode)

function Activity_NewPassBase_CountDownHallNode:initView()
    self.m_lbTime = self:findChild("lb_time")
    self.m_lb_time2 = self:findChild("lb_time2")
    self.m_node_time1 = self:findChild("node_time1")
    self.m_node_time2 = self:findChild("node_time2")
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateView), 1)
end

function Activity_NewPassBase_CountDownHallNode:updateView()
    -- 计算倒计时
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passActData then
        local expireAt = passActData:getExpireAt()
        local leftTime = math.max(expireAt, 0)
        local timeStr, isOver ,isFullDay = util_daysdemaining(leftTime,true)
        if isFullDay then
            if not self.m_node_time1:isVisible() then
                self.m_node_time1:setVisible(true)
            end
            if self.m_node_time2:isVisible() then
                self.m_node_time2:setVisible(false)
            end
            self.m_lb_time2:setString(timeStr)
        else
            if not self.m_node_time2:isVisible() then
                self.m_node_time2:setVisible(true)
            end
            if self.m_node_time1:isVisible() then
                self.m_node_time1:setVisible(false)
            end
            self.m_lbTime:setString(timeStr)
        end
    end
end

function Activity_NewPassBase_CountDownHallNode:onExit()
    self:clearScheduler()
    Activity_NewPassBase_CountDownHallNode.super.onExit(self)
end

function Activity_NewPassBase_CountDownHallNode:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

return Activity_NewPassBase_CountDownHallNode