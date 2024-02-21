--[[
]]
local PokerDetailData = require("activities.Activity_Poker.model.PokerDetailData")
local PokerDoubleGameNet = class("PokerDoubleGameNet", util_require("baseActivity.BaseActivityManager"))

function PokerDoubleGameNet:getInstance()
    if self.instance == nil then
        self.instance = PokerDoubleGameNet.new()
    end
    return self.instance
end

function PokerDoubleGameNet:printServerErrorLog(_actionType, _resData)
    if _resData:HasField("description") then
        local description = cjson.decode(_resData.description)
        if description and description.error ~= nil then
            assert(false, "[POKER][SERVER ERROR LOG]: actionType = " .. _actionType .. ", error = " .. description.error)
            gLobalViewManager:showReConnect()
            return true
        end
    end
    return false
end

-- 请求
-- _type: Yes, No, Red, Black, GiveUp
function PokerDoubleGameNet:sendPokerDoubleGame(_type)
    local function successCallFun(resData)
        if self:printServerErrorLog("PokerDouble_" .. _type, resData) then
            return
        end
        local flag = false
        if resData:HasField("result") then
            local result = cjson.decode(resData.result)
            if result then
                -- 数据解析
                local pData = G_GetMgr(ACTIVITY_REF.Poker):getData()
                if pData then
                    if result.leftDoubles ~= nil then
                        pData:setLeftDoubles(tonumber(result.leftDoubles))
                    end
                    -- 同步促销道具数量
                    if result.beHitDouble ~= nil then
                        pData:setDoubleHits(tonumber(result.beHitDouble))
                    end
                    -- detail数据
                    if result.detail and result.detail.maxChips ~= nil then
                        G_GetMgr(ACTIVITY_REF.Poker):setResultDetailData(result.detail)
                    end
                    -- 章节奖励和轮次奖励
                    G_GetMgr(ACTIVITY_REF.Poker):setResultData(result)
                    -- 同步detail，切换章节时，detail的数据是旧的，不用覆盖大活动数据
                    local rData = G_GetMgr(ACTIVITY_REF.Poker):getResultData()
                    if not (rData and (rData:hasRoundRewards() or rData:hasChapterRewards())) then
                        local rDetailData = G_GetMgr(ACTIVITY_REF.Poker):getResultDetailData()
                        pData:setPokerDetail(rDetailData)
                    end
                    -- 发送消息
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_DOUBLE_GAME_RESULT_SUCESS, {type = _type})
                    flag = true
                else
                    -- TODO 请求后活动关闭了
                end
            end
        end
        if not flag then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_DOUBLE_GAME_RESULT_FAILED, {type = _type})
        end
    end
    local function failedCallFun(target, errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_DOUBLE_GAME_RESULT_FAILED, {type = _type})
    end
    self:sendMsgBaseFunc(ActionType.PokerDouble, nil, {type = _type}, successCallFun, failedCallFun)
end

-- 请求: 返还本金
function PokerDoubleGameNet:sendPokerDoubleRedeem()
    local function successCallFun(resData)
        if self:printServerErrorLog("PokerGemBack", resData) then
            return
        end
        local flag = false
        if resData:HasField("result") then
            local result = cjson.decode(resData.result)
            if result then
                -- 数据解析
                local pData = G_GetMgr(ACTIVITY_REF.Poker):getData()
                if pData then
                    -- detail数据
                    if result.detail and result.detail.maxChips ~= nil then
                        G_GetMgr(ACTIVITY_REF.Poker):setResultDetailData(result.detail)
                    end
                    -- 章节奖励和轮次奖励
                    G_GetMgr(ACTIVITY_REF.Poker):setResultData(result)
                    -- 同步detail，切换章节时，detail的数据是旧的，不用覆盖大活动数据
                    local rData = G_GetMgr(ACTIVITY_REF.Poker):getResultData()
                    if not (rData and (rData:hasRoundRewards() or rData:hasChapterRewards())) then
                        local rDetailData = G_GetMgr(ACTIVITY_REF.Poker):getResultDetailData()
                        pData:setPokerDetail(rDetailData)
                    end
                    -- 发送消息
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_DOUBLE_REDEEM_RESULT_SUCESS)
                    -- 刷新钻石
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
                    flag = true
                end
            end
        end
        if not flag then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_DOUBLE_REDEEM_RESULT_FAILED)
        end
    end
    local function failedCallFun(target, errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_DOUBLE_REDEEM_RESULT_FAILED)
    end
    self:sendMsgBaseFunc(ActionType.PokerGemBack, nil, {}, successCallFun, failedCallFun)
end

return PokerDoubleGameNet
