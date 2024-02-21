

------------------------------------------------    公会相关    ------------------------------------------------

-- 请求刷新 公会 相关的活动数据
ProtoConfig.REQUEST_SYNC_CLAN_ACT = {
    protoType = "REQUEST_SYNC_CLAN_ACT",
    sign = "TOKEN",
    url = "/v1/game/config/features/clanActivity",
    request = GameProto_pb.FeaturesResultRequest,
    response = BaseProto_pb.FeaturesData,
    desc = "请求刷新 公会 相关的活动数据",
    bHideLoading = true
}

------------------------ 公会基础功能 ------------------------
-- 请求公会聊天服务器配置数据
ProtoConfig.REQUEST_CHAT_SERVER_INFO = {
    protoType = "REQUEST_CLAN_INFO",
    sign = "TOKEN",
    url = "/v1/clan/server",
    request = ClanProto_pb.ClanServerRequest,
    response = ClanProto_pb.ClanServerResponse,
    desc = "请求公会聊天服务器配置数据",
    bHideLoading = true
}
-- 请求公会基础数据
ProtoConfig.REQUEST_CLAN_INFO = {
    protoType = "REQUEST_CLAN_INFO",
    sign = "TOKEN",
    url = "/v1/clan/info",
    request = ClanProto_pb.ClanInfoRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "请求公会基础数据",
}
-- 请求公会基成员列表
ProtoConfig.REQUEST_CLAN_MEMBER = {
    protoType = "REQUEST_CLAN_MEMBER",
    sign = "TOKEN",
    url = "/v1/clan/member",
    request = ClanProto_pb.ClanMemberRequest,
    response = ClanProto_pb.ClanMemberResponse,
    desc = "请求公会基成员列表",
    bHideLoading = true,
    limitReqTime = 10,
}
-- 请求 公会任命职位
ProtoConfig.REQUEST_MEMBER_POSITION = {
    protoType = "REQUEST_MEMBER_POSITION",
    sign = "TOKEN",
    url = "/v1/clan/member/appoint",
    request = ClanProto_pb.ClanAppointRequest,
    response = ClanProto_pb.ClanMemberResponse,
    desc = "-- 请求 公会任命职位",
    bHideLoading = true,
}
-- 请求 同步新老职位信息
ProtoConfig.REQUEST_SYNC_POSITION = {
    protoType = "REQUEST_SYNC_POSITION",
    sign = "TOKEN",
    url = "/v1/clan/position/update",
    request = ClanProto_pb.ClanAppointRequest,
    response = BaseProto_pb.Response,
    desc = "-- 请求 同步新老职位信息",
    bHideLoading = true,
}
------------------------ 修改公会信息 ------------------------
-- 请求创建公会
ProtoConfig.REQUEST_CLAN_CREATE = {
    protoType = "REQUEST_CLAN_CREATE",
    sign = "TOKEN",
    url = "/v1/clan/create",
    request = ClanProto_pb.ClanRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "请求创建公会",
}
-- 请求创建公会(花费第二货币)
ProtoConfig.REQUEST_CLAN_CREATE_GEM = {
    protoType = "REQUEST_CLAN_CREATE_GEM",
    sign = "TOKEN",
    url = "/v1/clan/gem/skip",
    request = ClanProto_pb.ClanRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "请求创建公会(花费钻石)",
}
-- 请求修改公会信息(不包含名称 改名要花钱)
ProtoConfig.REQUEST_CLAN_EDIT = {
    protoType = "REQUEST_CLAN_EDIT",
    sign = "TOKEN",
    url = "/v1/clan/update",
    request = ClanProto_pb.ClanRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "请求修改公会信息(不包含名称 改名要花钱)",
}
-- 请求修改公会名称
ProtoConfig.REQUEST_CLAN_RENAME = {
    protoType = "REQUEST_CLAN_RENAME",
    sign = "TOKEN",
    url = "/v1/clan/name/update",
    request = ClanProto_pb.ClanRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "请求修改公会名称",
}

------------------------ 公会成员管理 ------------------------
-- 请求申请入会成员列表
ProtoConfig.REQUEST_CLAN_APPLY_LIST = {
    protoType = "REQUEST_CLAN_APPLY_LIST",
    sign = "TOKEN",
    url = "/v1/clan/apply/list",
    request = ClanProto_pb.ClanListRequest,
    response = ClanProto_pb.ClanMemberResponse,
    desc = "请求申请入会成员列表",
    bHideLoading = true
}
-- 拒绝入会申请(可以批量拒绝)
ProtoConfig.REQUEST_CLAN_APPLY_REFUSE = {
    protoType = "REQUEST_CLAN_APPLY_REFUSE",
    sign = "TOKEN",
    url = "/v1/clan/apply/refuse",
    request = ClanProto_pb.ClanApplyRequest,
    response = ClanProto_pb.ClanApplyResponse,
    desc = "拒绝入会申请(可以批量拒绝)",
}
-- 同意入会申请
ProtoConfig.REQUEST_CLAN_APPLY_AGREE = {
    protoType = "REQUEST_CLAN_APPLY_AGREE",
    sign = "TOKEN",
    url = "/v1/clan/apply/agree",
    request = ClanProto_pb.ClanApplyRequest,
    response = ClanProto_pb.ClanApplyResponse,
    desc = "同意入会申请",
}
-- 退出公会
ProtoConfig.REQUEST_CLAN_LEAVE = {
    protoType = "REQUEST_CLAN_LEAVE",
    sign = "TOKEN",
    url = "/v1/clan/leave",
    request = ClanProto_pb.ClanLeaveRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "退出公会",
}
-- 踢出公会
ProtoConfig.REQUEST_CLAN_KICK = {
    protoType = "REQUEST_CLAN_KICK",
    sign = "TOKEN",
    url = "/v1/clan/member/kick",
    request = ClanProto_pb.ClanKickRequest,
    response = ClanProto_pb.ClanMemberResponse,
    desc = "踢出公会",
}
-- 邀请玩家
ProtoConfig.REQUEST_INVITE = {
    protoType = "REQUEST_INVITE",
    sign = "TOKEN",
    url = "/v1/clan/invite",
    request = ClanProto_pb.ClanInviteRequest,
    response = BaseProto_pb.Response,
    desc = "邀请玩家",
}

------------------------ 搜索相关 ------------------------
-- 推荐公会
ProtoConfig.REQUEST_CLAN_RECOMMEND = {
    protoType = "REQUEST_CLAN_RECOMMEND",
    sign = "TOKEN",
    url = "/v1/clan/recommend",
    request = ClanProto_pb.ClanSearchRequest,
    response = ClanProto_pb.ClanSearchResponse,
    desc = "推荐公会",
}
-- 搜索公会
ProtoConfig.REQUEST_SEARCH_CLAN = {
    protoType = "REQUEST_SEARCH_CLAN",
    sign = "TOKEN",
    url = "/v1/clan/search",
    request = ClanProto_pb.ClanSearchRequest,
    response = ClanProto_pb.ClanSearchResponse,
    desc = "搜索公会",
}

-- 搜索玩家
ProtoConfig.REQUEST_SEARCH_USER = {
    protoType = "REQUEST_SEARCH_USER",
    sign = "TOKEN",
    url = "/v1/clan/search/user",
    request = ClanProto_pb.ClanSearchRequest,
    response = ClanProto_pb.ClanSearchUserResponse,
    desc = "搜索玩家",
}

-- 申请加入公会
ProtoConfig.REQUEST_CLAN_JOIN = {
    protoType = "REQUEST_CLAN_JOIN",
    sign = "TOKEN",
    url = "/v1/clan/apply/join",
    request = ClanProto_pb.ClanJoinRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "申请加入公会",
}

-- 拒绝加入公会
ProtoConfig.REQUEST_REJECT_CLAN_JOIN = {
    protoType = "REQUEST_REJECT_CLAN_JOIN",
    sign = "TOKEN",
    url = "/v1/clan/invite/refuse",
    request = ClanProto_pb.ClanInviteRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "拒绝加入公会",
}

-- 快去加入公会 由系统自动分配
ProtoConfig.REQUEST_CLAN_JOIN_QUICK = {
    protoType = "REQUEST_CLAN_JOIN_QUICK",
    sign = "TOKEN",
    url = "/v1/clan/quick/join",
    request = nil,
    response = ClanProto_pb.ClanResponse,
    desc = "快去加入公会 由系统自动分配",
}

------------------------ 奖励相关 ------------------------
-- 请求公会挑战奖励
ProtoConfig.REQUEST_CLAN_CHALLENGE_REWARD = {
    protoType = "REQUEST_CLAN_CHALLENGE_REWARD",
    sign = "TOKEN",
    url = "/v1/clan/challenge/collect",
    request = ClanProto_pb.ClanChallengeCollectRequest,
    response = GameProto_pb.ActionResponse,
    desc = "请求公会挑战奖励",
}
-- 请求公会任务奖励
ProtoConfig.REQUEST_CLAN_TASK_REWARD = {
    protoType = "REQUEST_CLAN_TASK_REWARD",
    sign = "TOKEN",
    url = "/v1/clan/points/reward",
    request = nil,
    response = GameProto_pb.ActionResponse,
    desc = "请求公会任务奖励",
    bHideLoading = true
}

------------------------ fb相关 ------------------------ 
-- 请求fb邀请公会信息 
ProtoConfig.REQUEST_FB_SHARE_CLAN_INFO = {
    protoType = "REQUEST_FB_SHARE_CLAN_INFO",
    sign = "TOKEN",
    url = "/v1/clan/invite/facebook",
    request = ClanProto_pb.ClanInviteRequest,
    response = ClanProto_pb.ClanResponse,
    desc = "请求fb邀请公会信息",
    bHideLoading = true
}

------------------------ 聊天相关 ------------------------
-- 请求公会聊天领奖数据(获取充值、jackpot等的奖励金币数值)
ProtoConfig.REQUEST_CHAT_REWARD = {
    protoType = "REQUEST_CHAT_REWARD",
    sign = "TOKEN",
    url = "/v1/clan/chat/reward/collect",
    request = ClanProto_pb.ClanChatRewardRequest,
    response = GameProto_pb.ActionResponse,
    desc = "请求聊天领奖数据",
}
-- 一键领取
ProtoConfig.REQUEST_CHAT_REWARD_FAST = {
    protoType = "REQUEST_CHAT_REWARD_FAST",
    sign = "TOKEN",
    url = "/v1/clan/chat/reward/collect/all",
    request = ClanProto_pb.ClanChatRewardRequest,
    response = GameProto_pb.ActionResponse,
    desc = "请求聊天领奖数据-一键领取",
}
-- 公会聊天索要卡牌
ProtoConfig.REQUEST_CHAT_CARD_NEEDED = {
    protoType = "REQUEST_CHAT_CARD_NEEDED",
    sign = "TOKEN",
    url = "/v1/clan/card/ask",
    request = ClanProto_pb.ClanAskCardRequest,
    response = ClanProto_pb.ClanAskCardResponse,
    desc = "公会聊天索要卡牌",
}
-- 公会聊天查询卡牌数量
ProtoConfig.REQUEST_CHAT_GET_CARD_COUNT = {
    protoType = "REQUEST_CHAT_GET_CARD_COUNT",
    sign = "TOKEN",
    url = "/v1/card/exist",
    request = CardProto_pb.CardExistRequest,
    response = CardProto_pb.CardExistResponse,
    desc = "公会聊天查询卡牌数量",
}
-- 公会聊天赠送卡牌
ProtoConfig.REQUEST_CHAT_CARD_GIVEN = {
    protoType = "REQUEST_CHAT_CARD_GIVEN",
    sign = "TOKEN",
    url = "/v1/clan/card/send",
    request = ClanProto_pb.ClanSendCardRequest,
    response = ClanProto_pb.ClanSendCardResponse,
    desc = "公会聊天赠送卡牌",
}
-- 请求公会聊天服务器配置数据(短链接)
ProtoConfig.REQUEST_HTTP_CHAT_SERVER_INFO = {
    protoType = "REQUEST_HTTP_CHAT_SERVER_INFO",
    sign = "TOKEN",
    url = "/v1/clan/messages",
    request = ChatProto_pb.SyncSend,
    response = ChatProto_pb.SyncReceive,
    desc = "请求公会聊天服务器配置数据短链",
    bHideLoading = true,
    limitReqTime = 20,
}
------------------------ 排行榜 ------------------------
-- 公会请求排行榜信息
ProtoConfig.REQUEST_CLAN_INFO_LIST = {
    protoType = "REQUEST_CLAN_INFO_LIST",
    sign = "TOKEN",
    url = "/v1/clan/rank/info",
    request = nil,
    response = ClanProto_pb.ClanRankInfoResponse,
    desc = "公会请求排行榜信息",
    bHideLoading = true,
    -- limitReqTime = 10,
}

-- 公会请求段位权益信息
ProtoConfig.REQUEST_CLAN_BENIFIT_LIST = {
    protoType = "REQUEST_CLAN_BENIFIT_LIST",
    sign = "TOKEN",
    url = "/v1/clan/division/interest",
    request = nil,
    response = ClanProto_pb.ClanDivisionInterestResponse,
    desc = "公会请求段位权益信息",
    bHideLoading = true
}

-- 告诉服务器 弹出段位结算面板 重置字段
ProtoConfig.SYNC_POP_REPORT_LAYER_SIGN = {
    protoType = "SYNC_POP_REPORT_LAYER_SIGN",
    sign = "TOKEN",
    url = "/v1/clan/division/displayed",
    request = nil,
    response = BaseProto_pb.Response,
    desc = "告诉服务器 弹出段位结算面板 重置字段",
    bHideLoading = true
}

-- 请求本公会 各玩家排行奖励
ProtoConfig.REQUEST_MEMBER_RANK_REWARD = {
    protoType = "REQUEST_MEMBER_RANK_REWARD",
    sign = "TOKEN",
    url = "/v1/clan/rank/user",
    request = nil,
    response = ClanProto_pb.ClanRankUserResponse,
    desc = "请求本公会 各玩家排行奖励",
    bHideLoading = true,
    limitReqTime = 10,
}

-- 请求 最强工会排行信息
ProtoConfig.REQUEST_TOP_RANK_LIST = {
    protoType = "REQUEST_TOP_RANK_LIST",
    sign = "TOKEN",
    url = "/v1/clan/rank/top",
    request = nil,
    response = ClanProto_pb.ClanRankTopResponse,
    desc = "-- 请求 最强工会排行信息",
}
------------------------ 排行榜 ------------------------
------------------------ 公会Rush ------------------------
-- 请求 公会Rush挑战任务信息
ProtoConfig.REQUEST_TEAM_RUSH_INFO = {
    protoType = "REQUEST_TEAM_RUSH_INFO",
    sign = "TOKEN",
    url = "/v1/clan/rush/info",
    request = nil,
    response = ClanProto_pb.ClanRushInfoResponse,
    desc = "-- 请求 公会Rush挑战任务信息",
    bHideLoading = true,
}
------------------------ 公会Rush ------------------------

----------------------- 公会 红包 -----------------------
-- 请求 公会红包 礼物信息
ProtoConfig.REQUEST_TEAM_SEND_RED_GIFT_INFO = {
    protoType = "REQUEST_TEAM_SEND_RED_GIFT_INFO",
    sign = "TOKEN",
    url = "/v1/clan/red-package",
    request = nil,
    response = ClanProto_pb.ClanRedPackageResponse,
    desc = "请求 公会红包 礼物信息",
}
-- 请求 公会红包 领取红包
ProtoConfig.REQUEST_TEAM_RED_GIFT_COLLECT = {
    protoType = "REQUEST_TEAM_RED_GIFT_COLLECT",
    sign = "TOKEN",
    url = "/v1/clan/red-package/collect",
    request = ClanProto_pb.ClanRedPackageCollectRequest,
    response = ClanProto_pb.ClanRedPackageCollectResponse,
    desc = "请求 公会红包 领取红包",
}
-- 请求 公会红包 查看领取记录
ProtoConfig.REQUEST_TEAM_RED_GIFT_COLLECT_RECORD = {
    protoType = "REQUEST_TEAM_RED_GIFT_COLLECT_RECORD",
    sign = "TOKEN",
    url = "/v1/clan/red-package/collect/record",
    request = ClanProto_pb.ClanRedPackageCollectRequest,
    response = ClanProto_pb.ClanRedPackageCollectRecordResponse,
    desc = "请求 公会红包 查看领取记录",
}
----------------------- 公会 红包 -----------------------
------------------------------------------------    公会相关    ------------------------------------------------

-- 错误提示 枚举
ProtoConfig.ErrorTipEnum = {
    CANNOT_CREATE_CLAN = {
        title = "sp_title1", -- sorry
        content = "You can not create a team until tommorow!",
    }, -- 不能创建公会
    VIP_NOT_ENOUGH = {
        title = "sp_title1", -- sorry
        content = "VIP level is not high enough!",
    }, -- vip 不足
    APPLICATION_SUBMITTED = {
        title = "sp_title2", -- pending approval
        content = "Application has been submitted to the team leader. Wait a second.",
    }, -- 申请已提交
    USER_HAVE_CLAN = {
        title = "sp_title1", -- sorry
        content = "You already have a team.",
    }, -- 用户已经 有公会了不用创建了
    CLAN_MEMBER_FULL = {
        title = "sp_title1", -- sorry
        content = "The team is full",
    }, -- 公会成员已经满员
    CLAN_NOT_OPEN_LV = {
        title = "sp_title1", -- sorry
        content = "Level %d at least!", 
    }, -- 还没到开启等级
    LEAVE_CUR_CLAN = {
        title = "sp_title3", -- are you sure
        content = "Your personal team points will be cleared. Are you sure you want to leave the team?", 
        bShowCancel = true,
        bLeaveClanType = true
    }, -- 离开公会
    KICK_OFF_USER = {
        title = "sp_title3", -- are you sure
        type = "KICK_OFF_USER",
        bShowCancel = true 
    }, -- 踢成员
    USER_NAME_EMPTY = {
        title = "sp_title1", -- sorry
        content = "Please input your team name!",  
    }, -- 名字为空
    USER_DESC_EMPTY = {
        title = "sp_title1", -- sorry
        content = "Please input your team description!",  
    }, -- 公会描述为空
    CANNOT_QUICK_JOIN_CLAN = {
        title = "sp_title1", -- sorry
        content = "There are no team available, please create a team.",   
    }, -- 没有可加入的公会
    CLAN_NAME_EXIT = {
        title = "sp_title1", -- sorry
        content = "The team name already exists!",   
    }, -- 公会名字已存在
    CLAN_NO_UNLOCK = {
        title = "sp_title1", -- sorry
        content = "TEAM will be unlocked for you after lv.%d",    
    }, -- 公会功能还没解锁
    CLAN_NO_JOIN_TEAM = {
        title = "sp_title1", -- sorry
        content = "You've joined no Team now",   
    }, -- 还没加入公会快点加入吧
    KICKED_OFF_TEAM = {
        title = "sp_title1", -- sorry
        content = "You just got kicked off by the leader!",  
    }, -- 你被踢出公会了
    PLAYER_HAD_OTHER_CLAN = {
        title = "sp_title1", -- sorry
        content = "This player already have a team.",      
    }, -- 玩家已经加入了其他公会
    NO_CLAN_CAN_JOIN = {
        title = "sp_title1", -- sorry
        content = "There is no team to join temporarily. Please create a new team.",      
    }, -- 没有合适的公会供你加入
    SEND_CARD_NO_MORE = {
        title = "sp_title1", -- sorry
        content = "There are no duplicate ones of this.",      
    }, -- 公会送卡没多余的了
    CREATE_USER_RANDOM_NAME_TIP = {
        title = "sp_title4", -- notice
        content = "You're now using a suggested Team name. The next time to change it will be free.",      
    }, -- 公会用的随机名字，第一次改名免费
    ELITE_MEMBER_FULL = {
        title = "sp_title1", -- sorry
        content = "Your team can only have 2 Elite.",      
    }, -- 公会精英成员满员了
    AUTO_LEVEL_LEADER = {
        title = "sp_title4", -- sorry
        content = "Because you haven't logged in for a long time Your leader position is automatically removed.",      
    }, -- 会长自动转让
    LEADER_POSITION_CHANGE_TIP = {
        title = "sp_title3", -- are you sure
        content = "YOU WILL BECOME THE NORMAL MEMBER FOR THE TEAM!",
        bShowCancel = true,
    }, -- 会长转让会长提示弹板
    CLAN_NO_TEAM_NO_FRIEND = {
        title = "sp_title1", -- sorry
        content = "Join a team or add a friend to request",   
    }, -- 还没加入公会，也没有好友
}