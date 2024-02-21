-- 集卡排行榜 数据请求

local CardRankNet = class("CardRankNet", require "network.NetWorkBase")

local CardSysProto = require "protobuf.CardProto_pb"
if CardProto_pb ~= nil then
    CardSysProto = CardProto_pb
end

function CardRankNet:getInstance()
    if self.instance == nil then
        self.instance = CardRankNet.new()
    end
    return self.instance
end

-- 发送获取排行榜消息
function CardRankNet:sendActionRank(info_type, succCallback)
    if not info_type then
        return
    end
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local function failedFunc(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local function successFunc(responseTable)
        gLobalViewManager:removeLoadingAnima()
        local responseConfig = CardSysProto.CardRankResponse()
        local responseStr = self:parseResponseData(responseTable)
        responseConfig:ParseFromString(responseStr)
        local act_data = G_GetMgr(G_REF.CardRank):getRunningData()
        if act_data then
            act_data:parseData(responseConfig.cardRank)
            -- act_data:setRankJackpotCoins(0)
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = G_REF.CardRank})
            if succCallback then
                succCallback()
            end
        end
    end

    gLobalViewManager:addLoadingAnimaDelay(1)
    local requestInfo = CardSysProto.CardRankRequest()
    requestInfo.type = info_type

    local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardRankRequest
    self:sendCardSysData(bodyData, sUrl, successFunc, failedFunc)
end

-- 通用发送接口 --
function CardRankNet:sendCardSysData(tBodyData, sUrl, callSuccess, callFaild)
    local httpSender = xcyy.HttpSender:createSender()
    local success_call_fun = function(responseTable)
        if callSuccess then
            callSuccess(responseTable)
        end
        httpSender:release()
    end
    local faild_call_fun = function(errorCode, errorData)
        if callFaild then
            callFaild(errorCode, errorData)
        end
        httpSender:release()
    end
    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendMessage(tBodyData, offset, token, sUrl, serverTime, success_call_fun, faild_call_fun)
end

return CardRankNet
