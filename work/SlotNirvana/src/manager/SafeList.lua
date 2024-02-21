--[[
lua的list安全扩展，支持一边迭代一边添加删除
author:JohnnyFred
]]

local SafeList = class("SafeList")

function SafeList:ctor()
	self.list = {}
	self.addCacheList = {}
	self.removeCacheList = {}
	self.lockFlag = 0
end

function SafeList:add(data)
	table.insert(self.lockFlag == 0 and self.list or self.addCacheList,data)
end

function SafeList:remove(data)
	if self.lockFlag == 0 then
		table_removebyvalue(self.list,data,true)
	else
		local removeCacheList = self.removeCacheList
		if removeCacheList[data] == nil then
			table_removebyvalue(self.addCacheList,data,true)
			removeCacheList[data] = data
		end
	end
end

function SafeList:hasData(data)
	local flag = false
	self:foreach(function(index,value)
					if value == data then
						flag = true
					end
					return flag
				end)
	return flag
end

function SafeList:getSize()
	return #self.list + #self.addCacheList - table_length(self.removeCacheList)
end

function SafeList:clear()
	self:foreach(function(index,value)
					self:remove(value)
				end)
end

function SafeList:foreach(callBack)
	self.lockFlag = self.lockFlag + 1
	local list = self.list
	local addCacheList = self.addCacheList
	local removeCacheList = self.removeCacheList
	
	local flag = nil
	for k,v in pairs(list) do
		if removeCacheList[v] == nil then
			if not flag then
				flag = callBack(k,v)
			end
		end
	end
	
	local listCount = #list
	local index = 0
	while #addCacheList > 0 do
		local v = addCacheList[1]
		table.insert(list,v)
		table.remove(addCacheList,1)
		index = index + 1
		if not flag then
			flag = callBack(listCount + index,v)
		end
	end
	
	while table.nums(removeCacheList) > 0 do
		for k,v in pairs(removeCacheList) do
			table_removebyvalue(list,v,true)
			removeCacheList[v] = nil
		end
	end
	self.lockFlag = self.lockFlag - 1
end

return SafeList