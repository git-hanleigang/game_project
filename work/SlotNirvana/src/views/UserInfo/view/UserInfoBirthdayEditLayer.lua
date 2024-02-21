--[[
    个人信息生日编辑界面
]]
local UserInfoBirthdayEditLayer = class("UserInfoBirthdayEditLayer", BaseLayer)
local MONTH = {
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
    "December"
}

function UserInfoBirthdayEditLayer:ctor()
    UserInfoBirthdayEditLayer.super.ctor(self)

    self:setLandscapeCsbName("Activity/csd/Information/Iformation_EditBirthdayDate.csb")
    self:setExtendData("UserInfoBirthdayEditLayer")
end

function UserInfoBirthdayEditLayer:initDatas()
    self.m_yearTableViewOffY = 0
    self.m_monthTableViewOffY = 0
    self.m_dayTableViewOffY = 0
    -- 是否在移动
    self.m_yearTableViewIsMove = false
    self.m_monthTableViewIsMove = false
    self.m_dayTableViewIsMove = false
    -- 是否在矫正
    self.m_yearTableViewIsRectifing = false
    self.m_monthTableViewIsRectifing = false
    self.m_dayTableViewIsRectifing = false
end

function UserInfoBirthdayEditLayer:initCsbNodes()
    self.m_txt_month = self:findChild("Text_month")
    self.m_txt_day = self:findChild("Text_day")
    self.m_txt_year = self:findChild("Text_year")
    self.m_node_down = self:findChild("node_down")

    self.m_panel_month = self:findChild("Panel_month")
    self.m_panel_day = self:findChild("Panel_day")
    self.m_panel_year = self:findChild("Panel_year")

    self.m_btn_click = self:findChild("btn_click")
    self.m_node_mask = self:findChild("node_mask")
    self.m_node_button = self:findChild("node_button")
    self.m_btn_confirm = self:findChild("btn_confirm")
end

function UserInfoBirthdayEditLayer:initView()
    self:initBtnState()
    self:initTxtYMD()
    self:initFold()
    self:initTableView()
    -- self:tryCreateScheduler()
end

function UserInfoBirthdayEditLayer:initBtnState()
    local isCanEditBirthdayInfo = false
    local data = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
    if data then
        isCanEditBirthdayInfo = data:isCanEditBirthdayInfo()
    end
    self:setButtonLabelDisEnabled("btn_confirm", isCanEditBirthdayInfo)
    self.m_btn_click:setEnabled(isCanEditBirthdayInfo)
    local actionName = isCanEditBirthdayInfo and "idle" or "idle2"
    self:runCsbAction(actionName, true, nil, 60)
end

function UserInfoBirthdayEditLayer:initTxtYMD()
    local data = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
    local nowTime = util_getCurrnetTime()
    local tm = os.date("*t", nowTime)
    local _year, _month, _day = 1900 + math.floor((tm.year - 1900) / 2), 6, 15
    tm = {year = _year, month = _month, day = _day}
    if data and data:isEditBirthdayInfo() then
        local birthdayInfo = data:getBirthdayInformation()
        local birthdayDate = birthdayInfo.birthdayDate
        if birthdayDate then
            local year = string.sub(birthdayDate, 1, 4)
            local month = string.sub(birthdayDate, 5, 6)
            local day = string.sub(birthdayDate, 7, 8)
            tm = {year = tonumber(year), month = tonumber(month), day = tonumber(day)}
        end
    end
    self.m_defaultTm = tm
    self.m_txt_month:setString(MONTH[tm.month])
    self.m_txt_day:setString(string.format("%02d", tm.day))
    self.m_txt_year:setString("" .. tm.year)
end

function UserInfoBirthdayEditLayer:initFold()
    self.m_node_down:setVisible(false)
end

function UserInfoBirthdayEditLayer:initTableView()
    -- 创建year TableView
    local tmpSize = self.m_panel_year:getContentSize()
    local tableViewInfo = {
        tableSize = tmpSize,
        parentPanel = self.m_panel_year,
        directionType = 2 --1 水平方向 ; 2 垂直方向
    }
    local tableView = util_require("views.UserInfo.view.UserInfoBirthdayEditTableView")
    self.m_yearTableView = tableView:create(tableViewInfo)
    self.m_yearTableView:reload("year")
    self.m_yearTableView:getTable():setBounceable(false)
    self.m_panel_year:addChild(self.m_yearTableView)
    self.m_yearTableViewOffY = self.m_yearTableView:getTableOffsetY()
    self.m_yearTableView:setLabel(self.m_txt_year)
    local yearInx = (self.m_defaultTm.year - 1900) + 1
    self.m_yearTableView:scrollTableViewByRowIndex(yearInx, 0, 0)
    self.m_yearTableView:setAutoScrollCallFunc(handler(self, self.yearTableViewAutoScrollCallFunc))

    -- 创建month TableView
    local tmpSize = self.m_panel_month:getContentSize()
    local tableViewInfo = {
        tableSize = tmpSize,
        parentPanel = self.m_panel_month,
        directionType = 2 --1 水平方向 ; 2 垂直方向
    }
    local tableView = util_require("views.UserInfo.view.UserInfoBirthdayEditTableView")
    self.m_monthTableView = tableView:create(tableViewInfo)
    self.m_monthTableView:reload("month", self.m_defaultTm.year)
    self.m_monthTableView:getTable():setBounceable(false)
    self.m_panel_month:addChild(self.m_monthTableView)
    self.m_monthTableViewOffY = self.m_monthTableView:getTableOffsetY()
    self.m_monthTableView:setLabel(self.m_txt_month)
    self.m_monthTableView:scrollTableViewByRowIndex(self.m_defaultTm.month, 0, 0)
    self.m_monthTableView:setAutoScrollCallFunc(handler(self, self.monthTableViewAutoScrollCallFunc))

    -- 创建day TableView
    local tmpSize = self.m_panel_day:getContentSize()
    local tableViewInfo = {
        tableSize = tmpSize,
        parentPanel = self.m_panel_day,
        directionType = 2 --1 水平方向 ; 2 垂直方向
    }
    local tableView = util_require("views.UserInfo.view.UserInfoBirthdayEditTableView")
    self.m_dayTableView = tableView:create(tableViewInfo)
    self.m_dayTableView:reload("day", self.m_defaultTm.year, self.m_defaultTm.month)
    self.m_dayTableView:getTable():setBounceable(false)
    self.m_panel_day:addChild(self.m_dayTableView)
    self.m_dayTableViewOffY = self.m_dayTableView:getTableOffsetY()
    self.m_dayTableView:setLabel(self.m_txt_day)
    self.m_dayTableView:scrollTableViewByRowIndex(self.m_defaultTm.day, 0, 0)
    self.m_dayTableView:setAutoScrollCallFunc(handler(self, self.dayTableViewAutoScrollCallFunc))
end

function UserInfoBirthdayEditLayer:clickFunc(sender)
    if self.m_isTouch then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_confirm" then
        local YMD = string.format("%d%02d%02d", self.m_defaultTm.year, self.m_defaultTm.month, self.m_defaultTm.day)
        G_GetMgr(ACTIVITY_REF.Birthday):requestEditBirthday({birthdayModify = YMD})
    elseif name == "btn_click" then
        local isVisible = self.m_node_down:isVisible()
        local rotation = isVisible and 0 or 180
        self.m_node_down:setVisible(not isVisible)
        self.m_btn_click:setRotation(rotation)
        self.m_btn_confirm:setTouchEnabled(isVisible)
    end
end

function UserInfoBirthdayEditLayer:onEnter()
    UserInfoBirthdayEditLayer.super.onEnter(self)
    -- 修改生日消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_BIRTHDAY_REQUEST_EDIT
    )
end

function UserInfoBirthdayEditLayer:onExit()
    -- self:clearScheduler()
    UserInfoBirthdayEditLayer.super.onExit(self)
end

function UserInfoBirthdayEditLayer:yearTableViewAutoScrollCallFunc()
    local offsetY = self.m_yearTableView:getTableViewOffset()
    local cellsizeW, cellsizeH = self.m_yearTableView:cellSizeForTable()
    local tableViewHeigh = self.m_yearTableView:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
    local totalCellNum = tableViewHeigh / cellsizeH
    local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
    local viewData = self.m_yearTableView:getViewData()
    self.m_defaultTm.year = viewData[inx]
    self.m_yearTableView:scrollTableViewByRowIndex(inx, 3 / 60, 0)
    self.m_yearTableViewOffY = offsetY
    -- 刷新 day list
    self.m_dayTableView:reload("day", self.m_defaultTm.year, self.m_defaultTm.month)
    local maxDayInx = self:getMaxDayByYearAndMonth()
    local day = tonumber(self.m_defaultTm.day) or 1
    local dayInx = math.min(day, maxDayInx)
    self.m_defaultTm.day = dayInx
    self.m_dayTableView:scrollTableViewByRowIndex(dayInx, 0, 0)
    self.m_dayTableView:setCellHighLight(dayInx)
    -- 刷新 month list
    self.m_monthTableView:reload("month", self.m_defaultTm.year)
    local maxMonthInx = self:getMaxMonthByYear()
    local month = tonumber(self.m_defaultTm.month) or 1
    local monthInx = math.min(month, maxMonthInx)
    self.m_defaultTm.month = monthInx
    self.m_monthTableView:scrollTableViewByRowIndex(monthInx, 0, 0)
    self.m_monthTableView:setCellHighLight(monthInx)
end

function UserInfoBirthdayEditLayer:monthTableViewAutoScrollCallFunc()
    local offsetY = self.m_monthTableView:getTableViewOffset()
    local cellsizeW, cellsizeH = self.m_monthTableView:cellSizeForTable()
    local tableViewHeigh = self.m_monthTableView:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
    local totalCellNum = tableViewHeigh / cellsizeH
    local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
    self.m_defaultTm.month = inx
    self.m_monthTableView:scrollTableViewByRowIndex(inx, 3 / 60, 0)
    self.m_monthTableViewOffY = offsetY
    -- 刷新 day list
    self.m_dayTableView:reload("day", self.m_defaultTm.year, self.m_defaultTm.month)
    local maxInx = self:getMaxDayByYearAndMonth()
    local day = tonumber(self.m_defaultTm.day) or 1
    local dayInx = math.min(day, maxInx)
    self.m_defaultTm.day = dayInx
    self.m_dayTableView:scrollTableViewByRowIndex(dayInx, 0, 0)
    self.m_dayTableView:setCellHighLight(dayInx)
end

function UserInfoBirthdayEditLayer:dayTableViewAutoScrollCallFunc()
    local offsetY = self.m_dayTableView:getTableViewOffset()
    local cellsizeW, cellsizeH = self.m_dayTableView:cellSizeForTable()
    local tableViewHeigh = self.m_dayTableView:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
    local totalCellNum = tableViewHeigh / cellsizeH
    local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
    local maxInx = self:getMaxDayByYearAndMonth()
    inx = math.min(inx, maxInx)
    self.m_dayTableView:scrollTableViewByRowIndex(inx, 3 / 60, 0)
    self.m_dayTableViewOffY = offsetY
    self.m_defaultTm.day = inx
end

------------------------------ 定时器 （tableview滑动停止时，矫正位置）------------------------------
-- function UserInfoBirthdayEditLayer:onUpdateSec()
--     -- 年
--     if self.m_yearTableView:isTouch() then
--         local offsetY = self.m_yearTableView:getTableOffsetY()
--         if self.m_yearTableViewOffY ~= offsetY and self.m_yearTableViewIsRectifing == false then
--             self.m_yearTableViewIsMove = true
--             self.m_yearTableViewOffY = offsetY
--         else
--             if not self.m_yearSameTime then
--                 self.m_yearSameTime = 3
--             end
--             self.m_yearSameTime = self.m_yearSameTime - 1
--             if self.m_yearSameTime <= 0 then -- 3帧的位置都一样则认为已经停下了
--                 self.m_yearSameTime = 0
--                 if not self.m_yearRectifyTime then
--                     self.m_yearRectifyTime = 3
--                 end
--                 self.m_yearRectifyTime = self.m_yearRectifyTime - 1
--                 if self.m_yearTableViewIsRectifing and self.m_yearRectifyTime <= 0 then
--                     self.m_yearSameTime = 3
--                     self.m_yearRectifyTime = 3
--                     self.m_yearTableViewIsRectifing = false
--                     self.m_yearTableViewOffY = offsetY
--                     self.m_yearTableView:setTouch(false)
--                 end
--                 if self.m_yearTableViewIsMove and self.m_yearTableViewIsRectifing == false then
--                     self.m_yearTableViewIsRectifing = true
--                     self.m_yearTableViewIsMove = false
--                     local cellsizeW, cellsizeH = self.m_yearTableView:cellSizeForTable()
--                     local tableViewHeigh = self.m_yearTableView:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
--                     local totalCellNum = tableViewHeigh / cellsizeH
--                     local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
--                     local viewData = self.m_yearTableView:getViewData()
--                     self.m_defaultTm.year = viewData[inx]
--                     self.m_yearTableView:scrollTableViewByRowIndex(inx, 3 / 60, 0)
--                     self.m_yearTableViewOffY = offsetY
--                     -- 刷新 day list
--                     self.m_dayTableView:reload("day", self.m_defaultTm.year, self.m_defaultTm.month)
--                     local maxDayInx = self:getMaxDayByYearAndMonth()
--                     local day = tonumber(self.m_defaultTm.day) or 1
--                     local dayInx = math.min(day, maxDayInx)
--                     self.m_defaultTm.day = dayInx
--                     self.m_dayTableView:scrollTableViewByRowIndex(dayInx, 0, 0)
--                     self.m_dayTableView:setCellHighLight(dayInx)
--                     -- 刷新 month list
--                     self.m_monthTableView:reload("month", self.m_defaultTm.year)
--                     local maxMonthInx = self:getMaxMonthByYear()
--                     local month = tonumber(self.m_defaultTm.month) or 1
--                     local monthInx = math.min(month, maxMonthInx)
--                     self.m_defaultTm.month = monthInx
--                     self.m_monthTableView:scrollTableViewByRowIndex(monthInx, 0, 0)
--                     self.m_monthTableView:setCellHighLight(monthInx)
--                 end
--             end
--         end
--     end
--     -- 月
--     if self.m_monthTableView:isTouch() then
--         local offsetY = self.m_monthTableView:getTableOffsetY()
--         if self.m_monthTableViewOffY ~= offsetY and self.m_monthTableViewIsRectifing == false then
--             self.m_monthTableViewIsMove = true
--             self.m_monthTableViewOffY = offsetY
--         else
--             if not self.m_monthSameTime then
--                 self.m_monthSameTime = 3
--             end
--             self.m_monthSameTime = self.m_monthSameTime - 1
--             if self.m_monthSameTime <= 0 then -- 3帧的位置都一样则认为已经停下了
--                 self.m_monthSameTime = 0
--                 if not self.m_monthRectifyTime then
--                     self.m_monthRectifyTime = 3
--                 end
--                 self.m_monthRectifyTime = self.m_monthRectifyTime - 1
--                 if self.m_monthTableViewIsRectifing and self.m_monthRectifyTime <= 0 then
--                     self.m_monthSameTime = 3
--                     self.m_monthRectifyTime = 3
--                     self.m_monthTableViewIsRectifing = false
--                     self.m_monthTableViewOffY = offsetY
--                     self.m_monthTableView:setTouch(false)
--                 end
--                 if self.m_monthTableViewIsMove and self.m_monthTableViewIsRectifing == false then
--                     self.m_monthTableViewIsRectifing = true
--                     self.m_monthTableViewIsMove = false
--                     local cellsizeW, cellsizeH = self.m_monthTableView:cellSizeForTable()
--                     local tableViewHeigh = self.m_monthTableView:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
--                     local totalCellNum = tableViewHeigh / cellsizeH
--                     local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
--                     self.m_defaultTm.month = inx
--                     self.m_monthTableView:scrollTableViewByRowIndex(inx, 3 / 60, 0)
--                     self.m_monthTableViewOffY = offsetY
--                     -- 刷新 day list
--                     self.m_dayTableView:reload("day", self.m_defaultTm.year, self.m_defaultTm.month)
--                     local maxInx = self:getMaxDayByYearAndMonth()
--                     local day = tonumber(self.m_defaultTm.day) or 1
--                     local dayInx = math.min(day, maxInx)
--                     self.m_defaultTm.day = dayInx
--                     self.m_dayTableView:scrollTableViewByRowIndex(dayInx, 0, 0)
--                     self.m_dayTableView:setCellHighLight(dayInx)
--                 end
--             end
--         end
--     end
--     -- 日
--     if self.m_dayTableView:isTouch() then
--         local offsetY = self.m_dayTableView:getTableOffsetY()
--         if self.m_dayTableViewOffY ~= offsetY and self.m_dayTableViewIsRectifing == false then
--             self.m_dayTableViewIsMove = true
--             self.m_dayTableViewOffY = offsetY
--         else
--             if not self.m_daySameTime then
--                 self.m_daySameTime = 3
--             end
--             self.m_daySameTime = self.m_daySameTime - 1
--             if self.m_daySameTime <= 0 then -- 3帧的位置都一样则认为已经停下了
--                 self.m_daySameTime = 0
--                 if not self.m_dayRectifyTime then
--                     self.m_dayRectifyTime = 3
--                 end
--                 self.m_dayRectifyTime = self.m_dayRectifyTime - 1
--                 if self.m_dayTableViewIsRectifing and self.m_dayRectifyTime <= 0 then
--                     self.m_daySameTime = 3
--                     self.m_dayRectifyTime = 3
--                     self.m_dayTableViewIsRectifing = false
--                     self.m_dayTableViewOffY = offsetY
--                     self.m_dayTableView:setTouch(false)
--                 end
--                 if self.m_dayTableViewIsMove and self.m_dayTableViewIsRectifing == false then
--                     self.m_dayTableViewIsRectifing = true
--                     self.m_dayTableViewIsMove = false
--                     local cellsizeW, cellsizeH = self.m_dayTableView:cellSizeForTable()
--                     local tableViewHeigh = self.m_dayTableView:getTabletotalHeight() - 1 * cellsizeH -- 有一个占位的，不计算在内
--                     local totalCellNum = tableViewHeigh / cellsizeH
--                     local inx = totalCellNum - math.ceil((math.abs(offsetY) / cellsizeH) - 0.5) -- 从1-totalCellNum
--                     local maxInx = self:getMaxDayByYearAndMonth()
--                     inx = math.min(inx, maxInx)
--                     self.m_dayTableView:scrollTableViewByRowIndex(inx, 3 / 60, 0)
--                     self.m_dayTableViewOffY = offsetY
--                     self.m_defaultTm.day = inx
--                 end
--             end
--         end
--     end
-- end

-- function UserInfoBirthdayEditLayer:tryCreateScheduler()
--     if self.m_schedule then
--         return
--     end
--     self.m_schedule = schedule(self, handler(self, self.onUpdateSec), 1 / 60)
--     self:onUpdateSec()
-- end
-- -- 清楚定时器
-- function UserInfoBirthdayEditLayer:clearScheduler()
--     if not self.m_scheduler then
--         return
--     end
--     self:stopAction(self.m_scheduler)
--     self.m_scheduler = nil
-- end
------------------------------ 定时器 ------------------------------

-- 是否是闰年
function UserInfoBirthdayEditLayer:isLeapYear(year)
    if year % 400 == 0 or (year % 100 ~= 0 and year % 4 == 0) then --闰年
        return true
    end
    return false
end

-- 根据年月得到天数
function UserInfoBirthdayEditLayer:getMaxDayByYearAndMonth()
    local maxInx = 31
    local nowTime = util_getCurrnetTime()
    local tm = os.date("*t", nowTime)
    if self.m_defaultTm.year and self.m_defaultTm.month then
        if self.m_defaultTm.year == tm.year and self.m_defaultTm.month == tm.month then
            maxInx = tonumber(tm.day) or 31
        else
            if self.m_defaultTm.month == 2 then
                maxInx = self:isLeapYear(self.m_defaultTm.year) and 29 or 28
            else
                local month31 = {1, 3, 5, 7, 8, 10, 12}
                local isInArr = table.indexof(month31, self.m_defaultTm.month)
                maxInx = isInArr and 31 or 30
            end
        end
    end
    return maxInx
end

-- 根据年得到最大月数 （主要算当前时间的月份）
function UserInfoBirthdayEditLayer:getMaxMonthByYear()
    local maxInx = 12
    local nowTime = util_getCurrnetTime()
    local tm = os.date("*t", nowTime)
    if self.m_defaultTm.year then
        if self.m_defaultTm.year == tm.year then
            maxInx = tonumber(tm.month) or 31
        end
    end
    return maxInx
end

return UserInfoBirthdayEditLayer
