--[[
    CardWildExcViewNew
    集卡系统 wild卡兑换界面
]]
-- 默认规则：如果当前赛季的卡都拥有那么默认全部显示出来

local CardWildExcViewNew = class("CardWildExcViewNew", BaseLayer)

function CardWildExcViewNew:initDatas(callFunc1, enterType)
    self.m_callFunc1 = callFunc1
    self.m_enterType = enterType
    self:setPauseSlotsEnabled(true)

    self:setLandscapeCsbName("CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/cash_wild_exchange_layer.csb")

    -- 当前选中的卡牌 --
    CardSysManager:getWildExcMgr():setSelCardId(nil)

    self.m_yearList = CardSysManager:getWildExcMgr():getYearTabList()
    if #self.m_yearList == 0 then
        return
    end
    self.m_curYearIndex = 1
end

function CardWildExcViewNew:initCsbNodes()
    self.timeNode = self:findChild("time")

    -- self.m_firstTabNode = self:findChild("Node_firstTab")
    self.m_secondTabNode = self:findChild("Node_secondTab")
    self.m_noviceTabNode = self:findChild("Node_NoviceTab")

    self.m_btnExchange = self:findChild("Button_3")
    -- self.m_btnExchange:setEnabled(false)
    self:setButtonLabelDisEnabled("Button_3", false)

    self.m_btnDontHaveMark = self:findChild("Button_3_0")
    self.m_btnDontHave = self:findChild("btn_dontHave")
    self:addClick(self.m_btnDontHave)

    self.m_TableViewRoot = self:findChild("tableViewRoot")
    self.m_listView = self:findChild("ListView_1")

    self.m_wildLogoNodes = {}
    for i = 1, 4 do
        local sp = self:findChild("wild_logo_" .. i)
        self.m_wildLogoNodes[#self.m_wildLogoNodes + 1] = sp
    end
end

function CardWildExcViewNew:initView()
    assert(self.m_yearList and #self.m_yearList > 0, "!!! self.m_yearList === {}, DATA ERROR!")

    -- 倒计时 --
    self:initCountDown()

    -- 根据兑换掉的wild卡显示 --
    self:initWildLogo()

    -- 设置赛季按钮显示与否 --
    self:initPageTitle()

    -- list
    self:showCardList(true)
end

-- 倒计时 --
function CardWildExcViewNew:initCountDown()
    local expireAt = CardSysManager:getWildExcMgr():getRunData():getExpireAt()
    local finalTime = math.floor(expireAt / 1000)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local remainTime = finalTime - curTime
    self.timeNode:setString(tostring(util_count_down_str(remainTime)))

    self.m_countDownTime =
        util_schedule(
        self,
        function()
            local curTime = globalData.userRunData.p_serverTime / 1000
            remainTime = finalTime - curTime
            self.timeNode:setString(tostring(util_count_down_str(remainTime)))
            if remainTime <= 0 then
                if self.m_countDownTime ~= nil then
                    self:stopAction(self.m_countDownTime)
                end
                self.m_countDownTime = nil
                CardSysManager:getWildExcMgr():closeWildExcView(1)
                CardSysManager:enterCardCollectionSys()
            end
        end,
        1
    )
end

function CardWildExcViewNew:initWildLogo()
    local CardType = CardSysManager:getWildExcMgr():getCurrentWildExchangeType()
    local showIndex = nil
    if CardType == CardSysConfigs.CardType.wild then
        showIndex = 1
    elseif CardType == CardSysConfigs.CardType.wild_normal then
        showIndex = 2
    elseif CardType == CardSysConfigs.CardType.wild_link then
        showIndex = 3
    elseif CardType == CardSysConfigs.CardType.wild_golden then
        showIndex = 4
    end

    -- logo
    for i = 1, #self.m_wildLogoNodes do
        local sp = self.m_wildLogoNodes[i]
        sp:setVisible(i == showIndex)
    end
end

function CardWildExcViewNew:initPageTitle()
    self.m_albumTabUIs = {}
    -- yearList是倒序的2022-2021-2020
    local albumsList = {}
    local maxTabCount = 4 -- 最多显示4个赛季
    local curYearAlbumsCount  -- 本年度赛季数
    for yearIdx = 1, #self.m_yearList do
        local albumTabData = self.m_yearList[yearIdx].albums
        if not curYearAlbumsCount then
            curYearAlbumsCount = #albumTabData
        end
        for albumIdx = #albumTabData, 1, -1 do
            if #albumsList > maxTabCount then
                break
            end

            table.insert(albumsList, albumTabData[albumIdx])
        end

        if #albumsList > maxTabCount then
            break
        end
    end
    self.m_allAlbumsList = albumsList

    -- 新手期集卡不显示页签，显示固定文本
    if self.m_noviceTabNode then
        self.m_noviceTabNode:setVisible(CardSysManager:isNovice() == true)
    end
    self.m_secondTabNode:setVisible(CardSysManager:isNovice() == false)

    local albumUI = util_createView("GameModule.Card.commonViews.CardTabUI", "album", albumsList, 1)
    self.m_secondTabNode:addChild(albumUI)
    albumUI:setVisible(true)
    self.m_albumTabUIs[#self.m_albumTabUIs + 1] = {ui = albumUI, curAlbumIndex = 1}
    
    self:initUnHaveBtn()
end

function CardWildExcViewNew:initUnHaveBtn()
    local curAlbumIndex = self.m_albumTabUIs[#self.m_albumTabUIs].curAlbumIndex
    local albumId = self.m_allAlbumsList[curAlbumIndex].albumId
    if not albumId then
        return
    end

    local albumData = CardSysManager:getWildExcMgr():getAlbumDataByAlbumId(albumId, CardSysManager:getWildExcMgr():getShowAll())
    -- 如果当前的卡数量为0，默认全部显示
    if albumData and albumData.cardClans and #albumData.cardClans == 0 then
        -- 全部显示
        CardSysManager:getWildExcMgr():setShowAll(true)
        self.m_btnDontHaveMark:setEnabled(true)
    else
        -- 只显示没有的卡
        CardSysManager:getWildExcMgr():setShowAll(false)
        self.m_btnDontHaveMark:setEnabled(false)
    end
end

function CardWildExcViewNew:showCardList(isInit)
    local totalCardNum = #self.m_cardDatas

    local CardDropChip = util_require("GameModule.Card.commonViews.CardDrop.CardDropChip")
    local chipSize = CardDropChip:getViewSize()
    local layoutSize = cc.size(self.m_listWidth, chipSize.height)

    self.m_chips = {}
    self.m_nadoChips = {}
    self.m_storeTicketIndex = 0
    for i = 1, self.m_rowNum do
        local layout = ccui.Layout:create()

        -- layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        -- layout:setBackGroundColor(cc.c3b(255, 0, 0))

        layout:setAnchorPoint(cc.p(0.5, 0.5))
        layout:setContentSize(layoutSize)
        local layoutNode = cc.Node:create()
        layout:addChild(layoutNode)
        layoutNode:setPosition(cc.p(layoutSize.width / 2, layoutSize.height / 2))
        local UIList = {}
        for j = 1, self.m_colNum do
            local cardIndex = j + (i - 1) * self.m_colNum
            if cardIndex <= totalCardNum then
                local cardData = self.m_cardDatas[cardIndex]
                local chip = util_createView("GameModule.Card.commonViews.CardDrop.CardDropChip", cardData)
                layoutNode:addChild(chip)
                local chipSize = chip:getViewSize()
                table.insert(UIList, {node = chip, anchor = cc.p(0.5, 0.5), scale = 1, size = cc.size(chipSize.width + 6, chipSize.height + 6)})
                table.insert(self.m_chips, chip)
                if cardData.type == CardSysConfigs.CardType.link then
                    table.insert(self.m_nadoChips, chip)
                end
            end
        end
        util_alignCenter(UIList)
        self.m_listView:pushBackCustomItem(layout)
    end
end

function CardWildExcViewNew:exchangeSelectType()
    local bEnabled = self.m_btnDontHaveMark:isEnabled()
    self.m_btnDontHaveMark:setEnabled(not bEnabled)
    CardSysManager:getWildExcMgr():setShowAll(not bEnabled)
    self:showCardList()
end

-- 点击按钮去兑换 --
function CardWildExcViewNew:goToExcahnge()
    if self.m_neting == true then
        return
    end
    self.m_neting = true
    -- ok 最后一步 找到选中的卡牌id --
    local cardId = CardSysManager:getWildExcMgr():getSelCardId()
    -- wild卡请求兑换接口 --
    local tExtraInfo = {
        ["newCardId"] = cardId,
        ["type"] = CardSysManager:getWildExcMgr():getCurrentWildExchangeType()
    }

    local excSuccess = function(tData)
        self.m_neting = false
    end
    local excFaild = function(errorCode, errorData)
        self.m_neting = false
    end
    CardSysManager:getWildExcMgr():sendCardExchangeRequest(tExtraInfo, excSuccess, excFaild)
end

function CardWildExcViewNew:canOpenConfirm()
    local expireAt = CardSysManager:getWildExcMgr():getRunData():getExpireAt()
    local finalTime = math.floor(expireAt / 1000)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local remainTime = finalTime - curTime
    return remainTime > 0
end

-- 点击事件 --
function CardWildExcViewNew:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_showConfirm then
        return
    end

    if name == "Button_1" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        if self:canOpenConfirm() then
            CardSysManager:getWildExcMgr():showWildExit(
                function()
                    CardSysManager:getWildExcMgr():closeWildExcView(1)
                    if self.m_enterType and self.m_enterType == "lobby" then
                        CardSysRuntimeMgr:setIgnoreWild(true)
                        CardSysManager:enterCardCollectionSys()
                    end
                end
            )
        else
            CardSysManager:getWildExcMgr():closeWildExcView(1)
        end
    elseif name == "Button_3" then
        -- 去兑换 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)

        local selCardId = CardSysManager:getWildExcMgr():getSelCardId()
        if not selCardId then
            return
        end
        local cardData = CardSysManager:getWildExcMgr():getCardDataByCardId(selCardId)
        if not cardData then
            return
        end
        self.m_showConfirm = true
        CardSysManager:getWildExcMgr():showWildConfirm(
            cardData,
            function()
                if not tolua.isnull(self) and self.goToExcahnge then
                    self:goToExcahnge()
                end
            end,
            function()
                self.m_showConfirm = false
            end
        )
    elseif name == "btn_dontHave" then
        self:exchangeSelectType()
    end
end

function CardWildExcViewNew:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardWildExcViewNew.super.playShowAction(self, "show")
end

function CardWildExcViewNew:onShowedCallFunc()
    if CardSysManager:getWildExcMgr():getCurrentWildExchangeType() == CardSysConfigs.CardType.wild_golden then
        self:runCsbAction("golden", true, nil, 60)
    else
        self:runCsbAction("idle", true, nil, 60)
    end
end

function CardWildExcViewNew:onEnter()
    CardWildExcViewNew.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getWildExcMgr():closeWildExcView(1)
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    -- 点击季度页签
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.index then
                -- 更新tableview
                self.m_albumTabUIs[#self.m_albumTabUIs].curAlbumIndex = params.index
                self:showCardList()
            end
        end,
        CardSysConfigs.ViewEventType.CARD_ALBUM_TAB_UPDATE
    )

    -- 更新兑换按钮
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setButtonLabelDisEnabled("Button_3", CardSysManager:getWildExcMgr():getSelCardId() ~= nil)
        end,
        CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_UPDATE_BTN_GO
    )

    -- -- 新手期结束
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         CardSysManager:getWildExcMgr():closeWildExcView(1)
    --     end,
    --     ViewEventType.CARD_NOVICE_OVER
    -- )
end

-- 关闭事件 --
function CardWildExcViewNew:closeUI(closeType)
    if self.isClose then
        return
    end
    self.isClose = true

    if self.m_countDownTime ~= nil then
        self:stopAction(self.m_countDownTime)
        self.m_countDownTime = nil
    end

    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_FRAMELOAD_CLEARUP)
    local callback = function()
        if closeType == 1 then
            -- 直接关闭兑换界面没有进行兑换事件（不进行兑换后的掉落），直接调用回调函数
            if self.m_callFunc1 then
                self.m_callFunc1()
            end
        elseif closeType == 2 then
            -- 兑换事件，需要掉落，要将回调函数放在掉落之后再调用
            CardSysManager:doWildExchange()
        end
    end
    CardWildExcViewNew.super.closeUI(self, callback)
end

return CardWildExcViewNew
