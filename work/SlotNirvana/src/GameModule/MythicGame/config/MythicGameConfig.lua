--[[
]]

local MythicGameConfig = {}

MythicGameConfig.csbPath = "Activity_CardGameSeeker/CardGame_Seeker/csb/"
MythicGameConfig.otherPath = "Activity_CardGameSeeker/CardGame_Seeker/other/"
MythicGameConfig.luaPath = "Activity_CardGameSeeker.Code."

MythicGameConfig.BoxTotalCount = 4
MythicGameConfig.GameStatus = {
    init = "INIT",
    playing = "PLAYING",
    finish = "FINISH"
}
MythicGameConfig.LevelType = {
    normal = 0,
    special = 1
}
MythicGameConfig.BoxType = {
    coin = "COINS",
    gem = "GEMS",
    item = "ITEM",
    monster = "END"
}

MythicGameConfig.BubbleTextType = {
    normalLevel = "normalLevel", -- 普通关卡，无气泡的
    firstLevel = "firstLevel", -- 第一关
    specialLevel = "specialLevel", -- 特殊关
    firstAfterSpecialLevel = "firstAfterSpecialLevel", -- 特殊关后的第一关
    lastLevel = "lastLevel" -- 最后一关
}

MythicGameConfig.BubbleTexts = {
    {levels = {1}, ["texts"] = {"WELCOME TO", "MYTHIC GAME!"}},
    {levels = {5, 10, 15}, ["texts"] = {"FIND THE PURPLE", "MYTHIC CHIP!"}},
    {levels = {6, 11, 16}, ["texts"] = {"FIND THE RED", "MYTHIC CHIP!"}},
    {levels = {20}, ["texts"] = {"FIND THE WILD", "MYTHIC CHIP!"}}
}

MythicGameConfig.getBubbleTextByLevelIndex = function(_index)
    if _index and _index > 0 then
        for i = 1, #MythicGameConfig.BubbleTexts do
            local cfg = MythicGameConfig.BubbleTexts[i]
            if cfg.levels and #cfg.levels > 0 then
                for j = 1, #cfg.levels do
                    if cfg.levels[j] == _index then
                        return cfg.texts
                    end
                end
            end
        end
    end
    return nil
end

ViewEventType.MYTHIC_GAME_REQUEST_OPENBOX = "MYTHIC_GAME_REQUEST_OPENBOX"
ViewEventType.MYTHIC_GAME_REQUEST_COLLECT = "MYTHIC_GAME_REQUEST_COLLECT"

return MythicGameConfig