-- quest挑战活动 奖励道具
-- FIX IOS 150 v465
local ShopItem = util_require("data.baseDatas.ShopItem")

local BaseView = util_require("base.BaseView")
local Activity_QuestNewRushRewardItem = class("Activity_QuestNewRushRewardItem", BaseView)

-- 奖励状态
local QuestNewRush_ItemState = {
    CANNOT = 1, -- 不能领取
    UNGAIN = 2, -- 可以领取但是未领取
    GAIN = 3 -- 已领取
}

function Activity_QuestNewRushRewardItem:initUI(_idx)
    BaseView.initUI(self)
    self.m_idx = _idx
    self.m_btnCollect = self:findChild("btn_collect")

    -- 奖励信息
    self:initItemUI(_idx)
    -- 奖励领取状态
    self:updateItemState()
end

function Activity_QuestNewRushRewardItem:getCsbName()
    assert(false, "Activity_QuestNewRushRewardItem:getCsbName 需要子类继承")
end

-- 奖励信息
function Activity_QuestNewRushRewardItem:initItemUI(_idx)
    local itemInfo = G_GetMgr(ACTIVITY_REF.QuestNewRush):getActGearInfo(_idx)
    local shopItems = itemInfo.itemResults or {}
    if not next(shopItems) then
        return
    end

    local data = shopItems[1]
    local shopItemData = ShopItem:create()
    shopItemData:parseData(data, true)
    if not shopItemData then
        return
    end

    shopItemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
    local shopItemUI = gLobalItemManager:createRewardNode(shopItemData, ITEM_SIZE_TYPE.REWARD)
    if not shopItemUI then
        return
    end

    -- 道具的阴影
    local icon = gLobalItemManager:getOldToNewIcon(shopItemData.p_icon)
    local iconPath = "PBRes/CommonItemRes/icon/" .. icon .. ".png"
    local ef = self:findChild("ef_yaan")
    if util_IsFileExist(iconPath) and ef then
        util_changeTexture(ef, iconPath)
    end

    local nodeItem = self:findChild("node_item")
    nodeItem:move(0, 0)
    shopItemUI:addTo(nodeItem)

    local designW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    shopItemUI:move(designW * 0.5, designW * 0.5)
end

-- 奖励领取状态
function Activity_QuestNewRushRewardItem:updateItemState(_bNew)
    local itemState = G_GetMgr(ACTIVITY_REF.QuestNewRush):getActGearState(self.m_idx, _bNew)

    if self.m_itemState == itemState then
        return
    end

    self.m_btnCollect:setVisible(false)

    if itemState == QuestNewRush_ItemState.CANNOT then
        -- 不能领取
        self:runCsbAction("idle")
    elseif itemState == QuestNewRush_ItemState.UNGAIN then
        -- else
        --     self.m_btnCollect:setVisible(true)
        --     self:runCsbAction("idle_daidianji", true)
        -- end
        -- 可以领取但是未领取
        -- if _bNew then
        self:runCsbAction(
            "idle_daidianji",
            false,
            function()
                G_GetMgr(ACTIVITY_REF.QuestNewRush):sendReceiveGearRewardReq(self.m_idx)
            end,
            60
        )
    elseif self.m_itemState and self.m_itemState == QuestNewRush_ItemState.UNGAIN and itemState == QuestNewRush_ItemState.GAIN then
        self:runCsbAction(
            "dianji",
            false,
            function()
                self:runCsbAction("idle_gou")
            end,
            60
        )
    elseif itemState == QuestNewRush_ItemState.GAIN then
        -- 已领取
        self:runCsbAction("idle_gou")
    end

    self.m_itemState = itemState
end

function Activity_QuestNewRushRewardItem:onEnter()
    -- 更新宝箱状态
    gLobalNoticManager:addObserver(
        self,
        function(self)
            self:updateItemState(true)
        end,
        ViewEventType.NOTIFY_NEWQUESTRUSH_UPDATE_REWARD_ITEM_STATE
    )
    -- 更新 按钮触控状态
    gLobalNoticManager:addObserver(
        self,
        function(self)
            self.m_btnCollect:setTouchEnabled(true)
        end,
        ViewEventType.NOTIFY_NEWQUESTRUSH_RESET_ITEM_TOUCH_ENABLE
    )
end

-- 统一点击回调
function Activity_QuestNewRushRewardItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        sender:setTouchEnabled(false)
        G_GetMgr(ACTIVITY_REF.QuestNewRush):sendReceiveGearRewardReq(self.m_idx)
    end
end

-- 关闭界面是 检测下如果 可领取去领取（version 手动领取改自动领取）
function Activity_QuestNewRushRewardItem:checkReceiveReward()
    local itemState = G_GetMgr(ACTIVITY_REF.QuestNewRush):getActGearState(self.m_idx, true)
    if itemState ~= QuestNewRush_ItemState.UNGAIN then
        return
    end

    -- 可以领取但是未领取
    G_GetMgr(ACTIVITY_REF.QuestNewRush):sendReceiveGearRewardReq(self.m_idx)
end

return Activity_QuestNewRushRewardItem
