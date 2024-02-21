--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-11 00:20:33
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-02 14:03:49
FilePath: /SlotNirvana/src/data/clanData/ChatConfig.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
-- 公会聊天相关配置

local ChatConfig = {}

---------------------------------    协议相关    ---------------------------------

ChatConfig.productNo = "1000001"    -- 平台编号 这个是服务器分配的固定值 跟产品绑定

ChatConfig.REQUEST_TYPE = {
    AUTH = 1001,            -- //认证
    SYNC = 1002,            -- //同步数据
    SEND = 1003,            -- //发送消息
    HEART = 1004,           -- //心跳
    COLLECT = 1005,         -- //领取
    NOTICE = 1006,          -- //通知
    COLLECT_ALL = 1007,          -- //领取全部
}

ChatConfig.RESPONSE_CODE = {
    SUCCEED = 1,                -- //成功
    SYSTEM_ERROR = 2,           -- //系统异常
    ILLEGAL_ARGUMENT = 3,       -- //参数非法
    AUTHORIZATION_FAILED = 4,   -- //认证失败
    SID_ILLEGAL = 5,            -- //SID无效
}
  



---------------------------------    UI相关    ---------------------------------
ChatConfig.NOTICE_TYPE = {
    COMMON = 1,                     -- 常规聊天消息列表刷新
    CHIPS = 2,                      -- 卡牌申请列表刷新
    GIFT = 3,                       -- 礼物领取列表刷新
    CHAT = 4,                     -- 普通文本表情聊天
}

-- 消息类型
ChatConfig.MESSAGE_TYPE = {
    TEXT = 1,                   --//普通文字&表情消息 显示在 all 选项里
    JACKPOT = 2,                --//jackpot大奖 显示在 gift 选项里
    CARD_CLAN = 3,              --//卡册集齐 显示在 gift 选项里
    CASHBONUS_JACKPOT = 4,      --//每日转盘中jackpot 显示在 gift 选项里 
    PURCHASE = 5,               --//充值 显示在 gift 选项里
    CLAN_CHALLENGE = 6,         --//公会挑战 显示在 all 选项里
    CLAN_MEMBER_CARD = 7,       --//公会内索求集卡 显示在 chips 选项里
    SYSTEM = 8,                 --//系统消息 显示在 all 选项里
    LOTTERY = 9,                --//乐透中奖消息 显示在 gift 选项里
    RANK_REWARD = 10,           --//公会排行榜结算消息 显示在 gift 选项里
    RUSH_REWARD = 11,           --//公会Rush奖励消息 显示在 gift 选项里
    JACKPOT_SHARE = 12,         --//jackpot大奖分享 显示在 gift 选项里
    AVATAR_FRAME = 13,          --//头像框获取奖励
    RED_PACKAGE = 14,           --//红包
    RED_PACKAGE_COLLECT = 15,   --//红包领取
    CLAN_DUEL = 16,             --//公会Duel奖励消息
}

-- 事件名称
ChatConfig.EVENT_NAME = {
    RECIEVE_CHAT_SERVER_INFO_SUCCESS = "RECIEVE_CHAT_SERVER_INFO_SUCCESS", -- 获取到聊天服务器配置信息
    CHAT_REWARD_GETDATA = "CHAT_REWARD_GETDATA",    -- 获取聊天奖励数据
    CHAT_REWARD_GETDATA_ALL = "CHAT_REWARD_GETDATA_ALL",  -- 获取聊天奖励 gift 数据--all 一键领取
    CHAT_REWARD_WHEEL_PLAYOVER = "CHAT_REWARD_WHEEL_PLAYOVER",  -- 聊天奖励领取完毕
    CHAT_SEND_EMOJI_MESSAGE = "CHAT_SEND_EMOJI_MESSAGE", -- 发送emoji
    CHAT_SEND_REQ_CARD_NEED = "CHAT_SEND_REQ_CARD_NEED", -- 请求要卡成功
    NOTIFY_CLAN_CHAT_SYNC_REFRESH = "NOTIFY_CLAN_CHAT_SYNC_REFRESH", -- 公会聊天刷新
    NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH = "NOTIFY_CLAN_CHAT_ADD_NEW_REFRESH", -- 公会聊天刷新 _新增
    NOTIFY_CLAN_CHAT_REFCEIVE = "NOTIFY_CLAN_CHAT_REFCEIVE", -- 公会聊天数据获取
    NOTIFY_CARD_DATA_READY = "NOTIFY_CARD_DATA_READY", -- 公会 拉取卡牌信息
    NOTIFY_CARD_DATA_CHANGE = "NOTIFY_CARD_DATA_CHANGE", -- 公会 卡牌信息更改
    NOTIFY_CARD_HAD_SEND = "NOTIFY_CARD_HAD_SEND", -- 公会 送卡 卡已被其他玩家送了

    UPDATE_CHAT_REWARD_DATA = "UPDATE_CHAT_REWARD_DATA", -- 更新奖励类型聊天消息Data
    UPDATE_CHAT_REWARD_UI = "UPDATE_CHAT_REWARD_UI", -- 更新奖励类型聊天消息UI
    SWITCH_FAST_COLLECT_VIEW_STATE = "SWITCH_FAST_COLLECT_VIEW_STATE", --更新一键领取view 状态
    CHECK_FAST_COLLECT_VIEW_VISIBLE = "CHECK_FAST_COLLECT_VIEW_VISIBLE", --更新一键领取按钮的先显隐

    COLLECTED_TEAM_RED_GIFT_SUCCESS = "COLLECTED_TEAM_RED_GIFT_SUCCESS", --领取工会红包成功
    NOTIFY_REFRESH_RED_GIFT_CHAT_TOP = "NOTIFY_REFRESH_RED_GIFT_CHAT_TOP", -- 刷新红包置顶消息
    NOTIFY_REFRESH_RED_GIFT_CHAT = "NOTIFY_REFRESH_RED_GIFT_CHAT", -- 红包消息更新

    DELETE_DATABASE_MEMBER = "DELETE_DATABASE_MEMBER", --玩家退出或被踢更新 成员数据
    NOTIFY_UPDATE_MEMBER = "NOTIFY_UPDATE_MEMBER", --玩家新加入更新 成员数据
}

-- tcp链接情况
ChatConfig.TCP_STATE = {
    CLOSED = 1, -- 未连接
    CONNECTING = 2, -- 链接中
    RE_CONNECTING = 3, -- 重连中
}
ChatConfig.TCP_TIP_STR = {
    CLOSED = "The Wall is being maintained.\n       Please wait patiently.", -- 未连接
    RE_CONNECTING = "Reconnecting to the Wall", -- 重连中
}

-- 聊天天 消息限制个数
ChatConfig.MESSAGE_LIMIT_ENUM ={
    ALL = 100, -- 所有聊天的
    CHAT = 100, -- 普通聊天
    CHIPS = 80, -- 赠送索要的卡片的
    GIFT = 150, -- 奖励的 (一键领取已gift消息为主 gift应大于等于ALL)
    RED = 150, -- 红包奖励的
}

return ChatConfig

