
--[[
Author: zkk
Description: 新手期pass 展示图
FilePath: /SlotNirvana/src/views/lobby/LevelNewUserPassHallNode.lua
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelNewUserPassHallNode = class("LevelNewUserPassHallNode", LevelFeature)

function LevelNewUserPassHallNode:createCsb()
    LevelNewUserPassHallNode.super.createCsb(self)
    self:createCsbNode("Icons/NewPassVegasNewHall.csb")
    self:runCsbAction("idle", true, nil, 60)
end

function LevelNewUserPassHallNode:clickFunc(sender)
    --gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyDisplay")
    performWithDelay(
        self,
        function()
            gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestEntrySite("lobbyDisplay")
            G_GetMgr(ACTIVITY_REF.NewPass):showLoadingView()
        end,
        0.2
    )
end

return LevelNewUserPassHallNode

