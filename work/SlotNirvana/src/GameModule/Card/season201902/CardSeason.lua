--[[
    赛季类
    author:{author}
    time:2020-08-24 20:13:26
]]
local CardSeasonBase = require("GameModule.Card.CardSeasonBase")
local CardSeason = class("CardSeason", CardSeasonBase)

function CardSeason:getLinkCompleteCsbName()
    return string.format(CardResConfig.commonRes.linkComplete201902, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getLinkProgressCsbName()
    return string.format(CardResConfig.commonRes.linkProgress201902, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getClanCompleteCsbName(_clanId)
    local albumId = string.sub(tostring(_clanId), 1, 6)
    return "CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/CardComplete" .. albumId .. "_zhangjie.csb"
    -- return string.format(CardResConfig.commonRes.clanComplete201902, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getAlbumCompleteCsbName(_albumId)
    return "CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/CardComplete" .. _albumId .. "_saiji.csb"
    -- return string.format(CardResConfig.commonRes.albumComplete201902, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

-- 进入卡牌系统
function CardSeason:enterCardSys()
    -- 移除消息等待面板 --
    gLobalViewManager:removeLoadingAnima()

    -- 从这里开始进入集卡系统 --
    CardSysManager:showCardAlbumView(true)
    CardSysManager:enterCard()
end

-- 显示卡牌赛季选择界面
-- function CardSeason:showCardSeasonView()
--     return util_createView("GameModule.Card.season201902.CardSeasonView")
-- end

-- 显示卡组面板
function CardSeason:showCardClanView(index, enterFromAlbum)
    return util_createView("GameModule.Card.season201902.CardClanView", index, enterFromAlbum)
end

-- 显示大卡面板
function CardSeason:showBigCardView(clanIndex, cardIndex)
    return util_createView("GameModule.Card.season201902.BigCardLayer", clanIndex, cardIndex)
end

-- 显示掉卡界面
function CardSeason:createDropCardView(tDropInfo)
    if globalDynamicDLControl:checkDownloading("CardsBase201902") then
        return
    end
    if not util_IsFileExist(CardResConfig.seasonRes.CardDropView201902Res) then
        return
    end
    return util_createView("GameModule.Card.season201902.CardDropView", tDropInfo)
end

-- 显示掉落步骤2
-- function CardSeason:showDropStep2(tDropInfo)
--     if not tDropInfo then
--         return false
--     end

--     return false
-- end

-- 创建章节完成
function CardSeason:createCardClanComplete(clanRewardData, callback)
    if clanRewardData then
        local clanParams = {
            csb = self:getClanCompleteCsbName(clanRewardData.id),
            clanId = clanRewardData.id,
            clanReward = clanRewardData,
            callback = callback
        }

        -- self:showCardClanComplete(clanParams)
        return util_createView("GameModule.Card.views.CardClanComplete", clanParams)
    else
        return nil
    end
end

-- 创建赛季完成界面
function CardSeason:createCardAlbumComplete(albumReward)
    local params = {
        csb = self:getAlbumCompleteCsbName(albumReward.id),
        coins = albumReward.coins,
        rewards = albumReward.rewards,
        albumId = albumReward.id
    }
    -- CardSysManager:showCardCollectComplete(params)
    -- self:showCardAlbumComplete(params)
    return util_createView("GameModule.Card.views.CardAlbumComplete", params)
end

-- 创建卡牌
function CardSeason:createCardItemView(cardData)
    if not cardData then
        return nil
    end

    if cardData.type == CardSysConfigs.CardType.puzzle then
        -- 拼图卡
        return util_createView("GameModule.Card.views.PuzzleCardUnitView", cardData, "idle")
    else
        return util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "idle", true, false, false)
    end
end

-- 赛季完成界面
-- function CardSeason:showCardAlbumComplete(params)
--     local _albumComplete = util_createView("GameModule.Card.views.CardAlbumComplete", params)
--     gLobalViewManager:showUI(_albumComplete, ViewZorder.ZORDER_UI)
--     CardSysManager:setAlbumCompleteUI(_albumComplete)
-- end

-- 章节完成界面
-- function CardSeason:showCardClanComplete(params)
--     local _clanComplete = util_createView("GameModule.Card.views.CardClanComplete", params)
--     gLobalViewManager:showUI(_clanComplete, ViewZorder.ZORDER_UI)
--     CardSysManager:setClanCompleteUI(_clanComplete)
-- end

-- nado卡获得进度界面
function CardSeason:createCardLinkProgressComplete(params)
    local _linkProgressComplete = util_createView("GameModule.Card.views.CardLinkProgressComplete", params)
    return _linkProgressComplete
end

-- nado卡完成界面
function CardSeason:createCardLinkComplete(params)
    local _linkOverComplete = util_createView("GameModule.Card.views.CardLinkComplete", params)
    return _linkOverComplete
end

-- 卡牌历史记录图标
function CardSeason:createCardHistoryCardIcon()
    return util_createView("GameModule.Card.commonViews.CardHistory.CardHistoryCard201902")
end

return CardSeason
