
--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local ListView = ccui.ListView

function ListView:onEvent(callback)
    self:addEventListener(function(sender, eventType)
        local event = {}
        if eventType == 0 then
            event.name = "ON_SELECTED_ITEM_START"
        else
            event.name = "ON_SELECTED_ITEM_END"
        end
        event.target = sender
        callback(event)
    end)
    return self
end

function ListView:onScroll(callback)
    self.m_bRegister = true
    self:addScrollViewEventListener(function(sender, eventType)
        local event = {}
        if eventType == 0 then
            event.name = "SCROLL_TO_TOP"
        elseif eventType == 1 then
            event.name = "SCROLL_TO_BOTTOM"
        elseif eventType == 2 then
            event.name = "SCROLL_TO_LEFT"
        elseif eventType == 3 then
            event.name = "SCROLL_TO_RIGHT"
        elseif eventType == 4 then
            event.name = "SCROLLING"
        elseif eventType == 5 then
            event.name = "BOUNCE_TOP"
        elseif eventType == 6 then
            event.name = "BOUNCE_BOTTOM"
        elseif eventType == 7 then
            event.name = "BOUNCE_LEFT"
        elseif eventType == 8 then
            event.name = "BOUNCE_RIGHT"
        elseif eventType == 9 then
            event.name = "CONTAINER_MOVED"
        elseif eventType == 10 then
            event.name = "AUTOSCROLL_ENDED"
        end
        event.target = sender
        event.eventType = eventType
        callback(event)
    end)
    return self
end

-- listView内容 pos Size 变化 回调
function ListView:onPosOrSizeChangeCall(_callback)
    self._posOrSizeCustomCb = _callback
end

-- 注册 监测
function ListView:onUpdateCheckVisible()
    self.m_direction = self:getDirection()
    self.m_innerNode = self:getInnerContainer()
    self:resetPrePosSizeInfo()
    schedule(self, handler(self, self.checkRefreshChildrenVisible), 1/60)
    self:checkRefreshChildrenVisible()
end
-- 重置记录的listView信息
function ListView:resetPrePosSizeInfo()
    if self.m_direction == ccui.LayoutType.HORIZONTAL then
        self.m_preInnerPos = math.floor(self.m_innerNode:getPositionX())
    else
        self.m_preInnerPos = math.floor(self.m_innerNode:getPositionY())
    end
    self.m_preInnerSize = self.m_innerNode:getContentSize()
end

-- 刷新子节点显隐
function ListView:checkRefreshChildrenVisible()
    if not self:isVisible() then
        return
    end
    
    if self:checkPosOrSizeChange() then
        self:resetPrePosSizeInfo()
        self:refreshChildrenVisible()

        if self._posOrSizeCustomCb then
            self._posOrSizeCustomCb()
        end
    end
end
function ListView:refreshChildrenVisible()
    local children = self:getItems()
    for k, item in pairs(children) do
        if item.checkSelfVisible then
            item:checkSelfVisible(self)
        else 
            self:addItemCheckVisibleFunc(item, self)
        end
    end
end

-- 添加子节点监测显隐方法
function ListView:addItemCheckVisibleFunc(_target)
    if tolua.isnull(_target) then
        return
    end

    _target.checkSelfVisible = function(_item, _listView)
        local listAabb = self:getWordAabb()
        local posSelf = _item:convertToWorldSpace(cc.p(0, 0))
        local sizeSelf = _item:getContentSize()
        local bVisible = cc.rectIntersectsRect(listAabb, cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
        _item:setVisible(bVisible)
    end
    _target:checkSelfVisible(self)
end

-- 检查listView内容 pos Size是否改变
function ListView:checkPosOrSizeChange()
    local curInnerSize = self.m_innerNode:getContentSize()
    local bChange = false
    if self.m_direction == ccui.LayoutType.HORIZONTAL then
        local curInnerPosX = math.floor(self.m_innerNode:getPositionX())
        bChange = curInnerPosX ~= self.m_preInnerPos or curInnerSize.width ~= self.m_preInnerSize.width
    else
        local curInnerPosY = math.floor(self.m_innerNode:getPositionY())
        bChange = curInnerPosY ~= self.m_preInnerPos or curInnerSize.height ~= self.m_preInnerSize.height
    end
    if bChange then
        -- print(string.format("cxc---%f---%f--%f--%f",math.floor(self.m_innerNode:getPositionY()), self.m_preInnerPos, curInnerSize.height, self.m_preInnerSize.height))
    end
    return bChange
end

function ListView:getWordAabb()
    local posWLB = self:convertToWorldSpace(cc.p(0, 0))
    local size = self:getContentSize()
    local posWRT = self:convertToWorldSpace(cc.p(size.width, size.height))
    return cc.rect(posWLB.x, posWLB.y, posWRT.x-posWLB.x, posWRT.y-posWLB.y)
end