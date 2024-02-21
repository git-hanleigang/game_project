--[[
Author: cxc
Date: 2021-08-11 15:35:56
LastEditTime: 2021-08-11 15:36:03
LastEditors: Please set LastEditors
Description: FAQ cell
FilePath: /SlotNirvana/src/views/clan/ClanFAQInfoCell.lua
--]]
local ClanFAQInfoCell = class("ClanFAQInfoCell", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")

local width = 920

function ClanFAQInfoCell:initUI(_idx, _info)
    ClanFAQInfoCell.super.initUI(self)
    
	self:createCsbNode("Club/csd/Faq/ClubFAQCell.csb")
	self.m_idx = _idx

	-- title
	local lbTitle = self:findChild("lb_question")
	util_AutoLine(lbTitle, _info.title or "", width, true)
	self.m_titleHeight = lbTitle:getContentSize().height

	local touch = ccui.Layout:create()
    touch:setName("btn_click")
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0, 1)
    touch:setContentSize(cc.size(width, self.m_titleHeight))
	self:addChild(touch)
    self:addClick(touch)

	-- desc
	local lbDesc = self:findChild("lb_answer")
	util_AutoLine(lbDesc, _info.desc or "", width, true)
	local descHeight = lbDesc:getContentSize().height
	self.m_lbDesc = lbDesc

	self.m_totalHeight = math.abs(lbDesc:getPositionY()) + descHeight
end

function ClanFAQInfoCell:getCurCellSize()
	if self.m_lbDesc:isVisible() then
		return cc.size(width, self.m_totalHeight)
	end

	return cc.size(width, self.m_titleHeight)
end

function ClanFAQInfoCell:clickFunc(sender)
    local sBtnName = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

	if sBtnName == "btn_click" then
		self.m_lbDesc:setVisible(not self.m_lbDesc:isVisible())
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.UPDATE_FAQ_LISTVIEW, self.m_idx)
	end
end

return ClanFAQInfoCell