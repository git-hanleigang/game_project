--[[--
    回收机气泡
]]
local CardMenuWheelBubble = class("CardMenuWheelBubble", util_require("base.BaseView"))

function CardMenuWheelBubble:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonLottoQipaoRes, "season201903")
end

function CardMenuWheelBubble:initUI()
    self:createCsbNode(self:getCsbName())
    self.m_countDownLabel = self:findChild("timelb")

    self.m_closeTime = 5
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
    self:initCloseTime()
    self:initCountTime()
end

function CardMenuWheelBubble:closeUI(callback)
    if self.closed then
        return
    end
    self.closed = true

    if self.m_closeTimer ~= nil then
        self:stopAction(self.m_closeTimer)
        self.m_closeTimer = nil
    end

    self:runCsbAction(
        "over",
        false,
        function()
            if callback then
                callback()
            end
            self:removeFromParent()
        end,
        60
    )
end

function CardMenuWheelBubble:initCountTime()
    local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
    local remainTime = math.max(util_getLeftTime(finalTime), 0)
    self:updateTime(remainTime)
end

function CardMenuWheelBubble:onEnter()
    -- 每秒刷新一次的消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
            local remainTime = math.max(util_getLeftTime(finalTime), 0)
            if remainTime == 0 then
                if self.closeUI then
                    self:closeUI()
                end
            else
                self:updateTime(remainTime)
            end
        end,
        CardSysConfigs.ViewEventType.CARD_COUNTDOWN_UPDATE
    )
    -- -- 关闭后要刷新数据可以点击进入结算界面
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
    --         local remainTime = math.max(util_getLeftTime(finalTime), 0)
    --         if remainTime == 0 then
    --             if self.closeUI then
    --                 self:closeUI()
    --             end
    --         end
    --     end,
    --     ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO
    -- )
end

function CardMenuWheelBubble:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function CardMenuWheelBubble:getWheelCountDown()
    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    if yearData then
        local wheelCfg = yearData:getWheelConfig()
        if wheelCfg then
            return wheelCfg:getCooldown()
        end
    end
end

function CardMenuWheelBubble:initCloseTime()
    local index = 0
    self.m_closeTimer =
        util_schedule(
        self,
        function()
            index = index + 1
            if index >= self.m_closeTime then
                if self.m_closeTimer ~= nil then
                    self:stopAction(self.m_closeTimer)
                    self.m_closeTimer = nil
                end
                self:closeUI()
            end
        end,
        1
    )
end

function CardMenuWheelBubble:updateTime(remainTime)
    self.m_countDownLabel:setString(util_count_down_str(remainTime))
end

return CardMenuWheelBubble
