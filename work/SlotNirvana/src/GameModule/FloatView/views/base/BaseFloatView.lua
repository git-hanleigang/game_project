--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 16:19:04
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 20:05:43
FilePath: /SlotNirvana/src/GameModule/FloatView/views/base/BaseFloatView.lua
Description: 浮动view 基类
--]]
local BaseFloatView = class("BaseFloatView", BaseView)

function BaseFloatView:ctor( ... )
	BaseFloatView.super.ctor(self)

	self._layoutComp = ccui.LayoutComponent:bindLayoutComponent(self)
	self._bMoveEnabled = true -- 是否可以移动
	self._percentPos = {0, 0} -- x， y percent 位置
	self._marginList = {0, 0, 0, 0} -- 左右上下
	self._bCorrectMargin = true --滑动超过 是否矫正
	self._edgeTypeList = {ccui.LayoutComponent.HorizontalEdge.None, ccui.LayoutComponent.VerticalEdge.None} -- 停靠横竖类型
	self._bNeedCheckNotchBar = false --是否需要检查 刘海
	self:setParentScale(1)
end

function BaseFloatView:initUI()
	BaseFloatView.super.initUI(self)

	-- 移动 触摸层
	if self._bMoveEnabled then
		self:initTouchLayerUI()
	end

	self:updateLayoutParameter()
end

-- 拖拽触摸层
function BaseFloatView:initTouchLayerUI()
	self._touchLayer = cc.LayerColor:create(cc.c3b(250, 250, 0))
    self._touchLayer:setOpacity(0)
    self:addChild(self._touchLayer)
    self:registerTouchEvent()
	self:updateTouchSize()
end
function BaseFloatView:updateTouchSize(_size)
	if not self._touchLayer then
		return
	end
	_size = _size or self:getContentSize()
	self._touchLayer:setContentSize(_size)
end

-- 监测 margin 是否超标 重置
function BaseFloatView:correctMarginInfo()
	if not self._bCorrectMargin then
		-- 不矫正 划到哪算哪
		return
	end
	if self._parentAabbW and self._parentAabbW.width == 0 and self._parentAabbW.height == 0 then
		-- 父节点 都没限制区域， 也没必要矫正
		return
	end
	
	-- 矫正 (只矫正了 超过父节点 rect world)
	local aabbW = self:getWordAabb()

	-- 左右监测
	local leftSpace = aabbW.x - self._parentAabbW.x
	local rightSpace = (self._parentAabbW.x + self._parentAabbW.width) - (aabbW.x + aabbW.width)
	local horizontalOverType
	if leftSpace < self._marginList[1] then
		horizontalOverType = ccui.LayoutComponent.HorizontalEdge.Left
	elseif rightSpace < self._marginList[2] then
		horizontalOverType = ccui.LayoutComponent.HorizontalEdge.Right
	end
	self._edgeTypeList[1] = horizontalOverType or ccui.LayoutComponent.HorizontalEdge.None

	-- 上下监测
	local topSpace = (self._parentAabbW.y + self._parentAabbW.height) - (aabbW.y + aabbW.height)
	local bottomSpace = aabbW.y - self._parentAabbW.y
	local verticalOverType 
	if topSpace < self._marginList[3] then
		verticalOverType = ccui.LayoutComponent.VerticalEdge.Top
	elseif bottomSpace < self._marginList[4] then
		verticalOverType = ccui.LayoutComponent.VerticalEdge.Bottom
	end
	self._edgeTypeList[2] = verticalOverType or ccui.LayoutComponent.VerticalEdge.None

	return horizontalOverType, verticalOverType
end

-- 更新 布局参数
function BaseFloatView:updateLayoutParameter()
	--{上边界，下边界，左边界，右边界}
	local areaInfoList, oriState = util_getSafeAreaInfoList()
	if not self._bNeedCheckNotchBar then
		areaInfoList = {0, 0, 0, 0}
	end
	self._layoutComp:setLeftMargin(self._marginList[1] + (tonumber(areaInfoList[3]) or 0))
	self._layoutComp:setRightMargin(self._marginList[2] + (tonumber(areaInfoList[4]) or 0))
	self._layoutComp:setTopMargin(self._marginList[3] + (tonumber(areaInfoList[1]) or 0))
	self._layoutComp:setBottomMargin(self._marginList[4] + (tonumber(areaInfoList[2]) or 0))

	self._layoutComp:setPositionPercentX(self._percentPos[1])
	self._layoutComp:setPositionPercentY(self._percentPos[2])

	self._layoutComp:setHorizontalEdge(self._edgeTypeList[1])
	self._layoutComp:setVerticalEdge(self._edgeTypeList[2])


	-- local layoutComp = self._layoutComp
	-- layoutComp:setLeftMargin(100)
    -- layoutComp:setRightMargin(100)
    -- layoutComp:setTopMargin(0)
    -- layoutComp:setBottomMargin(200)
    -- layoutComp:setPositionPercentX(0.5)
    -- layoutComp:setPositionPercentY(0.5)
    -- layoutComp:setHorizontalEdge(ccui.LayoutComponent.HorizontalEdge.Right) 
    -- layoutComp:setVerticalEdge(ccui.LayoutComponent.VerticalEdge.Center)
end

-- 拖拽触摸层事件
function BaseFloatView:registerTouchEvent(_event)
	local function onTouchBegan(touch, event)
        local touchPos = touch:getLocation()
		local target = event:getCurrentTarget()
		local location = cc.p(touch:getLocation())
		local locationInNode = target:convertToNodeSpace(location)
		local size = target:getContentSize()
		local rect = cc.rect(0, 0, size.width, size.height)
		if cc.rectContainsPoint(rect, locationInNode) then
			self._startPos = cc.p(self:getPosition())
			-- self._touchLayer:setSwallowsTouches(false)
			self._touchListener:setSwallowTouches(false)
			self._bCanMove = false
			return self._touchLayer:isVisible()
		end
		return false
    end
    local function onTouchMoved(touch, event)
		local startPos = touch:getStartLocation()
        local endPos = touch:getLocation()
		local subX = endPos.x - startPos.x
        local subY = endPos.y - startPos.y
		if not self._bCanMove then
			self._bCanMove = self:checkTouchMove(subX, subY)
		end
		if not self._bCanMove then
			return
		end
		-- self._touchLayer:setSwallowsTouches(true) 
		self._touchListener:setSwallowTouches(true)
		self:setPosition(cc.pAdd(self._startPos, cc.p(subX,subY)))
    end
    local function onTouchEnded(touch, event)
		self._touchListener:setSwallowTouches(false)
		if not self._bCanMove then
			return
		end
        self:correctMarginInfo()
		self:updateLayoutParameter()
		ccui.Helper:doLayout(self:getParent())
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self._touchLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self._touchLayer)
	self._touchListener = listener
end

-- 父节点aabb
function BaseFloatView:setParentWordAabb(_aabb)
	self._parentAabbW = _aabb
end

-- 该节点 aabb
function BaseFloatView:getWordAabb()
	local refNode = self
	local posW = refNode:convertToWorldSpace(cc.p(0,0))
	local size = refNode:getContentSize()
	local aabbW = cc.rect(posW.x,posW.y,size.width*self._parentScale*self:getScale(),size.height*self._parentScale*self:getScale())
	return aabbW
end

-- 触摸监测
function BaseFloatView:checkTouchMove(_subX, _subY)
	return math.abs(_subX) > 30 or (math.abs(_subY) > 30 and math.abs(_subX) > 10)
end

function BaseFloatView:setParentScale(_scale)
	self._parentScale = _scale or 1
end

return BaseFloatView