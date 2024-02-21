--[[
    
]]

local RoutineSalePrize = class("RoutineSalePrize", BaseView)

function RoutineSalePrize:getCsbName()
    if self.m_isPortrait then
        return "Sale_New/csb/main/SaleMain_Prize_shu.csb"
    else
        return "Sale_New/csb/main/SaleMain_Prize.csb"
    end
end

function RoutineSalePrize:initDatas(_data, _isPortrait, _mainLayer)
    self.m_data = _data
    self.m_isPortrait = _isPortrait
    self.m_mainLayer = _mainLayer
end

function RoutineSalePrize:initUI()
    RoutineSalePrize.super.initUI(self)

    self:setCoins()
    self:setCard()
    self:setDiscount()
    self:initItems()
    self:setNodeShow()
    self:setButtonLabelContent("btn_buy_" .. self.m_data.p_index, "$" .. self.m_data.p_price)
    self:runCsbAction("idle", true)
end

function RoutineSalePrize:setCoins()
    local index = self.m_data.p_index
    local sp_coin = self:findChild("sp_coin_" .. index)
    local lb_coins = self:findChild("lb_coins_" .. index)
    lb_coins:setString(util_formatCoins(self.m_data.p_coins, 9))

    local uiList = {
        {node = sp_coin},
        {node = lb_coins, alignX = 3}
    }
    util_alignCenter(uiList)
end

function RoutineSalePrize:setCard()
    local index = self.m_data.p_index
    local items = self.m_data.p_items or {}
    local rewardNode = self:findChild("node_card" .. index)
    if #items > 0 and rewardNode then
        local itemData = items[1]
        local tempData = gLobalItemManager:createLocalItemData(itemData.p_icon, itemData.p_num, itemData)
        local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
        rewardNode:addChild(itemNode)
    end    
end

function RoutineSalePrize:setDiscount()
    local index = self.m_data.p_index
    local node_more = self:findChild("node_more_" .. index)
    local more = util_createView("GameModule.RoutineSale.views.RoutineSaleMore", self.m_data.p_discount)
    node_more:addChild(more)
end

function RoutineSalePrize:initItems()
    local index = self.m_data.p_index
    local items = {}
    local priceItems = gLobalItemManager:checkAddLocalItemList({p_price = self.m_data.p_price, p_vipPoint = self.m_data.p_vipPoint})
    for i,v in ipairs(self.m_data.p_items) do
        table.insert(items, v)
    end
    for i,v in ipairs(priceItems) do
        table.insert(items, v)
    end
    for i = 1, 2 do
        local btnefitNode = self:findChild("node_prize_" .. index .. "_" .. i)
        local itemData = items[i]
        if itemData and btnefitNode then
            itemData = G_GetMgr(G_REF.Shop):getDescShopItemData(itemData)
            local propNode = gLobalItemManager:createDescShopBenefitNode(itemData,ITEM_SIZE_TYPE.REWARD)
            if propNode then
                gLobalItemManager:setItemNodeByExtraData(itemData,propNode)
                btnefitNode:addChild(propNode)
            end
        end
    end
end

function RoutineSalePrize:setNodeShow()
    for i = 1, 3 do
        local node = self:findChild("node_" .. i)
        node:setVisible(i == self.m_data.p_index)
    end
end

function RoutineSalePrize:getData()
    return self.m_data
end

function RoutineSalePrize:clickFunc(_sender)
    if self.m_mainLayer:getTouch() then
        return
    end

    local name = _sender:getName()
    if name == "btn_benefits_1" then
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(self.m_data, self.m_data.p_items, nil, true)
    elseif name == "btn_benefits_2" then
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(self.m_data, self.m_data.p_items, nil, true)
    elseif name == "btn_benefits_3" then
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(self.m_data, self.m_data.p_items, nil, true)
    elseif name == "btn_buy_1" then
        self:buySale(self.m_data, 1)
    elseif name == "btn_buy_2" then
        self:buySale(self.m_data, 2)
    elseif name == "btn_buy_3" then
        self:buySale(self.m_data, 3)
    end
end

function RoutineSalePrize:buySale(_data, _index)
    self.m_mainLayer:setTouch(true)
    self.m_mainLayer:setBuy(true)
    G_GetMgr(G_REF.RoutineSale):buySale(_data, _index)
end

function RoutineSalePrize:getPrizeBgPos()
    local index = self.m_data.p_index
    local sp_prize_bg = self:findChild("sp_prize_bg" .. index)
    local x, y = sp_prize_bg:getPosition()
    local worldPos = sp_prize_bg:getParent():convertToWorldSpace(cc.p(x, y))
    local content = sp_prize_bg:getContentSize()
    sp_prize_bg:setVisible(false)

    return worldPos, content
end

function RoutineSalePrize:playHideReward(_func)
    self:runCsbAction("over", false, function ()
        -- self:runCsbAction("idle", true)
        if _func then
            _func()
        end
    end)
end

return RoutineSalePrize