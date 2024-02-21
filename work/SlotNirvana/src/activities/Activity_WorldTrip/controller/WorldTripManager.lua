--[[
    大富翁 活动管理器
    注意：尽量在此类进行数据处理 如有操作界面 必须post事件出去
]] --
local WorldTripGuideCtrl = require("activities.Activity_WorldTrip.controller.WorldTripGuideCtrl")
local WorldTripManager = class("WorldTripManager", BaseActivityControl)
local WorldTripNet = require("activities.Activity_WorldTrip.net.WorldTripNet")

function WorldTripManager:ctor()
    WorldTripManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WorldTrip)

    self.m_worldTripNet = WorldTripNet:getInstance()
    self.m_guide = WorldTripGuideCtrl:getInstance()
end

function WorldTripManager:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    self.m_guide:triggerGuide(view, name, ACTIVITY_REF.WorldTrip)
end

-- 发送掷骰子消息
function WorldTripManager:play(point)
    -- 等待消息结果
    if self.bl_waitting and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(target, resultData)
        self.bl_waitting = false
        local act_data = self:getRunningData()
        if act_data then
            local result = json.decode(resultData)
            if result ~= nil then
                act_data:parsePlayData(result)
            else
                local errorMsg = "parse world trip play data error"
                printInfo(errorMsg)
                release_print(errorMsg)
                gLobalViewManager:showReConnect()
            end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORLDTRIP_PLAY_RESULT, {type = "normal", num = point})
    end

    local faild_call_fun = function(target, errorCode, errorData)
        self.bl_waitting = false
        gLobalViewManager:showReConnect()
    end

    printInfo("发送掷骰子消息")
    self.m_worldTripNet:sendActionPlay(point, success_call_fun, faild_call_fun)
    self.bl_waitting = true
    local act_data = self:getRunningData()
    if act_data then
        local cur_idx = act_data:getCurIdx()
        act_data:setLastIndex(cur_idx)
    end
end

-- 发送掷骰子消息
function WorldTripManager:recallPlay()
    -- 等待消息结果
    if self.bl_waitting and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(target, resultData)
        self.bl_waitting = false
        local act_data = self:getRunningData()
        if act_data then
            local result = json.decode(resultData)
            if result ~= nil then
                act_data:parseRecallPlayData(result)
            else
                local errorMsg = "parse world trip play data error"
                printInfo(errorMsg)
                release_print(errorMsg)
                gLobalViewManager:showReConnect()
            end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORLDTRIP_PLAY_RESULT, {type = "recall"})
    end

    local faild_call_fun = function(target, errorCode, errorData)
        self.bl_waitting = false
        gLobalViewManager:showReConnect()
    end

    printInfo("发送掷骰子消息")
    self.m_worldTripNet:sendActionRecallPlay(success_call_fun, faild_call_fun)
    self.bl_waitting = true
    local act_data = self:getRunningData()
    if act_data then
        local recall_data = act_data:getRecallData()
        if recall_data then
            local cur_idx = recall_data:getCurIdx()
            recall_data:setLastIndex(cur_idx)
        end
    end
end

function WorldTripManager:isCanRecallRewardCollect()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return (act_data:getStatus() == "RECALL_END")
end

function WorldTripManager:collectRecallReward()
    -- 等待消息结果
    if self.bl_waitting and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(target, resultData)
        self.bl_waitting = false

        local result = json.decode(resultData)
        if result ~= nil then
            if result.selectDiceNumberTimes then
                local act_data = self:getRunningData()
                if act_data then
                    act_data.optionalDices = result.selectDiceNumberTimes
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.WorldTrip})
                end
            end
        end

        local rewardUI = util_createView("Activity.WorldTripGame.WorldTripReward", "Recall")
        if not rewardUI then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORLDTRIP_RECALL_REWARD_COLLECT)
            return
        end
        gLobalViewManager:showUI(rewardUI, ViewZorder.ZORDER_UI)
    end
    local faild_call_fun = function()
        gLobalViewManager:showReConnect()
    end
    printInfo("发送掷骰子消息")
    self.m_worldTripNet:sendActionRecallReward(success_call_fun, faild_call_fun)
    self.bl_waitting = true
end

function WorldTripManager:isCanPhaseRewardCollect()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return (act_data:getCurIdx() == act_data:getMaxIdx())
end

function WorldTripManager:collectPhaseReward()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    local phase_idx = act_data:getCurrent()

    -- 等待消息结果
    if self.bl_waitting and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(target, resultData)
        self.bl_waitting = false
        local reward = json.decode(resultData)
        local act_data = self:getRunningData()
        if act_data then
            if reward.chapterReward then
                act_data:setPhaseRewardRecord(reward.chapterReward)
            end
            if reward.roundReward then
                act_data:setFinalRewardRecord(reward.roundReward)
            end
        end

        local rewardUI = util_createView("Activity.WorldTripGame.WorldTripPhaseReward", phase_idx)
        if not rewardUI then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORLDTRIP_PHASE_REWARD_COLLECT)
            return
        end
        gLobalViewManager:showUI(rewardUI, ViewZorder.ZORDER_UI)
    end
    local faild_call_fun = function()
        gLobalViewManager:showReConnect()
    end
    printInfo("发送掷骰子消息")
    self.m_worldTripNet:sendActionChapterReward(success_call_fun, faild_call_fun)
    self.bl_waitting = true
end

function WorldTripManager:isCanFinalRewardCollect()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    -- TODO
    return false
end

-- 获取最终大奖
function WorldTripManager:getFinalReward()
    local act_data = self:getRunningData()
    if act_data then
        return act_data:getFinalReward()
    else
        return nil
    end
end

function WorldTripManager:getStateData()
    local act_data = self:getRunningData()
    if act_data then
        return act_data.stageData
    else
        return nil
    end
end

function WorldTripManager:isOptionalDice()
    return self:getOptionalDices() > 0
end

-- 剩余骰子数
function WorldTripManager:getDices()
    local act_data = self:getRunningData()
    if act_data then
        return act_data:getDices()
    else
        return 0
    end
end

-- 双倍骰子数
function WorldTripManager:getOptionalDices()
    local act_data = self:getRunningData()
    if act_data then
        return act_data:getOptionalDices()
    else
        return 0
    end
end

function WorldTripManager:getInCoinBuff()
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_WORLDTRIP_COINBUFF)
    return leftTimes and leftTimes > 0
end

-- 骰子转动结果
function WorldTripManager:getDiceResult()
    local act_data = self:getRunningData()
    if act_data then
        return act_data.dice
    else
        return 0
    end
end

-- 大厅展示资源判断
function WorldTripManager:isDownloadLobbyRes()
    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

function WorldTripManager:showLevelLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("WorldTripLevel") == nil then
        local levelUI = util_createFindView("Activity/WorldTripGame/LevelUI/WorldTripLevel")
        if levelUI ~= nil then
            gLobalViewManager:showUI(levelUI, ViewZorder.ZORDER_UI)
        end
    end
end

function WorldTripManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return
    end

    self.m_guide:onRegist(ACTIVITY_REF.WorldTrip)

    if gLobalViewManager:getViewByExtendData("WorldTripMainUI") == nil then
        local mainUI = util_createFindView("Activity/WorldTripGame/WorldTripMainUI", params)
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function WorldTripManager:showRankView()
    if not self:isCanShowLayer() then
        return
    end

    local rankUI = nil
    if gLobalViewManager:getViewByExtendData("WorldTripRankUI") == nil then
        rankUI = util_createView("Activity.WorldTripRank.WorldTripRankUI")
        gLobalViewManager:showUI(rankUI, ViewZorder.ZORDER_POPUI)
    end
    return rankUI
end

-- 新版大富翁 请求排行榜数据
function WorldTripManager:sendActionRank()
    self.m_worldTripNet:sendActionRank()
end

-- 获取buff节点所在位置
function WorldTripManager:getBuffWorldPos()
    return self.buff_pos
end

-- 记录buff节点所在位置
function WorldTripManager:setBuffWorldPos(pos)
    self.buff_pos = pos
end

return WorldTripManager
