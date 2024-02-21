
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelWickedBlazeConfig = class("LevelWickedBlazeConfig", LevelConfigData)

function LevelWickedBlazeConfig:ctor()
    LevelWickedBlazeConfig.super.ctor(self)
    self.m_levelName = "WickedBlaze" --关卡名称
    self.m_freespinRowNum = 6 --freespin下行数
    self.m_freespinReelRunDatas = {16;19;22;25;28}-- freespin下滚动参数
    self.m_fireBallReelWartTime = 2 --小恶魔发射火球轮 轮盘延迟停止时间
    self.m_startFireBallFrame = 40--小恶魔施法动作多少帧时开始飞火球
    self.m_fireBallIntervalTime = 0.1--小恶魔发射火球时间间隔
    self.m_fireBallFlyTime = 0.3--火球飞行时间
    self.m_baozhaFrameScatter = 1--火球爆炸特效多少帧时创建scatter图标
    self.m_startShowWheelFrame = 23 --小恶魔施法动作多少帧时开始出转盘界面

    self.m_bigWildActionframeTime = 30/30 --一列大wild出现的动画时长
    self.m_freespinBigWildActionframeTime = 60/30 --freespin下 一列大wild出现的动画时长

    self.m_showWheelViewDelayTime = 2.5--延迟多长时间出轮盘界面(等scatter动画播完的时间)
    self.m_freespinMoreSymbolActionFlyTime = 15/30 --freespinmore图标动画开始多长时间后飞收集次数粒子
    self.m_showFreespinViewDelayTime = 0.5--延迟多长时间出freespin界面

    self.m_bonusActionToCollectTime = 5/30--bonus图标开始播动画多久后飞收集粒子
    self.m_collectParticleFlyTime = 0.2--收集粒子飞行的时间
    self.m_freespinBottomRowCollectParticleFlyTime = 0.3--freespin下 下三行收集粒子飞行的时间

    self.m_collectNodeFirecrackerNum = 3--一个收集点能收集的最大炮仗数

    self.m_reelChangeWaitTime = 5/30--等待多长时间将盘面切换（freespin与normal之间切换）
end


return  LevelWickedBlazeConfig