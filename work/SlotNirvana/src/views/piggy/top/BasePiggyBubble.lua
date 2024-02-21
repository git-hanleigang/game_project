--[[--
    气泡基类
]]
local BasePiggyBubble = class("BasePiggyBubble", BaseView)

function BasePiggyBubble:initDatas()
    self.m_isStarting = false
    self.m_isOvering = false
    self.m_isShowing = false
end

function BasePiggyBubble:isShowing()
    return self.m_isShowing
end

function BasePiggyBubble:initUI()
    BasePiggyBubble.super.initUI(self)
end

function BasePiggyBubble:getAutoCloseTime()
    return 3
end

function BasePiggyBubble:playStart(_over)
    if self.m_isStarting then
        return
    end
    if self.m_isOvering then
        return
    end
    self:initAutoCloseTimer()
    self.m_isStarting = true
    self:runCsbAction(
        "start",
        false,
        function()
            if _over then
                _over()
            end
            self.m_isStarting = false
            self.m_isShowing = true
            self:playIdle()
        end,
        60
    )
end

function BasePiggyBubble:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function BasePiggyBubble:playOver(_over)
    if self.m_isStarting then
        return
    end
    if self.m_isOvering then
        return
    end
    self.m_isOvering = true
    self:runCsbAction(
        "over",
        false,
        function()
            if _over then
                _over()
            end
            self.m_isOvering = false
            self.m_isShowing = false
        end,
        60
    )
end

function BasePiggyBubble:clearAutoCloseTimer()
    if self.m_autoCloseTimer then
        self:stopAction(self.m_autoCloseTimer)
        self.m_autoCloseTimer = nil
    end
end

function BasePiggyBubble:initAutoCloseTimer()
    self:clearAutoCloseTimer()
    local closeTime = self:getAutoCloseTime() or 3
    self.m_autoCloseTimer =
        util_performWithDelay(
        self,
        function()
            self:closeUI()
        end,
        closeTime
    )
end

function BasePiggyBubble:closeUI(_over)
    if self.isClose then
        return
    end
    self.isClose = true
    self:clearAutoCloseTimer()
    self:playOver(
        function()
            if _over then
                _over()
            end
            if not tolua.isnull(self) then
                self:removeFromParent()
                G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showNextTip()
            end
        end
    )
end

return BasePiggyBubble
