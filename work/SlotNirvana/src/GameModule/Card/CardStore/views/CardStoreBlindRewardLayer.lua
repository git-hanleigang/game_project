-- 卡牌商店 盲盒奖励展示界面

local ShopItem = util_require("data.baseDatas.ShopItem")
local CardStoreBlindRewardLayer = class("CardStoreBlindRewardLayer", BaseLayer)

function CardStoreBlindRewardLayer:ctor()
    CardStoreBlindRewardLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.BlindRewardUI)
    self:setExtendData("CardStoreBlindRewardLayer")
end

function CardStoreBlindRewardLayer:initCsbNodes()
    self.sp_gift1 = self:findChild("sp_gift1")
    self.sp_gift2 = self:findChild("sp_gift2")
    self.sp_gift3 = self:findChild("sp_gift3")

    self.node_reward = self:findChild("node_reward")
    self.sp_coin = self:findChild("sp_coin")
    self.sp_coin:setVisible(false)
    self.lb_coin = self:findChild("lb_coin")
    self.lb_coin:setVisible(false)
    self.btn_collect = self:findChild("btn_collect")
end

function CardStoreBlindRewardLayer:initDatas(reward_data, item_idx)
    self.reward_data = reward_data
    self.item_idx = item_idx
end

function CardStoreBlindRewardLayer:initView()
    if not self.reward_data then
        return
    end

    self.sp_gift1:setVisible(self.item_idx == 1)
    self.sp_gift2:setVisible(self.item_idx == 2)
    self.sp_gift3:setVisible(self.item_idx == 3)

    if self.reward_data.rewardType == "COINS" and self.reward_data.coins > 0 then
        self.sp_coin:setVisible(true)
        self.lb_coin:setVisible(true)
        self.lb_coin:setString(util_formatCoins(self.reward_data.coins, 12))
        util_alignCenter({{node = self.sp_coin}, {node = self.lb_coin}})
    elseif self.reward_data.rewardType == "ITEM" and table.nums(self.reward_data.shopItemResultList) > 0 then
        local item_list = {}
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
    end

    self:setPops()
end

function CardStoreBlindRewardLayer:setPops()
    if self.reward_data.rewardType == "ITEM" and table.nums(self.reward_data.shopItemResultList) > 0 then
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

function CardStoreBlindRewardLayer:playShowAction()
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
    CardStoreBlindRewardLayer.super.playShowAction(self, userDefAction)
end

function CardStoreBlindRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function CardStoreBlindRewardLayer:playHideAction()
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
    CardStoreBlindRewardLayer.super.playHideAction(self, userDefAction)
end

function CardStoreBlindRewardLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:flyCoins()
    end
end

function CardStoreBlindRewardLayer:flyCoins()
    local baseCoins = globalData.topUICoinCount
    local rewardCoins = globalData.userRunData.coinNum - baseCoins
    if rewardCoins <= 0 then
        self:closeUI(
            function()
                G_GetMgr(G_REF.CardStore):popNext()
            end
        )
        return
    end

    local endPos = globalData.flyCoinsEndPos
    local btnCollect = self.btn_collect
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        rewardCoins,
        function()
            self:closeUI(
                function()
                    G_GetMgr(G_REF.CardStore):popNext()
                end
            )
        end
    )
end
return CardStoreBlindRewardLayer
