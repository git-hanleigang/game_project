-- 长卡牌单元
-- 带有一些按钮的

local BaseCardUnitView = util_require("GameModule.Card.baseViews.BaseCardUnitView")
local LongCardUnitView = class("LongCardUnitView", BaseCardUnitView)

local BUBBLE_LAYER_TAG = "CardsCollectionBubbleText"
local LINK_LAYER_TAG = "CardsCollectionLinkTip"

function LongCardUnitView:ctor()
    BaseCardUnitView.ctor(self)
end

function LongCardUnitView:initUI(cardData, showTouchLayer, actionName, useClanIcon)
    BaseCardUnitView.initUI(self, cardData, showTouchLayer, actionName, useClanIcon)
    -- 添加点击相应，关闭界面
    self:showTouchLayer(showTouchLayer)
end

function LongCardUnitView:showTouchLayer(isShow)
    self.m_touch = self:findChild("touch")
    self.m_touch:setVisible(isShow)
    if isShow then
        self:addClick(self.m_touch)
    end
end

function LongCardUnitView:initSpecialData()
    self.m_isCenterShowCardIcon = true
end

function LongCardUnitView:createCsbInfo(actionName)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local cardData = self:getCardData()
    if cardData.type == CardSysConfigs.CardType.normal then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.long.normal, isAutoScale)
        self:initPageView()
    elseif cardData.type == CardSysConfigs.CardType.link then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.long.link, isAutoScale)
        self:initPageView()
    elseif cardData.type == CardSysConfigs.CardType.golden then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.long.golden, isAutoScale)
        self:initPageView()
    elseif cardData.type == CardSysConfigs.CardType.wild then
        assert(false, "THIS IS DEVEOPPING !!! TAKE EASY!!!")
    elseif cardData.type == CardSysConfigs.CardType.wild_normal then
        assert(false, "THIS IS DEVEOPPING !!! TAKE EASY!!!")
    elseif cardData.type == CardSysConfigs.CardType.wild_golden then
        assert(false, "THIS IS DEVEOPPING !!! TAKE EASY!!!")
    elseif cardData.type == CardSysConfigs.CardType.wild_link then
        assert(false, "THIS IS DEVEOPPING !!! TAKE EASY!!!")
    elseif cardData.type == CardSysConfigs.CardType.puzzle then
        assert(false, " puzzle dont have longcard !!!")
    end
    if actionName == "idle" then
        self:runCsbAction("idle")
    elseif actionName == "start" then
        self:runCsbAction(
            "start",
            false,
            function()
                self:runCsbAction("idle")
            end
        )
    end

    -- TODO:暂时先屏蔽点击事件 以后可能会删除
    local Button_send = self:findChild("Button_send")
    if Button_send then
        Button_send:setTouchEnabled(true)
        Button_send:setBright(true)
    end
    local Button_ask = self:findChild("Button_ask")
    if Button_ask then
        Button_ask:setTouchEnabled(true)
        Button_ask:setBright(true)
    end
    self:updateBack()
end

function LongCardUnitView:updateSpecialUI()
    self:updateCenterShow()
    self:updateCardNumber()
end

function LongCardUnitView:updateCardNumber()
    local cardData = self:getCardData()

    local sendNumNode = self:findChild("send_number")
    local cardNumNode = self:findChild("card_number")
    local num = cardData.count - 1
    if num > 0 then
        sendNumNode:setVisible(false) -- wuxiupdate on 2019-10-17 17:37:27 ， 没有社交全部不显示
        cardNumNode:setString("+" .. num)
    else
        sendNumNode:setVisible(false)
    end
end

-- 点击事件 --
function LongCardUnitView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_howto" then
        -- normalLong ui
        -- goldenLong ui
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:switchCenterShow()
    elseif name == "Button_ask" then
        -- normalLong ui
        -- goldenLong ui
        -- self:clickAsk()
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:showLongTips(sender)
    elseif name == "Button_info" then
        -- linkLong ui
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:switchCenterShow()
    elseif name == "Button_link" then
        -- linkLong ui
        -- self:showLinkGame()
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:showLinkTip()
    elseif name == "Button_learnmore" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:showLinkTip()
    elseif name == "Button_send" then
        -- 需要判断
        -- local cardData = self:getCardData()
        -- if cardData.count <= 1 then
        -- end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:showLongTips(sender)
    elseif name == "TouchCloseBubble" then
    elseif name == "touch" then
    end
end

-- 卡牌图标切换 如果有需要可以重写 --
function LongCardUnitView:getCenterHaveNode()
    return self:findChild("Font_info")
end
function LongCardUnitView:getCenterUnhaveNode()
    return self:findChild("PageView_1"), self:findChild("PagePoints")
end

function LongCardUnitView:getCardIdNode()
    return self:findChild("Font_cardid")
end

function LongCardUnitView:setSwitchData()
    self.m_isCenterShowCardIcon = not self.m_isCenterShowCardIcon
end
function LongCardUnitView:getSwitchData()
    return self.m_isCenterShowCardIcon
end

-- 更新中间显示区域 --
function LongCardUnitView:updateCenterShow()
    local isShow = self:getSwitchData()
    local haveNode = self:getCenterHaveNode()
    local unHaveNode, pagePoints = self:getCenterUnhaveNode()
    local cardIconNode = self:getCardIconNode()
    local cardIdNode = self:getCardIdNode()
    local cardData = self:getCardData()

    -- 卡牌唯一标示 --
    cardIdNode:setString("#" .. cardData.number)

    local isHaveCard = self:isHaveCard()
    if cardData.type == CardSysConfigs.CardType.link then
        -- link卡：
        -- 没卡：显示learnmore按钮 和 listview
        -- 有卡：显示learnmore按钮 和 info按钮（切花卡牌图片和文字描述）
        if isHaveCard then
            haveNode:setVisible(not isShow)
            haveNode:setString(cardData.description)
            cardIconNode:setVisible(isShow)
        else
            unHaveNode:setVisible(true)
            pagePoints:setVisible(true)
            cardIconNode:setVisible(false)
        end
    else
        -- 普通卡和金卡:
        -- 没卡：显示章节图片和howto按钮（listview)
        -- 有卡：显示info按钮（可以切换卡牌图片和文字描述）
        if isHaveCard then
            haveNode:setVisible(not isShow)
            haveNode:setString(cardData.description)
        else
            unHaveNode:setVisible(not isShow)
            pagePoints:setVisible(not isShow)
        end
        cardIconNode:setVisible(isShow)
    end
end

-- 切换中间显示区域 --
function LongCardUnitView:switchCenterShow()
    self:setSwitchData()
    self:updateCenterShow()
    self:updateBack()
end

-- 背景 --
function LongCardUnitView:updateBack()
    self.bg = self:findChild("bg")
    self.line_have = self:findChild("line_have")

    local cardData = self:getCardData()
    local clanId = string.sub(cardData.clanId, 7, 8)
    -- 背景图片 --
    -- util_changeTexture(self.bg, string.format(CardResConfig., clanId) )
    -- 虚线图片 --
    util_changeTexture(self.line_have, string.format(CardResConfig.ClanCardBigLinePath, clanId))
end

--显示敬请期待
function LongCardUnitView:showLongTips(sender)
    if not self.m_longTips then
        self.m_longTips = util_createAnimation(CardResConfig.LinkCardLongBtnTipRes)
        self:addChild(self.m_longTips, 1)
        local worldPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPosition()))
        local nodePos = self:convertToNodeSpace(worldPos)
        self.m_longTips:setPosition(cc.pAdd(nodePos, cc.p(40, 0)))
    end
    if self.m_longTips then
        local send_caption = self.m_longTips:findChild("send_caption")
        local needMoreCard = self.m_longTips:findChild("needmore")
        local needLoginFB = self.m_longTips:findChild("facebook")
        local commingsoon = self.m_longTips:findChild("commingsoon")
        needMoreCard:setVisible(false)
        needLoginFB:setVisible(false)
        commingsoon:setVisible(true)
        send_caption:setVisible(true)
        gLobalViewManager:addAutoCloseTips(
            self.m_longTips,
            function()
                send_caption:setVisible(false)
            end
        )
    end
end

-- bubble text pop end----------------------------------------------------

-- link tip pop start -------------------------------------------------------------
function LongCardUnitView:showLinkTip()
    local view = util_createView("GameModule.Card.season201901.LinkCardTipPop")
    local isHaveCard = self:isHaveCard()
    if isHaveCard then
        local tipNode = self:findChild("caption_have")
        tipNode:addChild(view)
    else
        local tipNode = self:findChild("caption")
        tipNode:addChild(view)
    end
end

function LongCardUnitView:showLinkGame()
    -- CardSysManager:closeBigCardView()
    -- CardSysManager:closeCardClanView()
    -- local cardData = self:getCardData()
    -- -- 打开link 小游戏
    -- CardSysManager:showNadoMachine(cardData.cardId, cardData.linkCount)
end

-- link tip pop end -------------------------------------------------------------

function LongCardUnitView:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    self:removeFromParent()
end

-- pageview start ---------------------------------------------------------------
function LongCardUnitView:initPageView()
    self.pageNode = self:findChild("PageView_1")
    self.pageSize = self.pageNode:getContentSize()

    self:initPageInfo()
    self:setCurrentPage(self.m_curPageIndex)

    local link = self:findChild("CashCards_an_link_29")
    --link卡 abtest
    if link then
        --util_changeTexture(link, CardResConfig.getLinkCardTarget())
        link:setPositionX(50)
    end
    local Button_link = self:findChild("Button_link")
    if not globalData.GameConfig.checkOldCardLink or not globalData.GameConfig:checkOldCardLink() then
        if Button_link then
            Button_link:loadTextureNormal(CardResConfig.getLinkCardButton())
            Button_link:loadTexturePressed(CardResConfig.getLinkCardButton(true))
            Button_link:loadTextureDisabled(CardResConfig.getLinkCardButton(true))
            if link then
                link:setScale(0.6)
                Button_link:setContentSize(link:getContentSize())
            end
        end
    end
end

function LongCardUnitView:initPageInfo()
    local cardData = self:getCardData()
    local sources = string.split(cardData.source, ";")
    self.m_pageList = {}
    self.m_pagePosList = {}
    self.m_pageNum = #sources
    self.m_curPageIndex = 1

    -- 初始化页数小点 --
    self:initPagePoint()

    -- 初始化page的位置列表 --
    for i = 1, self.m_pageNum do
        self.m_pagePosList[i] = (i - 1) * self.pageSize.width
    end

    -- 初始化page --
    for i = 1, self.m_pageNum do
        local image = util_createView("GameModule.Card.season201901.LongCardUnitCell")
        image:setPosition(cc.p(self.pageSize.width * 0.5 + self.m_pagePosList[i], self.pageSize.height * 0.5))
        image:updateCell(i, cardData)
        self.pageNode:addChild(image)
        self.m_pageList[i] = image
    end

    -- 注册滑动和点击区域 --
    self:registerTouchArea()
end

-- 注册滑动和点击区域 --
function LongCardUnitView:registerTouchArea()
    local touch = ccui.Layout:create()
    touch:setName("midTouchArea")
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(350, 340)
    touch:setPosition(cc.p(0, -27))
    touch:setClippingEnabled(false)
    touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    touch:setBackGroundColor(cc.c4b(255, 255, 255))
    touch:setBackGroundColorOpacity(0)
    self:addChild(touch)
    self:addClick(touch)
end

--移动监听
function LongCardUnitView:clickMoveFunc(sender)
    local name = sender:getName()
    if name == "midTouchArea" then
        local beginPos = sender:getTouchBeganPosition()
        local movePos = sender:getTouchMovePosition()
        local moveDis = movePos.x - beginPos.x
        local offx = math.abs(moveDis)
        if offx > 100 then
            self:movePageDir(moveDis)
        end
    end
end

-- 移动页面 ---- move left --
function LongCardUnitView:movePageDir(nDir)
    if not self.m_bScrolling then
        local nDestIndex = 0
        if nDir > 0 then
            nDestIndex = math.max(1, self.m_curPageIndex - 1)
        elseif nDir < 0 then
            nDestIndex = math.min(self.m_pageNum, self.m_curPageIndex + 1)
        end

        if nDestIndex == self.m_curPageIndex then
            return
        end

        self.m_pageList[self.m_curPageIndex]:moveOutCenter()

        self.m_curPageIndex = nDestIndex
        self:setPagePoint(self.m_curPageIndex)
        self:moveToPage(nDestIndex)
        self.m_bScrolling = true
        performWithDelay(
            self,
            function()
                self.m_bScrolling = false
            end,
            0.5
        )
    end
end

-- 移动具体页面展示 --
function LongCardUnitView:moveToPage(nIndex)
    local moveToAct = cc.MoveTo:create(0.2, cc.p(self.pageSize.width * 0.5 - self.m_pagePosList[nIndex], self.pageSize.height * 0.5))
    local moveEndFun =
        cc.CallFunc:create(
        function()
            self:setCurrentPage(nIndex)
        end
    )

    local seq = cc.Sequence:create(moveToAct, moveEndFun)
    self.pageNode:runAction(seq)
end

-- 移动完回调 --
function LongCardUnitView:setCurrentPage(nIndex)
    if not self.m_pageList[nIndex] then
        return
    end
    self.m_pageList[nIndex]:moveInCenter()
end

-- 页数索引小圆点
function LongCardUnitView:initPagePoint()
    self.m_pagePointLayer = self:findChild("PagePoints")
    self.m_pagePointLayer:removeAllChildren()
    local layerSize = self.m_pagePointLayer:getContentSize()

    -- 小圆点的长度
    local pointWidth = 20
    local pointIntervalWidth = 10
    -- 总页数
    local totalPageNum = self.m_pageNum

    -- 所有位置
    self.m_pagePointsPos = {}
    local startPosX = 0
    local halfNum = 0
    if totalPageNum % 2 == 0 then
        -- 总页数是偶数
        halfNum = totalPageNum / 2
        startPosX = layerSize.width * 0.5 - (halfNum * 2 - 1) * (pointWidth / 2 + pointIntervalWidth / 2)
        for i = 1, totalPageNum do
            self.m_pagePointsPos[#self.m_pagePointsPos + 1] = startPosX + (i - 1) * (pointWidth + pointIntervalWidth)
        end
    else
        -- 总页数是奇数
        halfNum = (totalPageNum - 1) / 2
        startPosX = layerSize.width * 0.5 - halfNum * (pointWidth + pointIntervalWidth)
        for i = 1, totalPageNum do
            self.m_pagePointsPos[#self.m_pagePointsPos + 1] = startPosX + (i - 1) * (pointWidth + pointIntervalWidth)
        end
    end

    -- 圆点灰色底图
    for i = 1, totalPageNum do
        local spBg = util_createSprite(CardResConfig.LongDesDianBg)
        spBg:setAnchorPoint(0.5, 0.5)
        spBg:setPosition(cc.p(self.m_pagePointsPos[i], layerSize.height * 0.5))
        self.m_pagePointLayer:addChild(spBg)
    end
    -- 圆点红色标识当前页数
    self.m_currentPagePointSp = util_createSprite(CardResConfig.LongDesDian)
    self.m_currentPagePointSp:setAnchorPoint(0.5, 0.5)
    self.m_pagePointLayer:addChild(self.m_currentPagePointSp)

    self:setPagePoint(self.m_curPageIndex)
end

-- 当PageView滑动后，需要更新页数 --
function LongCardUnitView:setPagePoint(curPageIndex)
    local layerSize = self.m_pagePointLayer:getContentSize()
    self.m_currentPagePointSp:setPosition(cc.p(self.m_pagePointsPos[curPageIndex], layerSize.height * 0.5))
end

-- pageview end   ---------------------------------------------------------------

return LongCardUnitView
