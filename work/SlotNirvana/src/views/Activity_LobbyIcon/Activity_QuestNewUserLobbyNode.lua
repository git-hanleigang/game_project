-- Created by jfwang on 2019-05-21.
-- 大厅入口
--
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local Activity_QuestNewUserLobbyNode = class("Activity_QuestNewUserLobbyNode", BaseLobbyNodeUI)

function Activity_QuestNewUserLobbyNode:initUI(data)
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        self:createCsbNode("Activity_LobbyIconRes/Activity_NewQuestLobbyNode.csb")
    else
        self:createCsbNode("Activity_LobbyIconRes/Activity_QuestLobbyNode.csb")
    end

    self.m_timeBg = self:findChild("timebg")
    self.m_djsLabel = self:findChild("timeValue")

    self.m_lock = self:findChild("lock")
    self.lb_unlock = self:findChild("lb_unlock")
    self.m_sp_new = self:findChild("sp_new")
    self.m_sp_new:setVisible(false)
    self.m_tips_msg = self:findChild("tipsNode")
    self.m_tips_msg:setVisible(false)
    self.m_nodeSizePanel = self:findChild("node_sizePanel")
    self.m_tips_commingsoon_msg = self:findChild("tipsNode_comingsoon")
    self.m_tipsNode_downloading = self:findChild("tipsNode_downloading")
    if self.m_tips_commingsoon_msg then
        self.m_tips_commingsoon_msg:setVisible(false)
    end
    if self.m_tipsNode_downloading then
        self.m_tipsNode_downloading:setVisible(false)
    end
    --Quest活动数据
    self:initView()
end

function Activity_QuestNewUserLobbyNode:getQuestData()
    local questData = G_GetMgr(ACTIVITY_REF.Quest):getData()
    if questData and questData:isNewUserQuest() then
        return questData
    else
        return nil
    end
end

function Activity_QuestNewUserLobbyNode:updateView()
    Activity_QuestNewUserLobbyNode.super.updateView(self)
    self.btnFunc:setOpacity(255)
end

--刷新界面
function Activity_QuestNewUserLobbyNode:initView()
    Activity_QuestNewUserLobbyNode.super.initView(self)
    self.m_lockIocn:setVisible(false)
    --解锁等级
    local unLockLevel = globalData.constantData.OPENLEVEL_NEWUSERQUEST or 6
    self.lb_unlock:setString("UNLOCK QUEST AT LEVEL " .. unLockLevel)

    local Sprite_1 = self:findChild("Sprite_1")

    local curLevel = globalData.userRunData.levelNum
    if curLevel < unLockLevel then
        self.m_timeBg:setVisible(false)
        self.m_sp_new:setVisible(false)
        self.m_lock:setVisible(true)
        self.m_LockState = true
        if Sprite_1 then
            Sprite_1:setColor(cc.c3b(180, 180, 180))
        end
        self:updateDownLoad(false)
    else
        self.m_timeBg:setVisible(true)
        self.m_lock:setVisible(false)
        self.m_LockState = false
        self:showDownTimer()
        if Sprite_1 then
            Sprite_1:setColor(cc.c3b(255, 255, 255))
        end
        self:updateDownLoad(true)
    end

    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        local lbUnlockDesc = self:findChild("lb_unlock")
        local unLockLevel = globalData.constantData.OPENLEVEL_NEWUSERQUEST or 6
        lbUnlockDesc:setString("UNLOCK VEGAS QUEST AT LEVEL " .. unLockLevel)
    end
end

--显示倒计时
function Activity_QuestNewUserLobbyNode:showDownTimer()
    local questConfig = self:getQuestData()
    if not questConfig then
        return
    end

    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_QuestNewUserLobbyNode:updateLeftTime()
    local questConfig = self:getQuestData()

    if not questConfig or questConfig:isOpen() == false then
        self:stopTimerAction()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_QUEST_NEWUSER)
        --活动结束，关闭入口
        if self.closeLobbyNode then
            self:closeLobbyNode()
        end
    elseif questConfig then
        local expireTime = questConfig:getLeftTime()
        --活动剩余24小时，请求刷新数据
        if questConfig and questConfig.p_questExtraPrize and expireTime == questConfig.p_questExtraPrize then
            if self.onUpdateActivityStart then
                self:onUpdateActivityStart()
            end
        end
        if self.m_djsLabel and self.m_djsLabel.setString then
            local strLeftTime = util_daysdemaining(questConfig:getExpireAt(), true)
            self.m_djsLabel:setString(strLeftTime)
        end
        self.m_lock:setVisible(false)
        self.m_timeBg:setVisible(true)
    end
end

function Activity_QuestNewUserLobbyNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
    self.m_timeBg:setVisible(false)
    self.m_lock:setVisible(true) -- 锁定icon
end

--活动结束，关闭入口
function Activity_QuestNewUserLobbyNode:closeLobbyNode()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FIND_CLOSE, "Activity_QuestNewUser")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FIND_CLOSE, "Activity_Quest")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, self.m_curActivityId)
end

--点击了活动node
function Activity_QuestNewUserLobbyNode:onClickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end
    --打开quest活动主界面
    G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
    self:openLayerSuccess()
end

function Activity_QuestNewUserLobbyNode:onUpdateActivityStart()
    --请求更新难度数据
    -- if not self.m_isRequest then
    --     self.m_isRequest = true
    --     performWithDelay(self,function()
    --         gLobalSendDataManager:getNetWorkFeature():sendActivityConfig()
    --     end,2)
    -- end
end

function Activity_QuestNewUserLobbyNode:onUpdateActivityEnd()
    gLobalNoticManager:postNotification(ViewEventType.UPDATE_SLIDEANDHALL_FINISH)
end

function Activity_QuestNewUserLobbyNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
        self:onClickLobbyNode()
    end
end

function Activity_QuestNewUserLobbyNode:showCommingSoon()
    -- 主要用作于活动结束之后 切换成commingSoon 界面
    self.m_commingSoon = true
    self.m_tips_msg:setVisible(false)
    self.m_tips_commingsoon_msg:setVisible(false)
    self.m_lock:setVisible(true)
    self.m_timeBg:setVisible(false)
    self.m_sp_new:setVisible(false)
end

function Activity_QuestNewUserLobbyNode:getBottomName()
    return "QUEST"
end

-- function Activity_QuestNewUserLobbyNode:getDownLoadKey()
--     return "Activity_Quest"
-- end

-- function Activity_QuestNewUserLobbyNode:getProgressPath()
--     return "Activity_LobbyIconRes/ui/QuestLink_dating.png"
-- end
-- function Activity_QuestNewUserLobbyNode:getDownLoadingNode()
--     return self:findChild("downLoadNode")
-- end
-- function Activity_QuestNewUserLobbyNode:getProcessBgOffset()
--     return 0,12
-- end
return Activity_QuestNewUserLobbyNode
