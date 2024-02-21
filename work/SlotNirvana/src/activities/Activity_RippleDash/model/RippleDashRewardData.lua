--[[
Author: cxc
Date: 2021-06-15 17:13:33
LastEditTime: 2021-07-03 15:31:34
LastEditors: Please set LastEditors
Description: rippledash活动 奖励数据
FilePath: /SlotNirvana/src/activities/Activity_RippleDash/model/RippleDashRewardData.lua
--]]

-- message RippleDashReward {
	-- optional int32 times = 1;//完成次数
	-- optional bool collected = 2;//领取标识
	-- repeated ShopItem items = 3;//物品奖励
	-- optional int64 coins = 4;      //金币奖励
	-- optional string rewardValue = 5; //金币价值
	-- optional string description = 6; //描述
	-- optional string bHasSpecialItems = 7; //奖励类型
	-- optional bool hasSpecialItems = 7;//特殊卡册奖励标识
-- }

local ShopItem = util_require("data.baseDatas.ShopItem")
local RippleDashRewardData = class("RippleDashRewardData")

function RippleDashRewardData:ctor()
    self.m_phase = 0
	self.m_bCollected = false
    self.m_rewardListNoMark = {}
    self.m_rewardListMark = {}
	self.m_coins = 0
	self.m_rewardValue = 0
	self.m_desc = ""
	self.m_bHasSpecialItems = false
end

function RippleDashRewardData:parseData(_data)
    if not _data then
        return
    end

    self.m_phase = _data.times or 0
	self.m_bCollected = _data.collected 
	self.m_coins = tonumber(_data.coins) or 0
	self.m_rewardValue = tonumber(_data.rewardValue) or 0
	self.m_desc = _data.description or ""
	self.m_bHasSpecialItems = _data.hasSpecialItems

	for i = 1, #(_data.items or {}) do
		local itemData = _data.items[i]
		local rewardItem = ShopItem:create()
		rewardItem:parseData(itemData)
		local rewardItemMark = clone(rewardItem) --mark的随配置走
		if rewardItem.p_icon then
			local newIcon = gLobalItemManager:getOldToNewIcon(rewardItem.p_icon)
			if not string.find(newIcon,"Card_Star") then
				rewardItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
			end
		end 
		table.insert(self.m_rewardListNoMark, rewardItem)
		table.insert(self.m_rewardListMark, rewardItemMark)
	end

	-- 金币放到 道具后边
	if self.m_rewardValue > 0 then
		local strCoins = "$"..self.m_rewardValue
        local coinItemData = gLobalItemManager:createLocalItemData("ChallengepPass_Coins", strCoins)
		local coinItemDataMark = clone(coinItemData)
		
		coinItemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
		coinItemDataMark:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}}) -- 自定义的coins 类型,需要显示设置角标格式

		table.insert(self.m_rewardListNoMark, coinItemData)
		table.insert(self.m_rewardListMark, coinItemDataMark)
	end

	-- 神像
	if self.m_bHasSpecialItems then
		local rewardItem = gLobalItemManager:createLocalItemData("Card_Statue_Package", 1)
		local rewardItemMark = clone(rewardItem)
		
		rewardItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
		rewardItemMark:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_X}}) -- 自定义的coins 类型,需要显示设置角标格式
		
        table.insert(self.m_rewardListNoMark, rewardItem)
		table.insert(self.m_rewardListMark, rewardItemMark)
	end

end

function RippleDashRewardData:getPhase()
    return self.m_phase
end

function RippleDashRewardData:checkHasSpecialItems()
    return self.m_bHasSpecialItems
end

function RippleDashRewardData:checkIsCollected()
    return self.m_bCollected
end

function RippleDashRewardData:getCoins()
    return self.m_coins
end

function RippleDashRewardData:getItemList(bMark)
	if bMark then
		return self.m_rewardListMark
	end
	
    return self.m_rewardListNoMark
end

return RippleDashRewardData