-- quest挑战活动 奖励道具
-- FIX IOS 150 v465
local ShopItem = util_require("data.baseDatas.ShopItem")

local BaseView = util_require("base.BaseView")
local Activity_QuestRushRewardItem = class("Activity_QuestRushRewardItem", BaseView)

function Activity_QuestRushRewardItem:initUI(_idx)
    BaseView.initUI(self)
    self.m_config = G_GetMgr(ACTIVITY_REF.QuestRush):getConfig()
    self.m_idx = _idx
    self.m_btnCollect = self:findChild("btn_collect")

    -- 奖励信息
    self:initItemUI(_idx)
    -- 奖励领取状态
    self:updateItemState()
end

function Activity_QuestRushRewardItem:getCsbName()
    assert(false, "Activity_QuestRushRewardItem:getCsbName 需要子类继承")
end

-- 奖励信息
function Activity_QuestRushRewardItem:initItemUI(_idx)
    local itemInfo = G_GetMgr(ACTIVITY_REF.QuestRush):getActGearInfo(_idx)
    local shopItems = itemInfo.itemResults or {}
    local node_item = self:findChild("node_item")
    if tolua.isnull(node_item) then
        return
    end
    node_item:move(0, 0)

    local rewards_list = {}
    if shopItems and #shopItems > 0 then
        for i, item_data in ipairs(shopItems) do
            if #rewards_list >= 4 then
                break
            end

            local shopItemData = ShopItem:create()
            shopItemData:parseData(item_data, true)
            if shopItemData then
                if shopItemData.p_icon == "Sidekicks_levelUp" then
                    -- 宠物升级道具
                    shopItemData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
                else
                    shopItemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
                end
                local shopItemUI = gLobalItemManager:createRewardNode(shopItemData, ITEM_SIZE_TYPE.REWARD)
                if not tolua.isnull(shopItemUI) then
                    table.insert(rewards_list, shopItemUI)
                    shopItemUI:addTo(node_item)
                    local designW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
                    shopItemUI:move(designW * 0.5, designW * 0.5)
                end
            end
        end
    end

    if #rewards_list == 2 then
        local distance = 40 -- 两张卡岔开的位移
        for i, node_item in ipairs(rewards_list) do
            node_item:setLocalZOrder(-1 * i)
            node_item:setScale(0.65)
            local posX = node_item:getPositionX()
            if i == 1 then
                node_item:setPositionX(posX + distance / 2 * -1)
                node_item:setRotation(-15)
            else
                node_item:setPositionX(posX + distance / 2)
                node_item:setRotation(30)
            end
        end
    elseif #rewards_list == 3 then
        local distance = 40 -- 两张卡岔开的位移
        local orderL = {2,1,3}
        for i, node_item in ipairs(rewards_list) do
            node_item:setLocalZOrder(orderL[i])
            node_item:setScale(0.65)
            local posX = node_item:getPositionX()
            local posY = node_item:getPositionY()
            if i == 1 then
                node_item:setPositionX(posX + distance / 2 * -1)
                node_item:setRotation(-15)
                node_item:setPositionY(posY+20)
            elseif i == 2 then
                node_item:setPositionX(posX + distance / 2)
                node_item:setRotation(30)
                node_item:setPositionY(posY+20)
            elseif i == 3 then
                node_item:setPositionX(posX)
                node_item:setPositionY(posY-20)
            end
        end
    elseif #rewards_list == 4 then
        local distance = 40 -- 两张卡岔开的位移
        local orderL = {2,1,4,3}
        for i, node_item in ipairs(rewards_list) do
            node_item:setLocalZOrder(orderL[i])
            node_item:setScale(0.65)
            local posX = node_item:getPositionX()
            local posY = node_item:getPositionY()
            if i == 1 then
                node_item:setPositionX(posX + distance / 2 * -1)
                node_item:setRotation(-15)
                node_item:setPositionY(posY+20)
            elseif i == 2 then
                node_item:setPositionX(posX + distance / 2)
                node_item:setRotation(30)
                node_item:setPositionY(posY+20)
            elseif i == 3 then
                node_item:setPositionX(posX + distance / 2 * -1)
                node_item:setRotation(-15)
                node_item:setPositionY(posY-20)
            elseif i == 4 then
                node_item:setPositionX(posX + distance / 2)
                node_item:setRotation(30)
                node_item:setPositionY(posY-20)
            end
        end
    end

    -- 每个主题的QuestRush都需要支持，处理三个/四个道具的情况
    -- 三个道具：倒品字排列
    -- 四个道具：2*2排列
end

-- 奖励领取状态
function Activity_QuestRushRewardItem:updateItemState(_bNew)
    local itemState = G_GetMgr(ACTIVITY_REF.QuestRush):getActGearState(self.m_idx, _bNew)

    if self.m_itemState == itemState then
        return
    end

    self.m_btnCollect:setVisible(false)

    if itemState == self.m_config.ITEM_STATE.CANNOT then
        -- 不能领取
        self:runCsbAction("idle")
    elseif itemState == self.m_config.ITEM_STATE.UNGAIN then
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
                G_GetMgr(ACTIVITY_REF.QuestRush):sendReceiveGearRewardReq(self.m_idx)
            end,
            60
        )
    elseif self.m_itemState and self.m_itemState == self.m_config.ITEM_STATE.UNGAIN and itemState == self.m_config.ITEM_STATE.GAIN then
        self:runCsbAction(
            "dianji",
            false,
            function()
                self:runCsbAction("idle_gou")
            end,
            60
        )
    elseif itemState == self.m_config.ITEM_STATE.GAIN then
        -- 已领取
        self:runCsbAction("idle_gou")
    end

    self.m_itemState = itemState
end

function Activity_QuestRushRewardItem:onEnter()
    -- 更新宝箱状态
    gLobalNoticManager:addObserver(
        self,
        function(self)
            self:updateItemState(true)
        end,
        self.m_config.EVENT_NAME.UPDATE_REWARD_ITEM_STATE
    )
    -- 更新 按钮触控状态
    gLobalNoticManager:addObserver(
        self,
        function(self)
            self.m_btnCollect:setTouchEnabled(true)
        end,
        self.m_config.EVENT_NAME.RESET_ITEM_TOUCH_ENABLE
    )

    -- test
    -- performWithDelay(
    --     self,
    --     function()
    --         self:runCsbAction(
    --             "dianji",
    --             false,
    --             function()
    --                 self:runCsbAction("idle_gou")
    --             end,
    --             60
    --         )
    --     end,
    --     2
    -- )
end

-- 统一点击回调
function Activity_QuestRushRewardItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        sender:setTouchEnabled(false)
        G_GetMgr(ACTIVITY_REF.QuestRush):sendReceiveGearRewardReq(self.m_idx)
    end
end

-- 关闭界面是 检测下如果 可领取去领取（version 手动领取改自动领取）
function Activity_QuestRushRewardItem:checkReceiveReward()
    local itemState = G_GetMgr(ACTIVITY_REF.QuestRush):getActGearState(self.m_idx, true)
    if itemState ~= self.m_config.ITEM_STATE.UNGAIN then
        return
    end

    -- 可以领取但是未领取
    G_GetMgr(ACTIVITY_REF.QuestRush):sendReceiveGearRewardReq(self.m_idx)
end

return Activity_QuestRushRewardItem
