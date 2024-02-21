--[[
    --新版每日任务主界面  左侧节点界面
]]
local DailyMissionMainLeftNodeView = class("DailyMissionMainLeftNodeView", BaseView)

local PAGE_TYPE = {
    MISSION_PAGE = 1,
    REWARD_PAGE = 2,
    FLOWER_PAGE = 3
}

function DailyMissionMainLeftNodeView:initDatas(data)
    self.m_isPortrait = data.isPortrait
    self.m_chanegFun = data.chanegFun
    self.m_currPageType = data.currPageType
end

function DailyMissionMainLeftNodeView:initUI()
    self:createCsbNode(self:getCsbName())

    self:initCsbNodes()

    self:updateView()
end

function DailyMissionMainLeftNodeView:getCsbName()
    if self.m_isPortrait then
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_TitleNode_Vertical.csb"
    else
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_TitleNode.csb"
    end
end

function DailyMissionMainLeftNodeView:initCsbNodes()
    self.m_node_pass = self:findChild("node_Pass")
    self.m_node_passTime = self:findChild("node_passTime")
    self.m_lb_passTime = self:findChild("lb_passTime")

    self.m_btnMission = self:findChild("btn_mission")
    self.m_btnReward = self:findChild("btn_reward")
    self.m_btnFlower = self:findChild("btn_flower")

    -- panel 触摸按钮
    self:addClick(self.m_btnMission)
    self:addClick(self.m_btnReward)
    self:addClick(self.m_btnFlower)

    self.m_spMissionPageUp = self:findChild("sp_missionPageUp")
    self.m_spRewardPageUp = self:findChild("sp_rewardPageUp")
    self.m_spFlowerPageUp = self:findChild("sp_flowerPageUp")

    self.m_spMissionPageDown = self:findChild("sp_missionPageDown")
    self.m_spRewardPageDown = self:findChild("sp_rewardPageDown")
    self.m_spFlowerPageDown = self:findChild("sp_flowerPageDown")
    
    self.m_sp_rewardRedPoint = self:findChild("sp_rewardRedPoint")
    self.m_lb_rewardRedNum = self:findChild("lb_rewardRedNum")

    self.m_sp_flowerRedPoint = self:findChild("sp_flowerRedPoint")
    self.m_lb_flowerRedNum = self:findChild("lb_flowerRedNum")
    self.m_lb_flowerRedNum:setString("1")
end

function DailyMissionMainLeftNodeView:updateView()
    self:runCsbAction("idle", true, nil, 60)
    self:checkTimer()
    self:initBGAndSpineNode()
    self:updateBtnSp()
    self:initRedPointNum()
end

function DailyMissionMainLeftNodeView:initBGAndSpineNode()
    local passTitleNode = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_Title,self.m_isPortrait)
    self.m_node_pass:addChild(passTitleNode)
    self.m_passTitleNode = passTitleNode 
end

function DailyMissionMainLeftNodeView:updateLeftTimeUI()
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passActData then
        self.m_node_passTime:setVisible(true)
        local expireAt = passActData:getExpireAt()
        local leftTime = math.max(expireAt, 0)
        local timeStr, isOver ,isFullDay = util_daysdemaining(leftTime,true)
        self.m_lb_passTime:setString(timeStr)
    else
        self.m_node_passTime:setVisible(false)
    end
end

function DailyMissionMainLeftNodeView:checkTimer()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
    end
    self.activityAction =
        util_schedule(
        self,
        function()
            self:updateLeftTimeUI()
        end,
        1
    )
    self:updateLeftTimeUI()
end

function DailyMissionMainLeftNodeView:clickFunc(_sender)
    if self.m_inAction then
        return
    end
    if self.m_isScrollingToSafeBoxGuide then
        return
    end
    local name = _sender:getName()

    if name == "btn_mission" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if G_GetMgr(G_REF.Flower) then
            if G_GetMgr(G_REF.Flower):getWaterHide() == nil then
            elseif not G_GetMgr(G_REF.Flower):getWaterHide() then
                return
            end
        end
        self.m_currPageType = PAGE_TYPE.MISSION_PAGE
        self.m_chanegFun(PAGE_TYPE.MISSION_PAGE) 
        self:updateBtnSp()
    elseif name == "btn_reward" or name == "btn_guideTouch" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if G_GetMgr(G_REF.Flower) then
            if G_GetMgr(G_REF.Flower):getWaterHide() == nil then
            elseif not G_GetMgr(G_REF.Flower):getWaterHide() then
                return
            end
        end
        self.m_currPageType = PAGE_TYPE.REWARD_PAGE
        self.m_chanegFun(PAGE_TYPE.REWARD_PAGE, name == "btn_reward")
        self:updateBtnSp()

        if  self:hasPassGuide() then
            gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_NEXT_GUIDE, {nextStep = true})
        end

    elseif name == "btn_flower" then
        if gLobalDailyTaskManager:isWillUseNovicePass() then
            return
        end

        if not G_GetMgr(G_REF.Flower):isDownloadRes(G_REF.Flower) then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_currPageType = PAGE_TYPE.FLOWER_PAGE
        self.m_chanegFun(PAGE_TYPE.FLOWER_PAGE)
        self:updateBtnSp()
        gLobalNoticManager:postNotification(G_GetMgr(G_REF.Flower):getConfig().EVENT_NAME.NOTIFY_FLOWER_GUIDE)
        self:updateRedPointNum(true)
    end
end

function DailyMissionMainLeftNodeView:updateBtnSp(currPageType)
    if currPageType then
        if self.m_currPageType == currPageType then
            return
        end
        self.m_currPageType = currPageType
    end
    self.m_spMissionPageUp:setVisible(self.m_currPageType == PAGE_TYPE.MISSION_PAGE)
    self.m_spMissionPageDown:setVisible(self.m_currPageType ~= PAGE_TYPE.MISSION_PAGE)

    self.m_spFlowerPageUp:setVisible(self.m_currPageType == PAGE_TYPE.FLOWER_PAGE and self:isFlowerOpen())
    self.m_spFlowerPageDown:setVisible(self.m_currPageType ~= PAGE_TYPE.FLOWER_PAGE and self:isFlowerOpen())

    self.m_spRewardPageUp:setVisible(self.m_currPageType == PAGE_TYPE.REWARD_PAGE)
    self.m_spRewardPageDown:setVisible(self.m_currPageType ~= PAGE_TYPE.REWARD_PAGE)
    
end

function DailyMissionMainLeftNodeView:initRedPointNum()
    local ct = G_GetMgr(G_REF.Flower):getFlowerData()
    self.m_sp_flowerRedPoint:setVisible(ct == 1)

    -- 显示可领奖励数
    local canClaimNum = G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum()
    if canClaimNum > 0 then
        self.m_sp_rewardRedPoint:setVisible(true)
        self.m_lb_rewardRedNum:setString(canClaimNum)
        if canClaimNum > 99 then
            self.m_lb_rewardRedNum:setScale(0.7)
        else
            self.m_lb_rewardRedNum:setScale(0.9)
        end
    else
        self.m_sp_rewardRedPoint:setVisible(false)
    end
end

function DailyMissionMainLeftNodeView:updateRedPointNum(onlyForFlower)
    self.m_sp_flowerRedPoint:setVisible(false)
    gLobalDataManager:setNumberByField("flower_red", 2)
    if G_GetMgr(G_REF.Flower):getData() and G_GetMgr(G_REF.Flower):getData():getIsWateringDay() then
        if gLobalDataManager:getNumberByField("flower_red1", 1) == 1 then
            gLobalDataManager:setNumberByField("flower_red1", 2)
            local time = globalData.userRunData.p_serverTime
            gLobalDataManager:setStringByField("flower_time", tostring(time))
        end
        if G_GetMgr(G_REF.Flower):getFlowerSpot() > 0 then
            self.m_sp_flowerRedPoint:setVisible(true)
        end
    end
    if onlyForFlower then
        return
    end
    
    -- 显示可领奖励数
    local canClaimNum = G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum()
    if canClaimNum > 0 then
        self.m_sp_rewardRedPoint:setVisible(true)
        self.m_lb_rewardRedNum:setString(canClaimNum)
        if canClaimNum > 99 then
            self.m_lb_rewardRedNum:setScale(0.7)
        else
            self.m_lb_rewardRedNum:setScale(0.9)
        end
    else
        self.m_sp_rewardRedPoint:setVisible(false)
    end

end

function DailyMissionMainLeftNodeView:isFlowerOpen()
    if not G_GetMgr(G_REF.Flower) then
        return false
    end
    local data = G_GetMgr(G_REF.Flower):getData()
    return data and data:getOpen()
end

function DailyMissionMainLeftNodeView:afterPassOver()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
    end
    self.m_node_passTime:setVisible(false)
end

function DailyMissionMainLeftNodeView:reloadBaseBGAndSpineNode()
    -- body
end

function DailyMissionMainLeftNodeView:getPassBtnPos()
    return self.m_spRewardPageDown:getPosition()
end

function DailyMissionMainLeftNodeView:getFlowerBtnPos()
    return self.m_spFlowerPageDown:getPosition()
end

function DailyMissionMainLeftNodeView:getPassBtn()
    return self.m_btnReward
end

-- 提取Pass引导判断方法
function DailyMissionMainLeftNodeView:hasPassGuide()
    if not G_GetMgr(ACTIVITY_REF.NewPass):getSeasonActivityOpen() then
        return false
    end
    -- if not self.m_hasInitPassData then
    --     return false
    -- end
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData:getGuideIndex() == -1 then
        return false
    end
    return true
end

return DailyMissionMainLeftNodeView
