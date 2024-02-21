-- Created by jfwang on 2019-05-21.
-- QuestBox
--
local QuestBox = class("QuestBox", BaseView)

local BIG_BOX_INDEX = 6 --最后一个大宝箱

function QuestBox:getCsbNodePath(index)
    if index == BIG_BOX_INDEX then
        return QUEST_RES_PATH.QuestMapBoxBig
    else
        return QUEST_RES_PATH.QuestMapBox
    end
end

function QuestBox:initUI(index, unLockFunc)
    self.questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()

    self:createCsbNode(self:getCsbNodePath(index))
    self:runCsbAction("idle", true)
    --唯一标示
    self.m_index = index
    self.m_unLockFunc = unLockFunc

    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
        btn_click:setSwallowTouches(false)
    end
end

function QuestBox:getIndex()
    return self.m_index
end

function QuestBox:IsUnLock()
    if self.questData ~= nil then
        if self.m_index < self.questData:getPhaseIdx() then
            return true
        end
    end
    return false
end

function QuestBox:openBox()
    --打开宝箱
    if self.m_unLockFunc and type(self.m_unLockFunc) == "function" then
        self.m_unLockFunc(
            self:getTag(),
            function()
                self:onRolling()
            end
        )
    else
        self:onRolling()
    end
end

function QuestBox:onRolling()
    gLobalNoticManager:addObserver(
        self,
        function()
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER)
            self:onCollect()
        end,
        ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER
    )
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_SHOW, {bl_complete = true, phase_idx = self.m_index})
end

function QuestBox:onCollect()
    if not self.questData then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE)
        return
    end

    local reward_data = {}
    reward_data.p_items = {}
    local phase_data = self.questData:getCurPhaseData()
    if self.questData:isNewUserQuest() or self.questData:getThemeName() ~= "Activity_QuestIsland" then
        local phaseReward = self.questData:getPhaseReward()
        reward_data.p_coins = phaseReward.p_coins or 0
        reward_data.p_items = phaseReward.p_items or {}
    else
        reward_data.p_coins = tonumber(phase_data.p_phaseCoins or 0)
    end
    local wheel_reward = phase_data:getWheelReward()
    if wheel_reward and wheel_reward.p_items and #wheel_reward.p_items > 0 then
        for i, item_data in ipairs(wheel_reward.p_items) do
            table.insert(reward_data.p_items, item_data)
        end
    end
    local view = util_createFindView(QUEST_CODE_PATH.QuestBoxReward, reward_data)
    view:setOverFunc(
        function()
            if not tolua.isnull(self) then
                if self.questData then
                    self.questData.m_lastPhase = nil
                end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE)
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function QuestBox:showTipsView()
    if not self.questData then
        return
    end

    if self:IsUnLock() then
        return
    end

    --难度还未选择，就不弹提示框
    if G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
        return
    end

    if self.questData:IsTaskAllFinish(self.m_index) then
        return
    end

    if not self.m_showBetTips then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local box_data = self.questData:getPhaseReward()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_SHOW, {bl_complete = false, box_data = box_data, phase_idx = self.m_index})
    end
end

function QuestBox:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_click" then
        self:showTipsView()
    end
end

return QuestBox
