--[[
Author: cxc
Date: 2021-07-20 14:30:12
LastEditTime: 2021-07-20 15:26:53
LastEditors: Please set LastEditors
Description: In User Settings Edit
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatEmojiView.lua
--]]
local ClanChatEmojiView = class("ClanChatEmojiView", util_require("base.BaseView"))
local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")

ClanChatEmojiView.EMOJI_LIST_NUMS = 10
ClanChatEmojiView.EMOJI_LIST_ORDER = {
	1,
	4,
	7,
	8,
	10,
	2,
	5,
	9,
	3,
	6
}

function ClanChatEmojiView:initUI()
	local csbName = "Club/csd/Chat_New/Club_wall_emoji.csb"
	self:createCsbNode(csbName)

	-- 触摸
	local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
	self:addChild(touch, -1)
	performWithDelay(
		self,
		function()
			if tolua.isnull(touch) then
				return
			end
			touch:move(self:convertToNodeSpaceAR(display.center))
		end,
		0
	)
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

	self:setVisible(false)

	self:initEmojiList()
end

function ClanChatEmojiView:initEmojiList()
	local listView = self:findChild("ListView_1")
	if listView then
		listView:setScrollBarEnabled(false)
		for i = 1, self.EMOJI_LIST_NUMS do
			local inx = self.EMOJI_LIST_ORDER[i]
			local layout = ccui.Layout:create()
			local emojiBtn = ccui.Button:create()
			emojiBtn:loadTextureNormal("Club/ui_new/chat/emoji/clanEmoji" .. inx .. ".png", 0)
			emojiBtn:loadTexturePressed("Club/ui_new/chat/emoji/clanEmoji" .. inx .. "_1.png", 0)
			emojiBtn:loadTextureDisabled("Club/ui_new/chat/emoji/clanEmoji" .. inx .. "_1.png", 0)
			local size = emojiBtn:getContentSize()
			layout:setContentSize(size)
			emojiBtn:setPosition(size.width / 2, size.height / 2)
			emojiBtn:setTitleText("")
			emojiBtn:setName("btn_biaoqing" .. inx)
			emojiBtn:setScale(0.9)
			layout:addChild(emojiBtn)
			self:addClick(emojiBtn)
			listView:pushBackCustomItem(layout)
		end
	end
end

function ClanChatEmojiView:clickFunc(sender)
	local name = sender:getName()

	if name == "touch_mask" then
		self:playHideAct()
		return
	end

	-- 发送表情
	local idx = string.split(name, "btn_biaoqing")[2]
	if not idx or string.len(idx) <= 0 or tonumber(idx) <= 0 then
		return
	end

	gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
	gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.CHAT_SEND_EMOJI_MESSAGE, idx) --点击发送emoji
end

function ClanChatEmojiView:playShowAct()
	self:setVisible(true)
	self:runCsbAction("show", false)
end

function ClanChatEmojiView:playHideAct()
	self:stopAllActions()
	self:runCsbAction(
		"hide",
		false,
		function()
			self:setVisible(false)
		end,
		60
	)
end

function ClanChatEmojiView:switchViewVisible(_visible)
	if _visible then
		self:playShowAct()
		return
	end

	self:playHideAct()
end

return ClanChatEmojiView
