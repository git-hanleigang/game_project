--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-11 16:45:49
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-11 16:46:06
FilePath: /SlotNirvana/src/views/lottery/reward/skipReward/LotteryShowBetListTableView.lua
Description: 乐透 按跳过 本期个人所选号码 tableview
--]]
local BaseTable = util_require("base.BaseTable")
local LotteryShowBetListTableView = class("LotteryShowBetListTableView", BaseTable)

function LotteryShowBetListTableView:ctor(param)
    LotteryShowBetListTableView.super.ctor(self, param)
end

function LotteryShowBetListTableView:cellSizeForTable(table, idx)
    return 650, 72
end

function LotteryShowBetListTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.lottery.reward.skipReward.LotteryShowBetNumberCell")
        cell:addChild(cell.view)
        cell.view:move(650*0.5, 72*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(idx + 1, data)
    self._cellList[idx + 1] = cell.view

    return cell
end

return LotteryShowBetListTableView 
