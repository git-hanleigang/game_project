local BaseView = require("base.BaseView")
local Activity_HolidayChallenge_Halloween2022 = class("Activity_HolidayChallenge_Halloween2022", BaseView)

function Activity_HolidayChallenge_Halloween2022:initUI()
    G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
end

function Activity_HolidayChallenge_Halloween2022:onEnter()
    self:removeFromParent()
end

return Activity_HolidayChallenge_Halloween2022
