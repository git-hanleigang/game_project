
-- 聊天信息解析

require "protobuf.ChatProto_pb"
require "protobuf.ChatBaseProto_pb"

local ChatConfig = require("data.clanData.ChatConfig")
local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
-- local TcpNetManager = require("network.socket_tcp.TcpNetManager")
local TcpNewManager = require("network.socket_tcp.TcpNewManager")
local ChatSyncManager = class("manager.System.ChatSyncManager")

local isNewTcp = true --C++版本消息通讯

function ChatSyncManager:getTcpName()
    return self.m_tcpName
end

-- 发送请求 获取sid(获取同步消息所必须的key)
function ChatSyncManager:requestAuthInfo()
    if not self:checkRequestEnabled("获取聊天sid") then
        return
    end

    local requestInfo = ChatProto_pb.AuthSend()
    requestInfo.productNo = ChatConfig.productNo -- 平台编号 这个是服务器分配的固定值 跟产品绑定
    requestInfo.group = self.chatManager:getClanId()   -- 公会id
    requestInfo.user = globalData.userRunData.userUdid -- 用户id
    requestInfo.token = globalData.userRunData.loginUserData.token

    if not requestInfo.group or requestInfo.group == "" then
        -- 玩家没有公会了(被踢出公会了没有 closeSockt)
        self.chatManager:onClose()
    end

    local body = requestInfo:SerializeToString()
    self:sendRequest( ChatConfig.REQUEST_TYPE.AUTH, body)
end

-- 同步聊天记录请求
function ChatSyncManager:requestChatSync()
    local sid = self.chatManager:getChatSid()
    if not self:checkRequestEnabled("同步聊天信息") or not sid then
        return
    end

    local requestInfo = ChatProto_pb.SyncSend()
    requestInfo.sid = self.chatManager:getChatSid()    -- 认证返回的Token
    requestInfo.msgId = self.chatManager:getLatestChatId()
    requestInfo.chipsMsgId = self.chatManager:getLatestChipId()
    requestInfo.giftMsgId = self.chatManager:getLatestGiftId()
    requestInfo.chatMsgId = self.chatManager:getLatestTextId()
    requestInfo.redPackageMsgId = self.chatManager:getLatestRedGiftId()
    local body = requestInfo:SerializeToString()
    self:sendRequest( ChatConfig.REQUEST_TYPE.SYNC, body )
end

-- 发送聊天信息
function ChatSyncManager:sendChat( content, msg_type )
    local sid = self.chatManager:getChatSid()
    if not self:checkRequestEnabled("发送聊天信息") or not sid then
        return
    end

    -- message MessageSend {
    --     optional string sid = 1;//认证返回的Token
    --     optional string content = 2;//消息内容
    --     optional MessageType type = 3;//消息类型
    --     optional string nickname = 4;//用户名称
    --     optional string head = 5;//用户头像
    --     optional string facebookId = 6;//facebookId
    --     optional string frame = 7;//用户头像框id
    -- }
    local requestInfo = ChatProto_pb.MessageSend()
    requestInfo.sid = self.chatManager:getChatSid()             -- 认证返回的Token
    requestInfo.content = content                               -- 消息内容
    requestInfo.type = msg_type                                 -- 消息类型
    requestInfo.nickname = globalData.userRunData.nickName      -- 用户名称
    requestInfo.head = tostring(globalData.userRunData.HeadName)    -- 用户头像
    requestInfo.facebookId = globalData.userRunData.facebookBindingID -- fbid
    requestInfo.frame = tostring(globalData.userRunData.avatarFrameId) -- 用户头像框id

    local body = requestInfo:SerializeToString()
    self:sendRequest( ChatConfig.REQUEST_TYPE.SEND, body )
end

-- 心跳
function ChatSyncManager:heartBeat()
    local sid = self.chatManager:getChatSid()
    if not self:checkRequestEnabled("聊天消息心跳") or not sid then
        return
    end

    local requestInfo = ChatProto_pb.HeartSend()
    requestInfo.sid = self.chatManager:getChatSid()    -- 认证返回的Token

    local body = requestInfo:SerializeToString()
    self:sendRequest( ChatConfig.REQUEST_TYPE.HEART, body )
end

--重新连接socket
function ChatSyncManager:reConnect()
    if isNewTcp then
        self.chatManager:setChatSid(nil)
        TcpNewManager:getInstance():reConnect(self.m_tcpName)
    else
        -- TcpNetManager:getInstance():reConnect("clan_chat")
    end
end

-- 金币领取消息
-- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
function ChatSyncManager:sendCollect(msgId, coins)
    local sid = self.chatManager:getChatSid()
    if not self:checkRequestEnabled("金币领取消息") or not sid then
        return
    end

    local requestInfo = ChatProto_pb.CollectSend()
    requestInfo.sid = self.chatManager:getChatSid()    -- 认证返回的Token
    requestInfo.msgId = msgId
    requestInfo.coins = coins
    requestInfo.collector = globalData.userRunData.userUdid  -- 用户id
    
    local body = requestInfo:SerializeToString()
    self:sendRequest( ChatConfig.REQUEST_TYPE.COLLECT, body )
end

-- 消息 一键领取
-- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
function ChatSyncManager:sendFastCollectAll(msgIdList, coinsList)
    local sid = self.chatManager:getChatSid()
    if not self:checkRequestEnabled("金币领取消息") or not sid then
        return
    end

    local requestInfo = ChatProto_pb.CollectAllSend()
    requestInfo.sid = self.chatManager:getChatSid()    -- 认证返回的Token
    for _, msgId in ipairs(msgIdList) do
        requestInfo.msgId:append(msgId)
     end
     for _, coinNum in ipairs(coinsList) do
         requestInfo.coins:append(coinNum)
     end
    local body = requestInfo:SerializeToString()
    self:sendRequest( ChatConfig.REQUEST_TYPE.COLLECT_ALL, body )
end

-- 消息返回成功
function ChatSyncManager:onSuccess( msgId, response )
    release_print("--------------------------onSuccess msgId = " .. msgId)
    if msgId == ChatConfig.REQUEST_TYPE.AUTH then
        -- 获取sid成功回调
        self.chatManager:parseAuthData( response )
    elseif msgId == ChatConfig.REQUEST_TYPE.SYNC then
        -- 拉取聊天记录成功回调
        self.chatManager:parseChatData( response )
    elseif msgId == ChatConfig.REQUEST_TYPE.NOTICE then
        -- 接收到新的消息
        self.chatManager:parseNoticeData( response )
    elseif msgId == ChatConfig.REQUEST_TYPE.SEND then
        -- 发送消息成功回调
        self.chatManager:onMessageSendOver( response )
    elseif msgId == ChatConfig.REQUEST_TYPE.HEART then
        -- 心跳成功回调
        self.chatManager:onHeratBeatSendOver( response )
    elseif msgId == ChatConfig.REQUEST_TYPE.COLLECT then
        -- 礼物领取成功回调
        self.chatManager:onCollectSyncOver( response )
    elseif msgId == ChatConfig.REQUEST_TYPE.COLLECT_ALL then
        -- 礼物领取全部成功回调
        self.chatManager:onCollectSyncOver( response )
    end
    self.chatManager:reConnectSplunkLog(4, msgId)
end

-- 消息返回异常
function ChatSyncManager:onFaild( msgId, response )
    release_print("--------------------------onFaild msgId ="..msgId)
    self.chatManager:reConnectSplunkLog(5, string.format("chatMsgID: %s, code: %s",msgId, (response and response.code or "not_response")))

    -- 报送到 splunk
    if response.code ~= ChatConfig.RESPONSE_CODE.SID_ILLEGAL then
        -- SID无效 不用报送
        local logMsg = "cahtMsgID:" .. tostring(msgId) .. ", code:".. tostring(response.code)
        util_sendToSplunkMsg("TeamChatFaildLog", logMsg)
    end

    printInfo("消息异常 " .. msgId)
    if msgId == ChatConfig.REQUEST_TYPE.AUTH then
        self.chatManager:setChatSid()   -- 置空
    end

    if response.code == ChatConfig.RESPONSE_CODE.SYSTEM_ERROR then
        printInfo("系统异常")
        return
    elseif response.code == ChatConfig.RESPONSE_CODE.ILLEGAL_ARGUMENT then
        printInfo("参数非法")
        return
    elseif response.code == ChatConfig.RESPONSE_CODE.AUTHORIZATION_FAILED then
        printInfo("认证失败")
        return
    elseif response.code == ChatConfig.RESPONSE_CODE.SID_ILLEGAL then
        printInfo("SID无效 需要再次请求sid")
        self:requestAuthInfo()          -- 重新请求
        return
    end

    if msgId == ChatConfig.REQUEST_TYPE.SEND then
        -- 发送消息失败回调
        self.chatManager:onMessageSendFaild( response )
    end
end

-- 消息接口
function ChatSyncManager:sendRequest( msgId, body )
    if not body then
        return
    end
    if isNewTcp then
        TcpNewManager:getInstance():sendMessage("clan_chat",msgId, body)
    else
        -- TcpNetManager:getInstance():sendMessage("clan_chat",  msgId, body)
    end
end
--读取socket通讯id对应的proto解析配置
function ChatSyncManager:getProtoMappingData()
    if not self.m_protoMappingData then
        self.m_protoMappingData = util_checkJsonDecode("src/ProtoMapping.json")
    end
    return self.m_protoMappingData
end
--字符串protobuf
function ChatSyncManager:loadStringProtoData(msgId,responseData )
    local receiveList = self:getProtoMappingData()
    local strFunc = nil
    if receiveList then
        strFunc = receiveList[tostring(msgId)]
        if not strFunc then
            -- "-1"是默认配置
            strFunc = receiveList["-1"]
        end
    end
    if not strFunc then
         --没有读取到表走默认配置正常不应该走这里
        strFunc = "return ChatBaseProto_pb.Response()"
    else
        --组装函数
        strFunc = "return "..strFunc.."()"
    end
    return loadstring(strFunc)()
end

--解析protobuf
function ChatSyncManager:parseProtoData(msgId,responseData )
    local proData = self:loadStringProtoData(msgId)
    proData:ParseFromString(responseData)
    return proData
end

-- 数据接收
function ChatSyncManager:onReceive( response )
    release_print("--------------------------onReceive start")
    local responseData = response.data
    if not responseData then
        printInfo("---->    接收的数据是个鸡儿？空的")
        return
    end
    local msgId = response.msgId
    
    release_print("--------------------------onReceive msgId ="..msgId)
    local proData = self:parseProtoData(msgId,responseData)
    if proData.code == ChatConfig.RESPONSE_CODE.SUCCEED then
        self:onSuccess(msgId, proData)
    else
        if msgId == ChatConfig.REQUEST_TYPE.NOTICE then
            self:onSuccess(msgId, proData)
        else
            self:onFaild(msgId, proData)
        end
    end
end

-- 判断是否可以发送消息
function ChatSyncManager:checkRequestEnabled(errorMsg)
    -- 这里只做了是否登录的检测 预留等级等一些其他的限定条件
    local isLogin = gLobalSendDataManager:isLogin()
    if errorMsg then
        local reason = ""
        if not isLogin then
            reason = " 玩家未登陆"
        end
        printInfo("------>    " .. errorMsg .. reason)
    end
    return isLogin
end

function ChatSyncManager:onOpen(func)
    if isNewTcp then
        TcpNewManager:getInstance():checkConnectClient(TcpNetConfig.SERVER_KEY.CLAN_CHAT,func)
    else
        -- if not TcpNetManager:getInstance():getClient(TcpNetConfig.SERVER_KEY.CLAN_CHAT) then
        --     TcpNetManager:getInstance():createTcpClient(TcpNetConfig.SERVER_KEY.CLAN_CHAT, "172.16.4.64", 9005)
        -- else
        --     if not TcpNetManager:getInstance():getClientReady(TcpNetConfig.SERVER_KEY.CLAN_CHAT) then
        --         TcpNetManager:getInstance():getClient(TcpNetConfig.SERVER_KEY.CLAN_CHAT):connect()
        --     end
        -- end
        -- if func then
        --     func()
        -- end
    end
end

function ChatSyncManager:onClose( )
    if isNewTcp then
        TcpNewManager:getInstance():clearSocket(TcpNetConfig.SERVER_KEY.CLAN_CHAT)
    else
        -- TcpNetManager:getInstance():closeTcpClient(TcpNetConfig.SERVER_KEY.CLAN_CHAT)
    end
end

function ChatSyncManager:init()
    local ChatManager = require("manager.System.ChatManager")
    self.chatManager = ChatManager:getInstance()
    gLobalNoticManager:addObserver(self,function(self,response)
        self:onReceive(response)
    end, ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_REFCEIVE)

    self.m_tcpName = TcpNetConfig.SERVER_KEY.CLAN_CHAT or "clan_chat"
end

function ChatSyncManager:getInstance()
    if not self._instance then
        self._instance = ChatSyncManager.new()
        self._instance:init()
    end
    return self._instance
end

--获取链接状态
function ChatSyncManager:getSocketState()
    return TcpNewManager:getInstance():getSocketState(self.m_tcpName)
end

return ChatSyncManager
