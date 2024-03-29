-- OutsideCave活动 配置

GD.OutsideCaveConfig = {}

OutsideCaveConfig.RewardType = {
    Item = "ITEM",
    Coin = "COIN",
    Forward = "FORWARD",
}


ViewEventType.NOTIFY_OUTSIDECAVE_CHAPTER_COMPLETED = "NOTIFY_OUTSIDECAVE_CHAPTER_COMPLETED" -- 章节主界面开始完成逻辑
ViewEventType.NOTIFY_OUTSIDECAVE_CHAPTER_FORWARD = "NOTIFY_OUTSIDECAVE_CHAPTER_FORWARD" -- 台机地图前进

ViewEventType.NOTIFY_OUTSIDECAVE_LOBBY_SHOW_VISIBLED = "NOTIFY_OUTSIDECAVE_LOBBY_SHOW_VISIBLED" -- 主界面隐藏

-- 转盘spin
ViewEventType.NOTIFY_OUTSIDECAVE_WHEEL_SPIN = "NOTIFY_OUTSIDECAVE_WHEEL_SPIN" 
-- 关卡spian 提升上限
ViewEventType.NOTIFY_OUTSIDECAVE_GEMSUPLIMIT =  "NOTIFY_OUTSIDECAVE_GEMSUPLIMIT" 
---咋龙蛋
ViewEventType.NOTIFY_EGGS_PLAY = "NOTIFY_EGGS_PLAY" -- 点击
ViewEventType.NOTIFY_EGGS_CLICK = "NOTIFY_EGGS_CLICK" -- 砸开
ViewEventType.NOTIFY_EGGS_COLLECT = "NOTIFY_EGGS_COLLECT" -- 领取完奖励
ViewEventType.NOTIFY_EGGS_CHANGE = "NOTIFY_EGGS_CHANGE" -- 专场
ViewEventType.NOTIFY_EGGS_FLY = "NOTIFY_EGGS_FLY" -- 飞动画
ViewEventType.NOTIFY_EGGS_BIG = "NOTIFY_EGGS_BIG" -- 大奖
ViewEventType.NOTIFY_EGGS_BIGR = "NOTIFY_EGGS_BIGR" -- 大奖

------------------促销
--
ViewEventType.NOTIFY_OUTSIDECAVE_PLAYBUFF = "NOTIFY_OUTSIDECAVE_PLAYBUFF"--buff动画完成
ViewEventType.NOTIFY_OUTSIDECAVE_PLAYAUTO = "NOTIFY_OUTSIDECAVE_PLAYAUTO"--解除连续
ViewEventType.NOTIFY_PROMOTION_OUTSIDECAVE_GO_SHOP = "NOTIFY_PROMOTION_OUTSIDECAVE_GO_SHOP"
ViewEventType.NOTIFY_PROMOTION_OUTSIDECAVE_CLOSE = "NOTIFY_PROMOTION_OUTSIDECAVE_CLOSE" --促销购买后关闭
ViewEventType.NOTIFY_OUTSIDECAVE_COINSBUFF_TIMEOUT = "NOTIFY_OUTSIDECAVE_COINSBUFF_TIMEOUT" -- 双倍金币buff到期
--老虎机
ViewEventType.NOTIFY_OCSLOT_START = "NOTIFY_OCSLOT_START" -- 开始旋转
ViewEventType.NOTIFY_OCSLOT_QUICKSTOP = "NOTIFY_OCSLOT_QUICKSTOP" -- 快停
ViewEventType.NOTIFY_OCSLOT_SPINRESULT = "NOTIFY_OCSLOT_SPINRESULT" -- spin结果
ViewEventType.NOTIFY_OCSLOT_SPINOVER = "NOTIFY_OCSLOT_SPINOVER" -- 本次spin完全结束
ViewEventType.NOTIFY_OUTSIDECAVE_SLOT_SPIN_MASK = "NOTIFY_OUTSIDECAVE_SLOT_SPIN_MASK" -- 老虎机流程中屏蔽界面其他位置点击

-- 转盘获得砸蛋次数后要刷新数据，区分通过步数增加的砸蛋次数
ViewEventType.NOTIFY_OUTSIDECAVE_WHEEL_GET_EGG = "NOTIFY_OUTSIDECAVE_WHEEL_GET_EGG"

---排行榜
 

--活动入口节点
ViewEventType.NOTIFY_OCSLOT_UPDATE_REDPOINT = "NOTIFY_OCSLOT_UPDATE_REDPOINT" -- 更新红点
ViewEventType.NOTIFY_OCSLOT_UPDATE_MAX = "NOTIFY_OCSLOT_UPDATE_MAX" -- 更新进度条

