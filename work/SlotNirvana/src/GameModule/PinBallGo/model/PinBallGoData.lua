--[[
    2周年
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseGameModel = require("GameBase.BaseGameModel")
local PinBallGoData = class("PinBallGoData",BaseGameModel)
local PinBallGoOneGameData = require("GameModule.PinBallGo.model.PinBallGoOneGameData")

function PinBallGoData:ctor()
    PinBallGoData.super.ctor(self)
    self.p_allGame = {}
end

function PinBallGoData:parseData(_data, _formLogon)
    PinBallGoData.super.parseData(self,_data)

    local temp = {}
    for i,gameData in ipairs(_data) do
        local oneGame = PinBallGoOneGameData:create()
        oneGame:parseData(gameData)

        if self.p_allGame[oneGame.p_index] or _formLogon then 
            oneGame:setIsNewGameData(false)
        else
            oneGame:setIsNewGameData(true)
        end
        temp[oneGame.p_index] = oneGame
    end
    self.p_allGame = temp

end

function PinBallGoData:getList()
    return self.p_allGame
end

function PinBallGoData:getGameDataByIndex(index)
    return self.p_allGame[index]
end

function PinBallGoData:getRefName()
    return  ACTIVITY_REF.PinBallGo
end

return PinBallGoData
