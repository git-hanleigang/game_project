--[[
Author: cxc
Date: 2021-07-26 14:50:28
LastEditTime: 2021-07-26 17:43:58
LastEditors: Please set LastEditors
Description: 公会宝箱
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanBoxReward.lua
--]]
local ClanBoxReward = class("ClanBoxReward", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanBoxReward:initUI(_idx)
	local csbName = "Club/csd/Main/ClubSysMain_baoxiang.csb"
    self:createCsbNode(csbName)

    self.m_idx = _idx or 1

	for i=1, 6 do
		local spBox = self:findChild("gonghui_baoxiang" .. i)
		if spBox then
			spBox:setVisible(i == self.m_idx)
		end
	end
	self:runCsbAction("idle1")
	self:setName("ClanBoxReward")
end

function ClanBoxReward:checkPlayAni(_bAni)
	if _bAni then
		self:playAni()
		return
	end

	self:stopAni()
end

function ClanBoxReward:playAni()
	self:runCsbAction("idle2", false, function()
		performWithDelay(self, handler(self, self.playAni), 3)
	end, 60)

	local curShowType = ClanManager:getCurSystemShowType() 
	if curShowType == ClanConfig.systemEnum.MAIN then
		-- cxc 2021年09月06日16:04:35 策划说不播放音效了
		-- gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.NEXT_BOX_SHAKE)
	end
end

function ClanBoxReward:stopAni()
	self:stopAllActions()
	self:runCsbAction("idle1")
end

return ClanBoxReward