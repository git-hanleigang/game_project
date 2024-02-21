--[[

    time:2022-12-14 19:33:14
]]
local BaseTable = require("base.BaseTable")
local FirebaseTestTable = class("FirebaseTestTable", BaseTable)

function FirebaseTestTable:ctor(...)
    FirebaseTestTable.super.ctor(self, ...)

    self._unitTableView:setSwallowTouches(false)
    -- self._unitTableView:setColor(cc.BLACK)
    -- self._unitTableView:setOpacity(50)
end

function FirebaseTestTable:cellSizeForTable(table, idx)
    return display.width / 2, 40
end

function FirebaseTestTable:tableCellAtIndex(table, idx)
    idx = idx + 1
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        local _lab = cc.Label:createWithSystemFont("Log", "", 24)
        _lab:setAnchorPoint(cc.p(0, 0))
        _lab:setPosition(cc.p(0, 0))
        cell.view = _lab
        cell:addChild(cell.view)
    end

    local data = self._viewData[idx]
    -- cell.view:updateView(data, idx)
    cell.view:setString(data)
    self._cellList[idx] = cell.view

    return cell
end



return FirebaseTestTable
