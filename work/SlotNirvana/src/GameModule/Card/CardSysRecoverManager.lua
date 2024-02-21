--[[
    集卡系统 卡片回收机管理
--]]
local CardSysRecoverRunData = util_require("GameModule.Card.CardSysRecoverRunData")
local CardSysRecoverManager = class("CardSysRecoverManager")

-- ctor
function CardSysRecoverManager:ctor()
    self:reset()
    self:initBaseData()
end

-- do something reset --
function CardSysRecoverManager:reset()
    self.m_countDownState = nil
end

-- init --
function CardSysRecoverManager:initBaseData()
    self.m_runningData = CardSysRecoverRunData:new()
end

function CardSysRecoverManager:getRunData()
    return self.m_runningData
end

-- 每秒刷新 --
function CardSysRecoverManager:onUpdateTimer(dt)
    self:initRecoverCountDownTime()
end

function CardSysRecoverManager:initRecoverCountDownTime(dt)
    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    if yearData then
        local wheelCfg = yearData:getWheelConfig()
        if wheelCfg then
            local finalTime = math.floor(tonumber(wheelCfg:getCooldown() or 0))
            local remainTime = math.max(util_getLeftTime(finalTime), 0)
            if remainTime == 0 then
                if self.m_countDownState == nil then
                    self.m_countDownState = "READY"
                end
                if self.m_countDownState == "COOLD0WN" then
                    -- 清除缓存记录
                    gLobalDataManager:setNumberByField("CardRecover", 0)
                    self.m_countDownState = "READY"
                    gLobalNoticManager:postNotification(ViewEventType.CARD_RECOVER_COUNTDOWN_CHANGE, {status = self.m_countDownState})
                end
            else
                if self.m_countDownState == nil then
                    self.m_countDownState = "COOLD0WN"
                end
                if self.m_countDownState == "READY" then
                    self.m_countDownState = "COOLD0WN"
                    gLobalNoticManager:postNotification(ViewEventType.CARD_RECOVER_COUNTDOWN_CHANGE, {status = self.m_countDownState})
                end
            end
        end
    end
end

-- 显示回收面板 --
function CardSysRecoverManager:showRecoverView(callBack)
    if self.m_RecoverView and not self.m_RecoverView:isVisibleEx() then
        self.m_RecoverView:setVisible(true)
        if callBack then
            callBack()
        end
        return
    end

    --屏蔽多次点击
    if self.m_isRecoverNetWaiting then
        return
    end
    self.m_isRecoverNetWaiting = true
    local requestSuccess = function(tData)
        gLobalViewManager:removeLoadingAnima()

        -- 数据处理
        self:getRunData():setCardWheelAllCardsInfo(tData)

        self.m_isRecoverNetWaiting = nil
        -- self.m_RecoverView = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverView")
        local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
        if curLogic then
            self.m_RecoverView = curLogic:createCardRevoverMain()
            gLobalViewManager:showUI(self.m_RecoverView, ViewZorder.ZORDER_UI)
            if callBack then
                callBack()
            end
        end
    end

    local failFunc = function()
        self.m_isRecoverNetWaiting = nil
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    gLobalViewManager:addLoadingAnimaDelay()
    local tExtraInfo = {["year"] = -1}
    CardSysNetWorkMgr:sendCardWheelAllCardsRequest(tExtraInfo, requestSuccess, failFunc)
end
function CardSysRecoverManager:closeRecoverView()
    if self.m_RecoverView and self.m_RecoverView.closeUI then
        self.m_RecoverView:closeUI()
    end
    self.m_RecoverView = nil
end
function CardSysRecoverManager:hideRecoverView()
    if self.m_RecoverView ~= nil then
        self.m_RecoverView:setVisible(false)
    end
end

-- 回收机系统：卡牌选择界面 --
function CardSysRecoverManager:showRecoverExchangeView()
    if self.m_RecoverExc and not self.m_RecoverExc:isVisibleEx() then
        self.m_RecoverExc:setVisible(true)
        return
    end
    -- self.m_RecoverExc = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeView")
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.m_RecoverExc = curLogic:createCardRevoverExchange()
        gLobalViewManager:showUI(self.m_RecoverExc, ViewZorder.ZORDER_UI)
    end
end

function CardSysRecoverManager:closeRecoverExchangeView()
    if self.m_RecoverExc and self.m_RecoverExc.closeUI then
        self.m_RecoverExc:closeUI()
    end
    self.m_RecoverExc = nil
end
function CardSysRecoverManager:hideRecoverExchangeView()
    if self.m_RecoverExc ~= nil then
        self.m_RecoverExc:setVisible(false)
    end
end

-- 显示回收轮盘 --
function CardSysRecoverManager:showRecoverWheelView()
    -- self.m_recoverWheelUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverLetto")
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.m_recoverWheelUI = curLogic:createCardRevoverLetto()
        gLobalViewManager:showUI(self.m_recoverWheelUI, ViewZorder.ZORDER_UI)
    end
end

function CardSysRecoverManager:closeRecoverWheelView()
    if self.m_recoverWheelUI ~= nil then
        if self.m_recoverWheelUI.closeUI then
            self.m_recoverWheelUI:closeUI()
        end
        self.m_recoverWheelUI = nil
    end
end ----------------------------------------------------------------------------------------------------------------------- -- 选择卡牌界面：获取年度列表

--[[ 数据处理模块 开始]]
function CardSysRecoverManager:setYearTabList()
    -- 不能通过配置表写死，要考虑上新赛季时代码上线但是赛季没有开的情况
    -- 根据当前年度和当前赛季，动态生成
    local yearTabList = {}
    local curYear = CardSysRuntimeMgr:getCurrentYear()
    local curAlbumId = CardSysRuntimeMgr:getSelAlbumID()
    for i = 1, #CardSysConfigs.TAB_CONFIG do
        if CardSysConfigs.TAB_CONFIG[i].year < tonumber(curYear) then
            -- 以往年度显示四个季度
            for m = 1, #CardSysConfigs.TAB_CONFIG[i].albums do
                table.insert(yearTabList, clone(CardSysConfigs.TAB_CONFIG[i].albums[m]))
            end
        elseif CardSysConfigs.TAB_CONFIG[i].year == tonumber(curYear) then
            for m = 1, #CardSysConfigs.TAB_CONFIG[i].albums do
                if CardSysConfigs.TAB_CONFIG[i].albums[m].albumId <= tonumber(curAlbumId) then
                    table.insert(yearTabList, clone(CardSysConfigs.TAB_CONFIG[i].albums[m]))
                end
            end
        end
    end

    table.sort(
        yearTabList,
        function(a, b)
            return a.albumId > b.albumId
        end
    )

    -- 组合卡牌数据
    for i = 1, #yearTabList do
        yearTabList[i].cards, yearTabList[i].typeCards, yearTabList[i].starCards = self:getCardsAndTypeCardsAndStarCardsByAlbumId(yearTabList[i].albumId) --self:getCardsByAlbumId(yearTabList[i].albums[j].albumId)
    end
    self.m_yearTabList = yearTabList
end

function CardSysRecoverManager:getYearTabList()
    return self.m_yearTabList
end

function CardSysRecoverManager:getCardsByAlbumId(_albumId)
    local cardList = {}
    local allCard = self:getRunData():getCardWheelAllCardsInfo()
    if allCard and #allCard > 0 then
        for i = 1, #allCard do
            if tonumber(allCard[i].albumId) == tonumber(_albumId) then
                local _cardData = clone(allCard[i])
                _cardData.chooseNum = 0 -- 组合选择的卡牌个数数据
                table.insert(cardList, _cardData)
            end
        end
    end
    -- 如果有拼图卡将拼图卡放在最前面
    table.sort(
        cardList,
        function(a, b)
            local cardTypeA = a.type == CardSysConfigs.CardType.puzzle and 1 or 2
            local cardTypeB = b.type == CardSysConfigs.CardType.puzzle and 1 or 2
            if cardTypeA == cardTypeB then
                return a.cardId < b.cardId
            else
                return cardTypeA < cardTypeB
            end
        end
    )

    return cardList
end

function CardSysRecoverManager:getCardsAndTypeCardsAndStarCardsByAlbumId(_albumId)
    local cardList = {}
    local starList = {{starText = "1 Star", cards = {}}, {starText = "2 Star", cards = {}}, {starText = "3 Star", cards = {}}, {starText = "4 Star", cards = {}}, {starText = "5 Star", cards = {}}}
    local typeList = {{starText = "Ordinary", cards = {}}, {starText = "Nado", cards = {}}, {starText = "Gold", cards = {}}, {starText = "Statue", cards = {}}}
    local allCard = self:getRunData():getCardWheelAllCardsInfo()
    if allCard then
        for i = 1, #allCard do
            if tonumber(allCard[i].albumId) == tonumber(_albumId) then
                local _cardData = clone(allCard[i])
                _cardData.chooseNum = 0 -- 组合选择的卡牌个数数据
                if _cardData.type == CardSysConfigs.CardType.normal then
                    if typeList[1].starList == nil then
                        typeList[1].starList = {
                            {starText = "1 Star", cards = {}},
                            {starText = "2 Star", cards = {}},
                            {starText = "3 Star", cards = {}},
                            {starText = "4 Star", cards = {}},
                            {starText = "5 Star", cards = {}}
                        }
                    end
                    if _cardData.star then
                        table.insert(typeList[1].starList[_cardData.star].cards, _cardData)
                        table.sort(
                            typeList[1].starList[_cardData.star].cards,
                            function(a, b)
                                return a.cardId < b.cardId
                            end
                        )
                    end
                elseif _cardData.type == CardSysConfigs.CardType.link then
                    if typeList[2].starList == nil then
                        typeList[2].starList = {
                            {starText = "1 Star", cards = {}},
                            {starText = "2 Star", cards = {}},
                            {starText = "3 Star", cards = {}},
                            {starText = "4 Star", cards = {}},
                            {starText = "5 Star", cards = {}}
                        }
                    end
                    if _cardData.star then
                        table.insert(typeList[2].starList[_cardData.star].cards, _cardData)
                        table.sort(
                            typeList[2].starList[_cardData.star].cards,
                            function(a, b)
                                return a.cardId < b.cardId
                            end
                        )
                    end
                elseif _cardData.type == CardSysConfigs.CardType.golden or _cardData.type == CardSysConfigs.CardType.puzzle then
                    if typeList[3].starList == nil then
                        typeList[3].starList = {
                            {starText = "1 Star", cards = {}},
                            {starText = "2 Star", cards = {}},
                            {starText = "3 Star", cards = {}},
                            {starText = "4 Star", cards = {}},
                            {starText = "5 Star", cards = {}}
                        }
                    end
                    if _cardData.star then
                        table.insert(typeList[3].starList[_cardData.star].cards, _cardData)
                        table.sort(
                            typeList[3].starList[_cardData.star].cards,
                            function(a, b)
                                return a.cardId < b.cardId
                            end
                        )
                    end
                elseif CardSysRuntimeMgr:isStatueCard(_cardData.type) then
                    if typeList[4].starList == nil then
                        typeList[4].starList = {
                            {starText = "1 Star", cards = {}},
                            {starText = "2 Star", cards = {}},
                            {starText = "3 Star", cards = {}},
                            {starText = "4 Star", cards = {}},
                            {starText = "5 Star", cards = {}}
                        }
                    end
                    if _cardData.star then
                        table.insert(typeList[4].starList[_cardData.star].cards, _cardData)
                        table.sort(
                            typeList[4].starList[_cardData.star].cards,
                            function(a, b)
                                return a.cardId < b.cardId
                            end
                        )
                    end
                end
            end
        end
        for type = #typeList, 1, -1 do
            local typeData = typeList[type]
            if typeData.starList == nil then
                typeData.starList = {
                    {starText = "1 Star", cards = {}},
                    {starText = "2 Star", cards = {}},
                    {starText = "3 Star", cards = {}},
                    {starText = "4 Star", cards = {}},
                    {starText = "5 Star", cards = {}}
                }
            else
                for i, starData in ipairs(typeData.starList) do
                    for i, v in ipairs(starData.cards) do
                        table.insert(typeData.cards, v)
                        table.insert(starList[v.star].cards, v)
                    end
                end
            end
        end
        for type = #typeList, 1, -1 do
            local typeData = typeList[type]
            for i, v in ipairs(typeData.cards) do
                table.insert(cardList, v)
            end
        end
    end
    return cardList, typeList, starList
end

-- 设置在回收机选择时  选择的level等级 --
function CardSysRecoverManager:setCardWheelSelLevel(nLevel, nNeedStars, nMaxCoins)
    self.selLevel = {["Level"] = nLevel, ["NeededStars"] = nNeedStars, ["MaxCoins"] = nMaxCoins}
end
function CardSysRecoverManager:getCardWheelSelLevel()
    return self.selLevel
end

-- 设置选择卡片时相关数据 金卡星数 奖励金币总数 --
-- 提供最大星的卡牌数据
function CardSysRecoverManager:setMaxStarCardList(cardDatas)
    self.m_cardDataList = cardDatas
end
function CardSysRecoverManager:getMaxStarCardList()
    return self.m_cardDataList
end

-- 设置选择卡片时相关数据 是否使用AI 自动选择卡片 --
function CardSysRecoverManager:setIsUseAISelect(useAISelect)
    self.m_useAISelect = useAISelect
end
function CardSysRecoverManager:getIsUseAISelect()
    return self.m_useAISelect
end

-----------------------------------------------------------------------------------------------------------------------

--[[ 数据处理模块 结束]]
return CardSysRecoverManager
