-- 新手quest 大宝箱
local STAGE_COUNTS_IN_PHASE = 7 -- 章节关卡数
local QuestNewUserBox = class("QuestNewUserBox", BaseView)

function QuestNewUserBox:getCsbName()
    if self.quest_data and self.quest_data:getPhaseCount() == self.m_index then
        return QUEST_RES_PATH.QuestMapBoxBig
    end

    return QUEST_RES_PATH.QuestMapBox
end

function QuestNewUserBox:initDatas(index, unLockFunc)
    --唯一标示
    self.m_index = index
    self.m_unLockFunc = unLockFunc
    self.quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not self.quest_data then
        return
    end
    self.phase_data = self.quest_data:getPhaseData(self.m_index)
    self.phase_idx = self.quest_data:getPhaseIdx()
    self.stage_idx = STAGE_COUNTS_IN_PHASE
end

function QuestNewUserBox:getIdx()
    return self.m_index
end

function QuestNewUserBox:initCsbNodes()
    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
        btn_click:setSwallowTouches(false)
    end
    self.node_card = self:findChild("node_card")
    self.node_tip = self:findChild("node_tip")
end

function QuestNewUserBox:initUI()
    QuestNewUserBox.super.initUI(self)
    self:updateUI()
end

function QuestNewUserBox:updateUI()
    if self.phase_data and not self.phase_data:getIsLast() and self.phase_data.p_status == "FINISHED" then
        self:showCollected()
    else
        self:showLocked()
    end

    self:showRewards()
end

function QuestNewUserBox:showLocked()
    self:runCsbAction("idle", true)
end

function QuestNewUserBox:showCollected()
    if util_csbActionExists(self.m_csbAct, "collected") then
        self:runCsbAction("collected", true)
    else
        self:showLocked()
    end
end

function QuestNewUserBox:showRewards()
    if not self.phase_data or not self.phase_data.p_phaseItems or #self.phase_data.p_phaseItems <= 0 then
        return
    end
    local item_data = self.phase_data.p_phaseItems[1]
    if not item_data then
        return
    end
    if not tolua.isnull(self.node_card) then
        self.node_card:removeAllChildren()
        local shopItemUI = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.REWARD)
        if shopItemUI then
            shopItemUI:addTo(self.node_card)
        end
    end
end

function QuestNewUserBox:openBox()
    if util_csbActionExists(self.m_csbAct, "open") then
        self:runCsbAction(
            "open",
            false,
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_STAGE_COMPLETE)
                if not tolua.isnull(self) then
                    self:updateUI()
                end
            end,
            60
        )
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_STAGE_COMPLETE)
        self:updateUI()
    end
end

function QuestNewUserBox:showTip()
    local phase_idx = self.quest_data:getPhaseIdx()
    if not self.phase_data or self.phase_data.p_status == "FINISHED" or self:getIdx() ~= phase_idx then
        return
    end

    if not self.tip_rewards then
        self:initTipUI()
    end
    self.tipUI:showTipView()
end

function QuestNewUserBox:initTipUI()
    if not self.tipUI then
        self.tipUI = util_createFindView(QUEST_CODE_PATH.QuestCellTips, self.m_index, #self.phase_data.p_stages)
        if self.tipUI then
            self.tipUI:addTo(self.node_tip)
        end
    end
end

function QuestNewUserBox:clicked()
    return self.m_clicked
end

function QuestNewUserBox:setClicked(bl_clicked)
    if self.m_clicked == bl_clicked then
        return
    end
    if bl_clicked then
        if self.click_delay then
            self:stopAction(self.click_delay)
            self.click_delay = nil
        end
        self.click_delay =
            util_performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self.click_delay = nil
                    self.m_clicked = false
                end
            end,
            0.5
        )
    end
    self.m_clicked = bl_clicked
end

function QuestNewUserBox:clickFunc(sender)
    if self:clicked() then
        return
    end
    local name = sender:getName()
    if name == "btn_click" then
        self:setClicked(true)
        self:showTip()
    end
end

return QuestNewUserBox
