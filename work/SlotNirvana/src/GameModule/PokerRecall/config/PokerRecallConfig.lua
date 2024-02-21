
--[[
Author: dhs
Date: 2022-02-26 13:38:32
LastEditTime: 2022-02-26 13:59:14
LastEditors: your name
Description: PokerRecallConfig
FilePath: /SlotNirvana/src/GameModule/PokerRecall/config/PokerRecallConfig.lua
--]]

local PokerRecallConfig = {}

PokerRecallConfig.Rewards = {
    [1] = {["name"] = "Straight Flush", ["value"] = 900,["reward"] = "StraightFlush"},
    [2] = {["name"] = "4 Of A Kind", ["value"] = 800,["reward"] = "FourOfAKind"},
    [3] = {["name"] = "Full House", ["value"] = 700,["reward"] = "FullHouse"},
    [4] = {["name"] = "Flush", ["value"] = 600,["reward"] = "Flush"},
    [5] = {["name"] = "Straight", ["value"] = 500,["reward"] = "Straight"},
    [6] = {["name"] = "3 Of A Kind", ["value"] = 400,["reward"] = "ThreeOfAKind"},
    [7] = {["name"] = "2 Pairs", ["value"] = 300,["reward"] = "TwoPair"},
    [8] = {["name"] = "1 Pair", ["value"] = 200,["reward"] = "OnePair"},
    [9] = {["name"] = "High Card", ["value"] = 100,["reward"] = "HighCard"}
}

PokerRecallConfig.Sounds = {
    PORKER_RECALL_OPENING = {path = "Activity/PokerRecall/sounds/poker_recall_opening.mp3",time = 2},
    PORKER_RECALL_DEAL = {path = "Activity/PokerRecall/sounds/poker_recall_deal.mp3",time = 1},
    PORKER_RECALL_REWARD_TIPS = {path = "Activity/PokerRecall/sounds/poker_recall_reward_tips.mp3",time = 2},
    PORKER_RECALL_SHUFFIE = {path = "Activity/PokerRecall/sounds/poker_recall_shuffle.mp3",time = 2},
    PORKER_RECALL_WIN_TIPS = {path = "Activity/PokerRecall/sounds/poker_recall_win_tips.mp3",time = 4},
    PORKER_RECALL_PAY_TIPS = {path = "Activity/PokerRecall/sounds/poker_recall_pay_tips.mp3",time = 4},
    PORKER_RECALL_BGM = {path = "Activity/PokerRecall/sounds/poker_recall_bgm.mp3",time = 4},
}

--翻牌后需要刷新翻牌次数，需要控制玩家的点击
ViewEventType.NOTIFY_POKER_RECALL_CARD_CLICK = "NOTIFY_POKER_RECALL_CARD_CLICK"
--翻牌失败
ViewEventType.NOTIFY_POKER_RECALL_CARD_CLICK_FAILED = "NOTIFY_POKER_RECALL_CARD_CLICK_FAILED"
--监听玩家点击收集奖励
ViewEventType.NOTIFY_POKER_RECALL_COLLECT_REWARD = "NOTIFY_POKER_RECALL_COLLECT_REWARD"
--监听玩家点击收集奖励失败
ViewEventType.NOTIFY_POKER_RECALL_COLLECT_REWARD_FAILED = "NOTIFY_POKER_RECALL_COLLECT_REWARD_FAILED"
--玩家点击付费按钮
ViewEventType.NOTIFY_POKER_RECALL_PAY_CLICK = "NOTIFY_POKER_RECALL_PAY_CLICK"
--玩家中奖
ViewEventType.NOTIFY_POKER_RECALL_PAY_TABLE = "NOTIFY_POKER_RECALL_PAY_TABLE"
--关闭PokerRecall界面
ViewEventType.NOTIFY_POKER_RECALL_CLOSE_VIEW = "NOTIFY_POKER_RECALL_CLOSE_VIEW"
--更新buy界面付费按钮
ViewEventType.NOTIFY_POKER_RECALL_CHANGE_BUY_STATUS = "NOTIFY_POKER_RECALL_CHANGE_BUY_STATUS"
--刷新邮件
ViewEventType.NOTIFE_POKER_RECALL_REFRESH_INBOX = "NOTIFE_POKER_RECALL_REFRESH_INBOX"
--关闭新手引导
ViewEventType.NOTIFY_POKER_RECALL_CLOSE_GUIDELAYER = "NOTIFY_POKER_RECALL_CLOSE_GUIDELAYER"
--PayTable展示动效
ViewEventType.NOTIFY_POKER_RECALL_PAYTABLE_RUNACTION = "NOTIFY_POKER_RECALL_PAYTABLE_RUNACTION"
--PayTable隐藏动效
ViewEventType.NOTIFY_POKER_RECALL_PAYTABLE_STOPACTION = "NOTIFY_POKER_RECALL_PAYTABLE_STOPACTION"
--关闭当前中奖特效
ViewEventType.NOTIFY_POKER_RECALL_STOP_REWARD_ACTION = "NOTIFY_POKER_RECALL_STOP_REWARD_ACTION"

--二次弹板玩家取消或者关闭界面
ViewEventType.NOTIFY_POKER_RECALL_CLOSE_REWARDTIPS_LAYER = "NOTIFY_POKER_RECALL_CLOSE_REWARDTIPS_LAYER"

return PokerRecallConfig
