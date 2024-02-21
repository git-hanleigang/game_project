local CircleScrollUI = class("CircleScrollUI", util_require("base.BaseView"))

function CircleScrollUI:initDatas(_callback)
    self.m_callFunc = _callback
end

function CircleScrollUI:initUI()
    self:initScrollView()
    self:onUpdate(handler(self, self.updateLogic))
end

function CircleScrollUI:onEnter()
    self:initUIList()
    self:checkPlayToLeftAnim()
    self:checkResetScrollViewPos()
end

function CircleScrollUI:initScrollView()
    local scrollView = ccui.ScrollView:create()
    self.scrollView = scrollView
    self:addChild(scrollView)
    scrollView:setDirection(ccui.LayoutType.HORIZONTAL)
    scrollView:setScrollBarEnabled(false)
    scrollView:setBounceEnabled(true)
    scrollView:addEventListener(
        function(target, eventType)
            if target == scrollView and self.scrollAnimFlag == nil then
                self:updateLogic(1 / 60)
            end
        end
    )
end

--设置UI列表项（锚点必须是0.5，0.5剧中对齐）
function CircleScrollUI:setUIList(uiList)
    self.uiList = uiList
end

--设置ScrollView显示大小
function CircleScrollUI:setDisplaySize(width, height)
    if self.scrollView ~= nil then
        local radius = self.radius
        self.scrollView:setContentSize(cc.size(width, height + radius))
    end
end

function CircleScrollUI:getDisplaySize()
    return self.scrollView:getContentSize()
end

--设置间距
function CircleScrollUI:setMargin(margin)
    self.margin = margin
end

--设置距离最高点的坐标方便计算角度
function CircleScrollUI:setMarginXY(marginX, marginY)
    self.marginX, self.marginY = marginX, marginY
end

--设置最高点宽度百分比，在该点达到最高位置，放在UI列表初始化之后
function CircleScrollUI:setMaxTopYPercent(percent)
    self.maxTopYPercent = percent
end

--设置从从哪个位置开始播放滚动到左边动画,不设置则不播放动画
function CircleScrollUI:setPlayToLeftAnimInfo(percent, time)
    self.playToLeftPercent = percent
    self.playToLeftTime = time
end

--设置最高点高度
function CircleScrollUI:setTopYHeight(height)
    self.topYHeight = height
end

--设置最值点
function CircleScrollUI:setMaxPosY(posY)
    self.maxPosY = posY
end

--设置最大倾斜角度
function CircleScrollUI:setMaxAngle(angle)
    self.maxAngle = angle
end

--设置半径,放在setDisplaySize之前
function CircleScrollUI:setRadius(radius)
    self.radius = radius
end

--设置scrollView初始位置百分比
function CircleScrollUI:setScrollViewOriginPercent(percent)
    self.movePercent = percent    
end

--设置scrollView初始位置移动距离
function CircleScrollUI:setScrollViewOriginDistance(distance)
    self.moveDistance = distance    
end

--设置scrollView初始位置
function CircleScrollUI:setScrollSoundPath(path)
    self.scrollSoundPath = path    
end

--设置裁切类型
function CircleScrollUI:setScrollClippingEnabled(_isEnable)
    if self.scrollView ~= nil then
        self.scrollView:setClippingEnabled(_isEnable)
    end
end

--播放滚动到左边的动画
function CircleScrollUI:checkPlayToLeftAnim()
    local scrollView = self.scrollView
    if self.playToLeftPercent and scrollView then
        local innerSize = scrollView:getInnerContainerSize()
        scrollView:getInnerContainer():setPositionX(-innerSize.width * self.playToLeftPercent)
        scrollView:scrollToLeft(self.playToLeftTime, true)
        self.playToLeftPercent = nil
    end
end

--检测是否初始化scrollView位置
function CircleScrollUI:checkResetScrollViewPos()
    if self.playToLeftPercent then
        return
    end
    local scrollView = self.scrollView
    if scrollView then
        local innerSize = scrollView:getInnerContainerSize()
        if self.movePercent then
            scrollView:getInnerContainer():setPositionX(-innerSize.width * self.movePercent)
            self.movePercent = nil
        elseif self.moveDistance then
            scrollView:getInnerContainer():setPositionX(self.moveDistance)
            self.moveDistance = nil
        end
    end
end

-- 向右向左滑动
function CircleScrollUI:checkScrollToHorizontal(_isRight, _time)
    local scrollView = self.scrollView
    if scrollView then
        if _isRight then
            scrollView:scrollToRight(_time, true)
        else
            scrollView:scrollToLeft(_time, true)
        end
    end
end

-- 水平滚动到指定百分比
function CircleScrollUI:scrollToHorizontalByIndex(moveDesPosX, _moveTime, _callBack)
    local scrollView = self.scrollView
    if scrollView then
        local moveTime = _moveTime or 0
        self.scrollAnimFlag = true
        self.scrollMoveTime = moveTime
        self.startInnerPos = scrollView:getInnerContainerPosition()
        self._autoScrollTargetDelta = moveDesPosX - self.startInnerPos.x
        self.scrollAnimCallBack = _callBack
        self._autoScrollAccumulatedTime = 0
    end
end

--初始化UI列表
function CircleScrollUI:initUIList()
    local scrollView = self.scrollView
    local uiList = self.uiList
    if uiList ~= nil then
        local uiCount = #uiList
        if scrollView ~= nil and uiCount > 0 then
            local margin = self.margin
            local radius = self.radius
            local uiSize = uiList[1]:getContentSize()
            local displaySize = self:getDisplaySize()
            local innerWidth = (uiCount - 1) * margin + uiSize.width * uiCount
            scrollView:setInnerContainerSize(cc.size(innerWidth, uiSize.height))
            self.maxTopYPositionX = displaySize.width * self.maxTopYPercent
            for k, v in ipairs(uiList) do
                local layout = ccui.Layout:create()
                layout:addChild(v)
                v:setPosition(uiSize.width / 2, uiSize.height / 2)
                layout:setPosition((k - 1) * (uiSize.width + margin), 0)
                layout:setSize(uiSize)
                scrollView:addChild(layout)
            end
        end
    end
end

--刷新滚动逻辑
function CircleScrollUI:updateLogic(dt)
    local scrollView = self.scrollView
    if scrollView ~= nil then
        local innerPosition = scrollView:getInnerContainerPosition()
        local innerPosX = innerPosition.x
        if innerPosX ~= self.innerPositionX then
            local marginX = self.marginX
            local marginY = self.marginY
            local maxAngle = self.maxAngle
            local topYHeight = self.topYHeight
            local radius = self.radius
            local maxTopYPositionX = self.maxTopYPositionX
            local displaySize = self:getDisplaySize()
            local circlePosX, circlePosY = displaySize.width / 2, 0
            for k, v in ipairs(scrollView:getChildren()) do
                local vSize = v:getContentSize()
                local vWorldPos = v:convertToWorldSpace(cc.p(vSize.width / 2, vSize.height / 2))
                local vNodePos = scrollView:convertToNodeSpace(vWorldPos)
                if math.abs(vNodePos.x - circlePosX) <= radius then
                    local nodeNewPosY = math.sqrt(math.pow(radius, 2) - math.pow((vNodePos.x - circlePosX), 2)) + circlePosY
                    v:setPositionY(nodeNewPosY)
                end
                local disX = maxTopYPositionX - vNodePos.x
                local movePosY = math.abs(vNodePos.x - maxTopYPositionX) * marginY / marginX
                local nodeNewPosY = topYHeight - movePosY
                local nodeRotation = (nodeNewPosY - topYHeight) * maxAngle / topYHeight
                nodeRotation = disX >= 0 and nodeRotation or -nodeRotation
                --设置角度
                for kk, vv in ipairs(v:getChildren()) do
                    vv:setRotation(nodeRotation)
                end
            end
            -- 这里判断为新手7日目标提供数据
            if self.m_callFunc then
                -- self.m_offSet = innerPosX
                local data = {offSet = innerPosX}
                self.m_callFunc(data)
            end
            self.innerPositionX = innerPosX

            if self.scrollSoundPath then
                local uiList = self.uiList
                if uiList ~= nil and #uiList > 0 then
                    local uiSize = uiList[1]:getContentSize()
                    local innerPos = scrollView:getInnerContainerPosition()
                    if not self.originInnerPos then
                        self.originInnerPos = innerPos
                    else
                        if math.abs(innerPos.x - self.originInnerPos.x) >= uiSize.width then
                            gLobalSoundManager:playSound( self.scrollSoundPath)
                            self.originInnerPos = nil
                        end
                    end
                end
            end
        end
        if self.scrollAnimFlag then
            local children = scrollView:getChildren()
            if #children > 0 then
                self._autoScrollAccumulatedTime = self._autoScrollAccumulatedTime + dt
                local percentage = math.min(1, self._autoScrollAccumulatedTime / self.scrollMoveTime)
                percentage = percentage - 1
                percentage = percentage * percentage * percentage * percentage * percentage + 1
                local newPositionX = self.startInnerPos.x + (self._autoScrollTargetDelta * percentage)
                local reachedEnd = math.abs(percentage - 1) <= 0.000001
                if reachedEnd then
                    newPositionX = self.startInnerPos.x + self._autoScrollTargetDelta
                end
                local adjustedMoveX = newPositionX - innerPosX
                scrollView:setInnerContainerPosition(cc.p((innerPosX + adjustedMoveX), innerPosition.y))
                if reachedEnd then
                    self.scrollAnimFlag = nil
                    if self.scrollAnimCallBack ~= nil then
                        self.scrollAnimCallBack()
                    end
                end
            end
        end
    end
end
return CircleScrollUI
