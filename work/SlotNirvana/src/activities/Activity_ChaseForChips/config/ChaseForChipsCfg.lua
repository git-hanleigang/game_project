--[[
    集卡赛季末聚合
]]
GD.ChaseForChipsCfg = {}

ChaseForChipsCfg.luaPath = "Activity.Activity_ChaseForChipsCode."
ChaseForChipsCfg.csbRes = "Activity/Activity_ChaseForChips/csb/"
ChaseForChipsCfg.otherRes = "Activity/Activity_ChaseForChips/other/"

ChaseForChipsCfg.setPath = function(themeName)
    ChaseForChipsCfg.luaPath = "Activity." .. themeName .."Code."
    ChaseForChipsCfg.csbRes = "Activity/" .. themeName .. "/csb/"
    ChaseForChipsCfg.otherRes = "Activity/" .. themeName .. "/other/"
end

ChaseForChipsCfg.MainCellStatus = {
    Lock = 1,
    Unlock = 2, 
    Collect = 3,
    Complete = 4
}

ChaseForChipsCfg.TaskType = {
    Star = "STAR",
    Card = "CARD"
}

NetType.ChaseForChips = "ChaseForChips"
NetLuaModule.ChaseForChips = "activities.Activity_ChaseForChips.net.ChaseForChipsNet"

ViewEventType.CHASE_FOR_CHIPS_COLLECT_PASS_SUCCESS = "CHASE_FOR_CHIPS_COLLECT_PASS_SUCCESS"

