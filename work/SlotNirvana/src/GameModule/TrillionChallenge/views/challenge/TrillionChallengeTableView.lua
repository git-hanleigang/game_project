--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:28:39
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/challenge/TrillionChallengeTableView.lua
Description: 亿万赢钱挑战 排行榜tbview
--]]
local BaseTable = util_require("base.BaseTable")
local TrillionChallengeTableView = class("TrillionChallengeTableView", BaseTable)

function TrillionChallengeTableView:ctor(_params)
    TrillionChallengeTableView.super.ctor(self, _params)

    self._bHallNode = _params.bHallNode
    self._cellSize = cc.size(968, 114)
    if self._bHallNode then
        self._cellSize = cc.size(198, 44)
    end
    self._data = G_GetMgr(G_REF.TrillionChallenge):getRunningData()
end

function TrillionChallengeTableView:getCellLuaPath()
    if self._bHallNode then
        return "GameModule.TrillionChallenge.views.challenge.TrillionChallengeRankCell_Hall"
    end
    return "GameModule.TrillionChallenge.views.challenge.TrillionChallengeRankCell"
end

function TrillionChallengeTableView:cellSizeForTable(table, idx)
    return self._cellSize.width, self._cellSize.height
end

function TrillionChallengeTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView(self:getCellLuaPath())
        cell:addChild(cell.view)
        cell.view:move(self._cellSize.width*0.5, self._cellSize.height*0.5)
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1)
    self._cellList[idx + 1] = cell.view

    return cell
end

function TrillionChallengeTableView:reload(_data)
    TrillionChallengeTableView.super.reload(self, _data)

    -- 个人排名
    local bIn = self._data:checkSelfInRankList() -- 玩家是否在 排行列表里
    local selfRank = self._data:getRankSelf()
    if tolua.isnull(self._rankView) then
        self._rankView = util_createView(self:getCellLuaPath())
        local posW = self._parentPanel:convertToWorldSpace(cc.p(self._tableSize.width * 0.5, self._cellSize.height*0.5))
        local posL = cc.p(self:convertToNodeSpaceAR(posW))
        self:addChild(self._rankView, 99)
        self._rankView:move(posL)
    end
    self._rankView:updateUI(selfRank)
    self._rankView:setVisible(not bIn)
end

return TrillionChallengeTableView