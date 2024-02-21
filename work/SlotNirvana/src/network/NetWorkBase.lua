---
-- 网络消息的 基类， 实现最基础功能
--
-- FIX ios new
local NetWorkAddressLog = require("network.NetWorkAddressLog")
local NetWorkBase = class("NetWorkBase")

NetWorkBase.PlatFormType = 1 -- 1:Android 2:iOS 3:Amazon 4:Facebook
NetWorkBase.SUCCESS = 1
NetWorkBase.FAILD = 0

function NetWorkBase:ctor()
end

function NetWorkBase:convertAppCodeToNumber(appCode)
    if appCode == nil then
        return 0
    end
    local strLen = string.len(appCode)
    local targetStr = ""
    local isFirstP = false
    for i = 1, strLen do
        local cStr = string.sub(appCode, i, i)
        if cStr ~= "." then
            targetStr = targetStr .. cStr
        elseif isFirstP == false then
            targetStr = targetStr .. cStr
            isFirstP = true
        end
    end
    local targetNum = tonumber(targetStr)
    if targetNum == nil then
        return 0
    end
    return targetNum
end

function NetWorkBase:getOffsetValue()
    local offset = globalData.userRunData.loginOffset or 0
    offset = tonumber(offset) + 1
    globalData.userRunData.loginOffset = offset
    return offset
end

---获取version  并且version自加1
function NetWorkBase:getVersionNum()
    globalData.userRunData.dataVersion = globalData.userRunData.dataVersion + 1
    return globalData.userRunData.dataVersion
end

--[[
    @desc: 解析response data超过10000个字节的数据
    time:2018-08-30 20:50:59
    @return:
]]
function NetWorkBase:parseResponseData(responseTable)
    return responseTable
end

--保存headers信息
function NetWorkBase:checkSaveHeaders(headers)
    if headers then
        local headersStr = self:parseResponseData(headers)
        if headersStr then
            local headersList = util_split(headersStr, "\n")
            if headersList and #headersList > 0 then
                for i = 1, #headersList do
                    local dataStr = headersList[i]
                    if string.find(dataStr, "requestId") ~= nil then
                        globalData.requestId = dataStr
                        break
                    end
                end
            end
        end
    end
end

-- 发送消息
function NetWorkBase:sendNetMsg(url, pbRequest, pbResponse, successCallFunc, faildCallFunc, offset)
    local requestData = pbRequest:SerializeToString()
    local httpSender = xcyy.HttpSender:createSender()
    offset = offset or self:getOffsetValue()

    local showReconnect = function(errorCode, errorData)
        local okFunc = nil
        local errHead = math.floor(errorCode / 100)
        if errorCode == 0 or errHead == 5 then
            okFunc = function()
                if gLobalGameHeartBeatManager then
                    gLobalGameHeartBeatManager:stopHeartBeat()
                end
                util_restartGame()
            end
        else
            -- 弹出断线重连弹窗
            -- okFunc = function()
            --     if not gLobalViewManager:getLoadingAnima() then
            --         gLobalViewManager:addLoadingAnima()
            --     end
            --     self:sendNetMsg(url, pbRequest, pbResponse, successCallFunc, faildCallFunc, offset)
            -- end
        end
        local errorInfo = {
            errorCode = tostring(errorCode),
            errorMsg = "NetWorkBase:sendNetMsg|url:" .. tostring(url) .. "|" .. tostring(errorData)
        }
        gLobalViewManager:showReConnectNew(okFunc, nil , false, errorInfo)
    end

    local faild_call_fun = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        -- 根据errorCode 做处理
        httpSender:release()
        showReconnect(errorCode, errorData)
        -- 同步消息失败--
        if faildCallFunc ~= nil then
            faildCallFunc(errorCode, errorData)
        end
    end

    local success_call_fun = function(responseTable, headers)
        -- gLobalViewManager:removeLoadingAnima()
        httpSender:release()

        if pbResponse then
            local responseStr = self:parseResponseData(responseTable)
            pbResponse:ParseFromString(responseStr)
        end

        gLobalViewManager:removeLoadingAnima()
        -- if pbResponse and pbResponse.code then
        --     if pbResponse.code == BaseProto_pb.SUCCEED or pbResponse.code == BaseProto_pb.GAME_MAINTAIN then
        --         gLobalSendDataManager:clearReconnTime()
        --         if successCallFunc then
        --             successCallFunc(pbResponse, headers)
        --         end
        --     else
        --         showReconnect()

        --         if faildCallFunc ~= nil then
        --             faildCallFunc(pbResponse.code, pbResponse.description)
        --         end
        --     end
        -- else
        gLobalSendDataManager:clearReconnTime()
        if successCallFunc then
            successCallFunc(pbResponse, headers)
        end
        -- end
    end

    local time = xcyy.SlotsUtil:getMilliSeconds()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendMessage(requestData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

-------  发送用户Action 数据 ------
---
-- @param successCallFun  成功返回回调
--          faildCallFun  失败返回回调
function NetWorkBase:sendMessageData(pbRequest, successCallFun, faildCallFun, offset)
    local bodyData = pbRequest:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()

    local url = DATA_SEND_URL .. RUI_INFO.DATA_ACITON -- 拼接url 地址
    -- offset = offset or self:getOffsetValue()

    -- local showReconnect = function()
    --     -- 弹出断线重连弹窗
    --     local okFunc = function()
    --         if not gLobalViewManager:getLoadingAnima() then
    --             gLobalViewManager:addLoadingAnima()
    --         end
    --         self:sendMessageData(pbRequest, successCallFun, faildCallFun, offset)
    --     end
    --     gLobalViewManager:showReConnectNew(okFunc)
    -- end
    if DEBUG > 0 then
        local _action = pbRequest.action
        if not _action then
            assert(false, "NetWorkBase:sendMessageData| pbRequest action is nil!!")
        end
    end

    local pbResponse = GameProto_pb.ActionResponse()
    -- local success_call_fun = function(responseTable, headers)
    local success_call_fun = function(resData, headers)
        -- gLobalViewManager:removeLoadingAnima()
        local time = socket.gettime()

        -- local resData = GameProto_pb.ActionResponse()

        -- local responseStr = self:parseResponseData(responseTable)
        -- resData:ParseFromString(responseStr)

        self:checkSaveHeaders(headers)

        local timeEndParse = socket.gettime()
        release_print("解析protobuf消耗时间" .. (timeEndParse - time))
        --发送spin消耗时间
        gLobalSendDataManager:getLogSlots():checkSendSpinCost()

        -- httpSender:release()
        if resData.code == BaseProto_pb.SUCCEED then
            -- gLobalSendDataManager:clearReconnTime()

            if resData:HasField("timestamp") == true and resData.timestamp ~= "" then
                globalData.userRunData:syncServerTime(tonumber(resData.timestamp))
            end

            globalData:syncActionData(resData)

            if successCallFun ~= nil then
                successCallFun(self, resData)
            end
            local time1 = socket.gettime()
            release_print("解析消耗时间" .. (time1 - timeEndParse))
        elseif resData.code == BaseProto_pb.GAME_MAINTAIN then
            -- gLobalSendDataManager:clearReconnTime()
            --版本维护中
            gLobalViewManager:showMaintain()
        else
            local errorInfo = {
                errorCode = tostring(resData.code),
                errorMsg = "NetWorkBase:sendNetMsg|url:" .. tostring(url) .. "|" .. tostring(resData.description)
            }
            gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "DataError")
            -- showReconnect()
            if faildCallFun ~= nil then
                faildCallFun(self, resData.code, resData.description)
            end
        end
        NetWorkAddressLog.stopRecord(url, bodyData)
    end

    local faild_call_fun = function(errorCode, errorData)
        -- gLobalViewManager:removeLoadingAnima()
        -- 根据errorCode 做处理
        -- httpSender:release()
        -- showReconnect()
        local errorInfo = {
            errorCode = tostring(errorCode),
            errorMsg = "NetWorkBase:sendNetMsg|url:" .. tostring(url) .. "|" .. tostring(errorData)
        }
        gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "NetFailed")
        -- 同步消息失败--
        if faildCallFun ~= nil then
            faildCallFun(self, errorCode, errorData)
        end
        NetWorkAddressLog.removeURLTimeInfo(url, bodyData)
    end
    local time = xcyy.SlotsUtil:getMilliSeconds()
    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, pbRequest, pbResponse, success_call_fun, faild_call_fun, offset)
    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("发送消息消耗时间 " .. (time1 - time) .. "  " .. url)
    NetWorkAddressLog.startRecord(url, bodyData)
end

function NetWorkBase:updatePlatFormType()
    if device.platform == "android" then
        if MARKETSEL == GOOGLE_MARKET then
            self.PlatFormType = 1
        elseif MARKETSEL == AMAZON_MARKET then
            self.PlatFormType = 3
        end
    elseif device.platform == "ios" then
        self.PlatFormType = 2
    else
        self.PlatFormType = 1
    end
end

function NetWorkBase:getSendActionData(actionType, name)
    self:updatePlatFormType()

    local actionData = GameProto_pb.ActionRequest()

    if not actionType and DEBUG > 0 then
        assert(false, "NetWorkBase:getSendActionData|ActionType is nil!!!")
    end

    actionData.action = actionType
    actionData.time = globalData.userRunData.p_serverTime * 1000
    if name == nil then
        name = ""
    end
    actionData.game = name
    actionData.platform = self.PlatFormType
    actionData.tournamentName = ""

    return actionData
end

function NetWorkBase.sendHttpRequest(url, requestType, timeout, successCallBack, failedCallBack)
    local xmlRequest = cc.XMLHttpRequest:new()
    xmlRequest.timeout = timeout or 30
    xmlRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xmlRequest:open(requestType, url)
    local function httpCallBack()
        local responseCode = xmlRequest.status
        local responseData = xmlRequest.response
        if xmlRequest.readyState == 4 and responseCode == 200 then
            if successCallBack ~= nil then
                successCallBack(responseData)
            end
        else
            if failedCallBack ~= nil then
                failedCallBack(responseCode, responseData)
            end
        end
        xmlRequest:unregisterScriptHandler()
    end
    xmlRequest:registerScriptHandler(httpCallBack)
    xmlRequest:send()
end

return NetWorkBase
