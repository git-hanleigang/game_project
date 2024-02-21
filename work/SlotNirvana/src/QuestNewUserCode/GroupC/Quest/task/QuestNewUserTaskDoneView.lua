-- Created by jfwang on 2019-05-21.
-- Quest任务完成界面
--
local QuestNewUserTaskDoneView = class("QuestNewUserTaskDoneView", BaseLayer)

function QuestNewUserTaskDoneView:ctor()
    QuestNewUserTaskDoneView.super.ctor(self)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestTaskDoneLayer)
    self:setPauseSlotsEnabled(true)

    self:setExtendData("QuestTaskDoneLayer")
end

function QuestNewUserTaskDoneView:initUI()
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    QuestNewUserTaskDoneView.super.initUI(self)
end

function QuestNewUserTaskDoneView:initCsbNodes()
    self.m_daojvNode = self:findChild("Node_daojv")
    self.m_doneNode = self:findChild("icon_done")
    self.m_logoNode = self:findChild("logo")
    self.m_keepBtn = self:findChild("btn_keep")

    self.m_rewardNode = self:findChild("node_reward")
    self.m_rewardCoins = self:findChild("m_lb_coins")
    self.m_rewardLighting = self:findChild("m_lb_num")
    self.m_sp_star = self:findChild("m_sp_star")

    self.m_sp_coins = self:findChild("m_sp_coins")
    self.m_node_star = self:findChild("node_star")
    self.m_node_coin = self:findChild("node_coin")
end

function QuestNewUserTaskDoneView:initView()
    self.m_offIconY = 0
    --关卡头像
    local levelName = ""
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName then
        levelName = globalData.slotRunData.machineData.p_levelName
    end

    if levelName ~= "" then
        local path = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.SMALL)
        if util_IsFileExist(path) then
            local sp = util_createSprite(path)
            if not sp then
                return
            end
            self.m_logoNode:addChild(sp)
            -- sp:setScale(0.66)
            -- local mask = util_createSprite(path)
            -- local flash = util_createSprite("QuestNewUser/Activity/NewQuestOther/quest_l_flash_a.png")
            -- flash:setBlendFunc(770, 1)
            -- local clip_node = cc.ClippingNode:create()
            -- clip_node:setAlphaThreshold(0.9)
            -- clip_node:setStencil(mask)
            -- sp:addChild(clip_node)
            -- local w, h = sp:getContentSize().width * 0.5, sp:getContentSize().height * 0.5
            -- clip_node:setPosition(w, h)
            -- clip_node:addChild(flash)
            -- flash:setPosition(-w * 3, 0)
            -- flash:runAction(cc.MoveTo:create(3, cc.p(w * 3, 0)))
        end
    end

    --完成，欢呼音效
    gLobalSoundManager:playSound("QuestNewUser/Activity/QuestNewUserSounds/Quest_huanhu.mp3")
end

function QuestNewUserTaskDoneView:onKeepGoing()
    if self.isOnKeepGoing then
        return
    end
    self.isOnKeepGoing = true

    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
end

function QuestNewUserTaskDoneView:playShowAction()
    QuestNewUserTaskDoneView.super.playShowAction(self, "show", false)
end

function QuestNewUserTaskDoneView:playHideAction()
    QuestNewUserTaskDoneView.super.playHideAction(self, "over", false)
end

function QuestNewUserTaskDoneView:onEnter()
    QuestNewUserTaskDoneView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                target:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function QuestNewUserTaskDoneView:onExit()
    QuestNewUserTaskDoneView.super.onExit(self)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
end

function QuestNewUserTaskDoneView:onKeyBack()
    self:onKeepGoing()
end

function QuestNewUserTaskDoneView:clickFunc(sender)
    local name = sender:getName()
    if self.isClick then
        return
    end
    self.isClick = true
    if name == "btn_keep" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        sender:setTouchEnabled(false)
        self:onKeepGoing()
    end
end

function QuestNewUserTaskDoneView:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    QuestNewUserTaskDoneView.super.closeUI(self)
end

return QuestNewUserTaskDoneView
