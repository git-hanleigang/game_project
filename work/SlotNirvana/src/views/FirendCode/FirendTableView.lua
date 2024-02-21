local BaseTable = util_require("base.BaseTable")
local FirendTableView = class("FrameTableView", BaseTable)

function FirendTableView:ctor(param)
    FirendTableView.super.ctor(self, param)
end

function FirendTableView:reload( _items )
    _items = _items or {}
    local splitItemsList = self:getItemList(_items)
    self.item_list = splitItemsList
    self._cellList = {}
    self.item_num = 0
    FirendTableView.super.reload( self, splitItemsList )
end

function FirendTableView:getItemList(_items)
    local splitItemsList = {}
    for idx, itemInfo in ipairs(_items) do
        local newIdx = math.floor((idx-1) / 5) + 1
        if not splitItemsList[newIdx] then
            splitItemsList[newIdx] = {}
        end
        table.insert(splitItemsList[newIdx], itemInfo)
    end
    return splitItemsList
end

function FirendTableView:cellSizeForTable(table, idx)
    return 840, 180
end

function FirendTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
        cell.view = nil
    end

    if cell.view == nil then
        cell.view = cc.Layer:create()
        cell.view:setContentSize(840,170)
        for i,v in ipairs(self.item_list[idx+1]) do
            local node = self:createNode(i)
            node:setZOrder(1-i)
            node:setTag(i)
            node:updataCell(v,idx,i)
            cell.view:addChild(node)
            self.item_num = self.item_num + 1
            self._cellList[self.item_num] = node
        end
        cell:addChild(cell.view)
        cell.view:setName("avtCell")
    end
    return cell
end

function FirendTableView:tableCellTouched(table, cell)
     print("点击了cell：" .. cell:getIdx())
end

function FirendTableView:_onTouchBegan( event )
    local touchPoint = cc.p( event.x,event.y )
    self._pointTouchBegin = touchPoint

    return FirendTableView.super._onTouchBegan( self,event )
end

function FirendTableView:_onTouchEnded( event )
    local touchPoint = cc.p( event.x,event.y )
    local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)

    if distance > 20 then
        return
    end
end

function FirendTableView:createNode(index)
    local node = util_createView("views.FirendCode.FirendHeadCell")
    node:setContentSize(150,170)
    local pos_x = 100+160*(index-1)
    node:setPosition(pos_x,90)
    return node
end

return FirendTableView 