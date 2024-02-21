--[[
    
]]

_G.BlindBoxConfig = {}


-- BlindBoxConfig.MissionType = {
--     DailyMission = "DAILYMISSION",
--     Activity = "ACTIVITY",
--     LevelRush = "LEVELRUSH",
--     NormalCard = "NORMALCARD",
--     GoldenCard = "GOLDENCARD",
--     Purchase = "PURCHASE",
--     Pass = "PASS",
-- }

BlindBoxConfig.MissionStatus = {
    UnComplete = 1,
    Complete = 2,
    Collect = 3,
}

ViewEventType.BLIND_BOX_BUY_SALE = "BLIND_BOX_BUY_SALE"
ViewEventType.BLIND_BOX_NEXT = "BLIND_BOX_NEXT"
ViewEventType.BLIND_BOX_OPEN = "BLIND_BOX_OPEN"
ViewEventType.BLIND_BOX_COLLECT_END = "BLIND_BOX_COLLECT_END"
ViewEventType.BLIND_BOX_GOTO_DAILY_TASK = "BLIND_BOX_GOTO_DAILY_TASK"
ViewEventType.BLIND_BOX_PASS_COLLECT = "BLIND_BOX_PASS_COLLECT"
ViewEventType.BLIND_BOX_PASS_UNLOCK = "BLIND_BOX_PASS_UNLOCK"
ViewEventType.BLIND_BOX_MISSION_COLLECT = "BLIND_BOX_MISSION_COLLECT"

BUY_TYPE.BLIND_BOX_PASS_UNLOCK = "BlindBoxPass"
