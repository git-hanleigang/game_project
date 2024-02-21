--[[
    赛季类
    author:{author}
    time:2020-08-24 20:13:26
]]
local CardSeason201903 = require("GameModule.Card.season201903.CardSeason")
local CardSeason = class("CardSeason", CardSeason201903)

function CardSeason:ctor()
    CardSeason.super.ctor(self)
    -- 卡册界面
    self.m_cardClanUI = "GameModule.Card.season202303.CardClanView"
    -- 卡册弹框
    self.m_bigCardUI = "GameModule.Card.season202303.BigCardLayer"
    -- 显示以往赛季
    self.m_collectionUI = "GameModule.Card.season202303.CardCollectionUI"
    -- nado卡获得进度界面
    self.m_linkProgress = "GameModule.Card.season202303.CardLinkProgressComplete"
    -- 赛季完成界面
    self.m_albumCompleteLua = "GameModule.Card.season202303.CardAlbumComplete"
    -- 章节完成界面
    self.m_clanCompleteLua = "GameModule.Card.season202303.CardClanComplete"
    -- self.m_statueCompleteLua = "GameModule.Card.season202303.CardStatueComplete"
    self.m_stateuClanLua = "GameModule.CardMiniGames.Statue.StatueClan.StatueMainLayer"
    self.m_statueEntryNodeLua = "GameModule.CardMiniGames.Statue.StatueClan.StatueEntryNode"
    self.m_roundCompleteLua = "GameModule.Card.season202303.CardRoundComplete"
end

function CardSeason:getLinkProgressCsbName()
    return string.format(CardResConfig.commonRes.linkProgress201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getPuzzlePageLuaName()
    return nil
end

function CardSeason:getPuzzleGameLuaName()
    return nil
end


-- 创建神像小游戏完成界面
function CardSeason:createCardSpecialGameComplete(rewardData, callback)
    if rewardData and self.m_statueCompleteLua then
        local params = {
            csb = self:getClanCompleteCsbName(rewardData.id),
            clanId = rewardData.id,
            clanReward = rewardData
        }

        -- self:showCardClanComplete(clanParams)
        return util_createView(self.m_statueCompleteLua, params)
    else
        return nil
    end
end

-- 创建小游戏buff节点
function CardSeason:createCardSpecialGameBuffNode(buffMultiple)
    local statueBuffUI = util_createView("GameModule.Card.season202303.CardBuffTipNode", buffMultiple)
    return statueBuffUI
end

function CardSeason:showStatueClanUI(openSource)
    local view = util_createView(self.m_stateuClanLua, openSource)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardSeason:getStatueEntryNode()
    return self.m_statueEntryNodeLua
end

return CardSeason
