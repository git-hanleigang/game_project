-- 卡牌商店 盲盒产出概率分布界面

local CardStoreBlindHelpItem = class("CardStoreBlindHelpItem", BaseView)

function CardStoreBlindHelpItem:initUI(index)
    assert(index, "CardStoreBlindHelpItem page id 不能为空")
    self.idx = index
    CardStoreBlindHelpItem.super.initUI(self)
    self:initView()
end

function CardStoreBlindHelpItem:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    return p_config.BlindItem
end

function CardStoreBlindHelpItem:initCsbNodes()
    self.sp_box1 = self:findChild("sp_box1")
    self.sp_box2 = self:findChild("sp_box2")
    self.sp_box3 = self:findChild("sp_box3")

    self.list_rewards = self:findChild("list_rewards")
end

function CardStoreBlindHelpItem:initView()
    self.sp_box1:setVisible(self.idx == 1)
    self.sp_box2:setVisible(self.idx == 2)
    self.sp_box3:setVisible(self.idx == 3)

    if self.list_rewards then
        self.list_rewards:setBounceEnabled(true)
        self.list_rewards:setScrollBarEnabled(false)
        self.list_rewards:setTouchEnabled(false)
        local store_data = G_GetMgr(G_REF.CardStore):getRunningData()
        if not store_data then
            return
        end
        local prob_data = store_data:getBlindProbListByIdx(self.idx)
        if not prob_data or table.nums(prob_data) <= 0 then
            return
        end

        for i, item_data in ipairs(prob_data) do
            if item_data then
                local item = self:createItem(item_data)
                if item then
                    self.list_rewards:pushBackCustomItem(item)
                end
            end
        end
    end
    self:runCsbAction("idle", true)
end

function CardStoreBlindHelpItem:createItem(item_data)
    local layout = ccui.Layout:create()
    local rewardUI = util_createView("GameModule.Card.CardStore.views.CardStoreBlindHelpItemReward", item_data)
    layout:addChild(rewardUI)
    local item_size = rewardUI:getContentSize()
    layout:setSize(item_size)
    rewardUI:setPosition(item_size.width / 2, item_size.height / 2)
    return layout
end

return CardStoreBlindHelpItem
