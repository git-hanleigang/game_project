--[[
    
]]
local BaseTable = require("base.BaseTable")
local QuestPassTableView = class("QuestPassTableView", BaseTable)

-- overwrite --
function QuestPassTableView:reload(_layer)
    self.m_cellSize = {width = 200, height = 465}
    self.m_boxCellSize = {width = 282, height = 465}
    self._cellList = {}
    self.m_passLayer = _layer
    QuestPassTableView.super.reload(self)
end

-- overwrite --
function QuestPassTableView:setViewData()
    local viewData = {}
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if self.m_gameData then
        self.m_passData = self.m_gameData:getPassData()
        viewData = self.m_passData:getTableUseData()
        self.m_maxIdx = #viewData
    end
    self._maxIndex = #viewData
    QuestPassTableView.super.setViewData(self, viewData)
end

-- overwrite --
function QuestPassTableView:cellSizeForTable(table, idx)
    if idx == self.m_maxIdx - 1 then
        return self.m_boxCellSize.width, self.m_boxCellSize.height
    else
        return self.m_cellSize.width, self.m_cellSize.height
    end
end

-- overwrite --
function QuestPassTableView:tableCellAtIndex(tableView, idx)
    local cell = tableView:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView(QUEST_CODE_PATH.QuestPassTableCell, self.m_passLayer)
        cell:addChild(cell.view)
        table.insert(self._cellList, cell.view)
    end

    if idx == self.m_maxIdx - 1 then
        cell.view:setPosition(0, 16)
    else
        cell.view:setPosition(25, 21)
    end

    -- Manager get data --
    self:setViewData()
    cell.view:loadDataUi(self._viewData[idx + 1], idx)
    return cell
end

-- 创建进度条
function QuestPassTableView:initProgress()
    -- 添加进度条 --
    if self._tableViewWidth then 
        self.m_progressNode = util_createView(QUEST_CODE_PATH.QuestPassProgress, self._tableViewWidth - self.m_cellSize.width - self.m_boxCellSize.width, self.m_cellSize)
        self.m_progressNode:setPosition(self.m_cellSize.width/2, self.m_cellSize.height/2 - 50)
        self._unitTableView:addChild(self.m_progressNode, 10000)
    end
end

function QuestPassTableView:setTablePos()
    local points = self.m_passData:getCurExp()
    local passData = self.m_passData:getFreeRewards()
    local pointIdx = 1
    local collectIdx = 0
    for i,v in ipairs(passData) do
        if points >= v.p_exp then
            pointIdx = i
        else
            break
        end
    end
    self:scrollTableViewByRowIndex(pointIdx, 0, 1)
end

function QuestPassTableView:hideEF()
    for i,v in ipairs(self._cellList) do
        v:hideEF()
    end
end

function QuestPassTableView:onEnter()
    QuestPassTableView.super.onEnter(self)
    self:initProgress()
    self:setTablePos()
end

-- function QuestPassTableView:onExit()
--     local eventDispatcher = self:getEventDispatcher()
--     if self._listener then
--         eventDispatcher:removeEventListener(self._listener)
--         self._listener = nil
--     end

--     if self._touchNode then
--         self._touchNode = nil
--     end
-- end


-- 重写父类
function QuestPassTableView:scrollViewDidScroll(view)
    QuestPassTableView.super.scrollViewDidScroll(self, view)

    local pos = self:getTable():getContentOffset()
    -- 滚动的时候同时刷新固定奖励
    local maxIndex = self:getMaxShowIndex()
    if maxIndex ~= nil then
        local previewIndex = self:getPreviewIndexFromIndex(maxIndex)
        if previewIndex and previewIndex ~= self.m_previewIndex then
            self.m_previewIndex = previewIndex
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_TABLEVIEW_MOVE_ONE, {show = true, index = previewIndex})
        end
    else
        self.m_previewIndex = nil
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_TABLEVIEW_MOVE_ONE, {show = false})
    end
end

function QuestPassTableView:initPreviewIndex()
    local maxIndex = self:getMaxShowIndex()
    if maxIndex ~= nil then
        self.m_previewIndex = self:getPreviewIndexFromIndex(maxIndex)
    end
end

function QuestPassTableView:getPreviewIndex()
    return self.m_previewIndex
end

function QuestPassTableView:getMaxShowIndex()
    local pos = self:getTable():getContentOffset()
    local offsetX = pos.x -- 默认是0，往左滑动时，是负数
    local fixedCellWidth = 200
    local cellWidht = self.m_cellSize.width
    local hidePosX = self._posList[self._maxIndex-1].x
    local maxShowPosX = self._tableSize.width - fixedCellWidth - cellWidht - offsetX -- offsetX 是负数，要用减
    maxShowPosX = math.max(maxShowPosX, 0)
    if maxShowPosX < hidePosX then
        local maxIndex = self:getIndexAtPos(maxShowPosX)
        return maxIndex
    end
    return nil
end

function QuestPassTableView:getPreviewIndexFromIndex(_maxIndex)
    local index = self.m_passData:getPreviewIndex(_maxIndex)
    if index and index ~= self.m_showMaxIndex then
        return index
    end
    return nil
end

function QuestPassTableView:getIndexAtPos(_offsetX)
    for i=1,#self._posList do
        if i > 1 then
            local prePos = self._posList[i-1]
            local curPos = self._posList[i]
            if _offsetX >= prePos.x  and _offsetX < curPos.x then
                return i-1
            end
        end
    end
end

function QuestPassTableView:getCellPos(_boxType, _level, _offset)
    if _offset == nil then
        _offset = cc.p(0, 0)
    end
    local pos = nil
    local cellNode = self:getCellByLevel(_boxType, _level)
    if cellNode then
        local cellNodePos = cc.p(cellNode:getParent():getPosition())
        local tableCell = self:cellAtIndex(_level)
        if tableCell then
            local tableCellPos = cc.p(tableCell:getPosition())
            local finalPos = cc.p(tableCellPos.x + cellNodePos.x + _offset.x, tableCellPos.y + cellNodePos.y + _offset.y)
            pos = tableCell:getParent():convertToWorldSpace(finalPos)
        end
    end
    return pos
end

function QuestPassTableView:getCellByLevel(_boxType, _level)
    local node = nil
    for k, v in pairs(self._cellList) do
        node = v:getCellByLevel(_boxType, _level)
        if node then
            break
        end
    end
    return node
end

return QuestPassTableView
