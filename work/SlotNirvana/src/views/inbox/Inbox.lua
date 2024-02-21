--[[--
    邮箱改为三个页签
]]
local Inbox = class("Inbox", BaseLayer)

Inbox.m_isGetMailData = nil -- 是否返回了邮箱数据, 新增每个页签单独处理数据
Inbox.m_isTouchOneItem = nil
Inbox.m_isRefreshCount = nil

-- 邮件页签的属性
local InboxPageInfo = {
    {index = 1, luaName = "views.inbox.InboxPage_collect", pageLayout = "btn_collect", isRedPoint = true},
    {index = 2, luaName = "views.inbox.InboxPage_send", pageLayout = "btn_send", isRedPoint = false},
    {index = 3, luaName = "views.inbox.InboxPage_friend", pageLayout = "btn_friend", isRedPoint = true}
}

function Inbox:initDatas(param)
    Inbox.super.initDatas(self)

    -- 设置横屏csb
    self:setLandscapeCsbName("InBox/InboxPageLayer.csb")
    -- 设置竖屏csb
    self:setPortraitCsbName("InBox/InboxPageLayerPortrait.csb")

    self:setPauseSlotsEnabled(true)

    self.ActionType = "Curve"

    if param then
        self.m_initParam = param
        if param.selIndex then
            self.m_selPageIndex = param.selIndex
        end
    end

    self.m_isGetMailData = false

    self.m_isTouchOneItem = false
    self.m_isRefreshCount = 0

    self:initData()
end

-- param = {selIndex=2, chooseState=3, chooseType="CARD"}
function Inbox:initUI(param)
    -- gLobalSendDataManager:getLogIap():setEntryType("inbox")
    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)

    Inbox.super.initUI(self)

    G_GetMgr(G_REF.Inbox):setShowInboxTimes(1)

    -- -- 向SDK请求拉取Facebook好友列表数据
    -- G_GetMgr(G_REF.Inbox):GetFacebookFriendList()

    -- 请求最新数据
    -- self:queryMailInfo()
end

function Inbox:initCsbNodes()
    self.m_btn_close = self:findChild("btn_close")
    self.m_imgColloct = self:findChild("img_collect")
    self.m_imgColloctDown = self:findChild("img_collect_0")
    self.m_imgSend = self:findChild("img_send")
    self.m_imgSendDown = self:findChild("img_send_0")
    self.m_imgFriend = self:findChild("img_friend")
    self.m_imgFriendDown = self:findChild("img_friend_0")
    self.m_imgColloctCH = self:findChild("img_collectch")
    self.m_imgSendCH = self:findChild("img_sendch")
    self.m_imgFriendCH = self:findChild("img_friendch")

    self:initNode()
end

-- 目前为1，以后根据需求在这里添加
function Inbox:getDefaultPageIndex()
    return 1
end

function Inbox:initData()
    -- 如果没有默认选择页签，设置默认页签
    if not self.m_selPageIndex then
        self.m_selPageIndex = self:getDefaultPageIndex()
    end
    -- 获取邮件数据
end

function Inbox:initNode()
    self.m_btnX = self:findChild("Button_x")
    self.m_contentNode = self:findChild("node_contents")

    self.m_pageTitles = {}
    for i = 1, #InboxPageInfo do
        self.m_pageTitles[i] = self:findChild(InboxPageInfo[i].pageTitleNode)

        local pageBtn = self:findChild(InboxPageInfo[i].pageLayout)
        self:addClick(pageBtn)
    end

    self:updatePageBtn()
end

function Inbox:initView()
    self:setTouchStatus(false)
    self:updatePageInfo()
    self:updateRedPoint()
end

--------------------------------------------------------------------------------------------------
-- state: false,没有获得数据， true,已经获得数据
function Inbox:setRequestMailState(state)
    self.m_isGetMailData = state
end

function Inbox:getRequestMailState(pageIndex)
    if self.m_isGetMailData == true then
        return true
    end
    return false
end

--------------------------------------------------------------------------------------------------
function Inbox:changePage(pageIndex)
    if not pageIndex then
        return
    end
    if self.m_selPageIndex == pageIndex then
        return
    end

    self.m_selPageIndex = pageIndex

    self:updatePageBtn()
    self:updatePageInfo()
end

-- 更新按钮的状态
function Inbox:updatePageBtn()
    self.m_imgColloct:setVisible(self.m_selPageIndex ~= 1)
    self.m_imgColloctDown:setVisible(self.m_selPageIndex == 1)

    self.m_imgSend:setVisible(self.m_selPageIndex ~= 2)
    self.m_imgSendDown:setVisible(self.m_selPageIndex == 2)

    self.m_imgFriend:setVisible(self.m_selPageIndex ~= 3)
    self.m_imgFriendDown:setVisible(self.m_selPageIndex == 3)

    self.m_imgColloctCH:setVisible(self.m_selPageIndex == 1)
    self.m_imgSendCH:setVisible(self.m_selPageIndex == 2)
    self.m_imgFriendCH:setVisible(self.m_selPageIndex == 3)
end

-- 更新每页的显示区域
function Inbox:updatePageInfo()
    if not self.m_pageUIs then
        self.m_pageUIs = {}
    end

    if not self.m_pageUIs[tostring(self.m_selPageIndex)] then
        local view = util_createView(InboxPageInfo[self.m_selPageIndex].luaName, self, self.m_initParam)
        view:setTag(1000 + self.m_selPageIndex)
        self.m_contentNode:addChild(view)
        self.m_pageUIs[tostring(self.m_selPageIndex)] = view
    end
    for pageIndex, pageView in pairs(self.m_pageUIs) do
        if tonumber(pageIndex) == self.m_selPageIndex then
            pageView:setVisible(true)
            if pageView.updataInboxItem then
                pageView:updataInboxItem()
            end
        else
            pageView:setVisible(false)
        end
    end
end

--------------------------------------------------------------------------------------------------
function Inbox:setTouchStatus(canTouch)
    self.isClose = not canTouch
    self.m_btn_close:setTouchEnabled(canTouch)
end
function Inbox:getTouchStatus()
    return self.isClose
end
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- 小红点
function Inbox:updateRedPoint()
    for i = 1, #InboxPageInfo do
        if InboxPageInfo[i].isRedPoint then
            local redNum = 0
            local btnName = InboxPageInfo[i].pageLayout
            if btnName == "btn_collect" then
                local collectData = G_GetMgr(G_REF.Inbox):getSysRunData()
                if collectData then
                    redNum = collectData:getMailCount()
                end
            elseif btnName == "btn_friend" then
                local friendData = G_GetMgr(G_REF.Inbox):getFriendRunData()
                if friendData then
                    redNum = friendData:getMailCount()
                end
            end
            local pageBtn = self:findChild(btnName)
            local redPoint = pageBtn:getChildByName("RED_POINT")
            if redNum > 0 then
                if not redPoint then
                    redPoint = util_createView("views.inbox.InboxPage_redPoint")
                    redPoint:setName("RED_POINT")
                    local pageBtnSize = pageBtn:getContentSize()
                    redPoint:setPosition(cc.p(pageBtnSize.width * 0.9, pageBtnSize.height * 0.8))
                    pageBtn:addChild(redPoint)
                end
                redPoint:updateNum(redNum)
            else
                if redPoint then
                    redPoint:removeFromParent()
                end
            end
        end
    end
end
--------------------------------------------------------------------------------------------------

function Inbox:onKeyBack()
    if self.m_isGetMailData == false then
        return -- 数据未返回时 不允许关闭邮箱界面
    end

    self:closeUI()
end

function Inbox:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    -- gLobalSendDataManager:getLogIap():setLastEntryType()

    gLobalViewManager:addLoadingAnima(true)

    local callback = function()
        globalNoviceGuideManager:attemptShowRepetition()
        gLobalViewManager:removeLoadingAnima()
    end

    Inbox.super.closeUI(self, callback)
end

function Inbox:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
        if G_GetMgr(G_REF.Inbox):getWatchRewardVideoFalg() == false and globalData.adsRunData:isPlayRewardForPos(PushViewPosType.InboxReward) then
            if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.CloseInbox) then
                gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.CloseInbox)
                gLobalAdsControl:playAutoAds(PushViewPosType.CloseInbox)
            end
        else
            G_GetMgr(G_REF.Inbox):setWatchRewardVideoFalg(false)
        end
    elseif name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changePage(1)
    elseif name == "btn_send" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changePage(2)
    elseif name == "btn_friend" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changePage(3)
    end
end

function Inbox:onEnter()
    Inbox.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(data)
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD,
        true
    )

    --服务器返回成功消息
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            --self:setFbLabShow()
            gLobalViewManager:removeLoadingAnima()
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS,
        true
    )

    ---fb登陆成功回调
    gLobalNoticManager:addObserver(
        self,
        function(Target, loginInfo)
            self:checkFBLoginState(loginInfo)
        end,
        GlobalEvent.FB_LoginStatus,
        true
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_CARD_SYS_ENTER
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if not params.flag then
    --             self:requestSDKForFBFriendList()
    --         end
    --     end,
    --     ViewEventType.NOTIFY_INBOX_FACEBOOK_FRIEND_LIST
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRedPoint()
        end,
        ViewEventType.NOTIFY_REFRESH_MAIL_COUNT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setRequestMailState(true)
        end,
        ViewEventType.NOTIFY_INBOX_RESET_REQUEST_STATE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_INBOX_CLOSE
    )
end

function Inbox:loginFail(errorData)
    -- 登录失败 -- 添加提示界面 
    local view = util_createView("views.logon.Logonfailure", true)
    view:setFailureDescribe(errorData)

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
end

function Inbox:checkFBLoginState(loginInfo)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end
    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
        local loginState = loginInfo.state
        local msg = loginInfo.message
        --成功
        if loginState == 1 then
            --取消
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        elseif loginState == 0 then
            --失败
            gLobalViewManager:removeLoadingAnima()
        else
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(nil)
        end
    else
        if loginInfo then
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        else
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(nil)
        end
    end
end

-- 请求最新的邮箱数据
function Inbox:queryMailInfo()
    self:setRequestMailState(false)
    gLobalViewManager:addLoadingAnimaDelay()

    G_GetMgr(G_REF.Inbox):addShowInboxTimes()
    --请求数据 无论成功失败都进入 inbox
    G_GetMgr(G_REF.Inbox):getDataMessage(
        function(data)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_RESET_REQUEST_STATE)
            gLobalViewManager:removeLoadingAnima()
            -- 领取成功后要刷新邮件列表
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
        end,
        function(data)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_RESET_REQUEST_STATE)
            gLobalViewManager:removeLoadingAnima()
        end,
        true
    )
end

-- function Inbox:requestSDKForFBFriendList()
--     if G_GetMgr(G_REF.Inbox):getFriendRunData():isLoginFB() then
--         if not self.m_delayTime then
--             self.m_delayTime =
--                 performWithDelay(
--                 self,
--                 function()
--                     self.m_delayTime = nil
--                     -- 向SDK请求拉取Facebook好友列表数据
--                     G_GetMgr(G_REF.Inbox):SDK_GetFacebookFriendList()
--                 end,
--                 5
--             )
--         end
--     end
-- end

return Inbox
