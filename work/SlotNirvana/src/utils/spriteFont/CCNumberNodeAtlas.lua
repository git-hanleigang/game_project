local CCNumberNodeAtlas = class(CCNumberNodeAtlas, cc.Node)

-- 确保图片里边是 
local defaultStr = "./0123456789"

--[[
_frameName  = 使用的和图中spriteFrame名字
_itemWidth  = 每个字符宽度
_itemHeight = 每个字符高度
_startChar  = 开始字符
]]
function CCNumberNodeAtlas:ctor(_frameName, _itemWidth, _itemHeight, _startChar)
	self.m_frameName = _frameName
	self.m_itemWidth = _itemWidth or 0
	self.m_itemHeight = _itemHeight or 0
	self.m_bFrameRotate = false

	self.m_uiWidth = 0
	self.m_uiHeight = 0

	self.m_charRectList = {}
	self.m_startChar = _startChar or "."

	self:createFontAtlas() 
	self:ceateContainerdNode()
end

function CCNumberNodeAtlas:ceateContainerdNode()
	-- 保存子numberNode
	self.m_childContainer = cc.Node:create()
	self:addChild(self.m_childContainer)
end

function CCNumberNodeAtlas:createFontAtlas()
	local spriteFrame = display.newSpriteFrame(self.m_frameName)
	self.m_texture2D = spriteFrame:getTexture()
	local startIdx = string.find(defaultStr, self.m_startChar)
	if not startIdx then
		error("please check input startChar!!!")
		return
	end

	local rect = spriteFrame:getRectInPixels()
	self.m_bFrameRotate = spriteFrame:isRotated()
	for i = startIdx, #defaultStr do
		local charId = string.sub(defaultStr, i, i)
		self.m_charRectList[charId] = cc.rect(rect.x, rect.y, self.m_itemWidth, self.m_itemHeight)
		if self.m_bFrameRotate then
			rect.y = rect.y + self.m_itemWidth
		else
			rect.x = rect.x + self.m_itemWidth
		end
	end
end

function CCNumberNodeAtlas:setString(_numberStr)
	self.m_childContainer:removeAllChildren()

	if tolua.isnull(self.m_texture2D) then
		error("CCNumberNodeAtlas can not find texture")
		return
	end

	self.m_uiWidth = 0
	self.m_uiHeight = 0
	local tempX, maxX = 0, 0
	local tempY = 0
	local str = tostring(_numberStr) or ""
	for i=1, #str do
		local char = string.sub(str, i, i)
		local rect = self.m_charRectList[char]

		if i ~= #str and char == "\n" then
			tempX = 0
			tempY = tempY - self.m_itemHeight
		elseif rect then
			local sp = cc.Sprite:createWithTexture(self.m_texture2D, rect, self.m_bFrameRotate)
			sp:setAnchorPoint(0, 1)
			sp:addTo(self.m_childContainer)
			sp:move(tempX, tempY)

			tempX = tempX + self.m_itemWidth
			maxX = math.max(tempX, maxX)
		end

	end

	self.m_uiWidth = maxX
	self.m_uiHeight = math.abs(tempY) + self.m_itemHeight

	local anchorPoint = self:getAnchorPoint()
	self.m_childContainer:move(self.m_uiWidth * -anchorPoint.x, self.m_uiHeight * (1 - anchorPoint.y))
end

function CCNumberNodeAtlas:getContentSize()
	return cc.size(self.m_uiWidth, self.m_uiHeight)
end

return CCNumberNodeAtlas