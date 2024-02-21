--[[
    赛季基础类
    author:{author}
    time:2020-08-24 20:13:26
]]
local CardSeasonBase = class("CardSeasonBase")

-- 进入卡牌系统
function CardSeasonBase:enterCardSys()
end

-- 显示卡牌赛季选择界面
-- function CardSeasonBase:showCardSeasonView()
-- end

-- 显示卡组面板
function CardSeasonBase:showCardClanView(index, enterFromAlbum)
end

-- 显示大卡面板
function CardSeasonBase:showBigCardView(cardData)
end

-- 显示以往赛季
function CardSeasonBase:showCardCollectionUI()
end
-- ====================掉落========================
-- 创建掉卡界面
function CardSeasonBase:createDropCardView(tDropInfo)
end
function CardSeasonBase:createDropCardViewV2(tDropInfo)
end

-- 显示掉落步骤2
-- function CardSeasonBase:showDropStep2(tDropInfo)
-- end

-- 创建章节完成界面
function CardSeasonBase:createCardClanComplete(...)
end

-- 创建轮次完成界面
function CardSeasonBase:createCardRoundOpen(...)
    return nil
end

-- 创建赛季完成界面
function CardSeasonBase:createCardAlbumComplete(...)
end

-- 创建神像小游戏完成界面
function CardSeasonBase:createCardSpecialGameComplete(...)
end

-- 创建小游戏buff节点
function CardSeasonBase:createCardSpecialGameBuffNode(...)
end
-- =============================================

-- 创建卡牌
function CardSeasonBase:createCardItemView(cardData)
end

-- 赛季完成界面
function CardSeasonBase:showCardAlbumComplete(params)
end

-- 章节完成界面
function CardSeasonBase:showCardClanComplete(params)
end

-- ======================Nado========================
-- Nado机主界面
function CardSeasonBase:createNadoMachineMain()
    return util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelMainUI")
end

-- nado卡获得进度界面
function CardSeasonBase:createCardLinkProgressComplete(params)
    return util_createView(self.m_linkProgress, params)
end

-- nado卡完成界面
function CardSeasonBase:createCardLinkComplete(params)
end
-- ====================================================
-- ======================回收机=========================
-- 回收机主界面
function CardSeasonBase:createCardRevoverMain()
    local _cardRecoverView = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverView")
    return _cardRecoverView
end

-- 回收机规则
function CardSeasonBase:createCardRevoverRule()
    local _cardRecoverRule = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverRule")
    return _cardRecoverRule
end

-- 回收机兑换
function CardSeasonBase:createCardRevoverExchange()
    local _cardRecoverExc = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeView")
    return _cardRecoverExc
end

-- 回收机乐透
function CardSeasonBase:createCardRevoverLetto()
    local _recoverWheelUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverLetto")
    return _recoverWheelUI
end

-- ====================================================
-- ======================历史===========================
-- 卡牌历史主界面
function CardSeasonBase:createCardHistoryMain(...)
    return util_createView("GameModule.Card.commonViews.CardHistory.CardHistoryView", ...)
end

-- 卡牌历史记录图标
function CardSeasonBase:createCardHistoryCardIcon()
end
-- ====================================================
-- =======================Wild卡兑换====================
-- wild兑换主界面
function CardSeasonBase:createWildExchangeMain(...)
    return util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildExcView", ...)
end

-- 关闭兑换时二次确认界面
function CardSeasonBase:createWildExchangeExit(...)
    return util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildExit", ...)
end

-- 兑换时二次确认界面
function CardSeasonBase:createWildExchangeConfirm(...)
    return util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildConfirm", ...)
end
-- ====================================================
return CardSeasonBase
