-- 聊天管理器
local ClanManager = require("manager.System.ClanManager")
local ClanConfig = require("data.clanData.ClanConfig")
local ChatConfig = require("data.clanData.ChatConfig")
local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
local ChatData = require("data.clanData.ChatData")
local ChatSyncManager = require("manager.System.ChatSyncManager")
local ChatManager = class("ChatManager")

ChatManager.m_heartbeatID = nil --心跳ID
ChatManager.m_heartWaiting = nil --心跳等待

function ChatManager:onOpen()
    if not ClanManager:getInstance():checkSupportAppVersion() then
        return
    end
    if self.hasSendSid == true then
        return
    end

    if not TcpNetConfig.SERVER_LIST[TcpNetConfig.SERVER_KEY.CLAN_CHAT].host then
        ClanManager:getInstance():requestChatServerInfo()
        return
    end

    ChatSyncManager:getInstance():onOpen(
        function()
            if not self.hasSendSid == true and not self:getChatSid() then
                self.hasSendSid = true
                self:requestAuthInfo()
                return
            end
        end
    )
end

function ChatManager:onClose()
    ChatSyncManager:getInstance():onClose()
    self:stopHeartBeat()

    -- local chatData = self:getChatData()
    -- chatData:clear()

    -- self.m_latestChatId = "0" -- 聊天信息的最近一条数据id 初始时默认"0"
    -- self.m_latestChipId = "0" -- 卡牌请求的最近一条数据id 初始时默认"0"
    -- self.m_latestGiftId = "0" -- 礼物领取的最近一条数据id 初始时默认"0"
    -- self.m_latestTextId = "0" -- 普通聊天的最近一条数据id 初始时默认"0"
    -- self.m_latestRedGiftId = "0" -- 红包消息的最近一条数据id 初始时默认"0"
    -- self.cardData = {} -- 玩家索要卡对应的数据
    self.m_sid = nil -- sid 拉取聊天信息的凭证
    self.hasSendSid = false
    self.m_requestAuthInfoIng = false

    TcpNetConfig.SERVER_LIST[TcpNetConfig.SERVER_KEY.CLAN_CHAT] = {}
end

function ChatManager:resetChatList()
    local chatData = self:getChatData()
    chatData:clear()

    self.m_latestChatId = "0" -- 聊天信息的最近一条数据id 初始时默认"0"
    self.m_latestChipId = "0" -- 卡牌请求的最近一条数据id 初始时默认"0"
    self.m_latestGiftId = "0" -- 礼物领取的最近一条数据id 初始时默认"0"
    self.m_latestTextId = "0" -- 普通聊天的最近一条数据id 初始时默认"0"
    self.m_latestRedGiftId = "0" -- 红包消息的最近一条数据id 初始时默认"0"
    self.cardData = {} -- 玩家索要卡对应的数据
end

-----------------------------------  消息发送和接收  -----------------------------------
-- 发送校验消息
function ChatManager:requestAuthInfo()
    self.m_requestAuthInfoIng = true
    ChatSyncManager:getInstance():requestAuthInfo()
end

-- 解析连接消息 获取公会聊天的sid
function ChatManager:parseAuthData(data)
    if data and data.sid then
        self.m_sid = data.sid
        self:requestChatSync()

        self:startHeartBeat()
    else
        printError("ChatManager:parseAuthData 获取数据异常 将不能建立聊天连接")
    end
    self.m_requestAuthInfoIng = false
end

-- 同步聊天记录
function ChatManager:requestChatSync()
    ChatSyncManager:getInstance():requestChatSync()
end

-- 解析聊天数据
-- message SyncReceive {
--     required ResponseCode code = 1 [default = SUCCEED];
--     optional string desc = 2;
--     repeated MessageInfo all = 3;//ALL消息
--     repeated MessageInfo chips = 4;//Chips消息
--     repeated MessageInfo gift = 5;//Gift消息
-- }
function ChatManager:parseChatData(data)
    if data then
        if data.all and #data.all > 0 then
            self:parseCommonData(data.all) -- 常规聊天列表
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_SYNC_REFRESH, ChatConfig.NOTICE_TYPE.COMMON)
        end

        if data.chips and #data.chips > 0 then
            self:parseChipsData(data.chips) -- 卡牌请求列表
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_SYNC_REFRESH, ChatConfig.NOTICE_TYPE.CHIPS)
        end

        if data.gift and #data.gift > 0 then
            self:parseGiftData(data.gift) -- 礼物领取列表
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_SYNC_REFRESH, ChatConfig.NOTICE_TYPE.GIFT)
        end

        if data.chat and #data.chat > 0 then
            self:parseTextData(data.chat) -- 普通聊天列表
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_SYNC_REFRESH, ChatConfig.NOTICE_TYPE.CHAT)
        end

        if data.redPackage and #data.redPackage > 0 then
            self:parseRedGiftData(data.redPackage) -- 红包 消息数据
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_SYNC_REFRESH, ChatConfig.NOTICE_TYPE.CHAT)
        end
    else
        print("本次同步 没有常规的聊天信息")
    end
end

-- 接收新消息
function ChatManager:parseNoticeData(data)
    if not data or not data.msg then
        return
    end

    -- 更新常规聊天列表
    local latestMessage = self:parseCommonMessage(data.msg, true)
    if latestMessage.messageType == ChatConfig.MESSAGE_TYPE.TEXT then
        self:parseTextMessage(data.msg, true)
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH, ChatConfig.NOTICE_TYPE.CHAT)
    end
    -- 如果需要 更新卡牌请求列表
    if latestMessage.messageType == ChatConfig.MESSAGE_TYPE.CLAN_MEMBER_CARD then
        self:parseChipsMessage(data.msg, true)
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH, ChatConfig.NOTICE_TYPE.CHIPS)
    end

    -- 如果需要 更新礼物领取列表
    if
        latestMessage.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT or latestMessage.messageType == ChatConfig.MESSAGE_TYPE.CARD_CLAN or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.CASHBONUS_JACKPOT or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.PURCHASE or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.LOTTERY or 
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.RANK_REWARD or 
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.RUSH_REWARD or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT_SHARE or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.AVATAR_FRAME or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE or 
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT or
            latestMessage.messageType == ChatConfig.MESSAGE_TYPE.CLAN_DUEL
     then
        self:parseGiftMessage(data.msg, true)
        if latestMessage.messageType ~= ChatConfig.MESSAGE_TYPE.RED_PACKAGE and latestMessage.messageType ~= ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT then
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH, ChatConfig.NOTICE_TYPE.GIFT)
        end
    end

    if latestMessage.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE or latestMessage.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT then
        self:parseRedGiftMessage(data.msg, true)
    else
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH, ChatConfig.NOTICE_TYPE.COMMON)
    end
end

-- 发送消息
function ChatManager:sendChat(content, type)
    if not self:getChatSid() then
        print("------------------断线中没有sid")
        release_print("------------------断线中没有sid")
        self:onClose()
    else
        ChatSyncManager:getInstance():sendChat(content, type)
    end
end

-- 发送消息的回调
function ChatManager:onMessageSendOver(data)
    -- 具体的消息内容会在消息同步接口里更新 这里只是告诉客户端 消息发送成功了
end

-- 发送消息失败
function ChatManager:onMessageSendFaild(data)
    -- 可能需要一些额外操作 对当前编辑的消息加红点？类似微信那样？
end

--开启心跳
function ChatManager:startHeartBeat()
    local HEART_TIME = 10
    self:stopHeartBeat()
    local scheduler = cc.Director:getInstance():getScheduler()
    self.m_heartbeatID =
        scheduler:scheduleScriptFunc(
        function()
            self:heartBeat()
        end,
        HEART_TIME,
        false
    )
end

--停止心跳检测
function ChatManager:stopHeartBeat()
    self.m_heartWaiting = nil
    if self.m_heartbeatID then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self.m_heartbeatID)
        self.m_heartbeatID = nil
    end
end

--发送心跳
function ChatManager:heartBeat()
    if self.m_heartWaiting or not self:getChatSid() then
        self:onHeratBeatSendError()
        return
    end
    self.m_heartWaiting = true
    ChatSyncManager:getInstance():heartBeat()
end

-- 心跳回调
function ChatManager:onHeratBeatSendOver(data)
    self.m_heartWaiting = nil
end

-- 心跳出现问题
function ChatManager:onHeratBeatSendError()
    self:stopHeartBeat()
    ChatSyncManager:getInstance():reConnect()
end

-- 领取礼物同步服务器
-- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
function ChatManager:sendCollect(msgId, coins)
    ChatSyncManager:getInstance():sendCollect(msgId, coins)
end
-- 领取礼物同步服务器
-- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
function ChatManager:sendFastCollectAll(msgIdList, coinsList)
    if not next(msgIdList) or not next(msgIdList) then
        return
    end
    ChatSyncManager:getInstance():sendFastCollectAll(msgIdList, coinsList)
end
-- 领取奖励同步回调
function ChatManager:onCollectSyncOver(data)
    -- 显示奖励？
end

function ChatManager:getCardDatas(cardList)
    ClanManager:getInstance():requestCardsData(cardList)
end

-----------------------------------  消息解析拆分  -----------------------------------
-- 常规聊天信息列表
function ChatManager:parseCommonData(data)
    if data then
        local count = #data

        -- 断线重现接收到的消息 一个一个的有序添加
        if self.chatData and #(self.chatData:getCommonChatList()) > 0 then
            for i = 1, count do
                local chatData = data[i]
                self:parseCommonMessage(chatData, true)
            end
            return
        end

        for i = 0, ChatConfig.MESSAGE_LIMIT_ENUM.ALL do
            local chatData = data[count - i]
            if not chatData then
                break
            end
            self:parseCommonMessage(chatData, i == 0)
        end
    end
end

function ChatManager:parseCommonMessage(commonData, bAddNewMsg)
    if self.chatData and commonData then
        local latestMessage = self.chatData:parseCommonData(commonData, bAddNewMsg)
        -- 刷新最后一条聊天记录的id
        if bAddNewMsg then
            self:setLatestChatId(latestMessage.msgId)
        end
        return latestMessage
    end
end

-- 卡牌请求列表
function ChatManager:parseChipsData(data)
    if data then
        local count = #data

        -- 断线重现接收到的消息 一个一个的有序添加
        if self.chatData and #(self.chatData:getChipsChatList()) > 0 then
            for i = 1, count do
                local chatData = data[i]
                self:parseChipsMessage(chatData, true)
            end
            return
        end

        for i = 0, ChatConfig.MESSAGE_LIMIT_ENUM.CHIPS do
            local chatData = data[count - i]
            if not chatData then
                break
            end
            self:parseChipsMessage(chatData)
        end
    end
end

function ChatManager:parseChipsMessage(chipData, bAddNewMsg)
    if self.chatData and chipData then
        local latestMessage = self.chatData:parseChipsData(chipData, bAddNewMsg)
        -- 刷新最后一条聊天记录的id
        self:setLatestChipId(latestMessage.msgId)
    end
end

-- 礼物领取列表
function ChatManager:parseGiftData(data)
    if data then
        local count = #data

        -- 断线重现接收到的消息 一个一个的有序添加
        if self.chatData and #(self.chatData:getGiftChatList()) > 0 then
            for i = 1, count do
                local chatData = data[i]
                self:parseGiftMessage(chatData, true)
            end
            return
        end

        for i = 0, ChatConfig.MESSAGE_LIMIT_ENUM.GIFT do
            local chatData = data[count - i]
            if not chatData then
                break
            end
            self:parseGiftMessage(chatData)
        end
    end
end

function ChatManager:parseGiftMessage(giftData, bAddNewMsg)
    if self.chatData and giftData then
        local latestMessage = self.chatData:parseGiftData(giftData, bAddNewMsg)
        -- 刷新最后一条聊天记录的id
        self:setLatestGiftId(latestMessage.msgId)
    end
end

-- 普通聊天列表
function ChatManager:parseTextData(data)
    if data then
        local count = #data

        -- 断线重现接收到的消息 一个一个的有序添加
        if self.chatData and #(self.chatData:getTextChatList()) > 0 then
            for i = 1, count do
                local chatData = data[i]
                self:parseTextMessage(chatData, true)
            end
            return
        end

        for i = 0, ChatConfig.MESSAGE_LIMIT_ENUM.CHAT do
            local chatData = data[count - i]
            if not chatData then
                break
            end
            self:parseTextMessage(chatData)
        end
    end
end

function ChatManager:parseTextMessage(textData, bAddNewMsg)
    if self.chatData and textData then
        local latestMessage = self.chatData:parseTextData(textData, bAddNewMsg)
        -- 刷新最后一条聊天记录的id
        if latestMessage then
            self:setLatestTextId(latestMessage.msgId)
        end
    end
end

-- 解析红包数据
function ChatManager:parseRedGiftData(data)
    if data then
        local count = #data

        -- 断线重现接收到的消息 一个一个的有序添加
        if self.chatData and #(self.chatData:getRedGiftList()) > 0 then
            for i = 1, count do
                local chatData = data[i]
                self:parseRedGiftMessage(chatData, true)
            end
            return
        end

        for i = 0, ChatConfig.MESSAGE_LIMIT_ENUM.RED do
            local chatData = data[count - i]
            if not chatData then
                break
            end
            self:parseRedGiftMessage(chatData)
        end
    end
end
function ChatManager:parseRedGiftMessage(textData, bAddNewMsg)
    if self.chatData and textData then
        local latestMessage = self.chatData:parseRedGiftData(textData, bAddNewMsg)
        -- 刷新最后一条聊天记录的id
        if latestMessage then
            self:setLatestRedGiftId(latestMessage.msgId)
        end
    end
end

-----------------------------------  get/set  -----------------------------------
-- 上一次拉取聊天信息的id
function ChatManager:getLatestChatId()
    return self.m_latestChatId
end
-- 最后一条聊天的id
function ChatManager:setLatestChatId(chatId)
    if chatId then
        self.m_latestChatId = chatId
    end
end

-- 卡牌请求的最近一条数据id
function ChatManager:getLatestChipId()
    return self.m_latestChipId
end
-- 卡牌请求的最近一条数据id
function ChatManager:setLatestChipId(chatId)
    if chatId then
        self.m_latestChipId = chatId
    end
end

-- 礼物领取的最近一条数据id
function ChatManager:getLatestGiftId()
    return self.m_latestGiftId
end
-- 礼物领取的最近一条数据id
function ChatManager:setLatestGiftId(chatId)
    if chatId then
        self.m_latestGiftId = chatId
    end
end

-- 普通聊天的最近一条数据id
function ChatManager:getLatestTextId()
    return self.m_latestTextId
end
-- 普通聊天的最近一条数据id
function ChatManager:setLatestTextId(chatId)
    if chatId then
        self.m_latestTextId = chatId
    end
end

-- 公会红包聊天的最近一条数据id
function ChatManager:getLatestRedGiftId()
    return self.m_latestRedGiftId
end
function ChatManager:setLatestRedGiftId(chatId)
    if chatId then
        self.m_latestRedGiftId = chatId
    end
end

-- 聊天相关信息请求的凭证
function ChatManager:getChatSid()
    return self.m_sid
end

function ChatManager:setChatSid(sid)
    self.m_requestAuthInfoIng = false
    self.m_sid = sid
    if sid == nil then
        self.hasSendSid = false
    end
end

-- 公会id
function ChatManager:getClanId()
    local simpleInfo = ClanManager:getInstance():getClanSimpleInfo()
    if simpleInfo and simpleInfo.getTeamCid then
        return simpleInfo:getTeamCid()
    end

    return ""
end

function ChatManager:getChatData()
    return self.chatData
end

function ChatManager:getCardDataById(cardId)
    if cardId then
        for idx, cardData in pairs(self.cardData) do
            if cardId == cardData.cardId then
                return self.cardData[idx]
            end
        end
    end
end

-- 更改卡的信息
function ChatManager:changeCardDataInfo(singleCardData)
    if type(self.cardData) == "table" and type(singleCardData) == "table" then
        local cardId = singleCardData.cardId
        if not cardId then
            return
        end
        for idx, cardData in pairs(self.cardData) do
            if cardId == cardData.cardId then
                self.cardData[idx].count = singleCardData.count
                break
            end
        end
    end
end

function ChatManager:clearCardCache()
    self.cardData = {}
end

-----------------------------------  初始化  -----------------------------------
function ChatManager:getInstance()
    if not self._instance then
        self._instance = ChatManager.new()
        self._instance:init()
    end
    return self._instance
end

-- 一些变量的初始化
function ChatManager:init()
    self.m_sid = nil -- sid 拉取聊天信息的凭证
    self.m_latestChatId = "0" -- 聊天信息的最近一条数据id 初始时默认"0"
    self.m_latestChipId = "0" -- 卡牌请求的最近一条数据id 初始时默认"0"
    self.m_latestGiftId = "0" -- 礼物领取的最近一条数据id 初始时默认"0"
    self.m_latestTextId = "0" -- 普通聊天的最近一条数据id 初始时默认"0"
    self.m_latestRedGiftId = "0" -- 红包消息的最近一条数据id 初始时默认"0"
    self.cardData = {} -- 玩家索要卡对应的数据
    self.chatData = ChatData.new()
    self.hasSendSid = false

    self.curMsgId = gLobalDataManager:getStringByField("clan_chatIdRecord", nil)
    -- 公会 卡牌信息更改
    gLobalNoticManager:addObserver(
        self,
        function(self, cardData)
            self:changeCardDataInfo(cardData)
        end,
        ChatConfig.EVENT_NAME.NOTIFY_CARD_DATA_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:onClose()
        end,
        ClanConfig.EVENT_NAME.RECIEVE_USER_LEAVE_CLAN
    ) -- 玩家 退出公会
    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:onClose()
        end,
        ClanConfig.EVENT_NAME.KICKED_OFF_TEAM
    ) -- 你被会长踢了

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:refreshMsgByData(data)
        end,
        ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:refreshMsgByData(data)
        end,
        ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:refreshRedGiftMsgData(data)
        end,
        ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, cardData)
            if cardData and table.nums(cardData) > 0 then
                self.cardData = cardData
            end
        end,
        ChatConfig.EVENT_NAME.NOTIFY_CARD_DATA_READY
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, cardData)
            self:onClose()
        end,
        ViewEventType.NOTIFY_RESTART_GAME_CLEAR
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, name)
            if not name then
                name = TcpNetConfig.SERVER_KEY.CLAN_CHAT
            end
            if name == ChatSyncManager:getInstance():getTcpName() then
                self:onClose()
            end
        end,
        ViewEventType.NOTIFY_ClOSE_CLEAR_TCP
    )

    gLobalNoticManager:addObserver(
        self,
        function(self)
            self:onOpen()
        end,
        ChatConfig.EVENT_NAME.RECIEVE_CHAT_SERVER_INFO_SUCCESS
    ) -- 获取到聊天服务器配置信息
end

function ChatManager:clearMsgList()
    self.curMsgId = self.m_latestChatId
    local chatData = self:getChatData()
    local chatList = chatData:getCommonChatList()
    local lastMsg = chatList[#chatList]
    if lastMsg then
        self.curMsgId = lastMsg.msgId
        self.m_latestChatId = lastMsg.msgId
    end
    gLobalDataManager:setStringByField("clan_chatIdRecord", self.curMsgId)
end

function ChatManager:getUnreadMessageCounts()
    local chatData = self:getChatData()
    local chatList = chatData:getCommonChatList()
    local total_counts = table.nums(chatList)
    if self.curMsgId then
        for idx, msg in ipairs(chatList) do
            if msg.msgId == self.curMsgId then
                total_counts = total_counts - idx
                break
            end
        end
    end

    -- 未领取的红包数量
    if total_counts == 0 then
        local unColRedGiftCount = chatData:getUnCollectRedGiftCount()
        total_counts = total_counts + unColRedGiftCount
    end

    return total_counts
end

--获取链接状态
function ChatManager:getSocketState()
    local socketState = ChatSyncManager:getInstance():getSocketState()
    if not socketState then
        return ChatConfig.TCP_STATE.CLOSED
    end

    if not self.m_heartbeatID and not self.m_requestAuthInfoIng then
        -- 没心跳也没有请求 聊天sid
        ChatSyncManager:getInstance():onClose() -- socket链接上的client断开
        return ChatConfig.TCP_STATE.CLOSED
    end

    if socketState == TcpNetConfig.XCTCP_STATUS.CLOSED then
        -- 重连中
        self:reConnectSplunkLog(3, 1)
        return ChatConfig.TCP_STATE.RE_CONNECTING
    end

    -- socket连上了 没有sid 也没有同步 sid
    local sid = self:getChatSid()
    if not sid and not self.m_requestAuthInfoIng then
        self:requestAuthInfo()
        -- 重连中
        self:reConnectSplunkLog(3, 2)
        return ChatConfig.TCP_STATE.RE_CONNECTING
    end

    -- 中途sid验证不通过了 验证中也显示重连
    if self.m_requestAuthInfoIng then
        self:reConnectSplunkLog(3, 3)
        return ChatConfig.TCP_STATE.RE_CONNECTING
    end

    -- 在线中
    return ChatConfig.TCP_STATE.CONNECTING
end
function ChatManager:reConnectSplunkLog(_logType, _extra)
    -- if globalData.userRunData.userUdid ~= "C511419D-3345-467A-A851-A91A49183F9B:SlotNewCashLink" then
    if globalData.userRunData.userUdid ~= "b1664957-b015-3c4c-ae3b-1abc0f38b604:SlotNewCashLink" and 
        globalData.userRunData.userUdid ~= "c3a16761-0056-3723-8ab1-3b78efc83c3d:SlotNewCashLink" and
        globalData.userRunData.userUdid ~= "9B34B204-9DE7-406A-A857-D97416774046:SlotNewCashLink" then
        return
    end
  
    if _logType == self.m_tempLogType and _extra == self.m_tempExtra then
        return
    end

    self.m_tempLogType = _logType
    self.m_tempExtra = _extra

    local str = ""
    if _logType == 1 then
        str = "client_socket_test_玩家重连上了"
    elseif _logType == 2 then
        str = "client_socket_test_玩家重连没连上了"
    elseif _logType == 3 then
        str = string.format("client_socket_test_玩家重连中, 心跳存在否:%s, 是否请求sid验证:%s, extraCode:%s", self.m_heartbeatID~=nil, self.m_requestAuthInfoIng, _extra)
    elseif _logType == 4 then
        str = string.format("client_socket_test_玩家连接上了，消息%s成功", _extra)
    elseif _logType == 5 then
        str = string.format("client_socket_test_玩家连接onFaild:%s", _extra)
    end
    print("cxc-----", str)
    util_sendToSplunkMsg("SocketReConnectLog", str)
end


-- 记录聊天tag页签
function ChatManager:recordCurChatTag(_tag)
    self.m_tag = _tag
end
function ChatManager:getCurChatTag()
    return self.m_tag or ChatConfig.NOTICE_TYPE.COMMON
end

-- 获取快速领取奖励 列表
function ChatManager:getFastCollectGiftMsgIdAndSign()
    if not self.chatData then
        return {}, {}
    end

    local msgIdList = {}
    local randomSignList = {}
    local msgIdMap = self.chatData:getCanCollectGiftMsgIdMap()
    for msgId, _ in pairs(msgIdMap) do
        local data = self.chatData:getGiftMessageById(msgId)
        if data and data.status == 0 and data.effecTime and data.extra and data.extra.randomSign then
            local leftTime = util_getLeftTime(data.effecTime)
            if leftTime > 0 then
                table.insert(msgIdList, msgId)
                table.insert(randomSignList, data.extra.randomSign)
            else
                msgIdMap[msgId] = nil
            end
        else
            msgIdMap[msgId] = nil
        end
    end

    return msgIdList, randomSignList
end

-- 客户端刷新消息
function ChatManager:refreshMsgByData(data)
    if data and data.result and data.result.msgId then
        local chatData = self:getChatData()
        local messageList = chatData:getMessageById(data.result.msgId)
        if next(messageList) then
            for idx, msgData in pairs(messageList) do
                local messageBody = messageList[idx]
                messageBody:refreshMsgByData({status = 1, coins = data.coins}) -- 把对应消息的状态刷新为已领取
            end
        end

        if not data.coins or tonumber(data.coins) == 0 then
            util_sendToSplunkMsg("TeamChatCollectReward", string.format("msg:%s coins is 0", data.result.msgId))
        end
    end
end
function ChatManager:refreshRedGiftMsgData(data)
    if data and data.coins and data.dollars and data.msgId then
        local chatData = self:getChatData()
        local messageList = chatData:getMessageById(data.msgId)
        for idx, msgData in pairs(messageList) do
            local messageBody = messageList[idx]

            messageBody.status = 1
            messageBody.coins = tonumber(data.coins) or 0

            if messageBody.content and #messageBody.content > #"{}" then
                local jsonObj = cjson.decode(messageBody.content)
                local sourceDollars = jsonObj.collectDollars or 0
                if tonumber(sourceDollars) == 0 and data.dollars  then
                    jsonObj.collectDollars = data.dollars
                    local newContent = cjson.encode(jsonObj)
                    messageBody.content = newContent
                end
            end
           
        end
        
    end
end

-- 是否需要弹出公会对决胜利 or 失败弹板
function ChatManager:isPopClanDuelResultLayer()
    if self.chatData and #(self.chatData:getGiftChatList()) > 0 then
        return self.chatData:isPopClanDuelResultLayer()
    end
    return false, false
end

return ChatManager