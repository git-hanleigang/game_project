--[[
    弹板的等级和时间规则
    author:{author}
    time:2020-08-18 20:40:11
]]
local PopLimitInfo = class("PopLimitInfo")

function PopLimitInfo:ctor()
    self.p_id = 0
    self.p_description = ""
    self.p_ref = ""
    -- 点位ID
    self.p_posId = -1
    -- 弹板信息ID
    self.p_popUpId = -1
    -- 筛选优先级
    self.p_filtOrder = 0
    -- 等级规则类型
    self.p_levelType = 1
    -- 按特定等级
    self.p_levelFix = ""
    -- 按等级范围间隔
    self.p_levelMin = -1
    self.p_levelMax = -1
    self.p_levelDiff = 1
    -- 时间规则类型
    self.p_timeType = 1
    -- 按周期
    self.p_weekDay = ""
    self.p_openTime = ""
    self.p_duration = 0
    -- 按日期
    self.p_startExpairAt = 0
    self.p_endExpairAt = 0
end

function PopLimitInfo:parseData(data)
    self.p_id = tonumber(data.levelPopupId)
    self.p_description = data.description
    self.p_ref = data.programName
    self.p_posId = data.posId
    self.p_popUpId = data.popupId
    self.p_filtOrder = tonumber(data.filtOrder)
    self.p_levelType = tonumber(data.levelType)
    self.p_levelFix = data.fixLevel
    self.p_levelMin = tonumber(data.levelMin)
    self.p_levelMax = tonumber(data.levelMax)
    self.p_levelDiff = tonumber(data.levelDiff)
    self.p_timeType = tonumber(data.timeType)
    self.p_weekDay = data.weekDay
    self.p_openTime = data.openTime
    self.p_duration = tonumber(data.duration)
    if data.startDate and data.startDate ~= "" then
        self.p_startExpairAt = util_getymd_time(data.startDate)
    end
    if data.endDate and data.endDate ~= "" then
        self.p_endExpairAt = util_getymd_time(data.endDate)
    end
end

function PopLimitInfo:getPosId()
    return self.p_posId
end

function PopLimitInfo:getPopUpId()
    return self.p_popUpId
end

-- 筛选优先级
function PopLimitInfo:getFiltOrder()
    return self.p_filtOrder
end

-- 检查等级规则
function PopLimitInfo:checkLevelRule(curLevel)
    if tonumber(self.p_levelType) == -1 then
        -- 忽略等级判断
        return true
    elseif tonumber(self.p_levelType) == 1 then
        -- 固定等级
        local lvList = string.split(self.p_levelFix, ";")
        for i = 1, #lvList do
            local level = lvList[i]
            if tonumber(level) == curLevel then
                return true
            end
        end
    elseif tonumber(self.p_levelType) == 2 then
        -- 等级范围
        local lvLeft = tonumber(self.p_levelMin)
        local lvRight = tonumber(self.p_levelMax)
        local lvRepeat = tonumber(self.p_levelDiff)
        local checkLv = lvLeft
        while curLevel > lvLeft do
            if lvRight > 0 and (checkLv > lvRight or curLevel > lvRight) then
                break
            end

            checkLv = checkLv + lvRepeat

            if checkLv == curLevel then
                return true
            elseif checkLv > curLevel then
                break
            end
        end
    end
    return false
end

-- 检查日期规则
function PopLimitInfo:checkDateRule(timestamp)
    if tonumber(self.p_timeType) == -1 then
        -- 忽略判断
        return true
    end

    local _TM = util_UTC2TZ(timestamp, -8)
    -- 时间戳转成秒
    local secs = math.floor(timestamp / 1000)
    if tonumber(self.p_timeType) == 1 then
        -- 按周期
        local weekList = string.split(self.p_weekDay, ";")
        for i = 1, #weekList do
            local week = weekList[i]
            if tonumber(week) == _TM.week then
                return true
            end
        end
    elseif tonumber(self.p_timeType) == 2 then
        -- 按时间段
        if self.p_startExpairAt > 0 and self.p_startExpairAt > secs then
            return false
        end

        if self.p_endExpairAt > 0 and self.p_endExpairAt < secs then
            return false
        end

        return true
    end

    return false
end

return PopLimitInfo
