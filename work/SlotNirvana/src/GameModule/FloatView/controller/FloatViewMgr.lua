--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-28 12:21:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-28 14:24:47
FilePath: /SlotNirvana/src/GameModule/FloatView/controller/FloatViewMgr.lua
Description: 浮动view  mgr
--]]
local FloatViewMgr = class("FloatViewMgr", BaseGameControl)

function FloatViewMgr:ctor()
    FloatViewMgr.super.ctor(self)

    self:setRefName(G_REF.FloatView)
end

function FloatViewMgr:creatMachineFloatView(_node, _zOrder)
    if not tolua.isnull(self._slotFloatLayer) then
        return
    end

    local layer = util_createView("GameModule/FloatView/views/slotLeft/SlotFloatLayer", {}) 
    local zOder = _zOrder or ViewZorder.ZORDER_FLOAT_VIEW
    if _node then
        _node:addChild(layer, zOder)
    else
        self:showLayer(layer, zOder, false)
    end

    local floatViewList = {}
    local luaPath = "GameModule/FloatView/views/slotLeft/SlotLeftFloatView"
	if globalData.slotRunData.isPortrait then
        luaPath = "GameModule/FloatView/views/slotLeft/SlotLeftFloatView_p"
    end
    local leftView = util_createView(luaPath)
    layer:addFloatView(leftView)

    self._slotFloatLayer = layer
    return layer
end

--[[
    获取 关卡左边条入口 node
    viewRefKey: 入口引用名
]]
function FloatViewMgr:getSlotLeftEntryNode(_viewRefKey, _bCheckSmallEntryNode)
    if tolua.isnull(self._slotFloatLayer) or type(_viewRefKey) ~= "string"  then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:getEntryNode(_viewRefKey, _bCheckSmallEntryNode)
end

--[[
    删除关卡左边条入口
    viewRefKey: 入口引用名
]]
function FloatViewMgr:removeSlotLeftEntryNode(_viewRefKey)
    if tolua.isnull(self._slotFloatLayer) or type(_viewRefKey) ~= "string"  then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    leftView:removeEntryCell(_viewRefKey)
end

--[[
	关卡左边条入口添加的 气泡
	_params = {
		viewRefKey: 入口引用名
		viewPath: 气泡资源或nodeLua路径
        bubblePosW: 气泡世界坐标,
		bubbleName: 气泡名
	}
]]
function FloatViewMgr:addSlotLeftFloatBubbleView(_params)
    if tolua.isnull(self._slotFloatLayer) or type(_params) ~= "table"  then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    leftView:addEntryBubble(_params)
end
--[[
	移除 左边条入口添加的 气泡
	_params = {
		viewRefKey: 入口引用名
		bubbleName: 气泡名
	}
]]
function FloatViewMgr:removeSlotLeftFloatBubbleView(_params)
    if tolua.isnull(self._slotFloatLayer) or type(_params) ~= "table"  then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    leftView:removeEntryBubble(_params)
end
--[[
    获取 左边条入口添加的 气泡view
	_params = {
		viewRefKey: 入口引用名
		bubbleName: 气泡名
	}
]]
function FloatViewMgr:getSlotLeftFloatBubbleView(_params)
    if tolua.isnull(self._slotFloatLayer) or type(_params) ~= "table"  then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:getEntryBubble(_params)
end

--[[
    关卡左边条 是否展开状态
    _viewRefKey: 
]]
function FloatViewMgr:checkSlotLeftViewUnfload(_viewRefKey)
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:checkIsUnfload(_viewRefKey)
end

--[[
    关卡左边条 方向
]]
function FloatViewMgr:getSlotLeftDirection()
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:getDirectionH()
end

--[[
    关卡左边条 按钮世界坐标
]]
function FloatViewMgr:getSlotLeftBtnDownPosW()
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:getBtnPosW()
end

--[[
    关卡左边条 按钮世界坐标
]]
function FloatViewMgr:getSlotLeftRootNode()
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:getRootNode()
end

--[[
    关卡左边条 顶部的世界坐标
]]
function FloatViewMgr:getSlotTopFlyPosW()
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:getTopFlyPosW()
end

--[[
    关卡左边条 是否显示
]]
function FloatViewMgr:checkSlotLeftEntryShow()
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:isVisible() and leftView:checkHideBtnVisible()
end

--[[
    获取关卡左边条
]]
function FloatViewMgr:getSlotLeftFloatView()
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView
end

--[[
    跳转到入口位置（居中显示）
    viewRefKey: 入口引用名
]]
function FloatViewMgr:jumpEntryNode(_viewRefKey, _scrollTime)
    if tolua.isnull(self._slotFloatLayer) or type(_viewRefKey) ~= "string"  then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    return leftView:jumpEntryNode(_viewRefKey, _scrollTime)
end

-- 设置 关卡左边条 显隐
function FloatViewMgr:setSlotLeftFloatVisible(_bVisible)
    if tolua.isnull(self._slotFloatLayer) then
        return
    end

    local leftView = self._slotFloatLayer:getFloatView("SlotLeftFloatView")
    if tolua.isnull(leftView) then
        return
    end

    leftView:setVisible(_bVisible and true or false)
end

return FloatViewMgr