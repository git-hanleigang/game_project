--[[--
    PASS 双倍积分 空弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewPassDoubleMedal = class("NewPassDoubleMedal", BaseActivityData)

function NewPassDoubleMedal:ctor()
    NewPassDoubleMedal.super.ctor(self)
    self.p_open = true
end

function NewPassDoubleMedal:isRunning()
    if not NewPassDoubleMedal.super.isRunning(self) then
        return false
    end

    local _activity = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not _activity then
        return false
    else
        local doubleMultip = _activity:getDoubleActMultiple()
        if doubleMultip == nil or doubleMultip == 0 then
            return false
        end
    end
    return true 
end

return NewPassDoubleMedal