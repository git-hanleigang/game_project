--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 17:43:57
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 17:44:05
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoChessUI.lua
Description: 扩圈小游戏 弹珠 剩余spin次数UI
--]]
local ExpandPlinkoChessUI = class("ExpandPlinkoChessUI", BaseView)

function ExpandPlinkoChessUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_map.csb"
end

function ExpandPlinkoChessUI:initUI(_gameData) 
    ExpandPlinkoChessUI.super.initUI(self)

    self.m_gameData = _gameData

    -- 钉子 节点
    self:initDingUI()
end

-- 钉子 节点
function ExpandPlinkoChessUI:initDingUI()
    local dingNodeList = {}
    for rowIdx = 1, 11 do
        local rowNode = self:findChild("node_ding_" .. rowIdx)
        dingNodeList[rowIdx] = {}
        for colIdx, colNode in pairs(rowNode:getChildren()) do
            local view = self:createDingUI()
            colNode:addChild(view)
            dingNodeList[rowIdx][colIdx] = view
        end
    end
end
function ExpandPlinkoChessUI:createDingUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoDingUI")
    return view
end

function ExpandPlinkoChessUI:onSpinSuccessEvt()
    self:updateLbLeftTimeUI()
    self:runCsbAction("start")
end

-- 获取12行 钉子节点x位置
function ExpandPlinkoChessUI:getRow12PosXList()
    local posXList = {}
    for i = 1, 2 do
        local rowNode = self:findChild("node_ding_" .. i)
        for _, colNode in pairs(rowNode:getChildren()) do
            table.insert(posXList, colNode:getPositionX())
        end
    end

    table.sort(posXList)
    return posXList
end

function ExpandPlinkoChessUI:getDingNodePosList(_startIdx)
    local pathList = G_GetMgr(G_REF.ExpandGamePlinko):getBallDropPath(_startIdx)
    local pathNodePosList = {}
    local tempDirection
    for idx, row_col in pairs(pathList) do
        local row, col, arr = self:getRowColArr(row_col, pathList[idx+1])
        if arr then
            tempDirection = arr
        end
        local dingNode = self:findChild(string.format("node_ding_%s_%s", row, col))
        local posW = dingNode:convertToWorldSpace(cc.p(0, 0))
        table.insert(pathNodePosList, {posW = posW, direction = tempDirection, view = dingNode:getChildByName("ExpandPlinkoDingUI")})
    end

    return pathNodePosList
end

function ExpandPlinkoChessUI:getRowColArr(_value, _nextValue)
    local row, col = string.match(_value, "(%d+)_(%d+)")
    local arr
    if _nextValue then
        local nRow, nCol = string.match(_nextValue, "(%d+)_(%d+)")
        arr = tonumber(col) < tonumber(nCol) and "RIGHT" or "LEFT"
    end

    if row % 2 == 1 then
        col = (col - 1) / 2 + 1
    else
        col = col / 2
    end

    return row, col, arr
end

return ExpandPlinkoChessUI