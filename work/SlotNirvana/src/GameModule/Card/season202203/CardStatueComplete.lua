--[[
    -- 章节集齐面板
    author:{author}
    time:2020-04-16 11:29:36
]]
local CardClanComplete201903 = util_require("GameModule.Card.season201903.CardClanComplete")
local CardStatueComplete = class("CardStatueComplete", CardClanComplete201903)
function CardStatueComplete:updateClan()
    -- 数据处理
    local coins = self.m_params.clanReward.coins
    local rewards = self.m_params.clanReward.rewards
    local clanID = self.m_params.clanId
    local clanIcon = CardResConfig.getCardClanIcon(clanID)

    -- UI处理
    local root = self:findChild("tanban3")
    local clanLogo = self:findChild("clan_logo")
    local clanLogoNode = self:findChild("Node_clanlogo")
    self.m_bmf_coins = self:findChild("bmf_coins")
    local sp_coins = self:findChild("sp_coins")
    local spCoinParent = self:findChild("Panel_6")

    local UIList = {}
    table.insert(UIList, {node = sp_coins, anchor = cc.p(0.5, 0.5)})

    local itemDatas = {}
    local clanData = CardSysRuntimeMgr:getClanDataByClanId(clanID)
    if clanData and clanData.rewards and #clanData.rewards > 0 then
        for i = 1, #clanData.rewards do
            if clanData.rewards[i].p_type ~= "Buff" then
                itemDatas[#itemDatas + 1] = clone(clanData.rewards[i])
            end
        end
    end
    self.m_addStr = ""
    if #itemDatas > 0 then
        self.m_addStr = self.m_addStr .. " +"
        -- 金币
        self.m_bmf_coins:setString(util_formatCoins(coins, 33) .. self.m_addStr)
        local scale = self.m_bmf_coins:getScale()
        table.insert(UIList, {node = self.m_bmf_coins, alignX = 5, scale = scale, anchor = cc.p(0.5, 0.5)})
        -- 道具
        for i = 1, #itemDatas do
            local shopItemUI = gLobalItemManager:createRewardNode(itemDatas[i])
            if shopItemUI then
                shopItemUI:setScale(0.5)
                spCoinParent:addChild(shopItemUI)
                table.insert(UIList, {node = shopItemUI, alignX = 5, scale = 0.5, size = cc.size(128, 128), anchor = cc.p(0.5, 0.5)})
            end
        end
    else
        -- 金币
        self.m_bmf_coins:setString(util_formatCoins(coins, 33))
        util_scaleCoinLabGameLayerFromBgWidth(self.m_bmf_coins, 500, 0.98)
        local scale = self.m_bmf_coins:getScale()
        table.insert(UIList, {node = self.m_bmf_coins, alignX = 5, scale = scale, anchor = cc.p(0.5, 0.5)})
    end
    util_alignCenter(UIList)

    self.m_bmf_coins:setString("")
    util_changeTexture(clanLogo, clanIcon)

    self.m_startValue = tonumber(coins) * 0.5
    self.m_endValue = tonumber(coins)
    self.m_addValue = (self.m_endValue - self.m_startValue) / 15
    gLobalSoundManager:pauseBgMusic()
    performWithDelay(
        self,
        function()
            self.m_zhangjie = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteChinafortune)
        end,
        1
    )
    performWithDelay(
        self,
        function()
            self.m_done = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteDone)
        end,
        1.8
    )

    self:setCloseBtnVisible(false)
end

return CardStatueComplete
