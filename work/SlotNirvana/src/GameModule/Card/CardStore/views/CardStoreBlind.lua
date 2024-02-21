-- 卡牌商城 盲盒道具

local CardStoreBlind = class("CardStoreBlind", BaseView)

function CardStoreBlind:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if p_config and p_config.BlindUI then
        return p_config.BlindUI
    end
end

function CardStoreBlind:initDatas(reward_idx, reward_type)
    self.reward_idx = reward_idx
    self.reward_type = reward_type
end

function CardStoreBlind:initUI()
    CardStoreBlind.super.initUI(self)
    self:initView()
end

function CardStoreBlind:initCsbNodes()
    self.sp_box1 = self:findChild("sp_box1")
    self.sp_box2 = self:findChild("sp_box2")
    self.sp_box3 = self:findChild("sp_box3")
    self.lb_chips = self:findChild("lb_chips")
    self.sp_empty = self:findChild("sp_empty")
    self.sp_ticketBg = self:findChild("sp_ticketBg")
end

function CardStoreBlind:initView()
    self.sp_box1:setVisible(self.reward_idx == 1)
    self.sp_box2:setVisible(self.reward_idx == 2)
    self.sp_box3:setVisible(self.reward_idx == 3)

    self:onRefresh()
end

function CardStoreBlind:onRefresh()
    local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
    if not reward_data then
        return
    end
    local chips = reward_data:getChips()
    self.lb_chips:setString(util_formatCoins(chips, 3))

    local counts = reward_data:getCounts()
    self.sp_empty:setVisible(counts <= 0)
    self.sp_ticketBg:setVisible(counts > 0)
end

function CardStoreBlind:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
        if not reward_data then
            return
        end

        local counts = reward_data:getCounts()
        if counts <= 0 then
            return
        end

        local total_chips = 0
        local store_data = G_GetMgr(G_REF.CardStore):getRunningData()
        local item_type = reward_data:getItemType()
        if item_type == "NORMAL" then
            total_chips = store_data:getNormalChipPoints()
        elseif item_type == "GOLDEN" then
            total_chips = store_data:getGoldenChipPoints()
        elseif item_type == "BLIND_BOX" then
            total_chips = store_data:getNormalChipPoints()
        end
        local chips = reward_data:getChips()
        if total_chips >= chips then
            self:onBuy()
        else
            self:showLackTip()
        end
    end
end

function CardStoreBlind:showLackTip()
    if gLobalViewManager:getViewByExtendData("CardStoreLackLayer") then
        return
    end

    local exchangeUI = util_createView("GameModule.Card.CardStore.views.CardStoreLackLayer")
    if exchangeUI then
        gLobalViewManager:showUI(exchangeUI, ViewZorder.ZORDER_UI)
    end
end

-- 发起兑换
function CardStoreBlind:onBuy()
    local reward_data = G_GetMgr(G_REF.CardStore):getItemData(self.reward_type, self.reward_idx)
    if not reward_data then
        return
    end
    local item_id = reward_data:getItemId()
    local item_num = 1
    local item_type = reward_data:getItemType()
    G_GetMgr(G_REF.CardStore):sendToExchange(item_id, item_num, item_type, self.reward_idx)
end

return CardStoreBlind
