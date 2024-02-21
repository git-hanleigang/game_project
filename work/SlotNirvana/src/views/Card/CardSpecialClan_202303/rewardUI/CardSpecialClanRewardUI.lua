--[[
    特殊卡册 领奖
]]
local CardSpecialClanRewardUI = class("CardSpecialClanRewardUI", BaseLayer)

function CardSpecialClanRewardUI:initDatas(_rewardData, _callBack)
    self.m_rewardData = _rewardData
    self.m_callBack = _callBack

    self.m_coinNum = self.m_rewardData:getCoins()

    self:setLandscapeCsbName("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/reward/MagicClanReward.csb")

    self:setPauseSlotsEnabled(true)
end

function CardSpecialClanRewardUI:initCsbNodes()
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")

    self.m_nodeBuffs = self:findChild("node_buffs")
    self.m_nodeClanIcon = self:findChild("node_clanIcon")
end

function CardSpecialClanRewardUI:initView()
    self:initCoins()
    self:initClanIcon()
    self:initBuffItems()
end

-- 金币
function CardSpecialClanRewardUI:initCoins()
    self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_coinNum))
    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.95},
            {node = self.m_lbCoin, scale = 0.60, alignX = 10}
        },
        nil,
        800
    )
end

function CardSpecialClanRewardUI:initClanIcon()
    local clanId = self.m_rewardData:getClanId()
    if clanId then
        local clanIcon = CardResConfig.getCardClanIcon(clanId)
        if clanIcon and util_IsFileExist(clanIcon) then
            local spClan = util_createSprite(clanIcon)
            if spClan then
                self.m_nodeClanIcon:addChild(spClan)
            end
        end
    end
end

function CardSpecialClanRewardUI:initBuffItems()
    local UIList = {}
    self.m_buffItems = {}
    local buffItems = self.m_rewardData:getBuffItems()
    if buffItems and #buffItems > 0 then
        for i=1,#buffItems do
            local itemData = buffItems[i]
            local mul = itemData:getBuffMultiple()
            if mul and mul ~= "" then
                local csbPath = self:getBuffCsbPath(itemData:getBuffType())
                if csbPath then
                    local buffNode = util_createView(self:getBuffLuaPath(), mul, csbPath)
                    if buffNode then
                        self.m_nodeBuffs:addChild(buffNode)
                        table.insert(self.m_buffItems, buffNode)
                        table.insert(UIList, {node = buffNode, size = cc.size(200, 200), anchor = cc.p(0.5, 0.5), scale = 1})
                    end
                end
            end
        end
    end
    util_alignCenter(UIList)
end

function CardSpecialClanRewardUI:playBuffsAction(_actionName)
    if self.m_buffItems and #self.m_buffItems > 0 then
        for i=1,#self.m_buffItems do
            local buff = self.m_buffItems[i]
            if _actionName == "idle" then
                buff:playIdle()
            elseif _actionName == "start" then
                buff:playStart()
            end
        end
    end
end

function CardSpecialClanRewardUI:getBuffLuaPath()
    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()
    return "views.Card." .. themeName .. ".rewardUI.CardSpecialClanRewardBuff"
end

function CardSpecialClanRewardUI:getBuffCsbPath(_buffType)
    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()
    if _buffType == BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST then
        return "CardRes/" .. themeName .. "/csb/reward/MagicClanRewardBuffQuest.csb"
    elseif _buffType == BUFFTYPY.BUFFTYPE_SPECIALCLAN_ALBUM then
        return "CardRes/" .. themeName .. "/csb/reward/MagicClanRewardBuffCard.csb"
    end
    return nil
end

--飞金币
function CardSpecialClanRewardUI:flyCoins()
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

function CardSpecialClanRewardUI:onClickMask()
    self:flyCoins()
end

function CardSpecialClanRewardUI:clickFunc(sender)
    if self.m_isFlyingIcons then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" or name == "btn_close" then
        self:flyCoins()
    end
end

function CardSpecialClanRewardUI:playShowAction()
    gLobalSoundManager:playSound("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/sound/collect_clan.mp3")
    local function userDefAction(_over)
        if not tolua.isnull(self) then
            self:runCsbAction("start", false, _over, 60)
            self:playBuffsAction("start")
        end
    end
    CardSpecialClanRewardUI.super.playShowAction(self, userDefAction)
end

function CardSpecialClanRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self:playBuffsAction("idle")
end

function CardSpecialClanRewardUI:closeUI(_over)
    CardSpecialClanRewardUI.super.closeUI(
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

return CardSpecialClanRewardUI
