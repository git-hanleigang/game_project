--[[
    @desc: 
    author:JohnnyFred
    time:2022-07-04 18:17:23
]]
local NetWorkAddressLog = class("NetWorkAddressLog")
NetWorkAddressLog.urlTimeMap = {}
--记录最大条数
local kNetWorkAddressLog_MaxRecordCount = 10

--开始记录
function NetWorkAddressLog.startRecord(url,body)
    local urlTimeMap = NetWorkAddressLog.urlTimeMap
    local timeInfoList = urlTimeMap[url]
    if timeInfoList == nil then
        timeInfoList = {}
        urlTimeMap[url] = timeInfoList
    end
    table.insert(timeInfoList,{startTime = xcyy.SlotsUtil:getMilliSeconds(),body = body})
end

--停止记录
function NetWorkAddressLog.stopRecord(url,body)
    local urlTimeMap = NetWorkAddressLog.urlTimeMap
    local timeInfoList = urlTimeMap[url]
    if timeInfoList ~= nil then
        for k,v in ipairs(timeInfoList) do
            if v.body == body and v.stopTime == nil then
                v.stopTime = xcyy.SlotsUtil:getMilliSeconds()
                break
            end
        end
        local count = 0
        local disTotalTime = 0
        for k,v in ipairs(timeInfoList) do
            if v.startTime ~= nil and v.stopTime ~= nil then
                local disTime = v.stopTime - v.startTime
                disTotalTime = disTotalTime + disTime
                count = count + 1
                if count == kNetWorkAddressLog_MaxRecordCount then
                    NetWorkAddressLog.sendLog(url,disTotalTime)
                    break
                end
            end
        end
    end
end

--发送日志
function NetWorkAddressLog.sendLog(url,disTotalTime)
    local urlTimeMap = NetWorkAddressLog.urlTimeMap
    local timeInfoList = urlTimeMap[url]
    if gL_logData ~= nil and timeInfoList ~= nil then
        local logInfo = 
        {
            type = "Request",
            url = url,
            cost = disTotalTime,
            times = kNetWorkAddressLog_MaxRecordCount
        }
        gL_logData:syncUserData()
        gL_logData:syncEventData("urlGame")
        gL_logData.p_data = logInfo
        local messageData = gL_logData:getJsonData()
        local httpSender = xcyy.HttpSender:createSender()
        local function successCallBack(responseTable)
            httpSender:release()
        end
        local function failedCallBack(errorCode, errorData)
            httpSender:release()
        end
        local key = tostring(xcyy.GameBridgeLua:getDeviceUuid()) .. ":" .. tostring(PRODUCTID) .. tostring(xcyy.SlotsUtil:getMilliSeconds()) .. tostring(util_random(1,100))
        httpSender:sendLogMessage(messageData, LOG_RecordServer, key, successCallBack, failedCallBack)
        gL_logData:clearMessageData()
    end
    NetWorkAddressLog.clearURLTimeList(url)
end

--删除指定记录
function NetWorkAddressLog.removeURLTimeInfo(url,body)
    local urlTimeMap = NetWorkAddressLog.urlTimeMap
    local timeInfoList = urlTimeMap[url]
    if timeInfoList ~= nil then
        for i = #timeInfoList,1,-1 do
            local timeInfo = timeInfoList[i]
            if timeInfo ~= nil and timeInfo.body == body then
                table.remove(timeInfoList,i)
            end
        end
    end
end

--清除指定URL记录
function NetWorkAddressLog.clearURLTimeList(url)
    NetWorkAddressLog.urlTimeMap[url] = nil
end

--清除所有记录
function NetWorkAddressLog.clearURLTimeMap()
    NetWorkAddressLog.urlTimeMap = {}
end

return NetWorkAddressLog
