
local PinBallGoConfig =  {}

local CODE_PATH = "Activity."
local RES_PATH = "Activity/PinBallGo/csd/"
local RES_SOUND_PATH = "Activity/PinBallGo/sound/"

-- 额外配置信息
PinBallGoConfig.extra = 
{
    Path_Path = CODE_PATH.."PinBallGoPath"
}
-- base下的代码文件路径
PinBallGoConfig.code = 
{

    ------------------------------------ 游戏 部分 ------------------------------------
    -- pinballgo 游戏界面
    PinBallGo_GameLayer                         = CODE_PATH.."PinBallGoGameLayer",
    -- pinballgo 小球
    PinBallGo_BallNode                          = CODE_PATH.."PinBallGoBallNode",
    -- pinballgo 隔板门
    PinBallGo_DoorNode                          = CODE_PATH.."PinBallGoDoorNode",
    -- pinballgo 对号
    PinBallGo_TickNode                          = CODE_PATH.."PinBallGoTickNode",
    -- pinballgo 档位节点
    PinBallGo_LevelNode                         = CODE_PATH.."PinBallGoLevelNode",
    -- pinballgo 奖励领取遮罩
    PinBallGo_DarkCelllNode                     = CODE_PATH.."PinBallGoDarkGiftNode",
    -- pinballgo 转场
    PinBallGo_TransitionNode                    = CODE_PATH.."PinBallGoTransitionNode",
    -- pinballgo 奖励节点
    PinBallGo_RewardNode                        = CODE_PATH.."PinBallGoRewardNode",
    -- pinballgo 欢迎界面
    PinBallGo_WelcomeLayer                      = CODE_PATH.."PinBallGoWelcomeLayer",
    -- pinballgo 碰撞球节点
    PinBallGo_CrashBallNode                     = CODE_PATH.."PinBallGoCrashBallNode",
    -- pinballgo 碰撞球进度条粒子
    PinBallGo_ProgressParticleNode              = CODE_PATH.."PinBallGoProgressParticleNode",
    -- pinballgo 弹簧
    PinBallGo_SpringNode                        = CODE_PATH.."PinBallGoSpringNode",
    -- pinballgo   奖励数量文本
    PinBallGo_RewardLableNode                   = CODE_PATH.."PinBallGoRewardLableNode",

    ------------------------------------ 购买 部分 ------------------------------------
    -- pinballgo 购买界面
    PinBallGo_PurchaseLayer                     = CODE_PATH.."PinBallGoPurchaseLayer",
    -- pinballgo 购买界面 确定关闭界面
    PinBallGo_PurchaseConfirmationLayer         = CODE_PATH.."PinBallGoPurchaseConfirmationLayer",   

    ------------------------------------ 奖励 部分 ------------------------------------
    -- pinballgo 付费游戏或者免费游戏奖励界面
    PinBallGo_VersionRewardLayer                = CODE_PATH.."PinBallGoGameRewardLayer",

    ------------------------------------ 获得道具触发 部分 ------------------------------------
    -- pinballgo 道具触发界面
    PinBallGo_TriggerBoardLayer                 = CODE_PATH.."PinBallGoTriggerBoardLayer",   
}
-- base下的资源路径
PinBallGoConfig.res = 
{
    ------------------------------------ 游戏 部分 ------------------------------------
    -- pinballgo 游戏界面
    PinBallGo_GameLayer                         = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi.csb",
    -- pinballgo 小球
    PinBallGo_BallNode                          = RES_PATH.."PinBallGo_MainUi/PinBallGo_ball.csb",
    -- pinballgo 隔板门  有动画 通过追加ID创建
    PinBallGo_DoorNode                          = RES_PATH.."PinBallGo_MainUi/PinBallGo_door",
    -- pinballgo 对号
    PinBallGo_TickNode                          = RES_PATH.."PinBallGo_MainUi/PinballGo_duiHao.csb",
    -- pinballgo 档位节点
    PinBallGo_LevelNode                         = RES_PATH.."PinBallGo_MainUi/PinBallGo_level.csb",
    -- pinballgo 奖励领取遮罩
    PinBallGo_DarkCelllNode                     = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_dark.csb",
    -- pinballgo 转场
    PinBallGo_TransitionNode                    = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_zhuanchang.csb",
    -- pinballgo 奖励节点
    PinBallGo_RewardNode                        = RES_PATH.."PinBallGo_MainUi/PinBallGo_reward.csb",
    -- pinballgo 欢迎界面
    PinBallGo_WelcomeLayer                      = RES_PATH.."PinBallGo_MainUi/PinBallGo_welcome.csb",
    -- pinballgo 碰撞球节点
    PinBallGo_CrashBallNode                     = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_reward.csb",
    -- pinballgo 奖励切换闪光
    PinBallGo_RewardActNode                     = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_jiangli_g.csb",
    -- pinballgo 碰撞球特效
    PinBallGo_CrashBallAct                      = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_reward_baodian.csb",
    -- pinballgo 奖励节点飞行托尾
    PinBallGo_RewardTuoWeiActNode               = RES_PATH.."PinBallGo_MainUi/PinBallGo_tuowei.csb",
    -- pinballgo 碰撞球进度条粒子
    PinBallGo_ProgressParticleNode              = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_reward_jindutiaolizi.csb",
    -- pinballgo 奖励背景闪光
    PinBallGo_RewardBGActNode                   = RES_PATH.."PinBallGo_MainUi/PinBallGo_MainUi_jiangli_idle.csb",
    -- pinballgo 弹簧
    PinBallGo_SpringNode                        = RES_PATH.."PinBallGo_MainUi/PinBallGo_tanhuang.csb",
    -- pinballgo   奖励数量文本
    PinBallGo_RewardLableNode                   = RES_PATH.."PinBallGo_MainUi/PinBallGo_rewardlabel.csb",

    ------------------------------------ 购买 部分 ------------------------------------
    -- pinballgo 购买界面
    PinBallGo_PurchaseLayer                     = RES_PATH.."PinBallGo_Purchase/PinBallGo_Purchase.csb",
    -- pinballgo 购买界面 确定关闭界面
    PinBallGo_PurchaseConfirmationLayer         = RES_PATH.."PinBallGo_Purchase/PinBallGo_Purchase_confirmation.csb",   

    ------------------------------------ 奖励 部分 ------------------------------------
    -- pinballgo 免费游戏奖励界面
    PinBallGo_FreeVersionRewardLayer            = RES_PATH.."PinBallGo_Reward/PinBallGo_FreeVersionReward.csb",
    -- pinballgo 付费游戏奖励界面
    PinBallGo_PayVersionRewardLayer             = RES_PATH.."PinBallGo_Reward/PinBallGo_PayVersionReward.csb",

    ------------------------------------ 获得道具触发 部分 ------------------------------------
    -- pinballgo 道具触发界面
    PinBallGo_TriggerBoardLayer                 = RES_PATH.."PinBallGo_Trigger/PinBallGo_TriggerBoard.csb",
    -- pinballgo 道具触发界面
    PinBallGo_TriggerBoardLayer_Vertical        = RES_PATH.."PinBallGo_Trigger/PinBallGo_TriggerBoard_Vertical.csb",    
   
    ------------------------------------ 图片 部分 ------------------------------------

    ------------------------------------ 音效 部分 ------------------------------------
    -- mp3
    PinBallGo_BGM_MP3                           = RES_SOUND_PATH.."PinBallGo_BGM.mp3",
    PinBallGo_EFFECT_SPRING_MP3                 = RES_SOUND_PATH.."PinBallGo_spring.mp3", --弹簧发射
    PinBallGo_EFFECT_QIEHUAN_MP3                = RES_SOUND_PATH.."PinBallGo_qiehuan.mp3", --切换到付费版 大旋风
    PinBallGo_EFFECT_RewardLvUp_MP3             = RES_SOUND_PATH.."PinBallGo_rewardLvUp.mp3", --奖励升级
    PinBallGo_EFFECT_CrashReward_MP3            = RES_SOUND_PATH.."PinBallGo_crashReward.mp3", --碰撞区中奖
    PinBallGo_EFFECT_DoorRise_MP3               = RES_SOUND_PATH.."PinBallGo_doorRise.mp3", --门升起
    PinBallGo_EFFECT_HitNomalReard_MP3          = RES_SOUND_PATH.."PinBallGo_hitNomalReward.mp3", --击中普通奖励
    PinBallGo_EFFECT_HitSpecialReard_MP3        = RES_SOUND_PATH.."PinBallGo_hitSpecialReward.mp3", --击高倍奖励
    PinBallGo_EFFECT_BallReset_MP3              = RES_SOUND_PATH.."PinBallGo_ballReset.mp3", --小球出现
    PinBallGo_EFFECT_HitCrash_MP3               = RES_SOUND_PATH.."PinBallGo_hitCrash.mp3", --击中中间小球奖
    PinBallGo_EFFECT_HitCrash_Collect_MP3       = RES_SOUND_PATH.."PinBallGo_hitCrashCollected.mp3", --击中中间小球奖 已领取
    PinBallGo_EFFECT_FlyReward_MP3              = RES_SOUND_PATH.."PinBallGo_flyReward.mp3", --飞奖励
    PinBallGo_EFFECT_ShowReward_MP3             = RES_SOUND_PATH.."PinBallGo_showReward.mp3", --结算弹板
    
    
}

return PinBallGoConfig
