--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local ActivityEntranceConfig = class("ActivityEntranceConfig")

function ActivityEntranceConfig:ctor()
    self.p_id = 0
    self.p_description = ""
    self.p_programName = ""
    self.p_descriptionName = ""
    self.p_open = 0
    self.p_type = 0
    self.p_weekDay = ""
    self.p_startDate = ""
    self.p_endDate = ""
end

function ActivityEntranceConfig:parseData(data)
    self.p_id = tonumber(data.id)
    self.p_description = data.description
    self.p_programName = data.programName
    self.p_descriptionName = data.descriptionName
    self.p_open = data.open
    self.p_type = data.type
    self.p_weekDay = data.weekDay
    if data.startDate ~= "null" and data.startDate ~= "" then
        self.p_startDate = data.startDate
    end
    if data.endDate ~= "null" and data.endDate ~= "" then
        self.p_endDate = data.endDate
    end
end

function ActivityEntranceConfig:isNovice()
    return tonumber(self.p_type) == 3
end

function ActivityEntranceConfig:getRefName()
    return self.p_programName
end

function ActivityEntranceConfig:getDescriptionNames()
    return string.split(self.p_descriptionName, "|")
end

function ActivityEntranceConfig:isOpen()
    if not self:isNovice() and (self.p_open or 0) <= 0 then
        return false
    end

    if self.p_weekDay ~= "-1" then
        local _date = util_UTC2TZ(math.floor(util_getCurrnetTime()), -8)
        local _weekList = string.split(self.p_weekDay, ";")
        for i = 1, #_weekList do
            -- 系统时间 周日是第一天
            local _wday = _date.wday - 1
            if _wday == 0 then
                _wday = 7
            end
            if tonumber(_weekList[i]) == _wday then
                return true
            end
        end
    elseif self.p_startDate ~= "" and self.p_endDate ~= "" then
        if self.p_startDate ~= nil and self.p_endDate ~= nil then
            local startTime = util_getymd_time(self.p_startDate, self.p_programName)
            local endTime = util_getymd_time(self.p_endDate, self.p_programName)
            local curTime = math.floor(util_getCurrnetTime())
            if curTime >= startTime and curTime < endTime then
                return true
            end
        end
    else
        return true
    end

    return false
end

return ActivityEntranceConfig
