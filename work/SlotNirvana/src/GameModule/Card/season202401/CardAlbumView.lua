--[[
    集卡系统
    卡册选择面板子类 202102赛季
    数据来源于年度开启的赛季
--]]
local CardAlbumView201903 = util_require("GameModule.Card.season201903.CardAlbumView")
local CardAlbumView = class("CardAlbumView", CardAlbumView201903)

function CardAlbumView:initDatas(isPlayStart)
    CardAlbumView.super.initDatas(self, isPlayStart)
    self:setHideActionEnabled(true)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season202401"))
    self:setName("CardAlbumView" .. "season202401")
end

function CardAlbumView:initCsbNodes()
    CardAlbumView.super.initCsbNodes(self)
    self.m_nodeMenu = self:findChild("node_menu")
    self.m_btnMenuClose = self:findChild("btn_menuClose")
    self.m_btnMenuClose:setVisible(false)
    self.node_cardrank = self:findChild("node_cardrank")

    -- CGspine的节点
    self.m_nodeSpineCG = self:findChild("node_spine_CG")
end

function CardAlbumView:getTitleLuaPath()
    return "GameModule.Card.season202401.CardAlbumTitle"
end

function CardAlbumView:getBottomLuaPath()
    return "GameModule.Card.season202401.CardSeasonBottom"
end

function CardAlbumView:getCellLuaPath()
    return "GameModule.Card.season202401.CardAlbumCell"
end

function CardAlbumView:getMenuLuaPath()
    return "GameModule.Card.season202401.CardAlbumMenuLayer"
end

function CardAlbumView:getAlbumListData()
    local cardClans, wildClans, normalClans, statueClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return normalClans
end

function CardAlbumView:getRoundGuideLuaPath()
    return "GameModule.Card.season202401.CardAlbumRoundGuide"
end

function CardAlbumView:getCsbFrame()
    return 60
end


function CardAlbumView:playShowActionCustom(callFunc)
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")

    local callback = function()

        
        self:updateUI(self.m_isPlayStart)
        self:runCsbAction(
            "start",
            false,
            function()
                self:initRoundGuide() -- 引导从onEnter中挪到播完 CG 之后 202401
                if callFunc then
                    callFunc()
                end
                -- local bCanGuide = self:checkClickFirstGuideEnabled()
                -- self:initAlbumList(not bCanGuide)
                -- util_setCascadeOpacityEnabledRescursion(self, true)
                -- util_nextFrameFunc(
                --     function()
                --         self:checkClickFirstGuide()
                --     end
                -- )
            end,
            60
        )
    end

    self:playCG(callback)
end

-- function CardAlbumView:playHideAction()
--     gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
--     CardAlbumView.super.playHideAction(self, "over")
-- end

function CardAlbumView:isPlayAlbumAct()
    return not self:checkClickFirstGuideEnabled()
end

-- function CardAlbumView:onShowedCallFunc()
--     CardAlbumView.super.onShowedCallFunc(self)

--     self:runCsbAction("idle", true, nil, 60)

--     local bCanGuide = self:checkClickFirstGuideEnabled()
--     self:initAlbumList(not bCanGuide)

    
--     util_nextFrameFunc(
--         function()
--             self:checkClickFirstGuide()
--         end
--     )
--     util_setCascadeOpacityEnabledRescursion(self, true)
-- end


function CardAlbumView:initSpineUI()
    if CardSysManager:isShowCG() then
        self.m_spineCG = util_spineCreate("CardRes/Other/spine/guochang", true, true, 1)
        self.m_nodeSpineCG:addChild(self.m_spineCG)
    end
end

-- 进入集卡系统的开场动画 202401 新加的
function CardAlbumView:playCG(callback)
    CardSysManager:saveCGTime()
    if not tolua.isnull(self.m_spineCG) then
        util_spinePlay(self.m_spineCG, "start", false)
        util_spineEndCallFunc(
            self.m_spineCG,
            "start",
            function()
                self.m_nodeSpineCG:setVisible(false)
                if callback then
                    callback()
                end
            end
        )
    else
        if callback then
            callback()
        end
    end
end

function CardAlbumView:initView()
    CardAlbumView.super.initView(self)
    self:initRankItem()
end

function CardAlbumView:initRankItem()
    if tolua.isnull(self.node_cardrank) then
        return
    end
    if not tolua.isnull(self.rank_icon) then
        return
    end
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        return
    end    
    local rank_icon = G_GetMgr(G_REF.CardRank):getEntryIcon()
    if not tolua.isnull(rank_icon) then
        rank_icon:addTo(self.node_cardrank)
        self.rank_icon = rank_icon
    end
end

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
    if gLobalViewManager:getViewByName("CardAlbumMenuLayer" .. "season202401") ~= nil then
        return
    end
    local view = util_createView(self:getMenuLuaPath(), handler(self, self.showMenuCloseBtn))
    view:setName("CardAlbumMenuLayer" .. "season202401")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardAlbumView:initRoundGuide()
    local luaPath = self:getRoundGuideLuaPath()
    if not luaPath then
        return
    end
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    local round = albumData and albumData.round or 0
    local cacheRound = gLobalDataManager:getNumberByField("Card_Round_Guide_" .. globalData.userRunData.uid, 0)
    if cacheRound < round then
        gLobalDataManager:setNumberByField("Card_Round_Guide_" .. globalData.userRunData.uid, albumData.round)

        self.m_isGuiding = true
        -- 创建黑色遮罩
        self.m_roundGuideMask = self:createGuideMask("Mask_RoundGuide")

        -- 提高层级
        local pos = util_convertToNodeSpace(self.m_titleUI, self.m_roundGuideMask)
        util_changeNodeParent(self.m_roundGuideMask, self.m_titleUI)
        self.m_titleUI:setPosition(pos)
        self.m_titleUI:setScale(self:getUIScalePro())

        -- 引导气泡
        local view = util_createView(luaPath, albumData.round)
        self.m_roundGuideMask:addChild(view)
        view:setPosition(cc.p(display.width / 2, 0))
        view:setScale(self:getUIScalePro())
    end
end

function CardAlbumView:createGuideMask(_touchName)
    local tLayout = ccui.Layout:create()
    self.m_csbNode:addChild(tLayout, 100)
    tLayout:setName(_touchName or "Mask_RoundGuide")
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(true)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setPosition(cc.p(display.width / 2, display.height / 2))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(190)
    -- tLayout:addTouchEventListener(handler(self, self.clickRoundGuideMask))
    self:addClick(tLayout)
    return tLayout
end

function CardAlbumView:clickRoundGuideMask()
    -- 恢复层级
    local pos = util_convertToNodeSpace(self.m_titleUI, self.m_titleNode)
    util_changeNodeParent(self.m_titleNode, self.m_titleUI)
    self.m_titleUI:setPosition(pos)
    self.m_titleUI:setScale(1)
    -- 移除遮罩
    if not tolua.isnull(self.m_roundGuideMask) then
        self.m_roundGuideMask:removeFromParent()
        self.m_roundGuideMask = nil
    end
    self.m_isGuiding = false
end

function CardAlbumView:isGuiding()
    return self.m_isGuiding
end

-- 点击事件 --
function CardAlbumView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        CardSysManager:closeCardAlbumView(
            function()
                CardSysManager:exitCardAlbum()
            end
        )
    elseif name == "btn_menuOpen" then
        self:showAlbumMenuUI()
    elseif name == "btn_menuClose" then
        self:hideMenuCloseBtn()
        local view = gLobalViewManager:getViewByName("CardAlbumMenuLayer" .. "season202401")
        if not tolua.isnull(view) then
            view:closeUI()
        end
    elseif name == "Mask_RoundGuide" then
        self:clickRoundGuideMask()
    elseif name == "Mask_Guide" then
        self:removeGuideMask()
    end
end

function CardAlbumView:onEnter()
    CardAlbumView.super.onEnter(self)
    -- self:initRoundGuide()

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                if params.refName == G_REF.CardRank then
                    self:initRankItem()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )
end

function CardAlbumView:checkClickFirstGuideEnabled()
    if self:isGuiding() then
        return false
    end

    local bCanGuide = gLobalDataManager:getBoolByField("CardGuideFirstClanClickEnabled", false)
    return bCanGuide
end

function CardAlbumView:checkClickFirstGuide()
    local bCanGuide = self:checkClickFirstGuideEnabled()
    if not bCanGuide then
        -- 限时膨胀 hl
        local limitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
        if limitExpansion then
            limitExpansion:showLogoLayer()
            limitExpansion:playStartAction()
        end

        -- 限时多倍奖励
        G_GetMgr(ACTIVITY_REF.AlbumMoreAward):showLogoLayer()

        return
    end

    gLobalDataManager:setBoolByField("CardGuideFirstClanClickEnabled", false)
    self.m_isGuiding = true
    -- 创建黑色遮罩
    self.m_guideMask = self:createGuideMask("Mask_Guide")
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

function CardAlbumView:getGuideLua()
    return "GameModule.Card.season202401.CardAlbumCellGuide"
end

return CardAlbumView
