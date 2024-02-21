--[[
    网络请求
    author:{author}
    time:2020-07-10 18:08:27
]]
require("net.ProtoConfig")
local ProtoNetwork = require("net.netBase.ProtoNetwork")
local BaseNetModel = class("BaseNetModel")

function BaseNetModel:getInstance()
    if not self._instance then
        -- 单例方法可实现多态
        self._instance = self.__index.new()
    end
    return self._instance
end

--[[
    @desc: 获取网络请求
    author: 徐袁
    time: 2021-02-26 12:27:00
    --@protoInfo: proto协议信息
    @return: 
]]
function BaseNetModel:getProtoRequest(protoInfo)
    if not protoInfo or not protoInfo.request then
        return nil
    end

    local protoRequest = nil
    if protoInfo.request then
        protoRequest = protoInfo.request()
    end

    if protoInfo.protoType == "DATA_ACITON" then
        -- ActionType的消息结构
        protoRequest = self:getActionRequest()
    end

    return protoRequest
end

--[[
    @desc: 获取Action类型网络请求
    author: 徐袁
    time: 2021-02-28 12:12:08
    --@actionType: 
    @return: 
]]
function BaseNetModel:getActionRequest(actionType)
    actionType = actionType or ""

    if actionType == "" and DEBUG > 0 then
        assert(false, "BaseNetModel:getActionRequest|ActionType is nil!!!")
    end

    local _request = ProtoConfig.DATA_ACITON.request()

    -- ActionType的消息结构
    _request.time = globalData.userRunData.p_serverTime * 1000
    _request.game = ""
    _request.action = actionType
    _request.platform = self:getPlatFormType()
    _request.tournamentName = ""
    _request.data.params = cjson.encode({})

    return _request
end

-- 平台类型
function BaseNetModel:getPlatFormType()
    local PlatFormType = 1
    if device.platform == "android" then
        if MARKETSEL == GOOGLE_MARKET then
            PlatFormType = 1
        elseif MARKETSEL == AMAZON_MARKET then
            PlatFormType = 3
        end
    elseif device.platform == "ios" then
        PlatFormType = 2
    end
    return PlatFormType
end

-- 打包body数据
function BaseNetModel:packBody(body, tbData)
    tbData = tbData or {}
    if body and type(body) == "table" then
        for key, value in pairs(tbData) do
            if key == "data" then
                -- data字段特殊处理
                body.data.params = cjson.encode(value.params or {})
            else
                body[key] = value
            end
        end
    end
end

-- 发送Action消息
function BaseNetModel:sendActionMessage(actionType, tbData, successFunc, failedFunc)
    if not actionType then
        return
    end

    local _requestBody = self:getActionRequest(actionType)

    if not tbData or (not next(tbData)) then
        -- tbData 为 nil 或 {} 时
        tbData = {
            data = {
                params = {
                }
            }
        }
    end

    -- table数据打包到request对象中
    self:packBody(_requestBody, tbData)

    local successCallback = function(protoResult)
        globalData:syncActionData(protoResult)

        if successFunc ~= nil then
            local jsonResult = {}
            -- 解析result的json字符串
            if protoResult:HasField("result") == true and protoResult.result ~= "" then
                jsonResult = cjson.decode(protoResult.result)
            end
            successFunc(jsonResult)
        end
    end

    local failedCallback = function(errorCode, errorData)
        -- 同步消息失败--
        if failedFunc then
            failedFunc(errorCode, errorData)
        end
    end

    self:_sendMessage(ProtoConfig.DATA_ACITON, _requestBody, successCallback, failedCallback)
end

-- 发送网络消息
function BaseNetModel:sendMessage(protoInfo, tbData, successFunc, failedFunc)
    if not protoInfo then
        return
    end

    local _requestBody = self:getProtoRequest(protoInfo)

    -- table数据打包到request对象中
    self:packBody(_requestBody, tbData)

    self:_sendMessage(protoInfo, _requestBody, successFunc, failedFunc)
end

-- 发送网络消息
function BaseNetModel:_sendMessage(protoInfo, body, successFunc, failedFunc)
    local successCallback = function(protoResult)
        -- 同步服务器时间
        if protoResult.timestamp and protoResult.timestamp ~= "" and protoResult.timestamp ~= 0 then
            -- TimeManager:setServerTime(resultData.timestamp)
            globalData.userRunData:syncServerTime(tonumber(protoResult.timestamp))
        end

        if successFunc ~= nil then
            successFunc(protoResult)
        end
    end

    local failedCallback = function(errorCode, errorData)
        -- 同步消息失败
        if failedFunc then
            failedFunc(errorCode, errorData)
        end
    end

    if protoInfo.sign == "TOKEN" then
        -- 发送Token签名的消息
        ProtoNetwork:getInstance():sendWithTokenSign(protoInfo, body, successCallback, failedCallback)
    elseif protoInfo.sign == "TIME" then
        -- 发送Time签名的消息
        ProtoNetwork:getInstance():sendWithTimeSign(protoInfo, body, successCallback, failedCallback)
    end
end

-- 发送 with Time消息，用于未获取到Token前的通信
-- function BaseNetModel:_sendWithTimeSign(protoInfo, body, successFunc, failedFunc)
--     local successCallback = function(resultData)
--         -- 同步服务器时间
--         if resultData.timestamp and resultData.timestamp ~= "" then
--             -- TimeManager:setServerTime(resultData.timestamp)
--             globalData.userRunData:syncServerTime(resultData.timestamp)
--         end

--         if successFunc ~= nil then
--             successFunc(resultData)
--         end
--     end

--     local failedCallback = function(errorCode, errorData)
--         -- 同步消息失败--
--     end

--     ProtoNetwork:getInstance():sendWithTimeSign(protoInfo, body, successCallback, failedCallback)
-- end

-- 发送 with Token消息，用于登陆后的通信
-- function BaseNetModel:_sendWithTokenSign(protoInfo, body, successFunc, failedFunc)
--     local successCallback = function(resultData)
--         -- 同步服务器时间
--         if resultData:HasField("timestamp") == true and resultData.timestamp ~= "" then
--             -- TimeManager:setServerTime(resultData.timestamp)
--             globalData.userRunData:syncServerTime(resultData.timestamp)
--         end

--         if successFunc ~= nil then
--             successFunc(resultData)
--         end
--     end
--     local failedCallback = function(errorCode, errorData)
--         -- 同步消息失败
--     end

--     ProtoNetwork:getInstance():sendWithTokenSign(protoInfo, body, successCallback, failedCallback)
-- end

return BaseNetModel
