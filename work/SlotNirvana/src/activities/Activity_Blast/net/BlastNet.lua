-- blast网络

local BlastNet = class("BlastNet", util_require("baseActivity.BaseActivityManager"))

function BlastNet:getInstance()
    if self.instance == nil then
        self.instance = BlastNet.new()
    end
    return self.instance
end

function BlastNet:ctor()
    BlastNet.super.ctor(self)
    self.bl_waitting = false
end

-- 发送获取排行榜消息
function BlastNet:requestRankData(loadingLayerFlag, successCallFunc, failedCallFunc)
    -- 数据不全 不执行请求
    -- if not self:getActivityData() then
    --     return
    -- end

    local _successCallFunc = function(target, resultData)
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            -- if rankData ~= nil then
            --     local blastData = self:getActivityData()
            --     if blastData then
            --         blastData:parseBlastRankConfig(rankData)
            --     end
            -- end
            if successCallFunc then
                successCallFunc(rankData)
            end
        end
        if loadingLayerFlag then
            gLobalViewManager:removeLoadingAnima()
        end
    end

    local _failedCallFunc = function(target, code, errorMsg)
        if loadingLayerFlag then
            gLobalViewManager:removeLoadingAnima()
        end
        -- gLobalViewManager:showReConnect()
        if failedCallFunc then
            failedCallFunc()
        end
    end
    if loadingLayerFlag then
        gLobalViewManager:addLoadingAnima()
    end
    local actionData = self:getSendActionData(ActionType.BlastRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFunc, _failedCallFunc)
end

-- 发送翻牌消息
function BlastNet:requestPick(_idx, successCallFunc, failedCallFunc)
    -- 等待消息结果
    if self.bl_waitting ~= nil and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(responseTable, resData)
        self.bl_waitting = false
        -- local blastData = G_GetActivityDataByRef(ACTIVITY_REF.Blast)
        -- if blastData and blastData:isRunning() then
        local result = json.decode(resData.result)
        --     if result ~= nil then
        --         blastData:parsePickData(result)
        --     else
        --         local errorMsg = "parse blast play json error"
        --         printInfo(errorMsg)
        --         release_print(errorMsg)
        --         gLobalViewManager:showReConnect()
        --     end
        -- end
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        self.bl_waitting = false
        -- gLobalViewManager:showReConnect()
        -- -- 放开格子点击
        -- self:setCellIsEnable(true)
        if failedCallFunc then
            failedCallFunc()
        end
    end

    -- printInfo("翻卡消息 " .. _idx)

    -- local stage_data = self:getCurrentStageData()
    -- dump(stage_data.boxes, "翻牌信息")
    -- _idx 从0开始
    local gameData = G_GetMgr(ACTIVITY_REF.Blast):getRunningData()
    if gameData and gameData:getNewUser() then
        gLobalSendDataManager:getNetWorkFeature():sendActionBlastPick(_idx, success_call_fun, faild_call_fun,1)
    else
        gLobalSendDataManager:getNetWorkFeature():sendActionBlastPick(_idx, success_call_fun, faild_call_fun)
    end
    self.bl_waitting = true
    -- 屏蔽格子点击
    -- self:setCellIsEnable(false)
    -- self.curCellIdx = _idx
end

-- 发送三选一
function BlastNet:requestSelectData(successCallFunc, failedCallFunc)

    local _successCallFunc = function(target,resultData)
        gLobalViewManager:addLoadingAnima()
        if successCallFunc then
            local result = json.decode(resultData.result)
            successCallFunc(result)
        end
    end

    local _failedCallFunc = function(target, code, errorMsg)
        gLobalViewManager:addLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end
    local actionData = self:getSendActionData(ActionType.BlastPick)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFunc, _failedCallFunc)
end

-- 炸弹
function BlastNet:requestBomData(_idx,successCallFunc, failedCallFunc)

    local _successCallFunc = function(target,resultData)
        gLobalViewManager:addLoadingAnima()
        if successCallFunc then
            local result = json.decode(resultData.result)
            successCallFunc(result)
        end
    end

    local _failedCallFunc = function(target, code, errorMsg)
        gLobalViewManager:addLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end
    local actionData = self:getSendActionData(ActionType.BlastBombBox)
    local params = {}
    params.index = _idx
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFunc, _failedCallFunc)
end

function BlastNet:sendNoviceTaskCollectReq(_activityType, _phaseIdx)
    local _successCallFunc = function(target,resultData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS)
    end

    local _failedCallFunc = function(target, code, errorMsg)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_FAILED)
    end
    local actionData = self:getSendActionData(ActionType.NewUserActivityMissionReward)
    local params = {}
    params.activityType = _activityType
    params.phase = _phaseIdx
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFunc, _failedCallFunc)
end

-- 收集最后领奖
function BlastNet:requestCollectReward(successCallFunc, failedCallFunc)

    local _successCallFunc = function(target,resultData)
        gLobalViewManager:addLoadingAnima()
        if successCallFunc then
            local result = json.decode(resultData.result)
            successCallFunc(result)
        end
    end

    local _failedCallFunc = function(target, code, errorMsg)
        gLobalViewManager:addLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end
    local actionData = self:getSendActionData(ActionType.BlastCollectReward)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFunc, _failedCallFunc)
end

return BlastNet
