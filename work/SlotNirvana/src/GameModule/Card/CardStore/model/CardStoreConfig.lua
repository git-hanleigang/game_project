-- 卡牌商店 资源配置

local CardStoreConfig = {}

CardStoreConfig.MainUI = "CardStore/csd/CardStore_mainUI.csb" -- 主界面
CardStoreConfig.npc = "CardStore/spine/pijiunv" -- 主界面 npc

CardStoreConfig.ChipTitle = "CardStore/csd/CardStore_mainUI_ticket.csb" -- 主界面 碎片总量条
CardStoreConfig.Gift = "CardStore/csd/CardStore_mainUI_logo.csb" -- 主界面 免费礼包
CardStoreConfig.GiftBubble = "CardStore/csd/CardStore_gift_bubble.csb" -- 主界面 免费礼包倒计时气泡

CardStoreConfig.ItemUI = "CardStore/csd/CardStore_mainUI_reward.csb" -- 主界面奖励道具
CardStoreConfig.TimerUI = "CardStore/csd/CardStore_mainUI_time.csb" -- 主界面刷新倒计时
CardStoreConfig.BlindUI = "CardStore/csd/CardStore_mainUI_box.csb" -- 主界面盲盒道具

CardStoreConfig.GuideUI = "CardStore/csd/CardStore_Guide_point.csb" -- 赛季结算引导界面
CardStoreConfig.ExchangeUI = "CardStore/csd/CardStore_exchange.csb" -- 奖励兑换界面
CardStoreConfig.ResetUI = "CardStore/csd/CardStore_reset.csb" -- 主界面重置倒计时
CardStoreConfig.ResetEff = "CardStore/csd/CardStore_reset_hongguang.csb" -- 主界面重置倒计时 红光特效
CardStoreConfig.ChipsLackUI = "CardStore/csd/CardStore_empty.csb" -- 碎片不足提示弹框

CardStoreConfig.RewardUI = "CardStore/csd/CardStore_reward.csb" -- 奖励界面
CardStoreConfig.BlindRewardUI = "CardStore/csd/CardStore_reward_box.csb" -- 盲盒奖励界面

-- 玩法介绍
CardStoreConfig.InfoUI = "CardStore/csd/CardStore_info.csb" -- 玩法介绍界面
CardStoreConfig.InfoItem1 = "CardStore/csd/CardStore_info1.csb" -- 玩法介绍界面1
CardStoreConfig.InfoItem2 = "CardStore/csd/CardStore_info2.csb" -- 玩法介绍界面2

-- 盲盒信息
CardStoreConfig.BlindInfoUI = "CardStore/csd/CardStore_box.csb" -- 盲盒信息界面
CardStoreConfig.BlindItem = "CardStore/csd/CardStore_boxItem.csb" -- 盲盒信息显示控件
CardStoreConfig.BlindReward = "CardStore/csd/CardStore_box_reward.csb" -- 盲盒奖励

return CardStoreConfig
