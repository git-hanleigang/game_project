--[[
Author: your name
Date: 2021-12-07 18:05:40
LastEditTime: 2021-12-07 18:05:42
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagYoursTableView.lua
--]]
local BaseTable = util_require("base.BaseTable")
local LotteryTagYoursTableView = class("LotteryTagYoursTableView", BaseTable)

function LotteryTagYoursTableView:ctor(param)
    LotteryTagYoursTableView.super.ctor(self, param)
end

function LotteryTagYoursTableView:cellSizeForTable(table, idx)
    return 490, 77
end

function LotteryTagYoursTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.lottery.mainUI.LotteryTagUIYoursCell")
        cell:addChild(cell.view)
        cell.view:move(490*0.5, 77*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(idx + 1, data)
    self._cellList[idx + 1] = cell.view

    return cell
end

function LotteryTagYoursTableView:reload(_sourceData)
    -- LotteryTagYoursTableView.super.reload(self, sourceData)

    _sourceData = _sourceData or {}
    -- 加载 tableview
    self._cellList = {}

    self:setViewData(_sourceData)

    self._rowNumber = #self._viewData

    self:_initCellPos()

    self._unitTableView:reloadData()

    self:_setScrollNoticeNode()
end

function LotteryTagYoursTableView:playSweepEffect()
    -- cxc 2021-12-14 10:12:12 改为值播放最新选择的彩票号码特效
    local cell = self:getCellByIndex(1)
    if cell and not tolua.isnull(cell.view) then
        cell.view:playSweepEffect()
    end

    -- cxc 2021-12-08 10:15:12 改为随机播放 彩票号码特效
    -- local showItemList = {}
    -- local container = self._unitTableView:getContainer()
    -- for k, cell in pairs(container:getChildren()) do
    --     table.insert(showItemList, cell.view)
    -- end

    -- if #showItemList == 0 then
    --     return
    -- end

    -- local efItem = showItemList[util_random(1, #showItemList)]
    -- if tolua.isnull(efItem) then
    --     return
    -- end

    -- efItem:playSweepEffect()
end

return LotteryTagYoursTableView 
