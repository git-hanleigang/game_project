--[[
Author: cxc
Date: 2022-04-15 15:32:35
LastEditTime: 2022-04-15 15:32:36
LastEditors: cxc
Description: 头像框 小游戏 数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameGameData.lua
--]]

local AvatarFrameGameData = class("AvatarFrameGameData")
local AvatarFrameGameCellData = util_require("GameModule.AvatarGame.model.AvatarFrameGameCellData")
local AvatarFrameGameWinnerData = util_require("GameModule.AvatarGame.model.AvatarFrameGameWinnerData")

-- message AvatarFrameGame {
--     optional int32 current = 1; //当前序号
--     optional int32 props = 2; //道具数量
--     optional int32 type = 3; //游戏类型 1普通状态 2上档状态
--     optional int32 playTimes = 4; //游戏次数
--     repeated AvatarFrameGameCell cells = 5; //格子
--     repeated AvatarFrameGameWinner winners = 6; //大赢家
--   }
function AvatarFrameGameData:ctor()
    self.m_curSeq = 0
    self.m_propsNum = 0
    self.m_type = 1
    self.m_cellList = {}
end

function AvatarFrameGameData:parseData(_data)
    if not _data then
        return
    end

    self.m_curSeq = _data.current or 0
    self.m_propsNum = _data.props or 0
    self.m_type = _data.type or 1
    self.m_playTimes = _data.playTimes or 0
    self.m_cellList = self:parseCellData(_data.cells or {})
    self.m_winners = self:parseWinners(_data.winners or {})
end

function AvatarFrameGameData:parseCellData(_list)
    local tempList = {}
    for i, data in ipairs(_list) do
        local cellData = AvatarFrameGameCellData:create()
        cellData:parseData(data)
        table.insert(tempList, cellData)
    end
    return tempList
end

function AvatarFrameGameData:parseWinners(_list)
  local tempList = {}
    for i, data in ipairs(_list) do
        local cellData = AvatarFrameGameWinnerData:create()
        cellData:parseData(data)
        table.insert(tempList, cellData)
    end
    return tempList
end

-- get 当前序号
function AvatarFrameGameData:getCurSeq()
    return self.m_curSeq
end
-- get 道具数量
function AvatarFrameGameData:setPropsNum(_num)
    self.m_propsNum = _num or 0
end
function AvatarFrameGameData:getPropsNum()
    return self.m_propsNum
end
-- get 游戏类型 1普通状态 2上档状态
function AvatarFrameGameData:getType()
    return self.m_type
end
-- get 格子数据
function AvatarFrameGameData:getCellList()
    return self.m_cellList
end

function AvatarFrameGameData:getPlayTimes()
    return self.m_playTimes
end

function AvatarFrameGameData:getWinners()
    return self.m_winners
end

return AvatarFrameGameData