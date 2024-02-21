local BaseTable = util_require("base.BaseTable")
local UserInfoBirthdayEditTableView = class("UserInfoTableView", BaseTable)

local FORMAT_MONTH = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
}

function UserInfoBirthdayEditTableView:ctor(param)
    UserInfoBirthdayEditTableView.super.ctor(self, param)
    self.m_isTouch = false
end

function UserInfoBirthdayEditTableView:reload(_type, year, month)
    _type = _type or ""
    self.type = _type
    self.m_cellSize = {width = 200, height = 50}
    if _type == "year" then
        self.m_cellSize.width = 80
    elseif _type == "month" then
        self.m_cellSize.width = 200
    elseif _type == "day" then
        self.m_cellSize.width = 45
    end
    local splitItemsList = self:getItemList(_type, year, month)
    self.item_list = splitItemsList

    splitItemsList = splitItemsList or {}

    self:setViewData(splitItemsList)

    self:_initCellPos()

    self._unitTableView:reloadData()

    self:_setScrollNoticeNode()
end

function UserInfoBirthdayEditTableView:getItemList(_type, year, month)
    local splitItemsList = {}
    local nowTime = util_getCurrnetTime()
    local tm = os.date("*t", nowTime)
    if _type == "year" then
        local startYear = 1900
        local endYear = tm.year
        for i = startYear, endYear do
            splitItemsList[#splitItemsList + 1] = i
        end
        splitItemsList[#splitItemsList + 1] = ""
    elseif _type == "month" then
        if year and year == tm.year then
            for i = 1, tm.month do
                splitItemsList[#splitItemsList + 1] = FORMAT_MONTH[i]
            end
        else
            splitItemsList = clone(FORMAT_MONTH)
        end
        splitItemsList[#splitItemsList + 1] = ""
    elseif _type == "day" then
        local maxDay = self:getMaxDayByYearAndMonth(year, month)
        for i = 1, maxDay do
            splitItemsList[#splitItemsList + 1] = string.format("%02d", i)
        end
        splitItemsList[#splitItemsList + 1] = ""
    end
    return splitItemsList
end

-- 是否是闰年
function UserInfoBirthdayEditTableView:isLeapYear(year)
    if year % 400 == 0 or (year % 100 ~= 0 and year % 4 == 0) then --闰年
        return true
    end
    return false
end

-- 根据年月得到天数
function UserInfoBirthdayEditTableView:getMaxDayByYearAndMonth(year, month)
    local maxInx = 31
    local nowTime = util_getCurrnetTime()
    local tm = os.date("*t", nowTime)
    if year and month then
        if year == tm.year and month == tm.month then
            maxInx = tonumber(tm.day) or 31
        else
            if month == 2 then
                maxInx = self:isLeapYear(year) and 29 or 28
            else
                local month31 = {1, 3, 5, 7, 8, 10, 12}
                local isInArr = table.indexof(month31, month)
                maxInx = isInArr and 31 or 30
            end
        end
    end
    return maxInx
end

function UserInfoBirthdayEditTableView:cellSizeForTable(table, idx)
    return self.m_cellSize.width, self.m_cellSize.height
end

function UserInfoBirthdayEditTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    local index = idx + 1
    if cell.view == nil then
        cell.view = self:createNode(index)
        cell.view:setPosition(self.m_cellSize.width / 2, self.m_cellSize.height / 2)
        cell:addChild(cell.view)
        self._cellList[#self._cellList + 1] = cell.view
    end
    local data = self._viewData[index]
    cell.view:updataCell(data, index)
    return cell
end

function UserInfoBirthdayEditTableView:tableCellTouched(table, cell)
    print("点击了cell：" .. cell:getIdx())
end

-- function UserInfoBirthdayEditTableView:_onTouchBegan(event)
--     self.m_isTouch = false
--     return UserInfoBirthdayEditTableView.super._onTouchBegan(self, event)
-- end

-- function UserInfoBirthdayEditTableView:_onTouchEnded(event)
--     self.m_isTouch = true
-- end

-- function UserInfoBirthdayEditTableView:_onTouchOutSideEnd(event)
--     self.m_isTouch = true
-- end

function UserInfoBirthdayEditTableView:scrollViewDidScroll()
    local offsetY = self:getTableOffsetY()
    local cellsizeW, cellsizeH = self:cellSizeForTable()
    local tableViewHeigh = self:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
    local totalCellNum = tableViewHeigh / cellsizeH
    local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
    self:setCellHighLight(inx)

    if not tolua.isnull(self.m_label) then
        local viewData = self:getViewData()
        local data = viewData[inx]
        if data then
            if self.type == "day" then
                self.m_label:setString(string.format("%02d", data))
            else
                self.m_label:setString("" .. data)
            end
        end
    end
end

function UserInfoBirthdayEditTableView:createNode(index)
    local node = util_createView("views.UserInfo.view.UserInfoBirthdayEditTableCell")
    node:setTag(index)
    return node
end

function UserInfoBirthdayEditTableView:getTableOffsetY()
    return self:getTable():getContentOffset().y
end

function UserInfoBirthdayEditTableView:getTabletotalHeight()
    return self:_getTabletotalHeight()
end

function UserInfoBirthdayEditTableView:isTouch()
    return self.m_isTouch
end

function UserInfoBirthdayEditTableView:setTouch(_bool)
    self.m_isTouch = _bool
end

function UserInfoBirthdayEditTableView:setLabel(_label)
    self.m_label = _label
end

function UserInfoBirthdayEditTableView:setCellHighLight(_inx)
    for i = 1, #self._cellList do
        local index = nil
        if self._cellList[i] and self._cellList[i].getIndex then
            index = self._cellList[i]:getIndex()
        end
        if index then
            self._cellList[i]:setLabelHighLight(_inx == index)
        end
    end
end

function UserInfoBirthdayEditTableView:setAutoScrollCallFunc(_func)
    if _func then
        self.m_onAutoScrollCallFunc = _func
    end
end

function UserInfoBirthdayEditTableView:onAutoScrollCallFunc()
    if self.m_onAutoScrollCallFunc then
        self.m_onAutoScrollCallFunc()
    end
end

return UserInfoBirthdayEditTableView
