-- 卡牌商店 奖励展示界面

local ShopItem = util_require("data.baseDatas.ShopItem")
local CardStoreRewardLayer = class("CardStoreRewardLayer", BaseLayer)

function CardStoreRewardLayer:ctor()
    CardStoreRewardLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.RewardUI)
    self:setExtendData("CardStoreRewardLayer")
end

function CardStoreRewardLayer:initCsbNodes()
    self.node_coins = self:findChild("node_coins")
    self.node_reward = self:findChild("node_reward")
    self.sp_coin = self:findChild("sp_coin")
    self.sp_coin:setVisible(false)
    self.lb_coin = self:findChild("lb_coin")
    self.lb_coin:setVisible(false)
    self.btn_collect = self:findChild("btn_collect")
end

function CardStoreRewardLayer:initDatas(reward_data, item_type)
    self.reward_data = reward_data
    self.item_type = item_type
end

function CardStoreRewardLayer:initView()
    if not self.reward_data then
        return
    end

    local has_coins = false
    local coins = tonumber(self.reward_data.coins or 0)
    if coins and coins > 0 then
        self.sp_coin:setVisible(true)
        self.lb_coin:setVisible(true)
        self.lb_coin:setString(util_formatCoins(coins, 12))
        util_alignCenter({{node = self.sp_coin}, {node = self.lb_coin}})
        local coins = tonumber(self.reward_data.coins or 0)
        has_coins = true
    end

    local has_items = false
    local item_list = {}
    local gems = tonumber(self.reward_data.gems or 0)
    if gems and gems > 0 then
        local item_info = gLobalItemManager:createLocalItemData("Gem", gems, {p_limit = 3, p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
        if item then
            item:addTo(self.node_reward)
            table.insert(item_list, {node = item})
        end
        has_items = true
    end
    if self.reward_data.shopItemResultList and table.nums(self.reward_data.shopItemResultList) > 0 then
        for idx, item_info in ipairs(self.reward_data.shopItemResultList) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_info, true)
            local item = gLobalItemManager:createRewardNode(shopItem, ITEM_SIZE_TYPE.REWARD)
            if item then
                item:addTo(self.node_reward)
                table.insert(item_list, {node = item})
            end
        end
        util_alignCenter(item_list)
        has_items = true
    end

    if has_coins and has_items then
        self.node_coins:setPositionY(60)
        self.node_reward:setPositionY(-60)
    end
    self:setPops()
end

function CardStoreRewardLayer:setPops()
    if self.reward_data.shopItemResultList and table.nums(self.reward_data.shopItemResultList) > 0 then
        local reward_data = self.reward_data.shopItemResultList[1]
        local counts = self.reward_data.num
        local pop_list = {
            [1] = function()
                if CardSysManager:needDropCards("Point Store") == true then
                    -- 集卡
                    gLobalNoticManager:addObserver(
                        self,
                        function(target, func)
                            G_GetMgr(G_REF.CardStore):popNext()
                        end,
                        ViewEventType.NOTIFY_CARD_SYS_OVER
                    )
                    CardSysManager:doDropCards("Point Store")
                    return true
                end
                return false
            end,
            [2] = function()
                if reward_data.icon == "Lottery_icon" then
                    -- 抽奖券
                    G_GetMgr(G_REF.Lottery):showTicketView(
                        nil,
                        function()
                            G_GetMgr(G_REF.CardStore):popNext()
                        end,
                        counts
                    )
                    return true
                end
                return false
            end,
            [3] = function()
                -- 高倍场
                globalDeluxeManager:dropExperienceCardItemEvt(
                    function()
                        G_GetMgr(G_REF.CardStore):popNext()
                    end
                )
                return true
            end
        }
        G_GetMgr(G_REF.CardStore):addRewardPops(pop_list)
    end
end

function CardStoreRewardLayer:playShowAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    CardStoreRewardLayer.super.playShowAction(self, userDefAction)
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
end

function CardStoreRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function CardStoreRewardLayer:playHideAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "over",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    CardStoreRewardLayer.super.playHideAction(self, userDefAction)
end

function CardStoreRewardLayer:onClickMask()
    self:flyCurrency()
end

function CardStoreRewardLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:flyCurrency()
    end
end

function CardStoreRewardLayer:flyCurrency()
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local coins = tonumber(self.reward_data.coins or 0)
        local gems = tonumber(self.reward_data.gems or 0)
        local startPos = self.btn_collect:getParent():convertToWorldSpace(cc.p(self.btn_collect:getPosition()))
        local flyList = {}
        if coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        if gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = gems, startPos = startPos})
        end
        curMgr:playFlyCurrency(
            flyList,
            function()
                if not tolua.isnull(self) then
                    self:closeUI(
                        function()
                            G_GetMgr(G_REF.CardStore):popNext()
                        end
                    )
                end
            end
        )
    end
end

return CardStoreRewardLayer
