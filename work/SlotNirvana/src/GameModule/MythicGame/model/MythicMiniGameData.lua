--[[
]]
local MythicGameData = import(".MythicGameData")
local BaseGameModel = require("GameBase.BaseGameModel")
local MythicMiniGameData = class("MythicMiniGameData", BaseGameModel)

function MythicMiniGameData:ctor()
    MythicMiniGameData.super.ctor(self)

    self.p_reference = G_REF.MythicGame
end

function MythicMiniGameData:parseData(_data)
    self.p_gameDatas = {}

    for i,v in ipairs(_data) do
        local aData = MythicGameData:create()
        aData:parseData(v)
        table.insert(self.p_gameDatas, aData)
    end
end

function MythicMiniGameData:getAllGameDatas()
    return self.p_gameDatas
end

function MythicMiniGameData:getGameDataById(_id)
    if self.p_gameDatas and #self.p_gameDatas > 0 then
        for i = 1, #self.p_gameDatas do
            if self.p_gameDatas[i]:getId() == _id then
                return self.p_gameDatas[i]
            end
        end
    end
    return nil
end

function MythicMiniGameData:getLastGameData()
    if self.p_gameDatas and #self.p_gameDatas > 0 then
        return self.p_gameDatas[#self.p_gameDatas]
    end
end

function MythicMiniGameData:getPlayingGameData()
    local playingGameDatas = {}
    if self.p_gameDatas and #self.p_gameDatas > 0 then
        for i = 1, #self.p_gameDatas do
            local gameData = self.p_gameDatas[i]
            if gameData:isPlaying() == true then
                playingGameDatas[#playingGameDatas + 1] = gameData
            end
        end
    end
    return playingGameDatas
end

function MythicMiniGameData:checkOpenLevel()
    return true
end

function MythicMiniGameData:getLastGameId()
    if self.p_gameDatas and #self.p_gameDatas > 0 then
        local data = self.p_gameDatas[#self.p_gameDatas]
        return data:getId()
    else
        return 0
    end 
end

return MythicMiniGameData
