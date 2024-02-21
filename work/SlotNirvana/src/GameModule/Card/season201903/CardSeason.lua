--[[
    赛季类
    author:{author}
    time:2020-08-24 20:13:26
]]
local CardSeasonBase = require("GameModule.Card.CardSeasonBase")
local CardSeason = class("CardSeason", CardSeasonBase)

function CardSeason:ctor()
    CardSeason.super.ctor(self)
    -- 卡册界面
    self.m_cardClanUI = "GameModule.Card.season201903.CardClanView"
    -- 卡册弹框
    self.m_bigCardUI = "GameModule.Card.season201903.BigCardLayer"
    -- 显示以往赛季
    self.m_collectionUI = "GameModule.Card.season201903.CardCollectionUI"
    -- 掉落界面
    self.m_cardDropUI = "GameModule.Card.commonViews.CardDrop.CardDropViewNew"
    self.m_cardDropUIV2 = "GameModule.Card.commonViews.CardDropV2.CardDropViewNew"

    -- 卡牌单元
    self.m_cardItemUI = "GameModule.Card.season201903.MiniChipUnit"
    -- 赛季完成界面
    self.m_albumCompleteLua = "GameModule.Card.season201903.CardAlbumComplete"
    -- 章节完成界面
    self.m_clanCompleteLua = "GameModule.Card.season201903.CardClanComplete"
    -- nado卡获得进度界面
    self.m_linkProgress = "GameModule.Card.season201903.CardLinkProgressComplete"
    -- nado卡完成界面
    self.m_linkCompleteLua = "GameModule.Card.season201903.CardLinkComplete"
    -- 卡牌历史记录icon
    self.m_cardHistoryCardIconLua = "GameModule.Card.commonViews.CardHistory.CardHistoryCard201903"
end

-- 创建轮次完成界面
function CardSeason:createCardRoundOpen(_nextRound, callback)
    if self.m_roundCompleteLua then
        return util_createView(self.m_roundCompleteLua, _nextRound, callback)
    end
    return nil
end

function CardSeason:getLinkProgressCsbName()
    return string.format(CardResConfig.commonRes.linkProgress201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

-- 使用 _clanId 赛季的代码
function CardSeason:getClanCompleteLuaName()
    return self.m_clanCompleteLua
end

-- 使用 当前赛季的 _clanId 赛季的工程
function CardSeason:getClanCompleteCsbName(_clanId)
    local albumId = string.sub(tostring(_clanId), 1, 6)
    return "CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/CardComplete" .. albumId .. "_zhangjie.csb"
    -- return string.format(CardResConfig.commonRes.clanComplete201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

-- 使用 _albumId 赛季的代码
function CardSeason:getAlbumCompleteLuaName()
    return self.m_albumCompleteLua
end

-- 使用 当前赛季的 _albumId 赛季的工程
function CardSeason:getAlbumCompleteCsbName(_albumId)
    return "CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/CardComplete" .. _albumId .. "_saiji.csb"
    -- return string.format(CardResConfig.commonRes.albumComplete201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

-- 进入卡牌系统
function CardSeason:enterCardSys(callback,fileFunc)
    -- 强制跳转到卡册界面
    local gotoClanId = CardSysManager:getEnterClanId()
    if gotoClanId then
        local successFunc = function()
            -- 移除消息等待面板 --
            gLobalViewManager:removeLoadingAnima()

            -- 遍历章节数据，找到含有link卡的章节，直接定位到此章节面板 --
            local firsClanHaveLinkGame = CardSysRuntimeMgr:getFirstClanCanPlayLinkGame(gotoClanId)
            CardSysManager:showCardClanView(firsClanHaveLinkGame)

            -- 从这里开始进入集卡系统 --
            local albumId = CardSysRuntimeMgr:getCurAlbumID()
            CardSysRuntimeMgr:setSelAlbumID(albumId)
            CardSysManager:enterCard()
                        
            if fileFunc then
                fileFunc()
            end
        end

        local yearID = CardSysRuntimeMgr:getCurrentYear()
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local tExtraInfo = {year = yearID, albumId = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, successFunc)
        CardSysManager:setEnterClanId(false)
        return
    end

    -- step 1 ，判断是否有 wild 卡 --
    if not CardSysRuntimeMgr:getIgnoreWild() then
        local hasWild, wildType = CardSysRuntimeMgr:hasWildCardData()
        if not hasWild then
            hasWild, wildType = G_GetMgr(G_REF.ObsidianCard):hadWildCardData()
        end
        if hasWild then
            -- wild卡可兑换的年度所有卡片数据接口 --
            local _callback = function()
                if fileFunc then
                    fileFunc()
                end
            end
            if wildType == CardSysConfigs.CardType.wild_obsidian then
                -- 黑耀卡 走 黑耀卡wild兑换逻辑
                G_GetMgr(G_REF.ObsidianCard):doDropWildLogic(_callback, "lobby", fileFunc)
            elseif wildType == CardSysConfigs.CardType.wild_magic or wildType == CardSysConfigs.CardType.wild_magic_red
            or wildType == CardSysConfigs.CardType.wild_magic_purple then
                -- Magic卡 走 Magic卡wild兑换逻辑
                G_GetMgr(G_REF.CardSpecialClan):doDropWildLogic(wildType, _callback, "lobby", fileFunc)
            else
                CardSysManager:showWildExchangeView(wildType, _callback, "lobby", fileFunc)
            end
            return
        end
    else
        CardSysRuntimeMgr:setIgnoreWild(nil)
    end

    -- 设置当前章节数据
    local albumId = CardSysRuntimeMgr:getCurAlbumID() -- "201903"
    CardSysRuntimeMgr:setSelAlbumID(albumId)

    local tExtraInfo = {["year"] = CardSysRuntimeMgr:getCurrentYear(), ["albumId"] = albumId}
    CardSysNetWorkMgr:sendCardsAlbumRequest(
        tExtraInfo,
        function()
            -- 移除消息等待面板 --
            gLobalViewManager:removeLoadingAnima()

            -- 从这里开始进入集卡系统 --
            CardSysManager:showCardAlbumView(true, callback)

            CardSysManager:enterCard()
            if fileFunc then
                fileFunc()
            end
        end,
        function()
            -- 移除消息等待面板 --
            gLobalViewManager:removeLoadingAnima()
            if fileFunc then
                fileFunc()
            end
        end
    )
end

-- 显示卡牌赛季选择界面
-- function CardSeason:showCardSeasonView()
--     return util_createView(self.m_cardSeasonUI)
-- end

-- 显示卡组面板
function CardSeason:showCardClanView(index, enterFromAlbum)
    return util_createView(self.m_cardClanUI, index, enterFromAlbum)
end

-- 显示大卡面板
function CardSeason:showBigCardView(cardData)
    return util_createView(self.m_bigCardUI, cardData)
end

-- 显示以往赛季
function CardSeason:showCardCollectionUI()
    return util_createView(self.m_collectionUI)
end

-- 显示掉卡界面
function CardSeason:createDropCardView(tDropInfo)
    return util_createView(self.m_cardDropUI, tDropInfo)
end
function CardSeason:createDropCardViewV2(tDropInfo)
    return util_createView(self.m_cardDropUIV2, tDropInfo)
end

-- 创建章节完成界面
function CardSeason:createCardClanComplete(clanRewardData, callback)
    if clanRewardData then
        local clanParams = {
            csb = self:getClanCompleteCsbName(clanRewardData.id),
            clanId = clanRewardData.id,
            clanReward = clanRewardData,
            callback = callback
        }

        -- self:showCardClanComplete(clanParams)
        return util_createView(self:getClanCompleteLuaName(), clanParams)
    else
        return nil
    end
end

-- 创建赛季完成界面
function CardSeason:createCardAlbumComplete(albumReward, callback)
    local params = {
        csb = self:getAlbumCompleteCsbName(albumReward.id),
        coins = albumReward.coins,
        rewards = albumReward.rewards,
        albumId = albumReward.id,
        callback = callback
    }
    return util_createView(self:getAlbumCompleteLuaName(), params)
end

-- 创建卡牌
function CardSeason:createCardItemView(cardData)
    local cardView = util_createView(self.m_cardItemUI)
    cardView:playIdle()
    if cardData then
        cardView:reloadUI(cardData, true)
    end
    return cardView
end

-- nado卡完成界面
function CardSeason:createCardLinkComplete(params)
    local linkOverComplete = util_createView(self.m_linkCompleteLua, params)
    return linkOverComplete
end

-- 卡牌历史记录图标
function CardSeason:createCardHistoryCardIcon()
    return util_createView(self.m_cardHistoryCardIconLua)
end

return CardSeason
