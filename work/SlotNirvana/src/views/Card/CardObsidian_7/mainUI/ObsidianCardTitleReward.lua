--[[
    特殊卡册标题奖励-购物主题
]]
local ObsidianCardTitleReward = class("ObsidianCardTitleReward", BaseView)

function ObsidianCardTitleReward:initDatas(_index)
    self.m_index = _index
    self.m_factor = 1
    self.m_baseCoins = 0
    self.m_itemDataList = {}
end

function ObsidianCardTitleReward:getCsbName()
    return "CardRes/CardObsidian_7/csb/main/ObsidianAlbum_title_reward.csb"
end

function ObsidianCardTitleReward:initCsbNodes()
    self.m_lbChips = self:findChild("lb_chips")
    self.m_lbCompleted = self:findChild("lb_completed")

    self.m_nodeCoin = self:findChild("node_coin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_nodeReward = self:findChild("node_card")
end

function ObsidianCardTitleReward:initUI()
    ObsidianCardTitleReward.super.initUI(self)
    self:initCoins()
    self:initChips()
end

function ObsidianCardTitleReward:initCoins()
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData()
    if not data then
        return
    end
    local rewardData = self:getPhaseReward()
    if not rewardData then
        return
    end
    if data:isPhaseRewardCompleted(self.m_index) then
        self.m_nodeCoin:setVisible(false)
        self.m_lbCompleted:setVisible(true)
    else
        self.m_nodeCoin:setVisible(true)
        self.m_lbCompleted:setVisible(false)
        -- 金币
        local coinNum = rewardData:getCoins()
        self.m_baseCoins = coinNum
        local timeLimitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
        if timeLimitExpansion then
            self.m_factor = self.m_factor + timeLimitExpansion:getExpansionRatio()
        end
        self.m_curCoins = math.floor(coinNum / self.m_factor)
        if self.m_factor > 1 then
            gLobalNoticManager:addObserver(
                self,
                function()
                    self:carnivalCoinsAction()
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE)
                end,
                ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE
            )
        end
        self.m_lbCoin:setString(util_formatCoins(self.m_curCoins, 3))
        local items = rewardData:getItems()
        if items and #items > 0 then
            self.m_lbCoin:setString(util_formatCoins(self.m_curCoins, 3) .. " +")
        end
        --道具
        local itemDataList = {}
        if items and #items > 0 then
            for i, v in ipairs(items) do
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
        if #itemDataList > 0 then
            local len = #itemDataList
            local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
            local height = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
            local width = height * #itemDataList
            self.m_nodeReward:addChild(itemNode)
        end
        self.m_itemDataList = itemDataList
        self:alignCoins()
    end
end

function ObsidianCardTitleReward:alignCoins()
    local uiList = {
        {node = self.m_spCoin, scale = 0.43, alignX = -15},
        {node = self.m_lbCoin, scale = 0.3, alignX = 17}
    }
    local len = #self.m_itemDataList
    if len > 0 then
        local height = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
        local width = height * len
        table.insert(uiList, {node = self.m_nodeReward, scale = 0.3, alignX = 8 + 14 * (len - 1), size = cc.size(width * 0.3, height * 0.3)})
    end
    util_alignCenter(uiList)
end

function ObsidianCardTitleReward:carnivalCoinsAction()
    if self.m_factor > 1 then
        local baseCoins = self.m_baseCoins
        local interval = 1 / 30
        local rolls = 33
        local curStep = math.floor((baseCoins - self.m_curCoins) / rolls)

        self.m_scheduleId =
            schedule(
            self,
            function()
                self.m_curCoins = math.min(self.m_curCoins + curStep, baseCoins)
                self.m_lbCoin:setString(util_formatCoins(self.m_curCoins, 3))
                if #self.m_itemDataList > 0 then
                    self.m_lbCoin:setString(util_formatCoins(self.m_curCoins, 3) .. " +")
                end
                self:alignCoins()
                if self.m_curCoins >= baseCoins then
                    if self.m_scheduleId then
                        self:stopAction(self.m_scheduleId)
                        self.m_scheduleId = nil
                    end
                end
            end,
            interval
        )

        local _ts = (rolls + 2) * interval
        local _action = {}
        _action[1] = cc.EaseBackInOut:create(cc.ScaleTo:create(_ts, 1.2))
        _action[2] = cc.ScaleTo:create(0.1, 1)
        _action[3] =
            cc.CallFunc:create(
            function()
                self:playBaoZaAction()
            end
        )
        self.m_nodeCoin:runAction(cc.Sequence:create(_action))
    end
end

function ObsidianCardTitleReward:playBaoZaAction()
    local sp = util_createAnimation(SHOP_RES_PATH.CoinLizi)
    if sp then
        self.m_nodeCoin:addChild(sp, 10)
        sp:playAction(
            "start",
            false,
            function()
                sp:removeFromParent()
            end,
            60
        )
    end
end

function ObsidianCardTitleReward:initChips()
    local rewardData = self:getPhaseReward()
    if not rewardData then
        return
    end
    local chipNum = rewardData:getNum()
    self.m_lbChips:setString(chipNum .. " CHIPS")
end

function ObsidianCardTitleReward:getPhaseReward()
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData()
    if not data then
        return
    end
    return data:getPhaseRewardByIndex(self.m_index)
end

return ObsidianCardTitleReward
