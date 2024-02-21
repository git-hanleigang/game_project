--[[
    特殊卡册-购物主题 领奖
]]
local ObsidianCardJackpotRewardUI = class("ObsidianCardJackpotRewardUI", BaseLayer)

function ObsidianCardJackpotRewardUI:initDatas(_coins, _percent, _callBack)
    self.m_coinNum = _coins or  0
    self.m_percent = _percent or 0
    self.m_callBack = _callBack

    self:setLandscapeCsbName("CardRes/CardObsidian_4/csb/reward/Season_Reward_Jackpot.csb")
    self:setPauseSlotsEnabled(true)
end

function ObsidianCardJackpotRewardUI:initCsbNodes()
    self.m_lbTitle = self:findChild("lb_title_small")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    -- self.m_nodeReward = self:findChild("node_reward")
end

function ObsidianCardJackpotRewardUI:initView()
    self.m_lbTitle:setString("YOU WON MORE THAN " .. self.m_percent .. "% OF PLAYERS")
    -- 金币
    self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_coinNum))
    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.95},
            {node = self.m_lbCoin, scale = 0.71, alignX = 2}
        },
        nil,
        730
    )
    -- self:initReward()
end

--飞金币
function ObsidianCardJackpotRewardUI:flyCoins()
    if self.m_coinNum <= 0 then
        self:closeUI()
        return
    end
    self.m_isFlyingIcons = true
    local rewardCoins = self.m_coinNum
    local coinNode = self.m_btnCollect
    local senderSize = coinNode:getContentSize()
    local startPos = coinNode:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
    G_GetMgr(G_REF.Currency):playFlyCurrency(
        {cuyType = FlyType.Coin, addValue = rewardCoins, startPos = startPos},
        function()
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end
    )
end

function ObsidianCardJackpotRewardUI:onClickMask()
    self:flyCoins()
end

function ObsidianCardJackpotRewardUI:clickFunc(sender)
    if self.m_isFlyingIcons then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" then
        self:flyCoins()
    end
end

function ObsidianCardJackpotRewardUI:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    ObsidianCardJackpotRewardUI.super.playShowAction(self, "start")
end

function ObsidianCardJackpotRewardUI:playHideAction()
    ObsidianCardJackpotRewardUI.super.playHideAction(self, "over")
end

function ObsidianCardJackpotRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function ObsidianCardJackpotRewardUI:closeUI(_over)
    ObsidianCardJackpotRewardUI.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            if self.m_callBack then
                self.m_callBack()
            end
        end
    )
end

-- 是否是最后一个奖励（大奖）
function ObsidianCardJackpotRewardUI:isTop()
    local isTop = false
    -- 通用道具
    if self.m_rewards and #self.m_rewards > 0 then
        for i, v in ipairs(self.m_rewards) do
            if v.p_icon and string.find(v.p_icon, "PropFrame_") then
                return true
            end
        end
    end
    return isTop
end

-- function ObsidianCardJackpotRewardUI:initReward()
--     -- 通用道具
--     local itemDataList = {}
--     if self.m_rewards and #self.m_rewards > 0 then
--         for i, v in ipairs(self.m_rewards) do
--             if v.p_icon and v.p_num then
--                 itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
--             end
--         end
--     end
--     local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
--     if itemNode then
--         self.m_nodeReward:addChild(itemNode)
--         util_setCascadeOpacityEnabledRescursion(self.m_nodeReward, true)
--     end
-- end

return ObsidianCardJackpotRewardUI
