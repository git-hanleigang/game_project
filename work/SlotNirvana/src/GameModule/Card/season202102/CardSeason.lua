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
    self.m_cardClanUI = "GameModule.Card.season202102.CardClanView"
    -- 卡册弹框
    self.m_bigCardUI = "GameModule.Card.season202102.BigCardLayer"
    -- nado卡获得进度界面
    self.m_linkProgress = "GameModule.Card.season202102.CardLinkProgressComplete"
    -- 章节完成界面
    -- self.m_clanCompleteLua = "GameModule.Card.season202102.CardClanComplete"
    self.m_statueCompleteLua = "GameModule.Card.season202102.CardStatueComplete"
    self.m_stateuClanLua = "GameModule.CardMiniGames.Statue.StatueClan.StatueMainLayer"
    self.m_statueEntryNodeLua = "GameModule.CardMiniGames.Statue.StatueClan.StatueEntryNode"
end

function CardSeason:getLinkProgressCsbName()
    return string.format(CardResConfig.commonRes.linkProgress201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getClanCompleteCsbName(_clanId)
    local _clanData = CardSysRuntimeMgr:getClanDataByClanId(_clanId)
    if _clanData then
        if CardSysRuntimeMgr:isStatueClan(_clanData.type) then
            return string.format(CardResConfig.commonRes.statueClanComplete202102, "common" .. CardSysRuntimeMgr:getCurAlbumID())
        end
    end
    return CardSeason.super.getClanCompleteCsbName(self, _clanId)
    -- return string.format(CardResConfig.commonRes.clanComplete202102, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getPuzzlePageLuaName()
    return nil
end

function CardSeason:getPuzzleGameLuaName()
    return nil
end

-- 章节完成界面
-- function CardSeason:showCardClanComplete(params)
--     if params and params.csb ~= nil then
--         local luaName = self.m_clanCompleteLua
--         if params.clanId then
--             local _clanData = CardSysRuntimeMgr:getClanDataByClanId(params.clanId)
--             if _clanData then
--                 if CardSysRuntimeMgr:isStatueClan(_clanData.type) then
--                     luaName = self.m_statueCompleteLua
--                 end
--             end
--         end
--         local clanComplete = util_createView(luaName, params)
--         gLobalViewManager:showUI(clanComplete, ViewZorder.ZORDER_UI)
--         CardSysManager:setClanCompleteUI(clanComplete)
--         return clanComplete
--     end
-- end

-- 创建小游戏完成界面
function CardSeason:createCardSpecialGameComplete(rewardData, callback)
    if rewardData then
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
    local statueBuffUI = util_createView("views.buffTip.CardStatueBuffTipNode", buffMultiple)
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
