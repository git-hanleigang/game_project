--[[
]]
local PokerDetailData = require("activities.Activity_Poker.model.PokerDetailData")
local PokerNet = class("PokerNet", util_require("baseActivity.BaseActivityManager"))

function PokerNet:getInstance()
    if self.instance == nil then
        self.instance = PokerNet.new()
    end
    return self.instance
end

function PokerNet:printServerErrorLog(_actionType, _resData)
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

function PokerNet:isRequestNeting()
    if self.m_isRequestNeting == true then
        return true
    end
    return false
end

-- 发牌请求
function PokerNet:sendPokerGameDeal()
    local function successCallFun(resData)
        if self:printServerErrorLog("PokerDeal", resData) then
            return
        end
        self.m_isRequestNeting = false
        local flag = false
        if resData:HasField("result") then
            local result = cjson.decode(resData.result)
            if result then
                -- 数据解析
                local pData = G_GetMgr(ACTIVITY_REF.Poker):getData()
                if pData then
                    -- 同步double进度
                    if result.leftDoubles ~= nil then
                        pData:setLeftDoubles(tonumber(result.leftDoubles))
                    end
                    -- 同步促销道具数量
                    if result.fixWildItems ~= nil then
                        pData:setWildHits(tonumber(result.fixWildItems))
                    end
                    -- 同步促销道具数量
                    if result.beHitDouble ~= nil then
                        pData:setDoubleHits(tonumber(result.beHitDouble))
                    end
                    -- 同步累积充能次数
                    if result.leftTreasures ~= nil then
                        pData:setTreasureCurPro(tonumber(result.leftTreasures))
                    end
                    -- 同步最大充能次数
                    if result.maxTreasures ~= nil then
                        pData:setTreasureMaxPro(tonumber(result.maxTreasures))
                    end
                    -- 同步双倍筹码数据
                    if result.doubleWinItems ~= nil then
                        pData:setDoubleWinTimes(tonumber(result.doubleWinItems))
                    end
                    -- detail数据
                    if result.detail and result.detail.maxChips ~= nil then
                        G_GetMgr(ACTIVITY_REF.Poker):setResultDetailData(result.detail)
                    end
                    -- 同步detail，切换章节时，detail的数据是旧的，不用覆盖大活动数据
                    local rData = G_GetMgr(ACTIVITY_REF.Poker):getResultData()
                    if not (rData and (rData:hasRoundRewards() or rData:hasChapterRewards())) then
                        local rDetailData = G_GetMgr(ACTIVITY_REF.Poker):getResultDetailData()
                        pData:setPokerDetail(rDetailData)
                        -- 同步剩余大活动道具
                        if result.leftProps ~= nil then
                            pData:setMaterialNum(tonumber(result.leftProps))
                        end
                    end
                    -- 发送通知
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_GAME_DEAL_RESULT_SUCESS, result)
                    flag = true
                else
                    -- TODO 请求后活动关闭了
                end
            end
        end
        if not flag then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_GAME_DEAL_RESULT_FAILED)
        end
    end
    local function failedCallFun(target, errorCode, errorData)
        self.m_isRequestNeting = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_GAME_DEAL_RESULT_FAILED)
        gLobalViewManager:showReConnect()
    end
    self.m_isRequestNeting = true
    self:sendMsgBaseFunc(ActionType.PokerDeal, nil, nil, successCallFun, failedCallFun)
end

-- 换牌请求
function PokerNet:sendPokerGameDraw(_unlockPokerIndexList)
    local function successCallFun(resData)
        if self:printServerErrorLog("PokerDraw", resData) then
            return
        end
        self.m_isRequestNeting = false
        local flag = false
        if resData:HasField("result") then
            local result = cjson.decode(resData.result)
            if result then
                -- 数据解析
                local pData = G_GetMgr(ACTIVITY_REF.Poker):getData()
                if pData then
                    -- 同步促销道具数量
                    if result.fixWildItems ~= nil then
                        pData:setWildHits(tonumber(result.fixWildItems))
                    end
                    -- detail数据
                    if result.detail and result.detail.maxChips ~= nil then
                        G_GetMgr(ACTIVITY_REF.Poker):setResultDetailData(result.detail)
                    end
                    -- 同步双倍筹码数据
                    if result.doubleWinItems ~= nil then
                        pData:setDoubleWinTimes(tonumber(result.doubleWinItems))
                    end
                    -- 章节奖励和轮次奖励
                    G_GetMgr(ACTIVITY_REF.Poker):setResultData(result)
                    -- 同步detail，切换章节时，detail的数据是旧的，不用覆盖大活动数据
                    local rData = G_GetMgr(ACTIVITY_REF.Poker):getResultData()
                    if not (rData and (rData:hasRoundRewards() or rData:hasChapterRewards())) then
                        local rDetailData = G_GetMgr(ACTIVITY_REF.Poker):getResultDetailData()
                        pData:setPokerDetail(rDetailData)
                        -- 同步剩余大活动道具
                        if result.leftProps ~= nil then
                            pData:setMaterialNum(tonumber(result.leftProps))
                        end
                    end
                    -- 未赢记录
                    G_GetMgr(ACTIVITY_REF.Poker):setUnWinCount()
                    -- 发送通知
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_GAME_DRAW_RESULT_SUCESS, result)
                else
                    -- TODO 请求后活动关闭了
                end
                flag = true
            end
        end
        if not flag then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_GAME_DRAW_RESULT_FAILED)
        end
    end
    local function failedCallFun(target, errorCode, errorData)
        self.m_isRequestNeting = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_GAME_DRAW_RESULT_FAILED)
        gLobalViewManager:showReConnect()
    end
    local str = ""
    if _unlockPokerIndexList and #_unlockPokerIndexList > 0 then
        str = table.concat(_unlockPokerIndexList, "-")
    end
    self.m_isRequestNeting = true
    self:sendMsgBaseFunc(ActionType.PokerDraw, nil, {replaces = str}, successCallFun, failedCallFun)
end

return PokerNet
