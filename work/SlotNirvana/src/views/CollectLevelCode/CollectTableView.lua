
local BaseTable = util_require("base.BaseTable")
local CollectTableView = class("CollectTableView", BaseTable)

function CollectTableView:ctor(param)
    CollectTableView.super.ctor(self, param)
end

function CollectTableView:reload( _items ,_scale)
    if not _scale then
        _scale = 1
    end 
    self.m_scale = 1/_scale
    _items = _items or {}
    local splitItemsList = self:getItemList(_items)
    self.item_list = splitItemsList
    
    CollectTableView.super.reload( self, splitItemsList )
end

function CollectTableView:getItemList(_items)
    local splitItemsList = {}
    for idx, itemInfo in ipairs(_items) do
        local newIdx = math.floor((idx-1) / 6) + 1
        if not splitItemsList[newIdx] then
            splitItemsList[newIdx] = {}
        end
        table.insert(splitItemsList[newIdx], itemInfo)
    end
    return splitItemsList
end

function CollectTableView:cellSizeForTable(table, idx)
    if idx == 3 then
        return 300*self.m_scale, 500*self.m_scale
    else
        return 960*self.m_scale, 500*self.m_scale
    end
end

function CollectTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
        cell.view = nil
    end
    if cell.view == nil then
        cell.view = cc.Layer:create()
        if idx == 3 then
            cell.view:setContentSize(280,500)
        else
            cell.view:setContentSize(930,500)
        end
        local node = util_createView("views.CollectLevelCode.CollectBigCell")
        local scale = 1/(node:getUIScalePro())
        cell.view:addChild(node)
        node:setPosition(0,300*scale)
        
        node:updataCell(self.item_list[idx+1],idx)
        cell:addChild(cell.view)
        cell.view:setName("collectCell")
        self._cellList[idx + 1] = cell.view
    end

    return cell
end

return CollectTableView 