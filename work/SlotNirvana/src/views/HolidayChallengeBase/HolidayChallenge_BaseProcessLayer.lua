--[[
    独立日新版聚合挑战 获得进度弹板
    author:csc
    time:2021-05-31
]]
local HolidayChallenge_BaseProcessLayer = class("HolidayChallenge_BaseProcessLayer", BaseLayer)

function HolidayChallenge_BaseProcessLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.PROCESS_LAYER)
end

function HolidayChallenge_BaseProcessLayer:initUI(_type, _params)
    HolidayChallenge_BaseProcessLayer.super.initUI(self)
    self.m_params = _params or {}
    self.m_isAutoClose = self.m_params.isAutoClose or false
    self:updateView(_type)
    self:initAutoClose()
end

function HolidayChallenge_BaseProcessLayer:initAutoClose()
    local lb_close = self:findChild("lb_close")
    if not lb_close then
        return
    end
    lb_close:setVisible(self.m_isAutoClose)
    self.m_lb_close = lb_close
    if self.m_isAutoClose then
        local onTick = function(sec)
            lb_close:setString(string.format("CLOSING IN %d S...", sec))
        end
        self:setAutoCloseUI(nil, onTick, handler(self, self.closeView))
    end
end

function HolidayChallenge_BaseProcessLayer:stopAutoCloseUITimer()
    if self.m_lb_close then
        self.m_lb_close:setVisible(false)
    end
    HolidayChallenge_BaseProcessLayer.super.stopAutoCloseUITimer(self)
end

function HolidayChallenge_BaseProcessLayer:initCsbNodes()

    self.m_labTaskPoint = self:findChild("lb_number") -- 本次任务给的点数 n
    self.m_labProgress = self:findChild("lb_progress_num") -- 当前总进度 p+n
    self.m_labNeedPoint = self:findChild("lb_need_num") -- 获取奖励还需要 m-(p+n)

    self.m_nodeReward = self:findChild("node_youjiang") -- 有奖励
    self.m_nodeNoReward = self:findChild("node_meijiang") -- 没奖励

    self.m_lb_close = self:findChild("lb_close")
    if self.m_lb_close then
        self.m_lb_close:setVisible(false)
    end
    self.m_nodeNoReward:setVisible(false)
    self.m_nodeReward:setVisible(false)

    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getCurrThemeName() .."ProgressLayer:btn_start"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) ~= "" and gLobalLanguageChangeManager:getStringByKey(key) or "COME ON"
    self:setButtonLabelContent("btn_start", lbString)

    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getCurrThemeName() .."ProgressLayer:btn_claim"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) ~= "" and gLobalLanguageChangeManager:getStringByKey(key) or "LET'S DO IT"
    self:setButtonLabelContent("btn_claim", lbString)
end

--重写父类方法
function HolidayChallenge_BaseProcessLayer:onShowedCallFunc( )
    self:runCsbAction("idle", true, nil,60)
    if self.m_lb_close and self.m_taskType == "holidayChallengeWhell" then
        self.m_lb_close:setVisible(true)
        self.m_leftTime = 11
        self:updateLeftTimeUI()
        self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
    end
end

function HolidayChallenge_BaseProcessLayer:updateLeftTimeUI()
    self.m_leftTime = self.m_leftTime - 1
    if self.m_leftTime <= 0 then
        if self.m_leftTimeScheduler then
            self:stopAction(self.m_leftTimeScheduler)
            self.m_leftTimeScheduler = nil
        end
        local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
        if actData and self.m_taskType then
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendRefreshReq(self.m_taskType,1)
        end
        self:closeUI(function(  )
            if self.m_newOverFunc then
                self.m_newOverFunc()
            end
        end)
    end
    if self.m_leftTime > 1 then
        self.m_lb_close:setString("CLOSING IN "..self.m_leftTime .." SECONDS…" )
    else
        self.m_lb_close:setString("CLOSING IN "..self.m_leftTime .." SECOND…" )
    end
    
end

function HolidayChallenge_BaseProcessLayer:updateView(_type)
    self.m_taskType = _type

    if _type == "holidayChallengeWhell" then
        self.m_nodeReward:setVisible(false)
        self.m_nodeNoReward:setVisible(false)
        self:findChild("node_congrats"):setVisible(false)
        self:findChild("node_progress"):setVisible(false)

        local addNum = 1
        local lb_numberwheel = self:findChild("lb_number_0")
        local lb_youhave = self:findChild("lb_word_0_0")
        local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
        if holidayData then
            local wheelData = holidayData:getWheelData()
            if wheelData then
                local spinLeft = wheelData:getSpinLeft()
                local lastSpinLeft = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getSpinLeft()
                addNum = spinLeft - lastSpinLeft
            end
        end
        lb_numberwheel:setString("X" .. addNum)
        lb_youhave:setString("YOU WON " .. addNum .. " CELEBRATION DRAW!")
    else
        local node_wheel = self:findChild("node_wheel")
        if node_wheel then
            node_wheel:setVisible(false)
        end
        local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
        if actData then
            -- 本次任务给的点数 n
            local taskPoint = 0
            local taskUnCollectNum = 0
            local tbTaskData = actData:getTaskData()
            for i = 1 ,#tbTaskData do
                local taskData = tbTaskData[i] 
                if taskData and taskData:getStatus() == "completed" then -- 防止用户有不同类型的任务完成跳过 这里需要累加
                    if _type == taskData:getTaskType() then
                        taskPoint = taskData:getPoints()
                    end
                    taskUnCollectNum = taskUnCollectNum + taskData:getUnCollectedNums()
                end
            end
            self.m_labTaskPoint:setString("X"..taskPoint)

            -- 当前总进度 p+n
            local currTotalProgress = actData:getCurrentPoints() + taskUnCollectNum
            currTotalProgress = currTotalProgress >= actData:getMaxPoints() and actData:getMaxPoints() or currTotalProgress
            self.m_labProgress:setString(currTotalProgress.."/"..actData:getMaxPoints())

            --看当前是否有奖励可以领取
            if G_GetMgr(ACTIVITY_REF.HolidayChallenge):isArriveRewardPoint(actData:getCurrentPoints(),currTotalProgress) then -- 当前有奖励可以领取
                self.m_nodeReward:setVisible(true)
            else --当前没有奖励可以领取
                self.m_nodeNoReward:setVisible(true)
                --获取奖励还需要 m-(p+n)
                local rewardPointList = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasPayRewardPoint()
                for i = 1,#rewardPointList do
                    if currTotalProgress < rewardPointList[i] then -- 有序队列,找到第一个比当前总进度大的即可
                        local num = rewardPointList[i] - currTotalProgress
                        self.m_labNeedPoint:setString(num)
                        break
                    end
                end
            end
        end
    end
end

-- 重写父类方法 
function HolidayChallenge_BaseProcessLayer:onEnter()
    HolidayChallenge_BaseProcessLayer.super.onEnter(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:closeUI(function(  )
                    if self.m_newOverFunc then
                        self.m_newOverFunc()
                    end
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HolidayChallenge_BaseProcessLayer:onExit()
    HolidayChallenge_BaseProcessLayer.super.onExit(self)
end

function HolidayChallenge_BaseProcessLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()
    if name == "btn_start" or name == "btn_claim" or name == "btn_wheel" then
        -- 需要打开主界面
        self:closeUI(function()
            if self.m_taskType == "holidayChallengeWhell" then
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):showWheelLayer(self.m_newOverFunc)
            else
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):checkMainLayer(self.m_newOverFunc)
            end
        end)
    elseif name == "btn_close" then
        self:closeView()
    end
end

function HolidayChallenge_BaseProcessLayer:closeView()
    self:closeUI(function(  )
        -- 需要刷新数据
        local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
        if actData and self.m_taskType then
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendRefreshReq(self.m_taskType,1)
        end
        if self.m_newOverFunc then
            self.m_newOverFunc()
        end
    end)
end

function HolidayChallenge_BaseProcessLayer:setViewOverFunc(_func)
    self.m_newOverFunc = _func
end

return HolidayChallenge_BaseProcessLayer
