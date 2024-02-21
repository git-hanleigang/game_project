local BaseActivityData = require("baseActivity.BaseActivityData")
local DinnerLandShowTopData = class("DinnerLandShowTopData", BaseActivityData)

function DinnerLandShowTopData:ctor()
    DinnerLandShowTopData.super.ctor(self)
    self.p_open = true
end

function DinnerLandShowTopData:checkOpenLevel()
    if not DinnerLandShowTopData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    local needLevel = globalData.constantData.ACTIVITY_OPEN_LEVEL or 20
    if needLevel > curLevel then
        return false
    end

    return true
end

return DinnerLandShowTopData
