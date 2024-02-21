-- quest 基础配置 新改的从 梦幻Quest 开始 

--代码路径
local ThemeConfig = {
    code = {
        QuestNewChapterChoseMainView = "baseQuestNewCode/lobby/QuestNewChapterChoseMainView", --quest章节选择界面
        QuestNewChapterChossCellNode = "baseQuestNewCode/lobby/QuestNewChapterChossCellNode", --quest章节选择界面 cell
        QuestNewChapterChoseInfoView = "baseQuestNewCode/lobby/QuestNewChapterChoseInfoView", --quest章节说明界面 
        QuestNewChapterChoseGuideView = "baseQuestNewCode/lobby/QuestNewChapterChoseGuideView", --quest章节引导界面  

        QuestNewMainMapView = "baseQuestNewCode/lobby/QuestNewMainMapView", --quest主界面
        QuestNewMapRoadLayer = "baseQuestNewCode/lobby/QuestNewMapRoadLayer", --地图节点界面
        QuestNewMapRoadScroll = "baseQuestNewCode/lobby/QuestNewMapRoadScroll", --地图滑动控制界面
        QuestNewMapCellNode = "baseQuestNewCode/lobby/QuestNewMapCellNode", --地图关卡
        QuestNewMapBoxNode = "baseQuestNewCode/lobby/QuestNewMapBoxNode", --地图宝箱
        QuestNewMapStepNode = "baseQuestNewCode/lobby/QuestNewMapStepNode", --地图脚步
        QuestNewMapBoxBubbleNode = "baseQuestNewCode/lobby/QuestNewMapBoxBubbleNode", --地图宝箱 气泡
        QuestNewMapCellWheelNode = "baseQuestNewCode/lobby/QuestNewMapCellWheelNode", --地图转盘
        QuestNewMapWheelBubbleNode = "baseQuestNewCode/lobby/QuestNewMapWheelBubbleNode", --地图转盘 气泡
        QuestNewTopCoinsShowNode = "baseQuestNewCode/lobby/QuestNewTopCoinsShowNode",  --主界面展示 金币奖励 

        QuestNewMapRewardLayer = "baseQuestNewCode/lobby/QuestNewMapRewardLayer", --奖励界面
        QuestNewAllTipLayer = "baseQuestNewCode/lobby/QuestNewAllTipLayer", --所有弹板提示界面

        QuestNewWheelLayer = "baseQuestNewCode/lobby/QuestNewWheelLayer", -- 奖励轮盘 界面
        QuestNewWheelNode = "baseQuestNewCode/lobby/QuestNewWheelNode", -- 奖励轮盘 控制节点
        QuestNewWheelItemNode = "baseQuestNewCode/lobby/QuestNewWheelItemNode", -- 奖励轮盘 单个扇形奖励
        QuestNewWheelRewardLayer = "baseQuestNewCode/lobby/QuestNewWheelRewardLayer", -- 奖励轮盘 奖励界面

        QuestNewLobbyLogoNode = "baseQuestNewCode/lobby/QuestLobbyLogo", --Logo 需要各个主题指定
        QuestNewLobbyRankNode = "baseQuestNewCode/lobby/QuestNewLobbyRankNode", --排行榜 需要各个主题指定
        QuestNewLobbySaleNode = "baseQuestNewCode/lobby/QuestNewLobbySaleNode", --促销 需要各个主题指定
        QuestNewLobbyStarNode = "baseQuestNewCode/lobby/QuestNewLobbyStarNode", --星星奖励 需要各个主题指定

        QuestNewNextChapterConfirmLayer = "baseQuestNewCode/lobby/QuestNewNextChapterConfirmLayer", -- 切换到下一章 确定界面


        QuestNewChapterStarPrizesLayer = "baseQuestNewCode/lobby/QuestNewChapterStarPrizesLayer", -- 章节星星奖励界面
        QuestNewChapterStarPrizesProgressNode = "baseQuestNewCode/lobby/QuestNewChapterStarPrizesProgressNode", -- 章节星星奖励界面 进度节点
        QuestNewChapterStarPrizesRewardNode = "baseQuestNewCode/lobby/QuestNewChapterStarPrizesRewardNode", -- 章节星星奖励界面 奖励节点
        

        QuestNewEntryNode = "baseQuestNewCode/task/QuestNewEntryNode", --关卡内入口
        QuestNewTaskProgress = "baseQuestNewCode/task/QuestNewTaskProgress", --关卡左侧任务进度
        QuestNewTaskTipNode = "baseQuestNewCode/task/QuestNewTaskTipNode", --关卡左侧任务提示
        QuestNewTaskDoneTipLayer = "baseQuestNewCode/task/QuestNewTaskDoneTipLayer", --任务完成界面

        --rank
        QuestNewRankLayer = "baseQuestNewCode/rank/QuestNewRankLayer", --排行榜

        --rush
        QuestNewRushEntry = "Activity/Activity_QuestRushFantasyEntry", --挑战活动 入口

    },
    --资源路径
    res = {
        --主界面
        QuestNewChapterChoseMainView = "QuestFantasyRes/Quest_Fantasy_MainMap.csb", --quest章节选择界面
        QuestNewChapterChossCellNode = "QuestFantasyRes/Quest_Fantasy_MainMap_Entrance.csb", --quest章节选择界面 cell 
        QuestNewChapterChoseInfoView = "QuestFantasyRes/Quest_Fantasy_Info.csb", --quest章节说明界面  
        QuestNewChapterChoseGuideView = "QuestFantasyRes/Quest_Fantasy_GuideLayer.csb", --quest章节引导界面

        QuestNewTopCoinsShowNode = "QuestFantasyRes/Quest_Fantasy_JackPot_", --主界面展示 金币奖励 需要链接

        QuestNewMainMapView = "QuestFantasyRes/Quest_Fantasy_Map.csb", --地图主界面展示
        QuestNewMapRoadLayer = "QuestFantasyRes/QuestRoadLayer.csb", --地图节点界面
        QuestNewMapCellNode = "QuestFantasyRes/Quest_Fantasy_Map_SlotMachine.csb", --地图关卡
        QuestNewMapBoxNode = "QuestFantasyRes/Quest_Fantasy_Map_SlotRewards.csb", --地图宝箱
        QuestNewMapStepNode = "QuestFantasyRes/QuestRoadStepNode.csb", --地图脚步 
        QuestNewMapBoxBubbleNode = "QuestFantasyRes/Quest_Fantasy_Map_SlotRewards_qipao.csb", --地图宝箱气泡
        QuestNewMapCellWheelNode = "QuestFantasyRes/Quest_Fantasy_Map_Wheel.csb", --地图转盘
        QuestNewMapCellWheelNode_UnlockAct = "QuestFantasyRes/Quest_Fantasy_Map_Wheel_jiesuo.csb", --地图转盘 解锁动画
        QuestNewMapWheelBubbleNode = "QuestFantasyRes/Quest_Fantasy_Map_Wheel_tanban.csb", --地图转盘气泡
        QuestNewMainMap_BG_PATH = "QuestFantasyRes/ui_map/Quest_map_bg_", --地图背景前缀 

        QuestNewLobbyLogoNode = "QuestFantasyRes/Quest_Fantasy_LobbyLogo.csb", --Logo 需要各个主题指定
        QuestNewLobbyRankNode = "QuestFantasyRes/Quest_Fantasy_LobbyRank.csb", --Rank 需要各个主题指定
        QuestNewLobbySaleNode = "QuestFantasyRes/Quest_Fantasy_LobbySale.csb", --Sale 需要各个主题指定
        QuestNewLobbyStarNode = "QuestFantasyRes/Quest_Fantasy_Map_StarMeter_entrance.csb", --星星奖励 需要各个主题指定 

        QuestNewAllTipLayer = "QuestFantasyRes/Quest_Fantasy_Map_Tanban.csb", --所有弹板提示界面
        QuestNewMapRewardLayer = "QuestFantasyRes/Quest_Fantasy_Map_Reward.csb", --奖励界面


        QuestNewWheelLayer = "QuestFantasyRes/Quest_Fantasy_Wheel.csb", -- quest 轮盘
        QuestNewWheelItemNode = "QuestFantasyRes/Quest_Fantasy_Wheel", -- 奖励轮盘 单个扇形奖励 资源前缀
        QuestNewWheelLayer_GainEffect = "QuestFantasyRes/Quest_Fantasy_Wheel_zjk", -- quest 轮盘中奖特效 需要追加后缀
        QuestNewWheelRewardLayer = "QuestFantasyRes/Quest_Fantasy_Wheel_reward.csb", -- quest 轮盘  
        

        QuestNewNextChapterConfirmLayer = "QuestFantasyRes/Quest_Fantasy_Map_Tanban.csb", -- 切换到下一章 确定界面

        QuestNewChapterStarPrizesLayer = "QuestFantasyRes/Quest_Fantasy_Map_StarMeter.csb", -- 章节星星奖励界面
        QuestNewChapterStarPrizesProgressNode = "QuestFantasyRes/Quest_Fantasy_Map_StarMeter_jianglidian.csb", -- 章节星星奖励界面 进度节点
        QuestNewChapterStarPrizesRewardNode = "QuestFantasyRes/Quest_Fantasy_Map_StarMeter_jiangli.csb", -- 章节星星奖励界面 奖励节点

        QuestNewGuideNode = "QuestFantasyRes/Quest_Fantasy_Guide.csb", -- 章节引导节点

        QuestNewEntryNode = "QuestFantasyRes/Quest_Fantasy_Task.csb", --关卡内左侧条 
        QuestNewTaskProgress = "QuestFantasyRes/Quest_Fantasy_Task_Progress.csb", --左侧任务条进度
        QuestNewTaskTipNode = "QuestFantasyRes/Quest_Fantasy_Task_TipNode.csb", --左侧任务条提示
        QuestNewTaskDoneTipLayer = "QuestFantasyRes/Quest_Fantasy_Task_slots_reward.csb", --任务完成界面
        QuestNewTaskDoneTipLayer_Shu = "QuestFantasyRes/Quest_Fantasy_Task_slots_reward_shu.csb", --任务完成界面 竖版
        QuestNewTaskProgressSpine = "QuestFantasyRes/spine/shuimian", --左侧任务条进度
        QuestNewTaskProgressEffect = "QuestFantasyRes/QuestTaskProgressEffect.csb", --boostbuff特效


        --
        QuestNewCellDL = "QuestFantasyRes/QuestCellDL.csb", --关卡下载进度
        QuestNewCellTips = "QuestFantasyRes/QuestCellTips.csb", -- 关卡奖励气泡
        QuestNewCellTipRewards = "QuestFantasyRes/QuestCellTipRewards.csb", -- 奖励气泡里面的内容
        QuestNewDifficultyLayer = "QuestFantasyRes/QuestDifficultyLayer.csb", --难度选择界面
        QuestNewEnterCell = "QuestFantasyRes/QuestEnterCell.csb", --关卡任务展示单个描述
        QuestNewEnterLayer = "QuestFantasyRes/QuestEnterLayer.csb", --关卡任务展示弹版
        QuestNewEnterPorLayer = "QuestFantasyRes/QuestEnterLayer_Portrait.csb", --关卡任务展示弹版
        QuestNewSkipSaleView = "QuestFantasyRes/QuestSkipSaleView.csb", --跳关购买弹窗
        QuestNewSkipSaleProView = "QuestFantasyRes/QuestSkipSaleView_Portrait.csb", --竖版跳关购买弹窗
        

        -- 图片路径
        QuestNewChapterPhotoPath = "QuestFantasyRes/ui_Main/QuestFantasyChapterPhoto_", --章节photo
        QuestNewNPCSpinePath = "QuestFantasyRes/spine/cpr", -- NPC spine 路径

        --bgm
        QuestNewBGMPath = "QuestFantasyRes/sound/QUEST_bg_bgm.mp3",
        QuestNew_Sound_ChestCollect = "QuestFantasyRes/sound/Quest_Fantasy_ChestCollect.mp3", --领取宝箱
        QuestNew_Sound_MapClick = "QuestFantasyRes/sound/Quest_Fantasy_MapClick.mp3", --点击章节进入地图
        QuestNew_Sound_SlotCompleted = "QuestFantasyRes/sound/Quest_Fantasy_SlotCompleted.mp3", --关卡任务全完成
        QuestNew_Sound_SlotUnlock = "QuestFantasyRes/sound/Quest_Fantasy_SlotUnlock.mp3", --关卡任务完成一项
        QuestNew_Sound_WheelLevelUp = "QuestFantasyRes/sound/Quest_Fantasy_WheelLevelUp.mp3", --转盘升级
        QuestNew_Sound_WheelReward = "QuestFantasyRes/sound/Quest_Fantasy_WheelReward.mp3", --转盘奖励
        QuestNew_Sound_WheelSpin = "QuestFantasyRes/sound/Quest_Fantasy_WheelSpin.mp3", --转盘转动

        QuestNew_Sound_WheelStart = "QuestFantasyRes/sound/QUEST_Wheel_start.mp3", --转盘界面出现
        QuestNew_Sound_ChapterUnlock = "QuestFantasyRes/sound/QUEST_Map_unlock.mp3", --章节解锁
        QuestNew_Sound_StageUnlock = "QuestFantasyRes/sound/QUEST_Slot_unlock.mp3", --关卡解锁
        QuestNew_Sound_StarMeterCollect = "QuestFantasyRes/sound/QUEST_StarMeter_duigou.mp3", --星星奖励领取
        QuestNew_Sound_WheelCheckOut = "QuestFantasyRes/sound/QUEST_Wheel_check.mp3", --转盘奖励出现
        QuestNew_Sound_WheelChangetToPointer = "QuestFantasyRes/sound/QUEST_WHEEL_CHANGE.mp3", --转盘奖励变成箭头
    }
}

return ThemeConfig
