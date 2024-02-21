-- 新手quest 礼盒
local QuestNewUserGift = class("QuestNewUserGift", BaseView)

local GIFT_STATE = {
    LOCKED = "LOCKED",
    OPEN = "OPEN",
    COLLECTING = "COLLECTING",
    COLLECTED = "COLLECTED"
}

function QuestNewUserGift:getCsbName()
    return QUEST_RES_PATH.QuestCellGift
end

function QuestNewUserGift:initDatas(phase_idx, stage_idx)
    self.phase_idx = phase_idx
    self.stage_idx = stage_idx
    self.quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not self.quest_data then
        return
    end
    self.stage_data = self.quest_data:getStageData(phase_idx, stage_idx)
    self.gift_state = GIFT_STATE.LOCKED
end

function QuestNewUserGift:initUI()
    QuestNewUserGift.super.initUI(self)

    self:updateUI()
end

function QuestNewUserGift:initCsbNodes()
    self.node_tip = self:findChild("node_tip")
    self.btn_i = self:findChild("btn_i")
    if self.btn_i then
        self:addClick(self.btn_i)
        self.btn_i:setSwallowTouches(false)
    end

    self.node_vip = self:findChild("node_vip")
    self.node_card = self:findChild("node_card")
end

function QuestNewUserGift:updateUI()
    if self.stage_data and not self.stage_data:getIsLast() and self.stage_data.p_status == "FINISHED" then
        self:showCollected()
    else
        if self.phase_idx == self.quest_data:getPhaseIdx() then
            self:showOpen()
        else
            self:showLocked()
        end
    end

    self:showRewards()
end

function QuestNewUserGift:showOpen()
    self:runCsbAction("idle", true)

    self.gift_state = GIFT_STATE.OPEN
    if not tolua.isnull(self.node_vip) then
        self.node_vip:setVisible(true)
    end
    if not tolua.isnull(self.node_card) then
        self.node_card:setVisible(true)
    end
end

function QuestNewUserGift:showLocked()
    self:runCsbAction("idle", true)

    self.gift_state = GIFT_STATE.LOCKED
    if not tolua.isnull(self.node_vip) then
        self.node_vip:setVisible(true)
    end
    if not tolua.isnull(self.node_card) then
        self.node_card:setVisible(true)
    end
end

function QuestNewUserGift:showCollected()
    if util_csbActionExists(self.m_csbAct, "idleframe2") then
        self:runCsbAction("idleframe2", true)
        self.gift_state = GIFT_STATE.COLLECTED
        if not tolua.isnull(self.node_vip) then
            self.node_vip:setVisible(false)
        end
        if not tolua.isnull(self.node_card) then
            self.node_card:setVisible(false)
        end
    else
        self:showLocked()
    end
end

function QuestNewUserGift:showRewards()
    if not self.stage_data or not self.stage_data.p_items or #self.stage_data.p_items <= 0 then
        return
    end
    local item_data = self.stage_data.p_items[1]
    if not item_data then
        return
    end
    if item_data.p_icon == "VipBoost" and not tolua.isnull(self.node_vip) then
        self.node_vip:removeAllChildren()
        local shopItemUI = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.TOP)
        if shopItemUI then
            shopItemUI:addTo(self.node_vip)
            shopItemUI:setIconTouchEnabled(false)
            -- 扫光特效
            local node_ef = util_createAnimation(QUEST_RES_PATH.QuestCellGiftEff)
            if node_ef then
                node_ef:playAction("idle", true, nil, 60)
                node_ef:addTo(self.node_vip)
            end
        end
    elseif not tolua.isnull(self.node_card) then
        self.node_card:removeAllChildren()
        local shopItemUI = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.REWARD)
        if shopItemUI then
            shopItemUI:addTo(self.node_card)
            shopItemUI:setIconTouchEnabled(false)
        end
    end
end

function QuestNewUserGift:openBox()
    if util_csbActionExists(self.m_csbAct, "open") then
        self.gift_state = GIFT_STATE.COLLECTING
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

function QuestNewUserGift:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_i" then
        if self.gift_state == GIFT_STATE.OPEN then
            self:showTip()
        end
    end
end

function QuestNewUserGift:showTip()
    if not self.tip_rewards then
        self:initTipUI()
    end
    self.tipUI:showTipView()
end

function QuestNewUserGift:initTipUI()
    if not self.tipUI then
        self.tipUI = util_createFindView(QUEST_CODE_PATH.QuestCellTips, self.phase_idx, self.stage_idx)
        if self.tipUI then
            self.tipUI:addTo(self.node_tip)
        end
    end
end

return QuestNewUserGift
