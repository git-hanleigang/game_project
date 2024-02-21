--[[
Author: cxc
Date: 2022-04-20 18:15:46
LastEditTime: 2022-04-20 18:15:47
LastEditors: cxc
Description: 关卡 热玩 玩家列表UI
FilePath: .SlotNirvana/src/views/ChooseLevel/SlotHotPlayerTableView.lua
--]]
local BaseTable = util_require("base.BaseTable")
local SlotHotPlayerTableView = class("SlotHotPlayerTableView", BaseTable)

function SlotHotPlayerTableView:ctor(param)
    SlotHotPlayerTableView.super.ctor(self, param)
end

function SlotHotPlayerTableView:cellSizeForTable(table, idx)
    return 130, 128
end

function SlotHotPlayerTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.ChooseLevel.SlotHotPlayerUI")
        cell:addChild(cell.view)
        cell.view:move(130*0.5, 128*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    self._cellList[idx + 1] = cell.view

    return cell
end

function SlotHotPlayerTableView:_onTouchBegan( event )
    local touchPoint = cc.p( event.x,event.y )
    self._pointTouchBegin = touchPoint

    return SlotHotPlayerTableView.super._onTouchBegan( self,event )
end

function SlotHotPlayerTableView:_onTouchEnded( event )
    local touchPoint = cc.p( event.x,event.y )
    local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)

    if distance > 20 then
        return
    end
    
    for i,node in pairs( self._cellList ) do
        local btn_head = node:findChild("btn_head")
        local isTouchPosPanel = self:onTouchCellChildNode( btn_head, touchPoint )
        if isTouchPosPanel then
            node:clickCell()
            return
        end
    end

end

return SlotHotPlayerTableView 