--[[
Author: cxc
Date: 2021-11-09 17:06:39
LastEditTime: 2021-11-09 17:07:14
LastEditors: your name
Description: 公会 要卡bubbleTip
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatCardBubbleTip.lua
--]]
local ClanChatCardBubbleTip = class("ClanChatCardBubbleTip", util_require("base.BaseView"))

function ClanChatCardBubbleTip:initUI()
    local csbName = "Club/csd/Chat_New/ClubWall_chips_cd.csb"
    self:createCsbNode(csbName)

	-- 触摸
	local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
    self:addChild(touch, -1)
	performWithDelay(self, function()
		if tolua.isnull(touch) then
			return
		end
		touch:move(self:convertToNodeSpaceAR(display.center))
	end, 0)
    touch:setSwallowTouches(true)
    self:addClick(touch)
	-- touch:setBackGroundColorOpacity(120)
	-- touch:setBackGroundColorType(2)
	-- touch:setBackGroundColor(cc.c3b(255,0,0))

	-- 适配
    local homeView = gLobalViewManager:getViewByExtendData("ClanHomeView")
    if homeView then
        self:setScale(homeView:getUIScalePro())
		touch:setScale(10) -- 触摸面板大点
    end    

	-- 更新tip类型UI显隐
	self:updateTipLbVisible()

	self:setVisible(false)
end

function ClanChatCardBubbleTip:initCsbNodes()
	self.m_spChipNormal = self:findChild("sp_chipscd")
	self.m_noChipNovice = self:findChild("node_chipNovice")
end

-- 更新tip类型UI显隐
function ClanChatCardBubbleTip:updateTipLbVisible()
	local bCardNovice = CardSysManager:isNovice()
	self.m_spChipNormal:setVisible(not bCardNovice)
	self.m_noChipNovice:setVisible(bCardNovice)
end

--结束监听
function ClanChatCardBubbleTip:clickEndFunc(sender)
	gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

	self:hideBubbleTip()
end

function ClanChatCardBubbleTip:showBubbleTip()
	self:setVisible(true)
	self:runCsbAction("show", false, function()
		performWithDelay(self, function()
			self:hideBubbleTip()
		end, 3)
	end, 60)
end

function ClanChatCardBubbleTip:hideBubbleTip()
	self:stopAllActions()
	self:runCsbAction("hide", false, function()
		self:setVisible(false)
	end, 60)
end

return ClanChatCardBubbleTip