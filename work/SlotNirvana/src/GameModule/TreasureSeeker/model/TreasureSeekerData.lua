--[[
]]
local AdventureData = import(".AdventureData")
local BaseGameModel = require("GameBase.BaseGameModel")
local TreasureSeekerData = class("TreasureSeekerData", BaseGameModel)
function TreasureSeekerData:ctor()
    TreasureSeekerData.super.ctor(self)
    self:setRefName(G_REF.TreasureSeeker)
end

-- 换皮时需主动更改这个名字，暂时无法通过配置来换皮
function TreasureSeekerData:getThemeName()
    return "TreasureSeekerAllCard"
end

function TreasureSeekerData:parseData(data)
    self.p_isFisrtBuy = data.adventureFistBuy
    self.p_TSGameDatas = {}
    if data.adventureResults and #data.adventureResults > 0 then
        for i = 1, #data.adventureResults do
            local aData = AdventureData:create()
            aData:parseData(data.adventureResults[i])
            table.insert(self.p_TSGameDatas, aData)
        end
    end
end

function TreasureSeekerData:getFirstBuy()
    return self.p_isFisrtBuy
end

function TreasureSeekerData:getAllGameDatas()
    return self.p_TSGameDatas
end

function TreasureSeekerData:getGameDataById(_id)
    if self.p_TSGameDatas and #self.p_TSGameDatas > 0 then
        for i = 1, #self.p_TSGameDatas do
            if self.p_TSGameDatas[i]:getId() == _id then
                return self.p_TSGameDatas[i]
            end
        end
    end
    return nil
end

function TreasureSeekerData:getLastGameData()
    if self.p_TSGameDatas and #self.p_TSGameDatas > 0 then
        return self.p_TSGameDatas[#self.p_TSGameDatas]
    end
end

function TreasureSeekerData:getPlayingGameData()
    local playingGameDatas = {}
    if self.p_TSGameDatas and #self.p_TSGameDatas > 0 then
        for i = 1, #self.p_TSGameDatas do
            local gameData = self.p_TSGameDatas[i]
            if gameData:isPlaying() == true then
                playingGameDatas[#playingGameDatas + 1] = gameData
            end
        end
    end
    return playingGameDatas
end

function TreasureSeekerData:onRegister()
    self:initCurGameIdx()
end

-- 初始化当前正在游戏的index, 断线重连用。
function TreasureSeekerData:initCurGameIdx()
end

function TreasureSeekerData:checkOpenLevel()
    if not TreasureSeekerData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end
    -- TSTODO:开启等级
    local needLevel = 20 -- globalData.constantData.CHALLENGE_OPEN_LEVEL
    if needLevel > curLevel then
        return false
    end

    return true
end

return TreasureSeekerData
