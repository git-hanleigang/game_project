local BaseParseFont = class("BaseParseFont")

local getNumberByStr = function(_str)
	return tonumber(_str) or 0
end

--[[
	解析fnt
	最简单的解析,解析每个字符的rect就行了
]]
function BaseParseFont:ctor(_fntUrl)
	self.m_fntUrl = _fntUrl

	self:parseFntData()
end

function BaseParseFont:parseFntData()
	local str = CCFileUtils:sharedFileUtils():getStringFromFile(self.m_fntUrl)
	if #str <= 0 then
		error("fnt file empty")
		return
	end

	local lineStrTable = string.split(str, "\n")
	if #lineStrTable < 1 then
		error("fnt file empty")
		return
	end

	self.m_charInfoList = {} 
	for _, lineStr in ipairs(lineStrTable) do
		if string.sub(lineStr, 1, 9) == "info face" then
			self:parseInfoArguments(lineStr)
		elseif string.sub(lineStr, 1, 17) == "common lineHeight" then
			self:parseCommonArguments(lineStr)
		elseif string.sub(lineStr, 1, 7) == "page id" then
			self:parseImageFileName(lineStr)
		elseif string.sub(lineStr, 1, 7) == "chars c" then
			-- // Ignore this line
			-- 当前贴图中所容纳的文字数量
		elseif string.sub(lineStr, 1, 4) == "char" then
			-- // Parse the current line and create a new CharDef
			self:parseCharacterDefinition(lineStr)
		elseif string.sub(lineStr, 1, 13) == "kerning first" then
			self:parseKerningEntry(lineStr)
		end
	end
end

-- 解析字体简介
function BaseParseFont:parseInfoArguments(_str)
	_str = _str or ""

	local sizeStr = string.match(_str, "size=(%d+)")
	self.m_fontSize = getNumberByStr(sizeStr)
	
	local paddingTopStr,paddingRightStr,paddingBottomStr,paddingLeftStr  = string.match(_str, "padding=(%d+),(%d+),(%d+),(%d+)")	
	self.m_paddingList = {	
							getNumberByStr(paddingTopStr), 
							getNumberByStr(paddingRightStr), 
							getNumberByStr(paddingBottomStr), 
							getNumberByStr(paddingLeftStr)
						 }

end

-- 解析字贴图的公共信息
function BaseParseFont:parseCommonArguments(_str)
end

-- 解析字贴图的信息
function BaseParseFont:parseImageFileName(_str)
	self.m_spriteFrameName = string.match(_str, "file=\"(.+)\"") or ""
	local preStr = string.match(self.m_fntUrl, "(.+/)")
	if preStr then
		self.m_spriteFrameName = preStr .. self.m_spriteFrameName
	end
	self.m_spriteFrame = display.newSpriteFrame(self.m_spriteFrameName)
	assert(self.m_spriteFrame, "can not find sprite frame！！！！")

	self.m_texture2D = self.m_spriteFrame:getTexture()
	self.m_txRectInPixels = self.m_spriteFrame:getRectInPixels()
	self.m_bFrameRotate = self.m_spriteFrame:isRotated() 
end

-- 解析 文字的编码以及对应在图片上的矩形位置，偏移等
function BaseParseFont:parseCharacterDefinition(_str)
	local charId = string.match(_str, "char id=(%d+)")
	local x = string.match(_str, "x=(%d+)")
	local y = string.match(_str, "y=(%d+)")
	local width = string.match(_str, "width=(%d+)")
	local height = string.match(_str, "height=(%d+)")
	local xOffset = string.match(_str, "xoffset=(%d+)")
	local yOffset = string.match(_str, "yoffset=(%d+)")
	local xAdvance = string.match(_str, "xadvance=(%d+)")
	local uvX, uvY, uiVOffset = 0,0,0
	local rect = cc.rect(0,0,0,0)

	if self.m_bFrameRotate then
		--- 纵向
		local charHY = getNumberByStr(y) + getNumberByStr(yOffset) +  getNumberByStr(height)
		uvX = (self.m_txRectInPixels.x + self.m_txRectInPixels.height) - charHY
		if charHY > self.m_txRectInPixels.height then
			uvX = (self.m_txRectInPixels.x + self.m_txRectInPixels.height) - self.m_txRectInPixels.height
			uiVOffset = charHY - self.m_txRectInPixels.height
		end
		uvY = self.m_txRectInPixels.y + ( getNumberByStr(x) + getNumberByStr(xOffset) )
		rect = cc.rect(uvX, uvY, getNumberByStr(width), getNumberByStr(height))
	else
		--- 横向
		uvX = self.m_txRectInPixels.x + getNumberByStr(x) + getNumberByStr(xOffset)
		uvY = self.m_txRectInPixels.y + getNumberByStr(y) + getNumberByStr(yOffset)
		local charBTY = uvY + getNumberByStr(height)
		if charBTY > self.m_txRectInPixels.height then
			uvY = self.m_txRectInPixels.height - getNumberByStr(height)
			uiVOffset = charBTY - self.m_txRectInPixels.height
		end
		rect = cc.rect(uvX, uvY, getNumberByStr(width), getNumberByStr(height))
	end

	local charId = string.char(getNumberByStr(charId))
	self.m_charInfoList[charId] = {rect, getNumberByStr(xAdvance), uiVOffset}
end

-- 解析 字组合间距调整的字的数量。
function BaseParseFont:parseKerningEntry(_str)
	-- kerning first=102  second=41 amount=2
	-- 也就是’f’与’)’进行组合显示’f)’时，’)’向右移2像素防止粘在一起。
end

function BaseParseFont:getSpriteFrameName()
	return self.m_spriteFrameName
end
function BaseParseFont:getTexture()
	return self.m_texture2D
end
function BaseParseFont:getCharInfoList()
	return self.m_charInfoList
end
function BaseParseFont:getFrameRotate()
	return self.m_bFrameRotate
end
function BaseParseFont:getCharInfo(_char)
	return self.m_charInfoList[_char]
end
return BaseParseFont