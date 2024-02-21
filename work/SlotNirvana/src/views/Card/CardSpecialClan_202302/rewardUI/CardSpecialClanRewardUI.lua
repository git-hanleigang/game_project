--[[
    特殊卡册 领奖
]]
local CardSpecialClanRewardUI = class("CardSpecialClanRewardUI", BaseLayer)

function CardSpecialClanRewardUI:initDatas(_rewardData, _callBack)
    self.m_rewardData = _rewardData
    self.m_callBack = _callBack

    self.m_coinNum = self.m_rewardData:getCoins()
    self.m_chipNum = self.m_rewardData:getPhaseChips()

    self:setLandscapeCsbName("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/reward/MagicAlbum_Reward.csb")

    self:setPauseSlotsEnabled(true)
end

function CardSpecialClanRewardUI:initCsbNodes()
    self.m_lbTitle = self:findChild("lb_title_small")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
end

function CardSpecialClanRewardUI:initView()
    -- 标题
    local str = gLobalLanguageChangeManager:getStringByKey("CardSpecialClanRewardUI:lb_title_small")
    self.m_lbTitle:setString(string.format(str, self.m_chipNum))
    -- 金币
    self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_coinNum))
    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.95},
            {node = self.m_lbCoin, scale = 0.74, alignX = 10}
        },
        nil,
        770
    )
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
    if name == "btn_collect" then
        self:flyCoins()
    end
end

function CardSpecialClanRewardUI:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardSpecialClanRewardUI.super.playShowAction(self, "start")
end

function CardSpecialClanRewardUI:playHideAction()
    CardSpecialClanRewardUI.super.playHideAction(self, "over")
end

function CardSpecialClanRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
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
