--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-10 15:18:50
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-10 15:18:57
FilePath: /SlotNirvana/src/views/lottery/other/LotteryTicketRandomNumberTableView.lua
Description: 一键选号 TableView
--]]
local BaseTable = util_require("base.BaseTable")
local LotteryTicketRandomNumberTableView = class("LotteryTicketRandomNumberTableView", BaseTable)

function LotteryTicketRandomNumberTableView:ctor(param)
    LotteryTicketRandomNumberTableView.super.ctor(self, param)
end

function LotteryTicketRandomNumberTableView:cellSizeForTable(table, idx)
    return 570, 95
end

function LotteryTicketRandomNumberTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.lottery.other.LotteryTicketRandomNumberCell")
        cell:addChild(cell.view)
        cell.view:move(570*0.5, 95*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    self._cellList[idx + 1] = cell.view

    return cell
end

return LotteryTicketRandomNumberTableView 
