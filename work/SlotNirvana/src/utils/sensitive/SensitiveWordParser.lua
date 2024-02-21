--
-- Author: cxc
-- Date: 2020年11月06日11:47:04
-- File: SensitiveWordParser.lua

-- maskWord默认* level默认 低等级按单词解析
-- ex: local sensitiveStr = SensitiveWordParser:getString(s, maskWord, level) 
-- 敏感字库解析

local SensitiveWordParser = { _inited = false }

local utf8 = require("utils.sensitive.utf8")

local strLen = utf8.len
local strGsub = utf8.sub
local strSub = string.sub
local strLen = string.len
local strByte = string.byte
local strGsub = string.gsub

local _treeLow = {}
local _treeHigh = {}

-- 解析等级
SensitiveWordParser.PARSE_LEVEL = {
	LOW = 1, --根据单词 来解析 fucky -> fucky
	HIGH = 2 --不管是不是单词 fucky -> ****y
}

local function _word2TreeLow(root, word)
	if strLen(word) == 0 then return end

	root[word] = true
end

local function _word2TreeHigh(root, word)
	if strLen(word) == 0 then return end

	local function _byte2Tree(r, ch, tail)
		if tail then
            if type(r[ch]) == 'table' then
                r[ch].isTail = true
            else
                r[ch] = true
            end
		else
            if r[ch] == true then
                r[ch] = { isTail = true }
            else
			    r[ch] = r[ch] or {}
            end
		end
		return r[ch]
	end
	
	local tmpparent = root
	local len = strLen(word)
    for i=1, len do
    	if tmpparent == true then
    		tmpparent = { isTail = true }
    	end
    	tmpparent = _byte2Tree(tmpparent, strSub(word, i, i), i==len)
    end
end

local function _detect(parent, word, idx)
    local len = strLen(word)
  
	local ch = strSub(word, 1, 1)
	-- 比较时将其转换为小写 不影响源字符
	local child = parent[string.lower(ch)]
    
    if not child then
    elseif type(child) == 'table' then
        if len > 1 then
            if child.isTail then
	            return _detect(child, strSub(word, 2), idx+1) or idx
            else
                return _detect(child, strSub(word, 2), idx+1)
            end
        elseif len == 1 then
            if child.isTail == true then
                return idx
            end
        end
    elseif (child == true) then
    	return idx
    end
    return false
end

function SensitiveWordParser:init()
	if self._inited then return end

	-- 统一维护在csv表里
	local words = gLobalResManager:parseCsvDataByName("Csv/Csv_SensitiveWord.csv")

	self:initTreeLow(words)
	self:initTreeHigh(words)

	self._maskWord = "*"
	self._inited = true
end

function SensitiveWordParser:initTreeLow(words)
	for _, word in pairs(words) do

		if type(word) == "table" then
			self:initTreeLow(word)
		end

		if type(word) == "string" then
			_word2TreeLow(_treeLow, word)
		end

	end
end

function SensitiveWordParser:initTreeHigh(words)
	for _, word in pairs(words) do

		if type(word) == "table" then
			self:initTreeHigh(word)
		end

		if type(word) == "string" then
			_word2TreeHigh(_treeHigh, word)
		end

	end
end

--[[
description: 获取 处理后 的字符串
param s str 原始字符串
param maskWord str 替换的字符
param level 处理等级
return str
--]]
function SensitiveWordParser:getString(s, maskWord, level)
	if type(s) ~= "string" or #s <= 0 then 
		return ""
	end

	self._maskWord = maskWord or "*"
	level = tonumber(level) or SensitiveWordParser.PARSE_LEVEL.LOW

	if level == SensitiveWordParser.PARSE_LEVEL.LOW then
		return self:getStringLow(s)
	elseif level == SensitiveWordParser.PARSE_LEVEL.HIGH then
		return self:getStringHigh(s)
	end

	return s
end

function SensitiveWordParser:getStringLow(s)
	local subStrs = string.split(s, " ")

	local tempStr = ""
	for _idx, str in ipairs(subStrs) do
		if #str > 0 and _treeLow[string.lower(str)] then
			str = string.rep(self._maskWord, #str)
		end

		tempStr = tempStr .. str .. ((_idx == #subStrs) and "" or " ")
	end

	if #tempStr > 0 then
		return tempStr
	end

	return s
end

function SensitiveWordParser:getStringHigh(s)
	local i = 1
	local len = strLen(s)
	local word, idx, tmps

	while true do
    	word = strSub(s, i)
    	idx = _detect(_treeHigh, word, i)

    	if idx then
    		tmps = strSub(s, 1, i-1)
    		for j=1, idx-i+1 do
    			tmps = tmps .. self._maskWord
    		end
    		s = tmps .. strSub(s, idx+1)
    		i = idx+1
    	else
    		i = i + 1
    	end
    	if i > len then
    		break
    	end
    end

    return s
end

SensitiveWordParser:init()

return SensitiveWordParser
