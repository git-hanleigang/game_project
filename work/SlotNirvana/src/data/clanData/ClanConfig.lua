-- 公会相关配置

local ClanConfig = {}

-- 玩家身份
ClanConfig.userIdentity = {
    NON = "non",            -- 非公会成员
    LEADER = "LEADER",      -- 会长
    MEMBER = "NORMAL",      -- 普通成员
    ELITE = "ELITE",        -- 精英
}

-- 玩家状态
ClanConfig.userState = {
    NON = 0,            -- 非公会成员
    APPLY = 1,          -- 申请中
    MEMBER = 2,         -- 公会成员
}

-- 入会审批设置
ClanConfig.joinLimitType = {
    PUBLIC =  1,    -- 自动加人 不需要审核
    REQUEST = 2,    -- 需要审核
}
ClanConfig.joinLimitTypeStr = {"PUBLIC", "APPLICATION"}

-- 处理入会申请
ClanConfig.applyAnswer = {
    AGREE = 1,              -- 同意
    REFUSE = 2,             -- 拒绝
    CLEAR = 3,              -- 清除(全部拒绝)
}

-- 功能 入口
ClanConfig.systemEnum = {
    MAIN = 1, -- 主页
    CHAT = 2, -- 聊天
    MEMEBER = 3, -- 成员
    RANK = 4, -- 排行榜界面
}

-- 排行榜升降
ClanConfig.RankUpDownEnum = {
    UP = 1,
    DOWN = 2,
    UNCHANGED = 3, 
}

-- 公会rush任务类型
ClanConfig.RushTaskType = {
    ACT = 1, -- 大活动消耗道具
    QUEST = 2, -- quest完成关卡
    CHIP = 3, -- 集卡收集赠送
}

-- 公会的 相关事件
ClanConfig.EVENT_NAME = {
    -- http
    RECIEVE_CLAN_INFO_DATA = "RECIEVE_CLAN_INFO_DATA", -- 请求接收到公会基础数据
    RECIEVE_CLAN_INFO_DATA_FAILD = "RECIEVE_CLAN_INFO_DATA_FAILD", -- 请求接收到公会基础数据_faild
    RECIEVE_CLAN_MEMBER_LIST = "RECIEVE_CLAN_MEMBER_LIST", -- 请求接收到公会成员列表
    RECIEVE_CLAN_APPLICANT_LIST = "RECIEVE_CLAN_APPLICANT_LIST", -- 请求接收到公会申请列表
    RECIEVE_CLAN_AGREE_USER_JOIN = "RECIEVE_CLAN_AGREE_USER_JOIN", -- 同意玩家入会
    RECIEVE_CLAN_REJECT_USER_JOIN = "RECIEVE_CLAN_REJECT_USER_JOIN", -- 拒绝玩家入会
    RECIEVE_CLAN_APPLICANT_CLEAR = "RECIEVE_CLAN_APPLICANT_CLEAR", -- 清空公会申请列表
    RECIEVE_CLAN_MAIN_CHALLENGE_REWARD = "RECIEVE_CLAN_MAIN_CHALLENGE_REWARD", -- 接收到 领取挑战奖励
    RECIEVE_CLAN_MAIN_TASK_INFO = "RECIEVE_CLAN_MAIN_TASK_INFO", --  请求公会任务数据
    RECIEVE_USER_LEAVE_CLAN = "RECIEVE_USER_LEAVE_CLAN", --  收到 玩家 退出公会
    RECIEVE_CHAGE_CLAN_NAME = "RECIEVE_CHAGE_CLAN_NAME", -- 更改公会 名字
    RECIEVE_NEW_CLAN_INFO_SUCCESS = "RECIEVE_NEW_CLAN_INFO_SUCCESS", -- 收到 会长更改公会信息消息
    RECIEVE_CLAN_SEARCH = "RECIEVE_CLAN_SEARCH", -- 搜索公会
    RECIEVE_CLAN_GEM_SUCCESS = "RECIEVE_CLAN_GEM_SUCCESS",   -- 花费钻石创建公会
    RECIEVE_CLAN_CREATE_SUCCESS = "RECIEVE_CLAN_CREATE_SUCCESS", -- 创建公会成功
    RECIEVE_FAST_JOIN_CLAN_SUCCESS = "RECIEVE_FAST_JOIN_CLAN_SUCCESS", -- 快速加入公会成功
    RECIEVE_JOIN_CLAN_SUCCESS = "RECIEVE_JOIN_CLAN_SUCCESS", -- 加入公会成功
    RECIEVE_REJECT_JOIN_CLAN_SUCCESS = "RECIEVE_REJECT_JOIN_CLAN_SUCCESS", -- 拒绝公会成功
    RECIEVE_SEARCH_USER_SUCCESS = "RECIEVE_SEARCH_USER_SUCCESS", -- 搜索玩家 成功
    RECIEVE_INVITE_USER_SUCCESS = "RECIEVE_INVITE_USER_SUCCESS", -- 邀请玩家 成功
    RECIEVE_TEAM_RANK_INFO_SUCCESS = "RECIEVE_TEAM_RANK_INFO_SUCCESS", -- 请求公会排行榜信息成功
    RECIEVE_TEAM_BENIFIT_SUCCESS = "RECIEVE_TEAM_BENIFIT_SUCCESS", -- 请求公会权益信息成功
    RECIEVE_MEMBER_RANK_REWARD_SUCCESS = "RECIEVE_MEMBER_RANK_REWARD_SUCCESS", -- 请求本公会各玩家排行奖励成功
    RECIEVE_TEAM_TOP_RANK_LIST_SUCCESS = "RECIEVE_TEAM_TOP_RANK_LIST_SUCCESS", -- 请求最强工会排行信息成功
    RECIEVE_TEAM_RUSH_SUCCESS = "RECIEVE_TEAM_RUSH_SUCCESS", -- 接收到公会rush信息成功
    RECIEVE_CHANGE_MEMBER_POSITION = "RECIEVE_CHANGE_MEMBER_POSITION", -- 接收到修改成员职位成功
    RECIEVE_TEAM_RED_GIFT_INFO_SUCCESS = "RECIEVE_TEAM_RED_GIFT_INFO_SUCCESS", --接收到送红包 礼物信息
    RECIEVE_TEAM_RED_COLLECT_RECORD_SUCCESS = "RECIEVE_TEAM_RED_COLLECT_RECORD_SUCCESS", --接收到红包 领取记录
    
    -- errorCode
    ERROR_CLAN_NAME_ERROR = "ERROR_CLAN_NAME_ERROR", -- 公会名字已经存在

    -- UI
    HIDE_OTHER_BUBBLE_TIP_VIEW = "HIDE_OTHER_BUBBLE_TIP_VIEW", -- 隐藏其他的 气泡提示
    UPDATE_MACHINE_ENTRY_PROG = "UPDATE_MACHINE_ENTRY_PROG", -- 更新关卡内入口的进度
    CLOSE_CLNA_PANEL_UI = "CLOSE_CLNA_PANEL_UI", -- 关闭弹板事件
    SELECT_CLAN_LOGO_CELL = "SELECT_CLAN_LOGO_CELL", -- 选中公会 logo cell
    SAVE_SELECT_CLAN_LOGO = "SAVE_SELECT_CLAN_LOGO", -- 保存选中的公会 logo
    CLOSE_CLAN_GUIDE_LAYER = "CLOSE_CLAN_GUIDE_LAYER", -- 关闭引导界面事件
    TASK_REWARD_BOX_ACTION_OVER = "TASK_REWARD_BOX_ACTION_OVER", --阶段 宝箱动画播放完毕
    UPDATE_FAQ_LISTVIEW = "UPDATE_FAQ_LISTVIEW" , -- 点击faqcell更新listView
    KICKED_OFF_TEAM = "KICKED_OFF_TEAM", -- 你被踢出公会了
    CLOSE_CLAN_HOME_VIEW = "CLOSE_CLAN_HOME_VIEW", --关闭公会界面
    UPDATE_TOP_RANK_SELF_VIEW_VISIBLE = "UPDATE_TOP_RANK_SELF_VIEW_VISIBLE", -- 最强工会自己的信息显隐
    HIDE_RUSH_GIT_BUBBLE_TIP = "HIDE_RUSH_GIT_BUBBLE_TIP", -- 隐藏rush奖励气泡
    REFRESH_ENTRY_UI = "REFRESH_ENTRY_UI", -- 刷新关卡入口UI
    UPDATE_CHOOSE_REGION_UI = "UPDATE_CHOOSE_REGION_UI", -- 刷新选择的地区UI
    NOTIFY_TEAM_EDIT_SHOW_NEXT_PAGE = "NOTIFY_TEAM_EDIT_SHOW_NEXT_PAGE", --引导显示编辑公会界面第二页
    NOTIFY_SHOW_POSITION_FLOAT_VIEW = "NOTIFY_SHOW_POSITION_FLOAT_VIEW", -- 引导显示职位变化floatView
    UPDATE_DUEL_RANK_SELF_VIEW_VISIBLE = "UPDATE_DUEL_RANK_SELF_VIEW_VISIBLE", -- 公会对决自己的信息显隐
    CLAN_DUEL_TIME_OUT = "CLAN_DUEL_TIME_OUT", -- 公会对决倒计时结束
    CLAN_DUEL_REQUEST_RANK = "CLAN_DUEL_REQUEST_RANK", -- 公会对决请求排行榜
    CLAN_ENTRY_REFRESH = "CLAN_ENTRY_REFRESH", -- 公会入口刷新（显示rush or duel）

    -- 逻辑
    SEND_SYNC_CLAN_ACT_DATA = "SEND_SYNC_CLAN_ACT_DATA", -- 同步公会配套的活动数据
    POP_CREATE_CLAN_PANEL = "POP_CREATE_CLAN_PANEL", -- 弹出出创建公会面板
    RUSH_TASK_JUMP_TO_OTHER_FEATURE = "RUSH_TASK_JUMP_TO_OTHER_FEATURE", -- 公会rush任务挑战到对应任务功能
    NOTIFY_RUSH_DEAL_GUIDE = "NOTIFY_RUSH_DEAL_GUIDE", --通知rush进行新手引导处理
}

ClanConfig.messageMaxNum = 200  -- 设定聊天记录保存最多200条
ClanConfig.CLAN_NAME_LIMIT_SIZE = 15 -- 公会名字限制大小
ClanConfig.CLAN_DESC_LIMIT_SIZE = 150 -- 公会名字限制大小
ClanConfig.MAX_LOGO_COUNT = 25 -- 最大的勋章数


-- 上一期 公会任务完成情况
ClanConfig.LastTaskState = {
    -- 0未完成 1 已完成 2 已领取
    UNDONE      = 0,
    DONE        = 1,
    COLLECTED   = 2,
}

-- 公会相关音乐
ClanConfig.MUSIC_ENUM ={
    BG = "Club/sounds/clan_bgm.mp3",
    NEW_CHAT_INFO = "Club/sounds/clan_new_chat_info.mp3",
    NEXT_BOX_SHAKE = "Club/sounds/clan_next_phase_box.mp3",
    TASK_BOX_UNLOCK = "Club/sounds/clan_task_box_unlock.mp3",
    TASK_DONE = "Club/sounds/clan_task_done_pop.mp3",
    TASK_DONE_REWARD_INFO = "Club/sounds/clan_task_done_reward_info_pop.mp3",
    TASK_UNDONE = "Club/sounds/clan_task_undone_pop.mp3",
    UNLOCK_NEXT_TASK = "Club/sounds/clan_unlock_next_task.mp3",
    RANK_REPORT_UP = "Club/sounds/clan_rank_report_up.mp3",
    RED_GIFT_OPEN_BOX = "Club/sounds/clan_red_gift_open_box.mp3",

    CLICK_INFO_TAG = "Club/sounds/Team_style_click.mp3",
    REGION_LIST_OPEN = "Club/sounds/Team_list_open.mp3",
    REGION_LIST_CLOSE = "Club/sounds/Team_list_close.mp3",
    REGION_LIST_SCROLL = "Club/sounds/Team_list_slide.mp3",

    CLUB_TOP_CHANGE = "Club/sounds/Club_TOP_Change.mp3",
}

-- 段位图和描述
ClanConfig.RANK_RESOURCE_PATH = {
    ICON = {
        "Club/ui/Rank/rank_icon/Rank_Novice1.png",
        "Club/ui/Rank/rank_icon/Rank_Novice2.png",
        "Club/ui/Rank/rank_icon/Rank_Elite1.png",
        "Club/ui/Rank/rank_icon/Rank_Elite2.png",
        "Club/ui/Rank/rank_icon/Rank_Master1.png",
        "Club/ui/Rank/rank_icon/Rank_Master2.png",
        "Club/ui/Rank/rank_icon/Rank_Glory1.png",
        "Club/ui/Rank/rank_icon/Rank_Glory2.png",
        "Club/ui/Rank/rank_icon/Rank_Mythic1.png",
    },
    DESC = {
        "Club/ui/Rank/rank_desc/RANK_NOVICE1.png",
        "Club/ui/Rank/rank_desc/RANK_NOVICE2.png",
        "Club/ui/Rank/rank_desc/RANK_ELITE1.png",
        "Club/ui/Rank/rank_desc/RANK_ELITE2.png",
        "Club/ui/Rank/rank_desc/RANK_MASTER1.png",
        "Club/ui/Rank/rank_desc/RANK_MASTER2.png",
        "Club/ui/Rank/rank_desc/RANK_GLORY1.png",
        "Club/ui/Rank/rank_desc/RANK_GLORY2.png",
        "Club/ui/Rank/rank_desc/RANK_MYTHIC.png",
    }

}
-- 段位图和描述
ClanConfig.RANK_DIVISION_DESC = {
    "NOVICE I",
    "NOVICE II",
    "ELITE I",
    "ELITE II",
    "MASTER I",
    "MASTER II",
    "GLORY I",
    "GLORY II",
    "MYTHIC",
}

-- 公会Tag
ClanConfig.TAG_CAN_CHOOSE_MAX = 3
ClanConfig.TAG_NAME_LIST = {"BEGINNERS","CASUAL","TRADERS","ACTIVE","HELPERS","RISING","EVERYDAY","GAMBLERS","COMPETITORS"}

return ClanConfig