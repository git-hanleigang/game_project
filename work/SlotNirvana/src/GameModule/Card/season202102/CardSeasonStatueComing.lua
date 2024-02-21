--[[--
    即将开启提示
]]
local CardSeasonStatueComing = class("CardSeasonStatueComing", BaseView)
function CardSeasonStatueComing:initUI()
    CardSeasonStatueComing.super.initUI(self)

    self:initData()
    self:initView()
end

function CardSeasonStatueComing:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonStatueComingRes, "season202102")
end

function CardSeasonStatueComing:initData()
    self.m_closeTime = 3
end

function CardSeasonStatueComing:initView()
    self:initCloseTime()
end

function CardSeasonStatueComing:initCloseTime()
    local index = 0
    self.m_closeTimer = util_schedule(self, function()
        index = index + 1
        if index >= self.m_closeTime then
            self:closeUI()
        end
    end, 1)
end

function CardSeasonStatueComing:onEnter()
    CardSeasonStatueComing.super.onEnter(self)

    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true, nil, 60)
    end, 60)
end

function CardSeasonStatueComing:closeUI(callback)
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
return CardSeasonStatueComing