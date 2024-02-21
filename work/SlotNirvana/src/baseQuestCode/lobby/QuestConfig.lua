-- quest 基础配置

--代码路径
local ThemeConfig = {
    code = {
        QuestMainView = "baseQuestCode/lobby/QuestMainView", --quest主界面
        --cell
        QuestBox = "baseQuestCode/cell/QuestBox", --地图上宝箱
        QuestBoxReward = "baseQuestCode/cell/QuestBoxReward", --宝箱打开得劲奖励
        QuestCell = "baseQuestCode/cell/QuestCell", --关卡节点
        QuestCellDL = "baseQuestCode/cell/QuestCellDL", --关卡下载进度
        QuestCellTips = "baseQuestCode/cell/QuestCellTips", --关卡奖励气泡
        QuestCellTipRewards = "baseQuestCode/cell/QuestCellTipRewards", -- 奖励气泡里面的内容
        --lobby
        QuestDifficultyLayer = "baseQuestCode/lobby/QuestDifficultyLayer", --难度选择界面
        QuestLobbyTitle = "baseQuestCode/lobby/QuestLobbyTitle", -- quest彩金栏
        QuestWheel = "baseQuestCode/lobby/QuestWheel", -- 奖励轮盘
        --map
        QuestDrawLine = "baseQuestCode/map/QuestDrawLine", --地图上的连线
        QuestMapCell = "baseQuestCode/map/QuestMapCell", --地图碎块
        QuestMapControl = "baseQuestCode/map/QuestMapControl", --地图控制
        QuestMapScroll = "baseQuestCode/map/QuestMapScroll", --地图滑动
        --task
        QuestEntryNode = "baseQuestCode/task/QuestEntryNode", --关卡内入口
        QuestEnterLayer = "baseQuestCode/task/QuestEnterLayer", --关卡任务提示弹版
        QuestTaskDoneLayer = "baseQuestCode/task/QuestTaskDoneLayer", --quest关卡任务完成
        QuestTaskTipNode = "baseQuestCode/task/QuestTaskTipNode", --关卡左侧任务提示
        QuestEnterCell = "baseQuestCode/task/QuestEnterCell", --关卡任务提示弹版上的描述
        QuestTaskProgress = "baseQuestCode/task/QuestTaskProgress", --关卡左侧任务进度
        QuestSkipSaleView = "baseQuestCode/task/QuestSkipSaleView", --跳过任务关卡购买弹板

        QuestSkipSaleView_PlanB = "baseQuestCode/task/QuestSkipSaleView_PlanB", --跳过任务关卡购买弹板  AB 分组

        --activity
        CollectStar = "Activity/Activity_QuestCollectStar", --星星收集活动
        RewardCoins = "Activity/Activity_QuestFirstCoins", --过一关奖励金币活动
        QuestRushEntry = "Activity/Activity_QuestRushEntry", --挑战活动 入口
        --theme 这些必须重写base里面没有
        QuestMapConfig = "QuestBaseMap/questMapConfig.json", --大地图配置文件json
        -- 主题相关文件
        QuestLobbyLogo = "baseQuestCode/lobby/QuestLobbyLogo", --Logo 需要各个主题指定
        QuestLobbyRank = "", --排行榜 需要各个主题指定
        QuestLobbySale = "baseQuestCode/lobby/QuestLobbySale", --促销 需要各个主题指定
        --rank
        QuestRankLayer = "", --排行榜界面 需要各个主题指定
        QuestRuleView = "", --排行榜规则 需要各个主题指定

        -- pass
        QuestPassLayer = "baseQuestCode/pass/QuestPassLayer", -- pass主界面
        QuestPassBuyTicket = "baseQuestCode/pass/QuestPassBuyTicket", -- pass促销
        QuestPassRuleView = "baseQuestCode/pass/QuestPassRuleView", -- pass规则
        QuestPassEntryNode = "baseQuestCode/pass/QuestPassEntry", -- pass入口
        QuestPassTableView = "baseQuestCode/pass/QuestPassTableView", -- pass Table
        QuestPassTableCell = "baseQuestCode/pass/QuestPassTableCell", -- pass Cell
        QuestPassRewardNode = "baseQuestCode/pass/QuestPassRewardNode", -- pass 奖励
        QuestPassProgress = "baseQuestCode/pass/QuestPassProgress", -- pass progress
        QuestPassTopUI = "baseQuestCode/pass/QuestPassTopUI", -- pass 解锁按钮
        QuestPassRewardBox = "baseQuestCode/pass/QuestPassRewardBox", -- pass 宝箱
        QuestPassRewardBubble = "baseQuestCode/pass/QuestPassRewardBubble", -- pass 宝箱奖励气泡
        QuestPassCellBubble = "baseQuestCode/pass/QuestPassQiPao", -- pass 宝箱奖励气泡

        QuestPassPreviewCellNode = "baseQuestCode/pass/QuestPassPreviewCellNode", -- pass 预览
        QuestPassPreviewCellProgressNode = "baseQuestCode/pass/QuestPassPreviewCellProgressNode", -- pass 宝箱奖励气泡
        QuestPassRewardSpecialItemNode = "baseQuestCode/pass/QuestPassRewardSpecialItemNode", -- pass 奖励
        QuestPassSeasonProgressNode = "baseQuestCode/pass/QuestPassSeasonProgressNode", -- pass 奖励
        QuestPassBuyTicketRewardPreviewLayer = "baseQuestCode/pass/QuestPassBuyTicketRewardPreviewLayer", -- pass 奖励预览
        QuestPassRewardLayer = "baseQuestCode/pass/QuestPassRewardLayer", -- pass 奖励界面

        QuestJackpotWheelTitleNode = "baseQuestCode/wheel/QuestJackpotWheelTitleNode", --关卡左侧任务提示
        QuestJackpotWheelLayer = "baseQuestCode/wheel/QuestJackpotWheelLayer", --jackpot 轮盘
        QuestJackpotWheelItemNode = "baseQuestCode/wheel/QuestJackpotWheelItemNode", --jackpot 轮盘

        QuestJackpotWheelRewardLayer = "baseQuestCode/wheel/QuestJackpotWheelRewardLayer", --jackpot 轮盘 奖励
        QuestJackpotRuleLayer = "baseQuestCode/wheel/QuestJackpotRuleLayer", --jackpot
    },
    --资源路径
    res = {
        --
        QuestCellDL = "QuestBaseRes/QuestCellDL.csb", --关卡下载进度
        QuestCellTips = "QuestBaseRes/QuestCellTips.csb", -- 关卡奖励气泡
        QuestCellTipRewards = "QuestBaseRes/QuestCellTipRewards.csb", -- 奖励气泡里面的内容
        QuestDifficultyLayer = "QuestBaseRes/QuestDifficultyLayer.csb", --难度选择界面
        QuestEnterCell = "QuestBaseRes/QuestEnterCell.csb", --关卡任务展示单个描述

        -- QuestEnterCell = "QuestNewUser/Activity/csd/GroupA/" .. "NewUser_QuestEnterCell.csb", --关卡任务展示单个描述

        
        QuestEnterLayer = "QuestBaseRes/QuestEnterLayer.csb", --关卡任务展示弹版
        QuestEnterPorLayer = "QuestBaseRes/QuestEnterLayer_Portrait.csb", --关卡任务展示弹版
        QuestSkipSaleView = "QuestBaseRes/QuestSkipSaleView.csb", --跳关购买弹窗
        QuestSkipSaleProView = "QuestBaseRes/QuestSkipSaleView_Portrait.csb", --竖版跳关购买弹窗

        QuestSkipSaleView_PlanB = "QuestBaseRes/QuestSkipSaleViewNew.csb", --跳关购买弹窗
        QuestSkipSaleProView_PlanB = "QuestBaseRes/QuestSkipSaleView_PortraitNew.csb", --竖版跳关购买弹窗

        --主界面
        QuestMainLayer = "QuestBaseRes/QuestMainLayer.csb", --主界面展示
        QuestMapMask = "QuestBaseRes/QuestMapMask.csb", --地图迷雾
        QuestBoxReward = "QuestBaseRes/QuestBoxReward.csb", --宝箱奖励界面
        QuestWheel = "QuestBaseRes/QuestWheel.csb", -- quest 轮盘
        QuestMapBox = "QuestBaseRes/QuestMapBox.csb", --地图宝箱
        QuestMapBoxBig = "QuestBaseRes/QuestMapBoxBig.csb", --地图宝箱最后一关资源
        --任务
        QuestTaskDoneLayer = "QuestBaseRes/QuestTaskDoneLayer.csb", --任务完成界面
        QuestTaskProgress = "QuestBaseRes/QuestTaskProgress.csb", --左侧任务条进度
        QuestTaskTipNode = "QuestBaseRes/QuestTaskTipNode.csb", --左侧任务条提示
        QuestTaskProgressEffect = "QuestBaseRes/QuestTaskProgressEffect.csb", --boostbuff特效
        QuestSkipIcon = "QuestBaseRes/QuestLobbySkip.csb", -- 跳关促销图标
        --theme 这些必须重写base里面没有
        QuestCell = "QuestThemeRes/QuestCell.csb", --关卡节点
        QuestCellGift = "QuestThemeRes/QuestCellGift.csb", --关卡礼物
        QuestCellGuide = "QuestThemeRes/QuestCellGuide.csb", --关卡引导小手
        QuestEntryNode = "QuestThemeRes/QuestEntryNode.csb", --关卡内左侧条
        QuestLobbyTitle = "QuestThemeRes/QuestLobbyTitle.csb", --主界面标题
        QuestMapArrow = "QuestThemeRes/QuestMapArrow.csb", --地图箭头
        --other
        QuestMapCellPath = "QuestBaseMap/ui/quest_bg_", --地图碎片路径
        --bgm
        QuestBGMPath = "QuestSounds/Quest_bg.mp3",
        QuestLinePointPath = "QuestOther/quest_m_dian.png", -- 地图路径小点图片路径
        -- 主题相关资源
        QuestRuleView = "", --排行榜规则界面
        -- 地图参数
        QuestMapBgCount = 150,
        QuestMapBgWidth = 90,

        -- pass(暂无资源，主题单做)
        QuestPassEntry = "QuestThemeRes/Pass_EntryNode.csb", -- pass 入口
        QuestPassLayer = "QuestThemeRes/Pass_MainLayer.csb", -- pass 主界面
        QuestPassTableCell = "QuestThemeRes/Pass_Cell.csb", -- pass table
        QuestPassTableFreeCell = "QuestThemeRes/Pass_FreeCell.csb", -- pass table
        QuestPassTableTicketCell = "QuestThemeRes/Pass_TicketCell.csb", -- pass table
        QuestPassProgress = "QuestThemeRes/Pass_Progress.csb", -- pass progress
        QuestPassTopUI = "QuestThemeRes/Pass_RewardTopUi.csb", -- pass 解锁按钮
        QuestPassRuleView = "QuestThemeRes/Pass_RuleView.csb", -- pass 说明页
        QuestPassBox = "QuestThemeRes/Pass_SafeBox.csb", -- pass 宝箱
        QuestPassBoxBubble = "QuestThemeRes/Pass_SafeBox_Bubble.csb", -- pass 气泡
        QuestPassBuyTicketLayer = "QuestThemeRes/Pass_BuyTicketLayer.csb", -- pass 购买页

        QuestJackpotMainTitleNode = "QuestBaseRes/QuestJakcpot.csb", -- jackpot 标题
        QuestJackpotWheelTitleNode = "QuestBaseRes/QuestWheel_Jackpot.csb", -- jackpot 标题
        QuestJackpotWheelLayer = "QuestBaseRes/QuestWheelNew.csb", --jackpot 轮盘
        QuestJackpotWheelItemNode = "QuestBaseRes/QuestWheelNew_Cell.csb", --jackpot 轮盘

        QuestJackpotWheelEffectPath = "QuestBaseRes/QuestWheel_Jackpot_select_", --jackpot 轮盘 中奖特效
        QuestJackpotRuleLayer = "QuestBaseRes/QuestJakcpot_Info.csb", --jackpot 轮盘 奖励

        QuestJackpotWheelBubble = "QuestBaseRes/QuestWheel_Bubble.csb", --jackpot 轮盘

        QuestJackpotWheelRewardLayer_Normal = "QuestBaseRes/QuestWheelNormal.csb",
        QuestJackpotWheelRewardLayer_Mini = "QuestBaseRes/QuestWheelMini.csb",
        QuestJackpotWheelRewardLayer_Major = "QuestBaseRes/QuestWheelMajor.csb",
        QuestJackpotWheelRewardLayer_Grand = "QuestBaseRes/QuestWheelGrand.csb",
    },
    plist = {
        QuestEnterLayer = {"QuestBaseRes/quest_enter/quest_enter_plist"},
        QuestTaskDoneLayer = {"QuestBaseRes/quest_task/quest_task_plist"},
        QuestTaskProgress = {
            "QuestBaseRes/effects/QuestBase_qipao_Plist",
            "QuestBaseRes/effects/QuestTaskProgress_Plist"
        },
        QuestMainLayer = {"QuestBaseRes/quest_lobby/quest_lobby_plist"},
        QuestDifficultyLayer = {
            "QuestBaseRes/sel_difficulty/difficulty_plist",
            "QuestBaseRes/effects/QuestLink_tanbansg_Plist"
        },
        QuestBoxReward = {"QuestBaseRes/box_reward/box_reward_plist"}
    },
    config = {
        arrow_posX = {210, 2350, 4500, 6666, 8815, 10980}, -- 箭头X坐标
        arrow_posY = {-10, -30, 0, 0, -20, 0}, -- 箭头Y坐标
        show_task_pop = true
    }
}

return ThemeConfig
