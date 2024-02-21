-- 菜单界面
local MenuNode = class("MenuNode", util_require("base.BaseView"))
-- MenuNode.m_lbInboxNum = nil
-- MenuNode.m_lbInboxTipSp = nil
--
local menuModul = {
    PayTable = "views.menu.MenuItemPayTable",
    Inbox = "views.menu.MenuItemInbox",
    RateUs = "views.menu.MenuItemRatus",
    Settings = "views.menu.MenuItemSetting",
    ContactUs = "views.menu.MenuItemContact",
    GiftCode = "views.menu.MenuItemGiftCode"
}

function MenuNode:ctor()
    MenuNode.super.ctor(self)
    self.m_bgFianlH = 0
    self.m_pbFinalH = 0
    self.m_itemsFinalH = 0
end

-- FIX IOS 0225
function MenuNode:initUI(info, bDeluxe)
    local deluxeName = ""
    if bDeluxe then
        deluxeName = "_1"
    end

    -- if info and info == 1 then
    --     if globalData.slotRunData.isPortrait then
    --         if globalData.adsRunData:hasInterstitialAdsInfo() then
    --             -- csc 2021年09月26日18:10:10 有插屏广告的用户不展示rate us标签
    --             self:createCsbNode("Option/OptionsLayer_shu_ads" .. deluxeName .. ".csb")
    --         else
    --             self:createCsbNode("Option/OptionsLayer_shu" .. deluxeName .. ".csb")
    --         end
    --     else
    --         if globalData.adsRunData:hasInterstitialAdsInfo() then
    --             -- csc 2021年09月26日18:10:10 有插屏广告的用户不展示rate us标签
    --             self:createCsbNode("Option/OptionsLayer_li_ads" .. deluxeName .. ".csb")
    --         else
    --             self:createCsbNode("Option/OptionsLayer_li" .. deluxeName .. ".csb")
    --         end
    --     end

    --     self.m_lbInboxNum = self:findChild("label_inbox_num")
    --     self.m_lbInboxTipSp = self:findChild("sprite_inbox_tip")
    --     self:addClick(self.m_csbOwner["pnl_touch5"])
    --     self:refreshInboxTip(0)
    -- else
    --     if globalData.adsRunData:hasInterstitialAdsInfo() then
    --         -- csc 2021年09月26日18:10:10 有插屏广告的用户不展示rate us标签
    --         self:createCsbNode("Option/OptionsLayer_ads" .. deluxeName .. ".csb")
    --     else
    --         self:createCsbNode("Option/OptionsLayer" .. deluxeName .. ".csb")
    --     end
    -- end

    local csbPath = "Option/OptionsMenu.csb"
    if bDeluxe then
        csbPath = "Option/OptionsMenu_club.csb"
    end
    self:createCsbNode(csbPath)

    -- self.m_sprNewMessage = self:findChild("sprite_contact")
    -- self.m_labNewMessageNum = self:findChild("label_message_num")
    -- if self.m_sprNewMessage then
    --     self.m_sprNewMessage:setVisible(false)
    -- end

    self:initStatus()

    self:initMenuItems(info, bDeluxe)
    -- self.m_clickPalyTable = nil
    -- self:addClick(self.m_csbOwner["pnl_touch4"])
    -- self:addClick(self.m_csbOwner["pnl_touch1"])
    -- self:addClick(self.m_csbOwner["pnl_touch2"])
    -- self:addClick(self.m_csbOwner["pnl_touch3"])
end

function MenuNode:initCsbNodes()
    self.m_imgBg = self:findChild("img_bg")
    self.m_bgOriSize = self.m_imgBg:getContentSize()
    self.m_palPb = self:findChild("pnl_pingbi")
    self.m_pbOriSize = self.m_palPb:getContentSize()
    self.m_palItems = self:findChild("Panel_items")
    self.m_itemsOriSize = self.m_palItems:getContentSize()
    self.m_nodeItem = self:findChild("Node_item")
    self.m_nodeMove = self:findChild("Node_Move")
end

function MenuNode:initMenuItems(info, bDeluxe)
    local _menuList = {}
    local rateUsEntryOpenLv = globalData.constantData.RATE_US_SETTING_ENTRY_OPEN_LEVEL or 0
    local bHideRateEntry = globalData.userRunData.levelNum < rateUsEntryOpenLv
    if info and info == 1 then
        -- cxc 2023年11月30日10:32:55 有插屏广告 不显示 RateUs
        if globalData.adsRunData:hasInterstitialAdsInfo() or bHideRateEntry then
            _menuList = {"PayTable", "Settings", "ContactUs"}
        else
            _menuList = {"PayTable", "RateUs", "Settings", "ContactUs"}
        end

        -- 是否是DiyFeature 触发关卡 (移除PayTable, 特殊玩法没paytable)
        local diyFeatureMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
        if diyFeatureMgr and diyFeatureMgr:isDiyFeatureLevel() then
            table.removebyvalue(_menuList, "PayTable")
        end

    else
        -- cxc 2023年11月30日10:32:55 有插屏广告 不显示 RateUs
        if globalData.adsRunData:hasInterstitialAdsInfo() or bHideRateEntry then
            _menuList = {"GiftCode", "Settings", "ContactUs"}
        else
            _menuList = {"GiftCode", "RateUs", "Settings", "ContactUs"}
        end
    end

    if #_menuList > 0 then
        if self.m_disabledItems and table.nums(self.m_disabledItems) > 0 then
            -- 从屏蔽列表中筛查一遍 去掉屏蔽的页签
            for idx, item in ipairs(_menuList) do
                for i, item_name in ipairs(self.m_disabledItems) do
                    if item == item_name then
                        _menuList[idx] = nil
                    end
                end
            end
        end

        local _lastPosY = 0
        local count = #_menuList
        for i = count, 1, -1 do
            local _menu = _menuList[i]
            local _modul = menuModul[_menu]
            local _itemNode = util_createView(_modul, bDeluxe)

            _itemNode:setPosition(cc.p(0, _lastPosY))
            self.m_nodeItem:addChild(_itemNode)

            _lastPosY = _lastPosY + _itemNode:getItemSize().height

            if i < count then
                _itemNode:setLineVisible(true)
            end
        end

        -- 更新背景和panel大小
        self.m_bgFianlH = self.m_bgOriSize.height + _lastPosY - self.m_itemsOriSize.height
        self.m_pbFinalH = self.m_bgFianlH
        self.m_itemsFinalH = _lastPosY
    end
end

-- 设置需要屏蔽的页签 现在的策略是屏蔽的页签会从列表中去掉
function MenuNode:addItemIntoDisabledList(item_name)
    if not self.m_disabledItems then
        self.m_disabledItems = {}
    end
    if table.nums(self.m_disabledItems) > 0 then
        for idx, item in ipairs(self.m_disabledItems) do
            if item == item_name then
                -- 已经被屏蔽了
                return
            end
        end
    end
    table.insert(self.m_disabledItems, item_name)
end

-- 将页签从屏蔽列表中移除
function MenuNode:removeItemFromDisabledList(item_name)
    if not self.m_disabledItems then
        return
    end
    if table.nums(self.m_disabledItems) > 0 then
        for idx, item in ipairs(self.m_disabledItems) do
            if item == item_name then
                -- 解除屏蔽
                self.m_disabledItems[idx] = nil
                return
            end
        end
    end
end

-- 更新图片UI(高倍场开启关闭都会更新)
-- function MenuNode:updateDeluxeUI(_bOpenDeluxe)
--     local concatStr = _bOpenDeluxe and "_deluxe" or ""

--     -- local bgImgPath = "Option/ui/option_bg" .. concatStr .. ".png"
--     local opBgImgPath = "Option/ui/Options_btn_di" .. concatStr .. ".png"
--     local moreImgPath = "Option/ui/Options_btn_an" .. concatStr .. ".png"
--     local closeImgPath = "Option/ui/Options_btnclose_an" .. concatStr .. ".png"
--     local closeSignImgPath = "Option/ui/Options_btn_close" .. concatStr .. ".png"
--     local lineImgPath = "Option/ui/Options_btn_gang" .. concatStr .. ".png"

--     local nodeBg = self:findChild("pnl_pingbi")
--     -- local spBg = nodeBg:getChildByName("node_1")
--     local spOpBg = self:findChild("Options_btn_di")
--     local spMore = self:findChild("Options_btn_an_12")
--     local spClose = self:findChild("Options_btnclose_an")
--     local spCloseSign = self:findChild("Options_btn_close_1")

--     for i = 1, 3 do
--         local spline = self:findChild("Options_btn_gang" .. i)
--         util_changeTexture(spline, lineImgPath)
--     end

--     -- util_changeTexture(spBg, bgImgPath)
--     util_changeTexture(spOpBg, opBgImgPath)
--     util_changeTexture(spMore, moreImgPath)
--     util_changeTexture(spClose, closeImgPath)
--     util_changeTexture(spCloseSign, closeSignImgPath)
-- end

function MenuNode:onEnter()
    self:initWithTouchEvent()

    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:endShorten()
        end,
        ViewEventType.NOTIFY_MENUNODE_OPEN
    )
    --请求inbox数据
    -- G_GetMgr(G_REF.Inbox):getDataMessage(nil, nil, true)
end

function MenuNode:onExit()
    self:removeEvents()
    MenuNode.super.onExit(self)
end

function MenuNode:initWithTouchEvent()
    local function onTouchBegan_callback(touch, event)
        self:endShorten()
        return false
    end

    local function onTouchMoved_callback(touch, event)
        --self:onTouchMoved(touch,event)
    end

    local function onTouchEnded_callback(touch, event)
        --self:onTouchEnded(touch,event)
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function MenuNode:removeEvents()
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self, true)
end

-- function MenuNode:refreshInboxTip(params)
--     if self.m_lbInboxTipSp == nil then
--         return
--     end

--     --csc 2021-08-25 18:00:43 新手期ABTEST 第三版 A组用户 inbox限制
--     if globalData.userRunData.levelNum < globalData.constantData.NOVICE_INOBXRED_SHOW_LEVEL then
--         params = 0
--     end

--     if params <= 0 then
--         self.m_lbInboxNum:setVisible(false)
--         self.m_lbInboxTipSp:setVisible(false)
--     else
--         self.m_lbInboxNum:setVisible(true)
--         self.m_lbInboxTipSp:setVisible(true)
--         self.m_lbInboxNum:setString(tostring(params))
--     end
-- end

function MenuNode:initStatus()
    self.isHide = true

    -- self.m_palPb:setTouchEnabled(false)
    self:runCsbAction("startIdle", false, nil, 60)
    self:updatePBContentSize(0)
end

function MenuNode:isShorten()
    return self.isHide
end

-- 变长
function MenuNode:idleLengthen()
    self.isHide = true
    self:runCsbAction("startIdle", false, nil, 60)
    -- self.m_palPb:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_CHANGED)
end
-- 变长
function MenuNode:beginLengthen()
    if not self.isHide then
        return
    end
    self:runCsbAction("startBegin", false, nil, 60)
end
-- 变长
function MenuNode:moveLengthen()
    if not self.isHide then
        return
    end
    self:runCsbAction("startMove", false, nil, 60)
end

-- 变长
function MenuNode:endLengthen()
    if self.m_isPlaying or not self.isHide then
        return
    end

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.isHide = false
    self:runCsbAction("startEnd", false, nil, 60)
    self:onUpdate(handler(self, self.showMenu))
    local _actionList = {}
    _actionList[1] = cc.EaseBackOut:create(cc.MoveTo:create(0.3, cc.p(0, -self.m_pbFinalH)))
    _actionList[2] =
        cc.CallFunc:create(
        function()
            self.m_isPlaying = false
        end
    )
    self.m_nodeMove:runAction(cc.Sequence:create(_actionList))
    self.m_isPlaying = true
    -- self.m_palPb:setTouchEnabled(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_CHANGED)
end

function MenuNode:updatePBContentSize(curHeight)
    local _pbCurH = 0
    if curHeight >= self.m_pbFinalH then
        _pbCurH = self.m_pbFinalH
    else
        _pbCurH = curHeight
    end

    -- 超过高度Y轴放大
    local _scale = math.max(1, curHeight / _pbCurH)
    self.m_palPb:setScaleY(_scale)

    -- 底部容器大小
    self.m_palPb:setContentSize(cc.size(self.m_pbOriSize.width, _pbCurH))
    local disPbH = _pbCurH - self.m_bgOriSize.height

    self.m_imgBg:setContentSize(cc.size(self.m_bgOriSize.width, math.min(self.m_bgOriSize.height + math.max(disPbH, 0), self.m_bgFianlH)))
    self.m_imgBg:setPositionY(self.m_palPb:getContentSize().height)

    self.m_palItems:setContentSize(cc.size(self.m_itemsOriSize.width, math.min(math.max(self.m_itemsOriSize.height + disPbH, 0), self.m_itemsFinalH)))
end

function MenuNode:showMenu(dt)
    local _height = math.abs(0 - self.m_nodeMove:getPositionY())

    self:updatePBContentSize(_height)

    if _height == self.m_pbFinalH and not self.m_isPlaying then
        self:onUpdate(
            function()
            end
        )
    end
end

-- 变短
function MenuNode:idleShorten()
    self.isHide = false
    self:runCsbAction("overIdle", false, nil, 60)
    -- self.m_palPb:setTouchEnabled(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_CHANGED)
end

-- 变短
function MenuNode:beginShorten()
    if self.isHide then
        return
    end
    self:runCsbAction("overBegin", false, nil, 60)
end

-- 变短
function MenuNode:moveShorten()
    if self.isHide then
        return
    end
    self:runCsbAction("overMove", false, nil, 60)
end

-- 变短
function MenuNode:endShorten()
    if self.m_isPlaying or self.isHide then
        return
    end

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- self.isHide = true
    self:runCsbAction(
        "overEnd",
        false,
        function()
            -- self:onUpdate(handler(self, self.hideMenu))
        end,
        60
    )
    self:onUpdate(handler(self, self.hideMenu))
    local _actionList = {}
    _actionList[1] = cc.EaseBackIn:create(cc.MoveTo:create(0.3, cc.p(0, 0)))
    _actionList[2] =
        cc.CallFunc:create(
        function()
            self.m_isPlaying = false
            self.isHide = true
        end
    )
    self.m_nodeMove:runAction(cc.Sequence:create(_actionList))
    self.m_isPlaying = true
    -- self.m_palPb:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_CHANGED)
    -- self.m_clickPalyTable = nil
end

function MenuNode:hideMenu(dt)
    local _height = math.abs(0 - self.m_nodeMove:getPositionY())
    self:updatePBContentSize(_height)

    if _height == 0 and not self.m_isPlaying then
        self:onUpdate(
            function()
            end
        )
    end
end

-- function MenuNode:updateNewMessageUi()
--     local status = false
--     if globalData.newMessageNums then
--         status = true
--     end
--     self.m_sprNewMessage:setVisible(status)
--     if status and globalData.newMessageNums then
--         self.m_labNewMessageNum:setString(tostring(globalData.newMessageNums))
--     end
-- end

return MenuNode
