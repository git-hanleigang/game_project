-- Created by jfwang on 2019-05-21.
-- QuestNewUserOpenView
--
local QuestNewUserOpenView = class("QuestNewUserOpenView", BaseLayer)

function QuestNewUserOpenView:initDatas(callback)
    self.m_callback = callback
    self:setLandscapeCsbName("QuestNewUser/Activity/csd/NewUser_QuestLinkLayer4.csb")
    self:setPortraitCsbName("QuestNewUser/Activity/csd/NewUser_QuestLinkLayer4_shu.csb")

    self:setPauseSlotsEnabled(true)
end

function QuestNewUserOpenView:initUI(callback)
    QuestNewUserOpenView.super.initUI(self)

    self:addClick(self:findChild("btn_close"))
    gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestEntrySite("gameLevelUpPush")
    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("PushPage", "Open")

    gLobalSoundManager:pauseBgMusic()

    gLobalSoundManager:playSound("QuestNewUser/Activity/QuestNewUserSounds/questNewUserOpen.mp3")

    self.m_labText1 = self:findChild("lb_text_1")
    self.m_labText2 = self:findChild("lb_text_2")
    self.m_labText3 = self:findChild("lb_text_3")
    self.m_labText4 = self:findChild("lb_text_3_num")
    self:setButtonLabelContent("Button_2", "SHOW ME")
    self:startButtonAnimation("Button_2", "sweep", true)

    self:updateView()
end

function QuestNewUserOpenView:onShowedCallFunc()
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )
end

function QuestNewUserOpenView:updateView()
    -- csc 2021-05-21 气泡文字修改
    if not self.m_labText1 or not globalData.constantData.NOVICE_NEWUSERQUEST_LEVELUP_CONTENT then
        return
    end
    -- 分割文本
    local tb_text = string.split(globalData.constantData.NOVICE_NEWUSERQUEST_LEVELUP_CONTENT, ";")
    self.m_labText1:setString(tb_text[1])
    self.m_labText2:setString(tb_text[2])

    local rewardNum = globalData.constantData.NOVICE_NEWUSERQUEST_LEVELUP_REWARD
    if string.len(rewardNum) > 0 then
        self.m_labText3:setVisible(false)
        self.m_labText4:setVisible(true)
        self.m_labText4:setString(util_getFromatMoneyStr(rewardNum))
    else
        self.m_labText3:setVisible(true)
        self.m_labText4:setVisible(false)
        self.m_labText3:setString(tb_text[3])
    end
end

function QuestNewUserOpenView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clicked then
        return
    end
    self.m_clicked = true
    if name == "Button_2" then
        local callback = function()
            gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("PushPage", "Click")
            G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
        end

        self:closeUI(callback)
    elseif name == "btn_close" then
        local callback = function()
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
            if self.m_callback then
                self.m_callback()
            end
        end

        self:closeUI(callback)
    end
end

function QuestNewUserOpenView:onExit()
    QuestNewUserOpenView.super.onExit(self)
    gLobalSoundManager:resumeBgMusic()
end

return QuestNewUserOpenView
