---
-- 处理 游戏内的spin 消息同步等， 处理
--

local NetWorkHeartBeat = class("NetWorkHeartBeat", require "network.NetWorkBase")

NetWorkHeartBeat.startSpinTime = nil
NetWorkHeartBeat.levelName = nil

function NetWorkHeartBeat:ctor()
end

--服务器发来的firebase事件强制添加价值
NetWorkHeartBeat.fireBaseValues = {
    A1stdaymore9p99 = 9.99,
    A1stdaymore1p99 = 1.99,
    A1stdaymore2p99 = 2.99,
    A1stdaymore4p99 = 4.99,
    in3daymore24p75 = 24.75,
    in7daymore39p6 = 39.6,
    in7daylowest0p99 = 0.99,
    accumulateupto1p99 = 1.99,
    accumulateupto2p99 = 2.99,
    accumulateupto4p99 = 4.99,
    accumulateupto9p99 = 9.99,
    accumulateupto19p99 = 19.99,
    accumulateupto29p99 = 29.99,
    accumulateupto39p99 = 39.99,
    accumulateupto49p99 = 49.99,
    accumulateupto59p99 = 59.99,
    accumulateupto69p99 = 69.99,
    accumulateupto79p99 = 79.99,
    accumulateupto89p99 = 89.99,
    accumulateupto99p99 = 99.99,
    accumulateupto129p99 = 129.99
}

function NetWorkHeartBeat:formatFirebaseEventKey(key)
    local value = nil
    if key ~= nil then
        local orgKey = key
        key = string.gsub(key, "%.", "p")
        key = string.gsub(key, "&", "and")
        local firstChar = string.sub(key, 1, 1)
        if tonumber(firstChar) ~= nil then
            key = "A" .. key
        end

        --屏蔽普通支付打点 服务器为啥不直接删除
        if orgKey == "inappnum" or orgKey == "1stpay" or orgKey == "2ndpay" then
            return nil
        end
        --解析有价值的支付打点 使用原始数据解析
        if string.find(orgKey, "#") ~= nil then
            local strList = string.split(orgKey, "#")
            if #strList == 2 then
                local firstChar = string.sub(strList[1], 1, 1)
                if tonumber(firstChar) ~= nil then
                    strList[1] = "A" .. strList[1]
                end
                return strList[1], strList[2]
            end
        end

        --服务器发送打点强制匹配价值
        return key, self.fireBaseValues[key]
    end
    return key, value
end

function NetWorkHeartBeat:sendHeartBeat(successCallBack, failCallBack)
    local heartBeatData = GameProto_pb.HeartBeatRequest()

    local bodyData = heartBeatData:SerializeToString()
    local httpSender = xcyy.HttpSender:createSender()

    local url = DATA_SEND_URL .. RUI_INFO.HEARTBEAT_ACITON -- 拼接url 地址

    local success_call_fun = function(responseTable, table2)
        local resData = GameProto_pb.HeartBeatResponse()
        -- local responseStr1 = self:parseResponseData(responseTable)
        local responseStr = self:parseResponseData(responseTable)
        resData:ParseFromString(responseStr)
        local resCode = resData.code
        if resCode == 1 or resCode == 2 then
            local extraJsonData = {}
            if resData.extra and string.len(tostring(resData.extra)) > string.len("{}") then
                extraJsonData = json.decode(resData.extra) 
            end
            --大奖广播
            if globalData.jackpotPushFlag and resData.bigRewards then
                local rewardList = resData.bigRewards
                if #rewardList > 0 then
                    globalData.syncJackpotPushData(rewardList)
                end
                if globalData.jackpotPushList and #globalData.jackpotPushList > 0 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JACKPOT_PUSH)
                end
            end

            --服务器打点日志
            if resCode == 1 then
                local serverEvents = resData.events
                if serverEvents ~= nil and #serverEvents > 0 then
                    local delayTime = 0.05
                    for k, v in ipairs(serverEvents) do
                        local eventName, value = self:formatFirebaseEventKey(v.key)
                        if eventName and not string.find(v.key, "14_fb") then -- fb 事件不往firebase 发送
                            delayTime = delayTime + 0.05
                            scheduler.performWithDelayGlobal(
                                function()
                                    globalFireBaseManager:sendBaseFirebaseLog(eventName, value)
                                end,
                                delayTime,
                                "HeartDelayTime"
                            )
                        end
                        globalFaceBookManager:checkSendFacebookEvent(v.key)
                    end
                end
            end

            -- 扩圈系统
            if resData.expandCircleGame and resData.expandCircleGame ~= "" then
                G_GetMgr(G_REF.NewUserExpand):setUserExpandEnabled(resData.expandCircleGame, true)
            end

            -- 个人限时比赛
            if extraJsonData.luckyRace then
                G_GetMgr(ACTIVITY_REF.LuckyRace):parseHeartBeatData(extraJsonData.luckyRace)
            end

            if successCallBack then
                successCallBack(resData)
            end
        else
            printInfo("xcyy :heartBeat返回失败 failed")
            if failCallBack then
                failCallBack(resCode, "heartBeat failed!!")
            end
        end
        httpSender:release()
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        httpSender:release()
        printInfo("xcyy :heartBeat返回失败 failed")
        -- 同步消息失败--
        if failCallBack then
            failCallBack(errorCode, errorData)
        end
    end

    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime

    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

return NetWorkHeartBeat
