--[[--
    多主题控制逻辑
    控制资源路径和Lua文件路径
    使用方式：将每个主题中不一样的资源文件，Lua文件和操作逻辑放入此文件夹中
]]
local RedecorThemeLogic = class("RedecorThemeLogic", BaseSingleton)

function RedecorThemeLogic:ctor()
    RedecorThemeLogic.super.ctor(self)
    --[[--
        粒子配置
    ]]
    self.m_liziCfg = {}
    self.m_liziCfg.mainProgressTrailing = "Activity/Redecor/lizi/Redecor_jindutiao_addlizi.plist" -- 进度条增长 拖尾粒子
    self.m_liziCfg.dragIconTrailing = "Activity/Redecor/lizi/Redecor_lizi.plist" -- 拖动家具icon时的 拖尾粒子
    self.m_liziCfg.mainTitleTrailing1 = "Activity/Redecor/lizi/Redecor_jindutiao_lizi.plist" -- 标题飞到剩余步数的拖尾粒子
    self.m_liziCfg.roundOverTrailing = "Activity/Redecor/lizi/Redecor_zhanshi_lizi.plist" -- 过关 拖尾粒子

    --[[--
        文案配置
    ]]
    self.m_txtConfig = {}
    self.m_txtConfig.lobbyFntLoading = "HOME REDECOR IS DOWNLOADING"
    self.m_txtConfig.lobbyFntUnlock = "UNLOCK HOME REDECOR AT LEVEL "

    --[[--
        图片资源配置
    ]]
    self.m_imgConfig = {}

    -- 最终大奖
    self.m_imgConfig.finalPrizeRound = "Activity/Redecor/other/finalPrize/round_%d_%d.png"

    -- 缩略图上的字体
    self.m_imgConfig.simpleWhite = "Activity/Redecor/font/NewFolder/tongyong_shuzi.fnt"
    self.m_imgConfig.simpleRed = "Activity/Redecor/font/NewFolder/hongse_shuzi.fnt"

    self.m_imgConfig.rankLayerScoreBg = "Activity/Redecor/other/rank/rank_item1_scoreBg_self.png" -- 第一个页签cell的玩家积分底图
    self.m_imgConfig.rankCell2Bg = "Activity/Redecor/other/rank/rank_cup_%d.png" -- 奖杯

    self.m_imgConfig.lobbyProgressIcon = "Activity_LobbyIconRes/ui/Redecor_Black.png"
    self.m_imgConfig.lobbyBtnFunc = "Activity_LobbyIconRes/ui/Redecor_node.png"
    self.m_imgConfig.lobbyBtnFuncGrey = "Activity_LobbyIconRes/ui/Redecor_Black.png"
    self.m_imgConfig.lobbyLockIcon = "Activity_LobbyIconRes/ui/Redecor_node.png"

    self.m_imgConfig.furnitureStar = "Activity/Redecor/other/star.png"
    self.m_imgConfig.furnitureIcon = "Activity/Redecor/other/%s.png"

    self.m_imgConfig.treasureNameIcon = "Activity/Redecor/other/treasure_level_%d.png"
    self.m_imgConfig.treasureSmallIcon = "Activity/Redecor/other/treasure_small_%d.png"
    self.m_imgConfig.treasureBigIcon = "Activity/Redecor/other/treasure_big_%d.png"
    self.m_imgConfig.treasureBiggestIcon = "Activity/Redecor/other/treasure_biggest_%d.png"

    -- 家具spine
    self.m_imgConfig.furnitureSpine = "Activity/Redecor/spine_node/Redecor_Furnitures_%s"
    -- 家具风格
    self.m_imgConfig.furnitureStyleIcon = "Activity/Redecor/other/styleIcon/%s_style%d.png"
    -- 家具创建时粒子效果
    self.m_imgConfig.FurnitureAppearParticleNode = "Activity/Redecor/csd/Redecor_furniture/lizi_createFurniture/lizi_%s.csb"
    self.m_imgConfig.furnitureAppearSpine = "Activity/Redecor/spine/Redecor_Furnitures_quan"
    -- 虚线
    self.m_imgConfig.furnitureDashLineIcon = "Activity/Redecor/other/xuXian/%s.png"
    -- 引导气泡
    self.m_imgConfig.guideBubbleIcon = "Activity/Redecor/other/guide_qipao%d.png"
    -- 过场帘子spine
    self.m_imgConfig.roundOverCurtainSpine = "Activity/Redecor/spine/Redecor_Furnitures_guoChangLianZi"

    -- loading
    self.m_imgConfig.hallTitleLastDay = "Icons/Redecor_loading/other/dating_lastday.png"
    self.m_imgConfig.slideTitleLastDay = "Icons/Redecor_loading/other/lunbo_lastday.png"

    -- 飞行光
    self.m_imgConfig.mainTitleFlyImg = "Activity/Redecor/other/Redecor_guangtiao.png"

    -- 轮盘双指针
    self.m_imgConfig.wheelPointerSilverImg = "Activity/Redecor/other/wheel/wheel_pointer1.png"
    self.m_imgConfig.wheelPointerGoldenImg = "Activity/Redecor/other/wheel/wheel_pointer2.png"

    --[[--
        csb资源配置
    ]]
    self.m_csbConfig = {}
    -- 主界面
    self.m_csbConfig.mainLayer = "Activity/Redecor/csd/Redecor_mainUI/Redecor_MainMap.csb"
    -- 主界面其他挂点
    self.m_csbConfig.mainTitleNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Title.csb"
    self.m_csbConfig.mainTitleRewardNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Title_reward.csb"
    self.m_csbConfig.mainTitleProgressNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Title_progress.csb"
    self.m_csbConfig.mainProgressNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_FinalPrize.csb"
    self.m_csbConfig.mainProgressBubbleNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Bubble.csb"
    self.m_csbConfig.mainPromotionNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_PowerUp.csb"
    self.m_csbConfig.mainRankNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Leaderboard.csb"
    self.m_csbConfig.mainFullViewNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_FullView.csb"
    self.m_csbConfig.mainTreasureSlotNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_GiftSlot.csb"
    self.m_csbConfig.mainTreasureNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Gift.csb"
    self.m_csbConfig.mainMultiNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_x2Buff.csb" -- x2 buff标签
    self.m_csbConfig.mainWheelNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_wheel_Entrance.csb"

    -- fullview主界面
    self.m_csbConfig.mainFullViewLayer = "Activity/Redecor/csd/Redecor_mainUI/Redecor_FullViewLayer.csb"

    self.m_csbConfig.mainRankStarFlyLayer = "Activity/Redecor/csd/Redecor_mainUI/Redecor_star_fly.csb" -- 奖杯入口飞星星
    self.m_csbConfig.mainRankStarBlastNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Leaderboard_node_baodian.csb" -- 奖杯入口飞星星后爆炸特效

    self.m_csbConfig.treasureEffectFlyLayer = "Activity/Redecor/csd/Redecor_mainUI/Redecor_Gift_effect_fly.csb" -- 获得后飞礼盒

    self.m_csbConfig.mainTaskNode = "Activity_Mission/csd/COIN_REDECOR_MissionEntryNode.csb" -- 主界面任务入口

    -- 任务
    self.m_csbConfig.taskMainLayer = "Activity/Activity_RedecorTask/csb/MainLayer.csb" -- 任务
    self.m_csbConfig.taskMainTitleNode = "Activity/Activity_RedecorTask/csb/MainTitleNode.csb"
    self.m_csbConfig.taskMainBubbleNode = "Activity/Activity_RedecorTask/csb/MainBubbleNode.csb"
    self.m_csbConfig.taskRewardLayer = "Activity/Activity_RedecorTask/csb/RewardLayer.csb"
    self.m_csbConfig.taskRewardIconNode = "Activity/Activity_RedecorTask/csb/RewardLayer.csb"
    self.m_csbConfig.taskRewardBgNode = "Activity/Activity_RedecorTask/csb/RewardLayer_bg_guang.csb"

    -- 规则
    self.m_csbConfig.ruleLayer = "Activity/Redecor/csd/Redecor_info/Redecor_info.csb" -- 规则

    -- 排行榜
    self.m_csbConfig.rankLayer = "Activity/Redecor/csd/Redecor_rank/Redecor_Rank.csb" -- 排行榜
    self.m_csbConfig.rankCellNode = "Activity/Redecor/csd/Redecor_rank/Redecor_Rank_item%d.csb"
    self.m_csbConfig.rankTopCellNode = "Activity/Redecor/csd/Redecor_rank/Redecor_Rank_item0.csb"
    self.m_csbConfig.rankTitleNode = "Activity/Redecor/csd/Redecor_rank/Redecor_RankTitle.csb"
    self.m_csbConfig.rankHelpLayer = "Activity/Redecor/csd/Redecor_rank/Redecor_Rank_help.csb"

    -- 促销
    self.m_csbConfig.promotionLayer = "Activity/Promotion_Redecor/csd/Promotion_Redecor" -- 促销
    self.m_csbConfig.promotionItemNode = "Activity/Promotion_Redecor/csd/RedecorSaleItem"
    self.m_csbConfig.promotionOpenBoxLayer = "Activity/Promotion_Redecor/csd/Promotion_open"
    self.m_csbConfig.promotionOpenBoxBgNode = "Activity/Promotion_Redecor/csd/Promotion_open_bg"

    -- 大厅和关卡入口
    self.m_csbConfig.lobbyNode = "Activity_LobbyIconRes/Activity_RedecorLobbyNode.csb" -- 大厅入口
    self.m_csbConfig.entryNode = "Activity/Redecor/csd/Redecor_gamescene/GameSceneUiNode.csb" -- 关卡入口
    self.m_csbConfig.entryTipNode = "Activity/Redecor/csd/Redecor_gamescene/Redecor_Tip.csb" -- 提示
    self.m_csbConfig.entryPromotionNode = "Activity/Redecor/csd/Redecor_mainUI/Redecor_PowerUp_Stage.csb" -- 关卡促销入口

    -- 所有家具
    self.m_csbConfig.furnituresNode = "Activity/Redecor/csd/Redecor_furniture/Redecor_Furnitures.csb" -- 所有家具节点

    -- 操作：简略图界面
    -- self.m_csbConfig.simpleMainNode = "Activity/Redecor/csd/Redecor_simpleNode/Redecor_simpleMainNode.csb" -- 拖拽主界面
    self.m_csbConfig.simpleInfoNode = "Activity/Redecor/csd/Redecor_simpleNode/Redecor_simpleItem.csb" -- 家具信息漂浮界面
    -- self.m_csbConfig.dragSlotNode = "Activity/Redecor/csd/Redecor_simpleNode/Redecor_ItemConfirm.csb" -- 拖拽确认槽
    -- self.m_csbConfig.dragArrowNode = "Activity/Redecor/csd/Redecor_simpleNode/Redecor_arrow.csb" -- 拖拽确认箭头
    -- self.m_csbConfig.dragArrowNode2 = "Activity/Redecor/csd/Redecor_simpleNode/Redecor_node_arrow.csb" -- 箭头
    -- self.m_csbConfig.dragInfo = "Activity/Redecor/csd/Redecor_simpleNode/Redecor_Item.csb" -- 拖拽确认家具详细介绍

    -- 操作：选择风格界面
    self.m_csbConfig.selectStyleMainLayer = "Activity/Redecor/csd/Redecor_operateUI/Redecor_chooseStyleMainLayer.csb" -- 选择风格主界面
    self.m_csbConfig.selectStyleNode = "Activity/Redecor/csd/Redecor_operateUI/Redecor_ChooseStyle.csb" -- 选择风格
    self.m_csbConfig.selectStyleCellNode = "Activity/Redecor/csd/Redecor_operateUI/Redecor_ChooseStyle_node.csb" -- 风格
    self.m_csbConfig.selectStyleOkNode = "Activity/Redecor/csd/Redecor_operateUI/Redecor_ChooseStyle_ok.csb" -- 确认
    self.m_csbConfig.selectStyleCancelNode = "Activity/Redecor/csd/Redecor_operateUI/Redecor_ChooseStyle_cancel.csb" -- 取消

    -- 礼盒界面
    self.m_csbConfig.treasureInfoLayer = "Activity/Redecor/csd/Redecor_giftBoard/Redecor_GiftBoardLayer.csb" -- 礼盒立马开启
    self.m_csbConfig.treasureInfoBtnOpen = "Activity/Redecor/csd/Redecor_giftBoard/Redecor_GiftBoard_Btn_openNow.csb"
    self.m_csbConfig.treasureInfoBtnOpenGems = "Activity/Redecor/csd/Redecor_giftBoard/Redecor_GiftBoard_Btn_openNowGems.csb"
    self.m_csbConfig.treasureInfoBtnPass = "Activity/Redecor/csd/Redecor_giftBoard/Redecor_GiftBoard_Btn_pass.csb"
    -- 结算界面
    self.m_csbConfig.treasureRewardLayer = "Activity/Redecor/csd/Redecor_reward/Redecor_Reward_gift.csb" -- 礼盒奖励界面
    self.m_csbConfig.chapterRewardLayer = "Activity/Redecor/csd/Redecor_reward/Redecor_Reward_chapter.csb" -- 章节奖励界面
    self.m_csbConfig.roundRewardLayer = "Activity/Redecor/csd/Redecor_reward/Redecor_Reward_FinalPrize.csb" -- 轮次奖励界面
    self.m_csbConfig.rewardCoinNode = "Activity/Redecor/csd/Redecor_reward/Node_coins.csb"
    self.m_csbConfig.rewardBgLightNode = "Activity/Redecor/csd/Redecor_reward/Node_bgLight.csb"
    self.m_csbConfig.roundOverStreamerLayer = "Activity/Redecor/csd/Redecor_roundOver/Redecor_RoundSG.csb"
    self.m_csbConfig.roundOverCurtainLayer = "Activity/Redecor/csd/Redecor_roundOver/Redecor_RoundChange.csb"

    -- 关卡弹框相关
    self.m_csbConfig.collectMaxPopEffect = "Activity/Redecor/csd/Redecor_popCollect/CollectMaxPopEffect.csb" -- 关卡内弹框上的特效

    -- 剧情
    self.m_csbConfig.plotLayer = "Activity/Redecor/csd/Redecor_plot/Redecor_Plot.csb"
    self.m_csbConfig.plotMaskTop = "Activity/Redecor/csd/Redecor_plot/Redecor_Plot_node_heiBian_top.csb"
    self.m_csbConfig.plotMaskBottom = "Activity/Redecor/csd/Redecor_plot/Redecor_Plot_node_heiBian_bottom.csb"
    self.m_csbConfig.plotContinue = "Activity/Redecor/csd/Redecor_plot/Redecor_Plot_node_continue.csb"
    self.m_csbConfig.plotRoleAction = "Activity/Redecor/csd/Redecor_plot/Redecor_Plot_node_role.csb"
    self.m_csbConfig.plotRole = "Activity/Redecor/csd/Redecor_plot/Node_role_%d.csb"

    -- 引导
    self.m_csbConfig.guideArrowNode = "Activity/Redecor/csd/Redecor_Guide/Node_jiantou.csb"
    self.m_csbConfig.guideBubbleNode = "Activity/Redecor/csd/Redecor_Guide/Node_qiPao.csb"
    self.m_csbConfig.guideHeadIconNode = "Activity/Redecor/csd/Redecor_Guide/Node_touXiang.csb"
    self.m_csbConfig.guideStep = "Activity/Redecor/csd/Redecor_Guide/Redecor_Guide%d.csb"
    self.m_csbConfig.guideChangeGolden = "Activity/Redecor/csd/Redecor_Guide/Redecor_Guide_changeGolden.csb"

    -- loading
    self.m_csbConfig.loadingLayer = "Activity/RedecorSendLayer.csb"

    -- 排行榜loading
    self.m_csbConfig.rankLoadingLayer = "Activity/Layer_RedecorShowTop.csb"

    -- 转盘
    self.m_csbConfig.wheelMainLayer = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel.csb" -- 转盘主界面
    self.m_csbConfig.wheelMainLight = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_light_bg.csb" -- 转盘主界面背景光
    self.m_csbConfig.wheelMainSpin = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_spin.csb" -- 转盘主界面 spin按钮
    self.m_csbConfig.wheelSector = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_sector.csb" -- 转盘扇面
    self.m_csbConfig.wheelSectorReward = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_sectorReward.csb" -- 转盘扇面上的奖励
    self.m_csbConfig.wheelAddition = "Activity/Redecor/csd/Redecor_wheel/Redecor_jiaCheng.csb" -- 转盘加成
    self.m_csbConfig.wheelSectorWin = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_win.csb" -- 转盘转动结束后中奖的框
    self.m_csbConfig.wheelSectorChange = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_sectorChange.csb" -- 转盘扇面切换为金色
    self.m_csbConfig.wheelSectorChangeLight = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_sector_ef_guang.csb" -- 转盘扇面切换为金色 金光
    self.m_csbConfig.wheelSectorChangeBottom = "Activity/Redecor/csd/Redecor_wheel/Redecor_wheel_sector_ef_di.csb" -- 转盘扇面切换为金色 底
    self.m_csbConfig.wheelRewardLayer = "Activity/Redecor/csd/Redecor_reward/Redecor_Reward_wheel.csb" -- 转盘结算界面
    self.m_csbConfig.wheelNodeRewardLayer = "Activity/Redecor/csd/Redecor_reward/Redecor_Reward_redecor.csb" -- 转盘结算界面 中家具

    --[[--
        lua配置
    ]]
    self.m_luaConfig = {}
    self.m_luaConfig.mainTitleNode = "Activity.RedecorCode.MainNode.RedecorTitleNode"
    self.m_luaConfig.mainTitleRewardNode = "Activity.RedecorCode.MainNode.RedecorTitleRewardNode"
    self.m_luaConfig.mainTitleProgressNode = "Activity.RedecorCode.MainNode.RedecorTitleProgressNode"
    self.m_luaConfig.mainProgressNode = "Activity.RedecorCode.MainNode.RedecorProcessNode"
    self.m_luaConfig.mainProgressBubbleNode = "Activity.RedecorCode.MainNode.RedecorProcessBubbleNode"
    self.m_luaConfig.mainPromotionNode = "Activity.RedecorCode.MainNode.RedecorPromotionNode"
    self.m_luaConfig.mainRankNode = "Activity.RedecorCode.MainNode.RedecorRankNode"
    self.m_luaConfig.mainFullViewNode = "Activity.RedecorCode.MainNode.RedecorFullViewNode"
    self.m_luaConfig.mainTreasureSlotNode = "Activity.RedecorCode.MainNode.RedecorTreasureSlotNode"
    self.m_luaConfig.mainTreasureNode = "Activity.RedecorCode.MainNode.RedecorTreasureNode"
    self.m_luaConfig.mainMultiNode = "Activity.RedecorCode.MainNode.RedecorMultiNode" -- x2 buff标签
    self.m_luaConfig.mainFullViewLayer = "Activity.RedecorCode.RedecorFullViewMainUI"
    self.m_luaConfig.mainRankStarFlyLayer = "Activity.RedecorCode.MainNode.RedecorRankStarFly" -- 飞星星
    self.m_luaConfig.mainRankStarBlastNode = "Activity.RedecorCode.MainNode.RedecorRankStarBlast" -- 飞星星后爆炸效果
    self.m_luaConfig.treasureEffectFlyLayer = "Activity.RedecorCode.MainNode.RedecorTreasureFlyUI" -- 飞礼盒
    self.m_luaConfig.mainTaskNode = "views/Activity_Mission/ActivityTaskBottom_redecor" -- 主界面任务入口
    self.m_luaConfig.mainWheelNode = "Activity.RedecorCode.MainNode.RedecorWheelNode" -- 转盘入口

    self.m_luaConfig.taskMainLayer = "Activity/RedecorTaskMainLayer" -- 任务
    self.m_luaConfig.taskRewardLayer = "Activity.RedecorTaskRewardLayer"

    self.m_luaConfig.ruleLayer = "Activity.RedecorCode.RedecorRuleUI" -- 规则

    self.m_luaConfig.rankLayer = "Activity.RedecorCode.RankUI.RedecorRankUI" -- 排行榜
    self.m_luaConfig.rankCellNode = "Activity.RedecorCode.RankUI.RedecorRankCell%d"
    self.m_luaConfig.rankTopCellNode = "Activity.RedecorCode.RankUI.RedecorRankTopCellNode"
    self.m_luaConfig.rankTitleNode = "Activity.RedecorCode.RankUI.RedecorRankTitleNode"
    self.m_luaConfig.rankHelpLayer = "Activity/RedecorCode/RankUI/RedecorRankHelpUI"

    self.m_luaConfig.promotionLayer = "Activity/Promotion_Redecor" -- 促销主界面
    self.m_luaConfig.promotionItemNode = "Activity.Promotion_RedecorItem"
    self.m_luaConfig.promotionOpenBoxLayer = "Activity.Promotion_RedecorOpenBox"

    self.m_luaConfig.furnitureNode = "Activity.RedecorCode.Furnitures.FurnitureNode"
    self.m_luaConfig.fullFurnitureNode = "Activity.RedecorCode.Furnitures.FullFurnitureNode"
    self.m_luaConfig.furnituresNode = "Activity.RedecorCode.Furnitures.FurnituresNode" -- 所有家具节点
    self.m_luaConfig.fullFurnituresNode = "Activity.RedecorCode.Furnitures.FullFurnituresNode" -- 所有家具节点

    -- self.m_luaConfig.simpleMainNode = "Activity.RedecorCode.SimpleInfo.SimpleMainNode" -- 拖拽主界面
    self.m_luaConfig.simpleInfoNode = "Activity.RedecorCode.SimpleInfo.SimpleInfoNode" -- 家具信息漂浮界面
    self.m_luaConfig.dragSlotNode = "Activity.RedecorCode.SimpleInfo.SlotNode" -- 拖拽确认槽
    self.m_luaConfig.dragArrowNode = "Activity.RedecorCode.SimpleInfo.ArrowNode" -- 拖拽确认箭头
    self.m_luaConfig.dragInfo = "Activity.RedecorCode.SimpleInfo.InfoNode" -- 拖拽确认家具详细介绍

    self.m_luaConfig.selectStyleMainLayer = "Activity.RedecorCode.SelectStyle.RedecorStyleMainUI" -- 选择风格主界面
    self.m_luaConfig.selectStyleNode = "Activity.RedecorCode.SelectStyle.StyleNode" -- 选择风格
    self.m_luaConfig.selectStyleCellNode = "Activity.RedecorCode.SelectStyle.StyleCellNode" -- 风格
    self.m_luaConfig.selectStyleOkNode = "Activity.RedecorCode.SelectStyle.ConfirmNode" -- 确认
    self.m_luaConfig.selectStyleCancelNode = "Activity.RedecorCode.SelectStyle.CancelNode" -- 取消

    self.m_luaConfig.treasureInfoLayer = "Activity.RedecorCode.TreasureUI.TreasureInfoUI" -- 礼盒信息
    self.m_luaConfig.treasureInfoBtnOpen = "Activity.RedecorCode.TreasureUI.TreasureInfoBtnOpen"
    self.m_luaConfig.treasureInfoBtnOpenGems = "Activity.RedecorCode.TreasureUI.TreasureInfoBtnOpenGems"
    self.m_luaConfig.treasureInfoBtnPass = "Activity.RedecorCode.TreasureUI.TreasureInfoBtnPass"

    self.m_luaConfig.rewardCoinNode = "Activity.RedecorCode.RewardUI.CoinNode" -- 结算界面：通用金币
    self.m_luaConfig.rewardBgLightNode = "Activity.RedecorCode.RewardUI.BgLightNode" -- 结算界面：通用背景光
    self.m_luaConfig.treasureRewardLayer = "Activity.RedecorCode.RewardUI.TreasureRewardUI" -- 礼盒奖励信息
    self.m_luaConfig.chapterRewardLayer = "Activity.RedecorCode.RewardUI.ChapterRewardUI" -- 章节奖励信息
    self.m_luaConfig.roundRewardLayer = "Activity.RedecorCode.RewardUI.RoundRewardUI" -- 章节奖励信息
    self.m_luaConfig.wheelRewardLayer = "Activity.RedecorCode.RewardUI.WheelRewardUI" -- 转盘结算界面
    self.m_luaConfig.wheelNodeRewardLayer = "Activity.RedecorCode.RewardUI.WheelNodeRewardUI" -- 转盘结算界面 中家具

    self.m_luaConfig.roundOverStreamerLayer = "Activity.RedecorCode.RoundOver.RoundOverStreamerUI" -- 轮次过场 扫光
    self.m_luaConfig.roundOverCurtainLayer = "Activity.RedecorCode.RoundOver.RoundOverCurtainUI" -- 轮次过场 帘子

    self.m_luaConfig.entryTipNode = "Activity.RedecorCode.EntryNode.RedecorEntryTip"
    self.m_luaConfig.entryPromotionNode = "Activity.RedecorCode.EntryNode.RedecorEntryPromotionNode"

    self.m_luaConfig.collectMaxPopEffect = "Activity.RedecorCode.popCollectUI.CollectMaxPopEffect"

    self.m_luaConfig.plotLayer = "Activity.RedecorCode.PlotUI.RedecorPlotUI"
    self.m_luaConfig.plotMask = "Activity.RedecorCode.PlotUI.RedecorPlotMask"
    self.m_luaConfig.plotContinue = "Activity.RedecorCode.PlotUI.RedecorPlotContinue"
    self.m_luaConfig.plotRoleAction = "Activity.RedecorCode.PlotUI.RedecorPlotRoleAction"
    self.m_luaConfig.plotRole = "Activity.RedecorCode.PlotUI.RedecorPlotRole"

    self.m_luaConfig.wheelMainLayer = "Activity.RedecorCode.WheelUI.RedecorWheelMainUI" -- 转盘主界面
    self.m_luaConfig.wheelMainSpin = "Activity.RedecorCode.WheelUI.RedecorWheelSpinNode" -- 转盘主界面 spin按钮
    self.m_luaConfig.wheelSector = "Activity.RedecorCode.WheelUI.RedecorWheelSectorNode" -- 转盘扇面
    self.m_luaConfig.wheelSectorChange = "Activity.RedecorCode.WheelUI.RedecorWheelSectorChangeNode" -- 转盘扇面切换为金色
    self.m_luaConfig.wheelSectorReward = "Activity.RedecorCode.WheelUI.RedecorWheelSectorRewardNode" -- 转盘扇面上的奖励
    self.m_luaConfig.wheelAddition = "Activity.RedecorCode.WheelUI.RedecorWheelAdditionNode" -- 转盘加成

    -- 引导
    self.m_luaConfig.guideArrowNode = "Activity.RedecorCode.GuideUI.RedecorGuideArrow"
    self.m_luaConfig.guideBubbleNode = "Activity.RedecorCode.GuideUI.RedecorGuideBubble"
    self.m_luaConfig.guideHeadIconNode = "Activity.RedecorCode.GuideUI.RedecorGuideHeadIcon"
    self.m_luaConfig.guideStep = "Activity.RedecorCode.GuideUI.RedecorGuideStep%d"
    self.m_luaConfig.guideChangeGolden = "Activity.RedecorCode.GuideUI.RedecorGuideChangeGolden"

    --[[--
        音乐音效资源配置
    ]]
    self.m_soundConfig = {}
    self.m_soundConfig.bgMusic = "Activity/Redecor/sound/bgm.mp3"
    self.m_soundConfig.drag_click = "Activity/Redecor/sound/drag_click.mp3"
    self.m_soundConfig.drag_over = "Activity/Redecor/sound/drag_over.mp3"
    self.m_soundConfig.gift_appear = "Activity/Redecor/sound/gift_appear.mp3"
    self.m_soundConfig.gift_open = "Activity/Redecor/sound/gift_open.mp3"
    self.m_soundConfig.node_appear = "Activity/Redecor/sound/node_appear.mp3"
    self.m_soundConfig.node_click = "Activity/Redecor/sound/node_click.mp3"
    self.m_soundConfig.plotText_show = "Activity/Redecor/sound/plotText_show.mp3"
    self.m_soundConfig.progress_fly = "Activity/Redecor/sound/progress_fly.mp3"
    self.m_soundConfig.reward_chapter = "Activity/Redecor/sound/reward_chapter.mp3"
    self.m_soundConfig.reward_gift = "Activity/Redecor/sound/reward_gift.mp3"
    self.m_soundConfig.reward_round = "Activity/Redecor/sound/reward_round.mp3"
    self.m_soundConfig.roundOver_lianzi = "Activity/Redecor/sound/roundOver_lianzi.mp3"
    self.m_soundConfig.roundOver_lizi = "Activity/Redecor/sound/roundOver_lizi.mp3"
    self.m_soundConfig.selectStyle_click = "Activity/Redecor/sound/selectStyle_click.mp3"
    self.m_soundConfig.simple_open = "Activity/Redecor/sound/simple_open.mp3"
    self.m_soundConfig.star_fly = "Activity/Redecor/sound/star_fly.mp3"
    self.m_soundConfig.title_fly = "Activity/Redecor/sound/title_fly.mp3"

    self.m_soundConfig.wheel_win = "Activity/Redecor/sound/wheel_win.mp3"
    self.m_soundConfig.wheel_roll = "Activity/Redecor/sound/wheel_roll.mp3"
    self.m_soundConfig.wheel_golden = "Activity/Redecor/sound/wheel_golden.mp3"

    self.m_soundConfig.node_complete = "Activity/Redecor/sound/node_complete.mp3"
end

-- 粒子配置
function RedecorThemeLogic:getLiziCfg()
    return self.m_liziCfg
end

-- 文案配置
function RedecorThemeLogic:getTxtCfg()
    return self.m_txtConfig
end

-- png路径配置
function RedecorThemeLogic:getImgCfg()
    return self.m_imgConfig
end

-- csb资源配置
function RedecorThemeLogic:getCsbCfg()
    return self.m_csbConfig
end

-- lua路径配置
function RedecorThemeLogic:getLuaCfg()
    return self.m_luaConfig
end

-- 音乐音效路径配置
function RedecorThemeLogic:getSoundCfg()
    return self.m_soundConfig
end

-- 多主题重写此方法
-- 配置关卡能量收集条相关信息(日志 跳转 收集特效)
-- 从 EntryNodeConfig.popup_config 中迁移过来的
function RedecorThemeLogic:getEntryNodeDataCfg()
    return {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "RedecorStageIcon", -- 活动左边条 打点传入参数
        lua_file = "RedecorMainUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Redecor/other/ticket_fly.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    }
end

-- 多主题重写此方法
-- 关卡弹框列表 只有继承了EntryNodeBase的活动类才有效
-- 从 EntryNodeConfig.popup_config 中迁移过来的， 方便多主题控制
function RedecorThemeLogic:getEntryNodePopCfg()
    return {
        ["levelUp"] = "Activity/Activity_Redecor", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "RedecorMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Redecor/csd/Redecor_popCollect/CollectPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/Redecor/csd/Redecor_popCollect/CollectPop_Portrait.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/RedecorCode/PopCollectUI/CollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "RedecorMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Redecor/csd/Redecor_popCollect/CollectMaxPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/Redecor/csd/Redecor_popCollect/CollectMaxPop_Portrait.csb" -- 竖版资源路径
        }
    }
end

-- TODO: 扩充界面逻辑，不同的主题中不一样的逻辑，函数提取到这里

return RedecorThemeLogic
