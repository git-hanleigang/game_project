

-- 聊天信息结构体
-- message MessageInfo {
--     optional string msgId = 1,          --//消息id
--     optional MessageType type = 2,      --//消息类型
--     optional string content = 3,        --//消息内容
--     optional string sendUser = 4,       --//发送人UDID
--     optional int64 sendTime = 5,        --//发送时间
--     optional int32 status = 6,          --//消息状态 -1:无状态，0:未领取，1:已领取
--     optional int64 effecTime = 7,       --//消息有效时间戳 -1：无；
--     optional string extra = 8,          --//额外参数
--     optional int64 coins = 9,           --//可领取奖励消息，领取的金币
--     optional string nickname = 10,      --//用户名称
--     optional string head = 11,          --//用户头像
--     optional string facebookId = 12,    --//facebookId
--     optional string extendData = 13;    --//额外数据2
-- }
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatConfig = require("data.clanData.ChatConfig")
local MessageBody = class("MessageBody")

function MessageBody:ctor( data )
    self:parsedata(data)
end

function MessageBody:parsedata( data )
    if data and data.msgId then
        self.msgId = data.msgId              -- 消息id
        self.messageType = data.type         -- 消息类型
        self.content = data.content          -- 消息内容
        self.sender = data.sendUser          -- 发送人UDID 这里直接给玩家昵称更好一点？
        self.sendTime = tonumber(data.sendTime)        -- 发生时间
        self.status = data.status            -- 消息状态 -1:无状态，0:未领取，1:已领取
        self.effecTime = tonumber(data.effecTime)      -- 消息有效时间戳 -1：无；
        self.extra = {}
        if string.len(data.extra) > 0 then
            self.extra = cjson.decode(data.extra)-- 额外参数
            self:checkSelfClanPositionChange()
        end
        self.coins = tonumber(data.coins)              -- 可领取的金币 用于可领取奖励的显示
        self.nickname = data.nickname        -- 用户名称
        self.head = data.head                -- 用户头像
        self.facebookId = data.facebookId    -- facebookId
        self.frameId = data.frame            -- 头像id
        if self.sender == globalData.userRunData.userUdid then
            self.frameId = globalData.userRunData.avatarFrameId
        end
        self.extendData = {}
        if string.len(data.extendData) > 0 then
            self.extendData = cjson.decode(data.extendData)-- 额外参数2
        end

        self:updateRedGiftStatus()
    end
end

-- 刷新消息体
function MessageBody:refreshMsgByData( data )
    if not data or data.type == ChatConfig.MESSAGE_TYPE.RED_PACKAGE then
        printInfo("聊天数据刷新 没有要刷新的信息")
        return
    end
    -- 服务器说 找到原来的完整消息比较困难 所以只返回部了分需要刷新的字段
    -- 由于返回的消息不完整 所以不能直接替换 这里只是找出旧消息里需要刷新的字段来替换
    -- 所以每次新增都要在这里加 后面看情况 如果复杂 就找服务器商量 要完整数据
    if data.extendData and string.len(data.extendData) > 0 then
        self.extendData = cjson.decode(data.extendData)-- 额外参数2
    end

    if data.status then
        self.status = data.status
    end

    if data.coins then
        self.coins = tonumber(data.coins)
    end
end

function MessageBody:updateRedGiftStatus()
    if self.messageType ~= ChatConfig.MESSAGE_TYPE.RED_PACKAGE then
        return
    end

    -- self.m_recAllUdidList = {} 
    -- self.m_hadColUdidList = {} 

    -- if self.content and #self.content > #"{}" then
    --     local msgInfo = cjson.decode(self.content)
    --     local allUdids = msgInfo.clanRedPackageUdids or ""
    --     local allUserList = {}
    --     if #allUdids > 0 then
    --         allUserList = string.split(allUdids, ";")
    --     end

    --     local colUdids = msgInfo.redPackageOwner or ""
    --     local colUserList = {}
    --     if #colUdids > 0 then
    --         colUserList = string.split(colUdids, ";")
    --     end

    --     local bCollected = false
    --     for _, udid in pairs(colUserList) do
    --         if udid == globalData.userRunData.userUdid then
    --             bCollected = true
    --             break
    --         end
    --     end

    --     self.status = bCollectd and 1 or 0
    --     self.m_recAllUdidList = allUserList 
    --     self.m_hadColUdidList = colUserList 
    -- end

    -- 本人是发送者
    if self.sender == globalData.userRunData.userUdid then
        self.status = 1
    end
end

-- 检测是本人的公会职位发生变化
--[[
    type:
        leave  主动退出
        kick  被会长踢了
        agreeJoin 审批加入
        applyJoin 申请主动自动加入
        quickJoin 快速加入
        inviteJoin 邀请加入
]]
function MessageBody:checkSelfClanPositionChange()
    local type = self.extra.type
    local udid = self.extra.udid
    if udid ~= globalData.userRunData.userUdid then
        if type == "leave" and udid == ClanManager:getLearderUdid() then
            -- 要是会长离开看下自己是不是变成会长了
            ClanManager:sendClanInfo()
        end

        return
    end

    if type == "kick" then
        -- 被会长踢了
        ClanManager:kickOffByLeader()
    elseif type == "agreeJoin" then
        -- 会长审批通过加入了公会
        ClanManager:notifyLeaderAgreeSelfJoin()
    end 
end



-- 聊天数据
local ChatData = class("ChatData")

function ChatData:ctor()
    self:init()
end

function ChatData:parseMessageData( data )
    return MessageBody.new(data)
end

-- 一些变量的初始化
function ChatData:init()
    self.m_commonList = {}      -- 常规聊天记录列表
    self.m_chipsList = {}       -- 卡牌请求列表
    self.m_giftList = {}        -- 礼物领取列表
    self.m_textList = {}        -- 普通文本类型聊天列表
    self.m_redGiftList = {}        -- 公会红包类型聊天列表

    self.m_canCollectGiftMsgIdMap = {} --记录下可以领取的gift类型的消息
end

-- 获取常规聊天记录列表
function ChatData:getCommonChatList()
    return self.m_commonList
end

-- 获取卡牌申请列表
function ChatData:getChipsChatList()
    if CardSysManager:isNovice() then
        return {}
    end
    return self.m_chipsList
end

-- 获取礼物领取列表
function ChatData:getGiftChatList()
    return self.m_giftList
end

-- 获取普通文本类型聊天列表
function ChatData:getTextChatList()
    return self.m_textList
end

-- 获取 微信红包聊天数据
function ChatData:getRedGiftList()
    return self.m_redGiftList
end
-- 获取 最新未领取的 红包数据 
function ChatData:getUnCollectRedGift()
    local redGiftData = nil
    for i=#self.m_redGiftList, 1, -1 do
        local data = self.m_redGiftList[i]
        if data and data.status==0 and data.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE and data.effecTime then
            local leftTime = util_getLeftTime(data.effecTime)
            if leftTime > 0 then
                redGiftData = data
                break
            end
        end 
    end

    return redGiftData
end
-- 获取 最新未领取的 红包个数
function ChatData:getUnCollectRedGiftCount()
    local count = 0
    for i=#self.m_redGiftList, 1, -1 do
        local data = self.m_redGiftList[i]
        if data and data.status==0 and data.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE and data.effecTime then
            local leftTime = util_getLeftTime(data.effecTime)
            if leftTime > 0 then
                count = count + 1
            end
        end 
    end

    return count
end


-- 获取可以领取的gift类型的消息 集合
function ChatData:getCanCollectGiftMsgIdMap()
    return self.m_canCollectGiftMsgIdMap
end

-- 常规聊天信息列表
function ChatData:parseCommonData( data, bAddNewMsg )
    if data then
        local commonChats = self:parseMessageData(data)
        if not self:checkCanInsertList(data) then
            return commonChats
        end
        local msg = self:isMessageExist(self.m_commonList, commonChats)
        if not msg and self:checkMsgLegal(data) then
            commonChats.m_listType = ChatConfig.NOTICE_TYPE.COMMON
            if bAddNewMsg then
                self:resetMessageList(self.m_commonList, commonChats, ChatConfig.MESSAGE_LIMIT_ENUM.ALL)
                self:checkMemberCountChange(commonChats)
            else
                table.insert(self.m_commonList, 1, commonChats)
            end
        elseif msg then
            msg:refreshMsgByData(data)
        end
        return commonChats
    end
end

-- 检查公会成员是否发生变化 以便使用成员信息时及时请求变化
function ChatData:checkMemberCountChange(_msgBody)
    if not _msgBody then
        return
    end

    local udid = _msgBody.extra.udid
    -- 自己被踢了什么的不用管
    if udid == globalData.userRunData.userUdid then
        return
    end

    local type = _msgBody.extra.type
    if type == "leave" or type == "kick" then
        -- 通知现有成员库 里删除改成员
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.DELETE_DATABASE_MEMBER) --玩家退出或被踢更新 成员数据
    else
        -- 通知 下次使用成员信息时及时更新
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_UPDATE_MEMBER) --玩家新加入更新 成员数据
    end

end

-- 卡牌请求列表 返回最新一条信息
function ChatData:parseChipsData( data, bAddNewMsg )
    if data then
        local chipChats = self:parseMessageData(data)
        local msg = self:isMessageExist(self.m_chipsList, chipChats)
        if not msg and self:checkMsgLegal(data) then
            chipChats.m_listType = ChatConfig.NOTICE_TYPE.CHIPS
            if bAddNewMsg then
                self:resetMessageList(self.m_chipsList, chipChats, ChatConfig.MESSAGE_LIMIT_ENUM.CHIPS)
            else
                table.insert(self.m_chipsList, 1, chipChats)
            end
        elseif msg then
            -- 刷新消息
            msg:refreshMsgByData(data)
        end
        return chipChats
    end
end

-- 礼物领取列表 返回最新一条信息
function ChatData:parseGiftData( data, bAddNewMsg )
    if data then
        local giftChats = self:parseMessageData(data)
        if not self:checkCanInsertList(data) then
            return giftChats
        end
        local msg = self:isMessageExist(self.m_giftList, giftChats)
        if not msg then
            giftChats.m_listType = ChatConfig.NOTICE_TYPE.GIFT
            if bAddNewMsg then
                self:resetMessageList(self.m_giftList, giftChats, ChatConfig.MESSAGE_LIMIT_ENUM.GIFT)
            else
                table.insert(self.m_giftList, 1, giftChats)
            end

            -- 可领奖 不是自己的 还没到期 加到一键领取列表里
            if giftChats.status == 0 and (giftChats.sender ~= globalData.userRunData.userUdid or 
            giftChats.messageType == ChatConfig.MESSAGE_TYPE.RANK_REWARD or 
            giftChats.messageType == ChatConfig.MESSAGE_TYPE.RUSH_REWARD or
            giftChats.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT_SHARE or 
            giftChats.messageType == ChatConfig.MESSAGE_TYPE.AVATAR_FRAME or
            giftChats.messageType == ChatConfig.MESSAGE_TYPE.CLAN_DUEL) and giftChats.effecTime and 
            giftChats.messageType ~= ChatConfig.MESSAGE_TYPE.RED_PACKAGE and
            giftChats.messageType ~= ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT then
                if self:checkCanInsertGiftMsg(data) then
                    local leftTime = util_getLeftTime(giftChats.effecTime)
                    if leftTime > 0 then
                        self.m_canCollectGiftMsgIdMap[giftChats.msgId] = true
                    end
                end
            end
            
        else
            -- 刷新消息
            msg:refreshMsgByData(data)
        end

        return giftChats
    end
end

-- 普通文本类型聊天列表 返回最新一条信息
function ChatData:parseTextData( data, bAddNewMsg )
    if data then
        local textChats = self:parseMessageData(data)
        local msg = self:isMessageExist(self.m_textList, textChats)
        if not msg then
            textChats.m_listType = ChatConfig.NOTICE_TYPE.CHAT
            if bAddNewMsg then
                self:resetMessageList(self.m_textList, textChats, ChatConfig.MESSAGE_LIMIT_ENUM.CHAT)
            else
                table.insert(self.m_textList, 1, textChats)
            end
        else
            -- 刷新消息
            msg:refreshMsgByData(data)
        end
        return textChats
    end
end

-- 红包 消息数据
function ChatData:parseRedGiftData( data, bAddNewMsg)
    if data then
        local redGiftChats = self:parseMessageData(data)
        local msg = self:isMessageExist(self.m_redGiftList, redGiftChats)
        if not msg and self:checkCanInsertList(data) then
            if bAddNewMsg then
                self:resetMessageList(self.m_redGiftList, redGiftChats, ChatConfig.MESSAGE_LIMIT_ENUM.RED)
                gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH)
                gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_REFRESH_RED_GIFT_CHAT_TOP) -- 刷新红包置顶消息
            else
                table.insert(self.m_redGiftList, 1, redGiftChats)
            end
        elseif msg then
            if msg.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE and data.content and #data.content > #"{}" then
                if msg.status == 0 and data.status == 1 then
                    -- 本人 领奖
                    msg.content = data.content
                    msg.status = 1
                    local msgAll = self:isMessageExist(self.m_commonList, redGiftChats)
                    if msgAll then
                        msgAll.content = data.content
                        msgAll.status = 1
                    end

                    local msgGift = self:isMessageExist(self.m_giftList, redGiftChats)
                    if msgGift then
                        msgGift.content = data.content
                        msgGift.status = 1
                    end
                else
                    local jsonObj = cjson.decode(data.content)
                    local msgInfo = {}
                    local content = msg.content or "{}"
                    if #content > 2 then
                        msgInfo = cjson.decode(content)
                    end
                    local sourceDollars = msgInfo.collectDollars or 0
                    msgInfo.collectedCount = jsonObj.collectedCount or 0
                    if sourceDollars == 0 then
                        msgInfo.collectDollars = jsonObj.collectDollars or 0
                    end
                    local newContent = cjson.encode(msgInfo)
                    msg.content = newContent
                    local msgAll = self:isMessageExist(self.m_commonList, redGiftChats)
                    if msgAll then
                        msgAll.content = newContent
                    end

                    local msgGift = self:isMessageExist(self.m_giftList, redGiftChats)
                    if msgGift then
                        msgGift.content = newContent
                    end
                end
                
                gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_REFRESH_RED_GIFT_CHAT, msg)
            end
        end
        return redGiftChats
    end
end

function ChatData:isMessageExist( msg_list, msg )
    for idx,msgData in pairs(msg_list) do
        if msgData.msgId == msg.msgId then
            return msg_list[idx]
        end
    end
end

-- 重排消息列表 返回最新一条信息
function ChatData:resetMessageList( msg_List, msg, max )
    if not msg then
        return
    end

    -- 超长 先去掉前面的
    if table.nums(msg_List) >= max then
        table.remove(msg_List, 1)
    end
    
    table.insert(msg_List, msg)
end

function ChatData:getMessageById( msgId )
    local messageList = {}
    for idx,data in pairs(self.m_commonList) do
        if data.msgId == msgId then
            table.insert(messageList, self.m_commonList[idx])
            break
        end
    end
    for idx,data in pairs(self.m_chipsList) do
        if data.msgId == msgId then
            table.insert(messageList, self.m_chipsList[idx])
            break
        end
    end
    for idx,data in pairs(self.m_giftList) do
        if data.msgId == msgId then
            table.insert(messageList, self.m_giftList[idx])
            break
        end
    end
    -- 客户端 获取消息  刷新数据 所以不用遍历纯文本的
    -- for idx,data in pairs(self.m_textList) do
    --     if data.msgId == msgId then
    --         table.insert(messageList, self.m_textList[idx])
    --         break
    --     end
    -- end
    return messageList
end

-- 获取 gift 类型里的消息
function ChatData:getGiftMessageById( msgId )
    for _,data in pairs(self.m_giftList) do
        if data.msgId == msgId then
            return data
        end
    end
end

function ChatData:clear()
    self.m_commonList = {}
    self.m_chipsList = {}
    self.m_giftList = {}
    self.m_textList = {}
    self.m_redGiftList = {}
    self.m_canCollectGiftMsgIdMap = {} 

end

-- 检查 聊天数据的合法行
function ChatData:checkMsgLegal(_data)
    if not _data then
        return false
    end

    -- 玩家送卡消息结构， 如果在集合里找不到该msgId。不insert到消息集合里
    -- msg {
    --     msgId: 2022021114420253975
    --     type: 7
    --     sendTime: 0
    --     status: 1
    --     effecTime: -1
    --     coins: 0
    --     extendData: {"senderName":"Guest5995"}
    -- }
    if _data.type == ChatConfig.MESSAGE_TYPE.CLAN_MEMBER_CARD then
        if not _data.content or _data.content == "" then
            return false
        end

        return true
    end

    return true
end

-- 检查 该数据是否要加到列表里
function ChatData:checkCanInsertList(_data)
    if not _data then
        return false
    end

    if (_data.type == ChatConfig.MESSAGE_TYPE.CLAN_MEMBER_CARD or _data.type == ChatConfig.MESSAGE_TYPE.CLAN_DUEL) and CardSysManager:isNovice() then
        -- 新手集卡期间 不显示要卡送卡消息
        return false
    end

    -- 公会排行榜自己没做贡献 不能领奖
    if _data.type == ChatConfig.MESSAGE_TYPE.RANK_REWARD or _data.type == ChatConfig.MESSAGE_TYPE.RUSH_REWARD then
        local content = _data.content or ""
        if #content < #"{}" then
            return false
        end
        local contentInfo = cjson.decode(content)
        local memberList = contentInfo.members
        for i=1,#memberList do
            local memberUdid = memberList[i]
            if memberUdid == globalData.userRunData.userUdid then
                return true
            end
        end
        return false
    elseif _data.type == ChatConfig.MESSAGE_TYPE.RED_PACKAGE then
        -- 红包 发送者 和 接受者 才可以看到
        if _data.sendUser == globalData.userRunData.userUdid then
            return true
        end
        local content = _data.content or ""
        if #content < #"{}" then
            return false
        end
        local contentInfo = cjson.decode(content)
        local udidListStr = contentInfo.clanRedPackageUdids or ""
        local list = string.split(udidListStr, ";")
        for _, udidStr in pairs(list) do
            if udidStr == globalData.userRunData.userUdid then
                return true
            end
        end
        return false
    elseif _data.type == ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT then
        -- 红包领取通知（谁领取了你的红包）
        local content = _data.content or ""
        if #content < #"{}" then
            return false
        end
        local contentInfo = cjson.decode(content)
        local redPackageOwner = contentInfo.redPackageOwner 
        if redPackageOwner == globalData.userRunData.userUdid then
            return true
        end
        return false
    elseif _data.type == ChatConfig.MESSAGE_TYPE.CLAN_DUEL then 
        -- 公会对决排行榜自己没做贡献 不能领奖
        local content = _data.content or ""
        if #content < #"{}" then
            return false
        end
        local contentInfo = cjson.decode(content)
        local memberList = contentInfo.members or {}
        local status = contentInfo.status or false
        if status then
            for k, v in pairs(memberList) do
                if k == globalData.userRunData.userUdid then
                    return true
                end
            end
        else
            return true
        end
        return false
    end

    return true
end

-- 检查 该数据是否要加到一键领取列表里
function ChatData:checkCanInsertGiftMsg(_data)
    if _data.type == ChatConfig.MESSAGE_TYPE.CLAN_DUEL then 
        -- 公会对决失败不发奖励（只发一段话）
        local content = _data.content or ""
        if #content < #"{}" then
            return false
        end
        local contentInfo = cjson.decode(content)
        local status = contentInfo.status or false
        if not status then
            return false
        end
    end

    return true
end

-- 是否需要弹出公会对决胜利 or 失败弹板
function ChatData:isPopClanDuelResultLayer()
    local msgId = ""
    local isPop = false
    local duelStatus = false
    for idx, data in pairs(self.m_giftList) do
        if data.messageType == ChatConfig.MESSAGE_TYPE.CLAN_DUEL then 
            local leftTime = util_getLeftTime(data.effecTime)
            local content = data.content or "{}"
            local contentInfo = cjson.decode(content)
            duelStatus = contentInfo.status or false
            if leftTime > 0 and data.status == 0 then
                msgId = data.msgId
                isPop = true
            end
        end
    end

    if isPop then
        local key = "isPopClanDuelResultLayer" .. msgId
        local isFirstPop = gLobalDataManager:getBoolByField(key, true)
        if not isFirstPop then
            return false, duelStatus
        end
        gLobalDataManager:setBoolByField(key, false)
    end

    return isPop, duelStatus
end

return ChatData