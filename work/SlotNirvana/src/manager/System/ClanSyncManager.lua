-- 公会数据解析

local ClanConfig = require("data.clanData.ClanConfig")
local ChatConfig = require("data.clanData.ChatConfig")
local ClanNetModel = require("net.netModel.ClanNetModel")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatManager = require("manager.System.ChatManager"):getInstance()
local ClanSyncManager = class("ClanSyncManager")

---------------------  公会基础功能  ---------------------
-- 请求公会基础数据
function ClanSyncManager:requestClanInfo(successCallback)
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        ClanManager:parseClanInfoData(responseData.clanInfo)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.REFRESH_ENTRY_UI)
        if successCallback then
            successCallback()
        end
    end

    local onFail = function()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA_FAILD)
    end

    -- //登入游戏以后，发送个人公会信息请求
    -- message ClanInfoRequest {
    --     optional string udid = 1; //玩家udid
    -- }
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid

    G_GetNetModel(NetType.Clan):requestClanInfo(requestInfo, onSuccess, onFail)
end

-- 拉取公会成员列表
function ClanSyncManager:requestClanMemberList(_successCb)
    local onSuccess = function(responseData)
        -- message ClanMemberResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional int32 current = 2;//成员人数
        --     optional int32 limit = 3;//成员人数上限
        --     optional int32 applicants = 4;//申请人数
        --     repeated ClanUser users = 5; //成员数据
        -- }
        ClanManager:parseClanMemberList(responseData)
        if _successCb then
            _successCb()
        end
    end

    -- //公会成员列表
    -- message ClanMemberRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string cid = 2; //公会ID
    -- }
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id

    G_GetNetModel(NetType.Clan):requestClanMemberList(requestInfo, onSuccess)
end

-- 会长更改成员职位
function ClanSyncManager:sendChangePositionReq(_memberUdid, _positionStr)
    local onSuccess = function(responseData)
        -- message ClanMemberResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional int32 current = 2;//成员人数
        --     optional int32 limit = 3;//成员人数上限
        --     optional int32 applicants = 4;//申请人数
        --     repeated ClanUser users = 5; //成员数据
        -- }
        ClanManager:parseClanMemberList(responseData)
        local leader = ClanManager:getLearderUdid()
        if leader ~= globalData.userRunData.userUdid then
            -- 我自己主动把 会长转让了
            self:sendSyncSelfPositionReq()
        end
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CHANGE_MEMBER_POSITION)
    end

    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id
    requestInfo.AppointUser = _memberUdid --任命玩家udid
    requestInfo.position = _positionStr -- 任命职位
    G_GetNetModel(NetType.Clan):sendChangePositionReq(requestInfo, onSuccess)
end

-- 同步新老职位信息
function ClanSyncManager:sendSyncSelfPositionReq()
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id
    G_GetNetModel(NetType.Clan):sendSyncSelfPositionReq(requestInfo)
end

---------------------  公会创建修改  ---------------------
-- 请求创建公会
function ClanSyncManager:requestCreateClan()
    local editInfo = ClanManager:getClanEditInfo()
    if editInfo.clanName and string.len(editInfo.clanName) <= 0 then
        printInfo("------>    创建公会请求 公会名称不能为空")
        return
    end

    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        ClanManager:parseNewUser7DayData(responseData)
        ClanManager:parseClanEditResult(responseData)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_CREATE_SUCCESS)
    end

    -- //编辑公会信息
    -- message ClanRequest {
    --     optional string cid = 1; //公会id，编辑公会信息时必传
    --     optional string name = 2; //名称
    --     optional string head = 3;  //logo
    --     optional string description = 4;  //描述
    --     optional int32 type = 5; //类型(1,自由出入 2,需要申请)
    --     optional int32 minLevel = 6;  //公会准入最小VIP等级
--     optional string countryArea = 7;工会所属国家地区
--   optional string tag = 8;//工会标签
    -- }
    local requestInfo = {}
    requestInfo.cid = editInfo.clanId -- 公会id
    requestInfo.name = editInfo.clanName -- 公会名称
    requestInfo.head = editInfo.clanLogo -- 公会logo
    requestInfo.description = editInfo.clanDesc -- 公会宣言
    requestInfo.type = editInfo.clanJoinType -- 入会限制类型
    requestInfo.minLevel = editInfo.clanMinVip -- 入会限制vip等级
    requestInfo.countryArea = editInfo.countryArea -- 工会所属国家地区
    requestInfo.tag = editInfo.tag -- 工会标签

    G_GetNetModel(NetType.Clan):requestCreateClan(requestInfo, onSuccess)
end

-- 请求创建公会(花费钻石)
function ClanSyncManager:requestCreateClan_Gem()
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        G_GetMgr(ACTIVITY_REF.GemChallenge):parseClanBackData(responseData)
        ClanManager:parseClanInfoData(responseData.clanInfo)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CLAN_GEM_SUCCESS)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end

    local requestInfo = {}
    G_GetNetModel(NetType.Clan):requestCreateClan_Gem(requestInfo, onSuccess)
end

-- 请求编辑公会信息 --
function ClanSyncManager:requestClanInfoEdit()
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        ClanManager:parseClanEditResult(responseData)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_NEW_CLAN_INFO_SUCCESS)
    end

    -- //编辑公会信息
    -- message ClanRequest {
    --     optional string cid = 1; //公会id，编辑公会信息时必传
    --     optional string name = 2; //名称
    --     optional string head = 3;  //logo
    --     optional string description = 4;  //描述
    --     optional int32 type = 5; //类型(1,自由出入 2,需要申请)
    --     optional int32 minLevel = 6;  //公会准入最小VIP等级
--     optional string countryArea = 7;工会所属国家地区
--   optional string tag = 8;//工会标签
    -- }
    local requestInfo = {}
    local editInfo = ClanManager:getClanEditInfo()
    requestInfo.cid = editInfo.clanId -- 公会id
    requestInfo.name = editInfo.clanName -- 公会名称
    requestInfo.head = editInfo.clanLogo -- 公会logo
    requestInfo.description = editInfo.clanDesc -- 公会宣言
    requestInfo.type = editInfo.clanJoinType -- 入会限制类型
    requestInfo.minLevel = editInfo.clanMinVip -- 入会限制vip等级
    requestInfo.countryArea = editInfo.countryArea -- 工会所属国家地区
    requestInfo.tag = editInfo.tag -- 工会标签

    G_GetNetModel(NetType.Clan):requestClanInfoEdit(requestInfo, onSuccess)
end

-- 请求修改公会名称 --
function ClanSyncManager:requestClanNameEdit()
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        G_GetMgr(ACTIVITY_REF.GemChallenge):parseClanBackData(responseData)
        ClanManager:parseClanEditResult(responseData)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_CHAGE_CLAN_NAME)
    end

    -- //编辑公会信息
    -- message ClanRequest {
    --     optional string cid = 1; //公会id，编辑公会信息时必传
    --     optional string name = 2; //名称
    --     optional string head = 3;  //logo
    --     optional string description = 4;  //描述
    --     optional int32 type = 5; //类型(1,自由出入 2,需要申请)
    --     optional int32 minLevel = 6;  //公会准入最小VIP等级
--     optional string countryArea = 7;工会所属国家地区
--   optional string tag = 8;//工会标签
    -- }
    local requestInfo = {}
    -- 设置当前公会信息
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id
    requestInfo.head = simpleInfo:getTeamLogo() -- 公会logo
    requestInfo.description = simpleInfo:getTeamDesc() -- 公会宣言
    requestInfo.type = simpleInfo:getTeamJoinType() -- 入会限制类型
    requestInfo.minLevel = simpleInfo:getTeamMinVipLevel() -- 入会限制vip等级
    requestInfo.countryArea = simpleInfo:getTeamCountryArea() -- 工会所属国家地区
    requestInfo.tag = simpleInfo:getTeamTag() -- 工会标签
    -- 设置修改后的公会名称
    local editInfo = ClanManager:getClanEditInfo()
    requestInfo.name = editInfo.clanName -- 公会名称

    G_GetNetModel(NetType.Clan):requestClanNameEdit(requestInfo, onSuccess)
end

---------------------  公会成员管理  ---------------------
-- 拉取申请入会成员列表
function ClanSyncManager:requestClanApplyList(_pageNu)
    local onSuccess = function(responseData)
        -- message ClanMemberResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional int32 current = 2;//成员人数
        --     optional int32 limit = 3;//成员人数上限
        --     optional int32 applicants = 4;//申请人数
        --     repeated ClanUser users = 5; //成员数据
        -- }
        ClanManager:parseClanApplyList(responseData)
    end

    -- message ClanListRequest {
    --     optional int32 pageNum = 1; //第几页页
    --     optional int32 pageSize = 2; //每页记录数
    -- }
    local requestInfo = {}
    requestInfo.pageNum = _pageNu -- 页数
    -- requestInfo.pageSize = 2; //每页记录数  走服务器默认值

    G_GetNetModel(NetType.Clan):requestClanApplyList(requestInfo, onSuccess)
end

-- 发送玩家入会申请处理消息(同意 拒绝 清空)
function ClanSyncManager:requestClanApply(apply_type, udid)
    local onSuccess = function(responseData)
        printInfo("------>    发送玩家入会申请处理消息成功 " .. apply_type)
        udid = responseData.udid or udid
        if apply_type == ClanConfig.applyAnswer.AGREE then
            -- 同意申请
            ClanManager:parseClanApplyAgree(udid)
        elseif apply_type == ClanConfig.applyAnswer.REFUSE then
            -- 拒绝申请
            ClanManager:onClanApplyRefused(udid)
        elseif apply_type == ClanConfig.applyAnswer.CLEAR then
            -- 清空申请列表
            ClanManager:onClanApplyClear()
        end
    end

    local type = ProtoConfig.REQUEST_CLAN_APPLY_REFUSE
    if apply_type == ClanConfig.applyAnswer.AGREE then
        type = ProtoConfig.REQUEST_CLAN_APPLY_AGREE
    end

    -- //公会申请处理
    -- message ClanApplyRequest {
    --     optional int32 type = 1; //处理类型(1同意 2拒绝 3清空)
    --     optional string udid = 2; //申请玩家udid
    -- }
    local requestInfo = {}
    requestInfo.type = apply_type
    requestInfo.udid = udid

    G_GetNetModel(NetType.Clan):requestClanApply(type, requestInfo, onSuccess)
end

-- 发送踢出玩家请求
function ClanSyncManager:requestKickMember(udid)
    local onSuccess = function(responseData)
        -- message ClanMemberResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional int32 current = 2;//成员人数
        --     optional int32 limit = 3;//成员人数上限
        --     optional int32 applicants = 4;//申请人数
        --     repeated ClanUser users = 5; //成员数据
        -- }
        ClanManager:parseKickMember(responseData)
    end

    -- //踢出公会
    -- message ClanKickRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string cid = 2; //公会ID
    --     optional string kickUser = 3; //踢出玩家udid
    -- }
    local requestInfo = {}
    local clanSimpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = clanSimpleInfo:getTeamCid()
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    requestInfo.kickUser = udid

    G_GetNetModel(NetType.Clan):requestKickMember(requestInfo, onSuccess)
end

-- 玩家离开公会的请求消息
function ClanSyncManager:requestLeaveClan()
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }

        ClanManager:parseLeaveClan(responseData)
    end

    -- //退出公会
    -- message ClanLeaveRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string cid = 2; //公会ID
    -- }
    local requestInfo = {}
    local clanSimpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = clanSimpleInfo:getTeamCid()
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid

    G_GetNetModel(NetType.Clan):requestLeaveClan(requestInfo, onSuccess)
end

-- 邀请玩家加入公会
function ClanSyncManager:requestUserInvite(udid)
    local onSuccess = function(responseData)
        ClanManager:onUserInvite(udid)
    end

    -- //邀请玩家
    -- message ClanInviteRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string inviteUser = 2; //受邀玩家udid
    -- }
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    requestInfo.inviteUser = udid -- 受邀玩家udid

    G_GetNetModel(NetType.Clan):requestUserInvite(requestInfo, onSuccess)
end

---------------------  搜索相关  ---------------------
-- 请求搜索公会 --
function ClanSyncManager:requestClanSearch(content, pageNu)
    if not content or content == "" then
        return
    end

    local onSuccess = function(responseData)
        -- message ClanSearchResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanSearch data = 3;//公会数据
        -- }
        ClanManager:parseClanSearchList(responseData.data, content)
    end

    -- //搜索公会
    -- message ClanSearchRequest {
    --     optional string content = 1; //搜索内容
    --     optional int32 pageNo = 2;//显示第几页
    -- }
    local requestInfo = {}
    requestInfo.content = content
    requestInfo.pageNo = pageNu or 1

    G_GetNetModel(NetType.Clan):requestClanSearch(requestInfo, onSuccess)
end

-- 拉取推荐公会列表
function ClanSyncManager:requestRecommendClanList(pageNu)
    local onSuccess = function(responseData)
        -- message ClanSearchResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanSearch data = 3;//公会数据
        -- }

        ClanManager:parseRecommendClanList(responseData.data)
    end

    local requestInfo = {}
    requestInfo.content = ""
    requestInfo.pageNo = pageNu or 1
    G_GetNetModel(NetType.Clan):requestRecommendClanList(requestInfo, onSuccess)
end

-- 搜索玩家 --
function ClanSyncManager:requestSearchUser(content, pageNu)
    local onSuccess = function(responseData)
        -- message ClanSearchUserResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanSearchUser user = 3; //搜索结果
        -- }

        ClanManager:parseSearchUserList(responseData, content)
    end

    -- //搜索玩家
    -- message ClanSearchRequest {
    --     optional string content = 1;//搜索内容
    --     optional int32 pageNo = 2;//显示第几页
    -- }
    local requestInfo = {}
    requestInfo.content = content --
    requestInfo.pageNo = pageNu or 1
    G_GetNetModel(NetType.Clan):requestSearchUser(requestInfo, onSuccess)
end

-- 快速加入公会 --
function ClanSyncManager:requestClanQuickJoin()
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        ClanManager:parseNewUser7DayData(responseData)
        ClanManager:parseClanJoinResult(responseData)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_FAST_JOIN_CLAN_SUCCESS) -- 快速加入公会 成功事件
    end

    local requestInfo = ""
    G_GetNetModel(NetType.Clan):requestClanQuickJoin(requestInfo, onSuccess)
end

-- 请求加入公会 --
function ClanSyncManager:requestClanJoin(clanId)
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        ClanManager:parseNewUser7DayData(responseData)  
        ClanManager:parseClanJoinResult(responseData)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_JOIN_CLAN_SUCCESS) -- 加入公会 成功事件
    end

    -- //申请加入公会
    -- message ClanJoinRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string cid = 2; //公会ID
    -- }
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    requestInfo.cid = clanId -- 公会id

    G_GetNetModel(NetType.Clan):requestClanJoin(requestInfo, onSuccess)
end

-- 拒绝加入公会 --
function ClanSyncManager:requestRejectInviteClan(_inviteUdid)
    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        ClanManager:parseInviteListRemoveUdid(_inviteUdid)
    end

    -- //拒绝加入公会
    -- message ClanInviteRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string inviteUser = 2; //受邀玩家udid
    -- }
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    requestInfo.inviteUser = _inviteUdid -- 受邀玩家udid

    G_GetNetModel(NetType.Clan):requestRejectInviteClan(requestInfo, onSuccess)
end

---------------------  奖励相关  ---------------------
-- 领取任务奖励请求消息
function ClanSyncManager:requestTaskReward(_callback)
    local onSuccess = function(responseData)
        local result = responseData.result or "{}"
        if result ~= "" then
            ClanManager:parseTaskReward(cjson.decode(result), _callback)
        elseif _callback then
            _callback()
        end
    end

    local requestInfo = ""
    G_GetNetModel(NetType.Clan):requestTaskReward(requestInfo, onSuccess, _callback)
end

-- 请求fb分享邀请接口
function ClanSyncManager:requestFbInvite(_clanId, _udid)
    local onFaild = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        --弹窗逻辑执行下一个事件
    end

    local onSuccess = function(responseData)
        -- message ClanResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanInfo clanInfo = 3; //公会数据
        -- }
        if responseData.clanInfo then
            local ClanData = require("data.clanData.ClanData")
            local clanData = ClanData:create()
            local simpleInfo = clanData:parseClanData(responseData.clanInfo.clan or {})

            ClanManager:popClanBaseInfoPanel(simpleInfo)
        else
            onFaild()
        end
    end

    -- //邀请玩家
    -- message ClanInviteRequest {
    --     optional string udid = 1; //玩家udid
    --     optional string inviteUser = 2; //受邀玩家udid
    --     optional string cid = 3; //公会ID
    -- }
    local requestInfo = {}
    requestInfo.cid = _clanId -- 公会ID
    requestInfo.udid = _udid -- 邀玩家的udid

    G_GetNetModel(NetType.Clan):requestFbInvite(requestInfo, onSuccess, onFaild)
end

-- 请求公会聊天服务器配置数据
function ClanSyncManager:requestChatServerInfo(_endCb)
    -- message ClanServerRequest {
    --     optional string udid = 1;
    -- }

    -- message ClanServerResponse {
    --     optional string host = 1; //host
    --     optional int32 port = 2; //ip
    --     optional string server = 3; //server
    --     repeated ClanChatServer chatServers = 4; //chatServers  (二维数组)
    -- }
    -- message ClanChatServer {
    --     repeated string servers = 1; //servers
    --   }
    local onSuccess = function(responseData)
        if responseData.host and responseData.port then
            local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
            TcpNetConfig.SERVER_LIST[TcpNetConfig.SERVER_KEY.CLAN_CHAT].host = responseData.host
            TcpNetConfig.SERVER_LIST[TcpNetConfig.SERVER_KEY.CLAN_CHAT].port = responseData.port
            TcpNetConfig.SERVER_LIST_NEW[TcpNetConfig.SERVER_KEY.CLAN_CHAT] = responseData.chatServers
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.RECIEVE_CHAT_SERVER_INFO_SUCCESS)
        end
        if _endCb then
            _endCb()
        end
    end

    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid -- 玩家udid
    G_GetNetModel(NetType.Clan):requestChatServerInfo(requestInfo, onSuccess, _endCb)
end

-- 获取聊天奖励数据
function ClanSyncManager:requestChatReward(msgId, msgDign)
    local onSuccess = function(responseData)
        -- message ActionResponse {
        --     required ResponseCode code = 1 [default = SUCCEED];
        --     optional string description = 2;
        --     optional UserInfo user = 3;
        --     optional Tournament tournament = 4;
        --     optional string result = 5;
        --     optional CommonConfig config = 6;
        --     optional PigCoin pig = 7;
        --     optional MissionConfig mission = 8;
        --     optional SimpleUserInfo simpleUser = 9; //用户核心数据
        --     optional int64 timestamp = 10; //当前时间戳
        --     optional int64 winCoins = 11; //本次赢钱
        --     optional FeaturesData activity = 12; // 所有活动数据
        --     repeated AdConfig adConfig = 13; //广告配置
        --     repeated CardDropInfo cardDrop = 14; //卡片掉落信息
        --     optional MissionConfig dailyTask = 15; //新版本每日任务
        --     optional GameCrazy gameCrazy = 16; // GameCrazy
        --     optional int64 fbCoins = 17; // Facebook绑定金币
        --     optional CommonItems drops = 18; // 通用掉落
        --     optional CardVegasTornado vegasTornado = 19; // 集卡小游戏数据
        --     optional TeamMission teamMission = 20; // 关卡团队任务
        -- }
        local data = cjson.decode(responseData.result)
        data.result = cjson.decode(data.result)
        if data.coins and tonumber(data.coins) > 0 then
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA, data)
        end
    end

    -- //请求聊天奖励数据
    -- message ClanChatRewardRequest {
    --     optional string msgId = 1; //消息ID
    --     optional string msgSign = 2; //奖励内容标识
    --     optional string cid = 3; //公会ID
    -- }
    local requestInfo = {}
    requestInfo.msgId = msgId -- 玩家udid
    requestInfo.msgSign = msgDign -- 邀玩家的udid
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id

    G_GetNetModel(NetType.Clan):requestChatReward(requestInfo, onSuccess)
end

-- 获取聊天奖励数据
function ClanSyncManager:requestCollectAllGiftReward(msgIdList, msgDignList)
    local onSuccess = function(responseData)
        local data = util_cjsonDecode(responseData.result)
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA_ALL, data)
    end

    -- message ClanChatRewardRequest {
    --     optional string msgId = 1; //消息ID
    --     optional string msgSign = 2; //奖励内容标识
    --     optional string cid = 3; //公会ID
    --     repeated string msgIds = 4; //消息IDs
    --     repeated string msgSigns = 5; //奖励内容标识s
    -- }
    local requestInfo = {}
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id
    requestInfo.msgIds = msgIdList -- 玩家udid
    requestInfo.msgSigns = msgDignList -- 邀玩家的udid

    G_GetNetModel(NetType.Clan):requestCollectAllGiftReward(requestInfo, onSuccess)
end

-- 公会聊天发送要卡消息
function ClanSyncManager:requestCardNeeded(albumId, cardId, successCall, failedCall)
    local onFailed = function()
        if failedCall then
            failedCall()
        end
    end

    local onSuccess = function(responseData)
        printInfo("公会聊天发送要卡消息 成功")
        -- 返回成功和失败 暂时不用处理 消息会生成在聊天里
        -- message ClanAskCardResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string result = 2;
        -- }
        if responseData and responseData.result and responseData.result ~= "" then
            local respData = cjson.decode(responseData.result)

            local cdTime = respData.askChipCD
            if cdTime then
                if CardSysRuntimeMgr then
                    CardSysRuntimeMgr:setAskCD(tonumber(cdTime))
                end
                ClanManager:setReqCardCD(tonumber(cdTime))
            end

            gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.NEW_CHAT_INFO)

            if successCall then
                successCall()
            end

            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.CHAT_SEND_REQ_CARD_NEED) -- 请求要卡成功
        else
            onFailed()
        end
    end

    -- //索要卡片
    -- message ClanAskCardRequest {
    --     optional string albumId = 1;//卡册id
    --     optional string cardId = 2;//卡id
    -- }
    local requestInfo = {}
    requestInfo.albumId = albumId -- 玩家udid
    requestInfo.cardId = cardId -- 邀玩家的udid

    G_GetNetModel(NetType.Clan):requestCardNeeded(requestInfo, onSuccess, onFailed)
end

-- 公会聊天发送赠卡消息
function ClanSyncManager:requestCardsData(cardList)
    local onSuccess = function(responseData)
        -- 返回成功和失败 暂时不用处理 消息会生成在聊天里
        -- message CardExistResponse {
        --     required ResponseCode code = 1 [default = SUCCEED];
        --     optional string result = 2;
        -- }
        if responseData and responseData.result and responseData.result ~= "" then
            local cardData = cjson.decode(responseData.result)
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CARD_DATA_READY, cardData)
        end
    end

    -- //请求卡牌数据
    -- message CardExistRequest {
    --     optional string cardIds = 1; //卡ID
    -- }
    local requestInfo = {}
    cardList = table.concat(cardList, ";")
    requestInfo.cardIds = cardList -- 卡id

    G_GetNetModel(NetType.Clan):requestCardsData(requestInfo, onSuccess)
end

-- 公会聊天发送赠卡消息
function ClanSyncManager:requestCardGiven(receiver, cardId, msgId)
    local onSuccess = function(responseData)
        -- 返回成功和失败 暂时不用处理 消息会生成在聊天里
        -- message ClanSendCardResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string result = 2;
        -- }
        if responseData and responseData.result and responseData.result ~= "" then
            local cardData = cjson.decode(responseData.result)
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CARD_DATA_CHANGE, cardData)
        end
    end
    local onFailed = function(errorCode , errorData)
        if errorCode == BaseProto_pb.CLAN_ERROR and errorData and string.len(errorData) > 0 then
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CARD_HAD_SEND, msgId)
        end
    end

    -- //赠送卡片
    -- message ClanSendCardRequest {
    --     optional string receiver = 1;//接收人udid
    --     optional string cardId = 2;//卡id
    --     optional string msgId = 3;//消息ID
    -- }
    local requestInfo = {}
    requestInfo.receiver = receiver -- 玩家udid
    requestInfo.cardId = cardId -- 卡id
    requestInfo.msgId = msgId

    G_GetNetModel(NetType.Clan):requestCardGiven(requestInfo, onSuccess, onFailed)
end

-- 请求聊天记录HTTP
function ClanSyncManager:requestHttpChatInfo(successCall, failedCall)
    local onSuccess = function(responseData)
        -- message SyncReceive {
        --     required ResponseCode code = 1 [default = SUCCEED];
        --     optional string desc = 2;
        --     repeated MessageInfo all = 3;//ALL消息
        --     repeated MessageInfo chips = 4;//Chips消息
        --     repeated MessageInfo gift = 5;//Gift消息
        --     repeated MessageInfo chat = 6;//chat消息
        --     repeated MessageInfo redPackage = 7;//红包消息
        -- }
        ChatManager:parseChatData( responseData )
        if successCall then
            successCall()
        end
    end
    local onFailed = function(errorCode , errorData)
        if failedCall then
            failedCall()
        end
    end
    -- message SyncSend {
    --     optional string sid = 1;//认证返回的Token
    --     optional string msgId = 2;//ALL最后一条消息id
    --     optional string chipsMsgId = 3;//CHIPS最后一条消息id
    --     optional string giftMsgId = 4;//GIFT最后一条消息id
    --     optional string chatMsgId = 5;//GIFT最后一条消息id
    --     optional string redPackageMsgId = 6;//红包最后一条消息id
    --  }
    local requestInfo = {}
    requestInfo.sid = globalData.userRunData.userUdid
    requestInfo.msgId = ChatManager:getLatestChatId()
    requestInfo.chipsMsgId = ChatManager:getLatestChipId()
    requestInfo.giftMsgId = ChatManager:getLatestGiftId()
    requestInfo.chatMsgId = ChatManager:getLatestTextId()
    requestInfo.redPackageMsgId = ChatManager:getLatestRedGiftId()
    G_GetNetModel(NetType.Clan):requestHttpChatServerInfo(requestInfo, onSuccess, onFailed)
end

-- 请求刷新 公会 相关的活动数据
function ClanSyncManager:requestSyncClanAct(_actId)
    local onSuccess = function(responseData)
        globalData.syncActivityConfig(responseData)
        gLobalNoticManager:postNotification(ViewEventType.UPDATE_ACTIVITY_CONFIG_FINISH)
    end

    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.activity = _actId or ""
    G_GetNetModel(NetType.Clan):requestSyncClanAct(requestInfo, onSuccess)
end

-- 公会请求排行榜信息
function ClanSyncManager:sendClanRankReq()
    local onSuccess = function( responseData )
        -- message ClanRankInfoResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanRankInfo rankInfo = 3; //排行榜整合数据
        --   }
        if responseData and responseData.rankInfo then
            ClanManager:parseClanRankData( responseData.rankInfo )
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_RANK_INFO_SUCCESS)
        end
    end
   
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendClanRankReq(requestInfo, onSuccess) 
end

-- 公会请求段位权益信息
function ClanSyncManager:sendClanBenifitReq(_successCB, _faildCB)
    local onSuccess = function( responseData )
        -- message ClanDivisionInterestResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanDivisionInterest interests = 3; //段位权益
        --   }
        if _successCB then
            _successCB()
        end
        if responseData and responseData.interests then
            ClanManager:parseClanBenifitData( responseData.interests )
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_BENIFIT_SUCCESS)
        end
    end
    local onFailed = function ()
        if _faildCB then
            _faildCB()
        end
    end
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendClanBenifitReq(requestInfo, onSuccess, onFailed) 
end

-- 告诉服务器 重置字段
function ClanSyncManager:sendResetPopReprotSign()
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendResetPopReprotSign(requestInfo) 
end

-- 请求本公会 各玩家排行奖励
function ClanSyncManager:sendMemberRankRewardListReq()
    local onSuccess = function( responseData )
        -- message ClanRankUserResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanRankUser users = 3; //工会榜单
        --   }
        if responseData and responseData.users then
            ClanManager:parseRankMemberRewardData( responseData.users )
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_MEMBER_RANK_REWARD_SUCCESS)
        end
    end
   
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendMemberRankRewardListReq(requestInfo, onSuccess) 
end

-- 请求 最强工会排行信息
function ClanSyncManager:sendeRankTopListDataReq()
    local onSuccess = function( responseData )
        -- message ClanRankTopResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanRank ranks = 3; //工会榜单
        --     optional string begin = 4; //开始时间
        --     optional string end = 5; //结束时间
        --     optional ClanRank myRank = 6;
        --   }
        if responseData and responseData.ranks then
            ClanManager:parseRankTopListData( responseData )
            ClanManager:parseRankTopMembersListData(responseData)
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_TOP_RANK_LIST_SUCCESS)
        end
    end
   
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendeRankTopListDataReq(requestInfo, onSuccess) 
end

-- 请求 公会Rush挑战任务信息
function ClanSyncManager:sendTeamRushInfoReqest()
    local onSuccess = function( responseData )
        -- message ClanRushInfoResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     optional ClanRush rush = 3; //rush
        --   }
        if responseData and responseData:HasField("rush") then
            ClanManager:parseRushData( responseData.rush )
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_RUSH_SUCCESS)
        end
    end
   
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendTeamRushInfoReqest(requestInfo, onSuccess) 
end

----------------------- 公会 红包 -----------------------
-- 请求 公会红包 礼物信息
function ClanSyncManager:sendTeamRedGiftInfo( onSuccess, onFaild )
    local onSuccess = function( responseData )
        -- message ClanRedPackageResponse {
        --     required ResponseCode code = 1 [default = SUCCEED]; //返回码
        --     optional string description = 2; //返回码的描述信息
        --     repeated ClanRedPackage redPackage = 3; //红包
        --   }
        if responseData and responseData.redPackage and #responseData.redPackage == 3 then
            ClanManager:parseRedGiftData( responseData.redPackage )
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RECIEVE_TEAM_RED_GIFT_INFO_SUCCESS)
        end
    end
   
    local requestInfo = {}
    requestInfo.udid = globalData.userRunData.userUdid
    G_GetNetModel(NetType.Clan):sendTeamRedGiftInfo(requestInfo, onSuccess, onFaild) 
end

-- 请求 公会红包 礼物信息
function ClanSyncManager:sendTeamRedGiftCollect( msgId, msgDign, onSuccess, onFaild )
    local onSuccess = function( responseData )
        -- message ClanRedPackageCollectRequest {
        --     optional string msgId = 1; //消息ID
        --     optional string msgSign = 2; //奖励内容标识
        --     optional string cid = 3; //公会ID
        --   }
        local data = cjson.decode(responseData.result)
        if data.success and data.coins and tonumber(data.coins) > 0 then
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS, data)
        end
    end
   
    local requestInfo = {}
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id
    requestInfo.msgId = msgId -- 玩家udid
    requestInfo.msgSign = msgDign -- 邀玩家的udid
    G_GetNetModel(NetType.Clan):sendTeamRedGiftCollect(requestInfo, onSuccess, onFaild) 
end

-- 请求 公会红包 查看领取记录
function ClanSyncManager:sendTeamRedGiftCollectRecord( msgId, msgDign, onSuccess, onFaild )   
    local requestInfo = {}
    local simpleInfo = ClanManager:getClanSimpleInfo()
    requestInfo.cid = simpleInfo:getTeamCid() -- 公会id
    requestInfo.msgId = msgId -- 玩家udid
    requestInfo.msgSign = msgDign -- 邀玩家的udid
    G_GetNetModel(NetType.Clan):sendTeamRedGiftCollectRecord(requestInfo, onSuccess, onFaild) 
end

----------------------- 公会 红包 -----------------------

----------------------- 公会 对决（限时比赛） -----------------------
-- 请求 公会对决排行榜信息
function ClanSyncManager:sendClanDuelRank( onSuccess, onFaild )   
    local requestInfo = {
        data = {
            params = {}
        }
    }
    G_GetNetModel(NetType.Clan):sendClanDuelRank(requestInfo, onSuccess, onFaild) 
end
----------------------- 公会 对决（限时比赛） -----------------------

function ClanSyncManager:getInstance()
    if self._instance == nil then
        self._instance = ClanSyncManager.new()
    end
    return self._instance
end

return ClanSyncManager
