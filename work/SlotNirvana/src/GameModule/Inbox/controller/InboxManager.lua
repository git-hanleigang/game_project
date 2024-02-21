--[[--
    Inbox管理
    主要处理：
        数据处理类的句柄
        请求接口
]]
--fix ios 0224
util_require("GameModule.Inbox.config.InboxConfig")

-- local ParseInboxData = util_require("data.inboxData.ParseInboxData")
-- local InboxFriendRunData = util_require("data.inboxData.InboxFriendRunData")
-- local InboxCollectRunData = util_require("data.inboxData.InboxCollectRunData")
local InboxFriendNetwork = util_require("GameModule.Inbox.net.InboxFriendNetwork")
local InboxCollectNetwork = util_require("GameModule.Inbox.net.InboxCollectNetwork")

local InboxManager = class("InboxManager", BaseGameControl)
InboxManager.m_instance = nil

InboxManager.m_showInboxTimes = nil

InboxManager.m_collectCoin = nil
InboxManager.m_collectGems = nil
InboxManager.m_readTime = nil

-- InboxManager.m_lastRequestSDKTime = nil
InboxManager.m_isClickRewardVideo = false

InboxManager.m_updateTime = 300


-- 构造函数
function InboxManager:ctor()
    InboxManager.super.ctor(self)

    self:setRefName(G_REF.Inbox)

    -- self.m_parseData = ParseInboxData:create()
    -- self.m_sysRunData = InboxCollectRunData:create()
    self.m_sysNetwork = InboxCollectNetwork:create()
    -- self.m_friendRunData = InboxFriendRunData:create()
    self.m_friendNetwork = InboxFriendNetwork:create()

    -- self.m_lastRequestSDKTime = 0

    self:registerObserveEvent()
end

-- function InboxManager:getInstance()
--     if InboxManager.m_instance == nil then
--         InboxManager.m_instance = InboxManager.new()
--     end
--     return InboxManager.m_instance
-- end

function InboxManager:registerObserveEvent()
    -- 刷新本地邮件
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- self:getSysRunData():updataLocalMail()
            -- self:getSysRunData():addLocalMail()
            local collectData = self:getSysRunData()
            if collectData then
                collectData:refreshLocalMail()
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
        end,
        ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL
    )
end

function InboxManager:parseCollectData(_netData)
    if not _netData then
        return
    end
    local data = self:getData()
    if not data then
        data = require("GameModule.Inbox.model.InboxData"):create()
        data:parseCollectData(_netData)
        self:registerData(data)
    else
        data:parseCollectData(_netData)
    end
end

function InboxManager:parseFriendData(_netData)
    if not _netData then
        return
    end
    local data = self:getData()
    if not data then
        data = require("GameModule.Inbox.model.InboxData"):create()
        data:parseFriendData(_netData)
        self:registerData(data)
    else
        data:parseFriendData(_netData)
    end
end

--------------------特殊逻辑处理-------------------------------
function InboxManager:getNewAppVer()
    -- local filePath = device.writablePath .. "/Version.json"
    -- local content = globalData.GameConfig.versionData or {}
    local content = globalData.GameConfig:getVerInfo()
    if not content then
        return "1.0.0"
    end
    -- 最新app version
    local newAppVer = content.new_app_version or "1.0.0"
    -- if device.platform == "ios" then
    --     newAppVer = content["ios"]["new_app_version"] -- 最新app version
    -- elseif device.platform == "android" then
    --     newAppVer = content["new_app_version"] -- 最新app version
    --     if MARKETSEL == AMAZON_MARKET then
    --         newAppVer = content["amazon"]["new_app_version"] -- 最新app version
    --     end
    -- end

    return newAppVer
end

-- 数据埋点
function InboxManager:setSourceData(data)
    self.m_sourceData = data
end

function InboxManager:sendFireBaseClickLog()
    if globalFireBaseManager.sendFireBaseLogDirect then
        if self.m_sourceData then
            globalFireBaseManager:sendFireBaseLogDirect(self.m_sourceData)
        else
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.InboxMailClick)
        end
    end
end

function InboxManager:initReadTime()
    self.m_readTime = os.time()
end

function InboxManager:getReadTime()
    return self.m_readTime
end
---------------------------------------------------

-- function InboxManager:getParseData()
--     return self.m_parseData
-- end

function InboxManager:getSysRunData()
    -- return self.m_sysRunData
    local data = self:getData()
    if data then
        return data:getCollectData()
    end
    return 
end

function InboxManager:getSysNetwork()
    return self.m_sysNetwork
end

function InboxManager:getFriendRunData()
    -- return self.m_friendRunData
    local data = self:getData()
    if data then
        return data:getFriendData()
    end
    return 
end

function InboxManager:getFriendNetwork()
    return self.m_friendNetwork
end

function InboxManager:setShowInboxTimes(count)
    self.m_showInboxTimes = count
end

function InboxManager:getShowInboxTimes()
    return self.m_showInboxTimes or 0
end

function InboxManager:addShowInboxTimes()
    self.m_showInboxTimes = (self.m_showInboxTimes or 0) + 1
end

function InboxManager:setInboxCollectStatus(_status)
    self.m_collectStatus = _status
end

function InboxManager:getInboxCollectStatus()
    return self.m_collectStatus
end

function InboxManager:getLobbyBottomNum()
    return self:getMailCount()
end

-- 获取礼物数量
function InboxManager:getMailCount()
    -- return self.m_sysRunData:getMailCount() + self.m_friendRunData:getMailCount()
    local count = 0
    local collectData = self:getSysRunData()
    if collectData then
        count = count + collectData:getMailCount()
    end
    local friendData = self:getFriendRunData()
    if friendData then
        count = count + friendData:getMailCount()
    end
    return count
end

-- 获取inbox中所有礼物的消息
-- _isFB: 是否请求FB好友邮件数据
function InboxManager:getDataMessage(_successCallFun, _failedCallFun, _isFB)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    self:initReadTime()

    local refreshTimes = 1
    if _isFB then
        refreshTimes = refreshTimes + 1
    end

    local function callback()
        refreshTimes = refreshTimes - 1
        if refreshTimes == 0 then
            -- 刷新红点数据
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, self:getMailCount())
            if _successCallFun then
                _successCallFun()
            end
        end
    end

    -- 请求系统邮件列表
    self.m_sysNetwork:requestMailList(
        callback,
        function()
            if _failedCallFun then
                _failedCallFun()
            end
        end
    )

    -- 请求好友邮件列表
    if _isFB then
        self.m_friendNetwork:requestMailList(callback)
    end
    --300秒更新一次邮箱状态
    self:updateInboxData()
end

function InboxManager:setWatchRewardVideoFalg(state)
    self.m_isClickRewardVideo = state
end

function InboxManager:getWatchRewardVideoFalg()
    return self.m_isClickRewardVideo
end

------------------------------------------------------------------------------
-- -- 向SDK发送请求 时间限制
-- function InboxManager:setRequestSDKTime()
--     self.m_lastRequestSDKTime = globalData.userRunData.p_serverTime
-- end

-- function InboxManager:getRequestSDKTime()
--     return self.m_lastRequestSDKTime
-- end

-- function InboxManager:canRequestSDK()
--     -- if self.m_lastRequestSDKTime and self.m_lastRequestSDKTime > 0 then
--     --     if math.floor(globalData.userRunData.p_serverTime - self.m_lastRequestSDKTime) <= 300000 then
--     --         return false
--     --     end
--     -- end
--     return true
-- end

-- function InboxManager:GetFacebookFriendList()
--     if self.m_friendRunData:isLoginFB() then
--         if self:canRequestSDK() then
--             self:setRequestSDKTime()
--             self:SDK_GetFacebookFriendList()
--         end
--     end
-- end

-- -- 向FACEBOOK SDK请求，拉取好友列表
-- function InboxManager:SDK_GetFacebookFriendList()
--     local function callback(data)
--         local jsonData = util_cjsonDecode(data)
--         if jsonData and jsonData.friendList ~= nil and jsonData.friendList.data ~= nil then
--             if jsonData.flag then
--                 self.m_friendRunData:setFaceBookFriendList(jsonData.friendList.data)
--             end
--             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_FACEBOOK_FRIEND_LIST, {flag = jsonData.flag})
--         end
--     end
--     globalFaceBookManager:getFaceBookFriendList(callback)
-- end
------------------------------------------------------------------------------
function InboxManager:showInboxLayer(_params)
    if gLobalViewManager:getViewByName("Inbox") ~= nil then
        return
    end
    gLobalViewManager:addLoadingAnimaDelay()
    self:getDataMessage(
        function()
            gLobalViewManager:removeLoadingAnima()
            -- 打开邮箱
            local view = util_createView("views.inbox.Inbox", _params)
            view:setName("Inbox")
            if _params and _params.rootStartPos then
                view:setRootStartPos(_params.rootStartPos)
            end
            if _params and _params.senderName and _params.dotUrlType and _params.dotEntrySite and _params.dotEntryType then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, _params.senderName, _params.dotUrlType, true, _params.dotEntrySite, _params.dotEntryType)
            end
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end,
        function()
            gLobalViewManager:removeLoadingAnima()
        end,
        true
    )
end

function InboxManager:updateInboxData()
    if self.m_schduleID then
        scheduler.unscheduleGlobal(self.m_schduleID)
        self.m_schduleID = nil
    end
    self.m_schduleID =
        scheduler.scheduleGlobal(
        function()
            self:getDataMessage(nil, nil, true)
        end,
        300
    )
end

return InboxManager
