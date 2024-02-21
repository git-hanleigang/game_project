
-- 公会数据解析

local ClanConfig = util_require("data.clanData.ClanConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local ClanNetModel = class("ClanNetModel", BaseNetModel)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanNetModel:ctor()
    ClanNetModel.super.ctor(self)

    self.m_reqIngList = {}
end

---------------------  公会基础功能  ---------------------
-- 请求公会基础数据
function ClanNetModel:requestClanInfo(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求公会基础数据") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_INFO, requestInfo, onSuccess, onFaild)
end

-- 拉取公会成员列表
function ClanNetModel:requestClanMemberList(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求公会成员列表") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_MEMBER, requestInfo, onSuccess)
    gLobalViewManager:removeLoadingAnima() -- 拉取公会成员不加蒙版
end

-- 会长更改成员职位
function ClanNetModel:sendChangePositionReq(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("会长更改成员职位") then
        return
    end
    self:sendRequest(ProtoConfig.REQUEST_MEMBER_POSITION, requestInfo, onSuccess)
end

-- 同步新老职位信息
function ClanNetModel:sendSyncSelfPositionReq(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("同步新老职位信息") then
        return
    end
    self:sendRequest(ProtoConfig.REQUEST_SYNC_POSITION, requestInfo, onSuccess)
end
---------------------  公会创建修改  ---------------------
-- 请求创建公会
function ClanNetModel:requestCreateClan(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求创建公会") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_CREATE, requestInfo, onSuccess)
end

-- 请求创建公会(花费钻石)
function ClanNetModel:requestCreateClan_Gem(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求创建公会") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_CREATE_GEM, requestInfo, onSuccess)
end

-- 请求编辑公会信息 --
function ClanNetModel:requestClanInfoEdit(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求编辑公会信息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_EDIT, requestInfo, onSuccess)
end

-- 请求修改公会名称 --
function ClanNetModel:requestClanNameEdit(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求修改公会名称") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_RENAME, requestInfo, onSuccess)
end




---------------------  公会成员管理  ---------------------
-- 拉取申请入会成员列表
function ClanNetModel:requestClanApplyList(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("拉取申请入会成员列表") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_APPLY_LIST, requestInfo, onSuccess)
end

-- 发送玩家入会申请处理消息(同意 拒绝 清空)
function ClanNetModel:requestClanApply(type, requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("发送玩家入会申请处理消息") then
        return
    end

    
    self:sendRequest(type, requestInfo, onSuccess)
end

-- 发送踢出玩家请求
function ClanNetModel:requestKickMember( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("发送踢出玩家请求") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_KICK, requestInfo, onSuccess)
end

-- 玩家离开公会的请求消息
function ClanNetModel:requestLeaveClan(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("发送离开公会请求") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_LEAVE, requestInfo, onSuccess)
end

-- 邀请玩家加入公会
function ClanNetModel:requestUserInvite( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("邀请玩家加入公会") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_INVITE, requestInfo, onSuccess)
end




---------------------  搜索相关  ---------------------
-- 请求搜索公会 --
function ClanNetModel:requestClanSearch( requestInfo, onSuccess, onFaild )
    self:sendRequest(ProtoConfig.REQUEST_SEARCH_CLAN, requestInfo, onSuccess)
end

-- 拉取推荐公会列表
function ClanNetModel:requestRecommendClanList(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("拉取推荐公会列表") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_RECOMMEND, requestInfo, onSuccess)
end

-- 搜索玩家 --
function ClanNetModel:requestSearchUser( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("搜索玩家") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_SEARCH_USER, requestInfo, onSuccess)
end

-- 快速加入公会 --
function ClanNetModel:requestClanQuickJoin(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("快速加入公会") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_JOIN_QUICK, requestInfo, onSuccess)
end

-- 请求加入公会 --
function ClanNetModel:requestClanJoin( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求加入公会") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_JOIN, requestInfo, onSuccess)
end

-- 拒绝加入公会 --
function ClanNetModel:requestRejectInviteClan( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("拒绝加入公会") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_REJECT_CLAN_JOIN, requestInfo, onSuccess) 
end

---------------------  奖励相关  ---------------------
-- 领取任务奖励请求消息
function ClanNetModel:requestTaskReward(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("领取任务奖励请求消息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_TASK_REWARD, requestInfo, onSuccess, onFaild)
end

-- 请求fb分享邀请接口
function ClanNetModel:requestFbInvite(requestInfo, onSuccess, onFaild)
    if not self:checkRequestEnabled("请求fb分享邀请接口") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_FB_SHARE_CLAN_INFO, requestInfo, onSuccess, onFaild)
end

------------------------------------------- 聊天 -------------------------------------------
-- 请求公会聊天服务器配置数据
function ClanNetModel:requestChatServerInfo( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求公会聊天服务器配置数据") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CHAT_SERVER_INFO, requestInfo, onSuccess, onFaild)
end

-- 获取聊天奖励数据
function ClanNetModel:requestChatReward( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("获取聊天奖励数据请求") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CHAT_REWARD, requestInfo, onSuccess)
end

-- 获取聊天奖励数据 _ 一键领取
function ClanNetModel:requestCollectAllGiftReward( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("获取聊天奖励数据请求") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CHAT_REWARD_FAST, requestInfo, onSuccess)
end

-- 公会聊天发送要卡消息
function ClanNetModel:requestCardNeeded( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("公会聊天发送要卡消息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CHAT_CARD_NEEDED, requestInfo, onSuccess)
end

-- 公会聊天发送卡牌消息请求
function ClanNetModel:requestCardsData( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("公会聊天发送要卡消息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CHAT_GET_CARD_COUNT, requestInfo, onSuccess)
end

-- 公会聊天发送赠卡消息
function ClanNetModel:requestCardGiven( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("公会聊天发送赠卡消息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CHAT_CARD_GIVEN, requestInfo, onSuccess, onFaild)
end

-- 请求公会聊天服务器配置数据（短链）
function ClanNetModel:requestHttpChatServerInfo( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求公会聊天服务器配置数据短链") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_HTTP_CHAT_SERVER_INFO, requestInfo, onSuccess, onFaild)
end
------------------------------------------- 聊天 -------------------------------------------

-- 请求刷新 公会 相关的活动数据
function ClanNetModel:requestSyncClanAct( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求刷新 公会 相关的活动数据") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_SYNC_CLAN_ACT, requestInfo, onSuccess)
end

-- 公会请求排行榜信息
function ClanNetModel:sendClanRankReq( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 排行榜信息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_INFO_LIST, requestInfo, onSuccess)
end

-- 公会请求段位权益信息
function ClanNetModel:sendClanBenifitReq( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 段位权益信息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_CLAN_BENIFIT_LIST, requestInfo, onSuccess, onFaild)
end

-- 告诉服务器 重置字段
function ClanNetModel:sendResetPopReprotSign(requestInfo)
    if not self:checkRequestEnabled("请求 段位权益信息") then
        return
    end
    self:sendRequest(ProtoConfig.SYNC_POP_REPORT_LAYER_SIGN, requestInfo)
end

-- 请求本公会 各玩家排行奖励
function ClanNetModel:sendMemberRankRewardListReq( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求本公会 各玩家排行奖励") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_MEMBER_RANK_REWARD, requestInfo, onSuccess)
end

-- 请求 最强工会排行信息
function ClanNetModel:sendeRankTopListDataReq( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 最强工会排行信息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_TOP_RANK_LIST, requestInfo, onSuccess)
end

-- 请求 公会Rush挑战任务信息
function ClanNetModel:sendTeamRushInfoReqest( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 公会Rush挑战任务信息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_TEAM_RUSH_INFO, requestInfo, onSuccess)
end

----------------------- 公会 红包 -----------------------
-- 请求 公会红包 礼物信息
function ClanNetModel:sendTeamRedGiftInfo( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 公会红包 礼物信息") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_TEAM_SEND_RED_GIFT_INFO, requestInfo, onSuccess)
end

-- 请求 公会红包 领取红包
function ClanNetModel:sendTeamRedGiftCollect( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 公会红包 领取红包") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_TEAM_RED_GIFT_COLLECT, requestInfo, onSuccess)
end
-- 请求 公会红包 查看领取记录
function ClanNetModel:sendTeamRedGiftCollectRecord( requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 公会红包 查看领取记录") then
        return
    end

    self:sendRequest(ProtoConfig.REQUEST_TEAM_RED_GIFT_COLLECT_RECORD, requestInfo, onSuccess)
end
----------------------- 公会 红包 -----------------------

----------------------- 公会 对决（限时比赛） -----------------------
-- 请求 公会对决排行榜
function ClanNetModel:sendClanDuelRank(requestInfo, onSuccess, onFaild )
    if not self:checkRequestEnabled("请求 公会对决 排行榜信息") then
        return
    end

    self:sendActionMessage(ActionType.ClanDuelRank, requestInfo, onSuccess, onFaild)
end
----------------------- 公会 对决（限时比赛） -----------------------

---------------------------------------------  公共接口  ---------------------------------------------

-- 判断是否可以发送消息
function ClanNetModel:checkRequestEnabled(errorMsg)
    -- 这里只做了是否登录的检测 预留等级等一些其他的限定条件
    local isLogin = gLobalSendDataManager:isLogin()
    if errorMsg then
        local reason = ""
        if not isLogin then
            reason = " 玩家未登陆"
        end
        if reason ~= "" then
            printInfo("------>    " .. errorMsg .. reason)
        end
    end
    return isLogin
end

-- 获取协议链接
function ClanNetModel:getNetUrl( netBody )
    if netBody and netBody.url then
        return netBody.url
    end 
end

-- 获取协议描述
function ClanNetModel:getNetDesc( netBody )
    if netBody and netBody.desc then
        return netBody.desc
    end 
end

-- 发送消息接口
function ClanNetModel:sendRequest( netBody, data, onReceive, onError)
    if not netBody or not data then
        return
    end

    if self.m_reqIngList[netBody.protoType] then
        return
    end

    if netBody.preReqTime and netBody.limitReqTime then
        local subTime = os.time() - netBody.preReqTime
        if subTime < netBody.limitReqTime then
            return
        end
    end

    -- 是否隐藏loading转圈
    if not netBody.bHideLoading then
        gLobalViewManager:addLoadingAnima(false, 1)
    end

    local url = self:getNetUrl( netBody )
    assert(url, "无效的链接")
    local desc = self:getNetDesc(netBody)

    local success_call = function(responseTable)
        gLobalViewManager:removeLoadingAnima()
        self.m_reqIngList[netBody.protoType] = false

        netBody.preReqTime = os.time()

        -- config数据 GameProto_pb.ActionResponse
        local config = responseTable.config 
        if config then
            globalData.syncUserConfig(config)
        end

        -- 玩家基本信息
        local simpleUser = responseTable.simpleUser 
        if simpleUser and simpleUser.level > 0 then
            globalData.syncSimpleUserInfo(simpleUser)
        end

        -- 活动数据
        local activity = responseTable.activity
        if activity then
            globalData.syncActivityConfig(activity)
        end

        local _miniGameData = responseTable.miniGame
        if _miniGameData and _miniGameData.dartsGameResults ~= nil and #(_miniGameData.dartsGameResults) > 0 then
            G_GetMgr(ACTIVITY_REF.DartsGame):parseData(_miniGameData.dartsGameResults)
        end

        if _miniGameData and _miniGameData.dartsGameV2Results ~= nil and #(_miniGameData.dartsGameV2Results) > 0 then
            G_GetMgr(ACTIVITY_REF.DartsGameNew):parseData(_miniGameData.dartsGameV2Results)
        end

        -- 掉卡
        if CardSysManager and responseTable.cardDrop and #responseTable.cardDrop > 0 then
            CardSysManager:doDropCardsData(responseTable.cardDrop)
        end

        -- 返回码异常的通用处理
        printInfo("------>    " .. desc .. " 请求成功: " .. url)
        if onReceive then
            onReceive( responseTable )
        end
    end
    local faild_call = function(errorCode , errorData)
        gLobalViewManager:removeLoadingAnima()
        self.m_reqIngList[netBody.protoType] = false

        printInfo("------>    " .. desc .. " 请求失败: " .. url)
        if errorCode then
            printInfo("错误码 " .. tostring(errorCode))
        end
        self:onResponseError(errorCode, errorData)
        if onError then
            onError( errorCode , errorData )
        end
    end
    self:sendMessage(netBody, data, success_call, faild_call)
    self.m_reqIngList[netBody.protoType] = true
end

-- 处理服务器返回的状态码
function ClanNetModel:onResponseError( errorCode, errorData )
    if not errorCode then
        return
    end

    printInfo("errorCode " .. errorCode)
    if errorCode == BaseProto_pb.CLAN_NAME_EXIST then
        printError("公会名称已存在")
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.ERROR_CLAN_NAME_ERROR)
    elseif errorCode == BaseProto_pb.CLAN_CREATE_LIMIT then
        printError("用户还不能创建公会")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CANNOT_CREATE_CLAN)
    elseif errorCode == BaseProto_pb.USER_HAVE_CLAN then
        printError("用户已经是公会公会成员了")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.USER_HAVE_CLAN, function()
            ClanManager:notifyLeaderAgreeSelfJoin()
        end)
    elseif errorCode == BaseProto_pb.CLAN_MEMBER_FULL then
        printError("公会成员已满")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CLAN_MEMBER_FULL)
    elseif errorCode == BaseProto_pb.CLAN_LEVEL_LIMIT then
        printError("用户未达到公会等级限制")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.VIP_NOT_ENOUGH)
    elseif errorCode == BaseProto_pb.CLAN_NO_EXIST then
        printError("你被踢出公会了")
        ClanManager:kickOffByLeader()
    elseif errorCode == BaseProto_pb.OTHER_USER_HAVE_CLAN then
        printError("其他人已经有公会了")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.PLAYER_HAD_OTHER_CLAN, function()
            ClanManager:requestClanApplyList()
        end)
    elseif errorCode == BaseProto_pb.NO_CLAN_CAN_JOIN then
        printError("没有合适的公会供你加入，自己创一个吧！")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.NO_CLAN_CAN_JOIN, function()
            -- 弹出创建公会面板
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.POP_CREATE_CLAN_PANEL)
        end)
    elseif errorCode == BaseProto_pb.CLAN_SEND_CARD_NO_MORE then
        printError("公会送卡没多余的了!")
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.SEND_CARD_NO_MORE)
    elseif errorCode == BaseProto_pb.CLAN_ERROR and errorData and string.len(errorData) > 0 then
        printError("公会 统一错误码 策划配描述")
        local tipInfo = {
            title = "sp_title1", -- sorry
            content = errorData
        }
        ClanManager:popCommonTipPanel(tipInfo)
    else
        printError("未知错误 数据结构异常")
    end
end


-- 发送网络消息
function ClanNetModel:sendMessage(protoInfo, tbData, successFunc, failedFunc )
    if not protoInfo then
        return
    end

    local _requestBody = self:getProtoRequest(protoInfo)
    if protoInfo.protoType ==  ProtoConfig.REQUEST_CHAT_REWARD_FAST.protoType then
        _requestBody.cid = tbData.cid
        for _, msgId in ipairs(tbData.msgIds or {}) do
           _requestBody.msgIds:append(msgId)
        end
        for _, msgSign in ipairs(tbData.msgSigns or {}) do
            _requestBody.msgSigns:append(msgSign)
        end
    else
        -- table数据打包到request对象中
        self:packBody(_requestBody, tbData)
    end

    self:_sendMessage(protoInfo, _requestBody, successFunc, failedFunc)
end

return ClanNetModel
