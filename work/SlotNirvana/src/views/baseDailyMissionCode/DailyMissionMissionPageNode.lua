--[[
    --新版每日任务pass 任务节点
]]
local DailyMissionMissionPageNode = class("DailyMissionMissionPageNode", BaseView)

function DailyMissionMissionPageNode:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionMissionPageNode:initUI()
    self:createCsbNode(self:getCsbName())

    self:initCsbNodes()

    self:runCsbAction("idle", true, nil, 60)
    self:startButtonAnimation("btn_collect", "sweep")
end

function DailyMissionMissionPageNode:getCsbName()
    if self.m_isPortrait then
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_Daily_Vertical.csb"
    else
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_Daily.csb"
    end
end

function DailyMissionMissionPageNode:initCsbNodes()
    self.m_nodeDailyMission = self:findChild("node_dailyMission") -- 任务节点
    self.m_nodeDailyCompleted = self:findChild("node_dailyComplete") -- 全部完成节点

    self.m_labTime = self:findChild("lb_time")
    self.m_labDesc = self:findChild("lb_desc")
    self.m_labGems = self:findChild("label_1")

    self.m_sprProgress = self:findChild("bar_progress")
    self.m_labProgress = self:findChild("lb_progress")
    self.m_labMissionID = self:findChild("lb_missionid")

    -- 积分显示
    self.m_nodeMedal = self:findChild("node_medal")
    self.m_labMealNum = self:findChild("lb_medal")

    self.m_btnGem = self:findChild("btn_gems")
    self.m_btnCollect = self:findChild("btn_collect")

    self.m_nodeGift = self:findChild("node_gift")
    self.m_nodeMedalMultip = self:findChild("node_medal_jiaCheng")
    self.m_labMedelMultip = self:findChild("lb_medal_jiaCheng")

    self.m_nodeRushTitle = self:findChild("node_missionRushTitle")

    self.m_btnRefresh = self:findChild("btn_refresh")
end

function DailyMissionMissionPageNode:initBtnRefresh()
    self.m_btnRefresh:setVisible(self:isShowRefreshBtn())
end

function DailyMissionMissionPageNode:isShowRefreshBtn()
    if not self.m_missionData then
        return false
    end
    if not self.m_tasksData then
        return false
    end
    if not (self.m_missionData.p_refreshGems and self.m_missionData.p_refreshGems > 0) then
        return false
    end
    if self.m_tasksData.p_taskCompleted == true then
        return false
    end
    if self.m_missionData.p_allMissionCompleted == true then
        return false
    end
    return true
end

-- 刷新数据
function DailyMissionMissionPageNode:updateData(_missionData)
    self.m_missionData = _missionData
    self.m_tasksData = _missionData.p_taskInfo
    self.m_normalExp = 0
    self.m_bAutoCollect = false
    self:initBtnRefresh()
    self:updateView()
end

function DailyMissionMissionPageNode:updateView()
    -- 判断当前任务全部的完成情况
    if self.m_missionData.p_allMissionCompleted then
        self.m_nodeDailyCompleted:setVisible(true)
        self.m_nodeDailyMission:setVisible(false)
    else
        self.m_nodeDailyCompleted:setVisible(false)
        self.m_nodeDailyMission:setVisible(true)
        self:updateMissionView()
        -- 添加礼物节点
        if not self.m_giftNode then
            self.m_giftNode = util_createView("views.baseDailyMissionCode.DailyMissionGiftNode", "Daily")
            self.m_nodeGift:addChild(self.m_giftNode)
        else
            self.m_giftNode:updateView("Daily")
        end
        self.m_nodeGift:setVisible(true)
    end
    -- 倒计时
    self:checkTimer()
end

function DailyMissionMissionPageNode:updateMissionView()
    -- 展示当前任务id
    local missionId = self.m_missionData.p_currMissionID .. "/" .. self.m_missionData.p_totalMissionNum
    self.m_labMissionID:setString(missionId)
    self:updateTaskDesc()
    -- 更新按钮状态
    self:updateBtnStatus()
    -- 进度条
    self:updateSchedule()
    -- 更新经验奖励
    self:updateExpTips()
end

function DailyMissionMissionPageNode:updateTaskDesc()
    -- 展示文本
    local tipStr = gLobalDailyTaskManager:getSpecialTaskDesc(self.m_tasksData)
    local strList = util_string_split(tipStr, ":")

    -- 兼容处理
    local size = #strList
    local posYList = {{50}, {62, 25}, {80, 50, 20}}
    if size > #posYList then
        size = #posYList
    end
    local selPosY = posYList[size]
    for i = 1, #posYList do
        local lb = self:findChild("lb_desc" .. i)
        if lb then
            if i <= size then
                lb:setString(strList[i])
                --lb:setPositionY(selPosY[i])
            else
                lb:setString("")
            end
        end
    end
end

function DailyMissionMissionPageNode:updateSchedule()
    self.m_sprProgress:setPercent(0)
    if self.m_tasksData then
        local process, params = self.m_tasksData:getTaskSchedule()
        if tonumber(process) >= tonumber(params) then
            process = params
        end
        -- self.lab_schedule:setString(util_formatCoins(collect, 8).."/"..util_formatCoins(pool, 8))
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

function DailyMissionMissionPageNode:updateBtnStatus()
    if self.m_tasksData.p_taskCompleted == true then
        self.m_btnGem:setVisible(false)
        self.m_btnCollect:setVisible(true)
    else
        -- self.m_labGems:setString(self.m_missionData.p_gems)
        self.m_btnGem:setVisible(true)
        self.m_btnCollect:setVisible(false)
        self:setButtonLabelContent("btn_gems", self.m_missionData.p_gems)
    end
end

function DailyMissionMissionPageNode:updateExpTips()
    if self.m_tasksData then
        self.m_normalExp = self.m_tasksData.p_taskPoint
        -- 开启buff 自检
        self:checkExpMultipTimer()
    end
end

function DailyMissionMissionPageNode:checkTimer()
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

    -- 更新rush title
    self:updateRushTitle()
end

-- 更新剩余时间
function DailyMissionMissionPageNode:updateLeftTime()
    local dayTime, weekTime = self.m_missionData:getLeftTime()
    local mleftTime = util_count_down_str(dayTime)
    self.m_labTime:setString(mleftTime)
end

function DailyMissionMissionPageNode:checkExpMultipTimer()
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

function DailyMissionMissionPageNode:updateExpMultipTimer()
    local newPassData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not newPassData then
        self.m_nodeMedal:setVisible(false)
        return
    else
        self.m_nodeMedal:setVisible(true)
    end
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

function DailyMissionMissionPageNode:setAutoCollect(_flag)
    self.m_bAutoCollect = _flag
end

function DailyMissionMissionPageNode:clickFunc(_sender)
    if self.m_bAutoCollect then
        return
    end
    local name = _sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_gems" then
        local view = util_createView("views.baseDailyMissionCode.DailyMissionMainGemsConfirmLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        view:updateView(gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION, self.m_missionData.p_gems)
    elseif name == "btn_collect" then
        -- 引导打点：每日任务完成提示-3.领取任务奖励
        if gLobalSendDataManager:getLogGuide():isGuideBegan(7) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(7, 3)
        end
        self.m_btnCollect:setTouchEnabled(false)
        gLobalDailyTaskManager:sendMissionCollectAction(gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION, self.m_tasksData.p_taskId, self.m_addExp,false,true)
    elseif name == "btn_refresh" then
        local view = util_createView("views.baseDailyMissionCode.DailyMissionReFreshLayer",gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION, self.m_missionData.p_refreshGems)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DailyMissionMissionPageNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params) --
            if params.missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION then
                self:playFlyAction()
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_OPENGIFT_ACTION
    )
end

function DailyMissionMissionPageNode:onExit()
    if self.buffAction ~= nil then
        self:stopAction(self.buffAction)
        self.buffAction = nil
    end
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    DailyMissionMissionPageNode.super.onExit(self)
end

------------ 刷新动画 ---------
function DailyMissionMissionPageNode:getMedalNodePos()
    return self.m_nodeMedal:getParent():convertToWorldSpace(cc.p(self.m_nodeMedal:getPosition()))
end

function DailyMissionMissionPageNode:getMedalNums()
    return self.m_addExp
end

function DailyMissionMissionPageNode:refreshAction(_missionData, _callback)
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

function DailyMissionMissionPageNode:playFlyAction()
    -- 重新生成一个礼物盒节点,播放动画
    if self.m_giftNode then
        self.m_nodeGift:setVisible(false)
        local pos = self.m_nodeGift:getParent():convertToWorldSpace(cc.p(self.m_nodeGift:getPosition()))
        gLobalDailyTaskManager:createFlyGifNode("Daily", pos,true)
    end
end

function DailyMissionMissionPageNode:getGiftPos()
    local pos = self.m_nodeGift:getParent():convertToWorldSpace(cc.p(self.m_nodeGift:getPosition()))
    return pos
end

function DailyMissionMissionPageNode:updateMedalMultip(_visible)
end

function DailyMissionMissionPageNode:changeGiftTexture()
    util_changeTexture(self.m_nodeGift, DAILYPASS_RES_PATH.DailyMissionPass_GiftIconLottery)
end

function DailyMissionMissionPageNode:updateRushTitle()
    local actData = G_GetMgr(ACTIVITY_REF.DailyMissionRush):getRunningData()
    if self.m_nodeRushTitle and not self.rushTitleNode then
        if actData then
            -- 创建节点
            self.rushTitleNode = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_RushTitleNode, "Daily")
            self.m_nodeRushTitle:addChild(self.rushTitleNode)
        end
    end

    if self.rushTitleNode and (not actData or actData:isCompleted()) then
        self.rushTitleNode:removeFromParent()
        self.rushTitleNode = nil
    end
end

function DailyMissionMissionPageNode:getBtnRefreshWorldPos()
    local worldPos = self.m_btnRefresh:getParent():convertToWorldSpace(cc.p(self.m_btnRefresh:getPosition()))
    return worldPos
end

return DailyMissionMissionPageNode
