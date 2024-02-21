--[[
Author: cxc
Date: 2022-01-10 15:56:28
LastEditTime: 2022-01-10 15:56:29
LastEditors: your name
Description: Lottery乐透 挑战活动 弹板基类
FilePath: /SlotNirvana/src/activities/Activity_LotteryChallenge/base/LotteryChallengeBaseView.lua
--]]
local LotteryChallengeBaseView = class("LotteryChallengeBaseView", BaseLayer)
local LotteryChallengeConfig = util_require("activities.Activity_LotteryChallenge.config.LotteryChallengeConfig")

function LotteryChallengeBaseView:ctor()
    LotteryChallengeBaseView.super.ctor(self)

    self:setKeyBackEnabled(true) 
    self:setPauseSlotsEnabled(true) 

    -- csb资源路径
    local csbThemeName = self:getCsbThemeName()
    self:setLandscapeCsbName(csbThemeName)
    -- 任务条luaView
    self.m_taskCellLuaFilePath = self:getTaskCellLuaFilePath()
    
    self.m_actData = G_GetMgr(ACTIVITY_REF.LotteryChallenge):getData() -- 数据
    self.m_canCollectedList = {} -- 可以领奖的数据列表
    self.m_rewardItemList = {}
    self.m_canCollectedCoins = 0
end

function LotteryChallengeBaseView:getCsbThemeName()
    return ""
end
function LotteryChallengeBaseView:getTaskCellLuaFilePath()
    return "activities.Activity_LotteryChallenge.base.LotteryChallengeBaseTaskCell"
end

function LotteryChallengeBaseView:initCsbNodes()
    self.m_lbLeftTime = self:findChild("lb_time2") -- 活动倒计时
    self.m_btnClose = self:findChild("btn_X")
end

function LotteryChallengeBaseView:onShowedCallFunc()
    LotteryChallengeBaseView.super.onShowedCallFunc(self)
    
    -- 播放 完成未领奖的 的任务动画
    for i, taskCellUI in ipairs(self.m_canCollectedList) do
        taskCellUI:playUnCollectedAct()
    end
end

function LotteryChallengeBaseView:initView()
    LotteryChallengeBaseView.super.initView(self)
    -- 活动 任务UI
    self:initTaskUI()

    -- 按钮文本UI
    self:updateBtnUI()

    -- 活动倒计时
    self:updateLeftTimeUI()
    self.m_timeScheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
end

-- 活动 任务UI
function LotteryChallengeBaseView:initTaskUI()
    --任务列表
    local taskList = self.m_actData:getTaskList() 
    local taskCur = self.m_actData:getTaskCur() --当前完成的任务

    for i=1, #taskList do
        local node = self:findChild("node_task" .. i)
        local taskData = taskList[i]
        if node and taskData then
            local taskNeed = taskData:getTaskNeed()
            local bCollected = taskData:isCollected() 
            local nodeTaskCell = util_createView(self.m_taskCellLuaFilePath, taskCur, taskData)
            node:addChild(nodeTaskCell)
            
            if taskCur >= taskNeed and not bCollected then
                self.m_canCollectedCoins = self.m_canCollectedCoins + taskData:getRewardCoins()
                local rewardList = taskData:getRewardItems()
                self:addRewardItem(rewardList) 
                table.insert(self.m_canCollectedList, nodeTaskCell)
            end 
        end
    end 

end

-- 任务奖励
function LotteryChallengeBaseView:addRewardItem(_list)
    if not _list then
        return
    end
    for _, rewardData in ipairs(_list) do
        table.insert(self.m_rewardItemList, rewardData)
        
    end
end

-- 按钮文本UI
function LotteryChallengeBaseView:updateBtnUI()
    -- 未完成时文案为：LOTTO MORE，完成时文案为COLLECT
    local key = "Activity_LotteryChallenge:btn_goLottery"
    if #self.m_canCollectedList > 0 then
        key = "Activity_LotteryChallenge:btn_collect"
    end
    local labelStr = gLobalLanguageChangeManager:getStringByKey(key)
    self:setButtonLabelContent("btn_collect", labelStr)
    self:startButtonAnimation("btn_collect", "breathe", true) 
end

-- 活动倒计时
function LotteryChallengeBaseView:updateLeftTimeUI()
    if tolua.isnull(self.m_lbLeftTime) then
        self:clearScheduler()
        return
    end

    local leftTimeStr, bOver = util_daysdemaining(self.m_actData:getExpireAt())
    if bOver then
        self.m_lbLeftTime:setString("00:00:00")
        self:clearScheduler()
        return
    end
    
    self.m_lbLeftTime:setString(leftTimeStr)
end

function LotteryChallengeBaseView:clickFunc(_sender)
    local btnName = _sender:getName()

    if btnName == "btn_X" then
        if #self.m_canCollectedList > 0 then
            G_GetMgr(ACTIVITY_REF.LotteryChallenge):sendCollectReq()
            return
        end
        
        local cb = function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        self:closeUI(cb)
    elseif btnName == "btn_collect" then
        if #self.m_canCollectedList > 0 then
            G_GetMgr(ACTIVITY_REF.LotteryChallenge):sendCollectReq()
        else
            self:closeUI()
            G_GetMgr(G_REF.Lottery):showMainLayer()
        end
    end
    
end

function LotteryChallengeBaseView:actTimeEndEvt(_params)
    if _params and _params.name == ACTIVITY_REF.LotteryChallenge then
        self:closeUI()
    end
end

function LotteryChallengeBaseView:collectedSuccessEvt()
    -- 更新任务UI
    for i, taskCellUI in ipairs(self.m_canCollectedList) do
        taskCellUI:collectedSuccessEvt(self.m_canCollectedCoins)
    end

    if next(self.m_rewardItemList) then
        local callbackfunc = function()
            if CardSysManager:needDropCards("Lottery Challenge") == true then
                CardSysManager:doDropCards("Lottery Challenge")
            end
        end
        local rewardLayer = gLobalItemManager:createRewardLayer(self.m_rewardItemList, callbackfunc, self.m_canCollectedCoins, true)
        gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
    end

    -- 更新按钮状态
    self.m_canCollectedList = {}
    self:updateBtnUI()
end

function LotteryChallengeBaseView:registerListener()
    LotteryChallengeBaseView.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "actTimeEndEvt", ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
    gLobalNoticManager:addObserver(self, "collectedSuccessEvt", LotteryChallengeConfig.EVENT_NAME.RECIEVE_COLLECT_LOTTERY_TASK_REWARD)
end

-- 清楚定时器
function LotteryChallengeBaseView:clearScheduler()
    if self.m_timeScheduler then
        self:stopAction(self.m_timeScheduler)
        self.m_timeScheduler = nil
    end
end

return LotteryChallengeBaseView