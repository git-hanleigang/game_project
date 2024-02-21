--[[
    集卡系统
    卡册选择面板子类 202102赛季
    数据来源于年度开启的赛季
--]]

local TEST_GUIDE = false
local CardAlbumView201903 = util_require("GameModule.Card.season201903.CardAlbumView")
local CardAlbumView = class("CardAlbumView", CardAlbumView201903)

function CardAlbumView:initDatas(isPlayStart)
    CardAlbumView.super.initDatas(self, isPlayStart)
    self:setShowActionEnabled(true)
    self:setHideActionEnabled(true)
    -- self.m_nadoMachineLuaPath = "GameModule.Card.season302301.CardSeasonBottomNadoMachine"
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season302301"))
    self:setName("CardAlbumView" .. "season302301")
end

function CardAlbumView:initCsbNodes()
    CardAlbumView.super.initCsbNodes(self)
    self.m_nodeMenu = self:findChild("node_menu")
    self.m_btnMenuClose = self:findChild("btn_menuClose")
    self.m_btnMenuClose:setVisible(false)
    -- self.node_cardrank = self:findChild("node_cardrank")
    self.m_nodeNadoMachine = self:findChild("node_nadoMachine")
end

function CardAlbumView:getTitleLuaPath()
    return "GameModule.Card.season302301.CardAlbumTitle"
end

function CardAlbumView:getBottomLuaPath()
    return "GameModule.Card.season302301.CardSeasonBottom"
end

function CardAlbumView:getCellLuaPath()
    return "GameModule.Card.season302301.CardAlbumCell"
end

function CardAlbumView:getMenuLuaPath()
    return "GameModule.Card.season302301.CardAlbumMenuLayer"
end

function CardAlbumView:getAlbumListData()
    local cardClans, wildClans, normalClans, statueClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return normalClans    
end

-- function CardAlbumView:getRoundGuideLuaPath()
--     return "GameModule.Card.season302301.CardAlbumRoundGuide"
-- end

function CardAlbumView:getCsbFrame()
    return 60
end

-- function CardAlbumView:playShowAction()
--     if self.m_isPlayStart then
--         gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
--         CardAlbumView.super.playShowAction(self, "start")
--     else
--         CardAlbumView.super.playShowAction(self)
--     end
-- end

function CardAlbumView:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self:initAlbumList(true)
    util_setCascadeOpacityEnabledRescursion(self, true)
    util_nextFrameFunc(function()
        self:checkGuide()
    end)
end

function CardAlbumView:initView()
    -- CardSysRuntimeMgr:setRecoverSourceUI(CardSysRuntimeMgr.RecoverSourceUI.AlbumUI)
    -- self:initAdapt()
    -- self:initTitle(self.m_isPlayStart)
    -- self:initBottom(self.m_isPlayStart)
    CardAlbumView.super.initView(self)

    -- self:initNadoMachine()

    -- self:initRankItem()
end

-- function CardAlbumView:initBottom(isPlayStart)
--     if not self.m_bottomUI then
--         self.m_bottomUI = util_createView(self:getBottomLuaPath(), CardSysRuntimeMgr.RecoverSourceUI.AlbumUI, nil, self)
--         self.m_bottomNode:addChild(self.m_bottomUI)
--     end
--     if self.m_bottomUI.updateUI then
--         self.m_bottomUI:updateUI(isPlayStart)
--     end
-- end

-- function CardAlbumView:initRankItem()
--     if tolua.isnull(self.node_cardrank) then
--         return
--     end
--     if not tolua.isnull(self.rank_icon) then
--         return
--     end
--     local albumID = CardSysRuntimeMgr:getSelAlbumID()
--     if CardSysRuntimeMgr:isPastAlbum(albumID) then
--         return
--     end    
--     local rank_icon = G_GetMgr(G_REF.CardRank):getEntryIcon()
--     if not tolua.isnull(rank_icon) then
--         rank_icon:addTo(self.node_cardrank)
--         self.rank_icon = rank_icon
--     end
-- end

-- function CardAlbumView:initNadoMachine()
--     if not self.m_nadoMachineLuaPath then
--         return
--     end
--     -- 只有当前赛季显示
--     if CardSysRuntimeMgr:getCurAlbumID() ~= CardSysRuntimeMgr:getSelAlbumID() then
--         return
--     end
--     self.m_nadoMachine = util_createView(self.m_nadoMachineLuaPath)
--     self.m_nodeNadoMachine:addChild(self.m_nadoMachine)    
-- end

function CardAlbumView:showMenuCloseBtn()
    self.m_btnMenuClose:setVisible(true)
    local worldPos = self.m_btnMenuClose:getParent():convertToWorldSpace(cc.p(self.m_btnMenuClose:getPosition()))
    util_changeNodeParent(gLobalViewManager:getViewLayer(), self.m_btnMenuClose, ViewZorder.ZORDER_UI)
    self.m_btnMenuClose:setPosition(cc.p(worldPos))
    self.m_btnMenuClose:setScale(self:getUIScalePro())
end

function CardAlbumView:hideMenuCloseBtn()
    self.m_btnMenuClose:setVisible(false)
    util_changeNodeParent(self.m_nodeMenu, self.m_btnMenuClose, 1)
    self.m_btnMenuClose:setPosition(cc.p(0, 0))
    self.m_btnMenuClose:setScale(1)
end

function CardAlbumView:showAlbumMenuUI()
    if gLobalViewManager:getViewByName("CardAlbumMenuLayer" .. "season302301") ~= nil then
        return
    end
    local view = util_createView(self:getMenuLuaPath(), handler(self, self.showMenuCloseBtn))
    view:setName("CardAlbumMenuLayer" .. "season302301")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- function CardAlbumView:initRoundGuide()
--     local luaPath = self:getRoundGuideLuaPath()
--     if not luaPath then
--         return
--     end
--     local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
--     local round = albumData and albumData.round or 0
--     local cacheRound = gLobalDataManager:getNumberByField("Card_Round_Guide_" .. globalData.userRunData.uid, 0)
--     if cacheRound < round then
--         gLobalDataManager:setNumberByField("Card_Round_Guide_" .. globalData.userRunData.uid, albumData.round)

--         self.m_isGuiding = true
--         -- 创建黑色遮罩
--         self.m_roundGuideMask = self:createRoundGuideMask()

--         -- 提高层级
--         local pos = util_convertToNodeSpace(self.m_titleUI, self.m_roundGuideMask)
--         util_changeNodeParent(self.m_roundGuideMask, self.m_titleUI)
--         self.m_titleUI:setPosition(pos)
--         self.m_titleUI:setScale(self:getUIScalePro())

--         -- 引导气泡
--         local view = util_createView(luaPath, albumData.round)
--         self.m_roundGuideMask:addChild(view)
--         view:setPosition(cc.p(display.width / 2, 0))
--         view:setScale(self:getUIScalePro())
--     end
-- end

-- function CardAlbumView:clickRoundGuideMask()
--     -- 恢复层级
--     local pos = util_convertToNodeSpace(self.m_titleUI, self.m_titleNode)
--     util_changeNodeParent(self.m_titleNode, self.m_titleUI)
--     self.m_titleUI:setPosition(pos)
--     self.m_titleUI:setScale(1)
--     -- 移除遮罩
--     if not tolua.isnull(self.m_roundGuideMask) then
--         self.m_roundGuideMask:removeFromParent()
--         self.m_roundGuideMask = nil
--     end
--     self.m_isGuiding = false
-- end

-- 点击事件 --
function CardAlbumView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        CardSysManager:closeCardAlbumView(
            function()
                CardSysManager:exitCardAlbum()
                G_GetMgr(G_REF.CardNoviceSale):checkCloseCardPopLayer()
            end
        )
    elseif name == "btn_menuOpen" then
        self:showAlbumMenuUI()
    elseif name == "btn_menuClose" then
        self:hideMenuCloseBtn()
        local view = gLobalViewManager:getViewByName("CardAlbumMenuLayer" .. "season302301")
        if not tolua.isnull(view) then
            view:closeUI()
        end
    -- elseif name == "Mask_RoundGuide" then
    --     self:clickRoundGuideMask()
    elseif name == "Mask_Guide" then
        self:removeGuideMask()
    end
end

function CardAlbumView:onEnter()
    CardAlbumView.super.onEnter(self)
    -- self:initRoundGuide()

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         if not tolua.isnull(self) then
    --             if params.refName == G_REF.CardRank then
    --                 self:initRankItem()
    --             end
    --         end
    --     end,
    --     ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    -- )
end

function CardAlbumView:hasGuide()
    if TEST_GUIDE then
        return true
    end
    local firstGuideIndex = gLobalDataManager:getNumberByField("Card_Novice_First_Guide_" .. globalData.userRunData.uid, 0)
    if firstGuideIndex == 0 then
        return true
    end
    return false
end

function CardAlbumView:saveGuideIndex()
    if not TEST_GUIDE then
        gLobalDataManager:setNumberByField("Card_Novice_First_Guide_" .. globalData.userRunData.uid, 1)
    end
end

function CardAlbumView:getGuideLua()
    return "GameModule.Card.season302301.CardAlbumCellGuide"
end

function CardAlbumView:createGuideMask()
    local tLayout = ccui.Layout:create()
    self.m_csbNode:addChild(tLayout, 100)
    tLayout:setName("Mask_Guide")
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(true)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setPosition(cc.p(display.width / 2, display.height / 2))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(190)
    tLayout:setScale(1)
    -- tLayout:addTouchEventListener(handler(self, self.clickRoundGuideMask))
    self:addClick(tLayout)
    return tLayout
end

function CardAlbumView:checkGuide()
    if not self:hasGuide() then 
        -- 没有引导 监测是否 要弹出新手期集卡双倍奖励弹板
        self:checkShowNoviceDoubleRewardLayer()
        return
    end
    self:saveGuideIndex()

    self.m_isGuiding = true
    -- 创建黑色遮罩
    self.m_guideMask = self:createGuideMask()
    -- 提高层级
    local cell = self.uiList[1]
    local guideNode = cell:getGuideNode()
    if guideNode then
        self.m_guideParent = guideNode:getParent()
        local ratation = cell:getRotation()
        self.m_oriScale = guideNode:getScale()
        local scale = self:getNodeGlobalScale(guideNode)

        local pos = util_convertToNodeSpace(guideNode, self.m_guideMask)

        util_changeNodeParent(self.m_guideMask, guideNode)
        guideNode:setPosition(pos)
        guideNode:setRotation(ratation)
        guideNode:setScale(scale)
        self.m_guideNode = guideNode

        -- 引导气泡
        local bubble = util_createView(self:getGuideLua())
        if bubble then
            self.m_guideMask:addChild(bubble)
            bubble:setPosition(cc.p(display.width / 2, display.height / 2))
            bubble:setScale(self:getUIScalePro())
        end
    end
end

function CardAlbumView:getNodeGlobalScale(_node)
    local scale = 1
    local _getScale
    _getScale = function(__node)
        if __node then
            scale = scale * __node:getScale()
            if __node:getParent() then
                _getScale(__node:getParent())
            end
        end
    end
    _getScale(_node)
    return scale
end

function CardAlbumView:removeGuideMask()
    if not self.m_isGuiding then
        return
    end
    self.m_isGuiding = false
    if self.m_guideNode and self.m_guideParent then        
        -- 恢复层级
        local pos = util_convertToNodeSpace(self.m_guideNode, self.m_guideParent)
        util_changeNodeParent(self.m_guideParent, self.m_guideNode)
        self.m_guideNode:setPosition(pos)
        self.m_guideNode:setRotation(1)
        self.m_guideNode:setScale(self.m_oriScale)
        -- 移除遮罩
        if not tolua.isnull(self.m_guideMask) then
            self.m_guideMask:removeFromParent()
            self.m_guideMask = nil
        end
    end
end

-- 重写父类方法
function CardAlbumView:initAlbumList(isPlayStart)
    if self:hasGuide() == true then
        isPlayStart = false
    end
    local cardClanData = self:getAlbumListData()
    if cardClanData ~= nil then
        if not self.uiList then
            self.uiList = {}
            for k, v in pairs(cardClanData) do
                -- 创建章节cell
                local albumCell = util_createView(self:getCellLuaPath())
                albumCell:updateCell(k, v)
                albumCell:updateTagNew()
                table.insert(self.uiList, albumCell)
            end

            local circleScrollUI = util_createView("base.CircleScrollUI")
            circleScrollUI:setMargin(0)
            circleScrollUI:setMarginXY(120, 20)
            circleScrollUI:setMaxTopYPercent(0.5)
            circleScrollUI:setTopYHeight(120)
            circleScrollUI:setMaxAngle(20)
            circleScrollUI:setRadius(2500)
            if isPlayStart then
                circleScrollUI:setPlayToLeftAnimInfo(0.2, 4)            
            end
            for i = 1, #self.uiList do
                local albumCell = self.uiList[i]
                albumCell:playAnim(isPlayStart == true)
            end
            circleScrollUI:setUIList(self.uiList)

            local scale = self:findChild("root"):getScale()
            circleScrollUI:setDisplaySize(display.width / scale, 525)
            circleScrollUI:setPosition(-display.width / scale / 2, -2270 - display.height / 2)
            self.m_albumNode:addChild(circleScrollUI)
            util_setCascadeOpacityEnabledRescursion(self, true)
        else
            for i = 1, #self.uiList do
                local albumCell = self.uiList[i]
                albumCell:updateCell(i, cardClanData[i])
                albumCell:updateTagNew()
                albumCell:playAnim()
            end
        end
    end
end

-- 没有引导 监测是否 要弹出新手期集卡双倍奖励弹板
function CardAlbumView:checkShowNoviceDoubleRewardLayer()
    G_GetMgr(G_REF.CardNoviceSale):showDoubleRewardLayer(true)
end

return CardAlbumView
