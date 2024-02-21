----
local QuestNewTaskDoneTipLayer = class("QuestNewTaskDoneTipLayer", BaseLayer)

function QuestNewTaskDoneTipLayer:ctor()
    QuestNewTaskDoneTipLayer.super.ctor(self)
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewTaskDoneTipLayer)
    self:setPortraitCsbName(QUESTNEW_RES_PATH.QuestNewTaskDoneTipLayer_Shu)
    self:setPauseSlotsEnabled(true)
    self:setHasGuide(true)
    self:setExtendData("QuestNewTaskDoneLayer")
end

function QuestNewTaskDoneTipLayer:initDatas(data)
    self.m_type = data.type 
    self.m_pointData = G_GetMgr(ACTIVITY_REF.QuestNew):getEnterGamePointData()
    self.m_pointNextData = G_GetMgr(ACTIVITY_REF.QuestNew):getEnterGamePointNextData()
end

function QuestNewTaskDoneTipLayer:initCsbNodes()
    self.m_lb_jindu = self:findChild("lb_jindu")
    self.m_bar_jindu = self:findChild("bar_jindu")
    
    self.m_node_slot = self:findChild("node_slot")
    self.m_nodelizi = self:findChild("node_lizi")
    
    self.m_node_tanban1 = self:findChild("node_unlocked")
    self.m_node_tanban2 = self:findChild("node_completed")
end


function QuestNewTaskDoneTipLayer:initView()

    self.m_node_tanban1:setVisible(self.m_type == 1)
    self.m_node_tanban2:setVisible(self.m_type == 2)
    self:updateQuestIcon()
    if self.m_type == 1 then
        local rate,points ,maxPoints = self.m_pointData:getStarRate()
        self.m_lb_jindu:setString("" .. points .. "/" .. maxPoints)
        self.m_bar_jindu:setPercent(rate)
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_SlotUnlock)
    else
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_SlotCompleted)
    end
end

function QuestNewTaskDoneTipLayer:updateQuestIcon()
    --关卡头像
    local pathForce = nil
    local levelName = globalData.slotRunData:getLevelName(self.m_pointData.p_gameId)
    if self.m_type == 1 then
        if self.m_pointNextData.isWheel then
            pathForce = "QuestFantasyRes/ui_wheel/QuestNew_wheel_Icon.png" 
        else
            levelName = globalData.slotRunData:getLevelName(self.m_pointNextData.p_gameId)
        end
    end
    if levelName then
        local level_icon = self:showSprite(levelName,pathForce)
        if level_icon then
            level_icon:setName("level_icon")
            self.m_node_slot:removeChildByName("level_icon")
            self.m_node_slot:addChild(level_icon)
            self.m_sp_cell = level_icon
            if not pathForce then
                self.m_sp_cell:setScale(0.75) -- 设置的固定值 之前是66% 正常的关卡图标放在这里会偏大
            end
        end
    end
end

function QuestNewTaskDoneTipLayer:showSprite(levelName,pathForce)
    local p_sprite = nil
    local path  = pathForce
    if not pathForce then
        path = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.UNLOCK)
    end
    if util_IsFileExist(path) then
        p_sprite = util_createSprite(path)
    else
        
    end
    return p_sprite
end

function QuestNewTaskDoneTipLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_keep"  then
        if self.m_bTouch then
            return
        end
        self.m_bTouch = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        if self.m_nodelizi then
            self.m_nodelizi:setVisible(false)
        end
        self:closeUI()
    elseif  name == "btn_back" or name == "btn_back2" then
        if self.m_nodelizi then
            self.m_nodelizi:setVisible(false)
        end
        self:closeUI(function ()
            self:goToChapterView()
        end)
    end
end

function QuestNewTaskDoneTipLayer:goToChapterView()
    if self.isOnKeepGoing then
        return
    end
    self.isOnKeepGoing = true
    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if questConfig ~= nil then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    end
end


-- 弹窗动画
function QuestNewTaskDoneTipLayer:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewTaskDoneTipLayer.super.playShowAction(self, userDefAction)
end

function QuestNewTaskDoneTipLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():triggerGuide(self, "enterQuestTaskDone", ACTIVITY_REF.QuestNew)
end


return QuestNewTaskDoneTipLayer
