--[[
    特殊卡册 领奖
    所有章节都完成的赛季奖励
]]
local CardSpecialAlbumRewardUI = class("CardSpecialAlbumRewardUI", BaseLayer)

function CardSpecialAlbumRewardUI:initDatas(_rewardData, _callBack)
    self.m_rewardData = _rewardData
    self.m_callBack = _callBack

    self.m_coinNum = self.m_rewardData:getCoins()

    self:setLandscapeCsbName("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/reward/MagicAlbumReward.csb")

    self:setPauseSlotsEnabled(true)
end

function CardSpecialAlbumRewardUI:initCsbNodes()
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
end

function CardSpecialAlbumRewardUI:initView()
    -- 金币
    self.m_lbCoin:setString(util_getFromatMoneyStr(self.m_coinNum))
    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.95},
            {node = self.m_lbCoin, scale = 0.6, alignX = 10}
        },
        nil,
        800
    )
end

--飞金币
function CardSpecialAlbumRewardUI:flyCoins()
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

function CardSpecialAlbumRewardUI:onClickMask()
    self:flyCoins()
end

function CardSpecialAlbumRewardUI:clickFunc(sender)
    if self.m_isFlyingIcons then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" or name == "btn_close" then
        self:flyCoins()
    end
end

function CardSpecialAlbumRewardUI:playShowAction()
    gLobalSoundManager:playSound("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/sound/collect_album.mp3")
    CardSpecialAlbumRewardUI.super.playShowAction(self, "start")
end

function CardSpecialAlbumRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardSpecialAlbumRewardUI:closeUI(_over)
    CardSpecialAlbumRewardUI.super.closeUI(
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

return CardSpecialAlbumRewardUI
