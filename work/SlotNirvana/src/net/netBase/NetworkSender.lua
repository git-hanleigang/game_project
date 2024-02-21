--[[
    网络消息收发模块
    author:{author}
    time:2020-07-10 16:48:41
]]
local NetworkSender = class("NetworkSender")

function NetworkSender:ctor()
    -- 消息偏移id
    self.m_offset = 0
    -- 用户token ID
    self.m_token = nil
end

function NetworkSender:getInstance()
    if not self._instance then
        self._instance = NetworkSender.new()
    end
    return self._instance
end

-- 发送 with Time消息，用于未获取到Token前的通信
function NetworkSender:sendWithTimeSign(url, bodyData, successCallFunc, failedCallFunc)
    local httpSender = xcyy.HttpSender:createSender()

    local success_call_fun = function(responseTable, headers)
        httpSender:release()

        -- 消息返回成功
        if successCallFunc then
            successCallFunc(responseTable, headers)
        end
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        httpSender:release()
        -- 同步消息失败--
        if failedCallFunc ~= nil then
            failedCallFunc(errorCode, errorData)
        end
    end
    -- 只用本地时间，服务器需要检测时间
    local localTime = xcyy.SlotsUtil:getMilliSeconds()
    httpSender:sendLoginMessage(bodyData, url, localTime, success_call_fun, faild_call_fun)
end

-- 发送 with Token消息，用于登陆后的通信
function NetworkSender:sendWithTokenSign(url, bodyData, successCallFunc, failedCallFunc)
    local httpSender = xcyy.HttpSender:createSender()

    local success_call_fun = function(responseTable, headers)
        httpSender:release()

        -- 消息返回成功
        if successCallFunc then
            successCallFunc(responseTable, headers)
        end
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        httpSender:release()
        -- 同步消息失败--
        if failedCallFunc ~= nil then
            failedCallFunc(errorCode, errorData)
        end
    end
    local localTime = xcyy.SlotsUtil:getMilliSeconds()
    local offset = self:getOffsetValue()
    local token = self.m_token or globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

function NetworkSender:getOffsetValue()
    local offset = self.m_offset or 0
    self.m_offset = tonumber(offset) + 1
    return self.m_offset
end

return NetworkSender
