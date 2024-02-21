--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-30 14:57:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-30 14:57:20
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/config/OperateGuidePopupConfig.lua
Description: 运营引导 弹板点位 cfg--
--]]
local OperateGuidePopupConfig = {}

-- 点位类型
OperateGuidePopupConfig.siteType = {
    SpecailSpinWin = "SpecailSpinWin",  -- 特殊spin大赢（Legendary Win及Grand Jackpot） 指定 cd 次数 不用SpinWin的 SpinWin弹出3次之后才会弹出，当次登录Spin超过100次，在关卡中Spin中第一次触发LegendaryWin或Grand，当次SPIN结束之后弹出
    SpinWin = "SpinWin",  -- spin大赢
    Card = "Card",  -- 完成一轮卡册并领奖
    Quest = "Quest", -- 完成一个章节Quest并领奖
    Bankruptcy = "Bankruptcy", -- 破产且未付款之后
    Levelup = "Levelup", -- 升级之后
    OldActivityMission = "OldActivityMission", -- 完成老版大活动任务第三个任务
    NewActivityMission = "NewActivityMission", -- 完成新版大活动任务，领取最终奖励之后
    Friendreward = "Friendreward", -- 领取邮箱好友奖励
    Cashbonus = "Cashbonus", -- 领取Cash Bonus
    CashMoneyWin = "CashMoneyWin", -- 20级以上，在Cash Money游戏游玩过程中，在免费游戏中中1000点的钞票或在付费游戏中中10000点钞票，玩家游戏结算完成回到大厅之后弹出
    BlastGrandWin = "BlastGrandWin", --	20级以上，在阿凡达Blast中，中Grand之后，结算完成之后弹出
    PipeGrandWin = "PipeGrandWin", -- 20级以上，在接水管中，中Grand之后，结算完成之后弹出
    NadoMachineWin = "NadoMachineWin", -- 20级以上，在NadoMachine中，获得Epic Nado Prize后，所有结算全部完成之后，弹出
    JillionJackpotWin = "JillionJackpotWin", -- 公共Jackpot活动中，中Super Jackpot，结算完成所有金币，弹出
    DIYWin = "DIYWin", --	DIY Feature中，玩家结算玩法，获得400倍以上Win，在结算玩金币之后，弹出
    MINZWin = "MINZWin", --	MINZ中，玩家结算玩法，获得400倍以上Win，在结算玩金币之后，弹出
    DuckShotWin = "DuckShotWin", --	20级以上，打鸭子游戏中，击中转盘中Grand，结算完金币和付费之后，弹出
    DartsWin = "DartsWin", --	20级以上，飞镖小游戏中，获得Grand，结算完金币和付费之后，弹出
    SuperSpinWin = "SuperSpinWin", --	50刀档位及以上，购买SuperSpin，中20倍的倍数，在所有弹版弹出之后，弹出
    LegendaryWinV2 = "LegendaryWinV2", -- 触发的时候只有玩家是已评价过的情况才会进入到这个点位，触发就计入点位CD 触发后直接弹出平台评分弹版
    MergeActOverChapter = "MergeActOverChapter",  -- 每一个赛季，合成完成第1章和第2章，领取奖励，回到关卡或大厅的时候弹出  点位CD48小时	引导评论>弹窗>FB
    LevelDash = "LevelDash", -- 完成LevelDash，触发Pearls link，当场游玩/在关卡内游玩，获得其完成Leveldash最后一次Bet，10倍以上奖励（包括付费/不付费），所有结算之后，回到关卡后弹出
    LevelRoadGameWin = "LevelRoadGameWin", -- LevelRoad小游戏，当场游玩/在关卡内游玩，累积获得200倍以上奖励（包括付费之后的情况），结算完成之后。回到关卡或大厅的时候弹出
    PassCollect = "PassCollect", --当天已经完成全部每日任务（Daily Mission），Pass点击Collect All并一次性领取超过10个奖励，回到关卡或大厅后弹出
    GrandWin = "GrandWin", -- 20级以上，在关卡中Grand的档次Spin结算之后弹出，触发优先级高于SpinWin、SpecailWin和SpecailWinV2，触发的时候不会触发前面几个点。单独弹板，弹板CD为0，点位CD24小时。触发的时候重置SpinWin和SpecailWin的点位CD。另外，没有Grand分享或没有Grand的关卡不弹。
}

-- 引导弹板类型
OperateGuidePopupConfig.popupType = {
    Score = "Score",  -- RateUs评分
    FB = "FB",  -- 绑定FB
    Mail = "Mail", -- 绑定邮箱
    OpenPush = "OpenPush", -- 推送开关
}

return OperateGuidePopupConfig