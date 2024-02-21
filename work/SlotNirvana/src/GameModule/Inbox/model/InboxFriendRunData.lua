local BaseInboxRunData = util_require("GameModule.Inbox.model.BaseInboxRunData")
local InboxFriendRunData = class("InboxFriendRunData", BaseInboxRunData)

function InboxFriendRunData:ctor()
    BaseInboxRunData.ctor(self)

    self.m_hasFriendData = false

    self.m_FBCardList = {}
    self.m_expireAtList = {}
    self.m_sendLimitList = {}
    self.m_sendRecordList = {}

    -- self.m_FBFriendList = {}
    -- self.m_FBFriendInfo = {}

    self.m_limitMax = 20 -- 显示的最大数量
end

function InboxFriendRunData:isCanShow(_mailData)
    -- 集卡新手期 不返回 常规集卡邮件数据
    if _mailData:isCardType() and globalData:isCardNovice() then
        return false
    end
    if _mailData:getLeftTime() <= 0 then
        return false
    end
    return true
end

function InboxFriendRunData:parseData(_netData)
    -- 移植后暂时这么处理，以后有时间再改 todo:maqun
    local temp = self:parseFBMailData(_netData)
    self:initFBMailData(temp)
end


-- 解析FB好友邮件数据
function InboxFriendRunData:parseFBMailData(netData)
    local temp = {}

    temp.expireAts = {} -- {COIN:1294102414, CARD:3254235151} -- 倒计时
    temp.expireAts.COIN = netData.expireAts.COIN
    temp.expireAts.CARD = netData.expireAts.CARD
    ----------------添加数据错误检测 start
    if not temp.expireAts.COIN then
        gLobalBuglyControl:luaException("InboxFriendRunData:parseFBMailData error not expireAts.COIN", debug.traceback())
    end

    if not temp.expireAts.CARD then
        gLobalBuglyControl:luaException("InboxFriendRunData:parseFBMailData error not expireAts.CARD", debug.traceback())
    end
    ----------------添加数据错误检测 end

    temp.sendLimits = {} -- {COIN:2, CARD:30} -- 已经发送的好友id
    temp.sendLimits.COIN = netData.sendLimits.COIN
    temp.sendLimits.CARD = netData.sendLimits.CARD
    ----------------添加数据错误检测 start
    local errorMessage = nil
    if not temp.sendLimits.COIN then
        errorMessage = "InboxFriendRunData:parseFBMailData error not coins"
    end
    if not temp.sendLimits.CARD then
        if errorMessage then
            errorMessage = errorMessage .. " or not card"
        else
            errorMessage = "InboxFriendRunData:parseFBMailData error not card"
        end
    end
    if errorMessage then
        gLobalBuglyControl:luaException(errorMessage, debug.traceback())
    end
    ----------------添加数据错误检测 end
    temp.sendRecords = {} -- {COIN:["fan2", "fbid",], CARD:["fan2", "fbid",]} -- 已经发送的好友id
    temp.sendRecords.COIN = {}
    if netData.sendRecords.COIN and #netData.sendRecords.COIN > 0 then
        for i = 1, #netData.sendRecords.COIN do
            temp.sendRecords.COIN[i] = netData.sendRecords.COIN[i]
        end
    end
    temp.sendRecords.CARD = {}
    if netData.sendRecords.CARD and #netData.sendRecords.CARD > 0 then
        for i = 1, #netData.sendRecords.CARD do
            temp.sendRecords.CARD[i] = netData.sendRecords.CARD[i]
        end
    end

    temp.collectMails = {}
    if netData.collectMails and #netData.collectMails > 0 then
        for i = 1, #netData.collectMails do
            temp.collectMails[#temp.collectMails + 1] = self:parseFBMailItemData(netData.collectMails[i])
        end
    end

    -- 公会送卡
    temp.clanMails = {}
    if netData.clanMails and #netData.clanMails > 0 then
        for i = 1, #netData.clanMails do
            temp.clanMails[#temp.clanMails + 1] = self:parseFBMailItemData(netData.clanMails[i])
        end
    end

    return temp
end

-- awards:"{"cards":{"19030708":1,"19030709":1,"19030909":1,"19030403":1,"19030702":1},"coins":0}"
-- id:10
-- senderFacebookId:"fan2"
-- senderNickName:"fanfan2"
-- senderUdid:"fan2:SlotNewCashLink"
-- sendTime:1596800475639
-- type:"CARD"
-- senderHead: "1"
function InboxFriendRunData:parseFBMailItemData(data)
    local temp = {}
    local keys = {"id", "senderFacebookId", "senderNickName", "senderUdid", "sendTime", "type", "senderHead", "expireAt", "senderFrameId"}
    for i = 1, #keys do
        local key = keys[i]
        temp[key] = data[key]
    end
    if data.awards then
        local dd = cjson.decode(data.awards)

        temp.awards = {}
        if dd.coins and dd.coins ~= "" then
            temp.awards.coins = dd.coins
        end

        if dd.cards then
            temp.awards.cards = {}
            for k, v in pairs(dd.cards) do
                temp.awards.cards[k] = v
            end
        end
    end
    return temp
end

-------------------------------------------------------------------------------------------------------------------------------------
-- 解析可以送的集卡的数据列表
function InboxFriendRunData:parseFBCardData(netData)
    local temp = {}
    if not netData then
        return temp
    end
    for i = 1, #netData do
        local cardData = netData[i]
        temp[i] = self:CardClone(cardData)
    end
    return temp
end

-- 需要同步集卡
function InboxFriendRunData:CardClone(tInfo)
    local card = {}
    card.cardId = tInfo.cardId
    card.number = tInfo.number
    card.year = tInfo.year
    card.season = tInfo.season
    card.clanId = tInfo.clanId
    card.albumId = tInfo.albumId
    card.type = tInfo.type
    card.star = tInfo.star
    card.name = tInfo.name
    card.icon = tInfo.icon
    card.count = tInfo.count
    card.linkCount = tInfo.linkCount
    card.newCard = tInfo.newCard
    card.description = tInfo.description
    card.source = tInfo.source
    card.firstDrop = tInfo.firstDrop
    card.nadoCount = tInfo.nadoCount
    card.greenPoint = tInfo.greenPoint
    card.goldPoint = tInfo.goldPoint
    card.exchangeCoins = tonumber(tInfo.exchangeCoins or 0)
    card.round = tInfo.round
    return card
end
-------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function InboxFriendRunData:initMailData(temp)
    local filterMailData  = self:filterMailData(temp or self.m_mailData)
    self.m_mailDatas = filterMailData
end

function BaseInboxRunData:initClanCardData( temp )
    local filterMailData  = self:filterMailData(temp or self.m_clanCardData)
    self.m_clanCardData = filterMailData  
end

function BaseInboxRunData:getClanCardData()
    return self.m_clanCardData
end

-- 刷选服务器数据(服务器会有5分钟缓存) cxc
function InboxFriendRunData:filterMailData(_mailDataList)
    local filterList = {}
    for k, mailData  in pairs(_mailDataList) do
        -- 集卡新手期 不返回 常规集卡邮件数据
        if not self:checkIgnoreCardMailData(mailData) then
            if mailData.validEnd then
                local endTime = util_getymd_time(mailData.validEnd)
                local leftTime  = endTime - util_getCurrnetTime()

                if leftTime > 0 then
                    table.insert(filterList, mailData)
                end
            else
                table.insert(filterList, mailData)
            end
        end
    end

    return filterList
end

-- 集卡新手期 不返回 常规集卡邮件数据
function InboxFriendRunData:checkIgnoreCardMailData(_mailData)
    local bCardNovice = globalData:isCardNovice()
    if not bCardNovice then
        return false
    end

    -- 该邮件涉及常规集卡 屏蔽
    if _mailData and _mailData.type == "CARD" then
        return true
    end

    return false
end

function InboxFriendRunData:initFBMailData(temp)
    self:initExpireAt(temp.expireAts)
    self:initMailData(temp.collectMails)
    self:initClanCardData(temp.clanMails)
    self:initSendLimit(temp.sendLimits)
    self:setSendRecordList(temp.sendRecords)
    self.m_hasFriendData = true
end

function InboxFriendRunData:getMailCount()
    return math.min(self.m_limitMax, (#self.m_mailDatas + #self.m_clanCardData))
end

function InboxFriendRunData:haveFriendData()
    return self.m_hasFriendData
end

----------------------------------------------------------------------------------------------------
-- 倒计时
function InboxFriendRunData:initExpireAt(data)
    self.m_expireAtList = data
end

function InboxFriendRunData:getExpireAt()
    return self.m_expireAtList
end

function InboxFriendRunData:getExpireAtBySendType(sendType)
    return self.m_expireAtList[sendType]
end

-- 倒计时这么写不准确，只是倒计时时间到了时处理一下
-- 每次进入邮箱还是会被重新赋值的
function InboxFriendRunData:clearExpireAt()
    local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    local tm = os.date("*t", math.floor(nowTime))
    local TodayTime24 = os.time({year = tm.year, month = tm.month, day = tm.day, hour = 24, min = 0, sec = 0, isdst = false})
    self.m_expireAtList.CARD = TodayTime24 * 1000
    self.m_expireAtList.COIN = TodayTime24 * 1000
end

-- 发送条件限制
function InboxFriendRunData:initSendLimit(data)
    self.m_sendLimitList = data
end

function InboxFriendRunData:getSendLimit()
    return self.m_sendLimitList
end

function InboxFriendRunData:getSendLimitBySendType(sendType)
    return self.m_sendLimitList[sendType] or 0
end

function InboxFriendRunData:isSendReachedLimit(sendType)
    local nLimit = self:getSendLimitBySendType(sendType)
    local recordList = self:getSendRecordListBySendType(sendType)
    if nLimit > #recordList then
        return false
    else
        return true
    end
end

-- 处理已经送过的好友
-- 所有当天已经送过的好友fbid列表
function InboxFriendRunData:setSendRecordList(list)
    self.m_sendRecordList = list
end

function InboxFriendRunData:getSendRecordList()
    return self.m_sendRecordList
end

function InboxFriendRunData:getSendRecordListBySendType(sendType)
    return self.m_sendRecordList[sendType] or {}
end

function InboxFriendRunData:addSendRecordList(sendType, friendUdids)
    if not self.m_sendRecordList[sendType] then
        self.m_sendRecordList[sendType] = {}
    end
    for i = 1, #friendUdids do
        table.insert(self.m_sendRecordList[sendType], friendUdids[i])
    end
end

function InboxFriendRunData:clearSendRecordList()
    self.m_sendRecordList = {CARD = {}, COIN = {}}
end
----------------------------------------------------------------------------------------------------
-- 发送给FB好友，选择卡牌列表
function InboxFriendRunData:initFBCardData(tempData)
    -- 移植后暂时这么处理，以后有时间再改 todo:maqun
    local temp = self:parseFBCardData(tempData)

    local cardList = {}
    for i, v in ipairs(temp) do
        local clanId = v.clanId
        if not cardList[clanId] then
            cardList[clanId] = {}
            cardList[clanId].cards = {}
        end
        table.insert(cardList[clanId].cards, v)
    end
    self.m_FBCardList = cardList
    return self:updateFBCardData()
end

function InboxFriendRunData:updateFBCardData()
    local cardClans, wildClans, normalClans, statueClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    if cardClans and #cardClans > 0 then
        local temp = {}
        for i, v in ipairs(cardClans) do
            local clanId = v.clanId
            if self.m_FBCardList[clanId] then
                local list = {}
                list.cards = self.m_FBCardList[clanId].cards
                list.name = v.name
                list.clanId = v.clanId
                if list.cards then
                    local types = {LINK = 3, GOLDEN = 2, NORMAL = 1}
                    table.sort(
                        list.cards,
                        function(a, b)
                            if types[a.type] == types[b.type] then
                                if a.star == b.star then
                                    return tonumber(a.cardId) < tonumber(b.cardId)
                                else
                                    return a.star > b.star
                                end
                            else
                                return types[a.type] > types[b.type]
                            end
                        end
                    )
                end
                table.insert(temp, list)
            end
        end
        self.m_FBCardList = temp
        if #self.m_FBCardList > 0 then
            table.sort(
                self.m_FBCardList,
                function(a, b)
                    return tonumber(a.clanId) < tonumber(b.clanId)
                end
            )
        end
        return true
    else
        return false
    end
end

function InboxFriendRunData:getFBCardList()
    return self.m_FBCardList
end

------------------------------------------------------------------------
-- 界面中使用的函数
function InboxFriendRunData:getLimitLevel(sendType)
    if sendType == "COIN" then
        return globalData.constantData.INBOX_FACEBOOK_COIN
    elseif sendType == "CARD" then
        return globalData.constantData.INBOX_FACEBOOK_CARD
    end
    return 0
end

-- 是否是facebook登陆
function InboxFriendRunData:isLoginFB()
    -- if CC_INBOX_FB_TEST then
    --     return true
    -- end
    -- if gLobalSendDataManager:getIsFbLogin() == true then
    --     return true
    -- end
    -- return false
    return true
end

-- 是否满足版本限制
function InboxFriendRunData:isSatisfyVersion()
    -- if CC_INBOX_FB_TEST then
    --     return true
    -- end
    -- if util_isSupportVersion("1.2.9") == true then
    --     return true
    -- end
    -- return false
    return true
end

function InboxFriendRunData:isSended(sendType, _udid)
    if _udid == nil or _udid == "" then
        return false
    end
    local sendList = self:getSendRecordList()
    if sendList[sendType] and #sendList[sendType] > 0 then
        for i = 1, #sendList[sendType] do
            if sendList[sendType][i] == _udid then
                return true
            end
        end
    end
    return false
end

return InboxFriendRunData
