--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-08 10:56:58
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-08 15:58:08
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/BaseSidekicksDetailLayer.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local BaseActivityMainLayer = util_require("baseActivity.BaseActivityMainLayer")
local BaseSidekicksDetailLayer = class("BaseSidekicksDetailLayer", BaseActivityMainLayer)
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")

function BaseSidekicksDetailLayer:initDatas(_seasonIdx, _petId)
    BaseSidekicksDetailLayer.super.initDatas(self)
    self._data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    self._stdCfg = self._data:getStdCfg()
    self._guideData = G_GetMgr(G_REF.Sidekicks):getGuideData()

    self._seasonIdx = _seasonIdx
    self._curSeasonStageIdx = self._stdCfg:getCurSeasonStageIdx(self._seasonIdx)
    self._curSeasonPetInfoList = self._data:getPetInfoListBySeasonIdx(self._seasonIdx)
    self._showIdx = 1
    if self._curSeasonPetInfoList[2] and self._curSeasonPetInfoList[2]:getPetId() == _petId then
        self._showIdx = 2
    end
    self._petSpinViewList = {}

    local honorLv = self._data:getHonorLv()
    G_GetMgr(G_REF.Sidekicks):setLastHonorLv(honorLv)

    self:setPauseSlotsEnabled(true) 
    self:setHideLobbyEnabled(true) 
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    local csbName = string.format("Sidekicks_%s/csd/message/Sidekicks_MessageLayer.csb", _seasonIdx)
    self:setLandscapeCsbName(csbName)
    self:addClickSound({"btn_back"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function BaseSidekicksDetailLayer:initCsbNodes()
    self.m_btn_left = self:findChild("btn_left")
    self.m_btn_right = self:findChild("btn_right")
    self.m_particle = self:findChild("Particle_3")
    self.m_particlePos = cc.p(self.m_particle:getPosition())
    self.m_particle:setVisible(false)
end

function BaseSidekicksDetailLayer:onShowedCallFunc()
    BaseSidekicksDetailLayer.super.onShowedCallFunc(self)
    self:runCsbAction("idle", true)

    self:dealGuideLogic()
    
    -- 个人信息页 打开关闭界面
    local preLayer = gLobalViewManager:getViewByName("UserInfoMainLayer")
    if preLayer then
        preLayer:closeUI()
    end
    gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTICE_SIDEKICKS_DETAIL_LAYER_OPEN_OVER) -- 宠物详情界面打开完毕
end

function BaseSidekicksDetailLayer:initView()
    BaseSidekicksDetailLayer.super.initView(self)

    -- 升级道具数量
    self:initLvUpPropCountUI()

    self:updateUI()
end

function BaseSidekicksDetailLayer:updateUI(_bChangePet, _bStarUp)
    local petInfo = self._curSeasonPetInfoList[self._showIdx]
    self._petInfo = petInfo
    self._petCfg, self._petNextCfg = self._petInfo:getSkillCfg()

    -- 宠物Spine
    self:updateSpineUI(_bChangePet)
    -- 宠物名字
    -- self:updatePetNameUI()
    -- 加成 技能(升星时延时刷新)
    if not _bStarUp then
        self:updatePetAddSkillUI()
    end
    -- 切换时随动效延时刷新
    if not _bChangePet then
        -- 宠物等级信息
        self:updatePetLevelUI()
        -- 宠物星级信息
        self:updatePetStarUI()
    end
    -- 隐藏翻页按钮    
    self:hideChangeBtn()
    -- 刷新动效
    self:updateAct(_bChangePet)
end

-- 升级道具数量
function BaseSidekicksDetailLayer:initLvUpPropCountUI()
    local parent = self:findChild("node_item_left")
    local lvItemUI = parent:getChildByName("SidekicksLvUpItemCountUI")
    if lvItemUI then
        return
    end

    lvItemUI =  util_createView("GameModule.Sidekicks.views.common.SidekicksLvUpItemCountUI", self._seasonIdx, self)
    lvItemUI:setName("SidekicksLvUpItemCountUI")
    lvItemUI:addTo(parent)
    self._lvItemView = lvItemUI
end

-- 宠物Spine
function BaseSidekicksDetailLayer:updateSpineUI(_bChangePet)
    local parent = self:findChild("node_spine_" .. self._showIdx)
    if not parent then
        return
    end

    local spineUI = parent:getChildByName("SpineUIView")
    if not spineUI then
        local petId = self._petInfo:getPetId()
        spineUI = util_createView("GameModule.Sidekicks.views.common.SidekicksSpineUI", petId, self._seasonIdx)
        spineUI:setName("SpineUIView")
        spineUI:addTo(parent)
    end
    parent:setVisible(true)
    local preParent = self:findChild("node_spine_" .. (self._showIdx == 1 and 2 or 1))
    if preParent then
        preParent:setVisible(false)
    end

    if _bChangePet then
        spineUI:playTouch()
    end
    self._petSpinViewList[self._showIdx] = spineUI
end

-- 宠物名字
function BaseSidekicksDetailLayer:updatePetNameUI()
    local parent = self:findChild("node_name")
    local petNameUI = parent:getChildByName("SidekicksNameView")
    if not petNameUI then
        petNameUI = util_createView("GameModule.Sidekicks.views.base.message.SidekicksNameView", self._seasonIdx, self._petInfo)
        petNameUI:setName("SidekicksNameView")
        petNameUI:addTo(parent)
    end
    petNameUI:updateUI(self._petInfo)
end

-- 加成 技能
function BaseSidekicksDetailLayer:updatePetAddSkillUI(_bPlayUpAct)
    for i = 1, 3 do
        local nodeSkill = self:findChild("node_skill_" .. i)
        local skillView = nodeSkill:getChildByName("SidekicksSkillMessageView")
        if not skillView then
            skillView = util_createView("GameModule.Sidekicks.views.base.message.SidekicksSkillMessageView", self._seasonIdx, i)
            skillView:setName("SidekicksSkillMessageView")
            skillView:addTo(nodeSkill)
        end
        skillView:updateUI(self._petInfo, self._curSeasonStageIdx, _bPlayUpAct)
    end
end

-- 宠物等级信息
function BaseSidekicksDetailLayer:updatePetLevelUI()
    local parent = self:findChild("node_level")
    local petLvInfoUI = parent:getChildByName("SidekicksLevelDetailView")
    if not petLvInfoUI then
        petLvInfoUI = util_createView("GameModule.Sidekicks.views.base.message.SidekicksLevelDetailView", self._seasonIdx, self._stdCfg, self._curSeasonStageIdx, self)
        petLvInfoUI:setName("SidekicksLevelDetailView")
        petLvInfoUI:addTo(parent)
    end
    petLvInfoUI:updateUI(self._petInfo)
    self._curPetLvInfoView = petLvInfoUI
end
function BaseSidekicksDetailLayer:getLevelUpBtnNode()
    return self._curPetLvInfoView:getLevelUpBtnNode()
end
function BaseSidekicksDetailLayer:resetLevelUpBtnNode()
    return self._curPetLvInfoView:resetLevelUpBtnNode()
end

-- 宠物星级信息
function BaseSidekicksDetailLayer:updatePetStarUI()
    local parent = self:findChild("node_star")
    local petStarInfoUI = parent:getChildByName("SidekicksStarDetailView")
    if not petStarInfoUI then
        petStarInfoUI = util_createView("GameModule.Sidekicks.views.base.message.SidekicksStarDetailView", self._seasonIdx, self._stdCfg, self._curSeasonStageIdx, self)
        petStarInfoUI:setName("SidekicksStarDetailView")
        petStarInfoUI:addTo(parent)
    end
    petStarInfoUI:updateUI(self._petInfo)
    self._curPetStarInfoView = petStarInfoUI
end
function BaseSidekicksDetailLayer:getStarUpBtnNode()
    return self._curPetStarInfoView:getStarUpBtnNode()
end
function BaseSidekicksDetailLayer:resetStarUpBtnNode()
    return self._curPetStarInfoView:resetStarUpBtnNode()
end

function BaseSidekicksDetailLayer:clickFunc(_sender)
    local name = _sender:getName()
    
    if name == "btn_back" then
        local func = function ()
            self._closeType = "back"
            self:closeUI()
        end
        
        G_GetMgr(G_REF.Sidekicks):showInterludeLayer(self._seasonIdx, func, 1)
    elseif name == "btn_close" then
        self._closeType = "close"
        self:closeUI()
    elseif name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:switchPetInfo(-1)
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:switchPetInfo(1)
    elseif name == "btn_skill_info" then
        self:popInfoLayer()
    end
end

-- 切换 宠物信息
function BaseSidekicksDetailLayer:switchPetInfo(_offset)
    if not _offset then
        return
    end

    local idx = self._showIdx + _offset
    self._showIdx = idx
    
    if self._petChangeSound then
        gLobalSoundManager:stopAudio(self._petChangeSound)
        self._petChangeSound = nil
    end
    local sound = string.format("Sidekicks_%s/sound/Sidekicks_petChange.mp3", self._seasonIdx)
    self._petChangeSound = gLobalSoundManager:playSound(sound)
    
    self:updateUI(true)
end

function BaseSidekicksDetailLayer:hideChangeBtn()
    self.m_btn_left:setVisible(self._showIdx > 1)
    self.m_btn_right:setVisible(self._showIdx < #self._curSeasonPetInfoList)
end

-- 刷新动效 切换宠物动效
function BaseSidekicksDetailLayer:updateAct(_bChangePet)
    if not _bChangePet then
        return
    end

    self.m_particle:stopAllActions()
    self.m_particle:setVisible(true)
    self.m_particle:setPosition(self.m_particlePos)
    self.m_particle:setPositionType(0)
    self.m_particle:resetSystem()
    local offsetY = SidekicksConfig.PET_CHANGE_ACT_OFFSET_Y[self._seasonIdx]
    local move = cc.MoveBy:create(1, cc.p(0, offsetY))
    local callfun = cc.CallFunc:create(function ()
        self.m_particle:stopSystem()
    end)
    self.m_particle:runAction(cc.Sequence:create(move, callfun))

    performWithDelay(self.m_btn_left, function ()
        -- 宠物星级信息
        self:updatePetStarUI()
    end, 0.4)
    
    performWithDelay(self.m_btn_right, function ()
        -- 宠物等级信息
        self:updatePetLevelUI()
    end, 0.8)
end

-- 显示本赛季说明弹板
function BaseSidekicksDetailLayer:popInfoLayer()
    G_GetMgr(G_REF.Sidekicks):showRuleLayer(self._seasonIdx)
end

-- 显示 宠物突破升级弹板
function BaseSidekicksDetailLayer:showPetStartUpLayer(_petId)
    if gLobalViewManager:getViewByName("SidekicksStarUpDetailLayer") then
        return
    end
    if self._petInfo:getPetId() ~= _petId then
        return
    end

    local view = util_createView("GameModule.Sidekicks.views.base.message.SidekicksStarUpDetailLayer", self._seasonIdx)
    if view then
        view:setName("SidekicksStarUpDetailLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    view:updateUI(self._petInfo)
    return view
end

function BaseSidekicksDetailLayer:getLvUpActing()
    return self._bLvUpActing
end

-- 宠物升级
function BaseSidekicksDetailLayer:onFeedPetNetCallbackEvt(_params)
    gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HIDE_CUR_STEP_GUIDE)

    self._data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    self._curSeasonPetInfoList = self._data:getPetInfoListBySeasonIdx(self._seasonIdx)
    self._petInfo = self._curSeasonPetInfoList[self._showIdx]
    self._petCfg, self._petNextCfg = self._petInfo:getSkillCfg()

    -- 1、升级流程：
    -- ①玩家点击FEED时，从右上角道具icon位置生成n个道具图标，飞到进度条处（飞行特效动效制作，路线程序控制）
    -- ②进度条上涨，需要上涨过程
    -- ③宠物SPINE新增一条升级时间线，进度条涨满后，播放此时间线动画
    -- ④同时cocos中，舞台播放升级反馈动画；对应的技能播放升级效果
    -- 2、此流程中，屏蔽除关闭按钮和返回按钮外的其他交互响应
    self._bLvUpActing = true
    local actionList = {}
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        self:playLvUpFLyItemAct()
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(45/60)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        self._curPetLvInfoView:playStart()
        self._curPetLvInfoView:playFeedOkAct(self._petInfo)
    end)
    if _params and _params.petLevelUp then
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self._petSpinViewList[self._showIdx]:playFeedOkAct()
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(1)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self:playLvUpSpineEfAct()
            self:updatePetAddSkillUI(true)
        end)
    end
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        self._bLvUpActing = false
        self:updateUI(false, false)

        -- 监测荣誉等级是否升级
        G_GetMgr(G_REF.Sidekicks):showRankLevelUp(self._seasonIdx)
        local honorLv = self._data:getHonorLv()
        G_GetMgr(G_REF.Sidekicks):setLastHonorLv(honorLv)

        self:dealGuideLogic()
    end)
    self:runAction(cc.Sequence:create(actionList))

    -- petLevelUp:
    -- sidekicksLevelUp:
end
function BaseSidekicksDetailLayer:playLvUpFLyItemAct()
    local posSW = self._lvItemView:getLvUpActPosW()
    local posEW = self._curPetLvInfoView:getLvUpActPosW()
    local view = util_createView("GameModule.Sidekicks.views.base.message.SidekicksItemFlyEf", self._seasonIdx)
    view:addTo(self)
    view:playFlyToLevelAct(posSW, posEW)
end
-- 宠物升级动效
function BaseSidekicksDetailLayer:playLvUpSpineEfAct()
    local parent = self:findChild("node_shengji")
    local efView = parent:getChildByName("LvUpSpineEfActView")
    if not efView then
        efView = util_createView("GameModule.Sidekicks.views.base.message.SidekicksSpineLvUpEf", self._seasonIdx)
        efView:setName("LvUpSpineEfActView")
        efView:addTo(parent)
    end
    efView:playSpineLvUpEfAct()
end

-- 宠物升星 突破
function BaseSidekicksDetailLayer:onStarUpPetNetCallbackEvt(_params)
    gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HIDE_CUR_STEP_GUIDE)

    local startUpLayer
    if _params and _params.petStarUp and _params.petId then
        startUpLayer = self:showPetStartUpLayer(_params.petId)
    end

    self._data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    self._curSeasonPetInfoList = self._data:getPetInfoListBySeasonIdx(self._seasonIdx)
    if startUpLayer then
        self:updateUI(false, true)
    else
        self:updateUI(false, false)
        self:dealGuideLogic()
    end
end

function BaseSidekicksDetailLayer:onHonorSaleCallbackEvt(_params)
    self:updateUI(false, false)
end

function BaseSidekicksDetailLayer:onStarUpRewardCallbackEvt()
    self:updatePetAddSkillUI(true)
    self:dealGuideLogic()
end

-- 注册事件
function BaseSidekicksDetailLayer:registerListener()
    BaseSidekicksDetailLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onFeedPetNetCallbackEvt", SidekicksConfig.EVENT_NAME.NOTICE_FEED_PET_NET_CALL_BACK) -- 投喂宠物升级
    gLobalNoticManager:addObserver(self, "onStarUpPetNetCallbackEvt", SidekicksConfig.EVENT_NAME.NOTICE_STAR_UP_PET_NET_CALL_BACK) -- 宠物升星突破
    gLobalNoticManager:addObserver(self, "onHonorSaleCallbackEvt", SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HONOR_SALE) -- 荣誉促销购买
    gLobalNoticManager:addObserver(self, "onHonorSaleCallbackEvt", ViewEventType.NOTIFY_BUYCOINS_SUCCESS) -- 商城购买
    gLobalNoticManager:addObserver(self, "onStarUpRewardCallbackEvt", SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_STAR_UP_REWARD_CLOSE) -- 升星奖励
end

function BaseSidekicksDetailLayer:closeUI(_cb)
    gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTICE_SIDEKICKS_DETAIL_LAYER_CLOSE_START, self._closeType) -- 宠物详情界面开始关闭 
    
    BaseSidekicksDetailLayer.super.closeUI(self, _cb)
end

function BaseSidekicksDetailLayer:dealGuideLogic(_stepId)
    local stepId = self._guideData:getDetailLayerGuideStep()
    if _stepId then
        stepId = _stepId
    end
    local stepInfo = self._guideData:getStepInfo("DetailLayer", stepId)
    if stepInfo and stepInfo.hightNodeInfo and stepInfo.hightNodeInfo[2] then
        self[stepInfo.hightNodeInfo[2]](self)
    end
    if not stepInfo or not stepInfo.nextStepId then
        G_GetMgr(G_REF.Sidekicks):checkCloseGuideLayer(self._seasonIdx, "DetailLayer")
        return
    end
    
    local nextStepInfo = self._guideData:getStepInfo("DetailLayer", stepInfo.nextStepId)
    if not nextStepInfo then
        G_GetMgr(G_REF.Sidekicks):checkCloseGuideLayer(self._seasonIdx, "DetailLayer")
        return
    end

    G_GetMgr(G_REF.Sidekicks):showGuideLayer(self._seasonIdx, "DetailLayer", nextStepInfo, self._showIdx)
end

return BaseSidekicksDetailLayer