---
--xcyy
--2018年5月23日
--CactusMariachiShopView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local CactusMariachiShopView = class("CactusMariachiShopView",BaseGame )

CactusMariachiShopView.m_totalShopCoins = 0
CactusMariachiShopView.m_curShopData = nil
CactusMariachiShopView.m_curCostData = nil
CactusMariachiShopView.m_curPage = 1
CactusMariachiShopView.m_curPlayMusicIndex = 0
CactusMariachiShopView.m_lastPlayMusicIndex = nil

CactusMariachiShopView.tblPageNodeList = {}
CactusMariachiShopView.tblAlbumNodeList = {}
CactusMariachiShopView.tblFinishList = {}
CactusMariachiShopView.tblPickResult = {}
CactusMariachiShopView.m_lastPickAgain = nil
CactusMariachiShopView.m_lastPickAgainPos = nil
CactusMariachiShopView.tblMusicStateList = {}
CactusMariachiShopView.tblMusicNodeList = {}
CactusMariachiShopView.tblAllSuperFreeList = {}
CactusMariachiShopView.tblMusicLikeData = {}

CactusMariachiShopView.m_onePageAlbumNum = 8
CactusMariachiShopView.m_disPosX = 1143

function CactusMariachiShopView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("CactusMariachi/ShopCactusMariachi.csb")
    self:initData()
    
    self:initView()

    self.nodeFiurePos = {
        {cc.p(0, 0), cc.p(-287, 10), cc.p(-100, 36), cc.p(0, 0)},
        {cc.p(-321, 35), cc.p(-76, 11), cc.p(0, 0), cc.p(0, 0)},
        {cc.p(-387, 36), cc.p(-192, 10), cc.p(-30, 36), cc.p(0, 0)},
        {cc.p(-405, 37), cc.p(-255, 9), cc.p(-120, 36), cc.p(28, 29)},
    }

    self.m_guideNode = util_createAnimation("CactusMariachi_shop_guide.csb")
    self:findChild("Node_guide"):addChild(self.m_guideNode)
    self.m_guideNode:setVisible(false)

    self.guidePanelClick = self.m_guideNode:findChild("Panel_click")
    self.guideStepClick = self.m_guideNode:findChild("Panel_step_click")
    self.guideStepClick:setVisible(false)

    self.m_finger = util_createAnimation("CactusMariachi_shouzhi.csb")
    self.m_guideNode:findChild("shouzhi"):addChild(self.m_finger)
    self.m_finger:runCsbAction("dian", true)
    self.m_finger:setVisible(false)

    for i=1, 5 do
        self.tblGuideNodeList[i] = self.m_guideNode:findChild("step"..i)
    end

    self.m_coinLeft = util_createAnimation("CactusMariachi_shop_CoinsLeft.csb")
    self:findChild("Node_CoinsLeft"):addChild(self.m_coinLeft)
    self.m_coinLeft:runCsbAction("idle", true)
    self.m_textTotalCoins = self.m_coinLeft:findChild("m_lb_coins")

    self.m_musicBg = util_createAnimation("CactusMariachi_shop_MusicPlayer.csb")
    self:findChild("Node_MusicPlayer"):addChild(self.m_musicBg)

    self.m_shopTips = util_createAnimation("CactusMariachi_shop_ShopTips.csb")
    self:findChild("Node_ShopTips"):addChild(self.m_shopTips)
    self.m_shopTips:runCsbAction("idle", true)

    self.m_shopTextTips = util_createAnimation("CactusMariachi_shop_ShopTipsText.csb")
    self.m_shopTips:findChild("Node_text"):addChild(self.m_shopTextTips)
    self.m_shopTextTips:runCsbAction("idle", true)

    self.m_cartainBg = util_spineCreate("Socre_CactusMariachi_lianzi",true,true)
    self:findChild("Node_curtains"):addChild(self.m_cartainBg)
    util_spinePlay(self.m_cartainBg,"idle",true)

    self.m_lightSpine = util_spineCreate("Socre_CactusMariachi_lianzi2",true,true)
    self:findChild("Node_figure"):addChild(self.m_lightSpine, -1)
    util_spinePlay(self.m_lightSpine,"idle",true)

    self.m_shopFigureSpine[1] = util_spineCreate("Socre_CactusMariachi_h1",true,true)
    self:findChild("Node_figure1"):addChild(self.m_shopFigureSpine[1])
    util_spinePlay(self.m_shopFigureSpine[1],"shop_idle",true)

    self.m_shopFigureSpine[2] = util_spineCreate("Socre_CactusMariachi_h2",true,true)
    self:findChild("Node_figure2"):addChild(self.m_shopFigureSpine[2])
    util_spinePlay(self.m_shopFigureSpine[2],"shop_idle",true)

    self.m_shopFigureSpine[3] = util_spineCreate("Socre_CactusMariachi_h3",true,true)
    self:findChild("Node_figure3"):addChild(self.m_shopFigureSpine[3])
    util_spinePlay(self.m_shopFigureSpine[3],"shop_idle",true)

    self.m_shopFigureSpine[4] = util_spineCreate("Socre_CactusMariachi_h4",true,true)
    self:findChild("Node_figure4"):addChild(self.m_shopFigureSpine[4])
    util_spinePlay(self.m_shopFigureSpine[4],"shop_idle",true)

    self.m_tips = util_createAnimation("CactusMariachi_shop_MusicUnlockTips.csb")
    self.m_musicBg:findChild("Music4"):addChild(self.m_tips)
    self.m_tips:setVisible(false)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    for i=1, 5 do
        self.tblMusicNodeList[i] = util_createView("CodeCactusMariachiSrc.CactusMariachiMusicNode", self.m_machine, self, i)
        self.m_musicBg:findChild("Music"..i-1):addChild(self.tblMusicNodeList[i])

        self.tblMusicNodeLikeList[i] = util_createView("CodeCactusMariachiSrc.CactusMariachiMusicLikeNode", self, i)
        self.tblMusicNodeList[i]:findChild("Node_Like"):addChild(self.tblMusicNodeLikeList[i])
    end
    
    for i=1, 2 do
        local tempDataPageList = {}
        local pageNode= util_createAnimation("CactusMariachi_shop_AlbumsReel.csb")
        -- 当前页状态是false
        tempDataPageList.isReady = true
        tempDataPageList.pageNode = pageNode
        table.insert(self.tblPageNodeList, tempDataPageList)

        local tblAlbumTemp = {}
        for j=1, self.m_onePageAlbumNum do
            tblAlbumTemp[j] = util_createView("CodeCactusMariachiSrc.CactusMariachiAlbumNode", self.m_machine, self, j)
        end
        table.insert(self.tblAlbumNodeList, tblAlbumTemp)
    end

    self:addClick(self.guidePanelClick)
    self:addClick(self.guideStepClick)

    self:addAlbumNode()
end

function CactusMariachiShopView:onExit()
    CactusMariachiShopView.super.onExit(self)
end

function CactusMariachiShopView:scaleShopMainLayer(_scale, _posY)
    self:findChild("root"):setScale(_scale)
    self:setPositionY(self:getPositionY() + _posY)
end

function CactusMariachiShopView:initData()
    self.tblPageNodeList = {}
    self.tblAlbumNodeList = {}
    self.tblFinishList = {}
    self.tblPickResult = {}
    self.tblMusicNodeList = {}
    self.tblMusicNodeLikeList = {}
    self.tblMusicStateList = {}
    self.tblAllSuperFreeList = {}
    self.m_isClick = true
    self.m_lastPickAgain = nil
    self.m_lastPickAgainPos = nil

    self.m_shopFigureSpine = {}
    self.m_isGuide = false
    self.m_guideIndex = 1
    self.tblGuideNodeList = {}
    self.lastPurchaseTime = 0
end

function CactusMariachiShopView:initView()
    for i=1, 4 do
        self:addClick(self:findChild("Page" .. i .. "_click"))
    end
end

function CactusMariachiShopView:addAlbumNode()
    for pageId, albumData in pairs(self.tblPageNodeList) do
        for i=1, self.m_onePageAlbumNum do
            local albumIcon = self.tblAlbumNodeList[pageId][i]
            albumIcon:setName("album")
            self.tblPageNodeList[pageId]["pageNode"]:findChild("Album_"..i-1):addChild(albumIcon)
        end
        self:findChild("Node_AlbumsReel"):addChild(self.tblPageNodeList[pageId]["pageNode"])
        self.tblPageNodeList[pageId]["pageNode"]:setPositionX((pageId-1)*1143)
    end
end

function CactusMariachiShopView:refreshShopCoins(_curCoins)
    self.m_totalShopCoins = _curCoins
    self.m_textTotalCoins:setString(_curCoins)
end

function CactusMariachiShopView:refreshShopLikeNum(_numList)
    if _numList then
        self.tblMusicLikeData = _numList
    end
    --刷新点赞
    self:refreshMusicLikeNum()
end

function CactusMariachiShopView:refreshShopMusicState()
    local curMusicData = self.m_machine:getCurMusicSatate()
    if curMusicData then
        self.tblMusicStateList = curMusicData
    end
end

function CactusMariachiShopView:refreshMusicLikeNum()
    for i=1, 5 do
        self.tblMusicNodeLikeList[i]:refreshMusicLikeNum(self.tblMusicLikeData[i])
    end
end

function CactusMariachiShopView:refreshView(_extraData)
    self.m_totalShopCoins = _extraData.coins
    self.m_curShopData = _extraData.shop
    self.m_curCostData = _extraData.cost
    self.tblFinishList = _extraData.finished
    self.tblMusicStateList = _extraData.musicUnlock
    self.tblAllSuperFreeList = _extraData.all_superFreeType
    self.tblMusicLikeData = _extraData.likes
    self.m_isGuide = _extraData.guide
    local clickPos = gLobalDataManager:getNumberByField("CactusMariachi_musicIndex", "")
    if clickPos and clickPos ~= "" then
        self.m_curPlayMusicIndex = clickPos
    else
        self.m_curPlayMusicIndex = _extraData.clickPos
    end

    self.tblPickResult[1] = _extraData.extraPick
    self.tblPickResult[2] = _extraData.extraPickPos

    self.m_curPage = self:getCurPage()
    self:havePickAndLockPage()

    self:changePageClickState(true)
    self:refreshAlbumData()
    self:playOpenCurtainSpine()
    self:initGuide()
end

function CactusMariachiShopView:initGameRefreshMusic()
    if self.m_machine:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_machine:playCurMusic(self.m_curPlayMusicIndex+1)
    end
end

function CactusMariachiShopView:refreshShopData()
    if not self.m_runSpinResultData then
        return
    end
    local _extraData = self.m_runSpinResultData.selfData
    if _extraData then
        local shopData = _extraData.shop
        if shopData then
            self.m_curShopData = shopData
        end
    end
end

function CactusMariachiShopView:getNextPageForSuperOver()
    local isRun = false
    local cutNextPage = 1
    for k, unLock in pairs(self.tblMusicStateList[1]) do
        if unLock then
            cutNextPage = cutNextPage + 1
            isRun = true
        end
    end
    if cutNextPage == 5 then
        cutNextPage = self.m_curPage
    end
    return isRun, cutNextPage
end

--superGame结束后切页解锁
function CactusMariachiShopView:superOverCutShop(_isCutPaga)
    if not _isCutPaga then
        return
    end
    
    local isRun, cutNextPage = self:getNextPageForSuperOver()
    if isRun then
        self:changePage(cutNextPage, true)
    end
end

--superGame完成切页时，初始化下一个pageNode(变成未解锁状态)
function CactusMariachiShopView:initCutPageAlbum()
    local pageNode = self:getReadyPageNode(true)
    local curPageAlbumData = self.m_curCostData[self.m_curPage]
    for k, v in pairs(curPageAlbumData) do
        local albumNode = pageNode:findChild("Album_"..k-1)
        local albumIcon = albumNode:getChildByName("album")
        albumIcon:initCutPageAlbum(v)
    end
end

function CactusMariachiShopView:refreshAlbumData(_refresh, _isUseCurPageNode, _isLockAlbum)
    if _refresh then
        self:refreshShopData()
    end
    local curPageAlbumData = self.m_curCostData[self.m_curPage]
    local curShopData = self.m_curShopData[self.m_curPage]
    local pageNode
    if _isUseCurPageNode then
        pageNode = self:getCurPageNode()
    else
        pageNode = self:getReadyPageNode(_refresh)
    end
    for k, v in pairs(curPageAlbumData) do
        local albumNode = pageNode:findChild("Album_"..k-1)
        local albumIcon = albumNode:getChildByName("album")
        local isSold = curShopData[k] == 1

        local isPickAgain, isFree
        if self:curPageIsHavePickAgain() then
            -- 当前页并且是没有售出的状态才是free
            if self.m_curPage == (self.tblPickResult[2][1] + 1) then
                if not isSold then
                    isFree = true
                end
                -- 当前售出并且是pickAgain
                if isSold and k == self.tblPickResult[2][2] + 1 then
                    isPickAgain = true
                    self.m_lastPickAgain = true
                    self.m_lastPickAgainPos = self.tblPickResult[2][2] + 1
                end
            end
        end

        albumIcon:refreshViewData(v, isSold, isPickAgain, isFree, _isLockAlbum)
    end

    --刷新唱片
    self:refreshMusicState()
end

function CactusMariachiShopView:refreshMusicState()
    for i=1, 5 do
        local isLock = false
        if i == 1 then
            isLock = true
        else
            isLock = self.tblMusicStateList[1][i-1]
        end
        self.tblMusicNodeList[i]:refreshMusicState(i, isLock)
    end
end

function CactusMariachiShopView:playCurMusic()
    self.m_machine:playCurMusic(self.m_curPlayMusicIndex+1)
end

function CactusMariachiShopView:cutShopMusic(_musicIndex)
    self.m_lastPlayMusicIndex = self.m_curPlayMusicIndex
    self.m_curPlayMusicIndex = _musicIndex
    if self.m_lastPlayMusicIndex then
        self.tblMusicNodeList[self.m_curPlayMusicIndex+1]:cutNextMusic()
        self.tblMusicNodeList[self.m_lastPlayMusicIndex+1]:cutLastMusic()
    end
    self:playCurMusic()
    gLobalDataManager:setNumberByField("CactusMariachi_musicIndex", self.m_curPlayMusicIndex)
end

function CactusMariachiShopView:curPageIsHavePickAgain()
    if self.tblPickResult[1] and (self.tblPickResult[1] == true or self.tblPickResult[1] == "extraPick") then
        return true
    end
    return false
end

--刷新当前页的唱片状态
function CactusMariachiShopView:refreshCurIconState(_pickResult, _endCallFunc)
    local curPageNode = self:getCurPageNode()

    local isFree = false
    if _pickResult and _pickResult[1] == "extraPick" then
        isFree = true
        self.m_lastPickAgain = true
        self.m_lastPickAgainPos = _pickResult[2][2] + 1
    end
    local albumNode = curPageNode:findChild("Album_"..self.clickIndex-1)

    local albumIcon = albumNode:getChildByName("album")
    albumIcon:refreshCurState(_pickResult, isFree, _endCallFunc)

    --如果钱不够刷新其他状态
    self:setCoinsNotEnoughAlbumState()
end

function CactusMariachiShopView:setCoinsNotEnoughAlbumState()
    local pageNode = self:getCurPageNode()
    local curShopData = self.m_curShopData[self.m_curPage]
    for k, state in pairs(curShopData) do
        local albumNode = pageNode:findChild("Album_"..k-1)
        local albumIcon = albumNode:getChildByName("album")
        if state == 0 then
            albumIcon:setCoinsNotEnoughAlbumState()
        end
    end
end

function CactusMariachiShopView:showOtherFree(_callFunc)
    local curPageNode = self:getCurPageNode()
    for i=1, self.m_onePageAlbumNum do
        if self.m_curShopData[self.m_curPage][i] == 0 then
            local albumNode = curPageNode:findChild("Album_"..i-1)
            local albumIcon = albumNode:getChildByName("album")
            albumIcon:showOtherFree()
        end
    end
    performWithDelay(self.m_scWaitNode, function ()
	    if _callFunc then
            _callFunc()
        end
    end, 20/60)
end

function CactusMariachiShopView:recoveryOtherFree()
    if not self.m_lastPickAgain then
        return
    end
    local curPageNode = self:getCurPageNode()
    for i=1, self.m_onePageAlbumNum do
        if self.m_curShopData[self.m_curPage][i] == 0 then
            local curCostData = self.m_curCostData[self.m_curPage]
            local albumNode = curPageNode:findChild("Album_"..i-1)
            local albumIcon = albumNode:getChildByName("album")
            albumIcon:recoveryOtherFree(curCostData[i])
        end
    end
    self.m_lastPickAgain = nil
    self.m_lastPickAgainPos = nil
end

function CactusMariachiShopView:playPickAgainAni(_totalReward, _callFunc)
    local curPageNode = self:getCurPageNode()
    local lastPickPos = self:getLastPickAgainPos()
    local endAlbumNode = curPageNode:findChild("Album_"..self.clickIndex-1)
    local endAlbumIcon = endAlbumNode:getChildByName("album")
    local endPos = util_convertToNodeSpace(endAlbumIcon:findChild("m_lb_coins"), self.m_machine)

    local albumNode = curPageNode:findChild("Album_"..lastPickPos-1)
    local albumIcon = albumNode:getChildByName("album")

    local coinsPickFunc = function()
        endAlbumIcon:playPickCoins(_totalReward, _callFunc)
    end
    albumIcon:playPickAgainAni(endPos, coinsPickFunc)
end

--默认按钮监听回调
function CactusMariachiShopView:clickFunc(sender)
    local name = sender:getName()
    -- self.m_machine:playClickEffect()
    if name == "Button_Back" then
        self:hideSelf()
    elseif name == "Panel_click" then
        self:setGuideNextStep()
    elseif name == "Panel_step_click" then
        self:guidePlayMusic()
    elseif name == "Button_LeftPage" then
        self:cutLastPage()
    elseif name == "Button_RightPage" then
        self:cutNextPage()
    elseif name == "Page1_click" then
        self:changePage(1)
    elseif name == "Page2_click" then
        self:changePage(2)
    elseif name == "Page3_click" then
        self:changePage(3)
    elseif name == "Page4_click" then
        self:changePage(4)
    end
end

function CactusMariachiShopView:changePage(_cutPage, _isLockAlbum)
    if self.m_curPage == _cutPage then
        return
    end
    local offsetX = self.m_disPosX
    if self.m_curPage == 1 then
        if _cutPage == 2 or _cutPage == 3 then
            offsetX = self.m_disPosX
        elseif _cutPage == 4 then
            offsetX = -self.m_disPosX
        end
    elseif self.m_curPage == 2 then
        if _cutPage == 3 or _cutPage == 4 then
            offsetX = self.m_disPosX
        elseif _cutPage == 1 then
            offsetX = -self.m_disPosX
        end
    elseif self.m_curPage == 3 then
        if _cutPage == 1 or _cutPage == 2 then
            offsetX = -self.m_disPosX
        elseif _cutPage == 4 then
            offsetX = self.m_disPosX
        end
    elseif self.m_curPage == 4 then
        if _cutPage == 2 or _cutPage == 3 then
            offsetX = -self.m_disPosX
        elseif _cutPage == 1 then
            offsetX = self.m_disPosX
        end
    end

    self:setBtnTouchState(false)
    self.m_curPage = _cutPage
    if _isLockAlbum then
        self:initCutPageAlbum()
    else
        self:refreshAlbumData(true, nil)
    end
    self:changePageClickState()
    local curPageNode, nextPageNode

    for k,v in pairs(self.tblPageNodeList) do
        -- 刚刚用过的pageNode
        if v.isReady == true then
            curPageNode = v.pageNode
        else
            -- 下一页准备要用的pageNode
            nextPageNode = v.pageNode
        end
    end
    curPageNode:setPositionX(0)
    nextPageNode:setPositionX(offsetX)

    local delayTime = 0.5
    local endPos_1 = cc.p(-offsetX, 0)
    local endPos_2 = cc.p(0, 0)
    self:playCloseCurtainSpine()
    util_playMoveToAction(curPageNode,delayTime,endPos_1,function(  )
        self:playOpenCurtainSpine()
        if _isLockAlbum then
            performWithDelay(self.m_scWaitNode, function()
                self:refreshAlbumData(true, true, _isLockAlbum)
            end, delayTime)
        end
    end)
    util_playMoveToAction(nextPageNode,delayTime,endPos_2,function(  )
        
    end)
end

function CactusMariachiShopView:changePageClickState(_isInit)
    for i=1, 4 do
        self:findChild("Page"..i):setVisible(false)
    end
    self:findChild("Page"..self.m_curPage):setVisible(true)
    self:changeTextTipsState(_isInit)
end

function CactusMariachiShopView:changeTextTipsState(_isInit)
    local delaytime = 0
    if not _isInit then
        delaytime = 20/60
    end
    local curPageAllSold = self:getCurPageSoldState()
    local curIdleName
    if curPageAllSold then
        curIdleName = "idle2"
    else
        curIdleName = "idle"
    end
    performWithDelay(self.m_scWaitNode, function()
        self.m_shopTextTips:runCsbAction(curIdleName, true)
        for i=1, 4 do
            self.m_shopTextTips:findChild("Tips"..i):setVisible(false)
        end
        self.m_shopTextTips:findChild("Tips"..self.m_curPage):setVisible(true)
    end, delaytime)
end

function CactusMariachiShopView:getCurPageSoldState()
    local curPageData = self.m_curShopData[self.m_curPage]
    local allSoldNum = 0
    for k, v in pairs(curPageData) do
        if v == 1 then
            allSoldNum = allSoldNum + 1
        end
    end

    if allSoldNum == 8 then
        return true
    else
        return false
    end
end

function CactusMariachiShopView:cutLastPage()
    self:setBtnTouchState(false)
    self:setNextPage(-1)
    self:refreshAlbumData(true)
    self:changePageClickState()
    local curPageNode, nextPageNode
    for k,v in pairs(self.tblPageNodeList) do
        -- 刚刚用过的pageNode
        if v.isReady == true then
            curPageNode = v.pageNode
        else
            -- 下一页准备要用的pageNode
            nextPageNode = v.pageNode
        end
    end
    curPageNode:setPositionX(0)
    nextPageNode:setPositionX(-self.m_disPosX)

    local delayTime = 0.5
    local endPos_1 = cc.p(self.m_disPosX, 0)
    local endPos_2 = cc.p(0, 0)
    self:playCloseCurtainSpine()
    util_playMoveToAction(curPageNode,delayTime,endPos_1,function(  )
        self:playOpenCurtainSpine()
    end)
    util_playMoveToAction(nextPageNode,delayTime,endPos_2,function(  )
        
    end)
end

function CactusMariachiShopView:setNextPage(num)
    self.m_curPage = self.m_curPage + num
    if self.m_curPage > 4 then
        self.m_curPage = 1
    elseif self.m_curPage < 1 then
        self.m_curPage = 4
    end
end

function CactusMariachiShopView:cutNextPage()
    self:setBtnTouchState(false)
    self:setNextPage(1)
    self:refreshAlbumData(true)
    self:changePageClickState()
    local curPageNode, nextPageNode
    for k,v in pairs(self.tblPageNodeList) do
        -- 刚刚用过的pageNode
        if v.isReady == true then
            curPageNode = v.pageNode
        else
            -- 下一页准备要用的pageNode
            nextPageNode = v.pageNode
        end
    end
    curPageNode:setPositionX(0)
    nextPageNode:setPositionX(self.m_disPosX)

    local delayTime = 0.5
    local endPos_1 = cc.p(-self.m_disPosX, 0)
    local endPos_2 = cc.p(0, 0)
    self:playCloseCurtainSpine()
    util_playMoveToAction(curPageNode,delayTime,endPos_1,function(  )
        self:playOpenCurtainSpine()
    end)
    util_playMoveToAction(nextPageNode,delayTime,endPos_2,function(  )
        
    end)
end

function CactusMariachiShopView:setBtnTouchState(_state, isPickAgain)
    self:findChild("Button_LeftPage"):setTouchEnabled(_state)
    self:findChild("Button_RightPage"):setTouchEnabled(_state)
    for i=1, 4 do
        self:findChild("Page" .. i .. "_click"):setTouchEnabled(_state)
    end
    for k, page in pairs(self.tblPageNodeList) do
        local pageNode = page.pageNode
        for i=1, self.m_onePageAlbumNum do
            local albumNode = pageNode:findChild("Album_"..i-1)
            local albumIcon = albumNode:getChildByName("album")
            albumIcon:findChild("click"):setTouchEnabled(_state)
        end
    end

    --如果有pickAgain，当前页可以点击
    if isPickAgain then
        for k,v in pairs(self.tblPageNodeList) do
            -- 当前的pageNode
            if v.isReady == false then
                local pageNode = v.pageNode
                for i=1, self.m_onePageAlbumNum do
                    local albumNode = pageNode:findChild("Album_"..i-1)
                    local albumIcon = albumNode:getChildByName("album")
                    albumIcon:findChild("click"):setTouchEnabled(isPickAgain)
                end
            end
        end
    end
end

function CactusMariachiShopView:setClickData(_index)
    self.clickPage = self.m_curPage
    self.clickIndex = _index
    local serverPage = self.m_curPage-1
    local serverIndex = _index-1
    self:sendData(serverPage, serverIndex)
end

function CactusMariachiShopView:sendData(_serverPage, _serverIndex, _isGuide)
    self.m_isClick = false
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的页数是client："..(_serverPage+1).."-- 索引是client：".._serverIndex+1)
    local data
    if _isGuide then
        data = "guide"
    else
        data = {_serverPage, _serverIndex}
    end
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = data, clickPos = self:getCurPlayMusicIndex()}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--数据接收
function CactusMariachiShopView:recvBaseData(_isSuperFreeGame)
    local _extraData = self.m_runSpinResultData.selfData
    if _extraData.guide == false then
        self.m_isClick = true
        return
    end
    self.m_curShopData = _extraData.shop
    self.tblFinishList = _extraData.finished
    self.tblPickResult = _extraData.pickResult
    self.tblMusicStateList = _extraData.musicUnlock
    -- self.tblAllSuperFreeList = _extraData.all_superFreeType
    local tblSuperFreeList = _extraData.superFreeType
    self.tblMusicLikeData = _extraData.likes

    self.m_totalShopCoins = _extraData.coins
    
    if _extraData.oldShop then
        self.m_curShopData = _extraData.oldShop
    else
        self.m_curShopData = _extraData.shop
    end
    self.m_machine:refreshShopCoins(self.m_totalShopCoins)

    local endCallFunc = function()
        self.m_isClick = true
        self:havePickAndLockPage()

        if _isSuperFreeGame then
            self:hideSelf()
            self.m_machine:showSuperFreeGame(self.m_runSpinResultData, tblSuperFreeList)
        end
    end
    self:refreshCurIconState(self.tblPickResult, endCallFunc)
    self:playFigureSpine()
end

function CactusMariachiShopView:playMusicUnlockAni()
    self:refreshShopMusicState()
    local unlockMusicIndex = self:getCurunLockMusicIndex()
    if unlockMusicIndex then
        self.tblMusicNodeList[unlockMusicIndex+1]:playMusicUnlockAni()
        -- self.tblMusicNodeList[self.m_curPlayMusicIndex]:cutLastMusic()
        self:playFigureSpine()
    end
end

function CactusMariachiShopView:getCurunLockMusicIndex()
    if self.tblMusicStateList[2] and self.tblMusicStateList[2] ~= -1 then
        return self.tblMusicStateList[2]
    end
    return false
end

function CactusMariachiShopView:havePickAndLockPage()
    local isPickAgain = self:curPageIsHavePickAgain()
    self:setBtnTouchState(not isPickAgain, true)
end

function CactusMariachiShopView:getCurPageNode()
    for k, v in pairs(self.tblPageNodeList) do
        if v.isReady == false then
            local curPageNode = v.pageNode
            return curPageNode
        end
    end
end

function CactusMariachiShopView:getReadyPageNode(_refresh)
    for k, page in pairs(self.tblPageNodeList) do
        if page.isReady then
            if _refresh then
                self:refreshPageNodeState()
            end
            page.isReady = false
            return page.pageNode
        end
    end
end

function CactusMariachiShopView:refreshPageNodeState()
    for k, page in pairs(self.tblPageNodeList) do
        if page.isReady == false then
            page.isReady = true
        end
    end
end

function CactusMariachiShopView:hideSelf()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    self.m_machine:setFigureSpineVisible(true)
    self.m_machine:setBtnCloseState(false)
    self:setBtnCloseState(false)
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_closeStore.mp3")
    self:runCsbAction("over",false, function()
        self.m_machine:setBtnCloseState(true)
        self:setBtnCloseState(true)
        self:setVisible(false)
    end)
end

function CactusMariachiShopView:setBtnCloseState(_state)
    self:findChild("Button_Back"):setTouchEnabled(_state)
end

function CactusMariachiShopView:getCurPage()
    --第四页因为都是true, 需要特殊判断
    local isComplete = true
    for k, v in pairs(self.m_curShopData[4]) do
        if v == 0 then
            isComplete = false
            break
        end
    end

    local curPage = 0
    for k, v in pairs(self.tblMusicStateList[1]) do
        if v == true then
            curPage = curPage + 1
        end
    end
    if curPage == 0 or (curPage == 4 and isComplete) then
        curPage = 1
    end
    --如果有pickAgain，取当前页显示
    if self:curPageIsHavePickAgain() then
        return self.tblPickResult[2][1] + 1
    end
    return curPage
end

function CactusMariachiShopView:getTotalCoins( )
    return self.m_totalShopCoins
end

function CactusMariachiShopView:getLastIsPickAgain()
    return self.m_lastPickAgain
end

function CactusMariachiShopView:getLastPickAgainPos()
    return self.m_lastPickAgainPos
end

function CactusMariachiShopView:getCurPlayMusicIndex()
    return self.m_curPlayMusicIndex
end

function CactusMariachiShopView:getAllSuperFreeList()
    return self.tblAllSuperFreeList
end

function CactusMariachiShopView:getMusicStateList()
    return self.tblMusicStateList
end

function CactusMariachiShopView:getCanClick(_clickIndex)
    if self.m_curShopData[self.m_curPage][_clickIndex] == 0 then
        print("当前点击——可以购买-页数："..self.m_curPage.."-索引".._clickIndex)
    else
        print("当前点击——index已经购买过-页数："..self.m_curPage.."-索引".._clickIndex)
    end
    
    return self.m_isClick and self.m_curShopData[self.m_curPage][_clickIndex] == 0
end

function CactusMariachiShopView:getCurShopDataIsClick(_clickIndex)
    return self.m_curShopData[self.m_curPage][_clickIndex] == 0
end

function CactusMariachiShopView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "SPECIAL" then
            self.m_runSpinResultData = spinData.result
            local isSuperFreeGame = self:getIsSuperFreeGame()
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(isSuperFreeGame)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData()
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function CactusMariachiShopView:refreshFigureState()
    local curSuperList = self.tblAllSuperFreeList[self.m_curPage]
    for i=1, 4 do
        local pos = self.nodeFiurePos[self.m_curPage][i]
        self.m_shopFigureSpine[i]:setPosition(pos)
    end
    for k, v in pairs(curSuperList) do
        if v == 1 then
            self.m_shopFigureSpine[k]:setVisible(true)
        else
            self.m_shopFigureSpine[k]:setVisible(false)
        end
    end
end

function CactusMariachiShopView:playCloseCurtainSpine()
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopCutPage.mp3")
    self.m_shopTips:runCsbAction("shangyi", false)
    util_spinePlay(self.m_cartainBg,"mubu_he",false)
    performWithDelay(self.m_scWaitNode, function()
        util_spinePlay(self.m_cartainBg,"idle",true)
    end, 35/30)
end

--刷新人物
function CactusMariachiShopView:playOpenCurtainSpine()
    self.m_shopTips:runCsbAction("xiayi", false)
    self:refreshFigureState()
    util_spinePlay(self.m_cartainBg,"mubu_fen",false)
    performWithDelay(self.m_scWaitNode, function()
        self:setBtnTouchState(true)
        util_spinePlay(self.m_cartainBg,"idle",true)
    end, 25/30)
end

function CactusMariachiShopView:playCoinsLight()
    self.m_coinLeft:runCsbAction("liang", false, function()
        self.m_coinLeft:runCsbAction("idle", true)
    end)
end

function CactusMariachiShopView:playFigureSpine()
    local delayTime = 75/30
    local curTime = os.time()
    if curTime - self.lastPurchaseTime < delayTime then
        return
    end
    self.lastPurchaseTime = curTime
    for i=1, 4 do
        util_spinePlay(self.m_shopFigureSpine[i],"wutaishow_tiaowu",false)
        performWithDelay(self.m_scWaitNode, function()
            util_spinePlay(self.m_shopFigureSpine[i],"shop_idle",true)
        end, delayTime)
    end
end

function CactusMariachiShopView:getIsSuperFreeGame()
    local featureDatas = self.m_runSpinResultData.features
    if not featureDatas then
        return false
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            return true
        end
    end
end

-- 引导
function CactusMariachiShopView:initGuide()
    if not self.m_isGuide then
        return
    end
    self.m_guideNode:setVisible(true)
    self:setGuideVisible()
end

function CactusMariachiShopView:setGuideNextStep()
    if self.m_guideIndex == 5 then
        self:sendData(0, 0, true)
        self.m_guideNode:runCsbAction("xiaoshi5", false, function()
            self.m_guideNode:setVisible(false)
            self.m_isGuide = false
        end)
    else
        self.m_guideIndex = self.m_guideIndex + 1
        self:setGuideVisible()
    end
end

function CactusMariachiShopView:setGuideVisible()
    local appearName = "chuxian" .. self.m_guideIndex
    local disAppearName = "xiaoshi" .. (self.m_guideIndex - 1)
    local idleName = "idle" .. self.m_guideIndex

    self.guidePanelClick:setTouchEnabled(false)
    if self.m_guideIndex > 1 then
        self.m_guideNode:runCsbAction(disAppearName, false, function()
            self.m_guideNode:runCsbAction(appearName, false, function()
                self.m_guideNode:runCsbAction(idleName, true)
                if self.m_guideIndex == 2 then
                    local guideCallFunc = function()
                        self.m_finger:setVisible(true)
                        self.guideStepClick:setVisible(true)
                    end
                    self.guidePanelClick:setTouchEnabled(false)
                    self.tblMusicNodeList[2]:playMusicUnlockAni(guideCallFunc)
                else
                    self.m_finger:setVisible(false)
                    self.guidePanelClick:setTouchEnabled(true)
                end
            end)
        end)
    else
        self.m_guideNode:runCsbAction(appearName, false, function()
            self.m_guideNode:runCsbAction(idleName, true)
            self.guidePanelClick:setTouchEnabled(true)
        end)
    end
end

function CactusMariachiShopView:guidePlayMusic()
    self.guideStepClick:setVisible(false)
    self.m_finger:setVisible(false)
    self:cutShopMusic(1)
    self.tblMusicStateList[1][1] = true
    performWithDelay(self.m_scWaitNode, function()
        self:setGuideNextStep()
        self.guidePanelClick:setTouchEnabled(true)
    end, 1.0)
end

function CactusMariachiShopView:showTips(_showIndex)
    if self.showIndex and self.showIndex ~= _showIndex then
        self.tipsState = false
    end
    self.showIndex = _showIndex
    local tagetNode = self.m_musicBg:findChild("Music".._showIndex)
    local targetPosY = tagetNode:getPositionY()
    self.m_tips:setPositionY(targetPosY+122)
    self.m_tips:stopAllActions()
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self.m_tips:runCsbAction("xiaoshi",false, function()
                self.m_tips:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self.m_tips:setVisible(true)
        self.m_tips:runCsbAction("kaishi",false, function()
            self.m_tips:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_tips, function ()
	    closeTips()
    end, 5.0)
end

return CactusMariachiShopView
