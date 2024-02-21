--[[
    wild卡片兑换卡组单元
    time:2019-07-12 11:12:49
]]
local BaseView = util_require("base.BaseView")
local BaseCardWildExcCell = class("BaseCardWildExcCell", BaseView)

function BaseCardWildExcCell:initUI()
    self:createCsbNode(self:getCsbName())
end

function BaseCardWildExcCell:getCsbName()
    return ""
end

-- 点击事件 --
function BaseCardWildExcCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
    elseif name == "Button_2" then
    end

    if tag > 0 and tag <= 10 then
        print("------------>touch tag .." .. tag)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickToSelCard(tag)
    end
end

function BaseCardWildExcCell:getClanLogoScale()
    return 1
end

-- 初始化资源及数据 --
function BaseCardWildExcCell:loadDataRes(nIndex, tData)
    -- 初始化标题和icon --
    self.m_ClanIcon = self:findChild("logo")
    self.m_ClanName = self:findChild("font_biaoti")

    local icon = CardResConfig.getCardClanIcon(tData.clanId)
    util_changeTexture(self.m_ClanIcon, icon)
    self.m_ClanIcon:setScale(self:getClanLogoScale(tData.type))

    self.m_ClanName:setString(tData.name)

    -- self.m_clickCallBack = callBack
    self.m_myIndex = nIndex

    self.m_ClanData = tData

    -- 初始化1张卡片 --
    self.m_cardsNodeList = {}
    for i = 1, 10 do
        self.m_cardsNodeList[i] = self:findChild("Panel_" .. i)
        self.m_cardsNodeList[i]:setTag(i)
        self.m_cardsNodeList[i]:setSwallowTouches(false)
        -- 隐藏选择层 --
        self:cancelCardSeledByIndex(i)
        -- 隐藏遮罩层 --
        local node = self.m_cardsNodeList[i]:getChildByName("mask")
        node:setVisible(false)

        if tData.cards[i] ~= nil then
            self:addNodeClicked(self.m_cardsNodeList[i])
            -- 初始化卡牌 --
            local cardNode = self:findChild("Node_" .. i)
            if tData.cards[i].type == CardSysConfigs.CardType.puzzle then
                -- 拼图卡
                local puzzleCardView = util_createView("GameModule.Card.views.PuzzleCardUnitView", tData.cards[i], "idle")
                cardNode:addChild(puzzleCardView)
            else
                local miniCardView = util_createView("GameModule.Card.views.MiniCardUnitView", tData.cards[i], nil, "idle", true, nil, nil, nil, nil, true)
                cardNode:addChild(miniCardView)
            end

            -- 如果卡片未获得 则增加蒙版 --
            if tData.cards[i].count == 0 then
                -- 如果需要遮罩 才显示 --
                if CardSysManager:getWildExcMgr():getShowAll() == true then
                    node:setVisible(true)
                end
            end

            -- 判断某卡是否被选中 --
            if tonumber(tData.cards[i].cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId()) then
                self:markCardSeledByIndex(i)
            end
        end
    end
end

function BaseCardWildExcCell:newCard(cardData, cardNode)
    if cardData.type == CardSysConfigs.CardType.puzzle then
        -- 拼图卡
        local puzzleCardView = util_createView("GameModule.Card.views.PuzzleCardUnitView", cardData, "idle")
        cardNode:addChild(puzzleCardView)
        return puzzleCardView
    else
        local miniCardView = util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "idle", true, nil, nil, nil, nil, true)
        cardNode:addChild(miniCardView)
        return miniCardView
    end
    -- local miniCardView = util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "idle", true, nil, nil, nil, nil, true)
    -- cardNode:addChild(miniCardView)
    -- return miniCardView
end

function BaseCardWildExcCell:initCard(cardData, cardNode)
    --保留初始类型
    local lastType = cardData.type

    cardData.type = CardSysConfigs.CardType.link
    cardNode.m_linkCard = self:newCard(cardData, cardNode)

    cardData.type = CardSysConfigs.CardType.golden
    cardNode.m_goldCard = self:newCard(cardData, cardNode)

    cardData.type = CardSysConfigs.CardType.normal
    cardNode.m_nomalCard = self:newCard(cardData, cardNode)

    cardData.type = CardSysConfigs.CardType.puzzle
    cardNode.m_puzzleCard = self:newCard(cardData, cardNode)
    --还原类型
    cardData.type = lastType
end

function BaseCardWildExcCell:updateCard(cardData, i)
    local cardNode = self:findChild("Node_" .. i)
    if not cardNode.m_initCard then
        cardNode.m_initCard = true
        self:initCard(cardData, cardNode)
    end
    --隐藏卡
    cardNode.m_linkCard:setVisible(false)
    cardNode.m_goldCard:setVisible(false)
    cardNode.m_nomalCard:setVisible(false)
    cardNode.m_puzzleCard:setVisible(false)
    --刷新卡
    if cardData.type == CardSysConfigs.CardType.link then
        cardNode.m_linkCard:setCardData(cardData)
        cardNode.m_linkCard:setVisible(true)
        cardNode.m_linkCard:updateUI()
    elseif cardData.type == CardSysConfigs.CardType.golden then
        cardNode.m_goldCard:setCardData(cardData)
        cardNode.m_goldCard:setVisible(true)
        cardNode.m_goldCard:updateUI()
    elseif cardData.type == CardSysConfigs.CardType.puzzle then
        cardNode.m_puzzleCard:setCardData(cardData)
        cardNode.m_puzzleCard:setVisible(true)
        cardNode.m_puzzleCard:updateUI()
    else
        cardNode.m_nomalCard:setCardData(cardData)
        cardNode.m_nomalCard:setVisible(true)
        cardNode.m_nomalCard:updateUI()
    end
end

-- 点击进行卡牌选中与否 --
function BaseCardWildExcCell:clickToSelCard(nTag)
    local cardData = self.m_ClanData.cards[nTag]
    local selCardId = CardSysManager:getWildExcMgr():getSelCardId()
    if selCardId then
        if tonumber(cardData.cardId) == tonumber(selCardId) then
            CardSysManager:getWildExcMgr():setSelCardId(nil)
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_CLICK_CELL, {cancelCardId = selCardId})
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_UPDATE_BTN_GO)
        else
            CardSysManager:getWildExcMgr():setSelCardId(cardData.cardId)
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_CLICK_CELL, {cancelCardId = selCardId, markCardId = cardData.cardId})
        end
    else
        CardSysManager:getWildExcMgr():setSelCardId(cardData.cardId)
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_CLICK_CELL, {markCardId = cardData.cardId})
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_UPDATE_BTN_GO)
    end
end

-- 标记卡片选中 --
function BaseCardWildExcCell:markCardSeledByIndex(index)
    local node = self.m_cardsNodeList[index]:getChildByName("yes")
    node:setScale(1.1)
    node:setVisible(true)
end

-- 标记卡片选中 --
function BaseCardWildExcCell:markCardSeled(sCardID)
    for i = 1, #self.m_ClanData.cards do
        local card = self.m_ClanData.cards[i]
        if tonumber(card.cardId) == tonumber(sCardID) then
            self:markCardSeledByIndex(i)
            break
        end
    end
end

-- 取消卡片选中 --
function BaseCardWildExcCell:cancelCardSeledByIndex(nIndex)
    local node = self.m_cardsNodeList[nIndex]:getChildByName("yes")
    node:setVisible(false)
end

-- 取消卡片选中 --
function BaseCardWildExcCell:cancelCardSeled(sCardID)
    for i = 1, #self.m_ClanData.cards do
        local card = self.m_ClanData.cards[i]
        if tonumber(card.cardId) == tonumber(sCardID) then
            self:cancelCardSeledByIndex(i)
            break
        end
    end
end

-- 节点选中的事件 --
function BaseCardWildExcCell:addNodeClicked(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.nodeClickedEvent))
end
function BaseCardWildExcCell:nodeClickedEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offy = math.abs(endPos.y - beginPos.y)
        if offy < 50 then
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        self:clickEndFunc(sender)
    end
end

function BaseCardWildExcCell:onEnter()
    BaseCardWildExcCell.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                if params.cancelCardId then
                    self:cancelCardSeled(params.cancelCardId)
                end
                if params.markCardId then
                    self:markCardSeled(params.markCardId)
                end
            end
        end,
        CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_CLICK_CELL
    )
end

-- function BaseCardWildExcCell:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

return BaseCardWildExcCell
