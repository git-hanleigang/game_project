--[[
    网络基础命令控制
    author:{author}
    time:2020-07-10 17:39:57
]]
local NetworkSender = require("net.netBase.NetworkSender")
local ProtoNetwork = class("ProtoNetwork")

function ProtoNetwork:getInstance()
    if not self._instance then
        -- 单例方法可实现多态
        self._instance = self.__index.new()
    end
    return self._instance
end

--保存headers信息
function ProtoNetwork:checkSaveHeaders(headers)
    if headers then
        local headersStr = headers
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

--[[
    @desc: 发送 with Time消息，用于未获取到Token前的通信
    author: 徐袁
    time: 2021-03-15 17:14:20
    --@protoInfo: 协议配置信息
	--@body: 协议请求数据结构
	--@successCallFunc: 成功回调
	--@failedCallFunc: 失败回调
    @return: 
]]
function ProtoNetwork:sendWithTimeSign(protoInfo, body, successCallFunc, failedCallFunc)
    local url = protoInfo.url
    if not url or url == "" then
        return
    end

    -- 拼接url 地址
    local url = DATA_SEND_URL .. url
    local bodyData = ""
    if body and body.SerializeToString then
        bodyData = body:SerializeToString()
    end

    local successCallback = function(responseTable, headers)
        if not protoInfo.response then
            printError("" .. protoInfo.protoType .. " Response不存在！！！")
            return
        end

        local resData = protoInfo.response()

        resData:ParseFromString(responseTable)

        printInfo("ProtoNetwork:sendWithTimeSign success!")

        if successCallFunc ~= nil then
            successCallFunc(resData)
        end
    end

    local failedCallback = function(errorCode, errorData)
        -- 同步消息失败--
        printInfo("ProtoNetwork:sendWithTimeSign failed!")
    end

    NetworkSender:getInstance():sendWithTimeSign(url, bodyData, successCallback, failedCallback)
end

--[[
    @desc: 发送 with Token消息，用于登陆后的通信
    author: 徐袁
    time: 2021-03-15 17:14:51
    --@protoInfo: 协议配置信息
	--@body: 协议请求数据结构
	--@successCallFunc: 成功回调
	--@failedCallFunc: 失败回调
    @return: 
]]
function ProtoNetwork:sendWithTokenSign(protoInfo, body, successCallFunc, failedCallFunc)
    local url = protoInfo.url
    if not url or url == "" then
        return
    end

    -- 拼接url 地址
    local url = DATA_SEND_URL .. url
    local bodyData = ""
    if body and body.SerializeToString then
        bodyData = body:SerializeToString()
    end
    local successCallback = function(responseTable, headers)
        if not protoInfo.response then
            printError("" .. protoInfo.protoType .. " Response不存在！！！")
            return
        end
        local resData = protoInfo.response()

        local responseStr = responseTable
        resData:ParseFromString(responseStr)

        self:checkSaveHeaders(headers)

        -- 返回码异常的通用处理
        if not self:isResponseError(resData, url) then
            if successCallFunc ~= nil then
                successCallFunc(resData)
            end
        else
            printInfo("ProtoNetwork:sendWithTokenSign failed " .. resData.code)
            local errorInfo = {
                errorCode = tostring(resData.code),
                errorMsg = "ProtoNetwork:sendWithTokenSign|url:" .. tostring(url) .. "|" .. tostring(resData.description)
            }
            gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "DataError")

            if failedCallFunc ~= nil then
                failedCallFunc(resData.code, resData.description)
            end
        end
    end

    -- 弹出断线重连弹窗
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
            -- okFunc = function()
            --     if not gLobalViewManager:getLoadingAnima() then
            --         gLobalViewManager:addLoadingAnima()
            --     end
            --     self:sendWithTokenSign(protoInfo, body, successCallFunc, failedCallFunc)
            -- end
        end
        local errorInfo = {
            errorCode = tostring(errorCode),
            errorMsg = "ProtoNetwork:sendWithTokenSign|url:" .. tostring(url) .. "|" .. tostring(errorData)
        }
        gLobalViewManager:showReConnectNew(okFunc, nil, false, errorInfo)
    end

    local failedCallback = function(errorCode, errorData)
        -- 同步消息失败--
        printInfo("ProtoNetwork:sendWithTokenSign failed!")
        if body and body.action and body.action == 340 then
        else
            showReconnect(errorCode, errorData)
        end
        local errorInfo = {
            errorCode = tostring(errorCode),
            errorMsg = "ProtoNetwork:sendWithTokenSign|url:" .. tostring(url) .. "|" .. tostring(errorData)
        }
        gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "NetFailed")

        if failedCallFunc ~= nil then
            failedCallFunc(errorCode, errorData)
        end
    end

    NetworkSender:getInstance():sendWithTokenSign(url, bodyData, successCallback, failedCallback)
end

-- 处理服务器返回的状态码
function ProtoNetwork:isResponseError(resData, url)
    if not resData.code or resData.code == BaseProto_pb.SUCCEED then
        return false
    end

    if resData.description then
        printInfo("来自服务器的描述： " .. resData.description)
    end

    -- 只对调试模式开放 方便查询用户信息
    printInfo("---->    url: " .. url)
    printInfo("---->    用户udid: " .. globalData.userRunData.userUdid)
    printInfo("---->    用户uid: " .. globalData.userRunData.uid)

    if resData.code == BaseProto_pb.SYSTEM_ERROR then
        printError("系统异常")
    elseif resData.code == BaseProto_pb.AUTHORIZATION_FAILED then
        printError("认证失败")
    elseif resData.code == BaseProto_pb.ILLEGAL_ARGUMENT then
        printError("参数非法")
    elseif resData.code == BaseProto_pb.TOURNAMENT_NOT_EXIST then
        printError("不存在")
    elseif resData.code == BaseProto_pb.USER_BINDED then
        printError("用户已绑定")
    elseif resData.code == BaseProto_pb.HEADER_TIME_EXCEED then
        printError("用户时间异常，无法向服务器发起网络请求")
    elseif resData.code == BaseProto_pb.NO_COINS then
        printError("金币不足")
    elseif resData.code == BaseProto_pb.BUSINESS_EXCEPTION then
        printError("业务逻辑异常")
    elseif resData.code == BaseProto_pb.GAME_MAINTAIN then
        printError("关卡维护中")
        gLobalViewManager:showMaintain()
    elseif resData.code == BaseProto_pb.ORDER_VERIFY_FAILED then
        printError("订单验证失败")
    elseif resData.code == BaseProto_pb.ORDER_EXIST then
        printError("订单已存在")
    elseif resData.code == BaseProto_pb.CLAN_NAME_EXIST then
        printError("公会名称已存在")
    elseif resData.code == BaseProto_pb.CLAN_CREATE_LIMIT then
        printError("用户还不能创建公会")
    elseif resData.code == BaseProto_pb.USER_HAVE_CLAN then
        printError("用户已经是公会公会成员了")
    elseif resData.code == BaseProto_pb.CLAN_MEMBER_FULL then
        printError("公会成员已满")
    elseif resData.code == BaseProto_pb.CLAN_LEVEL_LIMIT then
        printError("用户未达到公会等级限制")
    elseif resData.code == BaseProto_pb.NO_GEMS then
        printError("第二货币不足")
    elseif resData.code == BaseProto_pb.CLOSURE_USER then
        printError("该用户被封停")
    elseif resData.code == BaseProto_pb.BINGO_RUSH_ERROR then
        printError("bingo比赛 消息错误")
    else
        printError("未知错误 数据结构异常")
    end
    return true
end

return ProtoNetwork
