--[[
    CardWildExcView
    集卡系统 wild卡兑换界面
]]
-- 默认规则：如果当前赛季的卡都拥有那么默认全部显示出来

local CardWildExcView = class("CardWildExcView", BaseLayer)

function CardWildExcView:initDatas(callFunc1, enterType, fileFunc)
    self.m_callFunc1 = callFunc1
    self.m_enterType = enterType
    self.m_fileFunc = fileFunc
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardWildExcViewRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self:initData()
    self:setName("CardWildExcView")
end

-- 初始化UI --
-- callFunc1 直接关闭兑换界面后回调
function CardWildExcView:initUI(callFunc1)
    CardWildExcView.super.initUI(self)
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end
    -- self:createCsbNode(string.format(CardResConfig.commonRes.CardWildExcViewRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)

    -- self.m_callFunc1 = callFunc1
    -- self:initNode()
    -- self:initData()
    -- self:initView()

    self:runCsbAction("idle")
    -- self:commonShow(
    --     self.m_rootNode,
    --     function()
    --         if self.isClose then
    --             return
    --         end
    --         gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_FRAMELOAD_START)
    --         self:runCsbAction("idle", true)
    --     end
    -- )
end

function CardWildExcView:onShowedCallFunc()
    if self.isClose then
        return
    end
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_FRAMELOAD_START)
    self:runCsbAction("idle", true)
end

--适配方案 --
-- function CardWildExcView:getUIScalePro()
--     local x = display.width / DESIGN_SIZE.width
--     local y = display.height / DESIGN_SIZE.height
--     local pro = x / y
--     if globalData.slotRunData.isPortrait == true then
--         pro = 0.7
--     end
--     return pro
-- end

-- 初始化数据 --
function CardWildExcView:initData()
    self.isClose = false

    -- 当前选中的卡牌 --
    CardSysManager:getWildExcMgr():setSelCardId(nil)

    self.m_yearList = CardSysManager:getWildExcMgr():getYearTabList()
    if #self.m_yearList == 0 then
        return
    end
    self.m_curYearIndex = 1 -- #self.m_yearList
end

function CardWildExcView:initCsbNodes()
    self.m_rootNode = self:findChild("root")

    self.timeNode = self:findChild("time")

    self.m_firstTabNode = self:findChild("Node_firstTab")
    self.m_secondTabNode = self:findChild("Node_secondTab")

    self.m_btnExchange = self:findChild("Button_3")
    -- self.m_btnExchange:setEnabled(false)
    self:setButtonLabelDisEnabled("Button_3", false)

    self.m_btnDontHaveMark = self:findChild("Button_3_0")
    self.m_btnDontHave = self:findChild("btn_dontHave")
    self:addClick(self.m_btnDontHave)

    self.m_TableViewRoot = self:findChild("tableViewRoot")

    self.m_wildLogoNodes = {}
    for i = 1, 4 do
        local sp = self:findChild("wild_logo_" .. i)
        self.m_wildLogoNodes[#self.m_wildLogoNodes + 1] = sp
    end
end

function CardWildExcView:initView()
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

function CardWildExcView:initPageTitle()
    -- cxc 2022年01月05日14:56:04只保留4个赛季放一个页签里
    -- self.m_yearTabUI = util_createView("GameModule.Card.commonViews.CardTabUI", "year", self.m_yearList, self.m_curYearIndex)
    -- self.m_firstTabNode:addChild(self.m_yearTabUI)

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

    -- 新手期集卡不显示页签，显示固定文本
    if self.m_noviceTabNode then
        self.m_noviceTabNode:setVisible(CardSysManager:isNovice() == true)
    end
    self.m_secondTabNode:setVisible(CardSysManager:isNovice() == false)

    local albumUI = util_createView("GameModule.Card.commonViews.CardTabUI", "album", albumsList, 1)
    self.m_secondTabNode:addChild(albumUI)
    albumUI:setVisible(true)
    self.m_albumTabUIs[#self.m_albumTabUIs + 1] = {ui = albumUI, curAlbumIndex = 1}
    self.m_allAlbumsList = albumsList

    -- for i = 1, #self.m_yearList do
    --     local albumTabData = self.m_yearList[i].albums
    --     local curAlbumIndex = #albumTabData
    --     local albumUI = util_createView("GameModule.Card.commonViews.CardTabUI", "album", albumTabData, curAlbumIndex)
    --     self.m_secondTabNode:addChild(albumUI)
    --     albumUI:setVisible(i == self.m_curYearIndex)
    --     self.m_albumTabUIs[#self.m_albumTabUIs + 1] = {ui = albumUI, curAlbumIndex = curAlbumIndex}
    -- end

    self:initUnHaveBtn()
end

function CardWildExcView:initUnHaveBtn()
    local curAlbumIndex = self.m_albumTabUIs[#self.m_albumTabUIs].curAlbumIndex
    local albumId = self.m_allAlbumsList[curAlbumIndex].albumId
    -- local albums = self.m_yearList[self.m_curYearIndex].albums
    -- if albums and #albums > 0 then
    --     local curAlbumIndex = self.m_albumTabUIs[self.m_curYearIndex].curAlbumIndex
    --     albumId = albums[curAlbumIndex].albumId
    -- end
    if not albumId then
        return
    end

    local albumData = CardSysManager:getWildExcMgr():getAlbumDataByAlbumId(albumId, true)
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

function CardWildExcView:showCardList(isInit)
    -- 创建
    if not self.m_tableViews then
        self.m_tableViews = {}
    end
    -- 隐藏
    for k, v in pairs(self.m_tableViews) do
        if v then
            if v.allList then
                v.allList:setVisible(false)
                v.allList:setLocalZOrder(10)
            end
            if v.noOwnList then
                v.noOwnList:setVisible(false)
                v.noOwnList:setLocalZOrder(10)
            end
        end
    end

    -- local curAlbumIndex = self.m_albumTabUIs[self.m_curYearIndex].curAlbumIndex
    local curAlbumIndex = self.m_albumTabUIs[#self.m_albumTabUIs].curAlbumIndex
    if not curAlbumIndex then
        return
    end
    -- local albumId = self.m_yearList[self.m_curYearIndex].albums[curAlbumIndex].albumId
    local albumId = self.m_allAlbumsList[curAlbumIndex].albumId
    if not albumId then
        return
    end

    if not self.m_tableViews[albumId] then
        self.m_tableViews[albumId] = {}
    end

    if CardSysManager:getWildExcMgr():getShowAll() == true then
        if not self.m_tableViews[albumId].allList then
            local albumData = CardSysManager:getWildExcMgr():getAlbumDataByAlbumId(albumId)
            if albumData and albumData.cardClans and #albumData.cardClans > 0 then
                release_print("!!! ----- createSlide 1 ----- start")
                local list = util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildExcList", self.m_TableViewRoot, albumData, not isInit)
                release_print("!!! ----- createSlide 1 ----- addChild")
                self.m_TableViewRoot:addChild(list)
                release_print("!!! ----- createSlide 1 ----- end")

                self.m_tableViews[albumId].allList = list
                self.m_tableViews[albumId].showCount = (self.m_tableViews[albumId].showCount or 0) + 1 -- showCount:每次点击展示时+1，可以用来做内存优化
            end
        end
        if self.m_tableViews[albumId].allList then
            self.m_tableViews[albumId].allList:setVisible(true)
            self.m_tableViews[albumId].allList:setLocalZOrder(100)
        end
    else
        if not self.m_tableViews[albumId].noOwnList then
            local albumData = CardSysManager:getWildExcMgr():getAlbumDataByAlbumId(albumId, true)
            if albumData and albumData.cardClans and #albumData.cardClans > 0 then
                release_print("!!! ----- createSlide 2 ----- start")
                local list = util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildExcList", self.m_TableViewRoot, albumData, not isInit)
                release_print("!!! ----- createSlide 2 ----- addChild")
                self.m_TableViewRoot:addChild(list)
                release_print("!!! ----- createSlide 2 ----- end")
                self.m_tableViews[albumId].noOwnList = list
                self.m_tableViews[albumId].showCount = (self.m_tableViews[albumId].showCount or 0) + 1 -- showCount:每次点击展示时+1，可以用来做内存优化
            end
        end
        if self.m_tableViews[albumId].noOwnList then
            self.m_tableViews[albumId].noOwnList:setVisible(true)
            self.m_tableViews[albumId].noOwnList:setLocalZOrder(100)
        end
    end
end

function CardWildExcView:canOpenConfirm()
    local expireAt = CardSysManager:getWildExcMgr():getRunData():getExpireAt()
    local finalTime = math.floor(expireAt / 1000)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local remainTime = finalTime - curTime
    return remainTime > 0
end

-- 倒计时 --
function CardWildExcView:initCountDown()
    local expireAt = CardSysManager:getWildExcMgr():getRunData():getExpireAt()
    local finalTime = math.floor(expireAt / 1000)
    local curTime = globalData.userRunData.p_serverTime / 1000
    local remainTime = math.max(0, finalTime - curTime)
    self.timeNode:setString(tostring(util_count_down_str(remainTime)))

    self.m_countDownTime =
        util_schedule(
        self,
        function()
            local curTime = globalData.userRunData.p_serverTime / 1000
            remainTime = math.max(0, finalTime - curTime)
            self.timeNode:setString(tostring(util_count_down_str(remainTime)))
            if remainTime <= 0 then
                if self.m_countDownTime ~= nil then
                    self:stopAction(self.m_countDownTime)
                end
                self.m_countDownTime = nil
                CardSysManager:getWildExcMgr():closeWildExcView(1)
                CardSysManager:getWildExcMgr():closeWildConfirm()
                CardSysManager:getWildExcMgr():closeWildExit()
                CardSysManager:enterCardCollectionSys()
            end
        end,
        1
    )
end

function CardWildExcView:initWildLogo()
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

function CardWildExcView:exchangeSelectType()
    local bEnabled = self.m_btnDontHaveMark:isEnabled()
    self.m_btnDontHaveMark:setEnabled(not bEnabled)
    CardSysManager:getWildExcMgr():setShowAll(not bEnabled)
    self:showCardList()
end

-- 点击按钮去兑换 --
function CardWildExcView:goToExcahnge()
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

-- 点击事件 --
function CardWildExcView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_showConfirm then
        return
    end
    if self.m_neting == true then
        return
    end    

    if name == "Button_1" then
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
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
            CardSysManager:getWildExcMgr():closeWildExcView(1)
        end
    elseif name == "Button_3" then
        -- 去兑换 --
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
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:exchangeSelectType()
    end
end

-- 关闭事件 --
function CardWildExcView:closeUI(closeType)
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
            if self.m_fileFunc then
                self.m_fileFunc()
            end
        end
    end
    CardWildExcView.super.closeUI(self, callback)
end

function CardWildExcView:onEnter()
    CardWildExcView.super.onEnter(self)
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getWildExcMgr():closeWildExcView(1)
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    -- 点击年度页签
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.index then
                for i = 1, #self.m_albumTabUIs do
                    self.m_albumTabUIs[i].ui:setVisible(i == params.index)
                end
                -- 更新tableview
                self.m_curYearIndex = params.index
                self:showCardList()
            end
        end,
        CardSysConfigs.ViewEventType.CARD_YEAR_TAB_UPDATE
    )

    -- 点击季度页签
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.index then
                -- 更新tableview
                -- self.m_albumTabUIs[self.m_curYearIndex].curAlbumIndex = params.index
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
            -- self.m_btnExchange:setEnabled(CardSysManager:getWildExcMgr():getSelCardId() ~= nil)
            self:setButtonLabelDisEnabled("Button_3", CardSysManager:getWildExcMgr():getSelCardId() ~= nil)
        end,
        CardSysConfigs.ViewEventType.CARD_WILD_EXCHANGE_UPDATE_BTN_GO
    )
end

-- function CardWildExcView:onExit()
--     gLobalNoticManager:removeAllObservers(self)
--     CardSysManager:notifyResume()
-- end

return CardWildExcView
