--浇花
local FlowerConfig = {}

FlowerConfig.EVENT_NAME = {
	ITEM_CLICK_GIFT = "ITEM_CLICK_GIFT",
	ITEM_CLICK_WATER = "ITEM_CLICK_WATER",
	INIT_PAY_INFO = "INIT_PAY_INFO", --初始化支付
	INIT_REWARD_INFO = "INIT_REWARD_INFO", --初始化奖励
	NOTIFY_FLOWER_BUY_SUCCESS = "NOTIFY_FLOWER_BUY_SUCCESS", --购买
	NOTIFY_FLOWER_WATER = "NOTIFY_FLOWER_WATER", --浇水
	NOTIFY_REWARD_BIG = "NOTIFY_REWARD_BIG", --大奖
	NOTIFY_FLOWER_GUIDE = "NOTIFY_FLOWER_GUIDE", --引导
	NOTIFY_FLOWER_FINSHGUIDE = "NOTIFY_FLOWER_FINSHGUIDE", --引导完成
	ITEM_CLICK_SPOT = "ITEM_CLICK_SPOT",
	ITEM_END = "ITEM_END",
	NOTIFY_UNWATER_GUIDE = "NOTIFY_UNWATER_GUIDE",
	NOTIFY_WATER_GUIDE = "NOTIFY_WATER_GUIDE",
}

FlowerConfig.SPINE_PATH = {
	SILVER = "Activity/spine/flower2",
	GOLD = "Activity/spine/flower1"
}

FlowerConfig.SOUND = {
	CLICK = "Activity/audio/Flower_music1.mp3",
	HAPPY = "Activity/audio/Flower_music2.mp3",
	HAPPY1 = "Activity/audio/Flower_music3.mp3",
	WATER = "Activity/audio/Flower_music4.mp3",
	PAY = "Activity/audio/Flower_music5.mp3",
	PAY1 = "Activity/audio/Flower_music6.mp3",
	PRTICL = "Activity/audio/Flower_music7.mp3",
	REWARD = "Activity/audio/Flower_music8.mp3",
	REWARD1 = "Activity/audio/Flower_music9.mp3",
}

return FlowerConfig