--[[
Author: your name
Date: 2021-11-18 22:10:53
LastEditTime: 2021-11-18 22:11:29
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIHistoryTableView.lua
--]]
local BaseTable = util_require("base.BaseTable")
local LotteryTagUIHistoryTableView = class("LotteryTagUIHistoryTableView", BaseTable)

function LotteryTagUIHistoryTableView:ctor(param)
    LotteryTagUIHistoryTableView.super.ctor(self, param)
end

function LotteryTagUIHistoryTableView:cellSizeForTable(table, idx)
    return 920, 99
end

function LotteryTagUIHistoryTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.lottery.mainUI.LotteryTagUIHistoryCell")
        cell:addChild(cell.view)
        cell.view:move(920*0.5, 99*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    self._cellList[idx + 1] = cell.view

    return cell
end

return LotteryTagUIHistoryTableView 