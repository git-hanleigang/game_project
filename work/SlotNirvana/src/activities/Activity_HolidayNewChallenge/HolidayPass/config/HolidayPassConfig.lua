--[[
]]
GD.HolidayPassConfig = {}

ViewEventType.NOTIFY_HOLIDAY_PASS_TASK_COLLECT = "NOTIFY_HOLIDAY_PASS_TASK_COLLECT"
ViewEventType.NOTIFY_HOLIDAY_PASS_COLLECT = "NOTIFY_HOLIDAY_PASS_COLLECT"
ViewEventType.NOTIFY_HOLIDAY_PASS_UNLOCK = "NOTIFY_HOLIDAY_PASS_UNLOCK"

HolidayPassConfig.PassCellStatus = {
    Locked = 1,
    Unlocked = 2,
    Collected = 3,
    Completed = 4,
}

return HolidayPassConfig