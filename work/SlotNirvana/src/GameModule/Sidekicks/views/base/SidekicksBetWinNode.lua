--[[

--]]

local SidekicksBetWinNode = class("SidekicksBetWinNode", BaseView)

function SidekicksBetWinNode:getCsbName()
    return string.format("Sidekicks_%s/csd/main/reward_caijin.csb", self.m_seasonIdx)
end

function SidekicksBetWinNode:initDatas(_seasonIdx)
    self.m_seasonIdx = _seasonIdx
    self.m_status = "hide"
end

function SidekicksBetWinNode:initCsbNodes()
    self.m_lb_coins = self:findChild("lb_coins")
    self.m_node_spine = self:findChild("node_spine")
    self.m_lb_bet = self:findChild("lb_bet")
    self.m_node_bet = self:findChild("node_bet")
    self.m_caijin = self:findChild("coins")
end

function SidekicksBetWinNode:initUI()
    SidekicksBetWinNode.super.initUI(self)

    self.m_spine = util_spineCreate(string.format("Sidekicks_%s/spine/Sidekicks_cat", self.m_seasonIdx), true, true, 1)
    self.m_node_spine:addChild(self.m_spine)

    if globalData.slotRunData.isPortrait == true then
        self.m_node_bet:setScaleX(-1)
        self.m_caijin:setScaleX(-1)
        self.m_spine:setScaleX(-1)
        self.m_startName = "spin_start2"
        self.m_idleName = "spin_idle3"
        self.m_idle = "spin_idle4"
    else
        self.m_startName = "spin_start"
        self.m_idleName = "spin_idle2"
        self.m_idle = "spin_idle1"
    end

    util_setCascadeOpacityEnabledRescursion(self.m_node_spine, true)
end

function SidekicksBetWinNode:stopScheduler()
    if self.m_startScheduler then
        self.m_node_spine:stopAction(self.m_startScheduler)
        self.m_startScheduler = nil
    end

    if self.m_start2Scheduler then
        self.m_lb_bet:stopAction(self.m_start2Scheduler)
        self.m_start2Scheduler = nil
    end

    if self.m_start3Scheduler then
        self.m_node_bet:stopAction(self.m_start3Scheduler)
        self.m_start3Scheduler = nil
    end

    if self.m_overScheduler then
        self.m_lb_coins:stopAction(self.m_overScheduler)
        self.m_overScheduler = nil
    end

    if self.m_over2Scheduler then
        self.m_caijin:stopAction(self.m_over2Scheduler)
        self.m_over2Scheduler = nil
    end
end

function SidekicksBetWinNode:playStart(_coins)
    util_spinePlay(self.m_spine, self.m_idle, false)

    self.m_coins = toLongNumber(_coins)
    if self.m_coins > toLongNumber(0) then
        self:playStartCoins()
    else
        self:playStartNoCoins()
    end
end

function SidekicksBetWinNode:playStartCoins()
    self.m_status = "show"
    self:setVisible(true)
    self:setExtraBet()
    
    self:runCsbAction("start3", false)
    self.m_start3Scheduler = performWithDelay(self.m_node_bet, function ()
        self.m_start3Scheduler = nil
        self:runCsbAction("start2", false)
        util_spinePlay(self.m_spine, self.m_startName, false)
    end, 30/60)

    self.m_startScheduler = performWithDelay(self.m_node_spine, function ()
        self.m_startScheduler = nil
        util_spinePlay(self.m_spine, self.m_idleName, true)
    end, 70/60)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SIDEKICKS_BET_BONUS_START)
end

function SidekicksBetWinNode:setExtraBet()
    local lastBetIdx = globalData.slotRunData.iLastBetIdx
    local betInfo = globalData.slotRunData:getBetDataByIdx(lastBetIdx)
    local mul = 0
    local data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if data then
        local petInfo = data:getPetInfoById(2)
        local skill = petInfo:getSkillInfoById(3)
        mul = skill:getCurrentSpecialParam()
    end
    self.m_lb_bet:setString(util_formatCoins(betInfo.p_totalBetValue * mul, 3))
    self.m_lb_bet:setVisible(mul > 0)
end

function SidekicksBetWinNode:playStartNoCoins()
    self.m_status = "show"
    self:setVisible(true)
    self:setExtraBet()
    
    self:runCsbAction("start3", false)
    self.m_start3Scheduler = performWithDelay(self.m_node_bet, function ()
        self.m_start3Scheduler = nil
        self:runCsbAction("start2", false, function()
            util_spinePlay(self.m_spine, self.m_idleName, true)
        end, 60)
        util_spinePlay(self.m_spine, self.m_startName, false)
    end, 30/60)

    self.m_startScheduler = performWithDelay(self.m_node_spine, function ()
        self.m_startScheduler = nil
        self:runCsbAction("over2", false)
    end, (70 + 60)/60)

    self.m_over2Scheduler = performWithDelay(self.m_caijin, function ()
        self.m_over2Scheduler = nil
        self:setVisible(false)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SIDEKICKS_BET_BONUS_OVER)
    end, (90 + 60)/60)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SIDEKICKS_BET_BONUS_START)
end

function SidekicksBetWinNode:playOver()
    if self.m_coins > toLongNumber(0) then
        self:playOverCoins()
    end
end

function SidekicksBetWinNode:playOverCoins()
    self.m_status = "hide"
    self.m_lb_coins:setString(util_formatCoins(self.m_coins, 3))

    self:stopScheduler()
    
    self:runCsbAction("start", false)
    
    self.m_start2Scheduler = performWithDelay(self.m_lb_bet, function ()
        self:runCsbAction("over", false)
        self.m_start2Scheduler = nil
    end, 40/60)

    self.m_overScheduler = performWithDelay(self.m_lb_coins, function ()
        self.m_overScheduler = nil
        self:runCsbAction("over2", false)
    end, 1)

    self.m_over2Scheduler = performWithDelay(self.m_caijin, function ()
        self.m_over2Scheduler = nil
        self:setVisible(false)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SIDEKICKS_BET_BONUS_OVER)
    end, 80/60)
end

function SidekicksBetWinNode:onEnter()
    SidekicksBetWinNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_status == "show" then
                self:playOver()
            end
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_COIN
    )
end

return SidekicksBetWinNode