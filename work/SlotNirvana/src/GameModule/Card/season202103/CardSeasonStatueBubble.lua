--[[--
    倒计时气泡
]]
local CardSeasonStatueBubble = class("CardSeasonStatueBubble", BaseView)

function CardSeasonStatueBubble:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonStatueBubbleRes, "season202103")
end

function CardSeasonStatueBubble:initUI()
    CardSeasonStatueBubble.super.initUI(self)
    self:initData()
    self:initCloseTime()
    self:updateCountdown()
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true, nil, 60)
    end, 60)
end

function CardSeasonStatueBubble:initCsbNodes()
    self.m_countDownLabel = self:findChild("timelb")
end

function CardSeasonStatueBubble:initData()
    self.m_closeTime = 3
end

function CardSeasonStatueBubble:initCloseTime()
    local index = 0
    self.m_closeTimer = util_schedule(self, function()
        index = index + 1
        if index >= self.m_closeTime then
            self:closeUI()
        end
    end, 1)
end

function CardSeasonStatueBubble:updateCountdown()
    local remainTime = 0
    if StatuePickGameData then
        remainTime = StatuePickGameData:getCooldownTime()
    end
    self.m_countDownLabel:setString(util_count_down_str(remainTime))
end

function CardSeasonStatueBubble:closeUI(callback)
    if self.closed then
        return 
    end
    self.closed = true
    
    if self.m_closeTimer ~= nil  then
        self:stopAction(self.m_closeTimer)
        self.m_closeTimer = nil
    end

    self:runCsbAction("over", false, function()
        if callback then
            callback()
        end
        self:removeFromParent()
    end, 60)
end

function CardSeasonStatueBubble:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateCountdown()
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_UPDATE_TIME
    )
end

function CardSeasonStatueBubble:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return CardSeasonStatueBubble