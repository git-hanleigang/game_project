--砸龙蛋数据
local BaseGameModel = require("GameBase.BaseGameModel")
local EggsData = class("EggsData",BaseGameModel)
local ShopItem = require "data.baseDatas.ShopItem"

local EggRewardInfo = import(".EggRewardInfo")
local EggPackageInfo = import(".EggPackageInfo")

-- message OutsideGaveHammerGame {
--     optional int32 hammers = 1; //锤子道具
--     optional int32 level = 2; //等级
--     repeated int32 panels = 3; //南瓜位置信息，0 是没有 1 绿色 2 粉色 3 蓝色 4 红色
--     repeated OutsideGaveHammerRewardPool rewardPool = 4; //奖励池
--     repeated OutsideGaveHammerRewardPackage rewardPackage = 5; //未领取的奖励
-- }
-- message OutsideGaveHammerRewardPool {
--     optional int32 order = 1; //顺序
--     optional string type = 2; //类型 ITEM COIN
--     optional OutsideGaveReward reward = 3; //奖励
--     optional bool grand = 4; //是否大奖
--     optional bool fetch = 5; //领取标识
-- }
-- message OutsideGaveReward {
--     optional int64 coins = 1; //金币数
--     optional int64 gems = 2; //钻石数
--     repeated ShopItem items = 3; //物品
-- }

function EggsData:ctor()
    EggsData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CaveEggs)
end

function EggsData:parseData(data)
	self.m_hammers = data.hammers 
	self.m_level = data.level
	if data.panels and #data.panels > 0 then
		self:parsePanls(data.panels)
	end
	if data.rewardPool and #data.rewardPool > 0 then
		self:parseRewards(data.rewardPool)
	end
	self.m_package = {}
	if data.rewardPackage and #data.rewardPackage > 0 then
		self:parsePackage(data.rewardPackage)
	end
end
-- 南瓜位置信息
function EggsData:parsePanls(_data)
	self.m_panls = {}
	for i,v in ipairs(_data) do
		table.insert(self.m_panls,v)
	end
end

-- 奖励池
function EggsData:parseRewards(_data)
    self.m_reward = {}
    for i, v in ipairs(_data) do
        local item = EggRewardInfo:create()
        item:parseData(v)
        table.insert(self.m_reward, item)
    end
end

-- 未领取的奖励
function EggsData:parsePackage(_data)
    self.m_package = {}
    for i, v in ipairs(_data) do
        local item = EggPackageInfo:create()
        item:parseData(v)
        table.insert(self.m_package, item)
    end
end

--第几章节
function EggsData:getLevel()
	return self.m_level or 1
end

--剩余道具数
function EggsData:getHammers()
	return self.m_hammers or 0
end

--章节数据
function EggsData:getPanls()
	return self.m_panls or {}
end

--章节奖励数据
function EggsData:getPanlReward()
	return self.m_reward or {}
end

function EggsData:getPackage()
	if not self.m_package then
		self.m_package = {}
	end
	return self.m_package
end

function EggsData:getBoxData()
	local data = clone(self.m_package)
	local enddata = {}
	for i,v in ipairs(data) do
		if #enddata > 0 then
			local pt = nil
			local pl = 0
			for k=1,#enddata do
				local item = enddata[k]
				if v.p_type == item.p_type then
					if v.p_type == "COIN" then
						item.p_coins = toLongNumber(item.p_coins or 0) + toLongNumber(v.p_coins or 0)
						pl = 1
					else
						if v.p_items[1].p_id == item.p_items[1].p_id then
							if v.p_items[1].p_type == "Buff" then
								item.p_items[1].p_buffInfo.buffDuration = item.p_items[1].p_buffInfo.buffDuration + v.p_items[1].p_buffInfo.buffDuration
								item.p_items[1].p_buffInfo.buffExpire = item.p_items[1].p_buffInfo.buffExpire + v.p_items[1].p_buffInfo.buffExpire
							else
								item.p_items[1].p_num = tonumber(item.p_items[1].p_num) + tonumber(v.p_items[1].p_num)
							end
							pl = 1
						else
							pt = v
						end
					end
				else
					pt = v
				end
			end
			if pt and pl == 0 then
				table.insert(enddata,pt)
			end
		else
			table.insert(enddata,v)
		end
	end
	return enddata
end

return EggsData
