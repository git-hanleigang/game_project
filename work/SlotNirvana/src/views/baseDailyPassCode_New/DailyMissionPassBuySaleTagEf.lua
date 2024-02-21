--[[
    
]]
local DailyMissionPassBuySaleTagEf = class("DailyMissionPassBuySaleTagEf", BaseLayer)

function DailyMissionPassBuySaleTagEf:initDatas()
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    -- self:setShowBgOpacity(0)
end

function DailyMissionPassBuySaleTagEf:initView()
    local logo, act = util_csbCreate(DAILYPASS_RES_PATH.BuySaleTagEf)
    logo:setPosition(display.cx, display.cy)
    self:addChild(logo)
    util_csbPlayForKey(act, "start", false, function ()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PASS_DISCOUNT_EF_END)
        self:closeUI()
    end, 60)
end

return DailyMissionPassBuySaleTagEf
