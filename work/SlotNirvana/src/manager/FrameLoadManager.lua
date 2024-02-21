--[[
分帧加载
author:JohnnyFred

使用实例：
local FrameLoadManager = util_require("manager/FrameLoadManager")
local fm = FrameLoadManager:getInstance()
添加分帧加载信息：
1、没有绑定节点
fm:addInfo("a",10,function(curCount,totalCount)
                
				end,nil)
2、绑定节点（有绑定节点必须添加在父节点上，防止绑定节点删除之后继续加载）
local bindNode = cc.Node:create()
display.getRunningScene():addChild(bindNode)
fm:addInfo("b",20,function(curCount,totalCount)
					
				end,bindNode)
启动分帧加载：
	fm:start("a") fm:start("b") 或者 fm:startAll()
]]

local FrameLoadManager = class("FrameLoadManager")
local SafeList = util_require("manager.SafeList")
FrameLoadManager.instace = nil

function FrameLoadManager:getInstance()
	if FrameLoadManager.instace == nil then
		FrameLoadManager.instace = FrameLoadManager:create()
	end
	return FrameLoadManager.instace
end

function FrameLoadManager:ctor()
	--加载缓存列表
	self.loadMap = {}
	self:__checkSceneNodeEvent()
	util_schedule(display.getRunningScene(),handler(self,self.__onUpdate),1 / 60)
end

function FrameLoadManager:__onUpdate(dt)
	for key,loadList in pairs(self.loadMap) do
		if loadList.loadFlag then
			local infoList = loadList.infoList
			infoList:foreach(function(index,value)
								local curLoadCount = value.curLoadCount
								local count = value.count
								local callBack = value.callBack
								if curLoadCount < count then
									curLoadCount = curLoadCount + 1
									value.curLoadCount = curLoadCount
									print(string.format("frameload key:%s,count:%d/%d",key,curLoadCount,count))
									callBack(curLoadCount,count)
								--加载完成后删除
								else
									self:remove(key)
								end
							end)
		end
	end
end

--添加加载信息
function FrameLoadManager:addInfo(key,count,callBack,bindNode)
	local loadMap = self.loadMap
	local loadList = loadMap[key]
	if loadList == nil then
		loadList = {
						--加载标志
						loadFlag = false,
						--加载信息列表
						infoList = SafeList:create()
					}
		loadMap[key] = loadList
	else
		print(string.format("frameload has same key:%s",key))
	end
	local infoList = loadList.infoList
	infoList:add(
	{
		key = key,
		--当前加载数量
		curLoadCount = 0,
		--总共的加载数量
		count = count,
		--加载回调函数
		callBack = callBack,
		--绑定节点，可为空
		bindNode = bindNode,
	})
	self:__checkNodeEvent(bindNode)
end

function FrameLoadManager:__checkSceneNodeEvent()
	local listenerNode = cc.Node:create()
	local function nodeEvent(event)
        if event == "cleanup" then
        	self:removeAll()
			FrameLoadManager.instace = nil
        end
    end
    listenerNode:registerScriptHandler(nodeEvent)
    display.getRunningScene():addChild(listenerNode)
end

--检查是否绑定节点
function FrameLoadManager:__checkNodeEvent(node)
	if node ~= nil then
		local listenerNode = cc.Node:create()
		node:addChild(listenerNode)
		local function nodeEvent(event)
	        if event == "cleanup" then
	        	self:__handleNodeFunction(node,handler(self,self.remove))
	        end
	    end
	    listenerNode:registerScriptHandler(nodeEvent)
	end
end

function FrameLoadManager:__handleNodeFunction(node,func)
	for key,loadList in pairs(self.loadMap) do
		local infoList = loadList.infoList
		infoList:foreach(function(index,value)
							if value.bindNode == node then
								func(key)
							end
						end)
	end
end

--加载指定key的数据
function FrameLoadManager:start(key)
	local loadList = self.loadMap[key]
	if loadList ~= nil and not loadList.loadFlag then
		loadList.loadFlag = true
		print(string.format("frameload start load:%s",key))
	end
end

--开始加载所有key的数据
function FrameLoadManager:startAll()
	for key,loadList in pairs(self.loadMap) do
		loadList.loadFlag = true
	end
end

--移除指定key的加载数据
function FrameLoadManager:remove(key)
	local loadMap = self.loadMap
	local loadList = loadMap[key]
	if loadList ~= nil then
		loadMap[key] = nil
		print(string.format("frameload remove key:%s",key))
	end
end

--移除所有key的加载数据
function FrameLoadManager:removeAll()
	local loadMap = self.loadMap
	for key,loadList in pairs(loadMap) do
		loadMap[key] = nil
	end
end

return FrameLoadManager