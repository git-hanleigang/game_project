--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-06 10:25:55
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-06 10:55:37
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/BaseSidekicksMainLayer.lua
Description: 宠物主界面
--]]
local BaseActivityMainLayer = util_require("baseActivity.BaseActivityMainLayer")
local BaseSidekicksMainLayer = class("BaseSidekicksMainLayer", BaseActivityMainLayer)
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")
local SidekicksMgr = G_GetMgr(G_REF.Sidekicks)

function BaseSidekicksMainLayer:initDatas(_seasonIdx)
    BaseSidekicksMainLayer.super.initDatas(self)

    self.m_lbNameList = {}
    self._guideHandAniUI = {}

    self._data = SidekicksMgr:getRunningData()
    self._stdCfg = self._data:getStdCfg()
    self._guideData = SidekicksMgr:getGuideData()

    self._seasonIdx = _seasonIdx
    self._curSeasonStageIdx = self._stdCfg:getCurSeasonStageIdx(self._seasonIdx)
    self._curSeasonPetInfoList = self._data:getPetInfoListBySeasonIdx(self._seasonIdx)

    local newSesaonIdx = self._data:getNewSeasonIdx()
    self._newSeasonInfo = self._stdCfg:getSeasonStageInfo(newSesaonIdx, self._curSeasonStageIdx)
    self._bNewSeasonIdx = self._seasonIdx == newSesaonIdx
    
    local csbName = string.format("Sidekicks_%s/csd/main/Sidekicks_MainLayer.csb", _seasonIdx)
    self:setPauseSlotsEnabled(true) 
    self:setShowActionEnabled(false)
    -- self:setHideLobbyEnabled(true) 
    self:setLandscapeCsbName(csbName)
    self:setBgm(string.format("Sidekicks_%s/sound/Sidekicks_bgm.mp3", _seasonIdx))
end

-- 初始化节点
function BaseSidekicksMainLayer:initCsbNodes()
    BaseSidekicksMainLayer.super.initCsbNodes(self)

    local guideFeedNode = self:findChild("node_seemore_1")
    self._guideFeedParent = guideFeedNode:getParent()
    self._guideFeedPos = cc.p(guideFeedNode:getPosition())
    
    -- self:setButtonLabelContent("btn_seemore_1", "FEED")
    -- self:setButtonLabelContent("btn_seemore_2", "FEED")
end

function BaseSidekicksMainLayer:initView()
    BaseSidekicksMainLayer.super.initView(self)

    -- 荣誉等级
    self:initHonorLvUI()
    -- 加成 汇总
    self:initAdditionalUI()
    -- 宠物信息
    self:initPetSpineUI()
    -- 宠物名字
    self:initPetName()
    -- 小游戏入口
    self:initMiniGameUI()
    -- 7日任务入口
    self:initPetMission()
    -- 倒计时
    self:initTimeUI()
    -- 手指进入详情界面引导
    self:initHandGuideUI()
    -- 刷新红点
    self:updateRedPoint()
    self:sendSidekicksOpenLog()
end

-- 弹框日志
function BaseSidekicksMainLayer:sendSidekicksOpenLog()
    -- 发送打点日志
    local entryType = "lobby"
    local curMachineData = globalData.slotRunData.machineData
    if curMachineData then
        entryType = curMachineData.p_name
    end
    if not entryType or entryType == "" then
        entryType = "lobby"
    end
    local type = "Open"
    local pageName = "SidekicksMainLayer_"..self._seasonIdx
    local logManager = gLobalSendDataManager:getSidekicks()
    if logManager then
        logManager:sendSidekicksPopupLog(type, pageName, entryType)
    end
end

-- 荣誉等级
function BaseSidekicksMainLayer:initHonorLvUI()
    local parent = self:findChild("node_honorlevel")
    local view = util_createView("GameModule.Sidekicks.views.base.main.SidekicksHonorLvView", self._seasonIdx, self)
    parent:addChild(view)
end

-- 加成 汇总
function BaseSidekicksMainLayer:initAdditionalUI()
    -- 免费金币加成
    local parent_1 = self:findChild("node_skill_1")
    self.m_skillView1 = util_createView("GameModule.Sidekicks.views.base.main.SidekicksSkillView", self._seasonIdx, 1, self)
    parent_1:addChild(self.m_skillView1)
    -- 商城金币加成
    local parent_2 = self:findChild("node_skill_2")
    self.m_skillView2 = util_createView("GameModule.Sidekicks.views.base.main.SidekicksSkillView", self._seasonIdx, 2, self)
    parent_2:addChild(self.m_skillView2)
end

-- 宠物信息
function BaseSidekicksMainLayer:initPetSpineUI()
    for i=1, 2 do
        local petInfo = self._curSeasonPetInfoList[i]
        local parent = self:findChild("node_spine_" .. i)
        if petInfo then
            local petId = petInfo:getPetId()
            local spineUI = util_createView("GameModule.Sidekicks.views.common.SidekicksSpineUI", petId, self._seasonIdx)
            spineUI:addTo(parent)
        end
        parent:setVisible(petInfo ~= nil)
    end
end

-- 宠物名字
function BaseSidekicksMainLayer:initPetName()
    for i = 1, 2 do
        local lb_name = self:findChild("lb_name" .. i)
        local petInfo = self._curSeasonPetInfoList[i]
        local name = petInfo:getName()
        lb_name:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        lb_name:setString(name)
        table.insert(self.m_lbNameList, lb_name)
    end
end

function BaseSidekicksMainLayer:refreshPetName(_params)
    local name = _params.name
    local petId = _params.petId
    local lb_name = self.m_lbNameList[petId]
    lb_name:setString(name)
end

-- 小游戏入口
function BaseSidekicksMainLayer:initMiniGameUI()
    if not self._bNewSeasonIdx then
        return
    end

    local parent = self:findChild("node_miniGame")
    local view = util_createView(string.format("Sidekicks_Season_%s.GameMain.main.SidekicksDailyGameEntry", self._seasonIdx), self._seasonIdx, self)
    view:addTo(parent)
end

-- 7日任务入口
function BaseSidekicksMainLayer:initPetMission()
    if G_GetMgr(ACTIVITY_REF.PetMission) then
        local missionData = G_GetMgr(ACTIVITY_REF.PetMission):getRunningData()
        if missionData then
            local parent = self:findChild("node_petmission")
            local view = G_GetMgr(ACTIVITY_REF.PetMission):createEntryView()
            if not tolua.isnull(view) then
                view:addTo(parent)
            end
        end
    end
end

-- 倒计时
function BaseSidekicksMainLayer:initTimeUI()
    if not self._bNewSeasonIdx then
        return
    end

    self:updateTimeUI()
    self._scheduleAct = schedule(self, util_node_handler(self, self.updateTimeUI), 1)
end
-- 倒计时
function BaseSidekicksMainLayer:updateTimeUI()
    if not self._bNewSeasonIdx then
        return
    end

    local seasonEndTime = self._newSeasonInfo:getSeasonEndTime()
    local strLeftTime, bOver = util_daysdemaining(seasonEndTime * 0.001, true)
    if bOver then
        local nodeMiniGame = self:findChild("node_miniGame")
        nodeMiniGame:setVisible(false)
        self:checkNextSeasonOpen()
        self:stopScheduleAction()
    end
end

function BaseSidekicksMainLayer:updateRedPoint()
    for k,v in pairs(self._curSeasonPetInfoList) do
        local red = self:findChild("node_reddot_" .. k)
        if red then
            red:setVisible(self:canLevelUp(v) or self:canStarUp(v))
        end
    end
end

-- 手指进入详情界面引导
function BaseSidekicksMainLayer:initHandGuideUI()
    for i=1, 2 do
        local parent = self:findChild("node_guideHand_" .. i)
        local csbName = string.format("Sidekicks_%s/csd/guide/Sidekicks_guideHand.csb", self._seasonIdx)
        local handAni = util_createAnimation(csbName)
        handAni:addTo(parent)
        handAni:playAction("idle", true)
        self._guideHandAniUI[i] = handAni
        handAni:setVisible(false)
    end
end
function BaseSidekicksMainLayer:updateHandGuideUI()
    if not self:isVisible() then
        return
    end

    local stepId = self._guideData:getMainLayerGuideStep()
    
    if stepId < 6 then
        -- 引导 小于进入  详情页引导 return 
        self:hideGuideHandAniUI()
        return
    end
    if self._guideHandAniUI[1]:isVisible() or self._guideHandAniUI[2]:isVisible() then
        return
    end

    local bEnterDetailLayer = self._guideData:checkEnterDetailLayer()
    local bVisible = false
    local guideCount = gLobalDataManager:getNumberByField("ShowEnterDeailHandGuideCount" , 0)
    local bGuideCount = guideCount <= 3
    for i=1,2 do
        -- 未进入过 详情页
        self._guideHandAniUI[i]:setVisible(not bVisible and not bEnterDetailLayer)
        if bEnterDetailLayer and bGuideCount and not self._guideHandAniUI[i]:isVisible() then
            -- 进入过详情页，次数小于3次 加手指，  可升级升星
            local bCanFeed = self:findChild("node_reddot_" .. i):isVisible()
            self._guideHandAniUI[i]:setVisible(not bVisible and bCanFeed)
        end
        bVisible = self._guideHandAniUI[i]:isVisible()
    end
    if self._guideHandAniUI[1]:isVisible() or self._guideHandAniUI[2]:isVisible() then
        gLobalDataManager:setNumberByField("ShowEnterDeailHandGuideCount" , guideCount + 1)
    end
end
function BaseSidekicksMainLayer:hideGuideHandAniUI()
    self._guideHandAniUI[1]:setVisible(false)
    self._guideHandAniUI[2]:setVisible(false)
end

function BaseSidekicksMainLayer:canLevelUp(_petInfo)
    local bCanLevelUp = _petInfo:checkCanLevelUp()

    local level = _petInfo:getLevel()
    local levelMax = _petInfo:getLevelMax()
    local stage = _petInfo:getCurLevelAndStarStage()
    local levelCount = self._data:getLvUpItemCount()

    if level >= levelMax or levelCount <= 0 or stage > self._curSeasonStageIdx then
        bCanLevelUp = false
    end

    return bCanLevelUp
end

function BaseSidekicksMainLayer:canStarUp(_petInfo)
    local bCanStarUp = _petInfo:checkCanStarUp()

    local Star = _petInfo:getStar()
    local StarMax = _petInfo:getStarMax()
    local stage = _petInfo:getCurLevelAndStarStage()
    local nextStarExp = _petInfo:getStarUpNeedExp()
    local starCount = self._data:getStarUpItemCount()

    if Star >= StarMax or starCount < nextStarExp or stage > self._curSeasonStageIdx then
        bCanStarUp = false
    end

    return bCanStarUp
end

function BaseSidekicksMainLayer:stopScheduleAction()
    if self._scheduleAct then
        self:stopAction(self._scheduleAct)
        self._scheduleAct = nil
    end
end

-- 关闭技能加成气泡
function BaseSidekicksMainLayer:closeSkillbubble()
    self.m_skillView1:closebubble()
    self.m_skillView2:closebubble()
end

function BaseSidekicksMainLayer:onClickMask()
    self:closeSkillbubble()
end

function BaseSidekicksMainLayer:clickFunc(_sender)
    local name = _sender:getName()
    
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
        self:closeSkillbubble()
        self:popInfoLayer()
    elseif name == "btn_seemore_1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK) 
        self:closeSkillbubble()
        self:popDeailLayer(1)
    elseif name == "btn_seemore_2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK) 
        self:closeSkillbubble()
        self:popDeailLayer(2)
    elseif name == "btn_petName1" then
        self:showPetNameLayer(1)
    elseif name == "btn_petName2" then
        self:showPetNameLayer(2)
    end
end

-- 显示 命名弹板
function BaseSidekicksMainLayer:showPetNameLayer(_idx)
    self:closeSkillbubble()

    self._curSeasonPetInfoList = self._data:getPetInfoListBySeasonIdx(self._seasonIdx)
    local petInfo = self._curSeasonPetInfoList[_idx]
    SidekicksMgr:showSetNameLayer(self._seasonIdx, petInfo)
end

-- 显示本赛季说明弹板
function BaseSidekicksMainLayer:popInfoLayer()
    G_GetMgr(G_REF.Sidekicks):showRuleLayer(self._seasonIdx)
end

-- 显示 本赛季 某宠物
function BaseSidekicksMainLayer:popDeailLayer(_idx)
    local petInfo = self._curSeasonPetInfoList[_idx]
    if not petInfo then
        return
    end

    self:dealGuideLogic()
    self:hideGuideHandAniUI()

    local seasonIdx = self._seasonIdx
    local petId = petInfo:getPetId()
    local func = function ()
        SidekicksMgr:showPetDeailLayer(seasonIdx, petId)
    end

    SidekicksMgr:showInterludeLayer(seasonIdx, func, 1)

    -- local view = SidekicksMgr:showPetDeailLayer(self._seasonIdx, petInfo:getPetId())
    -- return view
end

-- 宠物详情界面打开完毕
function BaseSidekicksMainLayer:onDetaiLLayerOpenOEvt()
    self:setVisible(false)
end

-- 宠物详情界面开始关闭
function BaseSidekicksMainLayer:onDetaiLLayerCloseSEvt(_closeType)
    if _closeType == "back" then
        self:setVisible(true)
        self:updateRedPoint()

        self:hideGuideHandAniUI()
        performWithDelay(self, function()
            -- 界面等待5秒后 检查可喂养宠物加 进入宠物详情手指引导
            self:updateHandGuideUI()
        end,5)
    else
        self:closeUI()
    end
end

-- 宠物数据更新
function BaseSidekicksMainLayer:onUpdatePetDataEvt()
    self._curSeasonPetInfoList = self._data:getPetInfoListBySeasonIdx(self._seasonIdx)
    self:updateRedPoint()
    performWithDelay(self, function()
        self:updateHandGuideUI()
    end, 5)
end

-- 注册事件
function BaseSidekicksMainLayer:registerListener()
    BaseSidekicksMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onDetaiLLayerOpenOEvt", SidekicksConfig.EVENT_NAME.NOTICE_SIDEKICKS_DETAIL_LAYER_OPEN_OVER) -- 宠物详情界面打开完毕
    gLobalNoticManager:addObserver(self, "onDetaiLLayerCloseSEvt", SidekicksConfig.EVENT_NAME.NOTICE_SIDEKICKS_DETAIL_LAYER_CLOSE_START) -- 宠物详情界面开始关闭
    gLobalNoticManager:addObserver(self, "refreshPetName", SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_PET_SET_NAME) -- 宠物改名
    gLobalNoticManager:addObserver(self, "onUpdatePetDataEvt", SidekicksConfig.EVENT_NAME.NOTICE_UPDATE_SIDEKICKS_DATE) -- 宠物数据更新
end

function BaseSidekicksMainLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function BaseSidekicksMainLayer:checkNextSeasonOpen()
    local preSeasonIdx = self._newSeasonInfo:getSeasonIdx()
    local curSeasonIdx = self._stdCfg:getNewSeasonIdx(true)
    if curSeasonIdx > preSeasonIdx then
        SidekicksMgr:downloadSeasonRes(curSeasonIdx)
    end
end

function BaseSidekicksMainLayer:onEnter()
    BaseSidekicksMainLayer.super.onEnter(self)

    local node_main = self:findChild("node_main")
    node_main:setVisible(false)

    SidekicksMgr:showInterludeLayer(self._seasonIdx, nil, 2)

    performWithDelay(node_main, function ()
        node_main:setVisible(true)
        performWithDelay(self, function()
            self:dealGuideLogic()
        end,1.7)
        
        performWithDelay(self, function()
            -- 界面等待5秒后 检查可喂养宠物加 进入宠物详情手指引导
            self:updateHandGuideUI()
        end,5)

        -- 隐藏大厅背景
        self:setHideLobbyEnabled(true) 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_SHOW_VISIBLED, {isHideLobby = true})
    end, 20/60)
end

function BaseSidekicksMainLayer:dealGuideLogic(_stepId)
    local stepId = self._guideData:getMainLayerGuideStep()
    if _stepId then
        stepId = _stepId
    end
    local stepInfo = self._guideData:getStepInfo("MainLayer", stepId)
    if stepInfo and stepInfo.hightNodeInfo and stepInfo.hightNodeInfo[2] then
        self[stepInfo.hightNodeInfo[2]](self)
    end
    if not stepInfo or not stepInfo.nextStepId then
        SidekicksMgr:checkCloseGuideLayer(self._seasonIdx, "MainLayer")
        self:hideGuideHandAniUI()
        return
    end
    local nextStepInfo = self._guideData:getStepInfo("MainLayer", stepInfo.nextStepId)
    if not nextStepInfo then
        SidekicksMgr:checkCloseGuideLayer(self._seasonIdx, "MainLayer")
        self:hideGuideHandAniUI()
        return
    end

    SidekicksMgr:showGuideLayer(self._seasonIdx, "MainLayer", nextStepInfo, self._curSeasonPetInfoList)
end

function BaseSidekicksMainLayer:getFeedBtnNode()
    return self:findChild("node_seemore_1")
end
function BaseSidekicksMainLayer:resetFeedBtnNode()
    local node = self:findChild("node_seemore_1")
    if node:getParent() == self._guideFeedParent then
        return
    end

    util_changeNodeParent(self._guideFeedParent, node)
    node:move(self._guideFeedPos)
end

return BaseSidekicksMainLayer