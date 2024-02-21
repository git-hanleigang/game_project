--[[
    
    author:{author}
    time:2023-03-19 14:23:16
]]
local rtNodeOrder = {
    ReturnSign = 1,
    GrowthFund = 2,
    NewUser7Day = 3
}

local minWPos = cc.p(10, 100)
local maxWPos = cc.p(display.width, display.height - 60)

local itemSize = cc.size(150, 120)

local TipBar = class("TipBar", BaseView)

function TipBar:ctor()
    TipBar.super.ctor(self)
    self.m_rtList = {}
end

function TipBar:initUI()
    TipBar.super.initUI(self)

    self.m_tipBar = ccui.Layout:create()
    self.m_tipBar:setName("layoutTipBar")
    -- self.m_tipBar:setContentSize(itemSize)
    self.m_tipBar:setPosition(cc.p(100, -20))
    -- self.m_tipBar:setPositionX(100)
    self.m_tipBar:setAnchorPoint(cc.p(1, 0.5))
    -- self.m_tipBar:setBackGroundColor(cc.BLACK)
    -- self.m_tipBar:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    -- self.m_tipBar:setBackGroundColorOpacity(255)
    self.m_tipBar:setTouchEnabled(true)

    self:addChild(self.m_tipBar, 2)
    self:addClick(self.m_tipBar)
end

function TipBar:onEnterFinish()
    local minLPos = self:getParent():convertToNodeSpace(minWPos)
    local maxLPos = self:getParent():convertToNodeSpace(maxWPos)
    local _width = maxLPos.x - minLPos.x
    local _height = maxLPos.y - minLPos.y
    -- self.m_rangeRect = cc.rect(minLPos.x, minLPos.y, _width, _height)

    -- local rangeLay = ccui.Layout:create()
    -- rangeLay:setBackGroundColor(cc.RED)
    -- rangeLay:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    -- rangeLay:setBackGroundColorOpacity(150)
    -- rangeLay:setContentSize(cc.size(_width, _height))
    -- rangeLay:setPosition(cc.p(minLPos.x, minLPos.y))
    -- self:addChild(rangeLay)
end

function TipBar:clickStartFunc(_sender)
    local name = _sender:getName()
    if name == "layoutTipBar" then
        self.m_bPos = _sender:getTouchBeganPosition()
        self.m_tipPos = _sender:getParent():convertToWorldSpace(cc.p(_sender:getPosition()))
        local curRect = _sender:getBoundingBox()
        self.m_tipMinWPos = _sender:getParent():convertToWorldSpace(cc.p(curRect.x, curRect.y))
        self.m_tipMaxWPos = _sender:getParent():convertToWorldSpace(cc.p(curRect.x + curRect.width, curRect.y + curRect.height))
        self.m_offsetX = 0
        self.m_offsetY = 0
    end
end

function TipBar:clickMoveFunc(_sender)
    local name = _sender:getName()
    if name == "layoutTipBar" then
        local movePos = _sender:getTouchMovePosition()
        local offsetX = movePos.x - self.m_bPos.x
        local offsetY = movePos.y - self.m_bPos.y

        -- local curRect = _sender:getBoundingBox()
        local tipMinWPos = cc.pAdd(self.m_tipMinWPos, cc.p(offsetX, offsetY))
        local tipMaxWPos = cc.pAdd(self.m_tipMaxWPos, cc.p(offsetX, offsetY))

        if tipMinWPos.x > minWPos.x and tipMaxWPos.x < maxWPos.x then
            self.m_offsetX = offsetX
        end

        if tipMinWPos.y > minWPos.y and tipMaxWPos.y < maxWPos.y then
            self.m_offsetY = offsetY
        end

        if offsetX ~= 0 or offsetY ~= 0 then
            local posX = self.m_tipPos.x + self.m_offsetX
            local posY = self.m_tipPos.y + self.m_offsetY
            local lPos = _sender:getParent():convertToNodeSpace(cc.p(posX, posY))
            _sender:setPosition(lPos)
        end
    end
end

function TipBar:clickEndFunc(_sender)
    local name = _sender:getName()
end

-- function TipBar:addItem(node, type)
--     self.m_tipBar:addChild(node)
-- end

-- 添加到右上角
function TipBar:addItem(node, type)
    self.m_rtList = self.m_rtList or {}

    if not node then
        return
    end

    local _node = self.m_tipBar:getChildByName(type)
    if _node then
        return
    end

    node:setName(type)
    self.m_tipBar:addChild(node)

    node:setSwallowTouches(false, true)

    local _order = rtNodeOrder[type]
    local _info = {type = type, order = _order}
    table.insert(self.m_rtList, _info)
end
-- 从右下角移除
function TipBar:removeFromRT(type)
    local _node = self.m_tipBar:getChildByName(type)
    if _node then
        _node:removeFromParent()
    end

    -- 清理列表
    for i = #self.m_rtList, 1, -1 do
        local info = self.m_rtList[i]
        if info.type == type then
            table.remove(self.m_rtList, i)
        end
    end
end
-- 更新坐标
function TipBar:updatePosOffset()
    self.m_rtList = self.m_rtList or {}
    local nCount = #self.m_rtList
    if nCount <= 0 then
        return
    end

    table.sort(
        self.m_rtList,
        function(a, b)
            return a.order < b.order
        end
    )

    local _size = cc.size(itemSize.width * nCount, itemSize.height)
    self.m_tipBar:setContentSize(_size)
    for i = 1, nCount do
        local _info = self.m_rtList[i]
        if _info then
            local offset = _size.width - (2 * i - 1) * itemSize.width / 2
            local _node = self.m_tipBar:getChildByName(_info.type)
            if _node then
                _node:setPosition(cc.p(offset, itemSize.height / 2))
            end
        end
    end
end

return TipBar
