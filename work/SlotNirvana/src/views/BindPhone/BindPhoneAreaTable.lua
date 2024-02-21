--[[
    手机区号tableView
    author:{author}
    time:2022-11-16 11:31:48
]]
local BaseTable = require("base.BaseTable")
local BindPhoneAreaTable = class("BindPhoneAreaTable", BaseTable)

local _cellW, _cellH = 160, 41

-- function BindPhoneAreaTable:ctor(params)
--     BindPhoneAreaTable.super.ctor(self, params)
--     self:createScrollSlider()

--     -- 监测互斥的方案 --
--     self.m_moveTable = true
--     self.m_moveSlider = true
-- end

function BindPhoneAreaTable:cellSizeForTable(table, idx)
    -- local _data = self._viewData[idx + 1]
    -- -- local line = math.ceil(string.len(_data.country) / 12)
    -- local strLines = string.split(_data.country, "|")
    -- self.m_cellW = _cellW
    -- self.m_cellH = _cellH * #strLines
    -- local cell = self._cellList[idx + 1]
    -- if cell then
    --     cell:setTextContentSize(cc.size(self.m_cellW, self.m_cellH))
    -- end
    -- return self.m_cellW, self.m_cellH + 5
    return _cellW, _cellH + 5
end

function BindPhoneAreaTable:getCellLuaPath()
    return "views.BindPhone.BindPhoneAreaCell"
end

function BindPhoneAreaTable:setCellTemp(cell)
    self.m_tempCell = cell
end

function BindPhoneAreaTable:tableCellAtIndex(table, idx)
    idx = idx + 1
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        local luaPath = self:getCellLuaPath()
        if luaPath and string.len(luaPath) > 0 then
            cell.view = util_createView(luaPath, self)
            cell:addChild(cell.view)
        end
    end

    local data = self._viewData[idx]
    cell.view:updateView(data, idx)
    self._cellList[idx] = cell.view
    return cell
end

-- 子类可能需要重写
-- function BindPhoneAreaTable:createScrollSlider()
--     -- 创建 slider滑动条 --
--     local bgFile = display.newSprite("#Dialog/ui_new/new_code_1.png")
--     local progressFile = display.newSprite("#Dialog/ui_new/new_code_1.png")
--     local thumbFile = display.newSprite("#Dialog/ui_new/new_code_2.png")

--     self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
--     self.m_slider:setPosition(self._tableSize.width + 20, self._tableSize.height / 2)
--     self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
--     self.m_slider:setRotation(90)
--     self.m_slider:setEnabled(true)
--     self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
--     self:addChild(self.m_slider)
-- end

-- function BindPhoneAreaTable:_initCellPos()
--     BindPhoneAreaTable.super._initCellPos(self)

--     local _dis = self:_getTabletotalHeight() - self._tableSize.height
--     if _dis > 0 then
--         self.m_slider:setVisible(true)
--         local valueMin = -_dis
--         self.m_slider:setMinimumValue(valueMin)
--         self.m_slider:setMaximumValue(0)
--         self.m_slider:setValue(valueMin)
--     else
--         self.m_slider:setVisible(false)
--     end
-- end

-- slider 滑动事件 --
-- function BindPhoneAreaTable:sliderMoveEvent()
--     self.m_moveTable = false
--     if self.m_moveSlider == true then
--         local sliderOff = self.m_slider:getValue()
--         self._unitTableView:setContentOffset(cc.p(0, sliderOff))
--     end
--     self.m_moveTable = true
-- end

--滚动事件
-- function BindPhoneAreaTable:scrollViewDidScroll(view)
--     self.m_moveSlider = false

--     if self.m_moveTable == true then
--         if self.m_slider ~= nil then
--             local offY = self._unitTableView:getContentOffset().y
--             self.m_slider:setValue(offY)
--         end
--     end
--     self.m_moveSlider = true
-- end

return BindPhoneAreaTable
