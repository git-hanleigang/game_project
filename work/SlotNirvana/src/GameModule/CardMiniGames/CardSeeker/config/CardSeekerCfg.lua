--[[
]]
GD.CardSeekerCfg = {}

CardSeekerCfg.csbPath = "CardRes/CardGame_Seeker/csb/"
CardSeekerCfg.otherPath = "CardRes/CardGame_Seeker/other/"
CardSeekerCfg.luaPath = "views.Card.CardGame_Seeker."

CardSeekerCfg.resPath = function(_time)
    CardSeekerCfg.csbPath = string.format("CardRes%s/CardGame_Seeker/csb/", tostring(_time))
    CardSeekerCfg.otherPath = string.format("CardRes%s/CardGame_Seeker/other/", tostring(_time))
    CardSeekerCfg.luaPath = string.format("views.Card.CardGame_Seeker%s.", tostring(_time))
end


CardSeekerCfg.BoxTotalCount = 4
CardSeekerCfg.GameStatus = {
    init = "INIT",
    playing = "PLAYING",
    finish = "FINISH"
}
CardSeekerCfg.LevelType = {
    normal = 0,
    special = 1
}
CardSeekerCfg.BoxType = {
    coin = "COINS",
    gem = "GEMS",
    item = "ITEM",
    monster = "END"
}

CardSeekerCfg.BubbleTextType = {
    normalLevel = "normalLevel", -- 普通关卡，无气泡的
    firstLevel = "firstLevel", -- 第一关
    specialLevel = "specialLevel", -- 特殊关
    firstAfterSpecialLevel = "firstAfterSpecialLevel", -- 特殊关后的第一关
    lastLevel = "lastLevel" -- 最后一关
}

CardSeekerCfg.BubbleTexts = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"FIND THE REWARD!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE MAGIC CHIP!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT FOR THE WHISTLE!"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL LEVEL!"}}
}
CardSeekerCfg.BubbleTexts202302 = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"FIND THE REWARD!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE MAGIC CHIP!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT FOR THE PIGEON!"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL LEVEL!"}}
}
CardSeekerCfg.BubbleTexts202303 = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"FIND THE REWARD!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE MYTHIC CHIP!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT FOR THE ZEUS!"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL LEVEL!"}}
}
CardSeekerCfg.BubbleTexts202304 = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"FIND THE REWARD!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE MYTHIC CHIP!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT FOR", "THE BAD TAPE"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL LEVEL!"}}
}
CardSeekerCfg.BubbleTexts202401 = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"FIND THE REWARD!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE MYTHIC CHIP!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT FOR", "THE BAD CAN!"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL LEVEL!"}}
}
CardSeekerCfg.BubbleTexts302301 = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"FIND THE REWARD!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE GOLD CHIP!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT FOR THE DEVIL!"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL LEVEL!"}}
}
CardSeekerCfg.resetBubbleTexts = function(_albumId)
    local info = CardSeekerCfg["BubbleTexts" .. _albumId]
    if info then
        CardSeekerCfg.BubbleTexts = info
    end
end

CardSeekerCfg.getBubbleTextByLevelIndex = function(_levelIndex)
    if _levelIndex and _levelIndex > 0 then
        for i = 1, #CardSeekerCfg.BubbleTexts do
            local cfg = CardSeekerCfg.BubbleTexts[i]
            if cfg.levels and #cfg.levels > 0 then
                for j = 1, #cfg.levels do
                    if cfg.levels[j] == _levelIndex then
                        return cfg.texts
                    end
                end
            end
        end
    end
    return nil
end

CardSeekerCfg.getBubbleTextByLevelType = function(_levelType)
    if _levelType and _levelType ~= "" then
        for i = 1, #CardSeekerCfg.BubbleTexts do
            local cfg = CardSeekerCfg.BubbleTexts[i]
            if cfg.levelType == _levelType then
                return cfg.texts
            end
        end
    end
    return nil
end

ViewEventType.CARD_SEEKER_REQUEST_OPENBOX = "CARD_SEEKER_REQUEST_OPENBOX"
ViewEventType.CARD_SEEKER_REQUEST_COLLECT = "CARD_SEEKER_REQUEST_COLLECT"
ViewEventType.CARD_SEEKER_REQUEST_COSTGEM = "CARD_SEEKER_REQUEST_COSTGEM"
ViewEventType.CARD_SEEKER_REQUEST_GIVEUP = "CARD_SEEKER_REQUEST_GIVEUP"
ViewEventType.CARD_SEEKER_SHAKE_BOX = "CARD_SEEKER_SHAKE_BOX"
ViewEventType.CARD_SEEKER_CG_CLOSED = "CARD_SEEKER_CG_CLOSED"
-- ViewEventType.CARD_SEEKER_PICKGAME_ENTER_CD = "CARD_SEEKER_PICKGAME_ENTER_CD"
ViewEventType.CARD_SEEKER_DATA_REFRESH = "CARD_SEEKER_DATA_REFRESH"

NetType.CardSeeker = "CardSeeker"
NetLuaModule.CardSeeker = "GameModule.CardMiniGames.CardSeeker.net.CardSeekerNet"
