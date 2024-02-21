--[[
Author: cxc
Date: 2021-06-10 20:06:32
LastEditTime: 2021-07-07 15:00:11
LastEditors: Please set LastEditors
Description: rippledash活动
FilePath: /SlotNirvana/src/activities/Activity_RippleDash/model/RippleDashData.lua
--]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local RippleDashData = class("RippleDashData",BaseActivityData)
local RippleDashRewardData = require("activities.Activity_RippleDash.model.RippleDashRewardData")

local MAX_PHASE = 9 -- 一共9档

function RippleDashData:ctor()
    RippleDashData.super.ctor(self)
	
	self.m_curPhase = 0
	self.m_goodsKeyId = ""
	self.m_price = 0
	self.m_bPurchase = false
	self.m_normalRewardList = {}
	self.m_payRewardList = {}
	self.m_displayRewardList = {}

	self.m_init = false
end

function RippleDashData:parseData(_data)
    RippleDashData.super.parseData(self,_data)

	-- message RippleDash {
	-- optional int32 expire = 1; //剩余秒数
	-- optional int64 expireAt = 2; //过期时间
	-- optional string activityId = 3; //活动id
	-- optional int32 times = 4;//完成次数
	-- optional string keyId = 5; //付费标识
	-- optional string price = 6; //价格
	-- optional bool unlocked = 7;//付费奖励解锁标识
	-- repeated RippleDashReward free = 8;//免费奖励
	-- repeated RippleDashReward pay = 9;//Pass等级奖励
	-- repeated ShopItem displayRewards = 10;//付费版物品
	-- }
	self.m_curPhase = _data.times or 0
	self.m_bPurchase = _data.unlocked
	self.m_normalRewardList = self:parseRewardList(_data.free)
	self.m_payRewardList = self:parseRewardList(_data.pay)


	if not self.m_init then
		self.m_goodsKeyId = _data.keyId or ""
		self.m_price = tonumber(_data.price) or 0

		for i = #self.m_payRewardList, 1, -1 do
			local rewardData = self.m_payRewardList[i]
			local shopItemList = rewardData:getItemList()
			for _, shopItem in ipairs(shopItemList) do
				table.insert(self.m_displayRewardList, shopItem)
			end
		end

		-- for i = 1, #(_data.displayRewards or {}) do
		-- 	local itemData = _data.displayRewards[i]
		-- 	local rewardItem = ShopItem:create()
		-- 	rewardItem:parseData(itemData)
		-- 	rewardItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
		-- 	table.insert(self.m_displayRewardList, rewardItem)
		-- end
		self.m_init = true
	end

end

-- 解析 奖励
function RippleDashData:parseRewardList(_rewardDataList)
	if not _rewardDataList or #_rewardDataList <= 0 then
		return {}
	end

	local list = {}
	for i,v in ipairs(_rewardDataList) do
		local data = RippleDashRewardData:create()
		data:parseData(v)

		table.insert(list, data)
	end

	return list
end

function RippleDashData:getCurPhase()
	return self.m_curPhase
end
function RippleDashData:getProgress()
	return math.min(self.m_curPhase / MAX_PHASE, 1) 
end
function RippleDashData:checkCompleteAllTask()
	return self.m_curPhase >= 9
end

function RippleDashData:getGoodsKeyId()
	return self.m_goodsKeyId
end

function RippleDashData:getPrice()
	return self.m_price
end

function RippleDashData:checkHadPurchase()
	return self.m_bPurchase
end

function RippleDashData:getNormalRewardList()
	return self.m_normalRewardList
end

function RippleDashData:getPayRewardList()
	return self.m_payRewardList
end

function RippleDashData:getDisplayRewardList()
	return self.m_displayRewardList
end

return RippleDashData