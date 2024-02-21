---
-- 时间函数 ， 处理时间格式转化获取时间等。。  分钟转秒，  或者 分钟转天等都在这里
--

---
--获取系统时间
function GD.util_get_date()
    local tm = os.date("*t")

    --    if isIos() then
    --        local serverTime=cx.NativeToolIF:getServerTime()
    --        print("----server time:",serverTime)
    --        tm = os.time(serverTime)
    --        print("----server time:",tm)
    --
    --        print_table("tm",tm)
    --    end
    --    log(tm.year.."."..tm.month.."."..tm.day.." "..tm.hour..":"..tm.min..":"..tm.sec)
    return tm
end

--根据年月日获取时间戳2019-05-20 10:10:10
function GD.util_getymd_time(strTime, activityName)
    if not strTime then
        --添加报错屏蔽如果传入空获取当前时间减10秒当做开启时间
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        --减10秒防止出现负数
        curTime = curTime - 10
        return curTime
    end
    local year = tonumber(string.sub(strTime, 1, 4))
    local month = tonumber(string.sub(strTime, 6, 7))
    local day = tonumber(string.sub(strTime, 9, 10))

    local hour = tonumber(string.sub(strTime, 12, 13))
    local min = tonumber(string.sub(strTime, 15, 16))
    local sec = tonumber(string.sub(strTime, 18, 19))

    local time = os.time({day = day, month = month, year = year, hour = 0, minute = 0, second = 0, isdst = false})
    if not time then
        strTime = tostring(strTime)
        activityName = activityName or "NULL"
        release_print("--------------------------------strTime = " .. strTime .. ", activityName = " .. activityName)
    end
    time = time + hour * 3600 + min * 60 + sec
    time = util_LoaclChangeUtcTime(time, activityName)
    return time
end
--根据本地时间和时区转化utc时间
function GD.util_LoaclChangeUtcTime(time, activityName)
    --utc时区额外增加8小时
    local otherZone = 28800
    local a = os.date("!*t", time)
    local b = os.date("*t", time)

    if a.hour == nil or a.min == nil or a.sec == nil or b.hour == nil or b.min == nil or b.sec == nil then
        activityName = activityName or "NULL"
        release_print("ERROR[maqun]--------------------------------activityName = " .. activityName .. "------ time = " .. (time or "NULL"))
        release_print(debug.traceback())
    end
    local timeA = os.time({day = a.day, month = a.month, year = a.year, hour = 0, minute = 0, second = 0, isdst = false}) + a.hour * 60 * 60 + a.min * 60 + a.sec
    local timeB = os.time({day = b.day, month = b.month, year = b.year, hour = 0, minute = 0, second = 0, isdst = false}) + b.hour * 60 * 60 + b.min * 60 + b.sec

    local timeZone = timeB - timeA + otherZone
    time = time + timeZone
    return time
end

-- 时间戳转时区时间
-- timeZone  西8：-8    东8：8
function GD.util_UTC2TZ(timestamp, timeZone)
    timeZone = timeZone or 0
    -- 先转成格林威治时间
    local a = os.date("!*t", timestamp)
    local timeA = os.time({day = a.day, month = a.month, year = a.year, hour = 0, minute = 0, second = 0, isdst = false}) + a.hour * 60 * 60 + a.min * 60 + a.sec
    -- 计算所在时区时间
    local _time = timeA + timeZone * 3600
    -- 返回时间结构
    return os.date("*t", _time), _time
end

---
--获取系统年月日
function GD.util_get_ymd()
    local tm = os.date("*t")
    --    log(tm.year.."."..tm.month.."."..tm.day.." "..tm.hour..":"..tm.min..":"..tm.sec)
    return {year = tm.year, month = tm.month, day = tm.day, hour = 0, min = 0, sec = 0}
end

--[[
    @desc: 获得某天00:00:00的时间戳
    author:{author}
    time:2018-12-04 17:39:18
    --@tm:
    @return:
]]
function GD.util_get_Oneday_TimeStamp(cDateCurrectTime)
    -- body
    if not cDateCurrectTime then
        return 0
    end

    local cDateTodayTime = os.time({year = cDateCurrectTime.year, month = cDateCurrectTime.month, day = cDateCurrectTime.day, hour = 0, min = 0, sec = 0, isdst = false})

    return cDateTodayTime
end
--[[
    @desc: 获得某天00:00:00的时间戳 测试倒计时用 可配置相应时间
    author:{author}
    time:2018-12-04 17:39:18
    --@tm:
    @return:
]]
function GD.util_get_Oneday_TimeStamp_test(cDateCurrectTime)
    if not cDateCurrectTime then
        return 0
    end

    local cDateTodayTime =
        os.time({year = cDateCurrectTime.year, month = cDateCurrectTime.month, day = cDateCurrectTime.day, hour = cDateCurrectTime.hour, min = cDateCurrectTime.min, sec = 0, isdst = false})

    return cDateCurrectTime
end

---
--年月日获取时间戳
--@{day=, month=, year=, hour=, minute=, second=}
function GD.util_ymd_trans_data(tm)
    tm.isdst = false
    return os.time(tm)
end
---
-- 返回当天剩余时间，距离23:59:59 的剩余时间  服务器时间0点
--
--@return #number 秒数
function GD.util_get_today_lefttime()
    local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    nowTime = math.floor(nowTime)
    local tm = os.date("!*t", (nowTime - 8 * 3600))

    local hour = 23 - tm.hour
    local min = 59 - tm.min
    local sec = 59 - tm.sec

    return hour * 3600 + min * 60 + sec
end

---
-- 传入一个格式化时间 返回下一天的格式化时间
--
function GD.util_getNextymd_format(tm, flag)
    flag = flag or "-"
    local tms = util_split(tm, flag)

    local year = tms[1]
    local month = tms[2]
    local day = tms[3]
    day = day + 1
    if month == 2 then --2月
        if year % 400 == 0 or (year % 100 ~= 0 and year % 4 == 0) then --闰年
            if day > 29 then
                day = 1
                month = month + 1
            end
        else
            --平年
            if day > 28 then
                day = 1
                month = month + 1
            end
        end
    elseif month == 4 or month == 6 or month == 9 or month == 11 then
        --小月
        if day > 30 then
            day = 1
            month = month + 1
        end
    else
        --大月
        if day > 31 then
            day = 1
            month = month + 1
            if month > 12 then
                month = 1
                year = year + 1
            end
        end
    end
    return string.format("%d%s%d%s%d", year, flag, month, flag, day)
end

---
-- 获取年月日
--
function GD.util_getymd_format(flag)
    flag = flag or "-"
    local tm = os.date("*t")

    return string.format("%d%s%d%s%d", tm.year, flag, tm.month, flag, tm.day)
end

---
--获取服务器 年月日

function GD.util_formatServerTime()
    local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)

    nowTime = math.floor(nowTime)

    local tm = os.date("*t", nowTime)

    return tm.year .. tm.month .. tm.day
end

--时间戳转为时间 YYYY-MM-DD HH:MM:SS
function GD.util_chaneTimeFormat(time)
    if not time then
        return ""
    end
    return os.date("%Y-%m-%d %H:%M:%S", time)
end

function GD.util_getymdhms_format(flag)
    local flag = flag or "-"
    local tm = os.date("*t")

    return get_format(tm, flag)
end

function GD.get_format(tm, flag)
    return string.format("%d%s%d%s%d%s%d%s%d%s%d", tm.year, flag, tm.month, flag, tm.day, flag, tm.hour, flag, tm.min, flag, tm.sec)
end

---
-- 拆分字符串获取年月日
--@value "2018-11-11-12-0-0"
--@return {year=0, month=0, day=0, hour=0, min=0, sec=0}
function GD.util_getymdhms_split(value, flag)
    local flag = flag or "-"
    local times = util_string_split(value, flag, true)
    local tm = {year = times[1] or 0, month = times[2] or 0, day = times[3] or 0, hour = times[4] or 0, min = times[5] or 0, sec = times[6] or 0}

    return tm
end

---
--获取时间，秒数<br/>
--1.date为nil,相对于xxx时间经过的秒数<br/>
--2.date~=nil,date装换为秒数<br/>
--@return #number 秒数
function GD.util_get_time(date)
    local tm = nil

    if date == nil then
        tm = os.time()
    else
        date.isdst = false
        tm = os.time(date)
    end
    return tm
end

---
--获取系统年月日,x年x月x日0点0分0秒，并转换为秒数<br/>
--@return #number 秒数
function GD.util_get_time_ymd()
    local ymd = util_get_ymd()
    local time = util_get_time(ymd)
    --    local date = os.date("*t",time)
    --    print_table("date2",date)
    return time
end

---
--判断当前日期是否是指定日期后的一天
--@param t number 时间秒数
--@return #boolean 是指定日期后的某天，返回true，否则false
function GD.util_is_new_day(t)
    local date = os.date("*t", t)
    --    print_table("date",date)
    local tm = get_date()
    if tm.year > date.year or tm.month > date.month or tm.day > date.day then
        log("new day")
        return true
    end
    --    log("old day")
    return false
end

--获取当前时间是一年中的第几周
function GD.util_today_week_num_in_years(OSTime)
    -- local days = os.date("%j",OSTime)
    local baseTime = OSTime - 28742400 -- 1970.11.30.0.0.0（周一） 基础时间

    if baseTime < 0 then
        baseTime = math.abs(baseTime)
    end

    local days = math.ceil(baseTime / ONE_DAY_TIME_STAMP) -- 这就是已经过去了多少天
    local _weekIndx = 0
    local _years = os.date("%Y", OSTime)
    if (days % 7) == 0 then
        _weekIndx = days / 7
    else
        _weekIndx = math.modf(days / 7) + 1
    end

    return _weekIndx, _years
end

--获取当前时间距离下一个星期一还剩余多少天多少小时
function GD.util_today_to_next_monday_time()
    local tm = os.date("*t", os.time())
    --星期一是一个周的第二天
    local _monday = 2
    local weekday = _monday - tm.wday
    local _weekday = 0
    if weekday >= 0 then
        _weekday = 6 - weekday
    else
        _weekday = 6 - math.abs(weekday)
    end
    return _weekday, 24 - tm.hour, 60 - tm.min, 60 - tm.sec
end

--是否是周末
function GD.util_is_weekend()
    local localTime = os.time()
    local serverTime = cx.NativeToolIF:getServerTime()
    local tm = os.date("*t", serverTime)
    --log("is_weekend:  server time:%d, tm.wday:%d", serverTime, tm.wday)
    if tm.wday == 1 or tm.wday == 7 then
        return true
    end
    return false
end

---
--判断当前日期是否是指定日期后的一天
--@param t number 时间秒数
--@return #boolean 是指定日期后的某天，返回true，否则false
function GD.util_is_new_day_2(t)
    local tnow = os.time()
    if os.difftime(tnow, t) > 86400 then --60*60*24
        log("new day 2")
        return true
    end
    log("old day 2")
    return false
end

---
--转换时间秒为倒计时hh:mm:ss形式
--@param time #int 秒数
--@return #string hh:mm:ss格式字符串
function GD.util_count_down_str(time)
    local hour = math.floor(time / 3600)
    local minute = math.floor((time % 3600) / 60)
    local second = math.floor(time % 60)

    local str = string.format("%02d:%02d:%02d", hour, minute, second)

    return str
end

function GD.util_count_down_str1(time)
    local minute = math.floor((time % 3600) / 60)
    local second = math.floor(time % 60)

    local str = string.format("%02d:%02d", minute, second)

    return str
end

function GD.util_count_down_str_change(time)
    local hour = math.floor(time / 3600)
    local minute = math.floor((time % 3600) / 60)
    local second = math.floor(time % 60)

    if hour > 0 then
        return string.format("%02d:%02d:%02d", hour, minute, second)
    else
        return string.format("%02d:%02d", minute, second)
    end
end

function GD.util_leftDays(time, isFloor)
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if time - curTime > 86400 then
        if isFloor then
            return math.floor((time - curTime) / 86400)
        else
            return math.ceil((time - curTime) / 86400)
        end
    else
        return 0
    end
end

--获取剩余天数
function GD.util_daysdemaining(time, isFloor)
    local isFullDay = true  -- 剩余时间是否满一天
    local days = util_leftDays(time, isFloor)
    if days == 1 then
        return string.format("%d DAY", days), false ,isFullDay
    elseif days > 1 then
        return string.format("%d DAYS", days), false,isFullDay
    else
        isFullDay = false
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        local isOver = false
        local tempTime = time - curTime
        if tempTime <= 0 then
            tempTime = 0
            isOver = true
        end
        return util_count_down_str(tempTime), isOver,isFullDay
    end
end

--获取剩余天数
function GD.util_daysdemaining1(time, days)
    local strDays = "%d DAYS"
    if days ~= nil then
        strDays = "%d " .. days
    end

    if time > 86400 then
        local t = math.ceil((time) / 86400)

        local str = string.format(strDays, t)
        return str
    end

    return util_count_down_str(time)
end
--新手quest专用的
function GD.util_daysdemaining2(time)
    local daysStr = "%d DAYS LEFT"
    local dayStr = "%d DAY LEFT"
    if time > 86400 then
        local t = math.ceil((time) / 86400)
        if t > 1 then
            local str = string.format(daysStr, t)
            return str
        else
            local str = string.format(dayStr, t)
            return str
        end
    end
    return util_count_down_str(time)
end

--获取当前是活动的第几天
function GD.util_daysforstart(time)
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end

    if curTime - time > 0 then
        local t = math.ceil((curTime - time) / 86400)
        return t
    end

    return 0
end

--转成年月日接口
--time时间戳
function GD.util_time_trans_tmData(time)
    if time and time >= 0 then
        local tb = {}
        tb.year = tonumber(os.date("%Y", time))
        tb.month = tonumber(os.date("%m", time))
        tb.day = tonumber(os.date("%d", time))
        tb.hour = tonumber(os.date("%H", time))
        tb.min = tonumber(os.date("%M", time))
        tb.sec = tonumber(os.date("%S", time))
        return tb
    end
end

---
-- 将秒数转化为 时分格式  mm:ss 形式
-- @return #return
function GD.util_hour_min_str(time)
    -- local hour = math.floor(time/3600)
    local minute = math.floor(time / 60)
    local second = math.floor(time % 60)

    local str = string.format("%02d:%02d", minute, second)

    return str
end

---
--转换时间格式。
--分钟转 小时 ，天数
--
function GD.util_formatMinToDay(secs)
    local str = ""
    local min = secs / 60
    if min <= 60 then
        str = string.format("%d", min)
    elseif min < 60 * 24 then
        str = string.format("%d", min / 24)
    else
        str = string.format("%d", min / (60 * 24))
    end

    return str
end

---
-- 格式化金钱数字： 每三位用 , 分割
-- 废弃：使用 util_getFromatMoneyStr
--
function GD.util_formatMoneyStr(nums)
    -- nums = tonumber(nums or 0) or 0
    return util_getFromatMoneyStr(nums)
    -- str = string.format("%0.f", nums)
    -- local strLen = string.len(str)
    -- local newStr = ""
    -- local flag = ","
    -- for index = strLen, 1, -3 do
    --     local begin = index - 2
    --     if begin < 0 then
    --         begin = 0
    --     end
    --     local subStr = string.sub(str, begin, index)

    --     -- strLen = strLen - 3
    --     if subStr == "" or index == strLen then
    --         flag = ""
    --     else
    --         flag = ","
    --     end

    --     newStr = subStr .. flag .. newStr
    -- end
    -- return newStr
end

GD.FormatMonth = {
    "Jan",
    "Feb",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
}

-- 格式化时间
-- 返回： May 29 2019 25:15
-- 返回： 03:32, May 07 2019
function GD.util_formatToSpecial(str)
    local t = os.date("*t", str)
    -- return string.format("%s %02d %d %02d:%02d", FormatMonth[t.month], t.day, t.year, t.hour, t.min)
    return string.format("%02d:%02d, %s %02d %d ", t.hour, t.min, FormatMonth[t.month], t.day, t.year)
end

function GD.util_getLeftTime(expireAt)
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = expireAt / 1000 - curTime
    return leftTime
end

--获取当前时间
function GD.util_getCurrnetTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return math.floor(curTime)
end
