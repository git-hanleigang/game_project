--[[--
	好友客户端配置
--]]
GD.FriendConfig = {}

FriendConfig.TEST_MODE = false

FriendConfig.RequestAllFriendCD = 0 -- 请求所有好友数据列表的CD时间，单位：秒

-- 好友类型
FriendConfig.FriendType = {
    FaceBook = 1,
    Game = 2,
    Both = 3
}

-- 好友请求
FriendConfig.QuestType = {
    Apply = "Apply", --加好友
    Pass = "Pass",   --通过请求
    Refuse = "Refuse", --拒绝请求
    Screening = "Screening", --永久屏蔽
    Delete = "Delete", --删除好友
}

FriendConfig.Sounds = {
    CUT = "Friends/sound/Friend_Click_Btn.mp3",  --切页
    QIPAO = "Friends/sound/Friend_Clickl_Bubble.mp3",  --气泡
    CUT_BTN = "Friends/sound/Friend_Cut.mp3"  --切换对号
}

FriendConfig.btn_img = {
    {"Friends/ui/ui_main/Friends_main_page_friends1.png","Friends/ui/ui_main/Friends_main_page_help1.png","Friends/ui/ui_main/Friends_main_page_level1.png"},
    {"Friends/ui/ui_main/Friends_main_page_friends2.png","Friends/ui/ui_main/Friends_main_page_help2.png","Friends/ui/ui_main/Friends_main_page_level2.png"}
}

--好友等级
FriendConfig.macy_img = {
    "Friends/ui/ui_main_intimacy/Friends_main_intimacy_visitor.png",
    "Friends/ui/ui_main_intimacy/Friends_main_intimacy_chum.png",
    "Friends/ui/ui_main_intimacy/Friends_main_intimacy_friend.png",
    "Friends/ui/ui_main_intimacy/Friends_main_intimacy_buddy.png",
    "Friends/ui/ui_main_intimacy/Friends_main_intimacy_bestie.png"
}

FriendConfig.EVENT_NAME = {
    FRIEND_ALL_LIST = "FRIEND_ALL_LIST", --好友列表
    FRIEND_HEAD_CLICK = "FRIEND_HEAD_CLICK", --送卡成功
    COMMOND_LIST = "COMMOND_LIST", --推荐列表
    ADD_SERCH_LIST = "ADD_SERCH_LIST", --添加搜索
    ADD_SERCH_SUCCESS = "ADD_SERCH_SUCCESS", --添加成功
    ADD_FRIEND_LIST = "ADD_FRIEND_LIST", --添加好友列表
    REQUEST_FRIEND_LIST = "REQUEST_FRIEND_LIST", --处理列表
    REQUEST_FRIEND = "REQUEST_FRIEND", --处理好友请求
    CARD_FRIEND = "CARD_FRIEND", --要卡送卡列表
    CARD_SUCCESS = "CARD_SUCCESS", --送卡成功
}

-- 加载关联网络模块
NetType.Friend = "Friend"
NetLuaModule.Friend = "GameModule.Friend.net.FriendNet"
