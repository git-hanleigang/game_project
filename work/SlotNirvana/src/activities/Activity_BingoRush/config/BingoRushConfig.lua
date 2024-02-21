-- blast活动 配置

local BingoRushConfig = {}

-- 消息列表显示类型
BingoRushConfig.MSG_TYPE = {
    HALL = "hall", -- 大厅消息
    BALL = "ball", -- 命中球消息
    GAME = "game" -- 中玩法消息 bingo、jackpot
}

-- bingoPass阶段物品状态
BingoRushConfig.PASS_PHASE_CELL_STATE = {
    UNDONE = 1, --未完成
    COMPLETE = 2, -- 完成未领取
    COLLECTED = 3, -- 已领取
    LOCK = 4, -- 锁定状态
    TO_COMPLETE = 5, -- 未完成到完成
    GO_COLLECT = 6, -- 去领取
    UNLOCK = 7 -- 解锁
}

-- 关卡选择界面
BingoRushConfig.level = "Activity/BingoRush/csb/entrance/matchEntrance_mainUi.csb" -- 关卡ui
BingoRushConfig.levelItem = "Activity/BingoRush/csb/entrance/matchEntrance.csb" -- 关卡选项卡

BingoRushConfig.bingoLoading = "Activity/BingoRush/csb/bingo_round/guoChang_layer.csb" -- bingo过场界面

-- 大厅界面
BingoRushConfig.hall = "Activity/BingoRush/csb/hall/bingoRush_hall.csb" -- 大厅ui
BingoRushConfig.hallCoins = "Activity/BingoRush/csb/hall/bingoRush_jackpot.csb" -- 大厅顶部金币条
BingoRushConfig.hallTitle = "Activity/BingoRush/csb/hall/bingoRush_hallInfo.csb" -- 大厅信息条
BingoRushConfig.matchPlayerHeadItem = "Activity/BingoRush/csb/hall/bingoRush_userCell.csb" -- 玩家头像ui
BingoRushConfig.matchMyHeadItem = "Activity/BingoRush/csb/hall/bingoRush_userCell1.csb" -- 玩家头像ui

BingoRushConfig.guide = "Activity/BingoRush/csb/guide/bingoRush_guide.csb" -- 引导界面 视频
BingoRushConfig.matchLoading = "Activity/BingoRush/csb/hall/matchLoading.csb" -- loading界面

BingoRushConfig.bingoRush_popup1 = "Activity/BingoRush/csb/promptPopup/bingoRush_popup1.csb" -- 房间解散提示
BingoRushConfig.bingoRush_popup2 = "Activity/BingoRush/csb/promptPopup/bingoRush_popup2.csb" -- 最小spin次数提示
BingoRushConfig.bingoRush_popup3 = "Activity/BingoRush/csb/promptPopup/bingoRush_popup3.csb" -- 最小spin次数提示

-- 小活动入口
BingoRushConfig.rank_entrence = "Activity/BingoRush/csb/rank/bingoRush_rank_entrence.csb" -- 排行榜按钮
BingoRushConfig.saleIcon = "Activity/BingoRush/csb/entrance/bingoRush_promotionIcon.csb" -- 促销按钮
BingoRushConfig.passIcon = "Activity/BingoRush/csb/rank/bingoRush_pass_entrence.csb" -- pass按钮
BingoRushConfig.rankReward = "Activity/BingoRush/csb/rank/bingoRush_rankReward.csb" -- 排行榜玩家条目上的奖励控件
BingoRushConfig.passMainLayer = "Activity/BingoRush/csb/rank/bingoRush_pass_layer.csb"

-- bingo玩法资源
BingoRushConfig.bingo = "Activity/BingoRush/csb/bingo_round/matchBingo.csb" -- 第三轮ui bingo
BingoRushConfig.bingoCard = "Activity/BingoRush/csb/bingo_round/bingoCard.csb" -- bingo卡
BingoRushConfig.bingoCardNum = "Activity/BingoRush/csb/bingo_round/bingoCard_num.csb" -- 第三轮ui bingo卡上的字块
BingoRushConfig.bingoCardNumEff = "Activity/BingoRush/csb/bingo_round/bingoCard_num_tishi.csb" -- 第三轮ui bingo卡上的字块特效

BingoRushConfig.matchBingoTitle = "Activity/BingoRush/csb/bingo_round/bingoCardTitle.csb" -- bingo关 顶部信息条
BingoRushConfig.matchInfo = "Activity/BingoRush/csb/bingo_round/bingoCard_payTable.csb" -- 个人比赛信息ui
BingoRushConfig.matchCoins = "Activity/BingoRush/csb/bingo_round/bingoCard_totalWin.csb" -- 轮次总奖励金币ui
BingoRushConfig.msgList = "Activity/BingoRush/csb/bingo_round/matchMsgList.csb" -- 信息展示列表ui
BingoRushConfig.msgItem = "Activity/BingoRush/csb/bingo_round/matchMsgItem.csb" -- 信息条ui
BingoRushConfig.msgTip = "Activity/BingoRush/csb/bingo_round/matchBingoBall_wayList.csb" -- 信息条底部ui
BingoRushConfig.getScore = "Activity/BingoRush/csb/bingo_round/bingoRush_getScore.csb" -- 获得积分

BingoRushConfig.bonusCollect = "Activity/BingoRush/csb/bingo_round/cardBoost.csb" -- bingo道具生效界面
BingoRushConfig.cardBoost1 = "Activity/BingoRush/csb/bingo_round/cardBoost1.csb" -- bingo道具生效界面
BingoRushConfig.cardBoost2 = "Activity/BingoRush/csb/bingo_round/cardBoost2.csb" -- bingo道具生效界面
BingoRushConfig.cardBoost3 = "Activity/BingoRush/csb/bingo_round/cardBoost3.csb" -- bingo道具生效界面
BingoRushConfig.cardBoost4 = "Activity/BingoRush/csb/bingo_round/cardBoost4.csb" -- bingo道具生效界面

BingoRushConfig.bingoGrab = "Activity/BingoRush/csb/bingo_round/grabBingo.csb" -- 抢bingo界面
BingoRushConfig.bingoEnd = "Activity/BingoRush/csb/bingo_round/bingoRoundEnd.csb" -- bingo玩法结束界面

-- 过场及结算界面
BingoRushConfig.matchScore_final = "Activity/BingoRush/csb/roundResult/matchResult.csb" -- 最终积分排名整体信息显示ui
BingoRushConfig.matchScore_bingoPre = "Activity/BingoRush/csb/roundResult/round2Result.csb" -- 第二轮积分排名整体信息显示ui
BingoRushConfig.matchOver_round2 = "Activity/BingoRush/csb/roundResult/round2Result_info.csb" -- 第二轮结束过场ui
BingoRushConfig.round2Result_info_bingo = "Activity/BingoRush/csb/roundResult/round2Result_info_bingo.csb" -- 第二轮结束过场ui
BingoRushConfig.playerRankItem1 = "Activity/BingoRush/csb/roundResult/roundResult_Cell1.csb" -- 玩家轮次积分排名信息ui
BingoRushConfig.playerRankItem2 = "Activity/BingoRush/csb/roundResult/roundResult_Cell2.csb" -- 玩家轮次积分排名信息ui
BingoRushConfig.playerRankItem3 = "Activity/BingoRush/csb/roundResult/roundResult_Cell3.csb" -- 玩家轮次积分排名信息ui
BingoRushConfig.top5Reward = "Activity/BingoRush/csb/roundResult/top5Reward.csb" -- 前5名奖励显示
BingoRushConfig.top5Item1 = "Activity/BingoRush/csb/roundResult/top5_Cell1.csb" -- 玩家前五名展示ui
BingoRushConfig.top5Item2 = "Activity/BingoRush/csb/roundResult/top5_Cell2.csb" -- 玩家前五名展示ui
BingoRushConfig.top5Item3 = "Activity/BingoRush/csb/roundResult/top5_Cell3.csb" -- 玩家前五名展示ui

BingoRushConfig.reward = "Activity/BingoRush/csb/reward/bingoRush_reward.csb" -- 最终奖励领取

BingoRushConfig.SOUND = {
    -- 背景音乐
    level_bgm = "Activity/BingoRush/sounds/bgm/bingorushbgm_level.mp3",
    hall_bgm = "Activity/BingoRush/sounds/bgm/bingorushbgm_1.mp3",
    spin_bgm = "Activity/BingoRush/sounds/bgm/bingorushbgm_2.mp3",
    bingo_bgm = "Activity/BingoRush/sounds/bgm/bingorushbgm_3.mp3",
    ball_num = "Activity/BingoRush/sounds/balls/ball_%s.mp3",
    -- bingo轮次相关
    round2_1 = "Activity/BingoRush/sounds/round_bingo/round2_1.mp3",
    round2_2 = "Activity/BingoRush/sounds/round_bingo/round2_2.mp3",
    round2_rankover = "Activity/BingoRush/sounds/round_bingo/round2_rankover.mp3",
    round2_popInfo1 = "Activity/BingoRush/sounds/round_bingo/round2_popInfo1.mp3",
    round2_popInfo2 = "Activity/BingoRush/sounds/round_bingo/round2_popInfo2.mp3",
    round2_popInfo_bingo = "Activity/BingoRush/sounds/round_bingo/round2_popInfo_bingo.mp3",
    round3_rankstart = "Activity/BingoRush/sounds/round_bingo/round3_rankstart.mp3",
    --loading = "Activity/BingoRush/sounds/hall/loading.mp3", -- 过场
    score_growing = "Activity/BingoRush/sounds/hall/score_growing.mp3", -- 积分滚动
    levelShow = "Activity/BingoRush/sounds/hall/levelShow.mp3", -- 打开选择难度界面
    msg_player = "Activity/BingoRush/sounds/hall/msg_player.mp3", -- 玩家进入房间信息显示
    msg_player_extra = "Activity/BingoRush/sounds/hall/msg_player_extra.mp3", -- 特殊玩家进入房间信息显示
    msg_player_daub = "Activity/BingoRush/sounds/hall/msg_player_daub.mp3", -- 玩家中球信息
    msg_bingo = "Activity/BingoRush/sounds/hall/msg_bingo.mp3", -- 玩家bingo信息
    msg_mini = "Activity/BingoRush/sounds/hall/msg_mini.mp3", -- 玩家mini信息
    msg_major = "Activity/BingoRush/sounds/hall/msg_major.mp3", -- 玩家major信息
    msg_grand = "Activity/BingoRush/sounds/hall/msg_grand.mp3", -- 玩家grand信息
    round2_start = "Activity/BingoRush/sounds/hall/round2_start.mp3", -- 第二轮即将开启信息显示
    buff_show = "Activity/BingoRush/sounds/hall/buff_show.mp3", -- buff 界面显示
    buff_hide = "Activity/BingoRush/sounds/hall/buff_hide.mp3", -- buff 积分加成
    buff_daub = "Activity/BingoRush/sounds/hall/buff_daub.mp3", -- buff 必中 炸弹
    buff_link = "Activity/BingoRush/sounds/hall/buff_link.mp3", -- buff 关联 磁铁
    buff_double = "Activity/BingoRush/sounds/hall/buff_double.mp3", -- buff 双号 锤子
    card_daub = "Activity/BingoRush/sounds/hall/card_daub.mp3", -- 卡牌命中
    card_line = "Activity/BingoRush/sounds/hall/card_line.mp3", -- 卡牌连线
    card_bingo = "Activity/BingoRush/Slots/BingoRushSounds/sound_BingoRush_bingo.mp3", -- 卡牌命中bingo
    grab_bingo = "Activity/BingoRush/sounds/hall/grab_bingo.mp3", -- 抢bingo
    bingo_ended = "Activity/BingoRush/sounds/hall/grab_bingo.mp3", -- bingo结束
    rank_top_show = "Activity/BingoRush/sounds/hall/rank_top_show.mp3", -- 排行榜第一名显示
    rank_line2_show = "Activity/BingoRush/sounds/hall/rank_line2_show.mp3", -- 排行榜第二列显示
    show_top5 = "Activity/BingoRush/sounds/hall/show_top5.mp3", -- 前五名奖励结算
    show_reward = "Activity/BingoRush/sounds/hall/show_reward.mp3" -- 奖励结算
}

return BingoRushConfig
