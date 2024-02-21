--[[
Author: cxc
Date: 2021-12-04 16:56:42
LastEditTime: 2021-12-07 11:00:12
LastEditors: your name
Description: 解析 fnt 类型的node
FilePath: /SlotNirvana/src/utils/spriteFont/CCFntNode.lua
--]]
local CCFntNode = class(CCFntNode, cc.Node)
local BaseParseFont = require("utils.spriteFont.BaseParseFont")

function CCFntNode:ctor(_fontUrl)
	self.m_fontUrl = _fontUrl

	self.m_uiWidth = 0
	self.m_uiHeight = 0
	
	self:createFontAtlas() 
	self:ceateContainerdNode()
end

function CCFntNode:ceateContainerdNode()
	-- 保存子numberNode
	self.m_childContainer = cc.Node:create()
	self:addChild(self.m_childContainer)
end

function CCFntNode:createFontAtlas()
	local fntConfig = BaseParseFont:create(self.m_fontUrl)
	self.m_fntConfig = fntConfig
	self.m_texture2D = fntConfig:getTexture()
	self.m_bFrameRotate = fntConfig:getFrameRotate()
end

function CCFntNode:setString(_str)
	self.m_childContainer:removeAllChildren()

	if tolua.isnull(self.m_texture2D) then
		error("CCFntNode can not find texture")
		return
	end

	self.m_uiWidth = 0
	self.m_uiHeight = 0
	local tempX, maxX = 0, 0
	local tempY = 0
	local tempSize = cc.size(0,0)
	local tempXAdvance = 0
	local str = tostring(_str) or ""
	for i=1, #str do
		local char = string.sub(str, i, i)
		local info = self.m_fntConfig:getCharInfo(char)
		
		if i ~= #str and char == "\n" then
			tempX = 0
			tempXAdvance = 0
			tempY = tempY - tempSize.height
			tempSize = cc.size(0,0)
		elseif info then
			local rect = info[1]
			local xAdvance = info[2]
			local uiVOffset = info[3]

			local sp = cc.Sprite:createWithTexture(self.m_texture2D, rect, self.m_bFrameRotate)
			sp:setAnchorPoint(0, 1)
			sp:addTo(self.m_childContainer)
			tempX = tempX - tempXAdvance
			sp:move(tempX, tempY + uiVOffset)

			tempSize = sp:getContentSize()
			tempXAdvance = rect.width - xAdvance
			tempX = tempX + tempSize.width
			maxX = math.max(tempX, maxX)
		end

	end
	
	self.m_uiWidth = maxX
	self.m_uiHeight = math.abs(tempY) + tempSize.height

	local anchorPoint = self:getAnchorPoint()
	self.m_childContainer:move(self.m_uiWidth * -anchorPoint.x, self.m_uiHeight * (1 - anchorPoint.y))
end

function CCFntNode:getContentSize()
	return cc.size(self.m_uiWidth, self.m_uiHeight)
end

return CCFntNode