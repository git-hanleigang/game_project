--[[
Author: cxc
Date: 2022-04-15 15:37:31
LastEditTime: 2022-04-15 15:37:31
LastEditors: cxc
Description: 头像框 小游戏cell 数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameGameCellData.lua
--]]
local AvatarFrameGameCellData = class("AvatarFrameGameCellData")
local ShopItem = util_require("data.baseDatas.ShopItem")

-- message AvatarFrameGameCell {
--     optional int32 seq = 1; //序号
--     optional string rewardType = 2; //奖励类型 Item Coins
--     repeated ShopItem items = 3; //奖励物品
--     optional int64 coins = 4; //奖励金币
--     optional bool bigReward = 5;//是否时大奖
--   }
function AvatarFrameGameCellData:ctor()
    self.m_seq = 0
    self.m_rewardType = ""
    self.m_coins = 0
    self.m_rewardList = {}
    self.m_bigReward = false
end

function AvatarFrameGameCellData:parseData(_data)
    if not _data then
        return
    end

    self.m_seq = _data.seq or 0
    self.m_rewardType = _data.rewardType or ""
    self.m_coins = tonumber(_data.coins) or 0
    self.m_bigReward = _data.bigReward or false
    self:parseRewardData(_data.items or {})
end

function AvatarFrameGameCellData:parseRewardData(_items)
    self.m_rewardList = {}
    if not _items then
        return
    end

    for i = 1, #_items do
		local itemData = _items[i]
		local rewardItem = ShopItem:create()
		rewardItem:parseData(itemData)
		table.insert(self.m_rewardList, rewardItem)
	end
end


-- get 当前序号
function AvatarFrameGameCellData:getSeq()
    return self.m_seq
end
-- get 奖励类型 Item Coins
function AvatarFrameGameCellData:getRewardType()
    return self.m_rewardType
end
-- get 奖励金币
function AvatarFrameGameCellData:getCoins()
    return self.m_coins
end
-- get 奖励物品
function AvatarFrameGameCellData:getRewardList()
    return self.m_rewardList
end

function AvatarFrameGameCellData:isBigReward()
    return self.m_bigReward
end

return AvatarFrameGameCellData