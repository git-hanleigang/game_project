--[[
    集卡系统
    卡册选择面板子类 202102赛季
    数据来源于年度开启的赛季
--]]
local CardAlbumView201903 = util_require("GameModule.Card.season201903.CardAlbumView")
local CardAlbumView = class("CardAlbumView", CardAlbumView201903)

function CardAlbumView:initDatas(isPlayStart)
    CardAlbumView.super.initDatas(self, isPlayStart)
    self:setShowActionEnabled(true)
    self:setHideActionEnabled(true)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season202203"))
    self:setName("CardAlbumView" .. "season202203")
end

function CardAlbumView:initCsbNodes()
    CardAlbumView.super.initCsbNodes(self)
    self.m_nodeMenu = self:findChild("node_menu")
    self.m_btnMenuClose = self:findChild("btn_menuClose")
    self.m_btnMenuClose:setVisible(false)
end

function CardAlbumView:getTitleLuaPath()
    return "GameModule.Card.season202203.CardAlbumTitle"
end

function CardAlbumView:getBottomLuaPath()
    return "GameModule.Card.season202203.CardSeasonBottom"
end

function CardAlbumView:getCellLuaPath()
    return "GameModule.Card.season202203.CardAlbumCell"
end

function CardAlbumView:getMenuLuaPath()
    return "GameModule.Card.season202203.CardAlbumMenuLayer"
end

function CardAlbumView:getAlbumListData()
    local cardClans, wildClans, normalClans, statueClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return normalClans
end

function CardAlbumView:getRoundGuideLuaPath()
    return "GameModule.Card.season202203.CardAlbumRoundGuide"
end

function CardAlbumView:getCsbFrame()
    return 60
end

-- function CardAlbumView:playShowAction()
--     if self.m_isPlayStart then
--         local className = self.__cname
--         local callFunc = function()
--             if not tolua.isnull(self) then
--                 self:showActionCallback()
--                 self:_onEnterOver()
--             else
--                 assert(nil, "执行" .. className .. "的show回调时，C++对象被释放，请检查逻辑！！")
--             end
--         end

--         gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
--         self:runCsbAction(
--             "start",
--             false,
--             function()
--                 callFunc()
--                 self:runCsbAction("idle", true, nil, 60)
--                 self:initAlbumList(true)
--                 util_setCascadeOpacityEnabledRescursion(self, true)
--             end,
--             60
--         )
--         self:maskShow(15 / 60)
--     else
--         self:runCsbAction("idle", true, nil, 60)
--         self:initAlbumList(true)
--         util_setCascadeOpacityEnabledRescursion(self, true)
--     end
-- end

-- function CardAlbumView:playHideAction()
--     gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
--     CardAlbumView.super.playHideAction(self, "over")
-- end

function CardAlbumView:initView()
    -- CardSysRuntimeMgr:setRecoverSourceUI(CardSysRuntimeMgr.RecoverSourceUI.AlbumUI)
    -- self:initAdapt()
    -- self:initTitle(self.m_isPlayStart)
    -- self:initBottom(self.m_isPlayStart)
    CardAlbumView.super.initView(self)
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
    if gLobalViewManager:getViewByName("CardAlbumMenuLayer" .. "season202203") ~= nil then
        return
    end
    local view = util_createView(self:getMenuLuaPath(), handler(self, self.showMenuCloseBtn))
    view:setName("CardAlbumMenuLayer" .. "season202203")
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
        self.m_roundGuideMask = self:createRoundGuideMask()

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

function CardAlbumView:createRoundGuideMask()
    local tLayout = ccui.Layout:create()
    self.m_csbNode:addChild(tLayout, 100)
    tLayout:setName("Mask_RoundGuide")
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
        local view = gLobalViewManager:getViewByName("CardAlbumMenuLayer" .. "season202203")
        if not tolua.isnull(view) then
            view:closeUI()
        end
    elseif name == "Mask_RoundGuide" then
        self:clickRoundGuideMask()
    end
end

function CardAlbumView:onEnter()
    CardAlbumView.super.onEnter(self)
    self:initRoundGuide()
end

return CardAlbumView
