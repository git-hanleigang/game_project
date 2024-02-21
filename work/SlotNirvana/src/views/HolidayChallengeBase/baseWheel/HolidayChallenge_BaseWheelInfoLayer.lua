--[[
    转盘 - 规则界面
]]
local HolidayChallenge_BaseWheelInfoLayer = class("HolidayChallenge_BaseWheelInfoLayer", BaseLayer)

function HolidayChallenge_BaseWheelInfoLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.WHEEL_INFO_LAYER)
    self:setExtendData("HolidayChallenge_WheelInfoLayer")
end

function HolidayChallenge_BaseWheelInfoLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function HolidayChallenge_BaseWheelInfoLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function HolidayChallenge_BaseWheelInfoLayer:registerListener()
    HolidayChallenge_BaseWheelInfoLayer.super.registerListener(self)
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

return HolidayChallenge_BaseWheelInfoLayer
