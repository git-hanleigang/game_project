
local BaseTable = util_require("base.BaseTable")
local CollectLevelTable = class("CollectLevelTable", BaseTable)

function CollectLevelTable:ctor(param)
    CollectLevelTable.super.ctor(self, param)
end

function CollectLevelTable:reload( _items ,_scale,_type)
    if not _scale then
        _scale = 1
    end 
    self.m_scale = 1/_scale
    _items = _items or {}
    self.item_list = _items
    self.m_type = _type
    
    CollectLevelTable.super.reload( self, self.item_list )
end

function CollectLevelTable:cellSizeForTable(table, idx)
    return 960*self.m_scale, 500*self.m_scale
end

function CollectLevelTable:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
        cell.view = nil
    end
    if cell.view == nil then
        cell.view = cc.Layer:create()
        cell.view:setContentSize(930,500)
        local node = util_createView("views.CollectLevelCode.CollectBigCell")
        local scale = 1/(node:getUIScalePro())
        cell.view:addChild(node)
        node:setPosition(0,300*scale)
        
        node:updataLevelCell(self.item_list[idx+1],idx,self.m_type)
        cell:addChild(cell.view)
        cell.view:setName("collectLCell")
        self._cellList[idx + 1] = cell.view
    end

    return cell
end

return CollectLevelTable 