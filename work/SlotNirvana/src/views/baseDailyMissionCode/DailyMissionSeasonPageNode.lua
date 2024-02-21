--[[
    --新版每日任务pass season任务节点
    csc 2021-06-21
]]
local DailyMissionSeasonPageNode = class("DailyMissionSeasonPageNode", util_require("base.BaseView"))

function DailyMissionSeasonPageNode:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionSeasonPageNode:initUI()
    self:createCsbNode(self:getCsbName())

    self:initCsbNodes()

    self:runCsbAction("idle", true, nil, 60)
    self:startButtonAnimation("btn_collect", "sweep")
end

function DailyMissionSeasonPageNode:getCsbName()
    if self.m_isPortrait then
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_Season_Vertical.csb"
    else
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_Season.csb"
    end
end

function DailyMissionSeasonPageNode:initCsbNodes()
    self.m_nodeSeasonMission = self:findChild("node_seasonMission") -- 任务节点
    self.m_nodeCompletedCd = self:findChild("node_completedCd") -- 当前任务完成进入cd
    self.m_nodeComingSoon = self:findChild("node_comingSoon") -- 活动未开启
    self.m_nodeUnlock = self:findChild("node_unlock") --未达到开启等级

    -- 任务界面节点
    self.m_labTime = self:findChild("lb_time")
    self.m_labGems = self:findChild("label_1")
    self.m_sprProgress = self:findChild("bar_progress")
    self.m_labProgress = self:findChild("lb_progress")
    self.m_labMissionID = self:findChild("lb_missionid")
    self.m_btnGem = self:findChild("btn_gems")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_barBottom = self:findChild("img_barBottom")
    self.m_nodeTime = self:findChild("node_time")
    -- 积分显示
    self.m_nodeMedal = self:findChild("node_medal")
    self.m_labMealNum = self:findChild("lb_medal")

    -- cd界面节点
    self.m_labCDTime = self:findChild("lb_cdtime")

    -- 等级解锁节点
    self.m_labUnlock = self:findChild("lb_unlock") --解锁等级

    self.m_nodeGift = self:findChild("node_gift")
    self.m_nodeMedalMultip = self:findChild("node_medal_jiaCheng")
    self.m_labMedelMultip = self:findChild("lb_medal_jiaCheng")

    self.m_nodeRushTitle = self:findChild("node_missionRushTitle")

    self.m_btnRefresh = self:findChild("btn_refresh")
end

function DailyMissionSeasonPageNode:initBtnRefresh()
    self.m_btnRefresh:setVisible(self:isShowRefreshBtn())
end

function DailyMissionSeasonPageNode:isShowRefreshBtn()
    if not self.m_missionData then
        return false
    end
    if not self.m_tasksData then
        return false
    end
    if not (self.m_missionData.m_refreshGems and self.m_missionData.m_refreshGems > 0) then
        return false
    end
    if self.m_tasksData.p_taskCompleted == true then
        return false
    end

    return true
end

-- 刷新数据
function DailyMissionSeasonPageNode:updateData(_missionData)
    self.m_missionData = _missionData
    if _missionData then
        self.m_tasksData = _missionData:getTaskInfo()
    end
    self.m_normalExp = 0
    self.m_bAutoCollect = false
    self:initBtnRefresh()
    self:updateView()
end

function DailyMissionSeasonPageNode:updateView()
    self.m_nodeSeasonMission:setVisible(false)
    self.m_nodeCompletedCd:setVisible(false)
    self.m_nodeComingSoon:setVisible(false)
    self.m_nodeUnlock:setVisible(false)
    -- 更新界面节点展示
    self:checkNodeStatus()
end

function DailyMissionSeasonPageNode:checkNodeStatus()
    -- 等级优先
    local openLevel = globalData.constantData.NEWPASS_OPEN_LEVEL
    local passData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if globalData.constantData.NEWUSERPASS_OPEN_SWITCH and globalData.constantData.NEWUSERPASS_OPEN_SWITCH > 0 then
        if passData and passData:isNewUserPass() then
            openLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
        else
            if globalData.userRunData.levelNum >= globalData.constantData.NEWUSERPASS_OPEN_LEVEL then
                openLevel = globalData.constantData.NEWPASS_OPEN_LEVEL
            else
                openLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
            end
        end
    end
    self:findChild("lb_unlock"):setString("" .. openLevel)
    if globalData.userRunData.levelNum < openLevel then
        -- 未达到开启等级
        self.m_nodeUnlock:setVisible(true)
    elseif not self.m_missionData or not G_GetMgr(ACTIVITY_REF.NewPass):getSeasonActivityOpen() then
        -- 如果当前没有活动数据
        self.m_nodeComingSoon:setVisible(true)
    elseif self.m_missionData:getInCd() then
        -- 当前在cd状态下
        self.m_nodeCompletedCd:setVisible(true)
        self:checkTimer()
    else
        self.m_nodeSeasonMission:setVisible(true)
        self:updateMissionView()
        -- 添加礼物节点
        if not self.m_giftNode then
            self.m_giftNode = util_createView("views.baseDailyMissionCode.DailyMissionGiftNode", "Season")
            self.m_nodeGift:addChild(self.m_giftNode)
        else
            self.m_giftNode:updateView("Season")
        end
        self.m_nodeGift:setVisible(true)
        self:checkTimer()
    end

    -- 更新rush title
    self:updateRushTitle()
end

function DailyMissionSeasonPageNode:updateMissionView()
    self:updateTaskDesc()
    -- 更新按钮状态
    self:updateBtnStatus()
    -- 进度条
    self:updateProgress()
    -- 更新经验奖励
    self:updateExpTips()
end

function DailyMissionSeasonPageNode:updateTaskDesc()
    -- 展示文本
    local tipStr = gLobalDailyTaskManager:getSpecialTaskDesc(self.m_tasksData)
    local strList = util_string_split(tipStr, ":")

    for i = 1, 3 do
        local lb = self:findChild("lb_desc" .. i)
        if lb then
            if i <= #strList then
                lb:setString(strList[i])
            else
                lb:setString("")
            end
        end
    end
end

function DailyMissionSeasonPageNode:updateBtnStatus()
    -- 取消钻石跳过
    self.m_btnGem:setVisible(false)
    if self.m_tasksData.p_taskCompleted == true then
        self.m_btnCollect:setVisible(true)
    else
        self.m_btnCollect:setVisible(false)
    end
end

function DailyMissionSeasonPageNode:updateProgress()
    self.m_sprProgress:setPercent(0)
    if self.m_tasksData then
        local process, params = self.m_tasksData:getTaskSchedule()
        if tonumber(process) >= tonumber(params) then
            process = params
        end
        local loadingPercent = tonumber(process) / tonumber(params) * 100
        if loadingPercent > 100 then
            loadingPercent = 100
        end
        loadingPercent = math.floor(loadingPercent)
        self.m_sprProgress:setPercent(loadingPercent)
        local currNum = util_formatCoins(tonumber(process), 3, nil, nil, nil, true)
        local totalNum = util_formatCoins(tonumber(params), 3, nil, nil, nil, true)
        local progressLab = currNum .. " / " .. totalNum
        self.m_labProgress:setString(progressLab)
    end
end

function DailyMissionSeasonPageNode:updateExpTips()
    self.m_normalExp = self.m_missionData:getPassExp()
    -- 开启buff 自检
    self:checkExpMultipTimer()
end

function DailyMissionSeasonPageNode:checkTimer()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    self.activityAction =
        util_schedule(
        self,
        function()
            self:updateLeftTime()
        end,
        1
    )
    self:updateLeftTime()
end

-- 更新剩余时间
function DailyMissionSeasonPageNode:updateLeftTime()
    if not G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission() then
        if self.activityAction ~= nil then
            self:stopAction(self.activityAction)
            self.activityAction = nil
        end
        return
    end

    local leftTime, isOver = self.m_missionData:getLeftTimeForPage()
    if isOver then
        if self.activityAction ~= nil then
            self:stopAction(self.activityAction)
        end
        -- 刷新下一个任务
        gLobalDailyTaskManager:sendQuerySeasonMission()
    else
        self.m_labTime:setString(leftTime)
        self.m_labCDTime:setString(leftTime)
    end
end

function DailyMissionSeasonPageNode:checkExpMultipTimer()
    -- if gLobalDailyTaskManager:getPassExpMultipByActivity() > 1 then
    if self.buffAction ~= nil then
        self:stopAction(self.buffAction)
        self.buffAction = nil
    end
    self.buffAction =
        util_schedule(
        self,
        function()
            self:updateExpMultipTimer()
        end,
        1
    )
    -- end
    self:updateExpMultipTimer()
end

function DailyMissionSeasonPageNode:updateExpMultipTimer()
    local multip = G_GetMgr(ACTIVITY_REF.NewPass):getPassExpMultipByActivity()
    if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
        local newPassData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if newPassData and  newPassData:getCurrIsPayHigh() then
            local goodInfo = G_GetMgr(ACTIVITY_REF.NewPassBuy):getPayPassTicketInfo()
            if goodInfo then
                local middleData = goodInfo[2]
                if middleData then
                    local expPercent = tonumber(middleData:getExpPercent()) / 100
                    multip = multip + expPercent
                end
            end
        end
    end

    local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if data then
        local isBuyMonthlyCardNormal = data:isBuyMonthlyCardNormal()
        if isBuyMonthlyCardNormal then --购买了普通版月卡
            local additon = data:getPassAddition() 
            multip = multip * additon
        end
    end

    self.m_addExp = math.floor(self.m_normalExp * multip + 0.5)

    if multip > 1 then
        self.m_nodeMedalMultip:setVisible(true)
        self.m_labMedelMultip:setString("x" .. multip)
    else
        self.m_nodeMedalMultip:setVisible(false)
    end

    self.m_labMealNum:setString(self.m_addExp)
end

function DailyMissionSeasonPageNode:setAutoCollect(_flag)
    self.m_bAutoCollect = _flag
end

function DailyMissionSeasonPageNode:clickFunc(_sender)
    if self.m_bAutoCollect then
        return
    end
    local name = _sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_gems" then
        local view = util_createView("views.baseDailyMissionCode.DailyMissionMainGemsConfirmLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        view:updateView(gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION, self.m_missionData.p_gems)
    elseif name == "btn_collect" then
        self.m_btnCollect:setTouchEnabled(false)
        local isNewUser = gLobalDailyTaskManager:isWillUseNovicePass()
        gLobalDailyTaskManager:sendMissionCollectAction(gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION, self.m_tasksData.p_taskId, self.m_addExp,isNewUser,true)
    elseif name == "btn_skip" then
        -- 玩家需要跳过cd 弹出付费面板买 pass ticket
        gLobalDailyTaskManager:createBuyPassTicketLayer()
    elseif name == "btn_refresh" then
        local view = util_createView("views.baseDailyMissionCode.DailyMissionReFreshLayer",gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION, self.m_missionData.m_refreshGems)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DailyMissionSeasonPageNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.missionType == gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION then
                self:playFlyAction()
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_OPENGIFT_ACTION
    )
end

function DailyMissionSeasonPageNode:onExit()
    if self.buffAction ~= nil then
        self:stopAction(self.buffAction)
        self.buffAction = nil
    end
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    DailyMissionSeasonPageNode.super.onExit(self)
end

------------ 动画相关 ---------
function DailyMissionSeasonPageNode:getMedalNodePos()
    return self.m_nodeMedal:getParent():convertToWorldSpace(cc.p(self.m_nodeMedal:getPosition()))
end

function DailyMissionSeasonPageNode:getMedalNums()
    return self.m_addExp
end

function DailyMissionSeasonPageNode:refreshAction(_missionData, _callback)
    --先执行一下刷新的动画
    gLobalSoundManager:playSound(DAILYPASS_RES_PATH.PASS_MISSION_REFRESH_MP3)
    self:runCsbAction(
        "over",
        false,
        function()
            self:updateData(_missionData)
            self:runCsbAction(
                "start",
                false,
                function()
                    self:runCsbAction("idle", true, nil, 60)
                    self.m_btnCollect:setTouchEnabled(true)
                    if _callback then
                        _callback()
                    end
                end,
                60
            )
        end,
        60
    )
end

function DailyMissionSeasonPageNode:playFlyAction()
    -- 重新生成一个礼物盒节点,播放动画
    if self.m_giftNode then
        self.m_nodeGift:setVisible(false)
        local pos = self.m_nodeGift:getParent():convertToWorldSpace(cc.p(self.m_nodeGift:getPosition()))
        gLobalDailyTaskManager:createFlyGifNode("Season", pos)
    end
end

function DailyMissionSeasonPageNode:getGiftPos()
    local pos = self.m_nodeGift:getParent():convertToWorldSpace(cc.p(self.m_nodeGift:getPosition()))
    return pos
end

function DailyMissionSeasonPageNode:updateRushTitle()
    local actData = G_GetMgr(ACTIVITY_REF.SeasonMissionRush):getRunningData()
    if self.m_nodeRushTitle and not self.rushTitleNode then
        if actData then
            -- 创建节点
            self.rushTitleNode = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_RushTitleNode, "Season")
            self.m_nodeRushTitle:addChild(self.rushTitleNode)
        end
    end
    if self.rushTitleNode and (not actData or actData:isCompleted()) then
        self.rushTitleNode:removeFromParent()
        self.rushTitleNode = nil
    end
end
return DailyMissionSeasonPageNode
