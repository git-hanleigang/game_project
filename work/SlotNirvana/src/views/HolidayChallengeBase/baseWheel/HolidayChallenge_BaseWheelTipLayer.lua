--[[
    转盘 - 关闭二次确认界面
]]
local HolidayChallenge_BaseWheelTipLayer = class("HolidayChallenge_BaseWheelTipLayer", BaseLayer)

function HolidayChallenge_BaseWheelTipLayer:initDatas(_callFunc)
    self.m_callFunc = _callFunc
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.WHEEL_TIP_LAYER)
    self:setExtendData("HolidayChallenge_WheelTipLayer")
end

function HolidayChallenge_BaseWheelTipLayer:getWheelData()
    local wheelData = nil
    local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if holidayData then
        wheelData = holidayData:getWheelData()
        return wheelData
    end
    return wheelData
end

function HolidayChallenge_BaseWheelTipLayer:initCsbNodes()
    self.m_lb_times = self:findChild("lb_times")
end

function HolidayChallenge_BaseWheelTipLayer:initView()
    local wheelData = self:getWheelData()
    if wheelData then
        local spinLeft = wheelData:getSpinLeft()
        self.m_lb_times:setString("" .. spinLeft)
    end
end

function HolidayChallenge_BaseWheelTipLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI(
            function()
                if self.m_callFunc then
                    self.m_callFunc()
                end
            end
        )
    elseif name == "btn_go" then
        self:closeUI()
    end
end

function HolidayChallenge_BaseWheelTipLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function HolidayChallenge_BaseWheelTipLayer:registerListener()
    HolidayChallenge_BaseWheelTipLayer.super.registerListener(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return HolidayChallenge_BaseWheelTipLayer
