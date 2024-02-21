--[[
    集卡系统 WILD兑换管理
--]]
local CardSysWildExchangeRunData = util_require("GameModule.Card.CardSysWildExchangeRunData")
local CardSysWildExchangeManager = class("CardSysWildExchangeManager")

-- ctor
function CardSysWildExchangeManager:ctor()
    self:reset()
    self:initBaseData()
end

-- do something reset --
function CardSysWildExchangeManager:reset()
end

-- init --
function CardSysWildExchangeManager:initBaseData()
    self.m_runningData = CardSysWildExchangeRunData:create()
end

function CardSysWildExchangeManager:getRunData()
    return self.m_runningData
end

-- 每秒调用刷新 --
function CardSysWildExchangeManager:onUpdateTimer(dt)
    self:initWildCountTime(dt)
end

-- 所有wild卡倒计管理 --
function CardSysWildExchangeManager:initWildCountTime(dt)
    local isHaveWild = CardSysRuntimeMgr:hasWildCardData() or G_GetMgr(G_REF.ObsidianCard):hadWildCardData()
    if self.m_lastHaveWild ~= nil then
        if self.m_lastHaveWild ~= isHaveWild then
            self.m_lastHaveWild = isHaveWild
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO)
        end
    else
        self.m_lastHaveWild = isHaveWild
    end
end

---------------------------------------------------------------------------------------------------
---------------------------------------界面模块处理--------------------------------------------------
function CardSysWildExchangeManager:showWildExcUI(callFunc1, enterType, fileFunc)
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.ExcView = curLogic:createWildExchangeMain(callFunc1, enterType, fileFunc)
        if gLobalSendDataManager.getLogPopub and CardSysManager.sourceName then
            gLobalSendDataManager:getLogPopub():addNodeDot(self.ExcView, CardSysManager.sourceName, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
            CardSysManager.sourceName = nil
        end
        gLobalViewManager:showUI(self.ExcView, ViewZorder.ZORDER_UI)
    end
end

-- 关闭兑换面板 --
function CardSysWildExchangeManager:closeWildExcView(closeType)
    if self.ExcView ~= nil and self.ExcView.closeUI then
        self.ExcView:closeUI(closeType)
        self.ExcView = nil
    end
end

-- 关闭兑换时二次确认界面 --
function CardSysWildExchangeManager:showWildExit(callFunc)
    if self.m_wildExit then
        return
    end
    -- self.m_wildExit = util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildExit", callFunc)
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.m_wildExit = curLogic:createWildExchangeExit(callFunc)
        gLobalViewManager:showUI(self.m_wildExit, ViewZorder.ZORDER_UI)
    end
end
function CardSysWildExchangeManager:closeWildExit()
    if self.m_wildExit ~= nil and self.m_wildExit.closeUI then
        self.m_wildExit:closeUI()
    end
    self.m_wildExit = nil
end

-- 兑换时二次确认界面 --
function CardSysWildExchangeManager:showWildConfirm(cardData, yesCallFunc, overCall)
    if self.m_wildConfirm then
        return
    end
    -- self.m_wildConfirm = util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildConfirm", cardData, yesCallFunc)
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.m_wildConfirm = curLogic:createWildExchangeConfirm(cardData, yesCallFunc)
        gLobalViewManager:showUI(self.m_wildConfirm, ViewZorder.ZORDER_UI)
        self.m_wildConfirm:setOverFunc(
            function()
                if overCall then
                    overCall()
                end
            end
        )
    end
end
function CardSysWildExchangeManager:closeWildConfirm()
    if self.m_wildConfirm ~= nil and self.m_wildConfirm.closeUI then
        self.m_wildConfirm:closeUI()
    end
    self.m_wildConfirm = nil
end
---------------------------------------界面模块处理--------------------------------------------------
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
---------------------------------------协议模块处理--------------------------------------------------

-- 显示wild兑换面板 --
function CardSysWildExchangeManager:sendExchangeRequest(wildType, success, fail)
    -- wildType = wildType or CardSysConfigs.CardType.wild -- 默认全能卡
    assert(wildType ~= nil, "!!!wildType must be not null")

    local function tSuccess(tData)
        self:getRunData():setCardExchangeYearCardsInfo(tData)
        if success then
            success()
        end
    end

    local function tFail(errorCode, errorData)
        if fail then
            fail(errorCode, errorData)
        end
    end

    self:setCurrentWildExchangeType(wildType)

    -- 理论上需要有所有的卡册信息 才能显示面板 --
    local tExtraInfo = {["year"] = -1, ["type"] = self:getCurrentWildExchangeType()}
    CardSysNetWorkMgr:sendCardExchangeYearCardsRequest(tExtraInfo, tSuccess, tFail)
end

function CardSysWildExchangeManager:sendCardExchangeRequest(tExtraInfo, excSuccess, excFaild)
    local tExcSuccess = function(tData)
        self:getRunData():setCardExchangeInfo(tData)
        self:closeWildExcView(2)
        if excSuccess then
            excSuccess()
        end
    end
    local tExcFaild = function(errorCode, errorData)
        self:closeWildExcView(2)
        if excFaild then
            excFaild()
        end
    end
    CardSysNetWorkMgr:sendCardExchangeRequest(tExtraInfo, tExcSuccess, tExcFaild)
end
----------------------------------------协议模块处理-------------------------------------------------
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
----------------------------------------数据模块处理-------------------------------------------------
-- 是否显示全部卡片
function CardSysWildExchangeManager:setShowAll(_isShowAll)
    self.m_isShowAll = _isShowAll
end

function CardSysWildExchangeManager:getShowAll()
    return self.m_isShowAll
end

-- wild兑换中选中的卡牌id
function CardSysWildExchangeManager:setSelCardId(_cardId)
    self.m_selCardId = _cardId
end

function CardSysWildExchangeManager:getSelCardId()
    return self.m_selCardId
end

-- wild兑换界面打开时wild卡的类型
function CardSysWildExchangeManager:setCurrentWildExchangeType(_curType)
    self.m_currentWildExchangeType = _curType
end

function CardSysWildExchangeManager:getCurrentWildExchangeType()
    return self.m_currentWildExchangeType
end

function CardSysWildExchangeManager:canExchangeWildCard()
    local cardsInfo = self:getRunData():getCardExchangeYearCardsInfo()
    if cardsInfo and cardsInfo.wildCards and cardsInfo.wildCards > 0 then
        return true
    end
    return false
end

-- 获取 限时赛季 黑曜卡册
function CardSysWildExchangeManager:canExchangeObsidianWildCard()
    local albums = self:getRunData():getWildObsidianCardAlbums()
    return #albums > 0
end

-- -- 新规则：万能wild卡兑换界面，wild卡章节的拼图，要放在所有章节的前面
-- function CardSysWildExchangeManager:sortWildExcange(wildType, exchangeData)
--     if wildType == CardSysConfigs.CardDropType.wild then
--         if #exchangeData > 0 then
--             table.sort(
--                 exchangeData,
--                 function(a, b)
--                     -- wild卡章节
--                     local aType = self:getClanTypeIndex(a.type)
--                     local bType = self:getClanTypeIndex(b.type)
--                     if aType == bType then
--                         return tonumber(a.clanId) < tonumber(b.clanId)
--                     else
--                         return aType < bType
--                     end
--                 end
--             )
--         end
--     end
--     return exchangeData
-- end

-- 排序卡册章节（wild兑换界面用）
function CardSysWildExchangeManager:getClanTypeIndex(type)
    if type == CardSysConfigs.CardClanType.puzzle_normal then
        return 1
    elseif type == CardSysConfigs.CardClanType.puzzle_golden then
        return 2
    elseif type == CardSysConfigs.CardClanType.puzzle_link then
        return 3
    else
        return 4
    end
end

-- function CardSysWildExchangeManager:filterCards(cards, cardTypes)
--     local tempCards = {}
--     for i = 1, #cards do
--         local cardData = cards[i]
--         for i = 1, #cardTypes do
--             local cardType = cardTypes[i]
--             if cardData.type == cardType then
--                 tempCards[#tempCards + 1] = cardData
--             end
--         end
--     end
--     return tempCards
-- end

-- -- 过滤当前赛季可兑换卡牌
-- -- 根据wild卡的类型
-- -- wild卡【普通】：只能兑换本年度所有赛季的普通卡
-- -- wild卡【金卡】：只能兑换本年度所有赛季的金卡
-- -- wild卡【Link卡】：只能兑换本年度所有赛季的link卡
-- -- wild卡【全部】：能兑换本年度所有赛季的任意卡
-- function CardSysWildExchangeManager:filterWildExcData(clansData)
--     local temp = {}
--     local wildType = self:getCurrentWildExchangeType()
--     for i = 1, #clansData do
--         local cData = clansData[i]
--         if wildType == CardSysConfigs.CardDropType.wild then
--             -- WILD【全部】
--             local types = {
--                 CardSysConfigs.CardType.normal,
--                 CardSysConfigs.CardType.golden,
--                 CardSysConfigs.CardType.link,
--                 CardSysConfigs.CardType.puzzle
--             }
--             cData.cards = self:filterCards(cData.cards, types)
--         elseif wildType == CardSysConfigs.CardDropType.wild_normal then
--             -- WILD_NORMAL
--             cData.cards = self:filterCards(cData.cards, {CardSysConfigs.CardType.normal})
--         elseif wildType == CardSysConfigs.CardDropType.wild_golden then
--             -- WILD_GOLDEN
--             cData.cards = self:filterCards(cData.cards, {CardSysConfigs.CardType.golden})
--         elseif wildType == CardSysConfigs.CardDropType.wild_link then
--             -- WILD_LINK
--             cData.cards = self:filterCards(cData.cards, {CardSysConfigs.CardType.link})
--         end
--         if cData.cards and #cData.cards > 0 then
--             temp[#temp + 1] = cData
--         end
--     end

--     -- 新规则：万能wild卡兑换界面，wild卡章节的拼图，要放在所有章节的前面
--     temp = self:sortWildExcange(wildType, temp)

--     return temp
-- end

function CardSysWildExchangeManager:getCardSpecialClans(albumData, _clanType)
    if _clanType and albumData.cardSpecialClans and albumData.cardSpecialClans[_clanType] then
        return albumData.cardSpecialClans[_clanType]
    end
    return nil
end

function CardSysWildExchangeManager:getYearTabList()
    -- 不能通过配置表写死，要考虑上新赛季时代码上线但是赛季没有开的情况
    -- 根据当前年度和当前赛季，动态生成
    local yearTabList = {}
    local curYear = CardSysRuntimeMgr:getCurrentYear()
    local curAlbumId = CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
    for i = 1, #CardSysConfigs.TAB_CONFIG do
        if CardSysManager:isNovice() then
            if CardSysConfigs.TAB_CONFIG[i].year == tonumber(curYear) then
                local info = {}
                for k, v in pairs(CardSysConfigs.TAB_CONFIG[i]) do
                    if k == "albums" then
                        info.albums = {}
                        for j = 1, #v do
                            -- 当前年度开了几个季度显示几个季度
                            if v[j].albumId <= tonumber(curAlbumId) then
                                table.insert(info.albums, clone(v[j]))
                            end
                        end
                    else
                        info[k] = v
                    end
                end
                table.insert(yearTabList, info)                
            end
        else
            if CardSysConfigs.TAB_CONFIG[i].year < tonumber(curYear) then
                -- 以往年度显示四个季度
                table.insert(yearTabList, clone(CardSysConfigs.TAB_CONFIG[i]))
            elseif CardSysConfigs.TAB_CONFIG[i].year == tonumber(curYear) then
                local info = {}
                for k, v in pairs(CardSysConfigs.TAB_CONFIG[i]) do
                    if k == "albums" then
                        info.albums = {}
                        for j = 1, #v do
                            -- 当前年度开了几个季度显示几个季度
                            if v[j].albumId <= tonumber(curAlbumId) then
                                table.insert(info.albums, clone(v[j]))
                            end
                        end
                    else
                        info[k] = v
                    end
                end
                table.insert(yearTabList, info)
            end
        end
    end
    table.sort(
        yearTabList,
        function(a, b)
            return a.year > b.year
        end
    )
    return yearTabList
end

-- showUnhave:显示没有获得的卡牌 _clanType:卡册类型
function CardSysWildExchangeManager:getAlbumDataByAlbumId(_albumId, showUnhave, _clanType)
    if not _albumId then
        return {}
    end
    local albumData = nil
    local wildExcInfo = self:getRunData():getCardExchangeYearCardsInfo()
    local albums = wildExcInfo.cardAlbums
    if albums and #albums > 0 then
        for i = 1, #albums do
            if tonumber(albums[i].albumId) == tonumber(_albumId) then
                albumData = clone(albums[i])
                break
            end
        end
    end
    if not albumData then
        return {}
    end

    local cardClans = albumData.cardClans
    local specialCardClans = self:getCardSpecialClans(albumData, _clanType)
    if specialCardClans then
        cardClans = specialCardClans
    end
    if showUnhave then
        -- 移除卡牌数量大于0的卡牌
        if cardClans and #cardClans > 0 then
            for i = #cardClans, 1, -1 do
                local cardClanData = cardClans[i]
                if cardClanData.cards then
                    if #cardClanData.cards > 0 then
                        for j = #cardClanData.cards, 1, -1 do
                            local cardData = cardClanData.cards[j]
                            if cardData.count > 0 then
                                table.remove(cardClanData.cards, j)
                            end
                        end
                    end
                end
            end
        end
    end

    -- 移除没有卡的章节
    for i = #cardClans, 1, -1 do
        local cardClanData = cardClans[i]
        if (cardClanData.cards and #cardClanData.cards == 0) or CardSysRuntimeMgr:isStatueClan(cardClanData.type) then
            table.remove(cardClans, i)
        end
    end

    return albumData
end

function CardSysWildExchangeManager:getCardDataByCardId(_cardId, _clanType)
    local wildExcInfo = self:getRunData():getCardExchangeYearCardsInfo()
    local albumsData = wildExcInfo.cardAlbums
    if albumsData and #albumsData > 0 then
        for i = 1, #albumsData do
            local clansData = albumsData[i].cardClans
            local specialCardClans = self:getCardSpecialClans(albumsData[i], _clanType)
            if specialCardClans then
                clansData = specialCardClans
            end
            if clansData and #clansData > 0 then
                for j = 1, #clansData do
                    local cardsData = clansData[j].cards
                    if cardsData and #cardsData > 0 then
                        for m = 1, #cardsData do
                            local cardData = cardsData[m]
                            if tonumber(cardData.cardId) == tonumber(_cardId) then
                                return cardData
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- 获取黑耀卡数据
function CardSysWildExchangeManager:getObsidianCardDataByCardId(_cardId)
    
    local albums = self:getRunData():getWildObsidianCardAlbums()
    for i, shortCardAlbum in ipairs(albums) do
        local cardClanData = shortCardAlbum.cardClans
        local cards = cardClanData.cards or {}
        for idx, cardData  in ipairs(cards) do

            -- if cardData.count and cardData.count <= 0 then
            -- end
            if tonumber(cardData.cardId) == tonumber(_cardId) then
                return cardData
            end

        end
    end

    return nil
end
-----------------------------------------数据模块处理------------------------------------------------
---------------------------------------------------------------------------------------------------

return CardSysWildExchangeManager
