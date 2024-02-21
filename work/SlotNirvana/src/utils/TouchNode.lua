--
-- Author: 刘阳
-- Date: 2019-06-14 20:26:01
-- 触摸node
--

local TouchNode =
    class(
    "TouchNode",
    function()
        return cc.Node:create()
    end
)

function TouchNode:ctor()
    TouchNode.extends(self)
end

local function _checkParentIsVisible(_curNode)
    if not _curNode:isVisible() then
        return false
    end
    local _parent = _curNode:getParent()
    if nil == _parent then
        return true
    end
    return _checkParentIsVisible(_parent)
end

--[[
    node:要继承的节点
    hdl:触摸回调
    touchOutside:触摸外是否回调
    isNoTouchClipping:不在裁剪节点显示区域是否没有触摸回调
]]
function TouchNode.extends(node, hdl, touchOutside, isNoTouchClipping)
    if nil ~= node.__extend_touch_node then
        return
    end
    node.__extend_touch_node = true
    node.__touch_hdl = hdl
    node.__TouchEnabled = true
    node.__SwallowTouches = true
    node.__setVisible = node.setVisible
    node.__touchOutside = touchOutside or false
    node.__isNoTouchClipping = isNoTouchClipping or false

    local _event = {}
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(
        function(touch, event)
            if not _checkParentIsVisible(node) then
                return
            end

            -- if not node:checkEventIsDefaultCamera() then
            --     return
            -- end
            local target = event:getCurrentTarget()
            local location = cc.p(touch:getLocation())
            local locationInNode = target:convertToNodeSpace(location)
            local size = target:getContentSize()
            local rect = cc.rect(0, 0, size.width, size.height)
            if cc.rectContainsPoint(rect, locationInNode) then
                if node.__isNoTouchClipping then
                    --如果不在裁剪区域
                    if not node:isInClippingSpacePoint(location) then
                        return false
                    end
                end

                _event["name"] = "began"
                _event["x"] = location.x
                _event["y"] = location.y
                return node.__touch_hdl(_event)
            elseif node.__touchOutside then
                _event["name"] = "outside"
                _event["x"] = location.x
                _event["y"] = location.y
                return node.__touch_hdl(_event)
            end
            return false
        end,
        cc.Handler.EVENT_TOUCH_BEGAN
    )

    listener:registerScriptHandler(
        function(touch, event)
            -- if not node:checkEventIsDefaultCamera() then
            --     return
            -- end
            local target = event:getCurrentTarget()
            local location = touch:getLocation()
            local locationInNode = target:convertToNodeSpace(location)
            local previousLocation = touch:getPreviousLocation()
            local size = target:getContentSize()
            local rect = cc.rect(0, 0, size.width, size.height)
            if cc.rectContainsPoint(rect, locationInNode) then
                _event["name"] = "moved"
                _event["x"] = location.x
                _event["y"] = location.y
                _event["previousLocation"] = previousLocation
                _event["prevX"] = previousLocation.x
                _event["prevY"] = previousLocation.y
                node.__touch_hdl(_event)
            elseif node.__touchOutside then
                _event["name"] = "outsidemoved"
                _event["x"] = location.x
                _event["y"] = location.y
                _event["previousLocation"] = previousLocation
                _event["prevX"] = previousLocation.x
                _event["prevY"] = previousLocation.y
                node.__touch_hdl(_event)
            end
        end,
        cc.Handler.EVENT_TOUCH_MOVED
    )

    listener:registerScriptHandler(
        function(touch, event)
            -- if not node:checkEventIsDefaultCamera() then
            --     return
            -- end

            local target = event:getCurrentTarget()
            local location = cc.p(touch:getLocation())
            local locationInNode = target:convertToNodeSpace(location)
            local size = target:getContentSize()
            local rect = cc.rect(0, 0, size.width, size.height)
            if cc.rectContainsPoint(rect, locationInNode) then
                _event["name"] = "ended"
                _event["x"] = location.x
                _event["y"] = location.y
                _event["target"] = node
                node.__touch_hdl(_event)
            elseif node.__touchOutside then
                _event["name"] = "outsideend"
                _event["x"] = location.x
                _event["y"] = location.y
                return node.__touch_hdl(_event)
            end
        end,
        cc.Handler.EVENT_TOUCH_ENDED
    )

    -- cancelled event @ 2016.4.6 14：42
    listener:registerScriptHandler(
        function(touch, event)
            local location = touch:getLocation()
            _event["name"] = "cancelled"
            _event["x"] = location.x
            _event["y"] = location.y
            node.__touch_hdl(_event)
        end,
        cc.Handler.EVENT_TOUCH_CANCELLED
    )

    node.listener = listener

    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)

    function node:checkEventIsDefaultCamera()
        local default = cc.Camera:getDefaultCamera()
        if default == cc.Camera:getVisitingCamera() then
            return true
        end
        return false
    end

    function node:addNodeEventListener(__, hdl)
        self.__touch_hdl = hdl
        self.listener = listener
        self.listener:setEnabled(self.__TouchEnabled)
        self.listener:setSwallowTouches(self.__SwallowTouches)
    end

    function node:setTouchOutSide(value)
        self.__touchOutside = value
    end
    function node:setTouchEnabled(value)
        self.__TouchEnabled = value
        if nil ~= self.listener then
            self.listener:setEnabled(value)
        end
    end

    --[[
        如果设置了 true 必须 began 返回true 才有效
    ]]
    function node:setTouchSwallowEnabled(value)
        self:setSwallowTouches(value)
    end

    function node:setSwallowTouches(value)
        self.__SwallowTouches = value
        if nil ~= self.listener then
            self.listener:setSwallowTouches(value)
        end
    end

    function node:showBackgroundColor(color)
        if nil == color then
            color = cc.c4b(255, 255, 0, 255)
        end
        if nil ~= self.__bg_color then
            return
        end
        local size = self:getContentSize()
        self.__bg_color = cc.LayerColor:create(color, size.width, size.height)
        self:addChild(self.__bg_color)
    end

    function node:setVisible(value)
        self.listener:setEnabled(value)
        self:__setVisible(value)
    end

    --[[
        一直递归父节点，检查点击位置是否在容器中
        node：开始检查的节点
        ptworld:点击世界坐标
        deepth：检查深入，不填一直递归
    ]]
    function node:checkPtInParent(node, ptWorld, deepth)
        local parent = node:getParent()
        deepth = deepth or 9999999

        if parent then
            deepth = deepth - 1
            if deepth < 0 then
                print("____checkPtInParent=true")
                return true
            end

            local nodePt = parent:convertToNodeSpace(ptWorld)
            local size = parent:getContentSize()
            local rect = cc.rect(0, 0, size.width, size.height)

            --没设置父节点大小的，默认通过
            if size.width == 0 or cc.rectContainsPoint(rect, nodePt) then
                return self:checkPtInParent(parent, ptWorld, deepth)
            else
                print("____checkPtInParent=false")
                return false
            end
        end

        print("____checkPtInParent=true")
        return true
    end

    --是否在裁剪节点区域
    function node:isInClippingSpacePoint(pos)
        local affectByClipping = false
        local parent = self:getParent()
        local clippingParent = nil

        --查找裁剪节点
        while parent do
            --是否为裁剪节点
            if parent.isClippingEnabled and parent:isClippingEnabled() then
                affectByClipping = true
                clippingParent = parent
                break
            end

            if parent.isClippingToBounds and parent:isClippingToBounds() then
                affectByClipping = true
                clippingParent = parent
                break
            end

            parent = parent:getParent()
        end

        --不在裁剪节点内
        if not affectByClipping then
            return true
        end

        --如果在裁剪节点内
        if clippingParent then
            local clippingBox = clippingParent:getBoundingBox()
            local worldPos = clippingParent:getParent():convertToWorldSpace(clippingParent:getBoundingBox())
            clippingBox.x = worldPos.x
            clippingBox.y = worldPos.y
            --是否在裁剪节点内
            if cc.rectContainsPoint(clippingBox, pos) then
                return true
            end
            return false
        end
        return true
    end

    return listener
end

GD.TouchNode = TouchNode
