--[[
    
    author:{author}
    time:2023-03-14 21:50:48
]]
local BaseTable = require("base.BaseTable")
local BaseRankTable = class("BaseRankTable", BaseTable)

function BaseRankTable:ctor(...)
    BaseRankTable.super.ctor(self, ...)

    self.m_cellCsb = nil
    self.m_cellLua = nil
    -- 通用cell大小
    self.m_cellSize = self._cellSize or cc.size(813, 90)
    -- 滚动显示范围偏移 {上，下，左，右}（主要针对有mycell的情况）
    self.m_srOffset = {T = 0, B = 0, L = 0, R = 0}

    -- 自己独立的cell
    self.m_myRankCell = nil
    self.m_nodeMyCell = nil
    self.m_myCellIndex = nil
end

function BaseRankTable:setCellUiInfo(lua, csb, cellUIParams)
    self.m_cellLua = lua
    self.m_cellCsb = csb
    self.m_cellUIParams = cellUIParams
end

-- function BaseRankTable:getCellScale()
--     return self.m_cellScale or 1
-- end

function BaseRankTable:getCellLuaPath()
    -- 默认cell，上层可覆盖重写
    assert(self.m_cellLua, "cell lua path is nil!!!")
    return self.m_cellLua
end

function BaseRankTable:getCellCsb()
    assert(self.m_cellCsb, "cell csb path is nil!!!")
    return self.m_cellCsb
end

-- 通用cell大小
function BaseRankTable:getCellSize()
    return self.m_cellSize
end

-- 自身cell大小，针对自身的特殊显示
function BaseRankTable:getMyCellSize()
    -- 默认用通用大小，子类可重写
    return self.m_cellSize
end

function BaseRankTable:onEnter()
    BaseRankTable.super.onEnter(self)
    self:registerListener()
end

-- 注册消息事件
function BaseRankTable:registerListener()
end

function BaseRankTable:onExit()
    BaseRankTable.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function BaseRankTable:isLoaded()
    return self:numberOfCellsInTableView() > 0
end

function BaseRankTable:reload(sourceData, ...)
    if not sourceData or not next(sourceData) then
        return
    end

    local _sourceData = clone(sourceData)

    self.m_sourceData = _sourceData
    BaseRankTable.super.reload(self, sourceData)
end

function BaseRankTable:cellSizeForTable(table, idx)
    -- 默认大小，上层可覆盖重写
    local cellSize = self:getCellSize()
    return cellSize.width, cellSize.height
end

function BaseRankTable:getCellPosOffset(idx, offset)
    offset = offset or cc.p(0, 0)
    local cellSize = self:getCellSize()
    local posX, posY = cellSize.width / 2 + offset.x, cellSize.height / 2 + offset.y
    return cc.p(posX, posY)
end

function BaseRankTable:tableCellAtIndex(table, idx)
    idx = idx + 1
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        local luaPath = self:getCellLuaPath()
        if luaPath and string.len(luaPath) > 0 then
            cell.view = util_createView(luaPath, self:getCellCsb(), self.m_cellUIParams)
            cell:addChild(cell.view)
        end
    end

    local offsetPos = self:getCellPosOffset(idx)
    cell.view:setPosition(offsetPos)
    if cell.view.setRewardScale then
        cell.view:setRewardScale(self.m_itemscale)
    end
    local data = self._viewData[idx]
    cell.view:updateView(data, idx)


    self._cellList[idx] = cell.view

    self:checkCellVisible(idx)

    return cell
end

function BaseRankTable:scrollViewDidScroll(view)
    BaseRankTable.super.scrollViewDidScroll(self, view)
    self:updateMyCellPos()
end

-- tablebiew上自己的那一条cell要隐藏
function BaseRankTable:checkCellVisible(_idx)
    if self.m_myCellIndex == nil then
        return
    end
    local cellView = self._cellList[_idx]
    if cellView then
        cellView:setVisible(_idx ~= self.m_myCellIndex)
    end
end

-- 自己的单元信息
function BaseRankTable:initMyRankCellUI(userCsb)
    local myCell = self:getChildByName("MyRankCell")
    if myCell then
        -- 悬浮self cell存在，不重复创建，返回
        return
    end

    local luaPath = self:getCellLuaPath()
    if not luaPath or string.len(luaPath) == 0 then
        return
    end

    self.m_myRankCell = util_createView(luaPath, userCsb, {isHang = true})
    self.m_nodeMyCell = cc.Node:create()
    self.m_nodeMyCell:addChild(self.m_myRankCell)
    self.m_nodeMyCell:setName("MyRankCell")
    local pos = self:getCellPosOffset()
    self.m_myRankCell:setPosition(pos)
    self:addChild(self.m_nodeMyCell, 10)

    self.m_myRankCell:setVisible(false)
end

-- 更新自己排位信息
function BaseRankTable:updateMyRankCell(data, index)
    if tolua.isnull(self.m_myRankCell) then
        return
    end
    if not data or not index then
        self.m_myRankCell:setVisible(false)
        return
    end

    self.m_myCellIndex = index
    self.m_myRankCell:updateView(data, index)
    -- self.m_myRankCell:updateCellBright()
    self.m_myRankCell:setVisible(true)
    -- 更新位置
    self:updateMyCellPos()
end

-- 更新自身单元跟随位置
function BaseRankTable:updateMyCellPos()
    if self.m_myCellIndex == nil or self.m_myCellIndex < 0 then
        return
    end

    local tbHeight = self._tableSize.height
    local pos = self:getPosAtIndex(self.m_myCellIndex) or cc.p(0, 0)
    local tbOffset = self._unitTableView:getContentOffset()
    -- 计算相对位置
    local posY = pos.y + tbOffset.y
    local fPosY = math.min(math.max(posY, self.m_srOffset.B), (tbHeight - (self:getCellSize().height + self:getMyCellSize().height) / 2) + self.m_srOffset.T)
    
    local _offsetY = 0
    -- local _offsetPos = self:getCellPosOffset(self.m_myCellIndex)
    -- if _offsetPos then
    --     _offsetY = _offsetPos.y
    -- end
    local myCell = self:getChildByName("MyRankCell")
    if myCell then
        myCell:setPositionY(fPosY + _offsetY)
    end
end

function BaseRankTable:setRewardItemScale(_scale)
    self.m_itemscale = _scale
end

function BaseRankTable:getRewardItemScale()
    return self.m_itemscale or 1
end

return BaseRankTable
