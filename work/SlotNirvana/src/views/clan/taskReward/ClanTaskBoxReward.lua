--[[
Author: cxc
Date: 2021-07-27 19:43:53
LastEditTime: 2021-07-27 19:43:54
LastEditors: your name
Description: 结算的 任务宝箱
FilePath: /SlotNirvana/src/views/clan/taskReward/ClanTaskBoxReward.lua
--]]
local ClanTaskBoxReward = class("ClanTaskBoxReward", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanTaskBoxReward:initUI(_idx, _bDoneType)
    local csbName = "Club/csd/Rewards/ClubReward_box.csb"
    self:createCsbNode(csbName)

    self.m_idx = _idx or 1

	if _bDoneType then
		-- 完成 增加一个 宝箱升级过程
		for i=1, 6 do
			local nodeBox = self:findChild("Box_" .. i)
			if nodeBox then
				nodeBox:setVisible(i == 1)
			end 
		end
	else
		for i=1, 6 do
			local nodeBox = self:findChild("Box_" .. i)
			if nodeBox then
				nodeBox:setVisible(i == self.m_idx)
			end
		end
	end

	self:runCsbAction("idle", true)
end

-- 宝箱钥匙插入动画
function ClanTaskBoxReward:playKeyAni(_cb)
	-- 完成 增加一个 宝箱升级过程
	self:runCsbAction("UP", false, function()
		self:runCsbAction("UPidle", false, function()
			self:runCsbAction("open", false, function()
				if _cb then
					_cb()
				end
				self:runCsbAction("idle1", true)
			end, 60)
		end, 60)
	end, 60)
	performWithDelay(self, function()
		for i=1, 6 do
			local nodeBox = self:findChild("Box_" .. i)
			if nodeBox then
				nodeBox:setVisible(i == self.m_idx)
			end
		end
	end, 1)
end

-- 宝箱开启动画
function ClanTaskBoxReward:playUnlockAni(_cb)
	self:runCsbAction("open1", false, _cb, 60)
end

-- 宝箱消失动画
function ClanTaskBoxReward:playHideAni(_cb)
	self:runCsbAction("dark", false, _cb, 60)
end

return ClanTaskBoxReward