local BaseTable = util_require("base.BaseTable")
local HelpTableView = class("HelpTableView", BaseTable)

function HelpTableView:ctor(param)
    HelpTableView.super.ctor(self, param)
end

function HelpTableView:reload( _items,_type )
    _items = _items or {}
    self.item_list = _items
    self._cellList = {}
    self.m_type = _type
    HelpTableView.super.reload( self, _items )
end

function HelpTableView:cellSizeForTable(table, idx)
    return 841, 124
end

function HelpTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
        cell.view = nil
    end

    if cell.view == nil then
        if self.m_type == 1 then
            cell.view = util_createView("views.FirendCode.FirendHelpCell")
        else
            cell.view = util_createView("views.FirendCode.FirendMacyCell")
        end
        cell.view:setContentSize(841,122)
        cell.view:setPosition(420,61)
        cell.view:updataCell(self.item_list[idx+1],idx+1)
        cell:addChild(cell.view)
        cell.view:setName("helpCell")
        self._cellList[idx + 1] = cell.view
    end
    return cell
end

function HelpTableView:tableCellTouched(table, cell)
     print("点击了cell：" .. cell:getIdx())
end

return HelpTableView 