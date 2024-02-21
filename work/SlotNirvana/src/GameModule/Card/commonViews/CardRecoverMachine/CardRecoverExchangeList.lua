--[[-- 
    回收机卡牌列表
]]
local CardRecoverExchangeList = class("CardRecoverExchangeList", util_require("base.BaseView"))
local countOfOneLine = 5

function CardRecoverExchangeList:getTableView()
    return self.m_tableView
end

function CardRecoverExchangeList:initUI(_parentNode, _listData)
    self.m_tableViewSize = _parentNode:getContentSize()
    self.m_listData = _listData

    if not self.m_listData or #self.m_listData == 0 then
        return
    end
    self.m_cellPool = {}
    local FrameLoadManager = util_require("manager/FrameLoadManager")
    self.m_fm = FrameLoadManager:getInstance()

    self.m_ControlNodeList = {}
    local yushu = #self.m_listData % countOfOneLine
    local zhengshu = math.floor(#self.m_listData / countOfOneLine)
    self.m_CurCellsMaxNum = yushu > 0 and zhengshu + 1 or zhengshu
    self.m_vCellSize = cc.size(1064, 256)
    self:createTableView()
    self:createSlide()
end

function CardRecoverExchangeList:reloadDataByData(cardList)
    self.m_listData = cardList
    self.m_ControlNodeList = {}
    local yushu = #self.m_listData % countOfOneLine
    local zhengshu = math.floor(#self.m_listData / countOfOneLine)
    self.m_CurCellsMaxNum = yushu > 0 and zhengshu + 1 or zhengshu
    self.m_vCellSize = cc.size(1064, 256)
    if not self.m_tableView then
        if self.m_listData and #self.m_listData > 0 then
            self:createTableView()
        end
    else
        if self.m_listData then
            self.m_tableView:reloadData()
        end
    end
    self:createSlide()
end

function CardRecoverExchangeList:createTableView()
    self.m_tableView = cc.TableView:create(self.m_tableViewSize)
    --禁止回弹效果
    self.m_tableView:setBounceable(false)
    --设置滚动方向
    self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_tableView:setDelegate()
    self:addChild(self.m_tableView)

    --registerScriptHandler functions must be before the reloadData funtion
    self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)

    --调用这个才会显示界面
    self.m_tableView:reloadData()
end

function CardRecoverExchangeList:numberOfCellsInTableView(table)
    return self.m_CurCellsMaxNum
end

function CardRecoverExchangeList:cellSizeForTable(table, idx)
    return self.m_vCellSize.width, self.m_vCellSize.height
end

function CardRecoverExchangeList:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    local oldCellIndex = 0
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        oldCellIndex = cell:getTag()
    end
    cell:setTag(idx + 1)
    self:doCellLogic(cell, idx + 1, oldCellIndex)

    return cell
end

function CardRecoverExchangeList:doCellLogic(cell, index, oldCellIndex)
    local cellLayout = cell:getChildByTag(10)
    if cellLayout then
        self:updataAllSubCell(cellLayout, index, oldCellIndex)
    else
        cellLayout = ccui.Layout:create()
        cellLayout:setContentSize(self.m_vCellSize)
        cellLayout:setAnchorPoint(cc.p(0, 0))
        cellLayout:setPosition(cc.p(0, 0))
        cellLayout:setTag(10)
        cell:addChild(cellLayout)
        self:createAllSubCell(cellLayout, index)
    end
end

function CardRecoverExchangeList:createAllSubCell(cellLayout, index)
    self.m_fm:addInfo(
        "createCell",
        countOfOneLine,
        function(curCount, totalCount)
            local subIndex = (index - 1) * countOfOneLine + curCount
            if not self.m_listData or subIndex > #self.m_listData then
                return
            end
            local cardData = self.m_listData[subIndex]
            if not cardData then
                return
            end
            local subCell = util_csbCreate(string.format(CardResConfig.commonRes.CardRecoverSelCellRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
            cellLayout:addChild(subCell)
            subCell:setTag(curCount)
            self.m_ControlNodeList[subIndex] = subCell
            subCell:setPosition(cc.p(250 * (curCount - 1), 0))
            self:updataSubCell(subCell, cardData, subIndex)
        end,
        nil
    )
    self.m_fm:start("createCell")
end

function CardRecoverExchangeList:updataAllSubCell(cellLayout, index, oldCellIndex)
    for i = 1, countOfOneLine do
        local subCell = cellLayout:getChildByTag(i)
        local subIndex = (index - 1) * countOfOneLine + i
        if subCell then
            self.m_ControlNodeList[subIndex] = subCell
            local cardData = self.m_listData[subIndex]
            self:updataSubCell(subCell, cardData, subIndex)
        else
            local cardData = self.m_listData[subIndex]
            if cardData then
                local subCell = util_csbCreate(string.format(CardResConfig.commonRes.CardRecoverSelCellRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
                cellLayout:addChild(subCell)
                subCell:setTag(i)
                self.m_ControlNodeList[subIndex] = subCell
                subCell:setPosition(cc.p(250 * (i - 1), 0))
                self:updataSubCell(subCell, cardData, subIndex)
            end
        end
    end
end

function CardRecoverExchangeList:updataSubCell(subCell, cardData, subIndex)
    if cardData == nil then
        subCell:setVisible(false)
        return
    else
        subCell:setVisible(true)
    end

    local basePanel = subCell:getChildByName("Panel_main")
    local btnRoot = basePanel:getChildByName("Image_1")
    local btnSub = btnRoot:getChildByName("Button_Sub")
    btnSub:setVisible(false)
    local btnAdd = btnRoot:getChildByName("Button_Add")
    btnAdd:setVisible(false)

    local textNum = btnRoot:getChildByName("BitmapFont_Num")

    local cardRoot = basePanel:getChildByName("card")
    local cardNode1 = cardRoot:getChildByName("Panel_1")
    local cardNode2 = cardRoot:getChildByName("Panel_2")
    local doubleStar = basePanel:getChildByName("x2Stars")
    local bigPrize = basePanel:getChildByName("bigger")
    local lb_mul = bigPrize:getChildByName("BitmapFontLabel_1")

    local numberNode = basePanel:getChildByName("number")
    local maxNum = numberNode:getChildByName("BitmapFontLabel_4")

    local touch = cardRoot:getChildByName("touch")
    touch:setVisible(false)
    touch:setSwallowTouches(false)
    touch:setTouchEnabled(false)

    local mask = cardRoot:getChildByName("mask")

    local zhezhao = mask:getChildByName("zhezhao")
    local chouma = mask:getChildByName("chouma")

    -- 添加touch事件 --
    btnRoot:removeChildByName("myBtnSub")
    local myBtnSub = btnSub:clone()
    myBtnSub:setVisible(true)
    btnRoot:addChild(myBtnSub)
    myBtnSub:setTag(subIndex)
    myBtnSub:setName("myBtnSub")
    self:addClick(myBtnSub)

    btnRoot:removeChildByName("myBtnAdd")
    local myBtnAdd = btnAdd:clone()
    myBtnAdd:setVisible(true)
    btnRoot:addChild(myBtnAdd)
    myBtnAdd:setTag(subIndex)
    myBtnAdd:setName("myBtnAdd")
    self:addClick(myBtnAdd)

    cardRoot:removeChildByName("myTouch")
    local myTouch = touch:clone()
    myTouch:setVisible(true)
    cardRoot:addChild(myTouch)
    myTouch:setTouchEnabled(true)
    myTouch:setSwallowTouches(false)
    myTouch:setTag(subIndex)
    myTouch:setName("myTouch")

    if cardData.chooseNum == nil then
        cardData.chooseNum = 0
    end
    myBtnSub:setTouchEnabled(cardData.chooseNum > 0)
    myBtnSub:setBright(cardData.chooseNum > 0)

    myBtnAdd:setTouchEnabled(cardData.count > cardData.chooseNum)
    myBtnAdd:setBright(cardData.count > cardData.chooseNum)

    myTouch:setEnabled(cardData.count > cardData.chooseNum)
    self:addNodeClicked(myTouch)

    -- 设置显示数字 --
    textNum:setString(cardData.chooseNum)

    if cardData.type == CardSysConfigs.CardType.puzzle then
        -- 拼图卡
        cardNode1:setVisible(true)
        cardNode2:setVisible(false)

        local node_tu = cardNode1:getChildByName("Node_tu")
        local card_icon = node_tu:getChildByName("card_icon")
        local sp = CardResConfig.getCardIcon(cardData.cardId, true)
        util_changeTexture(card_icon, sp)
    else
        cardNode1:setVisible(false)
        cardNode2:setVisible(true)
        local spBg = cardNode2:getChildByName("sp_card_bg")
        local cardBgRes = CardResConfig.getCardBgRes(cardData.type, cardData.count > 0)
        if cardBgRes ~= nil then
            util_changeTexture(spBg, cardBgRes)
        end
        local spIcon = cardNode2:getChildByName("sp_card_icon")
        local cardIconRes = CardResConfig.getCardIcon(cardData.cardId)
        util_changeTexture(spIcon, cardIconRes)

        local fntName1 = cardNode2:getChildByName("lb_name_1")
        local fntName2 = cardNode2:getChildByName("lb_name_2")
        local fntName3 = cardNode2:getChildByName("lb_name_3")

        local nameStrs = string.split(cardData.name, "|")
        if #nameStrs == 1 then
            fntName1:setVisible(false)
            fntName2:setVisible(false)
            fntName3:setVisible(true)
            fntName3:setString(nameStrs[1])
        else
            fntName1:setVisible(true)
            fntName2:setVisible(true)
            fntName3:setVisible(false)
            fntName1:setString(nameStrs[1])
            fntName2:setString(nameStrs[2])
        end

        local fntRes = nil
        if cardData.type == CardSysConfigs.CardType.normal then
            fntRes = "CardsBase201903/CardRes/Other/chipFnt_normal.fnt"
        elseif cardData.type == CardSysConfigs.CardType.golden then
            fntRes = "CardsBase201903/CardRes/Other/chipFnt_golden.fnt"
        elseif cardData.type == CardSysConfigs.CardType.link then
            fntRes = "CardsBase201903/CardRes/Other/chipFnt_nado.fnt"
        end
        if fntRes ~= nil then
            fntName1:setFntFile(fntRes)
            fntName2:setFntFile(fntRes)
            fntName3:setFntFile(fntRes)
        end
        local nodeStar = cardNode2:getChildByName("star")
        nodeStar:removeAllChildren()
        local pngPath = "CardsBase201903/CardRes/season201903/ui/liang_star" .. cardData.star .. ".png"
        local sp_star = util_createSprite(pngPath)
        nodeStar:addChild(sp_star)
    end

    -- 双倍星数标识
    doubleStar:setPositionY(193)
    if self:isShowStar(cardData.type) then
        doubleStar:setVisible(true)
        if CardSysRuntimeMgr:isStatueCard(cardData.type) then
            doubleStar:setPositionY(123)
        end
    else
        doubleStar:setVisible(false)
        doubleStar:setPositionY(193)
    end

    -- 奖励提升标识，如果是金卡，需要添加奖励提升标识
    bigPrize:setVisible(self:isShowBigPrize(cardData.type))

    -- 卡牌可回收数量
    local remain = cardData.count - cardData.chooseNum
    if remain > 0 then
        numberNode:setVisible(true)
        maxNum:setString("X" .. remain)
    else
        numberNode:setVisible(false)
    end
    -- 遮罩
    mask:setVisible(remain == 0)
    if cardData.type == CardSysConfigs.CardType.puzzle then
        zhezhao:setVisible(true)
        chouma:setVisible(false)
    else
        zhezhao:setVisible(false)
        chouma:setVisible(true)
    end
    util_changeTexture(chouma, string.format(CardResConfig.otherRes.CardMarkRes, cardData.star))
    self:updateMul(lb_mul, cardData)
end

function CardRecoverExchangeList:updataSelectCell(subCell, cardData)
    local basePanel = subCell:getChildByName("Panel_main")
    local btnRoot = basePanel:getChildByName("Image_1")
    local cardRoot = basePanel:getChildByName("card")

    local myBtnSub = btnRoot:getChildByName("myBtnSub")
    local myBtnAdd = btnRoot:getChildByName("myBtnAdd")
    local myTouch = cardRoot:getChildByName("myTouch")
    myBtnSub:setTouchEnabled(cardData.chooseNum > 0)
    myBtnSub:setBright(cardData.chooseNum > 0)
    myBtnAdd:setTouchEnabled(cardData.count > cardData.chooseNum)
    myBtnAdd:setBright(cardData.count > cardData.chooseNum)
    myTouch:setEnabled(cardData.count > cardData.chooseNum)

    local textNum = btnRoot:getChildByName("BitmapFont_Num")
    textNum:setString(cardData.chooseNum)

    local numberNode = basePanel:getChildByName("number")
    local maxNum = numberNode:getChildByName("BitmapFontLabel_4")
    local remain = cardData.count - cardData.chooseNum
    if remain > 0 then
        numberNode:setVisible(true)
        maxNum:setString("X" .. remain)
    else
        numberNode:setVisible(false)
    end
    local mask = cardRoot:getChildByName("mask")
    mask:setVisible(remain == 0)
end

function CardRecoverExchangeList:createSlide()
    if self.m_slider then
        self.m_slider:removeFromParent()
    end

    local ExchangeSliderBg = string.format(CardResConfig.ExchangeSliderBg, "common" .. CardSysRuntimeMgr:getCurAlbumID())
    local ExchangeSliderMark = string.format(CardResConfig.ExchangeSliderMark, "common" .. CardSysRuntimeMgr:getCurAlbumID())

    self.m_slider = ccui.Slider:create()
    self.m_slider:setTouchEnabled(false)
    self.m_slider:loadBarTexture(ExchangeSliderBg)
    self.m_slider:loadProgressBarTexture(ExchangeSliderBg)
    self.m_slider:loadSlidBallTextures(ExchangeSliderMark)
    self.m_slider:addEventListenerSlider(handler(self, self.sliderMoveEvent))
    self.m_slider:setRotation(-90)
    self.m_slider:setScale(0.8)
    self.m_slider:setMaxPercent(self.m_vCellSize.height * self.m_CurCellsMaxNum - self.m_tableViewSize.height)
    self.m_slider:setPercent((self.m_vCellSize.height * self.m_CurCellsMaxNum - self.m_tableViewSize.height))
    self.m_slider:setPosition(self.m_tableViewSize.width - 30, self.m_tableViewSize.height / 2)
    self:addChild(self.m_slider)

    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(ExchangeSliderBg)
    local progressFile = cc.Sprite:create(ExchangeSliderBg)
    local thumbFile = cc.Sprite:create(ExchangeSliderMark)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(ExchangeSliderBg)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)

    if #self.m_listData <= countOfOneLine then
        self.m_slider:setVisible(false)
    else
        self.m_slider:setVisible(true)
    end

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end

-- slider 滑动事件 --
function CardRecoverExchangeList:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getPercent()
        self.m_tableView:setContentOffset(cc.p(0, -sliderOff))
    end
    self.m_moveTable = true
end

-- tableView回调事件 --
--滚动事件
function CardRecoverExchangeList:scrollViewDidScroll(view)
    self.m_moveSlider = false

    if self.m_moveTable == true then
        local offY = self.m_tableView:getContentOffset().y

        if self.m_slider ~= nil then
            local sliderY = self.m_slider:getPercent()
            self.m_slider:setPercent(-offY)
        end
    end
    self.m_moveSlider = true
end

function CardRecoverExchangeList:isShowStar(_cardType)
    if _cardType == CardSysConfigs.CardType.link or CardSysRuntimeMgr:isStatueCard(_cardType) then
        return true
    end
    return false
end

function CardRecoverExchangeList:isShowBigPrize(cardType)
    if cardType == CardSysConfigs.CardType.golden or cardType == CardSysConfigs.CardType.puzzle or CardSysRuntimeMgr:isStatueCard(cardType) then
        return true
    end
    return false
end

--显示倍数
function CardRecoverExchangeList:updateMul(lb_mul, cardData)
    local mul = 0
    if cardData.type == CardSysConfigs.CardType.golden then
        local additionList = globalData.constantData.CARD_GoldenCardCoinAddition
        mul = (additionList and additionList[cardData.star] or 0) * 100
    elseif cardData.type == CardSysConfigs.CardType.puzzle then
        mul = (globalData.constantData.CARD_PuzzleCardCoinAddition or 0) * 100
    elseif CardSysRuntimeMgr:isStatueCard(cardData.type) then
        local additionList = globalData.constantData.CARD_StatueCardCoinAddition
        mul = (additionList and additionList[cardData.star] or 0) * 100
    end
    if lb_mul then
        lb_mul:setString("+" .. mul .. "%")
    end
end

function CardRecoverExchangeList:addEventMusic()
    self.m_addEventMusicIndex = (self.m_addEventMusicIndex or 0) + 1
    if self.m_addEventMusicIndex > #CardResConfig.CARD_MUSIC.RecoverAddCards then
        self.m_addEventMusicIndex = 1
    end
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.RecoverAddCards[self.m_addEventMusicIndex])
end

-- 处理“+”按钮事件 --
function CardRecoverExchangeList:addEvent(nTag)
    self:addEventMusic()
    local nIndex = nTag
    local cardData = self.m_listData[nIndex]
    local pControlNode = self.m_ControlNodeList[nIndex]
    if cardData.chooseNum == nil then
        cardData.chooseNum = 0
    end
    local starNum = cardData.chooseNum
    starNum = math.min(cardData.count, starNum + 1)
    if starNum == cardData.chooseNum then
        return
    end
    cardData.chooseNum = starNum
    -- 播放金卡动画 --
    if cardData.type == CardSysConfigs.CardType.golden then
        self:runCsbAction("golden")
    end
    -- 处理卡片面板 --
    self:updataSelectCell(pControlNode, cardData)
    -- 处理星星数量相加 --
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_RECOVER_EXCHANGE_CLICK_CELL, {isAddLink = cardData.type == CardSysConfigs.CardType.link})
end

-- 处理“-”按钮事件 --
function CardRecoverExchangeList:subEvent(nTag)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
    local nIndex = nTag
    local cardData = self.m_listData[nIndex]
    local pControlNode = self.m_ControlNodeList[nIndex]
    if cardData.chooseNum == nil then
        cardData.chooseNum = 0
    end
    local starNum = cardData.chooseNum
    starNum = math.max(0, starNum - 1)
    if starNum == cardData.chooseNum then
        return
    end
    cardData.chooseNum = starNum
    -- 处理卡片面板 --
    self:updataSelectCell(pControlNode, cardData)
    -- 处理星星数量相加 --
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_RECOVER_EXCHANGE_CLICK_CELL)
end

-- 节点选中的事件 --
function CardRecoverExchangeList:addNodeClicked(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.nodeClickedEvent))
end
function CardRecoverExchangeList:nodeClickedEvent(sender, eventType)
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

function CardRecoverExchangeList:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "myBtnAdd" then
        self:addEvent(tag)
    elseif name == "myBtnSub" then
        self:subEvent(tag)
    elseif name == "myTouch" then
        self:addEvent(tag)
    end
end

return CardRecoverExchangeList
