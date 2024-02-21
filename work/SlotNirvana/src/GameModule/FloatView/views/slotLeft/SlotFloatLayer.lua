--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-17 12:04:20
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-20 14:40:47
FilePath: /SlotNirvana/src/GameModule/FloatView/views/slotLeft/SlotFloatLayer.lua
Description:  浮动 view 的 layer
--]]
local SlotFloatLayer = class("SlotFloatLayer", BaseLayer)

function SlotFloatLayer:ctor()
	SlotFloatLayer.super.ctor(self)

	self._flotViewList = {}
	self:setShowActionEnabled(false)
	self:setHideActionEnabled(false)
	self:setMaskEnabled(false)
	self:setLandscapeCsbName("LeftFrame/BaseFloatViewLayer.csb")
	self:setPortraitCsbName("LeftFrame/BaseFloatViewLayer_p.csb")
	-- self:setIgnoreAutoScale(true)
end

function SlotFloatLayer:initCsbNodes()
	SlotFloatLayer.super.initCsbNodes(self)

	self._floatViewParent = self:findChild("root")
end

function SlotFloatLayer:initView(_flotViewList)
	_flotViewList = _flotViewList or {}
	-- 容器 aabb 世界坐标
	local refPosW = self._floatViewParent:convertToWorldSpace(cc.p(0,0))
	local refSize = self._floatViewParent:getContentSize()
	self._refAabbW = cc.rect(refPosW.x,refPosW.y, display.width, display.height)

	for i=1, #_flotViewList do
		self:addFloatView((_flotViewList[i]))
	end
end

function SlotFloatLayer:addFloatView(_floatView)
	if tolua.isnull(_floatView) then
		return
	end
	self._floatViewParent:addChild(_floatView)
	_floatView:setParentWordAabb(self._refAabbW)
	_floatView:setParentScale(self:getUIScalePro() or 1)
	-- table.insert(self._flotViewList, _floatView)
	self._flotViewList[_floatView:getName()] = _floatView
end

function SlotFloatLayer:adaptivePos()
	SlotFloatLayer.super.adaptivePos(self)

	self:toDoLayout()
end 

function SlotFloatLayer:toDoLayout()
	self:updateChildLayoutInfo()

	ccui.Helper:doLayout(self._floatViewParent)
	SlotFloatLayer.super.toDoLayout(self)
end

function SlotFloatLayer:updateChildLayoutInfo()
	for _key, _view in pairs(self._flotViewList) do
		if not tolua.isnull(_view) then
			_view:updateLayoutParameter()
		else
			self._flotViewList[_key] = nil
		end
	end
end

function SlotFloatLayer:getFloatView(_floatViewName)
	if not _floatViewName or _floatViewName == "" then
		return
	end

	local floatView
	floatView = self._flotViewList[_floatViewName]
	-- for _, _floatView in ipairs(self._flotViewList) do
	-- 	if not tolua.isnull(_floatView) then
	-- 		if _floatView:getName() == _floatViewName then
	-- 			floatView = _floatView
	-- 			break
	-- 		end
	-- 	end
	-- end

	return floatView
end

return SlotFloatLayer