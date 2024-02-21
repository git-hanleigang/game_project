-- bingo比赛 bingo玩法数据

local BaseActivityData = require "baseActivity.BaseActivityData"
local BingoRushLevelData = class("BingoRushLevelData", BaseActivityData)

function BingoRushLevelData:ctor()
    BingoRushLevelData.super.ctor(self)
    self.m_gameData = nil
end

-- 解析bingo游戏数据
function BingoRushLevelData:parseData(data)
    if not data then
        return
    end

    if data.gameData then
        self.m_gameData = clone(data.gameData)
    end
end

--[[
    获取关卡数据
]]
function BingoRushLevelData:getGameData()
    return self.m_gameData
end


return BingoRushLevelData
