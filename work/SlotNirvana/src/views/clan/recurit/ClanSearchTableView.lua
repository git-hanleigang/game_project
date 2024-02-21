--[[
Author: cxc
Date: 2021-02-25 15:34:18
LastEditTime: 2021-03-17 10:32:28
LastEditors: Please set LastEditors
Description: 搜索公会 tableView
FilePath: /SlotNirvana/src/views/clan/recurit/ClanSearchTableView.lua
--]]
local BaseTable = util_require("base.BaseTable")
local ClanSearchTableView = class("ClanSearchTableView", BaseTable)

function ClanSearchTableView:ctor(param)
    ClanSearchTableView.super.ctor(self, param)
end

function ClanSearchTableView:cellSizeForTable(table, idx)
    return 1062, 112
end

function ClanSearchTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.clan.recurit.ClanSearchClanCell")
        cell:addChild(cell.view)
        cell.view:move(1062*0.5, 112*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    self._cellList[idx + 1] = cell.view

    return cell
end

-- 触摸的处理
function ClanSearchTableView:_onTouchBegan( event )
    local touchPoint = cc.p( event.x,event.y )
    self._pointTouchBegin = touchPoint

    return ClanSearchTableView.super._onTouchBegan( self,event )
end
function ClanSearchTableView:_onTouchEnded( event )
    local touchPoint = cc.p( event.x,event.y )
    local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)

    if distance > 10 then
        return
    end

    local data = self:getViewData()
    if not data then
        return
    end

    for i=1, #data do
        local cell = self:getCellByIndex(i)
        if cell and cell.view then
            local btn = cell.view:findChild("btn_click")
            local isTouchPosPanel = self:onTouchCellChildNode( btn,touchPoint )
            if isTouchPosPanel then
                cell.view:popBaseInfoPanel()
                return
            end
        end
    end
end

return ClanSearchTableView 