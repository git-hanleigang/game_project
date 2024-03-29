--[[
]]
_G.JewelManiaCfg = {}

JewelManiaCfg.InnerW = 5000

JewelManiaCfg.GuideJewelType = 2 -- 蓝色长方形宝石

-- 网络协议定义
NetType.JewelMania = "JewelMania"
NetLuaModule.JewelMania = "activities.Activity_JewelMania.net.JewelManiaNet"

-- 消息事件定义
-- 砸石块成功
ViewEventType.NOTIFY_BREAK_STONE_SUCCESS = "NOTIFY_BREAK_STONE_SUCCESS" 
-- 锤子不足
ViewEventType.NOTIFY_JMC_NOT_ENOUGH_HAMMER = "NOTIFY_JMC_NOT_ENOUGH_HAMMER"
-- 敲砖 点击砖块上的按钮
ViewEventType.NOTIFY_JMC_BREAKSLATE = "NOTIFY_JMC_BREAKSLATE" 
-- 敲砖 点击砖块上的按钮特殊章节
ViewEventType.NOTIFY_JMC_BREAKSLATE_SPECIAL = "NOTIFY_JMC_BREAKSLATE_SPECIAL" 
-- 敲砖 点击砖块上的按钮  消息传回来成功回调
ViewEventType.NOTIFY_JMC_PLAYSUCC = "NOTIFY_JMC_PLAYSUCC" 
-- 敲砖 一键全碎  消息传回来成功回调
ViewEventType.NOTIFY_JMC_PLAYALL_SUCC = "NOTIFY_JMC_PLAYALL_SUCC" 
-- 进入章节
ViewEventType.NOTIFY_JMC_ENTER_CHAPTER = "NOTIFY_JMC_ENTER_CHAPTER" 

ViewEventType.NOTIFY_JEWELMANIA_GUIDE_OVER = "NOTIFY_JEWELMANIA_GUIDE_OVER"
-- 章节奖励付费
ViewEventType.NOTIFY_JEWELMANIA_PAY_COMPLETE = "NOTIFY_JEWELMANIA_PAY_COMPLETE" 
-- 章节完成
ViewEventType.NOTIFY_JEWELMANIA_CHAPTER_COMPLETE = "NOTIFY_JEWELMANIA_CHAPTER_COMPLETE" 
-- 章节引导的小手
ViewEventType.NOTIFY_JEWELMANIA_CHAPTER_GUIDE_FINGER = "NOTIFY_JEWELMANIA_CHAPTER_GUIDE_FINGER" 