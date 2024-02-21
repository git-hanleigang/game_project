--[[
    回收兑换面板
]]
local CardRecoverExchangeView = class("CardRecoverExchangeView", BaseLayer)
local PAGE_COUNT = 4

function CardRecoverExchangeView:initDatas()
    CardRecoverExchangeView.super.initDatas(self)
    self.isClose = false
    -- 当前选择 --
    self.m_CurStarNum = 0
    self.m_onlyShowSelected = false --只显示选中
    self.m_canShowOnlySelectedBtn = false --可否使用只显示选中
    self.m_didAISelect = false --使用一键选择
    self.m_loadingSpeed = 0.1 --进度条增长速度
    self.m_hasShowFullAct = false --进度集满动画
    self.m_keyCardsMap = {} --选择tab的卡片存储容器
    -- 记录所有+-控制节点 --
    self.m_ControlNodeList = {}
    local yearList = CardSysManager:getRecoverMgr():getYearTabList()
    self.m_yearList = {}
    local maxTabCount = 4 -- 最多显示4个赛季
    for yearIdx = 1, math.min(maxTabCount, #yearList) do
        table.insert(self.m_yearList, yearList[yearIdx])
    end

    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardRecoverSelViewRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
end

function CardRecoverExchangeView:initView()
    -- 初始化卡片显示列表 --
    self:initPage()
    self:showCardsList()
    self:updateOnlyShowSelectBtnStatus()
    self:updateAISelectBtnStatus()
    self:runCsbAction("idle")
end

-- 初始化节点数据 --
function CardRecoverExchangeView:initCsbNodes()
    local touchPanel =  self:findChild("touchPanel") 
    touchPanel:setSwallowTouches(false)
    self:addNodeClicked(touchPanel)
    self.m_tableViewRoot = self:findChild("tableViewRoot")
    self.m_nocardsNode = self:findChild("Node_Nocards")

    -- 满了的tip节点 --
    self.m_tipNode = self:findChild("Node_tips")
    self.m_sp_go_war = self:findChild("sp_go_war")
    self.m_sp_go_war:setVisible(false)
    
    self.m_btnOnlyShowLight = self:findChild("btn_onlyshow_light")
    self.m_btnOnlyShowDark = self:findChild("btn_onlyshow_dark")


    local node_jiangli_Extra1 = self:findChild("node_jiangli_Extra1")
    local node_jiangli_Extra2 = self:findChild("node_jiangli_Extra2")

    self.m_nodeExtraCoinMark1 = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverAddGoldRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    node_jiangli_Extra1:addChild(self.m_nodeExtraCoinMark1)
            
    self.m_nodeExtraCoinMark2 = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverAddGoldRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    node_jiangli_Extra2:addChild(self.m_nodeExtraCoinMark2)
    
    self.m_nodeExtraCoinMark1:setVisible(false)
    self.m_nodeExtraCoinMark2:setVisible(false)
    
    -- 当前拥有 --
    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    local wheelCfg = yearData:getWheelConfig()
    
    -- 当前选择 --
    self.m_CurStarNum = 0
    self.m_selLevelInfo = CardSysManager:getRecoverMgr():getCardWheelSelLevel()
    self.m_MaxStarNum = self.m_selLevelInfo.NeededStars

    -- 选择数量和百分比 --
    self.m_BFont_StarNumNode = self:findChild("lb_LoadingBar_number")
    self.m_LdBar_StarNumNode = self:findChild("LoadingBar_1")
    self.m_BFont_StarNumNode:setString(self.m_CurStarNum .. "/" .. self.m_MaxStarNum)
    self.m_LdBar_StarNumNode:setPercent(self.m_CurStarNum / self.m_MaxStarNum * 100)
    self.m_sp_LoadingBar_star = self:findChild("sp_LoadingBar_star")
    
    -- 赢得金币数量 --
    self.m_BFnt_MaxCoins = self:findChild("lb_jiangli_coinnumber")
    self.m_BFnt_MaxCoins:setString(util_formatCoins(tonumber(self.m_selLevelInfo.MaxCoins), 30))

    -- 设置金币左右字体的位置 --
    local pNodeWinUpToText = self:findChild("sp_jiangli_word1")
    local pNodeCoinsText = self:findChild("sp_jiangli_word2")

    local pNodeWinUpToSize = pNodeWinUpToText:getContentSize()
    local pNodeCoinsSize = pNodeCoinsText:getContentSize()

    local pMaxCoinsPos = self.m_BFnt_MaxCoins:getPositionX()
    local pMaxCoinsSize = self.m_BFnt_MaxCoins:getContentSize()

    pNodeWinUpToText:setPositionX(pMaxCoinsPos - pMaxCoinsSize.width / 2  - pNodeWinUpToSize.width / 2 - 3)
    pNodeCoinsText:setPositionX(pMaxCoinsPos + pMaxCoinsSize.width / 2  + pNodeCoinsSize.width / 2 + 3)
    -- GO按钮 --
    self.m_goToSpinBtn = self:findChild("btn_go")
    self.m_goToSpinBtn:setTouchEnabled(false)
    self.m_goToSpinBtn:setBright(false)

    self.m_chooseBtn = self:findChild("btn_Choose")
    self.m_deselect = self:findChild("btn_Deselect")
    
end

function CardRecoverExchangeView:initPage()
    self.m_curYearIndex = -1  --全部
    self.m_curTypeIndex = -1  --全部
    self.m_curStarIndex = -1  --全部
    self.m_yearNode = self:findChild("Node_year")
    self.m_qualityNode = self:findChild("Node_quality")
    self.m_starNode = self:findChild("Node_star")

    local yearList = {{tabText = "ALL YEAR", albumId = -1,count = -1}}
    for i = 1, #self.m_yearList do
        local oneYear = {}
        oneYear.tabText = self.m_yearList[i].tabText
        oneYear.albumId = self.m_yearList[i].albumId
        yearList[#yearList +1] = oneYear
    end
    if self.m_yearTabUI == nil then
        self.m_yearTabUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeTabList", "year", yearList, self.m_curYearIndex)
        self.m_yearNode:addChild(self.m_yearTabUI)
    end
    
    local typeList = {{tabText = "ALL chips", type = "All",count = -1}}
    if #self.m_yearList > 0 and self.m_yearList[1] then
        local oneTypeList = self.m_yearList[1].typeCards
        for i,v in ipairs(oneTypeList) do
            local oneType = {}
            oneType.tabText = v.starText
            oneType.type = v.starText
            oneType.count = #v.cards
            typeList[#typeList +1] = oneType
        end
    end
    if self.m_qualityTabUI == nil then
        self.m_qualityTabUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeTabList", "type", typeList, self.m_curTypeIndex)
        self.m_qualityNode:addChild(self.m_qualityTabUI)
    end
    
    local starList = {{tabText = "ALL Star", star = -1,count = -1}}
    if #self.m_yearList > 0 and self.m_yearList[1] then
        local oneStarList = self.m_yearList[1].starCards
        for i,v in ipairs(oneStarList) do
            local oneStar= {}
            oneStar.tabText = v.starText
            oneStar.star = i
            oneStar.count = #v.cards
            starList[#starList +1] = oneStar
        end 
    end
    if self.m_starTabUI == nil then
        self.m_starTabUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeTabList", "star", starList, self.m_curStarIndex)
        self.m_starNode:addChild(self.m_starTabUI)
    end
end

function CardRecoverExchangeView:canClick()
    if self.isClose then
        return false
    end
    return true
end
-- 点击事件 --
function CardRecoverExchangeView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self:canClick() then
        return
    end
    if name == "btn_close" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:getRecoverMgr():closeRecoverExchangeView()
    elseif name == "btn_go" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- go to exchange --
        self:goToExchangeSpin()
    elseif name == "btn_onlyshow_light" or name == "btn_onlyshow_dark" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:doOnlyShowSelected()
    elseif name == "btn_Choose" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- go to exchange --
        local usedNadoTypeCard = self:doAISelect()
        self:updateAISelectBtnStatus()
        self:changALlTabToALL()
        self.m_loadingSpeed = 0.25 *(self.m_MaxStarNum /15)
        self:doFinalData(usedNadoTypeCard)
    elseif name == "btn_Deselect" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- go to exchange --
        self:clearALlChoose()
        self:updateAISelectBtnStatus()
        self:changALlTabToALL()
        self.m_loadingSpeed = 0.25 *(self.m_MaxStarNum /15)
        self:doFinalData(false)
    end
end

-- 关闭事件 --
function CardRecoverExchangeView:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    self:delMaxTip()
    CardRecoverExchangeView.super.closeUI(self)
end

function CardRecoverExchangeView:onShowedCallFunc()
    if self.isClose then
        return
    end
    self:runCsbAction("idle", true, nil, 60)
end

function CardRecoverExchangeView:onEnter()
    CardRecoverExchangeView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getRecoverMgr():closeRecoverExchangeView()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    -- 点击页签
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params then
                if  params.yearIndex  and params.yearIndex ~= self.m_curYearIndex then
                    -- 更新tableview
                    self.m_curYearIndex = params.yearIndex
                    self:showCardsList()
                end
                if  params.typeIndex  and params.typeIndex ~= self.m_curTypeIndex then
                    -- 更新tableview
                    self.m_curTypeIndex = params.typeIndex
                    self:showCardsList()
                end

                if  params.starIndex  and params.starIndex ~= self.m_curStarIndex then
                    -- 更新tableview
                    self.m_curStarIndex = params.starIndex
                    self:showCardsList()
                end
            end
        end,
        CardSysConfigs.ViewEventType.CARD_EXCHANGE_TAB_UPDATE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- TODO:+-按钮操作
            self.m_loadingSpeed = 0.1
            self:doFinalData(params and params.isAddLink)
        end,
        CardSysConfigs.ViewEventType.CARD_RECOVER_EXCHANGE_CLICK_CELL
    )
end
function CardRecoverExchangeView:getCardsMapKey()
    local key = "key_" .. (self.m_curYearIndex + 2) .. (self.m_curTypeIndex + 2) .. (self.m_curStarIndex + 2)
    if self.m_onlyShowSelected == true then
        key = key .. "_only"
    end
    return key
end
-- 显示可选择卡片 --
function CardRecoverExchangeView:showCardsList()
    local typeTabList = {{tabText = "ALL chips", type = "All",count = -1}}
    local starTabList = {{tabText = "ALL Star", star = -1,count = -1}}
    local refreshTypeTabUI = false
    local refreshStarTabUI = false
    local cardList ={}
    local key = self:getCardsMapKey()
    if self.m_keyCardsMap[key] and self.m_onlyShowSelected == false then
        cardList = self.m_keyCardsMap[key].cards
        starTabList = self.m_keyCardsMap[key].starTabList
        typeTabList = self.m_keyCardsMap[key].typeTabList
    else
        if self.m_curYearIndex == -1 then
            for i=1,#self.m_yearList do
                local oneTypeList = self.m_yearList[i].typeCards
                for j = #oneTypeList,1,-1 do
                    local typeData =  oneTypeList[j]
                    local count = 0
                    for m,v in ipairs(typeData.cards) do
                        if self.m_onlyShowSelected == true then
                            if v.chooseNum and v.chooseNum > 0 then
                                count = count + v.count
                            end
                        else
                            count = count + v.count
                        end
                    end
                    if typeTabList[j+1] == nil then
                        local oneType = {}
                        oneType.tabText = typeData.starText
                        oneType.type = typeData.starText
                        oneType.count = count
                        typeTabList[j+1] = oneType
                    else
                        typeTabList[j+1].count = typeTabList[j+1].count + count
                    end
                end
            end
            if self.m_curTypeIndex == -1 then
                for i=1,#self.m_yearList do
                    local oneStarList = self.m_yearList[i].starCards
                    for j,starData in ipairs(oneStarList) do
                        local count = 0
                        for m,v in ipairs(starData.cards) do
                            if self.m_onlyShowSelected == true then
                                if v.chooseNum and v.chooseNum > 0 then
                                    count = count + v.count
                                end
                            else
                                count = count + v.count
                            end
                        end
                        if starTabList[j+1] == nil then
                            local oneStar= {}
                            oneStar.tabText = starData.starText
                            oneStar.star = j
                            oneStar.count = count
                            starTabList[#starTabList +1] = oneStar
                        else
                            starTabList[j+1].count = starTabList[j+1].count + count
                        end
                    end
                end 
                if self.m_curStarIndex == -1 then
                    for i=1,#self.m_yearList do
                        local oneTypeList = self.m_yearList[i].typeCards
                        for j = #oneTypeList,1,-1 do
                            local typeData =  oneTypeList[j]
                            local count = 0
                            for m,v in ipairs(typeData.cards) do
                                if self.m_onlyShowSelected == true then
                                    if v.chooseNum and v.chooseNum > 0 then
                                        table.insert(cardList, v)
                                    end
                                else
                                    table.insert(cardList, v) 
                                end
                            end
                        end
                    end
                else
                    for i=1,#self.m_yearList do
                        for j,v in ipairs(self.m_yearList[i].starCards[self.m_curStarIndex].cards) do 
                            if self.m_onlyShowSelected == true then
                                if v.chooseNum and v.chooseNum > 0 then
                                    table.insert(cardList, v)
                                end
                            else
                                table.insert(cardList, v) 
                            end
                        end
                    end
                end
            else
                for i=1,#self.m_yearList do
                    local oneStarList = self.m_yearList[i].typeCards[self.m_curTypeIndex].starList
                    for j,starData in ipairs(oneStarList) do
                        local count = 0
                        for m,v in ipairs(starData.cards) do
                            if self.m_onlyShowSelected == true then
                                if v.chooseNum and v.chooseNum > 0 then
                                    count = count + v.count
                                end
                            else
                                count = count + v.count
                            end
                        end
                        if starTabList[j+1] == nil then
                            local oneStar= {}
                            oneStar.tabText = starData.starText
                            oneStar.star = j
                            oneStar.count = count
                            starTabList[#starTabList +1] = oneStar
                        else
                            starTabList[j+1].count = starTabList[j+1].count + count
                        end
                    end
                end

                if self.m_curStarIndex == -1 then
                    refreshStarTabUI = true
                    for i=1,#self.m_yearList do
                        local starList = self.m_yearList[i].typeCards[self.m_curTypeIndex].starList
                        for j,starData in ipairs(starList) do
                            for k,v in ipairs(starData.cards) do
                                if self.m_onlyShowSelected == true then
                                    if v.chooseNum and v.chooseNum > 0 then
                                        table.insert(cardList, v)
                                    end
                                else
                                    table.insert(cardList, v)
                                end
                            end
                        end
                    end
                else
                    for i=1,#self.m_yearList do
                        local starData = self.m_yearList[i].typeCards[self.m_curTypeIndex].starList[self.m_curStarIndex]
                        for k,v in ipairs(starData.cards) do 
                            if self.m_onlyShowSelected == true then
                                if v.chooseNum and v.chooseNum > 0 then
                                    table.insert(cardList, v)
                                end
                            else
                                table.insert(cardList, v)
                            end
                        end
                    end
                end
            end
        else
            local oneTypeList = self.m_yearList[self.m_curYearIndex].typeCards
            for j= #oneTypeList,1,-1 do
                local typeData = oneTypeList[j]
                local count = 0
                for m,v in ipairs(typeData.cards) do
                    if self.m_onlyShowSelected == true then
                        if v.chooseNum and v.chooseNum > 0 then
                            count = count + v.count
                        end
                    else
                        count = count + v.count
                    end
                end
                if typeTabList[j+1] == nil then
                    local oneType = {}
                    oneType.tabText = typeData.starText
                    oneType.type = typeData.starText
                    oneType.count = count
                    typeTabList[j +1] = oneType
                else
                    typeTabList[j+1].count = typeTabList[j+1].count + count
                end
            end

            if self.m_curTypeIndex == -1 then
                local oneStarList = self.m_yearList[self.m_curYearIndex].starCards
                for j,starData in ipairs(oneStarList) do
                    local count = 0
                    for m,v in ipairs(starData.cards) do
                        if self.m_onlyShowSelected == true then
                            if v.chooseNum and v.chooseNum > 0 then
                                count = count + v.count
                            end
                        else
                            count = count + v.count
                        end
                    end
                    if starTabList[j+1] == nil then
                        local oneStar= {}
                        oneStar.tabText = starData.starText
                        oneStar.star = j
                        oneStar.count = count
                        starTabList[#starTabList +1] = oneStar
                    else
                        starTabList[j+1].count = starTabList[j+1].count + count
                    end
                end 
                if self.m_curStarIndex == -1 then
                    local oneTypeList = self.m_yearList[self.m_curYearIndex].typeCards
                    for j= #oneTypeList,1,-1 do
                        local typeData = oneTypeList[j]
                        for m,v in ipairs(typeData.cards) do
                            if self.m_onlyShowSelected == true then
                                if v.chooseNum and v.chooseNum > 0 then
                                    table.insert(cardList, v)
                                end
                            else
                                table.insert(cardList, v) 
                            end
                        end
                    end
                else
                    for j,v in ipairs(self.m_yearList[self.m_curYearIndex].starCards[self.m_curStarIndex].cards) do 
                        if self.m_onlyShowSelected == true then
                            if v.chooseNum and v.chooseNum > 0 then
                                table.insert(cardList, v)
                            end
                        else
                            table.insert(cardList, v) 
                        end
                    end
                end
            else
                local oneStarList = self.m_yearList[self.m_curYearIndex].typeCards[self.m_curTypeIndex].starList
                for j,starData in ipairs(oneStarList) do
                    local count = 0
                    for m,v in ipairs(starData.cards) do
                        if self.m_onlyShowSelected == true then
                            if v.chooseNum and v.chooseNum > 0 then
                                count = count + v.count
                            end
                        else
                            count = count + v.count
                        end
                    end
                    if starTabList[j+1] == nil then
                        local oneStar= {}
                        oneStar.tabText = starData.starText
                        oneStar.star = j
                        oneStar.count = count
                        starTabList[#starTabList +1] = oneStar
                    else
                        starTabList[j+1].count = starTabList[j+1].count + count
                    end
                end
                if self.m_curStarIndex == -1 then
                    local oneStarList = self.m_yearList[self.m_curYearIndex].typeCards[self.m_curTypeIndex].starList
                    for j,starData in ipairs(oneStarList) do
                        for m,v in ipairs(starData.cards) do
                            if self.m_onlyShowSelected == true then
                                if v.chooseNum and v.chooseNum > 0 then
                                    table.insert(cardList, v) 
                                end
                            else
                                table.insert(cardList, v) 
                            end
                        end
                    end
                else
                    local starData = self.m_yearList[self.m_curYearIndex].typeCards[self.m_curTypeIndex].starList[self.m_curStarIndex]
                    for k,v in ipairs(starData.cards) do
                        if self.m_onlyShowSelected == true then
                            if v.chooseNum and v.chooseNum > 0 then
                                table.insert(cardList, v) 
                            end
                        else
                            table.insert(cardList, v) 
                        end 
                    end
                end
            end
        end
        if self.m_onlyShowSelected == false then
            local mapData = {}
            mapData.cards = cardList
            mapData.starTabList = starTabList
            mapData.typeTabList = typeTabList
            self.m_keyCardsMap[key] = mapData
        end
    end

    if #typeTabList > 1 then
        self.m_qualityTabUI:refreshViewByData(typeTabList)
    end
    if  #starTabList > 1 then
        self.m_starTabUI:refreshViewByData(starTabList)
    end

    if cardList == nil or #cardList == 0 then
        self.m_nocardsNode:setVisible(true)
        if self.m_onlyShowSelected == false then
            self.m_nocardsNode:getChildByName("sp_noCard"):setVisible(true)
            self.m_nocardsNode:getChildByName("sp_noChosen"):setVisible(false)
        else
            self.m_nocardsNode:getChildByName("sp_noCard"):setVisible(false)
            self.m_nocardsNode:getChildByName("sp_noChosen"):setVisible(true)
        end
        if cardList == nil then
            return
        end
    else
        self.m_nocardsNode:setVisible(false)
    end

    if self.m_tableView == nil then
        self.m_tableView = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeList", self.m_tableViewRoot, cardList)
        self.m_tableViewRoot:addChild(self.m_tableView)
    else
        self.m_tableView:reloadDataByData(cardList)
    end
end

function CardRecoverExchangeView:doOnlyShowSelected()
    if self.m_canShowOnlySelectedBtn == false then
        return
    end
    self.m_onlyShowSelected = not self.m_onlyShowSelected
    self:updateOnlyShowSelectBtnStatus()
    self:changALlTabToALL()
end
function CardRecoverExchangeView:changALlTabToALL()
    self.m_curYearIndex = -1  --全部
    self.m_curTypeIndex = -1  --全部
    self.m_curStarIndex = -1  --全部
    self:showCardsList()
    self.m_yearTabUI:changeSelectIndexToAll()
    self.m_qualityTabUI:changeSelectIndexToAll()
    self.m_starTabUI:changeSelectIndexToAll()
end
function CardRecoverExchangeView:updateOnlyShowSelectBtnStatus()
    self.m_btnOnlyShowLight:setEnabled(self.m_canShowOnlySelectedBtn)
    self.m_btnOnlyShowDark:setEnabled(self.m_canShowOnlySelectedBtn)
    self.m_btnOnlyShowLight:setVisible(self.m_onlyShowSelected)
    self.m_btnOnlyShowDark:setVisible(not self.m_onlyShowSelected)
end

function CardRecoverExchangeView:updateAISelectBtnStatus()
    self.m_chooseBtn:setEnabled(not self.m_didAISelect)
    self.m_chooseBtn:setVisible(not self.m_didAISelect)

    self.m_deselect:setEnabled(self.m_didAISelect)
    self.m_deselect:setVisible(self.m_didAISelect)
end


function CardRecoverExchangeView:clearALlChoose()
    self.m_didAISelect = false
    self.m_onlyShowSelected = false
    self.m_hasShowFullAct = false
    for i=1,#self.m_yearList do
        local oneCards = self.m_yearList[i].cards
        for k,v in ipairs(oneCards) do
            v.chooseNum = 0
        end
    end
end

function CardRecoverExchangeView:doAISelect()
    self:clearALlChoose()
    self.m_didAISelect = true

    local chooseStar = 0
    local choseStatueFinish = false
    local choseGoldFinish = false
    for i = 1,#self.m_yearList  do
        if choseStatueFinish == false then
            local statueStarList = self.m_yearList[i].typeCards[4].starList
            if statueStarList then
                for j=#statueStarList,1,-1 do
                    if statueStarList[j].cards and #statueStarList[j].cards > 0 then
                        statueStarList[j].cards[1].chooseNum = 1
                        chooseStar = chooseStar + j* globalData.constantData.CARD_StatueCardStarAddition
                        choseStatueFinish = true
                        break
                    end
                end
            end
        end
        if chooseStar >= self.m_MaxStarNum then
            break
        end

        if choseGoldFinish == false then
            local goldStarList = self.m_yearList[i].typeCards[3].starList
            if goldStarList then
                for j=#goldStarList,1,-1 do
                    if goldStarList[j].cards and #goldStarList[j].cards > 0 then
                        goldStarList[j].cards[1].chooseNum = 1
                        chooseStar = chooseStar + j
                        choseGoldFinish = true
                        break
                    end
                end
            end
        end
        if choseStatueFinish and choseGoldFinish then
            break
        end
    end
    local doRecheck,usedNadoTypeCard,chooseStar = self:ChooseAICards(chooseStar,2,globalData.constantData.CARD_LinkCardStarAddition)
    if doRecheck == false then
        self:ChooseAICards(chooseStar,1,1)
    end
    return usedNadoTypeCard
end

function CardRecoverExchangeView:ChooseAICards(chooseStar,typeIndex,starAddition)
    local beyondRecheckCount = typeIndex == 1 and 0 or 1
    local usedThisTypeCard = false
    if self.m_MaxStarNum - chooseStar <= beyondRecheckCount then
        return false ,false ,chooseStar
    end
    local oneBeyondStarCount = 0
    local oneBeyondStarYearIndex = 0
    local oneBeyondStarIndex = 0
    local chooseFinish = false
    for i = 1 ,#self.m_yearList do
        local starList = self.m_yearList[i].typeCards[typeIndex].starList
        if starList then
            for j=1,#starList do
                if starList[j].cards and #starList[j].cards > 0 then
                    for k,v in ipairs(starList[j].cards) do
                        if typeIndex == 2 or v.count >1 then
                            local beginIndex = typeIndex == 1 and 2 or 1
                            for m = beginIndex,v.count do
                                chooseStar = chooseStar + j* starAddition
                                v.chooseNum = (m - beginIndex + 1)
                                usedThisTypeCard = true
                                if chooseStar  >= self.m_MaxStarNum then
                                    oneBeyondStarCount = chooseStar - self.m_MaxStarNum 
                                    
                                    if oneBeyondStarCount > beyondRecheckCount then
                                        oneBeyondStarYearIndex = i
                                        oneBeyondStarIndex = j
                                    end
                                    chooseFinish = true
                                    break
                                end
                            end
                        end
                        if chooseFinish then
                            break
                        end
                    end
                    if chooseStar  < self.m_MaxStarNum  and typeIndex == 1 then
                        for k,v in ipairs(starList[j].cards) do
                            chooseStar = chooseStar + j* starAddition
                            v.chooseNum = v.count
                            if chooseStar  >= self.m_MaxStarNum then
                                oneBeyondStarCount = chooseStar - self.m_MaxStarNum 
                                if oneBeyondStarCount > 0 then
                                    oneBeyondStarYearIndex = i
                                    oneBeyondStarIndex = j
                                end
                                chooseFinish = true
                                break
                            end
                        end
                    end
                    if chooseFinish then
                        break
                    end
                end
                if chooseFinish  then
                    break
                end
            end
        end
        if chooseFinish  then
            break
        end
    end
    
    local checkOutCard= {}
    local checkOutCardEvenNumber = {}
    chooseFinish = false
    local chooseFinishEvenNumber = false
    
    if oneBeyondStarYearIndex > 0 and oneBeyondStarIndex > 0 then
        local subStar = math.floor(oneBeyondStarCount / starAddition)
        local checkStar = subStar
        for i = oneBeyondStarYearIndex,1,-1 do
            local nadoStarList = self.m_yearList[i].typeCards[typeIndex].starList
            if nadoStarList then
                for j= subStar,1,-1 do
                    if nadoStarList[j].cards and #nadoStarList[j].cards > 0 then
                        for k = #nadoStarList[j].cards,1,-1 do
                            local v = nadoStarList[j].cards[k]
                            if checkStar < j then
                                break
                            end
                            for i=1,v.chooseNum do
                                if checkOutCard[v.cardId] == nil then
                                    checkOutCard[v.cardId] = {count = 0}
                                end
                                checkOutCard[v.cardId].card = v
                                checkOutCard[v.cardId].count = checkOutCard[v.cardId].count +1
                                checkStar = checkStar - j
                                if checkStar == 0 then
                                    chooseFinish = true
                                    break
                                end
                                if checkStar < j then
                                    break
                                end
                            end
                        end
                        if chooseFinish then
                            break
                        end
                    end
                    if chooseFinish then
                        break
                    end
                end
            end
        end
        if subStar == 4  and checkStar ~= 0 then
            local checkOutCard= {}
            local checkStar =  subStar
            for i = oneBeyondStarYearIndex,1,-1 do
                local nadoStarList = self.m_yearList[i].typeCards[typeIndex].starList
                if nadoStarList then
                    for j= subStar/2,1,-1 do
                        if nadoStarList[j].cards and #nadoStarList[j].cards > 0 then
                            for k = #nadoStarList[j].cards,1,-1 do
                                local v = nadoStarList[j].cards[k]
                                if checkStar < j then
                                    break
                                end
                                for i=1,v.chooseNum do
                                    if checkOutCardEvenNumber[v.cardId] == nil then
                                        checkOutCardEvenNumber[v.cardId] = {count = 0}
                                    end
                                    checkOutCardEvenNumber[v.cardId].card = v
                                    checkOutCardEvenNumber[v.cardId].count = checkOutCardEvenNumber[v.cardId].count +1
                                    checkStar = checkStar - j
                                    if checkStar == 0 then
                                        chooseFinishEvenNumber = true
                                        break
                                    end
                                    if checkStar < j then
                                        break
                                    end
                                end
                            end
                            if chooseFinishEvenNumber then
                                break
                            end
                        end
                        if chooseFinishEvenNumber  then
                            break
                        end
                    end
                end
            end
        end
    end

    if chooseFinishEvenNumber then
        for k,v in pairs(checkOutCardEvenNumber) do
            v.card.chooseNum =  v.card.chooseNum - v.count
        end
    else
        for k,v in pairs(checkOutCard) do
            v.card.chooseNum =  v.card.chooseNum - v.count
        end
    end
    return oneBeyondStarYearIndex > 0 ,usedThisTypeCard ,chooseStar
end

function CardRecoverExchangeView:doFinalData(isAddLinkCard)
    -- 计算现在添加了多少星 --
    self.m_oldStarNum = self.m_CurStarNum or 0
    self.m_CurStarNum = 0

    -- 选中的金卡星级数量  --
    self.m_GoldenCardStars = 0
    self.m_goldCardData = nil
    --拼图卡
    self.m_PuzzleCardStars = 0
    self.m_puzzleCardData = nil
    self.m_hasPuzzleCard = false

    -- 选中的神像卡星级数量  --
    self.m_StatueCardStars = 0
    self.m_statueCardData = nil

    for i = 1, #self.m_yearList do
        local cards = self.m_yearList[i].cards
                if cards and #cards > 0 then
                    for m = 1, #cards do
                        local card = cards[m]
                        if card.chooseNum and card.chooseNum > 0 then
                            -- 如果是link卡 星级算双倍 --
                            if card.type == "LINK" then
                                self.m_CurStarNum = self.m_CurStarNum + card.star * card.chooseNum * globalData.constantData.CARD_LinkCardStarAddition
                            elseif card.type == CardSysConfigs.CardType.golden then
                                -- 金卡会提供金币额外加成 --
                                if card.star >= self.m_GoldenCardStars then
                                    self.m_GoldenCardStars = card.star
                                    self.m_goldCardData = card
                                end
                                self.m_CurStarNum = self.m_CurStarNum + card.star * card.chooseNum
                            elseif card.type == CardSysConfigs.CardType.puzzle then
                                -- 拼图卡提供金币额外加成 --
                                if card.star >= self.m_PuzzleCardStars then
                                    self.m_PuzzleCardStars = card.star
                                    self.m_puzzleCardData = card
                                end
                                self.m_CurStarNum = self.m_CurStarNum + card.star * card.chooseNum
                            elseif CardSysRuntimeMgr:isStatueCard(card.type) then
                                -- 金卡会提供金币额外加成 --
                                if card.star >= self.m_StatueCardStars then
                                    self.m_StatueCardStars = card.star
                                    self.m_statueCardData = card
                                end
                                -- 星级算双倍
                                self.m_CurStarNum = self.m_CurStarNum + card.star * card.chooseNum * globalData.constantData.CARD_StatueCardStarAddition
                            else
                                self.m_CurStarNum = self.m_CurStarNum + card.star * card.chooseNum
                            end
                        end
                    end
                end
    end

    -- 选择数量与百分比 --
    self.m_BFont_StarNumNode:setString(self.m_CurStarNum .. "/" .. self.m_MaxStarNum)
    self.m_sp_LoadingBar_star:setPositionX(self.m_BFont_StarNumNode:getPositionX() - self.m_BFont_StarNumNode:getContentSize().width / 2 - 20 -5)
    -- 进度条 --
    self:doLoadingBar(self.m_LdBar_StarNumNode, self.m_oldStarNum, self.m_CurStarNum, self.m_MaxStarNum, isAddLinkCard)

    -- 计算金币的加成 --
    local fAddRadio = self:getCoinRadio()
    local showCoins = self.m_selLevelInfo.MaxCoins * (fAddRadio + 1)
    self.m_BFnt_MaxCoins:setString(util_formatCoins(tonumber(showCoins), 30))
    -- 设置金币左右字体的位置 --
    local pNodeWinUpToText = self:findChild("sp_jiangli_word1")
    local pNodeCoinsText = self:findChild("sp_jiangli_word2")

    local pNodeWinUpToSize = pNodeWinUpToText:getContentSize()
    local pNodeCoinsSize = pNodeCoinsText:getContentSize()

    local pMaxCoinsPos = self.m_BFnt_MaxCoins:getPositionX()
    local pMaxCoinsSize = self.m_BFnt_MaxCoins:getContentSize()

    pNodeWinUpToText:setPositionX(pMaxCoinsPos - pMaxCoinsSize.width / 2  - pNodeWinUpToSize.width / 2-3)
    pNodeCoinsText:setPositionX(pMaxCoinsPos + pMaxCoinsSize.width / 2  + pNodeCoinsSize.width / 2 +3)

    -- 如果够数量 点亮 GO按钮 --
    if self.m_CurStarNum >= self.m_MaxStarNum then
        self.m_goToSpinBtn:setTouchEnabled(true)
        self.m_goToSpinBtn:setBright(true)
    else
        self.m_goToSpinBtn:setTouchEnabled(false)
        self.m_goToSpinBtn:setBright(false)
    end
    self.m_canShowOnlySelectedBtn = self.m_CurStarNum > 0 and true or false
    self:updateOnlyShowSelectBtnStatus()
    
    self:updateExtraCoinMark()

    -- 如果超过数量 显示“已经超过”小提示 --
    if self.m_CurStarNum > self.m_MaxStarNum then
        self:addMaxTip()
    else
        self:delMaxTip()
    end
end

-- 一次性添加多张拼图卡时，只享受一张拼图卡的加成效果【即效果不叠加】
-- 拼图卡的效果和金卡的加成效果不叠加，取最大加成效果
-- 因为拼图卡的加成比金卡的加成多所以先这么写，理论上应该判断一下谁的加成多
function CardRecoverExchangeView:getCoinRadio()
    local fAddRadio = 0
    -- 拼图卡金币加成 --
    if self.m_PuzzleCardStars > 0 then
        fAddRadio = globalData.constantData.CARD_PuzzleCardCoinAddition or 0
    end
    -- 金卡金币加成， 两者取最大值--
    if self.m_GoldenCardStars > 0 then
        local additionList = globalData.constantData.CARD_GoldenCardCoinAddition
        local addGolden = additionList and additionList[self.m_GoldenCardStars] or 0
        fAddRadio = math.max(fAddRadio, addGolden)
    end
    -- 神像卡金币加成， 累加 --
    if self.m_StatueCardStars > 0 then
        fAddRadio = fAddRadio + (globalData.constantData.CARD_StatueCardCoinAddition[self.m_StatueCardStars] or 0)
    end
    return fAddRadio
end

--显示倍数
function CardRecoverExchangeView:updateExtraCoinMark()
    local nodeMarks = {self.m_nodeExtraCoinMark1,self.m_nodeExtraCoinMark2}
    local marks = {}
    local fAddRadio = 0
    if self.m_PuzzleCardStars > 0 then
        fAddRadio = globalData.constantData.CARD_PuzzleCardCoinAddition or 0
    end
    -- 金卡金币加成， 两者取最大值--
    if self.m_GoldenCardStars > 0 then
        local additionList = globalData.constantData.CARD_GoldenCardCoinAddition
        local addGolden = additionList and additionList[self.m_GoldenCardStars] or 0
        fAddRadio = math.max(fAddRadio, addGolden)
    end
    if fAddRadio > 0 then
        marks[#marks +1] = fAddRadio * 100
    end

    if self.m_StatueCardStars > 0 then
        local addStatue = globalData.constantData.CARD_StatueCardCoinAddition[self.m_StatueCardStars] or 0
        marks[#marks +1] = addStatue * 100
    end
    for i=1,2 do
        if marks[i] == nil then
            nodeMarks[i]:setVisible(false)
        else
            nodeMarks[i]:setVisible(true)
            local bitmapFontLabel_1 = nodeMarks[i]:findChild("BitmapFontLabel_1")
            if bitmapFontLabel_1 then
                bitmapFontLabel_1:setString("+" .. marks[i] .. "%")
            end
            nodeMarks[i]:runCsbAction(
                 "jiangli",
                 false,
                 nil
             )
        end
    end
end

function CardRecoverExchangeView:goToExchangeSpin()
    if self.isClose then
        return
    end

    local cardList = {} -- 乐透界面logo上展示的卡牌数据，提供最大金币收益的
    local puzzleMul = globalData.constantData.CARD_PuzzleCardCoinAddition or 0
    local goldenMuls = globalData.constantData.CARD_GoldenCardCoinAddition or {}
    local statueMuls = globalData.constantData.CARD_StatueCardCoinAddition or {}

    if self.m_goldCardData ~= nil and self.m_puzzleCardData ~= nil then
        local goldenMul = goldenMuls[self.m_goldCardData.star]
        if goldenMul >= puzzleMul then
            cardList[#cardList + 1] = {cardData = self.m_goldCardData, cardMul = goldenMul}
        else
            cardList[#cardList + 1] = {cardData = self.m_puzzleCardData, cardMul = puzzleMul}
        end
    else
        if self.m_goldCardData ~= nil then
            local goldenMul = goldenMuls[self.m_goldCardData.star]
            cardList[#cardList + 1] = {cardData = self.m_goldCardData, cardMul = goldenMul}
        end
        if self.m_puzzleCardData ~= nil then
            cardList[#cardList + 1] = {cardData = self.m_puzzleCardData, cardMul = puzzleMul}
        end
    end
    if self.m_statueCardData ~= nil then
        local statueMul = statueMuls[self.m_statueCardData.star]
        cardList[#cardList + 1] = {cardData = self.m_statueCardData, cardMul = statueMul}
    end
    CardSysManager:getRecoverMgr():setMaxStarCardList(cardList)
    CardSysManager:getRecoverMgr():setIsUseAISelect(self.m_didAISelect)
    CardSysManager:getRecoverMgr():showRecoverWheelView()
    performWithDelay(
        self,
        function()
            CardSysManager:getRecoverMgr():hideRecoverView()
            CardSysManager:getRecoverMgr():hideRecoverExchangeView()
        end,
        0.3
    )
end

function CardRecoverExchangeView:addMaxTip()
    if not self.m_maxTip then
        self.m_maxTip = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverExchangeMaxTip")
        self.m_tipNode:addChild(self.m_maxTip)
    end
    self.m_maxTip:reloadUI(self.m_MaxStarNum, self.m_CurStarNum)
    self.m_sp_go_war:setVisible(true)
end
function CardRecoverExchangeView:delMaxTip()
    if self.m_maxTip ~= nil then
        if self.m_maxTip.closeUI then
            self.m_maxTip:closeUI()
        end
        self.m_maxTip = nil
    end
    self.m_sp_go_war:setVisible(false)
end

function CardRecoverExchangeView:doLoadingBar(node, oldNum, curNum, maxNum, isLink)
    node:setPercent(oldNum / maxNum * 100)
    if self.m_addTick ~= nil then
        self:stopAction(self.m_addTick)
    end
    if self.m_delTick ~= nil then
        self:stopAction(self.m_delTick)
    end
    if oldNum < curNum then
        local nodeSize = node:getContentSize()
        if isLink then
            if self.linkIcon ~= nil then
                self.linkIcon:removeFromParent()
                self.linkIcon = nil
            end
            self.linkIcon = util_createAnimation(CardResConfig.commonRes.CardRecoverAddLinkRes)
            if self.linkIcon then
                --link卡 abtest
                local sp_link1 = self.linkIcon:findChild("CashCards_an_link_1")
                -- if sp_link1 then
                --     util_changeTexture(sp_link1, CardResConfig.getLinkCardTarget())
                -- end
                --link卡 abtest
                local sp_link2 = self.linkIcon:findChild("CashCards_an_link_1_0")
                -- if sp_link2 then
                --     util_changeTexture(sp_link2, CardResConfig.getLinkCardTarget())
                -- end

                self.linkIcon:runCsbAction(
                    "start",
                    false,
                    function()
                        self.linkIcon:runCsbAction("idle", true)
                    end
                )
                node:addChild(self.linkIcon)
                self.linkIcon:setScale(0.6)
                self.linkIcon:setPositionX(nodeSize.width * (oldNum / maxNum * 100))
                self.linkIcon:setPositionY(nodeSize.height * 0.5)
            end
        end

        self.m_addTick =
            util_schedule(
            self,
            function()
                oldNum = oldNum + self.m_loadingSpeed 
                if oldNum > curNum then
                    oldNum = curNum
                end
                if oldNum > maxNum then
                    oldNum = maxNum
                end
                node:setPercent(oldNum / maxNum * 100)
                if isLink then
                    local x = nodeSize.width * (oldNum / maxNum)
                    if self.linkIcon then
                        self.linkIcon:setPositionX(x)
                    end
                end
                if oldNum >= curNum or oldNum >= maxNum then
                    if self.linkIcon ~= nil then
                        self.linkIcon:removeFromParent()
                        self.linkIcon = nil
                    end
                    if self.m_addTick ~= nil then
                        self:stopAction(self.m_addTick)
                    end
                    self:doBarFullAct()
                end
            end,
            0.01
        )
    elseif oldNum > curNum then
        if self.linkIcon ~= nil then
            self.linkIcon:removeFromParent()
            self.linkIcon = nil
        end
        self.m_delTick =
            util_schedule(
            self,
            function()
                oldNum = oldNum - self.m_loadingSpeed *5
                if oldNum < curNum then
                    oldNum = curNum
                end
                if oldNum < 0 then
                    oldNum = 0
                end
                node:setPercent(oldNum / maxNum * 100)

                if oldNum <= curNum or oldNum <= 0 then
                    if self.m_delTick ~= nil then
                        self:stopAction(self.m_delTick)
                    end
                end
            end,
            0.01
        )
    end
end

function CardRecoverExchangeView:doBarFullAct()
    -- 集满动画
    if self.m_CurStarNum >= self.m_MaxStarNum then
        if self.m_hasShowFullAct == false then
            self.m_hasShowFullAct = true
            self:runCsbAction("jiman", false, nil, 60)
        end
    else
        self.m_hasShowFullAct = false
    end
end

-- 节点选中的事件 --
function CardRecoverExchangeView:addNodeClicked(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.nodeClickedEvent))
end
function CardRecoverExchangeView:nodeClickedEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        self:hideAllTab()
    end
end
function CardRecoverExchangeView:hideAllTab()
    self.m_yearTabUI:hideDetail()
    self.m_qualityTabUI:hideDetail()
    self.m_starTabUI:hideDetail()
end

return CardRecoverExchangeView
