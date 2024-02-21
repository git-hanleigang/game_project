--
-- 处理所有的log 请求
-- Author:{author}
-- Date: 2018-11-09 16:12:59
--
local NetworkLog = class("NetworkLog", require "network.NetWorkBase")
local LogData = require "log.LogData"

GD.gL_logData = nil -- 定义成全局的log 数据池
NetworkLog.m_udid = nil
local logFilePath = device.writablePath .. "splunkLogCache.dat"

function NetworkLog.saveLogToFile()
    if NetworkLog.logInfoList ~= nil then
        local strJsonData = cjson.encode(NetworkLog.logInfoList)
        cc.FileUtils:getInstance():writeStringToFile(strJsonData,logFilePath)
    end
end
-- 读取log本地缓存文件
function NetworkLog.readLogFromFile()
    local isExist = cc.FileUtils:getInstance():isFileExist(logFilePath)
    if isExist then
        local _fileSize = cc.FileUtils:getInstance():getFileSize(logFilePath) or 0
        if _fileSize > 2048000 then
            -- 超过 2M 删除文件
            cc.FileUtils:getInstance():removeFile(logFilePath)
        end
    end
    NetworkLog.logInfoList = util_checkJsonDecode(logFilePath) or {}
end

function NetworkLog:ctor()
    self.m_udid = xcyy.GameBridgeLua:getDeviceUuid() .. ":" .. PRODUCTID
    if gL_logData == nil then
        gL_logData = LogData:create()
    end
end

--[[
    @desc: 返回nonce 字符串 随机保证每次都不同
    time:2018-11-09 17:52:58
    @return:  返回 nonce
]]
function NetworkLog:getNonceStr()
    local curTime = xcyy.SlotsUtil:getMilliSeconds()

    local nonceStr = self.m_udid .. curTime .. util_random(1, 100)

    return nonceStr
end

--关卡顺序
function NetworkLog:getLevelOrder(levelName)
    if not levelName then
        return -1
    end
    -- local levelInfo = globalData.slotRunData.p_machineDatas
    -- for i = 1, #levelInfo do
    --     local info = levelInfo[i]
    --     if info.p_levelName == levelName then
    --         return i
    --     end
    -- end
    return globalData.slotRunData:getLevelIdxByName(levelName)
end

-- LOG_RecordServer   ,, sendLogMessage
function NetworkLog:sendLogData()
    local messageData = gL_logData:getJsonData()
    if DEBUG == 2 then
        print("NetworkLog:sendLogData=" .. messageData)
        release_print("NetworkLog:sendLogData=" .. messageData)
    end
    local code = util_getUpdateVersionCode(false)
    if code then
        print("------------------------sendLogMsg:lastUpdateVersion=" .. code)
        release_print("------------------------sendLogMsg:lastUpdateVersion=" .. code)
    end
    NetworkLog.pushLogInfo(messageData, self:getNonceStr())
    gL_logData:clearMessageData()
end

function NetworkLog.pushLogInfo(messageData,nonceData)
    if NetworkLog.logInfoList ~= nil then
        table.insert(NetworkLog.logInfoList,{msgData = messageData,timestr = nonceData})
    else
        if LOG_RecordServer ~= nil then
            local httpSender = xcyy.HttpSender:createSender()
            local function success_call_fun(responseData)
                httpSender:release()
            end
            local function faild_call_fun(errorCode, errorData)
                httpSender:release()
            end
            httpSender:sendLogMessage(messageData, LOG_RecordServer, nonceData, success_call_fun, faild_call_fun)
        end
    end
    NetworkLog.checkSendLogToServer()
end

function NetworkLog.checkSendLogToServer()
    if NetworkLog.logSendCor == nil and LOG_RecordServer ~= nil then
        NetworkLog.logSendCor = coroutine.create(
        function()
            while NetworkLog.logInfoList ~= nil and #NetworkLog.logInfoList > 0 do
                local info = NetworkLog.logInfoList[1]
                local httpSender = xcyy.HttpSender:createSender()
                local function success_call_fun(responseData)
                    httpSender:release()
                    table.remove(NetworkLog.logInfoList, 1)
                    util_resumeCoroutine(NetworkLog.logSendCor)
                end
                local function faild_call_fun(errorCode, errorData)
                    httpSender:release()
                    table.remove(NetworkLog.logInfoList,1)
                    util_resumeCoroutine(NetworkLog.logSendCor)
                end
                httpSender:sendLogMessage(info.msgData, LOG_RecordServer, info.timestr, success_call_fun, faild_call_fun)
                coroutine.yield()
            end
            NetworkLog.logSendCor = nil
        end)
        util_resumeCoroutine(NetworkLog.logSendCor)
    end
end
return NetworkLog
