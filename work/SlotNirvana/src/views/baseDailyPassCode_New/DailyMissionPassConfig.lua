
local DailyMissionPassConfig =  {}

local CODE_PATH = "views/baseDailyPassCode_New/"
local RES_PATH = "Pass/"
local TABLEVIEW_PATH = CODE_PATH.."tableView/"

-- 额外配置信息
DailyMissionPassConfig.extra = 
{
    DailyMissionPass_CloseMainLayerPopUnlockCD = 600,
    DailyMissionPass_CloseMainLayerPopUnlock = "closeMainLayerPopUnlock",-- 关闭主界面引导解锁
    DailyMissionPass_CloseBuyTicketLayerPopUnlock = "closeBuyTicketLayerPopUnlock", -- 关闭解锁界面再次引导解锁
}
-- base下的代码文件路径
DailyMissionPassConfig.code = 
{
    DailyMissionPass_MailLayer                  = CODE_PATH.."DailyMissionPassMainLayer",               -- dailypass 主界面
    DailyMissionPass_Title                      = CODE_PATH.."DailyMissionPassTitleNode",               -- dailypass 标题节点
    DailyMissionPass_Infolayer                  = CODE_PATH.."DailyMissionPassMainInfoLayer",           -- dailypass 游戏信息页
    DailyMissionPass_ConfirmLayer               = CODE_PATH.."DailyMissionPassMainGemsConfirmLayer",    -- dailypass 钻石解锁确认页
    DailyMissionPass_RewardLayer                = CODE_PATH.."DailyMissionPassRewardLayer",             -- dailypass 奖励面板
    DailyMissionPass_RewardTopUi                = CODE_PATH.."DailyMissionPassRewardTopUi",             -- dailypass pass界面 topui
    DailyMissionPass_BuyTicketLayer             = CODE_PATH.."DailyMissionPassBuyTicketNewLayer",       -- dailypass 购买门票界面 2021年09月06日15:03:32 新版修改
    DailyMissionPass_BuyLevelStoreLayer         = CODE_PATH.."DailyMissionPassBuyLevelLayer",           -- dailypass pass界面 购买等级界面
    DailyMissionPass_SeasonProgressNode         = CODE_PATH.."DailyMissionPassSeasonProgressNode",      -- dailypass 主界面pass进度条
    DailyMissionPass_MedalFlyNode               = CODE_PATH.."DailyMissionPassMedalFlyNode",            -- dailypass 飞行节点
    DailyMissionPass_GuideLayer                 = CODE_PATH.."DailyMissionPassGuideLayer",              -- dailypass 引导节点
    DailyMissionPass_BuyTicketRewardLayer       = CODE_PATH.."DailyMissionPassBuyTicketRewardLayer",    -- dailypass 购买门票后续再次引导购买门票 获取奖励 2022-01-25
    DailyMissionPass_RushTitleNode              = CODE_PATH.."DailyMissionPassRushTitleNode" ,          -- dailypass 关联missionrush 活动节点 2022-02-23
   
    DailyMissionPass_PreviewCellProgressNode      = CODE_PATH.."DailyMissionPassPreviewCellProgressNode" ,      -- dailypass 奖励界面 右侧固定奖励 进度条
    
    --三行pass
    DailyMissionPass_PreviewCellNode_ThreeLine           = CODE_PATH.."threeLine/DailyMissionThreeLinePassPreviewCellNode" ,          -- dailypass 奖励界面 右侧固定奖励
    DailyMissionPass_BuyTicketLayer_ThreeLine            = CODE_PATH.."threeLine/DailyMissionThreeLinePassBuyTicketNewLayer",       -- 三行 dailypass 购买门票界面
    DailyMissionPass_RewardTopUi_ThreeLine               = CODE_PATH.."threeLine/DailyMissionThreeLinePassRewardTopUi",             -- dailypass pass界面 topui
    DailyMissionPass_BuyTicketRewardLayer_ThreeLine      = CODE_PATH.."threeLine/DailyMissionThreeLinePassBuyTicketRewardLayer",    -- dailypass 购买门票后续再次引导购买门票 获取奖励 2022-01-25
    --BUFF
    DailyMissionPass_PromotionNode              = CODE_PATH.."DailyMissionPassPromotionNode",           -- dailypass buff促销节点
    DailyMissionPass_BuySaleLayer               = CODE_PATH.."DailyMissionPassBuySaleLayer",            -- dailypass buff促销界面

    -- TABLE VIEW
    DailyMissionPass_PassTableView              = TABLEVIEW_PATH.."DailyMissionPassTableView",          -- dailypass pass 奖励滑动层
    -- DailyMissionPass_PassCell                   = TABLEVIEW_PATH.."DailyMissionPassCellNode",           -- dailypass  奖励滑动层所有节点容器
    -- DailyMissionPass_PassSafeBoxCell            = TABLEVIEW_PATH.."DailyMissionPassSafeBoxCell",        -- dailypass pass 保险箱节点
    -- DailyMissionPass_PassSafeBoxCellQipao       = TABLEVIEW_PATH.."DailyMissionPassSafeBoxCellQiPao",   -- dailypass pass 宝箱气泡
    -- DailyMissionPass_PassRewardCell             = TABLEVIEW_PATH.."DailyMissionPassRewardCell",         -- dailypass pass 奖励节点
    -- DailyMissionPass_PassCellQipao              = TABLEVIEW_PATH.."DailyMissionPassQiPao",              -- dailypass pass 气泡

    DailyMissionPass_PassCell_ThreeLine                    = TABLEVIEW_PATH.."threeLine/DailyMissionThreeLinePassCellNode",           -- 三行 dailypass  奖励滑动层所有节点容器
    DailyMissionPass_PassSafeBoxCell_ThreeLine             = TABLEVIEW_PATH.."threeLine/DailyMissionThreeLinePassSafeBoxCell",        -- 三行  dailypass pass 保险箱节点
    DailyMissionPass_PassSafeBoxCellQipao_ThreeLine        = TABLEVIEW_PATH.."threeLine/DailyMissionThreeLinePassSafeBoxCellQiPao",   -- 三行  dailypass pass 宝箱气泡
    DailyMissionPass_PassRewardCell_ThreeLine              = TABLEVIEW_PATH.."threeLine/DailyMissionThreeLinePassRewardCell",         -- 三行  dailypass pass 奖励节点
    DailyMissionPass_PassCellQipao_ThreeLine               = TABLEVIEW_PATH.."threeLine/DailyMissionThreeLinePassQiPao",              -- 三行  dailypass pass 气泡
    -----------------   折扣 -------------------
    DailyMissionPass_BuySaleTag = CODE_PATH .. "DailyMissionPassBuySaleTag",
    DailyMissionPass_BuySaleTagEf = CODE_PATH .. "DailyMissionPassBuySaleTagEf",
    DailyMissionPass_BuyCouponRewardLayer = CODE_PATH .. "DailyMissionPassBuyCouponRewardLayer",
}
-- base下的资源路径
DailyMissionPassConfig.res = 
{
    ------------------------------------ Mission 部分 ------------------------------------
    -- dailypass 礼物盒
    DailyMissionPass_GiftNode                          = RES_PATH.."csd/pass_Mission/Pass_GiftNode.csb",
    -- dailypass 钻石消耗
    DailyMissionPass_ComfirmLayer                      = RES_PATH.."csd/pass_Mission/Pass_SkipConfirm.csb",
    DailyMissionPass_ComfirmLayer_Vertical             = RES_PATH.."csd/pass_Mission/Pass_SkipConfirm_Vertical.csb",
    -- dailypass 飞行节点
    DailyMissionPass_MedalFlyNode                      = RES_PATH.."csd/pass_Mission/Pass_MedalFlyNode.csb",
    
    ------------------------------------ 主目录 部分 ------------------------------------
    -- dailypass 主界面
    DailyMissionPass_MainLayer                         = RES_PATH.."csd/Mission_MainLayer.csb",
    DailyMissionPass_MainLayer_Vertical                = RES_PATH.."csd/Mission_MainLayer_Vertical.csb",
    -- 三行 dailypass 主界面
    DailyMissionPass_MainLayer_ThreeLine                         = RES_PATH.."csd/Pass_Main2Layer.csb",
    DailyMissionPass_MainLayer_Vertical_ThreeLine                = RES_PATH.."csd/Pass_Main2Layer_Vertical.csb",

    -- dailypass pass进度节点
    DailyMissionPass_SeasonProgressNode                = RES_PATH.."csd/Pass_MainLeftProgress.csb",
    -- dailypass 主界面标题
    DailyMissionPass_Title                             = RES_PATH.."csd/Pass_TitleBg.csb",
    DailyMissionPass_Title_Vertical                    = RES_PATH.."csd/Pass_TitleBg_Vertical.csb",

    -- dailypass 关卡活动入口
    DailyMissionPass_EntryNode                         = RES_PATH.."csd/Pass_EntryNode.csb",
    -- dailypass 引导
    DailyMissionPass_GuideLayer                        = RES_PATH.."csd/Pass_Guide.csb",
    DailyMissionPass_GuideLayer_Vertical               = RES_PATH.."csd/Pass_Guide_Vertical.csb",
    ------------------------------------ reward 部分 ------------------------------------
    -- tableview右侧固定节点
    DailyMissionPass_PreviewCellNode                   = RES_PATH.."csd/pass_Reward/Pass_PreviewCell.csb",
    DailyMissionPass_PreviewCellNode_Vertical          = RES_PATH.."csd/pass_Reward/Pass_PreviewCell_Vertical.csb",

    -- tableview右侧固定节点 进度条
    DailyMissionPass_PreviewCellProgressNode           = RES_PATH.."csd/pass_Reward/Pass_PreviewCell_Progress.csb",
    -- dailypass pass页top ui
    DailyMissionPass_RewardTopUi                       = RES_PATH.."csd/pass_Reward/Pass_RewardTopUi.csb",
    DailyMissionPass_RewardTopUi_Vertical              = RES_PATH.."csd/pass_Reward/Pass_RewardTopUi_Vertical.csb",   


    -- 三行 dailypass pass页top ui
    DailyMissionPass_RewardTopUi_ThreeLine                         = RES_PATH.."csd/pass_Reward/Pass_RewardTopUi.csb",
    DailyMissionPass_RewardTopUi_Vertical_ThreeLine                = RES_PATH.."csd/pass_Reward/Pass_RewardTopUi_Vertical.csb", 


    -- dailypass pass页容器、气泡、奖励节点、保险箱节点
    DailyMissionPass_PassCell                          = RES_PATH.."csd/pass_Reward/Pass_Cell.csb",
    DailyMissionPass_PassCellQipao                     = RES_PATH.."csd/pass_Reward/Pass_QiPao.csb",
    DailyMissionPass_PassRewardPayCell                 = RES_PATH.."csd/pass_Reward/Pass_TicketCell.csb",
    DailyMissionPass_PassRewardFreeCell                = RES_PATH.."csd/pass_Reward/Pass_FreeCell.csb",
    DailyMissionPass_PassSafeBoxCell                   = RES_PATH.."csd/pass_Reward/Pass_SafeBox.csb",
    DailyMissionPass_PassSafeBoxCellQiPao              = RES_PATH.."csd/pass_Reward/Pass_SafeBox_QiPao.csb",

    ------------------------------------- 三行-----------------------------
    -- tableview右侧固定节点
    DailyMissionPass_PreviewCellNode_ThreeLine                     = RES_PATH.."csd/pass_Reward/Pass_PreviewCell.csb",
    -- tableview右侧固定节点 进度条
    DailyMissionPass_PreviewCellProgressNode_ThreeLine             = RES_PATH.."csd/pass_Reward/Pass_PreviewCell_Progress.csb",
    -- 三行 dailypass pass页容器、气泡、奖励节点、保险箱节点
    DailyMissionPass_PassCell_ThreeLine                            = RES_PATH.."csd/pass_Reward/Pass_Cell.csb",
    DailyMissionPass_PassCell_ThreeLine_Vertical                            = RES_PATH.."csd/pass_Reward/Pass_Cell_Vertical.csb",


    DailyMissionPass_PassCellQipao_ThreeLine                       = RES_PATH.."csd/pass_Reward/Pass_QiPao.csb",
    DailyMissionPass_PassSafeBoxCell_ThreeLine                     = RES_PATH.."csd/pass_Reward/Pass_SafeBox.csb",
    DailyMissionPass_PassSafeBoxCell_ThreeLine_Vertical                     = RES_PATH.."csd/pass_Reward/Pass_SafeBox_Vertical.csb",
    DailyMissionPass_PassSafeBoxCellQiPao_ThreeLine                = RES_PATH.."csd/pass_Reward/Pass_SafeBox_QiPao.csb",
    
    DailyMissionPass_PassRewardFreeCell_ThreeLine                  = RES_PATH.."csd/pass_Reward/Pass_TicketFreeCell.csb",
    DailyMissionPass_PassRewardSeasonCell_ThreeLine                = RES_PATH.."csd/pass_Reward/Pass_TicketSeasonCell.csb",
    DailyMissionPass_PassRewardPremiumCell_ThreeLine                = RES_PATH.."csd/pass_Reward/Pass_TicketPremiumCell.csb",

    ------------------------------------ 其余文件夹 部分 ------------------------------------
    -- dailypass 奖励领取页
    DailyMissionPass_RewardLayer                       = RES_PATH.."csd/pass_CollectReward/Pass_CollectRawardLayer.csb",
    DailyMissionPass_RewardLayer_Vertical              = RES_PATH.."csd/pass_CollectReward/Pass_CollectRawardLayer_Vertical.csb",
    -- dailypass 信息页
    DailyMissionPass_Infolayer                         = RES_PATH.."csd/pass_Info/Pass_InfoLayer.csb",
    DailyMissionPass_Infolayer_Vertical                = RES_PATH.."csd/pass_Info/Pass_InfoLayer_Vertical.csb",
    -- dailypass 购买等级
    DailyMissionPass_LevelStoreLayer                   = RES_PATH.."csd/pass_LevelStore/Pass_LevelStore.csb",
    DailyMissionPass_LevelStoreLayer_Vertical          = RES_PATH.."csd/pass_LevelStore/Pass_LevelStore_Vertical.csb", 
    -- dailypass 促销
    DailyMissionPass_SaleLayer                         = RES_PATH.."csd/pass_Promotion/Pass_PromotionSale.csb",
    DailyMissionPass_SaleLayer_Vertical                = RES_PATH.."csd/pass_Promotion/Pass_PromotionSale_Vertical.csb",
    -- dailypass buff节点
    DailyMissionPass_PromotionNode                     = RES_PATH.."csd/pass_Promotion/Pass_PromotionIcon.csb",
    -- csc 2021-09-06 12:06:55 dailypass 新版门票
    DailyMissionPass_BuyTicketNewLayer                 = RES_PATH.."csd/pass_BuyTicket_New/Pass_BuyTicketNewLayer.csb",
    DailyMissionPass_BuyTicketNewLayer_Vertical        = RES_PATH.."csd/pass_BuyTicket_New/Pass_BuyTicketNewLayer_Vertical.csb",

    -- csc 2022-01-25 18:03:09 dailypass 新版门票 关闭后新增奖励引导 面板
    DailyMissionPass_BuyTicketRewardLayer              = RES_PATH.."csd/pass_BuyTicketReward/Pass_BuyTicketRewardLayer.csb",
    DailyMissionPass_BuyTicketRewardLayer_Vertical     = RES_PATH.."csd/pass_BuyTicketReward/Pass_BuyTicketRewardLayer_Vertical.csb",

    -- csc 2022-01-25 18:03:09 dailypass 新版门票 关闭后新增奖励引导 面板
    DailyMissionPass_BuyTicketRewardLayer_ThreeLine               = RES_PATH.."csd/pass_BuyTicketReward/Pass_BuyTicketReward2Layer.csb",
    DailyMissionPass_BuyTicketRewardLayer_Vertical_ThreeLine      = RES_PATH.."csd/pass_BuyTicketReward/Pass_BuyTicketReward2Layer_Vertical.csb",

    -- csc 2022-02-23 关联missionrush 活动节点
    DailyMissionPass_MissionRushNode                   = RES_PATH.."csd/pass_ExtraAcivity/Pass_NodeTitleFire.csb",
    ------------------------------------ 特效 部分 ------------------------------------
    -- dailypass 特效
    DailyMissionPass_FreeCellBg_Effect                 = RES_PATH.."csd/pass_Reward/Pass_FreeCell_ef_node_1.csb",
    DailyMissionPass_FreeCellSg_Effect                 = RES_PATH.."csd/pass_Reward/Pass_FreeCell_ef_node_2.csb",
    DailyMissionPass_PayCellBg_Effect                  = RES_PATH.."csd/pass_Reward/Pass_TicketCell_ef_node_1.csb",
    DailyMissionPass_PayCellSg_Effect                  = RES_PATH.."csd/pass_Reward/Pass_TicketCell_ef_node_2.csb",
    DailyMissionPass_SafeBoxCell_Effect                = RES_PATH.."csd/pass_Reward/Pass_SafeBox_node_guang.csb",
    DailyMissionPass_LevelProgress                     = RES_PATH.."csd/pass_Reward/Pass_LevelProgress.csb",

    -- 三行 dailypass 特效
    DailyMissionPass_FreeCellBg_Effect_ThreeLine                   = RES_PATH.."csd/pass_Reward/Pass_TicketFreeCell_bjg.csb",
    DailyMissionPass_SeasonCellBg_Effect_ThreeLine                    = RES_PATH.."csd/pass_Reward/Pass_TicketSeasonCell_bjg.csb",
    DailyMissionPass_PremiumCellBg_Effect_ThreeLine                    = RES_PATH.."csd/pass_Reward/Pass_TicketPremiumCell_bjg.csb",

    DailyMissionPass_SafeBoxCell_Effect_ThreeLine                  = RES_PATH.."csd/pass_Reward/Pass_SafeBox_node_guang.csb",
    DailyMissionPass_LevelProgress_ThreeLine                       = RES_PATH.."csd/pass_Reward/Pass_LevelProgress.csb",
    DailyMissionPass_LevelProgress_ThreeLine_Vertical                       = RES_PATH.."csd/pass_Reward/Pass_LevelProgress_Vertical.csb",

    -- 三行  csc 2021-09-06 12:06:55 dailypass 新版门票
    DailyMissionPass_BuyTicketNewLayer_ThreeLine                  = RES_PATH.."csd/pass_BuyTicket_New/Pass_BuyTicketNew2Layer.csb",
    DailyMissionPass_BuyTicketNewLayer_Vertical_ThreeLine         = RES_PATH.."csd/pass_BuyTicket_New/Pass_BuyTicketNew2Layer_Vertical.csb",
    ------------------------------------ 图片 部分 ------------------------------------
    -- dailypass 替图片资源
    DailyMissionPass_LevelProgress_Frame               = RES_PATH.."ui/ui_reward2/pass_progress_jiao.png",
    DailyMissionPass_LevelProgress_Frame_Arrived       = RES_PATH.."ui/ui_reward2/pass_progress_kuang.png",
    DailyMissionPass_LevelProgress_Frame_Last               = RES_PATH.."ui/ui_reward2/pass_progressend.png",

    
    DailyMissionPass_Mask                              = RES_PATH.."ui/ui_guide/pass_guide_zhezhao.png",
    ------------------------------------ 音效 部分 ------------------------------------
    -- mp3
    PASS_MISSION_REFRESH_MP3                    = RES_PATH.."sound/pass_mission_refresh.mp3",
    PASS_FLYNODE_ACTION_MP3                     = RES_PATH.."sound/pass_fly_action.mp3",
    PASS_REWARDLAYER_OPEN_MP3                   = RES_PATH.."sound/pass_rewardlayer_open.mp3",
    PASS_MISSION_BGM_MP3                        = RES_PATH.."sound/pass_bg.mp3",
    PASS_AUTO_COLLECT_MP3                       = RES_PATH.."sound/pass_auto_effect.mp3",
    PASS_OPEN_GIFT_MP3                          = RES_PATH.."sound/pass_open_gift.mp3",
    ------------------------------------ spine 部分 ------------------------------------
    -- spine
    AUTO_COLLECT_SPINE_PATH                     = RES_PATH.."spine/pass_huiju",
    DailyMissionPass_MainLayerNpc                      = RES_PATH.."spine/NewPass_npc1",
    DailyMissionPass_RushTitleFire                     = RES_PATH.."spine/Pass_Title_Fire",

    DailyMissionPass_LevelProgress_Font                = RES_PATH.."ui/ui_reward2/shuzi_16-export.fnt",
    DailyMissionPass_LevelProgress_Font_Arrived                = RES_PATH.."ui/ui_reward2/shuzi_15-export.fnt",

    ---------   折扣 --------------------
    BuySaleTag = RES_PATH .. "csd/pass_BuyTicket_New/Pass_BuyTicketNew2Layer_tag.csb",  
    BuySaleTagEf = RES_PATH .. "csd/pass_BuyTicket_New/Pass_BuyTicketNew2Layer_piao.csb",
    BuyCouponRewardLayer = RES_PATH .. "csd/pass_CollectReward/Pass_CollectRawardLayer_off.csb",
    BuyCouponRewardLayerVertical = RES_PATH .. "csd/pass_CollectReward/Pass_CollectRawardLayer_Vertical_off.csb"  
}

return DailyMissionPassConfig
