--[[
    特殊卡册-购物主题 领奖
]]
local ObsidianCardRewardUI = class("ObsidianCardRewardUI", BaseLayer)

function ObsidianCardRewardUI:initDatas(_rewardData, _callBack)
    self.m_rewardData = _rewardData
    self.m_callBack = _callBack

    self.m_coinNum = self.m_rewardData:getCoins()
    self.m_rewards = self.m_rewardData:getRewards()

    self.m_isTop = self:isTop()
    local csbPath = "CardRes/CardObsidian_2/csb/reward/Season_Reward_normal.csb"
    if self.m_isTop then
        csbPath = "CardRes/CardObsidian_2/csb/reward/Season_Reward_high.csb"
    end

    self:setLandscapeCsbName(csbPath)

    self:setPauseSlotsEnabled(true)
end

function ObsidianCardRewardUI:initCsbNodes()
    self.m_lbTitle = self:findChild("lb_title_small")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_nodeReward = self:findChild("node_reward")
end

function ObsidianCardRewardUI:initView()
    -- 标题
    if not self.m_isTop then
        local chipNum = self.m_rewardData:getPhaseChips()
        local str = gLobalLanguageChangeManager:getStringByKey("ObsidianCardRewardUI:lb_title_small")
        self.m_lbTitle:setString(string.format(str, chipNum))
    end
    -- 金币
    self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_coinNum))
    self:updateLabelSize({label = self.m_lbCoin, sx = 0.71, sy = 0.71}, 892)
    util_alignCenter(
        {
            {node = self.m_spCoin},
            {node = self.m_lbCoin, alignX = 10}
        }
    )

    self:initReward()
end

--飞金币
function ObsidianCardRewardUI:flyCoins()
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

function ObsidianCardRewardUI:onClickMask()
    self:flyCoins()
end

function ObsidianCardRewardUI:clickFunc(sender)
    if self.m_isFlyingIcons then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" then
        self:flyCoins()
    end
end

function ObsidianCardRewardUI:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    ObsidianCardRewardUI.super.playShowAction(self, "start")
end

function ObsidianCardRewardUI:playHideAction()
    ObsidianCardRewardUI.super.playHideAction(self, "over")
end

function ObsidianCardRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function ObsidianCardRewardUI:closeUI(_over)
    ObsidianCardRewardUI.super.closeUI(
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
function ObsidianCardRewardUI:isTop()
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

function ObsidianCardRewardUI:initReward()
    -- 通用道具
    local itemDataList = {}
    if self.m_rewards and #self.m_rewards > 0 then
        for i, v in ipairs(self.m_rewards) do
            if v.p_icon and v.p_num then
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
    end

    local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
    if itemNode then
        self.m_nodeReward:addChild(itemNode)
        util_setCascadeOpacityEnabledRescursion(self.m_nodeReward, true)
    end
end

return ObsidianCardRewardUI
