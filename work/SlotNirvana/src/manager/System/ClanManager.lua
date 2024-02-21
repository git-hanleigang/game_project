-- 公会管理器
local ClanConfig = require("data.clanData.ClanConfig")
local ChatConfig = require("data.clanData.ChatConfig")
local ClanData = require("data.clanData.ClanData")
local ClanRankBenifitData = util_require("data.clanData.ClanRankBenifitData")
local SensitiveWordParser = require("utils.sensitive.SensitiveWordParser")
local Country_config = util_require("luaStdTable.Country_config")
local ClanManager = class("ClanManager")
local ClanBaseInfoData = util_require("data.clanData.ClanBaseInfoData")
local ClanSearchUserData = util_require("data.clanData.ClanSearchUserData")
local ResCacheMgr = require("GameInit.ResCacheMgr.ResCacheMgr")

local RICH_TEXT_SUFFIX = "_RichText"

function ClanManager:init()
    if not self.clanData then
        self.clanData = ClanData.new()
        self.m_rankBenifitList = {}
    end
    local ClanSyncManager = util_require("manager.System.ClanSyncManager")
    self.clanSyncManager = ClanSyncManager:getInstance()

    -- 聊天气泡弹出表示表
    self.m_popCardTipSignList = {}
    -- 公会红包选择的 人
    self.m_redGiftChooseUserList = {}
end

function ClanManager:getInstance()
    if self._instance == nil then
        self._instance = ClanManager.new()
        self._instance:init()
        self._instance:registerListener()
    end
    return self._instance
end

-- 获取公会数据
function ClanManager:getClanData()
    return self.clanData
end

function ClanManager:checkIsMember()
    local bJoinClan = self.clanData:isClanMember()
    return bJoinClan
end

function ClanManager:getLobbyBottomNum()
    local num
    local clanData = self:getClanData()
    if clanData:isClanMember() then
        local ChatManager = util_require("manager.System.ChatManager")
        -- 聊天 消息数量
        num = ChatManager:getInstance():getUnreadMessageCounts()
        -- 申请 加入公会数量
        if clanData:getUserIdentity() == ClanConfig.userIdentity.LEADER then
            num = num + clanData:getApplyCounts()
        end
    else
        -- 被公会邀请的数量
        local inviteList = clanData:getInviteList()
        num = table.nums(inviteList)
    end

    local duelData = clanData:getClanDuelData()
    if duelData and duelData:isRunning() then
        local duelRedPoints = duelData:getDuelRedPoints()
        num = num + duelRedPoints
    end

    return num
end

-- 重置公会数据(玩家被踢出公会了，http返回错误码不带公会数据)
function ClanManager:resetClanData()
    self.clanData = ClanData.new()

    local ChatManager = require("manager.System.ChatManager"):getInstance()
    -- ChatManager:setLatestChatId("0")
    ChatManager:clearMsgList()
    -- ChatManager:clearCardCache()
    ChatManager:resetChatList()

    self:requestSyncClanAct()
end

--------------------------------  公会 相关的活动数据  --------------------------------
-- 请求刷新 公会 相关的活动数据
function ClanManager:requestSyncClanAct(_actId)
    self.clanSyncManager:requestSyncClanAct(_actId)
end
--------------------------------  公会 相关的活动数据  --------------------------------

--------------------------------  获取公会基础信息  --------------------------------
-- 获取公会基础数据请求
function ClanManager:sendClanInfo(callback)
    self.clanSyncManager:requestClanInfo(callback)
end

-- 解析公会基础数据
function ClanManager:parseClanInfoData(data)
    if data then
        if self.clanData then
            self.clanData:parseClanInfoData(data)
        end

        -- 有公会再链接聊天tcp
        if self.clanData:isClanMember() then
            local ChatManager = require("manager.System.ChatManager")
            ChatManager:getInstance():onOpen()
            if not self._bOnce then
                -- 预先请求一次 聊天数据 http
                self:requestHttpChatInfo()
                self._bOnce = true
            end
        end
    else
        -- 刷新公会信息失败
    end

    self:checkBenifitData()
end

function ClanManager:getClanSimpleInfo()
    if self.clanData then
        return self.clanData:getClanSimpleInfo()
    end
end

-- 关卡spin掉落points
function ClanManager:updateClanMyPointsValue(_addPoints)
    if not self.clanData or not _addPoints then
        return
    end

    if not self.clanData:isClanMember() then
        return
    end

    local taskData = self.clanData:getTaskData()
    taskData.myPoints = self.clanData:getMyPoints() + tonumber(_addPoints)

    self.clanData:resetTaskStep()
end
--------------------------------  创建公会、修改公会信息  --------------------------------
-- 是否可以创建公会
function ClanManager:clanCreateEnable()
    if self.clanData then
        return (not self.clanData:isClanMember()) and self.clanData:canCreateClan()
    end
end
-- 是否可以编辑公会信息
function ClanManager:clanEditEnable()
    if self.clanData then
        return self.clanData:getUserIdentity() == ClanConfig.userIdentity.LEADER
    end
    return false
end

-- 编辑公会信息前 需要清空缓存
function ClanManager:clearEditCache()
    if not self.clanData then
        printError("------>    编辑公会数据 公会数据异常")
        return
    end

    self.clanEditCache = {}
    local clanSimpleData = self:getClanSimpleInfo()
    if clanSimpleData and next(clanSimpleData) then
        -- 设置默认值
        self.clanEditCache.clanId = clanSimpleData:getTeamCid() -- 公会id
        self.clanEditCache.clanName = clanSimpleData:getTeamName() -- 公会名称
        self.clanEditCache.clanLogo = clanSimpleData:getTeamLogo() -- 公会logo
        self.clanEditCache.clanDesc = clanSimpleData:getTeamDesc() -- 公会宣言
        self.clanEditCache.clanJoinType = clanSimpleData:getTeamJoinType() -- 入会限制类型
        self.clanEditCache.clanMinVip = clanSimpleData:getTeamMinVipLevel() -- 入会限制vip等级
        self.clanEditCache.countryArea = clanSimpleData:getTeamCountryArea() -- 工会所属国家地区
        self.clanEditCache.tag = clanSimpleData:getTeamTag() -- 工会标签
    else
        -- 没有公会数据 走默认模板 创建公会用
        self.clanEditCache.clanId = "" -- 公会id 传空
        self.clanEditCache.clanName = "" -- 公会名称 空 创建时设置
        self.clanEditCache.clanLogo = "1" -- 公会logo 默认第一个
        self.clanEditCache.clanDesc = "" -- 公会宣言 默认空
        self.clanEditCache.clanJoinType = ClanConfig.joinLimitType.PUBLIC -- 入会限制类型
        self.clanEditCache.clanMinVip = 1 -- 入会限制vip等级 默认1级
        self.clanEditCache.countryArea = "" -- 工会所属国家地区
        self.clanEditCache.tag = "" -- 工会标签
    end
end

-- 编辑公会名称
function ClanManager:editClanName(clanName)
    clanName = SensitiveWordParser:getString(clanName)
    self.clanEditCache.clanName = clanName
end
-- 编辑公会头像
function ClanManager:editClanLogo(clanLogo)
    self.clanEditCache.clanLogo = tostring(clanLogo)
end
-- 编辑公会宣言
function ClanManager:editClanDescription(clanDesc)
    clanDesc = SensitiveWordParser:getString(clanDesc)
    self.clanEditCache.clanDesc = clanDesc
end
-- 编辑公会加入限制类型
function ClanManager:editClanJoinLimitType(clanJoinType)
    self.clanEditCache.clanJoinType = clanJoinType
end
-- 编辑公会限制最低vip等级
function ClanManager:editClanMinVipLevel(clanMinVip)
    self.clanEditCache.clanMinVip = clanMinVip
end
-- 工会所属国家地区
function ClanManager:editClanRegionInfo(_countryArea)
    self.clanEditCache.countryArea = _countryArea
end
-- 工会标签
function ClanManager:editClanTagInfo(_tag)
    self.clanEditCache.tag = _tag
end

-- 获取编辑公会信息的缓存
function ClanManager:getClanEditInfo()
    return self.clanEditCache
end

-- 发送创建公会消息
function ClanManager:sendClanCreate()
    self.clanSyncManager:requestCreateClan()
end

-- 发送创建公会消息(花费钻石)
function ClanManager:sendClanGemCreate()
    self.clanSyncManager:requestCreateClan_Gem()
end

-- 发送修改公会名称消息
function ClanManager:sendClanNameEdit()
    self.clanSyncManager:requestClanNameEdit()
end

-- 发送编辑公会信息消息
function ClanManager:sendClanInfoEdit()
    self.clanSyncManager:requestClanInfoEdit()
end

-- 解析公会信息刷新
function ClanManager:parseClanEditResult(data)
    if data and data.clanInfo then
        self:parseClanInfoData(data.clanInfo)
    else
        -- 刷新公会信息失败
    end
end

--------------------------------  拉取公会成员列表  --------------------------------
-- 发送拉取公会成员列表消息
function ClanManager:sendClanMemberList(_successCb)
    self.clanSyncManager:requestClanMemberList(_successCb)
end

-- 解析公会成员列表信息
function ClanManager:parseClanMemberList(data)
    if data then
        if data.limit then
            self.clanData:setMemberMax(data.limit)
        end

        if data.applicants then
            self.clanData:setApplyCounts(data.applicants)
        end

        if data.users then
            self.clanData:parseClanMemberList(data.users)
        end
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_MEMBER_LIST) -- 请求接收到公会成员列表
    else
        -- 公会成员列表信息不存在
    end
end

--------------------------------  入会申请操作相关  --------------------------------
-- 拉取公会申请列表
function ClanManager:requestClanApplyList(_pageNu)
    local bJoinClan = self.clanData:isClanMember()
    if not bJoinClan then
        -- 未加入公会
        return
    end

    local userIdentity = self.clanData:getUserIdentity()
    if userIdentity ~= ClanConfig.userIdentity.LEADER then
        -- 不是会长
        return
    end

    _pageNu = _pageNu or 1
    self.clanSyncManager:requestClanApplyList(_pageNu)
end

-- 解析公会申请列表
function ClanManager:parseClanApplyList(data)
    self.applyList = {}
    if data then
        if data.limit then
            self.clanData:setMemberMax(data.limit)
        end

        if data.applicants then
            self.clanData:setApplyCounts(data.applicants)
        end

        if data.users then
            local ClanMemberData = util_require("data.clanData.ClanMemberData")
            for i=1, #data.users do
                local memberInfo = data.users[i]
                local memberData = ClanMemberData:create()
                memberData:parseData(memberInfo, "ClanUser")
                table.insert(self.applyList, memberData)
            end
        end

        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_APPLICANT_LIST) -- 请求接收到公会申请列表
    else
        -- 公会申请列表信息不存在
    end
end

-- 返回 申请列表
function ClanManager:getClanApplyList()
    return self.applyList or {}
end
--reset
function ClanManager:resetClanApplyList()
    self.applyList = {}
end

-- 发送同意入会申请消息
function ClanManager:requestClanApplyAgree(udid)
    self.clanSyncManager:requestClanApply(ClanConfig.applyAnswer.AGREE, udid)
end

-- 解析同意入会申请结果
function ClanManager:parseClanApplyAgree(udid)
    if self.applyList and next(self.applyList) then
        for idx, member in ipairs(self.applyList) do
            if tostring(member:getUdid()) == tostring(udid) then
                table.remove(self.applyList, idx)
                gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_AGREE_USER_JOIN, idx) -- 同意玩家入会
                break
            end
        end
    end

    self.clanData:setApplyCounts(#self.applyList)
end

-- 发送拒绝入会申请消息
function ClanManager:requestClanApplyRefuse(udid)
    self.clanSyncManager:requestClanApply(ClanConfig.applyAnswer.REFUSE, udid)
end

-- 拒绝入会申请返回消息处理
function ClanManager:onClanApplyRefused(udid)
    if self.applyList and next(self.applyList) then
        for idx, member in ipairs(self.applyList) do
            if tostring(member:getUdid()) == tostring(udid) then
                table.remove(self.applyList, idx)
                gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_REJECT_USER_JOIN, idx) -- 拒绝玩家入会
                break
            end
        end
    end

    self.clanData:setApplyCounts(#self.applyList)
end

-- 发送清空入会申请列表消息
function ClanManager:requestClanApplyClear()
    self.clanSyncManager:requestClanApply(ClanConfig.applyAnswer.CLEAR, "")
end

-- 清空入会申请列表消息返回处理
function ClanManager:onClanApplyClear()
    self.applyList = {}
    self.clanData:setApplyCounts(#self.applyList)
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_APPLICANT_CLEAR) -- 清空公会申请列表
end

--------------------------------  玩家离开公会相关  --------------------------------
-- 踢出玩家
function ClanManager:requestKickMember(udid)
    if udid then
        self.clanSyncManager:requestKickMember(udid)
    end
end

-- 踢出玩家后的成员列表刷新
function ClanManager:parseKickMember(data)
    if data then
        self:parseClanMemberList(data)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_MEMBER_LIST) -- 刷新成员列表
    end
end

-- 玩家离开公会请求
function ClanManager:requestLeaveClan()
    self.clanSyncManager:requestLeaveClan()
end

-- 玩家离开公会后 刷新自己公会信息
function ClanManager:parseLeaveClan(data)
    self:resetClanData()
    gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化

    if data and data.clanInfo then
        self.clanData:parseClanInfoData(data.clanInfo)
    end

    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_USER_LEAVE_CLAN) -- 收到 玩家 退出公会
end

--------------------------------  搜索公会列表相关  --------------------------------
-- 获取公会列表请求
function ClanManager:sendClanSearch(_clanStr, _pageNu)
    if _clanStr then
        self.m_clanSearchStr = ""
        self.clanSyncManager:requestClanSearch(_clanStr, _pageNu)
    end
end

-- 解析公会搜索列表
function ClanManager:parseClanSearchList(data, searchStr)
    self.searchResult = {}
    if data then
        for i,clanInfo in ipairs(data) do
            local data = ClanBaseInfoData:create()
            data:parseData(clanInfo.clan)
            data:setCurMemberCount(clanInfo.current)
            data:setLimitMemberCount(clanInfo.limit)
            table.insert(self.searchResult, data)
        end
    end

    self.m_clanSearchStr = searchStr
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_SEARCH) -- 搜索 公会 成功事件
end
-- 搜索 公会的 搜索文本
function ClanManager:getCurClanSearchStr()
    return self.m_clanSearchStr or ""
end
function ClanManager:resetCurClanSearchStr()
    self.m_clanSearchStr = ""
end
-- 获取公会搜索列表
function ClanManager:getClanSearchList()
    return self.searchResult
end
-- reset
function ClanManager:resetClanSearchList()
    self.searchResult = {}
end
--------------------------------  搜索公会列表相关  --------------------------------

-- 快速加入公会
function ClanManager:requestClanQuickJoin()
    self.clanSyncManager:requestClanQuickJoin()
end

-- 加入公会请求
function ClanManager:requestClanJoin(clanId)
    if clanId then
        self.clanSyncManager:requestClanJoin(clanId)
    end
end

-- 加入公会成功 刷新公会基础信息
function ClanManager:parseClanJoinResult(data)
    if data and data.clanInfo then
        self:parseClanInfoData(data.clanInfo)
    else
        -- 刷新公会信息失败
    end
end

-- 搜索玩家
function ClanManager:requestSearchUser(content, pageNu)
    if not content or content == "" then
        return
    end

    self.m_userSearchStr = ""
    self.clanSyncManager:requestSearchUser(content, pageNu)
end

-- 搜索玩家结果
function ClanManager:parseSearchUserList(data, searchStr)
    self.m_searchMemberList = {}
    if data and data.user then
        self.m_userSearchStr = searchStr

        for i,member in ipairs(data.user) do
            local searchUserData = ClanSearchUserData:create()
            searchUserData:parseData(member)
            
            table.insert( self.m_searchMemberList, searchUserData )
        end
    end

    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_SEARCH_USER_SUCCESS) -- 搜索玩家 成功事件
end

-- 搜索 公会的 搜索文本
function ClanManager:getCurUserSearchStr()
    return self.m_userSearchStr or ""
end
function ClanManager:resetCurUserSearchStr()
    self.m_userSearchStr = ""
end

-- 搜索成员列表
function ClanManager:getSearchUserList()
    return self.m_searchMemberList
end
-- reset
function ClanManager:resetSearchUserList()
    self.m_searchMemberList = {}
end

-- 邀请玩家
function ClanManager:requestUserInvite(udid)
    if udid then
        self.clanSyncManager:requestUserInvite(udid)
    end
end

-- 邀请玩家消息返回
function ClanManager:onUserInvite(udid)
    if not udid then
        return
    end
    for idx, userInfo in ipairs(self.m_searchMemberList) do
        if userInfo.udid == udid then
            userInfo.status = ClanConfig.userState.APPLY
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_INVITE_USER_SUCCESS, idx) -- 邀请玩家 成功事件
            break
        end
    end
end

-- 拉取推荐公会列表
function ClanManager:requestRecommendClanList(pageNu)
    self.clanSyncManager:requestRecommendClanList(pageNu)
end

-- 解析推荐公会列表
function ClanManager:parseRecommendClanList(data)
    self:parseClanSearchList(data)
end

-- 拒绝加入被邀请公会
function ClanManager:requestRejectInviteClan(_inviteUdid)
    if _inviteUdid then
        self.clanSyncManager:requestRejectInviteClan(_inviteUdid)
    end
end
-- 删除 拒绝的公会信息
function ClanManager:parseInviteListRemoveUdid(_inviteUdid)
    local inviteList = self.clanData:getInviteList()
    if #inviteList <= 0 then
        return
    end

    for idx, info in pairs(inviteList) do
        if info:getInviteUdid() == _inviteUdid then
            table.remove(inviteList, idx)
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_REJECT_JOIN_CLAN_SUCCESS, idx) -- 拒绝公会 成功事件
            return
        end
    end
end

--------------------------------  公会奖励领取相关  --------------------------------
-- 任务奖励领取
function ClanManager:requestTaskReward(_callBack)
    if not self:isDownLoadRes() then
        return false
    end

    self.clanSyncManager:requestTaskReward(_callBack)
end

-- 解析任务奖励
function ClanManager:parseTaskReward(data, _callback)
    _callback = _callback or function()
        end
    if not data then
        _callback()
        return
    end

    local sign = self.clanData:getLastTaskSign()
    local view = nil
    if sign == ClanConfig.LastTaskState.UNDONE then
        view = self:popTaskRewardUndonePanel(data)
    elseif sign == ClanConfig.LastTaskState.DONE then
        view = self:popTaskRewardDonePanel(data)
    end

    -- 界面关闭回调
    if view then
        view:setViewOverFunc(_callback)
    else
        _callback()
    end

    if data.clanInfo then
        self:parseClanInfoData(data.clanInfo)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)
    end

    self.clanData:resetLastTaskSign()
end

-- 请求fb分享邀请接口
function ClanManager:requestFbInvite(_clanId, _udid)
    if not self:isUnlock() then
        return
    end

    if _clanId and _udid then
        self.clanSyncManager:requestFbInvite(_clanId, _udid)
    end
end

-------------------------------- 公会聊天 --------------------------------
-- 请求公会聊天服务器配置数据
function ClanManager:requestChatServerInfo()
    if self.m_bRequestIng then
        return
    end

    self.m_bRequestIng = true
    local endCb = function()
        self.m_bRequestIng = false
    end
    self.clanSyncManager:requestChatServerInfo(endCb)
end

-- 获取聊天奖励数据
function ClanManager:requestChatReward(msgId, msgDign)
    if msgId and string.len(msgId) > 0 and msgDign and string.len(msgDign) > 0 then
        self.clanSyncManager:requestChatReward(msgId, msgDign)
    else
        printInfo("获取消息奖励数据 信息不全 不能发送")
    end
end
-- 获取聊天奖励数据 - 一键领取
function ClanManager:requestCollectAllGiftReward(msgIdList, randomSignList)
    if not next(msgIdList) or not next(randomSignList) then
        return
    end
    self.clanSyncManager:requestCollectAllGiftReward(msgIdList, randomSignList)
end

-- 公会聊天发送要卡消息
function ClanManager:requestCardNeeded(albumId, cardId, successCall, failedCall)
    if albumId and string.len(albumId) > 0 and cardId and string.len(cardId) > 0 then
        self.clanSyncManager:requestCardNeeded(albumId, cardId, successCall, failedCall)
    else
        if failedCall then
            failedCall()
        end
        printInfo("公会聊天发送要卡消息 信息不全 不能发送")
    end
end

-- 公会聊天查询卡牌数量
function ClanManager:requestCardsData(cardList)
    if cardList and table.nums(cardList) > 0 then
        self.clanSyncManager:requestCardsData(cardList)
    else
        printInfo("公会聊天查询卡牌数量 信息不全 不能发送")
    end
end

-- 公会聊天发送赠卡消息
function ClanManager:requestCardGiven(receiver, cardId, msgId)
    if receiver and string.len(receiver) > 0 and cardId and string.len(cardId) > 0 and msgId and string.len(msgId) > 0 then
        self.clanSyncManager:requestCardGiven(receiver, cardId, msgId)
    else
        printInfo("公会聊天发送赠卡消息 信息不全 不能发送")
    end
end

-- 请求聊天记录HTTP
function ClanManager:requestHttpChatInfo(successCall, failedCall)
    self.clanSyncManager:requestHttpChatInfo(successCall, failedCall)
end
-------------------------------- 公会聊天 --------------------------------

-------------------------------- 公会排行榜 --------------------------------
-- 公会请求排行榜信息
function ClanManager:sendClanRankReq()
    local rankData = self.clanData:getClanRankData()
    local list = rankData:getRankRewardDataList()
    if #list == 0 then
        gLobalViewManager:addLoadingAnima(false, 1)
    end
    self.clanSyncManager:sendClanRankReq(#list == 0)
end
function ClanManager:parseClanRankData(_rankInfo)
    self.clanData:parseClanRankData(_rankInfo)
end
function ClanManager:syncMyRankInfo(_rankCellData)
    if not _rankCellData then
        return
    end

    self.clanData:syncMyRankInfo(_rankCellData)
end

-- 公会排行段位 图 icon
function ClanManager:getRankDivisionIconPath(_division)
    _division = math.max(1, tonumber(_division) or 1)

    return ClanConfig.RANK_RESOURCE_PATH.ICON[_division] or ClanConfig.RANK_RESOURCE_PATH.ICON[#ClanConfig.RANK_RESOURCE_PATH.ICON]
end
-- 公会排行段位 图 desc
function ClanManager:getRankDivisionDescPath(_division)
    _division = math.max(1, tonumber(_division) or 1)

    return ClanConfig.RANK_RESOURCE_PATH.DESC[_division] or ClanConfig.RANK_RESOURCE_PATH.DESC[#ClanConfig.RANK_RESOURCE_PATH.DESC]
end
-- 公会排行段位 文本 desc
function ClanManager:getRankDivisionDesc(_division)
    _division = math.max(1, tonumber(_division) or 1)

    return ClanConfig.RANK_DIVISION_DESC[_division] or ClanConfig.RANK_DIVISION_DESC[#ClanConfig.RANK_DIVISION_DESC]
end

-- 公会请求段位权益信息
function ClanManager:sendClanBenifitReq()
    self.m_bReqBenifitReq = true
    local recieveReqCB = function()
        self.m_bReqBenifitReq = false
    end
    self.clanSyncManager:sendClanBenifitReq(recieveReqCB, recieveReqCB)
end
function ClanManager:checkBenifitData()
    if #self.m_rankBenifitList > 0 or self.m_bReqBenifitReq then
        return
    end

    self:sendClanBenifitReq()
end
function ClanManager:parseClanBenifitData(_benifitList)
    if not _benifitList then
        return
    end

    self.m_rankBenifitList = {}
    for i = #_benifitList, 1, -1 do
        -- 倒序
        local data = _benifitList[i]
        local benifitData = ClanRankBenifitData:create()
        benifitData:parseData(data)
        table.insert(self.m_rankBenifitList, benifitData)
    end
end
function ClanManager:getClanBenifitList()
    self:checkBenifitData()
    return self.m_rankBenifitList
end
function ClanManager:resetBenifitList()
    self.m_rankBenifitList = {}
end

-- 显示公会权益界面
function ClanManager:showRankBenifitLayer()
    local benifitList = self:getClanBenifitList()
    if not benifitList or #benifitList <= 0 then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanRankBenefitLayer") then
        return
    end

    local view = util_createView("views.clan.rank.ClanRankBenefitLayer", benifitList)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 排行榜结算后段位变化
function ClanManager:checkPopRankUpDownLayer(_cb)
    if self.m_hadPopUpDownLayer then
        return
    end
    if not self.clanData then
        return
    end

    if not self.clanData:checkInitServerData() then
        return
    end

    local bJoinClan = self.clanData:isClanMember()
    if not bJoinClan then
        return
    end

    local selfRankInfo = self.clanData:getSelfClanRankInfo()
    if selfRankInfo.bPopReportLayer then
        return
    end

    local benifitData = selfRankInfo.benifitData
    if not benifitData then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanRankReportLayer") then
        return
    end

    local view = util_createView("views.clan.rank.ClanRankReportLayer", selfRankInfo, _cb)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI + 1)
    self.m_hadPopUpDownLayer = true

    return view
end

-- 弹出 开启宝箱时间变化提示弹板
function ClanManager:popOpenTimeChangeLayer()
    if true then
        -- cxc 2022年06月13日12:01:51  提示弹板功能不要了delete
        return
    end
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterHomeTip.id) -- 第一次进入公会主页
    if bFinish then
        return
    end
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterHomeTip)

    if gLobalViewManager:getViewByExtendData("ClanOpenTimeChangeTipLayer") then
        return
    end

    local view = util_createView("views.clan.ClanOpenTimeChangeTipLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 公会 当前段位 排行奖励 1 - 10th
function ClanManager:popCurDivisionRankRewardInfoLayer()
    local rankData = self.clanData:getClanRankData()
    local selfRankInfo = self.clanData:getSelfClanRankInfo()
    local list = rankData:getRankRewardDataList()
    if gLobalViewManager:getViewByExtendData("ClanRankRewardsInfoLayer") then
        return
    end

    local view = util_createView("views.clan.rank.ClanRankRewardsInfoLayer", list, selfRankInfo.rank)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 最强工会列表
function ClanManager:popTopRankTeamListLayer(_type)
    -- local topRankData = self.clanData:getRankTopListData()
    if gLobalViewManager:getViewByExtendData("ClanRankTopListLayer") then
        return
    end

    local view = util_createView("views.clan.rank.topTeam.ClanRankTopListLayer", _type)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 重置公会排行结算sign
function ClanManager:sendResetPopReprotSign()
    self.clanData:resetPopReportLayerSign()
    self.clanSyncManager:sendResetPopReprotSign()
end

-- 请求本公会 各玩家排行奖励
function ClanManager:sendMemberRankRewardListReq()
    self.clanSyncManager:sendMemberRankRewardListReq()
end
function ClanManager:parseRankMemberRewardData(_memberRewards)
    self.clanData:parseRankMemberRewardData(_memberRewards)
end

-- 请求 最强工会排行信息
function ClanManager:sendeRankTopListDataReq()
    local topRankData = self.clanData:getRankTopListData()
    local topMembersData = self.clanData:getRankTopMembersListData()
    local list = topRankData:getTeamRankList()
    local topMembersList = topMembersData:getTeamRankList()
    local leftTime = self.clanData:getClanLeftTime()
    if #list > 0 and #topMembersList > 0 and leftTime > 0 then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_TOP_RANK_LIST_SUCCESS)
        return
    end

    self.clanSyncManager:sendeRankTopListDataReq()
end
function ClanManager:parseRankTopListData(_data)
    self.clanData:parseRankTopListData(_data)
end

function ClanManager:parseRankTopMembersListData(_data)
    self.clanData:parseRankTopMembersListData(_data)
end
-------------------------------- 公会排行榜 --------------------------------

-------------------------------- 公会Rush挑战任务 --------------------------------
-- 请求 公会Rush挑战任务信息
function ClanManager:sendTeamRushInfoReqest()
    self.clanSyncManager:sendTeamRushInfoReqest()
end
function ClanManager:parseRushData(_data)
    self.clanData:parseRushData(_data)
end
function ClanManager:popTeamRushMainLayer()
    local rushData = self.clanData:getTeamRushData()
    if not rushData:isRunning() then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanRushMainLayer") then
        return
    end

    local view = util_createView("views.clan.rush.ClanRushMainLayer", rushData)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
-- 改变公会rush任务图标
function ClanManager:changeTeamRushTaskIcon(_refNode, _iconPath)
    if not _refNode or not _iconPath then
        return
    end
    _refNode:setVisible(false)
    local refSize = _refNode:getContentSize()
    local spIcon = _refNode:getParent():getChildByName("RushTaskIcon")
    if not spIcon then
        spIcon = display.newSprite()
    end
    local bSuccess = util_changeTexture(spIcon, _iconPath)
    if not bSuccess then
        release_print("公会rush任务没有对应图标:", _iconPath)
        return
    end
    spIcon:addTo(_refNode:getParent())
    spIcon:setName("RushTaskIcon")

    local size = spIcon:getContentSize()
    spIcon:setScale(refSize.width / size.width)
    spIcon:setPosition(_refNode:getPosition())
end
-- 公会rush任务跳转到对应功能
function ClanManager:rushTaskJumpToOtherFeature(_taskType, _actName)
    _actName = _actName or ""
    local view = nil
    if _taskType == ClanConfig.RushTaskType.ACT then
        -- 1001 大活动消耗道具
        local actMgr = G_GetMgr(_actName)
        if not actMgr then
            return
        end
        view = actMgr:showMainLayer()
    elseif _taskType == ClanConfig.RushTaskType.QUEST then
        -- 1002 quest完成关卡
        view = G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
    elseif _taskType == ClanConfig.RushTaskType.CHIP then
        -- 1003 集卡收集赠送
        if CardSysManager:isDownLoadCardRes() then
            CardSysManager:enterCardCollectionSys()
        end
    end
end
function ClanManager:ClanRushTaskReportLayer()
    local rushData = self.clanData:getTeamRushData()
    if not rushData:isRunning() then
        return
    end

    local bCompleteCurTask = rushData:isCompleteCurTask()
    if not bCompleteCurTask then
        return
    end
    
    if gLobalViewManager:getViewByExtendData("ClanRushTaskReportLayer") then
        rushData:resetRecordData()
        return
    end

    local view = util_createView("views.clan.rush.ClanRushTaskReportLayer", rushData)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    rushData:resetRecordData()
    return view
end
-------------------------------- 公会Rush挑战任务 --------------------------------

-- 玩家退出公会界面
function ClanManager:onQuit()
    -- 需要在退出时 清理一下卡牌数据缓存
    local ChatManager = require("manager.System.ChatManager")
    ChatManager:getInstance():clearCardCache()
end

--------------------------------  公会逻辑  --------------------------------
-- 检查要不要 弹出上一次结算 的奖励
function ClanManager:checkShowTaskReward()
    local bPopPointsReward = self.clanData:willShowTaskReward()
    return bPopPointsReward
end

-- 挑战活动领奖面板
function ClanManager:popChallengeRewardPanel(_rewards)
    if not _rewards.coins or not _rewards.items then
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        --弹窗逻辑执行下一个事件
        return
    end
    local view = util_createView("views.clan.ClanChallengeRewardPanel", _rewards)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 公会任务完成奖励面板
function ClanManager:popTaskRewardDonePanel(_rewards)
    if not _rewards.coins or not _rewards.items then
        return
    end
    local view = util_createView("views.clan.taskReward.ClanTaskRewardDonePanel", _rewards)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 公会任务未完成  面板
function ClanManager:popTaskRewardUndonePanel(_rewards)
    if not _rewards.coins or tonumber(_rewards.coins) <= 0 then
        return
    end

    local view = util_createView("views.clan.taskReward.ClanTaskRewardUndonePanel", _rewards)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ClanManager:enterClanSystem(_sysType, _cb)
    if not self:isDownLoadRes() then
        return
    end
    if not self.clanData:checkInitServerData() then
        return
    end

    local bPopPointsReward = self:checkShowTaskReward()
    if bPopPointsReward then
        local enterSys = function()
            self:enterClanSystem(_sysType, _cb)
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.REFRESH_ENTRY_UI) -- 刷新关卡入口UI
        end
        self:requestTaskReward(enterSys)
        return
    end

    local bJoinClan = self.clanData:isClanMember()
    local view = nil
    if bJoinClan then
        -- 公会主面板
        view = self:showHomeView(_sysType, _cb)
    else
        -- 公会招募大厅面板
        view = self:showRecuritView(_cb)
    end
    
    if view then
        view:setViewOverFunc(_cb)
    end

    if view then
        gLobalSoundManager:playSubmodBgm(ClanConfig.MUSIC_ENUM.BG, self.__cname, ViewZorder.ZORDER_UI)
        view:setOverFunc(_cb)
    end

    return view
end

-- 退出公会
function ClanManager:exitClanSystem()
    gLobalSoundManager:removeSubmodBgm(self.__cname)
    ResCacheMgr:getInstance():removeUnusedResCache()
    ProtoConfig.REQUEST_CLAN_MEMBER.preReqTime = nil 
    ProtoConfig.REQUEST_MEMBER_RANK_REWARD.preReqTime = nil 
end

-- 显示公会主界面
function ClanManager:showHomeView(_sysType, _cb)
    if gLobalViewManager:getViewByExtendData("ClanHomeView") then
        return
    end

    local view = util_createView("views.clan.ClanHomeView", _sysType)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示公会招募大厅界面
function ClanManager:showRecuritView(_cb)
    if gLobalViewManager:getViewByExtendData("ClanRecuritHallView") then
        return
    end

    local view = util_createView("views.clan.ClanRecuritHallView")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 弹出 公会基本信息面板
function ClanManager:popClanBaseInfoPanel(_simpleInfo)
    local view = util_createView("views.clan.baseInfo.ClanSimpleInfoPanel", _simpleInfo)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 弹出创建/修改公会界面
function ClanManager:popEditClanInfoPanel(_simpleInfo)
    local view = util_createView("views.clan.baseInfo.ClanEditClanInfoPanel", _simpleInfo)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 弹出搜索公会面板
function ClanManager:popSearchClanPanel()
    local view = util_createView("views.clan.recurit.ClanSearchPanel")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 显示统一提示面板
-- _params -- ProtoConfig.ErrorTipEnum
function ClanManager:popCommonTipPanel(_params, _confirmCB, _cancelCB)
    if not self:isDownLoadRes() then
        return
    end

    if not _params or not _params.content then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanCommonTipPanel") then
        return
    end

    local view = util_createView("views.clan.ClanCommonTipPanel", _params)
    view:setConfirmCB(_confirmCB)
    view:setCancelCB(_cancelCB)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ClanManager:popGemCreatePanel()
    local view = util_createView("views.clan.ClanCreateGemTipPanel")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 显示规则面板
function ClanManager:popClanRulePanel()
    local view = util_createView("views.clan.ClanRulePanel")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 显示grandShare图片 详情信息面板
function ClanManager:popGrandShareImgLayer(_imgPath, _msgId)
    if not _imgPath then
        return
    end
    local view = util_createView("views.clan.chat.ClanGrandShareImgLayer", _imgPath, _msgId)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 显示邀请界面面板
function ClanManager:popClanInviteListPanel(bCheck)
    local inviteList = self.clanData:getInviteList()
    if bCheck and #inviteList <= 0 then
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        --弹窗逻辑执行下一个事件
        return
    end

    local view = util_createView("views.clan.recurit.ClanInviteListPanel", bCheck)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 公会关卡内入口
function ClanManager:createMachineEntryNode()
    if not self:isUnlock() then
        return
    end

    local view = util_createView("views.clan.ClanMachineEntryNode")
    return view
end

-- 判断资源是否下载
function ClanManager:isDownLoadRes()
    if self.m_bDownLoad then
        return true
    end

    if globalDynamicDLControl:checkDownloading("Club_res") then
        return false
    end

    self.m_bDownLoad = cc.FileUtils:getInstance():isFileExist("Club/csd/GameSceneUiNode.csb")

    return self.m_bDownLoad
end

-- 公会是否unlock
function ClanManager:isUnlock()
    local curLevel = globalData.userRunData.levelNum
    local lockLevel = globalData.constantData.CLAN_OPEN_LEVEL or 20
    return curLevel >= lockLevel
end

-- 显示引导 layer
function ClanManager:showGuideLayer(_guideId, _curIdNodeList)
    if not tolua.isnull(self.m_guideLayer) then
        self.m_guideLayer:removeSelf()
    end

    if not _curIdNodeList then
        return
    end

    self.m_guideLayer = util_createView("views.clan.ClanGuideLayer", _guideId)
    gLobalViewManager:getViewLayer():addChild(self.m_guideLayer, ViewZorder.ZORDER_GUIDE + 1)
    self.m_guideLayer:setCurGuideIdNodeList(_guideId, _curIdNodeList)
    self.m_guideLayer:showStep()
end

-- 更新关卡内 入口的进度
function ClanManager:updateEntryProgUI()
    local node = gLobalActivityManager:getEntryNode("ClanEntryNode")
    if not node then
        return
    end

    local startPos = display.center
    local endPos = nil
    local _isVisible = gLobalActivityManager:getEntryNodeVisible("ClanEntryNode")
    if not _isVisible then
        -- 隐藏图标的时候使用箭头坐标
        endPos = gLobalActivityManager:getEntryArrowWorldPos()
    else
        endPos = node:getFlyEndPos()
    end

    -- local nodeTeamPoint = display.newSprite("Club/ui/logo/logo_member.png")
    local nodeTeamPoint = util_createAnimation("Club/csd/Clubflyicon.csb")
    local particle_ef = nodeTeamPoint:findChild("Particle_1")
    if particle_ef then
        particle_ef:setPositionType(0)
    end
    nodeTeamPoint:playAction("fly", true)
    nodeTeamPoint:move(display.center)
    nodeTeamPoint:setScale(1)
    gLobalViewManager:showUI(nodeTeamPoint, ViewZorder.ZORDER_GUIDE, false)

    ---------------------------------- cxc flyAction 跟大活动一样 ----------------------------------
    local moveTime = 1
    local start_scale = 0.5
    -- 随机一个区域
    local off_1 = math.random(1, 200 * start_scale)
    local off_2 = math.random(1, 100 * start_scale)
    -- 这里给曲线匹配一个方向(相当于给原曲线做了一个轴对称的反转)
    local x_param = (endPos.x - startPos.x) / math.abs(endPos.x - startPos.x)
    local y_param = (endPos.y - startPos.y) / math.abs(endPos.y - startPos.y)
    -- 位移
    local control_1 = cc.p(startPos.x + 60 * x_param, startPos.y + (200 + off_1) * y_param)
    local control_2 = cc.p(endPos.x - 200 * x_param, endPos.y - (100 + off_2) * y_param)
    local bezierTo = cc.BezierTo:create(moveTime, {control_1, control_2, endPos})
    local ease = cc.EaseSineInOut:create(bezierTo)
    -- 缩放
    local scale_pre =
        cc.CallFunc:create(
        function()
            -- 节点的初始状态
            if not tolua.isnull(nodeTeamPoint) then
                nodeTeamPoint:setVisible(true)
                nodeTeamPoint:setScale(start_scale)
            end
        end
    )
    local scale1 = cc.ScaleTo:create(5 / 30, start_scale + 0.5)
    local scale2 = cc.ScaleTo:create(15 / 30, 0.7)
    local scale_delay = cc.DelayTime:create(10 / 30)
    local scale_seq = cc.Sequence:create(scale_pre, scale1, scale2, scale_delay)

    -- 透明度
    local opacity_pre =
        cc.CallFunc:create(
        function()
            if not tolua.isnull(nodeTeamPoint) then
                nodeTeamPoint:setOpacity(255)
            end
        end
    )
    local opacity1 = cc.FadeTo:create(5 / 30, 255)
    local opacity_delay = cc.DelayTime:create(17 / 30)
    local opacity2 = cc.FadeTo:create(8 / 30, 0 * 255)
    local flyEnd =
        cc.CallFunc:create(
        function()
            -- 更新关卡内入口的进度
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.UPDATE_MACHINE_ENTRY_PROG)
            if not tolua.isnull(nodeTeamPoint) then
                nodeTeamPoint:removeSelf()
            end
        end
    )
    local opacity_seq = cc.Sequence:create(opacity_pre, opacity1, opacity_delay, opacity2, flyEnd)
    local spawn = cc.Spawn:create(ease, scale_seq, opacity_seq)

    ---------------------------------- cxc flyAction 跟大活动一样 ----------------------------------

    nodeTeamPoint:runAction(cc.Sequence:create(spawn))
end

-- 获取 公会 logo 资源路径
function ClanManager:getClanLogoBgImgPath(_clanLogo, _bSelect)
    _clanLogo = tonumber(_clanLogo) or 1
    if _clanLogo > ClanConfig.MAX_LOGO_COUNT then
        _clanLogo = ClanConfig.MAX_LOGO_COUNT
    end

    -- 紫： 1-6
    -- 蓝： 7-12
    -- 黄： 13-18
    -- 红： 19-25
    local bgIdx = math.floor((_clanLogo - 1) / 5) + 1
    local imgPath = "Club/ui_new/Logo/logo_1/gonghui_logo" .. bgIdx .. ".png"
    if _bSelect then
        imgPath = "Club/ui_new/Logo/logo_1/logo" .. bgIdx .. "_di_xuanzhong.png"
    end
    return imgPath
end

-- 获取 公会 logo 资源路径
function ClanManager:getClanLogoImgPath(_clanLogo)
    _clanLogo = tonumber(_clanLogo) or 1
    if _clanLogo > ClanConfig.MAX_LOGO_COUNT then
        _clanLogo = ClanConfig.MAX_LOGO_COUNT
    end

    local imgPath = "Club/ui_new/Logo/logo_1/logo" .. (_clanLogo - 1) .. ".png"
    return imgPath
end

-- 创建 richText
function ClanManager:createSearchRichText(_handleStr, _refNode, _filterStr, _richType)
    if not _refNode or not _handleStr then
        return
    end

    local parent = _refNode:getParent()
    _refNode:setVisible(true)
    local richTextName = _refNode:getName() .. RICH_TEXT_SUFFIX
    parent:removeChildByName(richTextName)

    local filterStr = _filterStr
    if not filterStr or #filterStr < 1 then
        return
    end

    local tempHandleStr = string.lower(_handleStr)
    local tempFilterStr = string.lower(_filterStr)
    local splitStrList = string.split(tempHandleStr, tempFilterStr) or {}
    if #splitStrList <= 1 then
        return
    end

    local elementList = {}
    _richType = _richType or 4
    local richTypeTemp = {
        [1] = {type = 1, color = cc.WHITE, opacity = 255, str = "", font = "", fontSize = 38, flag = 2},
        [4] = {type = 1, color = cc.c3b(98, 40, 184), opacity = 255, str = "", font = "CommonButton/font/Neuron Heavy_2.ttf", fontSize = 40, flag = 2}
    }

    local startIdx = 1
    for idx, subStr in ipairs(splitStrList) do
        if #subStr > 0 then
            local info = clone(richTypeTemp[_richType])
            info.str = string.sub(_handleStr, startIdx, startIdx + #subStr - 1)
            table.insert(elementList, info)
            startIdx = startIdx + #subStr
        end
        if idx < #splitStrList then
            local info = clone(richTypeTemp[_richType])
            info.str = string.sub(_handleStr, startIdx, startIdx + #filterStr - 1)
            info.color = cc.c3b(255, 110, 0)
            table.insert(elementList, info)
            startIdx = startIdx + #filterStr
        end
    end
    local info = {}
    info.list = elementList
    info.alignment = 0 --左对齐
    local richText = util_createRichText(info)
    richText:setName(richTextName)
    richText:ignoreContentAdaptWithSize(true)
    richText:addTo(parent)
    richText:move(_refNode:getPosition())
    richText:setScale(_refNode:getScaleX())
    richText:setAnchorPoint(_refNode:getAnchorPoint())

    _refNode:setVisible(false)

    return richText
end

-- 公会推荐列表刷新倒计时
function ClanManager:onSearchRefresh()
    self.refresh_timeEnd = math.floor(globalData.userRunData.p_serverTime / 1000) + 10
end

-- 公会推荐列表刷新倒计时
function ClanManager:getRefreshTimer()
    return self.refresh_timeEnd or 0
end

-- 公会推荐列表能否刷新
function ClanManager:getRefreshEnabled()
    if self.refresh_timeEnd and self.refresh_timeEnd >= math.floor(globalData.userRunData.p_serverTime / 1000) then
        return false
    end
    return true
end

-- 关卡内弹出 宝箱升级动画面板
function ClanManager:checkRewardBoxPop()
    local clanData = self:getClanData()
    if not clanData then
        return false
    end

    local taskData = clanData:getTaskData()
    if not taskData then
        return false
    end

    if self.curStep == nil then
        self.curStep = taskData.curStep
    end

    if self.curStep ~= taskData.curStep then
        self.curStep = taskData.curStep
        return true
    end
end
function ClanManager:setCurStep(_step)
    self.curStep = _step
end
function ClanManager:showRewardBoxPop()
    local view = util_createView("views.clan.ClanRewardPop")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 公会索要卡片的CD
function ClanManager:setReqCardCD(_cd)
    local clanData = self:getClanData()
    if not clanData then
        return
    end

    clanData:setReqCardCD(_cd)
end
function ClanManager:getReqCardCD()
    local clanData = self:getClanData()
    if not clanData then
        return 0
    end

    return clanData:getReqCardCD()
end

function ClanManager:isHadPopCardTip()
    local cd = self:getReqCardCD()
    return self.m_popCardTipSignList[cd .. ""]
end
function ClanManager:setHadPopCardTip(_cd)
    if not _cd then
        return
    end

    self.m_popCardTipSignList[tostring(_cd)] = true
end

-- 当前公会显示的 系统页签（主界面，聊天， 成员）
function ClanManager:setCurSystemShowType(_type)
    self.m_systemType = _type
end
function ClanManager:getCurSystemShowType()
    return self.m_systemType
end

function ClanManager:checkSupportAppVersion(_bPopDownload)
    ---------cxc2021年09月03日11:57:34---------
    -- 就算上了 也不一定开coming soon
    if not globalData.constantData.CLAN_OPEN_SIGN then
        return false
    end
    ---------cxc2021年09月03日11:57:34---------

    local bSupport = true
    if device.platform == "ios" then
        bSupport = util_isSupportVersion("1.6.0")
    elseif device.platform == "android" then
        bSupport = util_isSupportVersion("1.5.3")
    end

    if bSupport then
        return true
    end

    if _bPopDownload then
        gLobalViewManager:showDialog(
            "Dialog/NewVersionLayerClan.csb",
            function()
                xcyy.GameBridgeLua:rateUsForSetting()
            end,
            nil,
            nil,
            nil
        )
    end

    return false
end

-- 我被会长踢了
function ClanManager:kickOffByLeader()
    gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化
    self:resetClanData()

    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)

    if not gLobalViewManager:getViewByExtendData("ClanHomeView") then
        return
    end
    self:popCommonTipPanel(ProtoConfig.ErrorTipEnum.KICKED_OFF_TEAM)
end

-- 会长同意了我的加入
function ClanManager:notifyLeaderAgreeSelfJoin()
    self:sendClanInfo()
end

-- 会长信息
function ClanManager:setLearderUdid(_udid)
    self.m_leaderUdid = _udid
end
function ClanManager:getLearderUdid()
    return self.m_leaderUdid or ""
end

-- 登录大厅尝试弹出 公会大厅界面
function ClanManager:logonAutoPopRecuritHallView()
    if not self.clanData:checkInitServerData() then
        return
    end
    -- 14,ClanRemindOpenLevel,45,未加入公会提醒弹窗最低弹出等级>= 15,ClanRemindOpenTimes,5,未加入公会提醒弹窗最多弹出次数>
    local bJoinClan = self.clanData:isClanMember()
    if bJoinClan then
        return
    end

    local curDate = os.date("*t")
    local dateKey = string.format("%d%02d%02d", curDate.year, curDate.month, curDate.day)
    local curKey = "PopClanRecurit_" .. dateKey
    local saveKey = gLobalDataManager:getStringByField("PopClanRecuritKey", "")
    local saveDay = string.split(saveKey, "_")[2] or ""
    if #saveDay > 0 and tonumber(saveDay) < tonumber(dateKey) then
        gLobalDataManager:delValueByField(saveKey)
    elseif saveDay == "" then
        gLobalDataManager:setNumberByField("PopClanRecuritKey", curKey)
    end

    local hadPopTimes = gLobalDataManager:getNumberByField(curKey, 0)
    if hadPopTimes >= globalData.constantData.CLAN_REMIND_OPEN_TIMES then
        return
    end

    -- 公会招募大厅面板
    self:enterClanSystem(nil, function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end)
    gLobalDataManager:setNumberByField(curKey, hadPopTimes + 1)
    return true
end

-- 生成公会名字
function ClanManager:generateClanRandomName()
    local uidStr = tostring(globalData.userRunData.loginUserData.displayUid)
    local number = tonumber(string.sub(uidStr, -util_random(4, 8)))
    number = number + util_random(0, 10)
    return "CASHTEAM" .. number
end

function ClanManager:parseNewUser7DayData(_data)
    if not _data then
        return
    end
    if _data:HasField("vegasTrip") then
        G_GetMgr(G_REF.NewUser7Day):parseData(_data.vegasTrip)
    end
end

------------------ 公会切换职位 ------------------
-- 会长更改成员职位
function ClanManager:sendChangePositionReq(_memberUdid, _positionStr)
    self.clanSyncManager:sendChangePositionReq(_memberUdid, _positionStr)
end
-- 同步新老职位信息
function ClanManager:sendSyncSelfPositionReq()
    local clanData = self:getClanData()
    clanData:resetUserIdentityOld()
    self.clanSyncManager:sendSyncSelfPositionReq()
end
-- 监测 是否可以弹出  会长 任命成员职位 UI
function ClanManager:checkCanPopPositionFloatView(_memberData)
    local selfPosition = self.clanData:getUserIdentity()
    if selfPosition ~= ClanConfig.userIdentity.LEADER then
        return false
    end
    if _memberData:checkIsBMe() then
        return false
    end
    return true
end
-- 会长 任命成员职位 UI
function ClanManager:showChangePositionFloatView(_memberData, _posW)
    local oldView = gLobalViewManager:getViewByExtendData("ClanPositionChangeConfirmLayer")
    if oldView then
        oldView:closeUI()
    end

    local view = util_createView("views.clan.member.position.ClanPositionFloatView", _memberData)
    return view
end
-- 会长 任命成员职位 确认弹板
function ClanManager:popChangePositionConfirmLayer(_memberData, _type)
    if not _memberData or not _type then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanPositionChangeConfirmLayer") then
        return
    end

    local view = util_createView("views.clan.member.position.ClanPositionChangeConfirmLayer", _memberData, _type)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
-- 个职位变化 玩家提示弹板
function ClanManager:popSelfPositionChangeTipLayer(_cb)
    local clanData = self:getClanData()
    if not clanData then
        return
    end
    local selfPositionNew = clanData:getUserIdentity()
    local selfPositionOld = clanData:getUserIdentityOld()
    if selfPositionNew == selfPositionOld then
        return
    end

    self:sendSyncSelfPositionReq()
    if selfPositionOld == ClanConfig.userIdentity.LEADER then
        local view = self:popCommonTipPanel(ProtoConfig.ErrorTipEnum.AUTO_LEVEL_LEADER, _cb)
        return view
    end

    if gLobalViewManager:getViewByExtendData("ClanPositionChangeTipLayer") then
        return
    end

    local view = util_createView("views.clan.member.position.ClanPositionChangeTipLayer", selfPositionNew)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
-- 判断精英成员数量是否满了
function ClanManager:checkElitieMemberFull()
    local eliteCount = self.clanData:getEliteMemberCount()
    return eliteCount >= 2
end
------------------ 公会切换职位 ------------------
------------------ 公会 国家地区， tag ------------------
function ClanManager:getStdCountryData(_type)
    if _type == "country" then
        if not self.m_totalCountryStdList then
            self.m_totalCountryStdList = table.keys(Country_config) or {}
            table.sort(self.m_totalCountryStdList)
            for i=#self.m_totalCountryStdList, 1, -1 do
                local country = self.m_totalCountryStdList[i]
                if country == "USA" then
                    table.remove(self.m_totalCountryStdList, i)
                    break
                end
            end
            table.insert(self.m_totalCountryStdList, 1, "USA")
        end
        return self.m_totalCountryStdList
    end

    -- _type -- 国家名字
    local allStateStr = (Country_config[_type] or {})[1] or ""
    if allStateStr == "" then
        return {}
    end
    return string.split(allStateStr, ",")
end
function ClanManager:getStdTagName(_tagIdx)
    if not _tagIdx  then
        return ""
    end
    
    return ClanConfig.TAG_NAME_LIST[tonumber(_tagIdx)] or ""
end
function ClanManager:createTagSprite(_tagIdx)
    if not _tagIdx then
        return display.newNode()
    end

    local sp = display.newSprite()
    local imgPath = self:getTagImgPath(_tagIdx)
    local success = util_changeTexture(sp, imgPath)
    return success and sp or display.newNode()
end
function ClanManager:getTagImgPath(_tagIdx)
    local imgPath = string.format("Club/ui_new/Create/Club_label%s.png", _tagIdx)
    return imgPath
end
-- 弹出公会 标签选择弹板
function ClanManager:popChooseTagLayer(_hadChooseTagList)
    if gLobalViewManager:getViewByExtendData("ClanTagChooseLayer") then
        return
    end

    local view = util_createView("views.clan.baseInfo.tag.ClanTagChooseLayer", _hadChooseTagList)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
------------------ 公会 国家地区， tag ------------------
------------------ 公会 红包 ------------------
function ClanManager:setRedGiftOpenSign(_bOpen)
    self.m_bRedGiftOpen = _bOpen
end
function ClanManager:checkRedGiftOpen()
    return self.m_bRedGiftOpen or false
end
function ClanManager:resetGiftChooseUserList()
    self.m_redGiftChooseUserList = {}
end
function ClanManager:getGiftChooseUserList()
    return self.m_redGiftChooseUserList
end
function ClanManager:addGiftChooseUser(_udid)
    table.insert(self.m_redGiftChooseUserList, _udid)
end
function ClanManager:removeGiftChooseUser(_udid)
    local idx = nil
    for _idx, udid in pairs(self.m_redGiftChooseUserList) do
        if _udid == udid then
            idx = _idx
            break
        end
    end
    if not idx then
        return
    end

    table.remove(self.m_redGiftChooseUserList, idx)
end
function ClanManager:checkExitChooseList(_udid)
    local bExit = false
    for _, udid in pairs(self.m_redGiftChooseUserList) do
        if _udid == udid then
            bExit = true
        end
    end
    return bExit
end
-- 解析 红包礼物信息
function ClanManager:parseRedGiftData(_list)
    local clanData = self:getClanData()
    clanData:parseRedGiftData(_list)
end
-- 请求 公会红包 礼物信息
function ClanManager:sendTeamRedGiftInfo()
    local clanData = self:getClanData() 
    local allMemberList = clanData:getClanMemberList()
    local bReqMember = false
    if ProtoConfig.REQUEST_CLAN_MEMBER.preReqTime and ProtoConfig.REQUEST_CLAN_MEMBER.limitReqTime then
        local subTime = os.time() - ProtoConfig.REQUEST_CLAN_MEMBER.preReqTime
        if subTime >= ProtoConfig.REQUEST_CLAN_MEMBER.limitReqTime then
            bReqMember = true
        end
    end
    if #allMemberList == 0 or bReqMember then
        self:sendClanMemberList(function()
            self.clanSyncManager:sendTeamRedGiftInfo()
        end)
    else
        self.clanSyncManager:sendTeamRedGiftInfo()
    end
end
-- 请求 公会红包 礼物信息
function ClanManager:sendTeamRedGiftCollect(msgId, msgDign)
    if msgId and string.len(msgId) > 0 and msgDign and string.len(msgDign) > 0 then
        self.clanSyncManager:sendTeamRedGiftCollect(msgId, msgDign)
    else
        printInfo("获取消息奖励数据 信息不全 不能发送")
    end
end
-- 请求 公会红包 领取记录
function ClanManager:sendTeamRedGiftCollectRecord(msgId, msgDign, msgType)
    if msgId and string.len(msgId) > 0 and msgDign and string.len(msgDign) > 0 then
        local onSuccess = function( responseData )
            local ClanRedGiftCollectDeailData = util_require("data.clanData.ClanRedGiftCollectDeailData")
            local data = ClanRedGiftCollectDeailData:create()
            data:parseData(responseData, msgType)

            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_RED_COLLECT_RECORD_SUCCESS, data)
        end
        self.clanSyncManager:sendTeamRedGiftCollectRecord(msgId, msgDign, onSuccess)
    else
        printInfo("获取消息奖励数据 信息不全 不能发送")
    end
end
-- 弹出 自动领取红包弹板
function ClanManager:popAutoColRedGiftLayer(_msgData, _cb)
    if gLobalViewManager:getViewByExtendData("ClanRedGiftAutoCollectLayer") then
        return
    end

    local view = util_createView("views.clan.redGift.ClanRedGiftAutoCollectLayer", _msgData, _cb)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
-- 弹出 公会送礼礼物选择界面
function ClanManager:popSendGiftLayer()
    if gLobalViewManager:getViewByExtendData("ClanSendGiftChooseLayer") then
        return
    end

    local view = util_createView("views.clan.redGift.ClanSendGiftChooseLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 弹出 公会送红包规则界面
function ClanManager:popRedGiftRuleLayer()
    if gLobalViewManager:getViewByExtendData("ClanRedGiftRuleLayer") then
        return
    end

    local view = util_createView("views.clan.redGift.ClanRedGiftRuleLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 弹出 公会送红包 选择赠送成员面板
function ClanManager:popGiftChooseMemberLayer(_giftData)
    if not _giftData then
        return
    end
    if gLobalViewManager:getViewByExtendData("ClanRedGiftChooseMemberLayer") then
        return
    end

    local view = util_createView("views.clan.redGift.ClanRedGiftChooseMemberLayer", _giftData)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 弹出 公会送红包 红包领取详情面板
function ClanManager:popGiftCollectDetailLayer(_data, _bAuto)
    if not _data then
        return
    end
    if gLobalViewManager:getViewByExtendData("ClanRedGiftCheckCollectDetailLayer") then
        return
    end

    local luaPath = "views.clan.redGift.ClanRedGiftCheckCollectDetailLayer"
    if _bAuto then
        luaPath = "views.clan.redGift.ClanRedGiftAutoCollectDetailLayer"
    end
    local view = util_createView(luaPath, _data)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示付费权益界面
function ClanManager:showPayBenefitLayer(_redGiftData)
    if not _redGiftData then
        return
    end

    local price = _redGiftData:getPrice()
    local view = util_createView(SHOP_CODE_PATH.ShopBenefitLayer, {p_price = tostring(price)})
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
-- 充值
function ClanManager:goPurchase(_redGiftData)
    if not _redGiftData then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _redGiftData:getKeyId()
    goodsInfo.goodsPrice = tostring(_redGiftData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, _redGiftData:getIdx())

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_redGiftData)
    local list = self:getGiftChooseUserList()
    local str = ""
    for idx, udid in pairs(list) do
        if str == "" then
            str = udid
        else
            str = str .. ";" .. udid
        end
    end
    gLobalSaleManager:purchaseActivityGoods(nil, str, BUY_TYPE.TEAM_RED_GIFT, goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end
function ClanManager:buySuccess()
    gLobalViewManager:checkBuyTipList(function()
        local view = gLobalViewManager:getViewByExtendData("ClanRedGiftChooseMemberLayer")
        if view then
            view:closeUI()
        end
        self:resetGiftChooseUserList()
    end)
end
function ClanManager:buyFailed()
    print("ClanManager--buy--failed")
end

function ClanManager:sendIapLog(_goodsInfo, _idx)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "TeamGift"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "TeamGift" .. _idx
    purchaseInfo.purchaseStatus = "TeamGift"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end
------------------ 公会 红包 ------------------
--玩家退出或被踢更新 成员数据
function ClanManager:deleteMemberByUdidEvt(_udid)
    local clanData = self:getClanData()
    clanData:deleteMemberByUdid(_udid)
end
--玩家新加入更新 成员数据
function ClanManager:notifyUpdateMemberReqConfigEvt()
    ProtoConfig.REQUEST_CLAN_MEMBER.preReqTime = nil 
    ProtoConfig.REQUEST_MEMBER_RANK_REWARD.preReqTime = nil 
end

------------------ 公会 对决 start ------------------
-- 请求 公会对决排行榜
function ClanManager:sendClanDuelRank()
    local duelData = self.clanData:getClanDuelData()
    if not duelData:isRunning() then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLAN_DUEL_REQUEST_RANK, false)
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local onSuccess = function(_result)
        duelData:parseRankInfo(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLAN_DUEL_REQUEST_RANK, true)
    end

    local onFaild = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLAN_DUEL_REQUEST_RANK, false)
    end
    self.clanSyncManager:sendClanDuelRank(onSuccess, onFaild)
end

function ClanManager:popClanDuelMainLayer()
    local duelData = self.clanData:getClanDuelData()
    if not duelData:isRunning() then
        return
    end

    if not duelData:isMatchRival() then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanDuelMainLayer") then
        return
    end

    local view = util_createView("views.clan.duel.ClanDuelMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ClanManager:popClanDuelRuleLayer()
    local duelData = self.clanData:getClanDuelData()
    if not duelData:isRunning() then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanDuelRuleLayer") then
        return
    end

    local view = util_createView("views.clan.duel.ClanDuelRuleLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ClanManager:popClanDuelOpenLayer()
    local duelData = self.clanData:getClanDuelData()
    if not duelData:isRunning() then
        return
    end

    if not duelData:isMatchRival() then
        return
    end

    if gLobalViewManager:getViewByExtendData("ClanDuelOpenLayer") then
        return
    end
    
    local isFirstPop = gLobalDataManager:getBoolByField("isFirstPopClanDuelOpenLayer", true)
    if not isFirstPop then
        return
    end

    local view = util_createView("views.clan.duel.ClanDuelOpenLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ClanManager:popClanDuelResultLayer()
    if gLobalViewManager:getViewByExtendData("ClanDuelResultLayer") then
        return
    end
    
    local ChatManager = require("manager.System.ChatManager"):getInstance()
    local isPop, duelStatus = ChatManager:isPopClanDuelResultLayer()
    if not isPop then
        return
    end

    local view = util_createView("views.clan.duel.ClanDuelResultLayer", duelStatus)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 打开公会界面要弹出的界面
function ClanManager:clanHomeViewPoptLayer()
    local openLayer = self:popClanDuelOpenLayer()
    if not openLayer then
        self:popClanDuelResultLayer()
    end
end

-- 公会对决关卡内入口
function ClanManager:createClanDuelEntryNode()
    if not self:isUnlock() then
        return
    end

    local duelData = self.clanData:getClanDuelData()
    if not duelData:isRunning() then
        return
    end

    if not duelData:isMatchRival() then
        return
    end

    local view = util_createView("views.clan.duel.ClanDuelEntryNode")
    return view
end
------------------ 公会 对决 end ------------------

-- 注册事件
function ClanManager:registerListener()
    gLobalNoticManager:addObserver(self, "requestSyncClanAct", ClanConfig.EVENT_NAME.SEND_SYNC_CLAN_ACT_DATA)
    gLobalNoticManager:addObserver(self, "deleteMemberByUdidEvt", ChatConfig.EVENT_NAME.DELETE_DATABASE_MEMBER) --玩家退出或被踢更新 成员数据
    gLobalNoticManager:addObserver(self, "notifyUpdateMemberReqConfigEvt", ChatConfig.EVENT_NAME.NOTIFY_UPDATE_MEMBER) --玩家新加入更新 成员数据
end

return ClanManager