--[[
]]
GD.ReturnConfig = {}


-- ViewEventType.TREASURE_SEEKER_SHAKE_BOX = "TREASURE_SEEKER_SHAKE_BOX"

NetType.Return = "Return"
NetLuaModule.Return = "GameModule.Return.net.ReturnNet"

ViewEventType.NOTIFY_RETURN_TIMEOUT = "NOTIFY_RETURN_TIMEOUT"
ViewEventType.NOTIFY_RETURN_TASK_COLLECT = "NOTIFY_RETURN_TASK_COLLECT"
ViewEventType.NOTIFY_RETURN_PASS_COLLECT = "NOTIFY_RETURN_PASS_COLLECT"
ViewEventType.NOTIFY_RETURN_PASS_UNLOCK = "NOTIFY_RETURN_PASS_UNLOCK"
ViewEventType.NOTIFY_RETURN_SIGN_BUBBLE = "NOTIFY_RETURN_SIGN_BUBBLE"
ViewEventType.NOTIFY_RETURN_WHEEL_DATA_UPDATE = "NOTIFY_RETURN_WHEEL_DATA_UPDATE"
ViewEventType.NOTIFY_RETURN_WHEEL_SPIN = "NOTIFY_RETURN_WHEEL_SPIN"

ReturnConfig.PassCellStatus = {
    Locked = 1,
    Unlocked = 2,
    Completed = 3,
    Collected = 4,
}

ReturnConfig.SignDayStatus = {
    Locked = 1,
    Completed = 2,
    Collected = 3,
}
