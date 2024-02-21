-- 处理网络请求
local BaseInboxNetwork = util_require("GameModule.Inbox.net.BaseInboxNetwork")
local InboxFriendNetwork = class("InboxFriendNetwork", BaseInboxNetwork)
function InboxFriendNetwork:ctor()
    BaseInboxNetwork.ctor(self)

    -- self.m_lastSendTime = {}
    -- self.m_lastSendTime.FriendInfo = 0
end

-- FB好友页签 收集邮件 一键领取 FriendCollectGiftMail
-- extra: "{"mailId":2,"type":"COLLECT_BACK"}"
-- type: COLLECT, COLLECT_BACK, COLLECT_ALL
function InboxFriendNetwork:collectMail(extraData, successFunc, failFunc)
    local success = function(resData)
        local result = nil
        if resData:HasField("result") == true then
            result = cjson.decode(resData.result)
        end
        -- local netData = G_GetMgr(G_REF.Inbox):getParseData():parseFBMailData(result)
        G_GetMgr(G_REF.Inbox):parseFriendData(result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
        if successFunc then
            successFunc()
        end
    end
    local fail = function()
        if failFunc then
            failFunc()
        end
    end
    gLobalSendDataManager:getNetWorkFeature():FBInbox_collectFBMail(extraData, success, fail)
end

-- FB好友页签 请求邮件列表 FriendGiftMails
function InboxFriendNetwork:requestMailList(successFunc, failFunc)
    local success = function(result)
        -- local netData = G_GetMgr(G_REF.Inbox):getParseData():parseFBMailData(result)
        G_GetMgr(G_REF.Inbox):parseFriendData(result)
        if successFunc then
            successFunc()
        end
    end
    local fail = function()
        if failFunc then
            failFunc()
        end
    end
    gLobalSendDataManager:getNetWorkFeature():FBInbox_requestFBMailList(success, fail)
end

-- FB发送页签 发送邮件 FriendSendGiftMail
-- extra: {"mailType":"COIN","facebookIds":["fan2"]}
-- extra: {"mailType":"CARD","facebookIds":["fan2"], "cards":{"190812":1,"190813":1,}}
function InboxFriendNetwork:FBInbox_sendFBMail(extraData, _successFunc, _failFunc)
    local success = function(result)
        -- G_GetMgr(G_REF.Inbox):getFriendRunData():addSendRecordList(extraData.mailType, extraData.facebookIds)
        G_GetMgr(G_REF.Inbox):getFriendRunData():addSendRecordList(extraData.mailType, extraData.friendUdid)
        -- local data = G_GetMgr(G_REF.Inbox):getParseData():parseFBCardData(result)
        G_GetMgr(G_REF.Inbox):getFriendRunData():initFBCardData(result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_SEND_SUCCESS)
        if _successFunc then
            _successFunc()
        end
    end
    local fail = function()
        if _failFunc then
            _failFunc()
        end
    end
    G_GetMgr(G_REF.Friend):requestSendCard(nil, nil, extraData.mailType, extraData.friendUdid, extraData.cards, success, fail)
    -- if CC_INBOX_FB_TEST then
    --     success()
    -- else
    --     gLobalSendDataManager:getNetWorkFeature():FBInbox_sendFBMail(extraData, success, fail)
    -- end
    -- local actionData = self:getSendActionData(ActionType.UserFriendSendCardMail)
    -- actionData.data.extra = cjson.encode(extraData)
    -- self:sendActionMessage(ActionType.UserFriendSendCardMail, tbData, successFunc, failedFunc)
end

-- FB发送页签 请求集卡数据 FriendGiftCards
function InboxFriendNetwork:FBInbox_requestFBCardList(successFunc, failFunc)
    local success = function(result)
        -- local data = G_GetMgr(G_REF.Inbox):getParseData():parseFBCardData(result)
        local isOk = G_GetMgr(G_REF.Inbox):getFriendRunData():initFBCardData(result)
        if isOk then
            gLobalViewManager:removeLoadingAnima()
            if successFunc then
                successFunc()
            end
        else
            gLobalViewManager:addLoadingAnima()
            local tExtraInfo = {["year"] = CardSysRuntimeMgr:getCurrentYear(), ["albumId"] = CardSysRuntimeMgr:getCurAlbumID()}
            CardSysNetWorkMgr:sendCardsAlbumRequest(
                tExtraInfo,
                function()
                    -- 移除消息等待面板 --
                    gLobalViewManager:removeLoadingAnima()
                    G_GetMgr(G_REF.Inbox):getFriendRunData():updateFBCardData(data)
                    if successFunc then
                        successFunc()
                    end
                end,
                function()
                    -- 移除消息等待面板 --
                    gLobalViewManager:removeLoadingAnima()
                    if failFunc then
                        failFunc()
                    end
                end
            )
        end
    end
    local fail = function()
        if failFunc then
            failFunc()
        end
    end
    gLobalSendDataManager:getNetWorkFeature():FBInbox_requestFBCardList(success, fail)
end

return InboxFriendNetwork
