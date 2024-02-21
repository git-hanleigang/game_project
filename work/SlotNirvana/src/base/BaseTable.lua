--
-- Author: 	刘阳
-- Date: 	2019-10-24
-- Desc:	tableView的基类

local BaseTable =
    class(
    "BaseTable",
    function()
        return cc.Node:create()
    end
)

BaseTable.isFixBug = function()
    -- if (device.platform == "ios" and util_isSupportVersion("1.7.3")) then
    --     return true
    -- end
    -- if (device.platform == "android" and util_isSupportVersion("1.6.5")) then
    --     return true
    -- end
    return true
end

function BaseTable:ctor(param)
    assert(param, " !! BaseTable is nil !!")
    assert(type(param) == "table", " !! param must be table!! ")
    assert(param.tableSize, " !! must define table's size !! ")
    -- assert(param.parentPanel, " !! must define table's parentPanel !! ")

    self:enableNodeEvents()

    self._tableSize = param.tableSize -- tableview的size
    self._parentPanel = param.parentPanel -- 要加载到的layer
    self._tableDirection = param.directionType or 1 -- tableview的显示方式 1 水平展示 2 竖直展示 (默认水平)
    self._cellSize = param.cellSize -- tableview中cell的size

    -- 存储cell的指针
    self._cellList = {}
    -- 存储坐标
    self._posList = {}
    -- cell界面数据
    self._viewData = {}

    self:addTableView()
    self._showScroll = param.showScroll
    self._paddingScroll = param.padding

    -- 添加监听
    self:_createListeren()
    -- 添加滚动条
    self:_addScrollNoticeNode()
    -- 自动滑动
    self.m_isAutoScroll = false
    self.m_tempOffset = 0
    self.m_checkFrame = 0
end

function BaseTable:addTableView()
    local tableView = cc.TableView:create(cc.size(self._tableSize.width, self._tableSize.height))

    tableView:setDelegate()

    tableView:registerScriptHandler(handler(self, self.tableCellTouched), cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)
    tableView:registerScriptHandler(handler(self, self.scrollViewDidZoom), cc.SCROLLVIEW_SCRIPT_ZOOM)
    tableView:registerScriptHandler(handler(self, self.tableHighLight), cc.TABLECELL_HIGH_LIGHT)
    tableView:registerScriptHandler(handler(self, self.tableUnHighLight), cc.TABLECELL_UNHIGH_LIGHT)

    self._unitTableView = tableView
    -- self._unitTableView:setBounceable(false) -- 取消弹性性能

    self:setTableDirection()
    self:addChild(self._unitTableView, 1)
end

function BaseTable:setTouchEnabled(bEnabled)
    self._unitTableView:setTouchEnabled(bEnabled or false)
    self._touchNode:setTouchEnabled(bEnabled or false)
end

--[[ 重要 用于处理cell的点击的业务逻辑 ]]
function BaseTable:_createListeren()
    local node = cc.Node:create()
    node:setContentSize(self._tableSize)
    self:addChild(node, 999)
    self._touchNode = node
    self._listener =
        TouchNode.extends(
        node,
        function(event)
            if event.name == "began" then
                return self:_onTouchBegan(event)
            elseif event.name == "moved" then
                self:_onTouchMoved(event)
            elseif event.name == "ended" then
                self:_onTouchEnded(event)
            elseif event.name == "outside" then
                self:_onTouchOutSide(event)
            elseif event.name == "outsideend" then
                self:_onTouchOutSideEnd(event)
            end
        end,
        true
    )
end

function BaseTable:onEnter()
    self:onUpdate(handler(self, self.onScheduleUpdate))
end

function BaseTable:onEnterTransitionFinish()
    self:onEnterFinish()
end

function BaseTable:onEnterFinish()
end

function BaseTable:onExitTransitionStart()
    self:onExitStart()
end

function BaseTable:onExitStart()
end

function BaseTable:onExit()
    -- self:reload()
    self:unscheduleUpdate()

    local eventDispatcher = self:getEventDispatcher()
    if self._listener then
        eventDispatcher:removeEventListener(self._listener)
        self._listener = nil
    end

    if self._touchNode then
        self._touchNode = nil
    end

    self:clearData()
end

function BaseTable:onCleanup()
end

-- 定时更新
function BaseTable:onScheduleUpdate(dt)
    if self.m_isAutoScroll then
        local _tempOffset = self:getTableViewOffset() * 1000
        if self.m_checkFrame == 0 then
            self.m_tempOffset = _tempOffset
        end
        if self.m_checkFrame == 2 then
            -- 误差值0.001
            if math.abs(_tempOffset - self.m_tempOffset) < 1 then
                -- 判断是否停止
                self.m_isAutoScroll = false
                self:onAutoScrollCallFunc()
            end
            self.m_checkFrame = 0
        else
            self.m_checkFrame = self.m_checkFrame + 1
        end
    end
end

function BaseTable:onAutoScrollCallFunc()
    -- printInfo("BaseTable:onAutoScrollCallFunc")
end

function BaseTable:onTouchCellChildNode(cellNode, touchPoint)
    if cellNode and cellNode:isVisible() then
        local boxRect = cellNode:getBoundingBox()
        local localPoint = cellNode:getParent():convertToNodeSpace(touchPoint)
        local isTouchInside = cc.rectContainsPoint(boxRect, localPoint)
        return isTouchInside
    end
    return false
end

-- 添加滚动条的提示node 私有方法 外面不要调用
function BaseTable:_addScrollNoticeNode()
    if not self._showScroll then
        return
    end
    -- 创建背景 进度条
    self:createScrollBgAndIcon()
    self:addTouchForScrollIcon()
    -- 滚动条初始位置距离tableview的距离 ( 对于竖直位置来说 距离tableview的右上点差10px 对于水平来说 距离左下点差10px)
    local padding = 10
    if self._paddingScroll then
        padding = self._paddingScroll
    end

    if self._tableDirection == 2 then
        -- 对于竖直位置的初始化
        self._scrollIcon:setAnchorPoint(cc.p(1, 1))
        self._maxHeight = self._tableSize.height -- 滚动的背景底(或者区域)的高度
        self._topPoint = cc.p(self._tableSize.width + padding, self._tableSize.height) -- 滚动条能到的最高点
        self._scrollIcon:setPosition(self._topPoint)
        self._bottomPoint = cc.p(self._tableSize.width + padding, 0) -- 滚动条的右下点
        self._scrollIconOrgSize = self._scrollIcon:getContentSize()
        -- 设置scroll背景底部条
        self._scrollBg:setAnchorPoint(cc.p(1, 1))
        self._scrollBg:setPosition(cc.p(self._tableSize.width + padding, self._tableSize.height))
        self._scrollBg:setContentSize(cc.size(self._scrollBgSize.width, self._maxHeight))
    else
        -- 对于水平位置的初始化
        self._scrollIcon:setAnchorPoint(cc.p(0, 0))
        self._maxWidth = self._tableSize.width - padding * 2 -- 滚动条能设置的最大宽度
        self._leftPoint = cc.p(0 + padding, 0 - padding) -- 滚动条左边的位置
        self._scrollIcon:setPosition(self._leftPoint)
        -- self._scrollIcon:setScaleY( 0.25 )  -- 针对这个图片需要设置一下 后面换图片了 需要改
        self._rightPoint = cc.p(self._tableSize.width - padding, 0 - padding)
    end
    self._scrollIcon:setVisible(false)
end

-- 子类可能需要重写
function BaseTable:createScrollBgAndIcon()
    if self._scrollIcon == nil then
        self._scrollIcon = ccui.ImageView:create("system/image/cardbook/card_jd_latiao.png", 1)
        self._scrollIcon:setScale9Enabled(true)
        self._scrollIcon:setCapInsets(cc.rect(7, 7, 30, 30))
        self._scrollIcon:ignoreContentAdaptWithSize(true)
        self:addChild(self._scrollIcon, 1999)
        self._scrollIconSize = self._scrollIcon:getContentSize()
    end
    if self._scrollBg == nil then
        self._scrollBg = ccui.ImageView:create("system/image/cardbook/card_jd_bj3.png", 1)
        self._scrollBg:setScale9Enabled(true)
        self._scrollBg:setCapInsets(cc.rect(8, 8, 153, 153))
        self._scrollBg:ignoreContentAdaptWithSize(true)
        self:addChild(self._scrollBg, 1998)
        self._scrollBgSize = self._scrollIcon:getContentSize()
    end
end

-- 为滚动条添加触摸
function BaseTable:addTouchForScrollIcon()
    -- 触摸
    if self._scrollIcon then
        util_addNodeClick(
            self._scrollIcon,
            {
                beganCallBack = function()
                    self:touchScrollIconBegan()
                end,
                moveCallBack = function()
                    self:touchScrollIconMoved()
                end,
                endCallBack = function()
                    self:touchScrollIconEnd()
                end,
                cancelCallBack = function()
                    self:touchScrollIconEnd()
                end
            }
        )
    end
end

-- 滚动条的点击的开始
function BaseTable:touchScrollIconBegan()
    if self._scrollIcon == nil then
        return
    end
    if not self._viewData or self._rowNumber == 0 then
        return
    end
    self._touchScrollMark = true
    if self._tableDirection == 2 then
        -- 竖直方向
        self._scrollIconLastPos = cc.p(self._scrollIcon:getTouchBeganPosition())
    else
        -- 水平方向 (暂时还没有涉及到，所以业务逻辑没有实现)
    end
end
-- 滚动条的点击的移动
function BaseTable:touchScrollIconMoved()
    if self._scrollIcon == nil then
        return
    end
    if not self._viewData or self._rowNumber == 0 then
        return
    end
    if self._tableDirection == 2 then
        -- 竖直方向
        local now_pos = cc.p(self._scrollIcon:getPosition())
        local bottomY = self._bottomPoint.y + self._scrollIcon:getContentSize().height
        self._scrollIconTouchMovePos = cc.p(self._scrollIcon:getTouchMovePosition())
        local view_size = self._unitTableView:getViewSize()
        local total_height = self:_getTabletotalHeight() - view_size.height

        if self._scrollIconTouchMovePos.y >= self._scrollIconLastPos.y then
            -- 向上 判断最高点
            if now_pos.y >= self._topPoint.y then
                self._scrollIcon:setPositionY(self._topPoint.y)
                self._unitTableView:setContentOffset(cc.p(0, 0 - total_height))
                return
            end
        else
            -- 向下 判断最低点
            if now_pos.y <= bottomY then
                self._scrollIcon:setPositionY(bottomY)
                self._unitTableView:setContentOffset(cc.p(0, 0))
                return
            end
        end
        -- 设置滚动条的位置
        local dis_y = self._scrollIconTouchMovePos.y - self._scrollIconLastPos.y
        self._scrollIcon:setPositionY(now_pos.y + dis_y)
        self._scrollIconLastPos = cc.p(self._scrollIcon:getTouchMovePosition())
        -- 设置tableview的位置
        local off_set = self._unitTableView:getContentOffset()
        -- 当前位置
        local meta = total_height / (self._topPoint.y - bottomY)
        local ji_fen = self._scrollIcon:getPositionY() - bottomY
        local tableview_posy = ji_fen * meta
        self._unitTableView:setContentOffset(cc.p(0, 0 - tableview_posy))
    else
        -- 水平方向 (暂时还没有涉及到，所以业务逻辑没有实现)
    end
end
-- 滚动条的点击的结束
function BaseTable:touchScrollIconEnd()
    if self._scrollIcon == nil then
        return
    end
    if not self._viewData or self._rowNumber == 0 then
        return
    end
    self._touchScrollMark = nil
    if self._tableDirection == 2 then
        -- 竖直方向
        local now_pos = cc.p(self._scrollIcon:getPosition())
        -- 最高点
        if now_pos.y >= self._topPoint.y then
            self._scrollIcon:setPositionY(self._topPoint.y)
            return
        end
        -- 最低点
        local bottomY = self._bottomPoint.y + self._scrollIcon:getContentSize().height
        if now_pos.y <= bottomY then
            self._scrollIcon:setPositionY(bottomY)
            return
        end
        -- 设置滚动条的位置
        self._scrollIconTouchEndedPos = cc.p(self._scrollIcon:getTouchEndPosition())
        local dis_y = self._scrollIconTouchEndedPos.y - self._scrollIconLastPos.y
        self._scrollIcon:setPositionY(now_pos.y + dis_y)
        self._scrollIconLastPos = cc.p(self._scrollIcon:getTouchEndPosition())
    else
        -- 水平方向 (暂时还没有涉及到，所以业务逻辑没有实现)
    end
end

-- 添加滚动条的提示node 私有方法 外面不要调用
function BaseTable:_setScrollNoticeNode()
    -- 初始化一些基础数据 用于计算
    self._unitTableTopPosY = self._unitTableView:getContentOffset().y
    self._unitTableTopPosX = self._unitTableView:getContentOffset().x
    self._tempPosY = self._unitTableTopPosY -- 对于竖直的 初始值为最顶部
    self._tempPosX = 0
    if not self._showScroll then
        return
    end
    if self._scrollIcon == nil then
        return
    end
    local view_size = self._unitTableView:getViewSize()
    local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, 0)
    if self._tableDirection == 2 then
        -- 竖直
        local total_height = self:_getTabletotalHeight()
        if view_size.height >= total_height then
            self._scrollIcon:setVisible(false)
            self._scrollBg:setVisible(false)
            return
        end
        self._scrollIcon:setVisible(true)
        self._scrollBg:setVisible(true)
        -- 设置缩放的尺寸 (公式: view_size.height / total_height = (滚动条的高度) / self._maxHeight )
        local showHeight = view_size.height / total_height * self._maxHeight
        local scaleY = showHeight / self._scrollIconOrgSize.height
        -- 最小缩放尺寸为原尺寸
        if scaleY < 1 then
            scaleY = 1
            showHeight = self._scrollIconOrgSize.height
        end
        -- self._scrollIcon:setScaleY( scaleY )

        self._scrollIcon:setContentSize(cc.size(self._scrollIconSize.width, showHeight))

        -- 设置初始位置
        self._scrollIcon:setPositionY(self._topPoint.y)
    else
        -- 水平
        local total_width = cell_width * self:numberOfCellsInTableView()
        if view_size.width >= total_width then
            self._scrollIcon:setVisible(false)
            self._scrollBg:setVisible(false)
            return
        end
        self._scrollIcon:setVisible(true)
        self._scrollBg:setVisible(true)
        -- 设置缩放的尺寸 (公式: view_size.width / total_width = (滚动条的宽度) / self._maxWidth )
        local showWidth = view_size.width / total_width * self._maxWidth
        local scaleX = showWidth / self._scrollIcon:getContentSize().width
        -- 最小缩放尺寸为原尺寸
        if scaleX < 1 then
            scaleX = 1
            showWidth = self._scrollIcon:getContentSize().width
        end
        -- self._scrollIcon:setScaleX( scaleX )

        self._scrollIcon:setContentSize(cc.size(showWidth, self._scrollIconSize.height))

        -- 设置初始位置
        self._scrollIcon:setPositionX(self._leftPoint.x)
    end
end

-- tableView偏移位置
function BaseTable:getTableViewOffset()
    local _offset = 0
    if self._tableDirection == 2 then
        _offset = self._unitTableView:getContentOffset().y
    else
        _offset = self._unitTableView:getContentOffset().x
    end
    return _offset
end

-- 滑动的时候 计算滚动条的位置
function BaseTable:_setScrollNoticePosition()
    if self._scrollIcon == nil then
        return
    end
    if self._scrollIcon:isVisible() == false then
        return
    end
    local view_size = self._unitTableView:getViewSize()
    local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, 0)
    if self._tableDirection == 2 then
        if self._unitTableTopPosY then
            -- 竖直
            local totalHeight = self:_getTabletotalHeight()
            local showHeight = view_size.height / totalHeight * self._maxHeight -- ( showHeight为滚动条的高度 )
            -- 计算能到达的最底部点
            local bottomY = self._bottomPoint.y + self._scrollIcon:getContentSize().height
            -- 设置位置
            local nowY = self._unitTableView:getContentOffset().y
            if nowY <= self._unitTableTopPosY then
                -- 超出最高位置
                self._scrollIcon:setPositionY(self._topPoint.y)
                self._tempPosY = self._unitTableTopPosY
            elseif nowY >= 0 then
                -- 已经到最低位置
                self._scrollIcon:setPositionY(bottomY)
                self._tempPosY = 0
            else
                local distance = math.abs(nowY - self._tempPosY)
                -- 计算移动距离的公式: distance / ( totalHeight - viewHeight) = scrollDis / ( self._topPoint -  bottomY )
                local scrollDis = distance / (totalHeight - view_size.height) * (self._topPoint.y - bottomY)

                local scrollPosY = 0
                if nowY > self._tempPosY then
                    scrollPosY = self._scrollIcon:getPositionY() - scrollDis
                    self._scrollIcon:setPositionY(scrollPosY)
                elseif nowY < self._tempPosY then
                    scrollPosY = self._scrollIcon:getPositionY() + scrollDis
                    self._scrollIcon:setPositionY(scrollPosY)
                end

                self._tempPosY = nowY
            end
        end
    else
        if self._unitTableTopPosX then
            local totalWidth = cell_width * self:numberOfCellsInTableView()
            -- 计算能到达的最右边的点
            local showWidth = view_size.width / totalWidth * self._maxWidth -- ( showHeight为滚动条的宽度 )
            local rightX = self._rightPoint.x - showWidth
            -- 设置位置
            local nowX = self._unitTableView:getContentOffset().x
            if nowX <= (-(totalWidth - view_size.width)) then
                -- 最右边
                self._scrollIcon:setPositionX(rightX)
                self._tempPosX = -(totalWidth - view_size.width)
            elseif nowX >= 0 then
                -- 最左边
                self._scrollIcon:setPositionX(self._leftPoint.x)
                self._tempPosX = 0
            else
                local distance = math.abs(nowX - self._tempPosX)
                -- 计算移动距离的公式: distance / ( totalWidth - view_size.width) = scrollDis / ( self._rightPoint.x -  showWidth )
                local scrollDis = distance / (totalWidth - view_size.width) * (self._rightPoint.x - showWidth)
                local scrollPosX = 0
                if nowX > self._tempPosX then
                    scrollPosX = self._scrollIcon:getPositionX() - scrollDis
                    self._scrollIcon:setPositionX(scrollPosX)
                elseif nowX < self._tempPosX then
                    scrollPosX = self._scrollIcon:getPositionX() + scrollDis
                    self._scrollIcon:setPositionX(scrollPosX)
                end
                self._tempPosX = nowX
            end
        end
    end
end

-- 初始化单元坐标
function BaseTable:_initCellPos()
    self._posList = {}
    self._tableViewHeight = 0
    self._tableViewWidth = 0

    local view_size = self._unitTableView:getViewSize()
    if self._tableDirection == 1 then
        -- 水平
        local total_width = 0
        local _tempX = 0
        for i = 1, #self._viewData, 1 do
            local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, i - 1)
            total_width = total_width + cell_width
            self._posList[i] = cc.p(_tempX, 0)
            _tempX = _tempX + cell_width
        end
        self._tableViewWidth = total_width
        self._tableViewHeight = view_size.height
    elseif self._tableDirection == 2 then
        -- 竖直
        local total_height = 0
        local _tempY = 0
        for i = #self._viewData, 1, -1 do
            local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, i - 1)
            total_height = total_height + cell_height
            self._posList[i] = cc.p(0, _tempY)
            _tempY = _tempY + cell_height
        end
        self._tableViewHeight = total_height
        self._tableViewWidth = view_size.width
    end
end

-- 获取高度
function BaseTable:_getTabletotalHeight()
    return self._tableViewHeight
end

-- 获取总宽度
function BaseTable:_getTabletotalWidth()
    return self._tableViewWidth
end

--[[ 子类需要重写 ]]
function BaseTable:_onTouchBegan(event)
    self.m_isAutoScroll = false
    return true
end
--[[ 子类需要重写 ]]
function BaseTable:_onTouchMoved(event)
end
--[[ 子类需要重写 ]]
function BaseTable:_onTouchEnded(event)
    self.m_isAutoScroll = true
end
--[[ 子类可能需要重写 ]]
function BaseTable:_onTouchOutSide(event)
    return false
end
--[[ 子类可能需要重写 ]]
function BaseTable:_onTouchOutSideEnd(event)
    self.m_isAutoScroll = true
end

function BaseTable:getTable()
    return self._unitTableView
end

--[[ 子类需要重写 ]]
function BaseTable:reload(sourceData)
    sourceData = sourceData or {}
    -- 加载 tableview
    self._cellList = {}

    self:setViewData(sourceData)

    self:_initCellPos()

    self._unitTableView:reloadData()

    self:_setScrollNoticeNode()
end

function BaseTable:clearData()
    self._posList = {}
    self._cellList = {}
    self._viewData = {}
    self._rowNumber = 0
end

--[[ 子类 可能 需要重写 ]]
function BaseTable:setTableDirection()
    if self._tableDirection == 1 then
        self._unitTableView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL) -- 水平展示
    else
        self._unitTableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 竖直展示
        self._unitTableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    end
end

--[[ 子类需要重写 ]]
function BaseTable:setViewData(sourceData)
    self._viewData = sourceData or {}

    self._rowNumber = table.nums(self._viewData)
end

function BaseTable:getViewData()
    return self._viewData or {}
end

--[[
    @desc: TableView滚动时的回调事件
    author: 徐袁
    time: 2021-01-15 16:11:13
    --@view: 
    @return: 
]]
function BaseTable:scrollViewDidScroll(view)
    if self._showScroll then
        if not self._touchScrollMark then
            self:_setScrollNoticePosition()
        end
    end
end

function BaseTable:numberOfCellsInTableView()
    if self._rowNumber then
        return self._rowNumber
    else
        return 0
    end
end

--[[
    @desc: TableView缩放时的回调事件
    author: 徐袁
    time: 2021-01-15 16:11:00
    --@view: 
    @return: 
]]
function BaseTable:scrollViewDidZoom(view)
end

--[[ 子类需要重写 ]]
function BaseTable:tableCellTouched(table, cell)
end

--[[ 子类需要重写 ]]
function BaseTable:tableHighLight(table, cell)
end

--[[ 子类需要重写 ]]
function BaseTable:tableUnHighLight(table, cell)
end

--[[ 子类需要重写 ]]
function BaseTable:cellSizeForTable(table, idx)
    return 0, 0
end

--[[ 子类需要重写]]
function BaseTable:tableCellAtIndex(table, idx)
end

--[[
    @desc: 滚动到指定的行
    author: 徐袁
    time: 2021-01-10 16:49:13
    --@rowIndex:
	--@scrollTime:
	--@direction: 0 置顶，1 居中，3 置底
    @return: 
]]
function BaseTable:scrollTableViewByRowIndex(rowIndex, scrollTime, direction)
    -- assert(rowIndex, " !! rowIndex is nil !! ")
    -- cclog("scrollTime==="..scrollTime)
    if not rowIndex or rowIndex <= 0 then
        return
    end

    if not self._rowNumber or self._rowNumber <= 0 then
        return
    end

    if rowIndex > self._rowNumber then
        rowIndex = self._rowNumber
    end
    local rowPos = self._posList[rowIndex]
    local view_size = self._unitTableView:getViewSize()
    local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, rowIndex - 1)
    if self._tableDirection == 2 then
        -- 竖直
        local totalHeight = self:_getTabletotalHeight()
        -- 总高度没有超过view_size的高度 不滚动
        if view_size.height >= totalHeight then
            return
        end

        local _offset = 0
        direction = direction or 0
        if direction == 0 then
            _offset = cell_height
        elseif direction == 1 then
            -- 居中
            _offset = (view_size.height + cell_height) / 2
        elseif direction == 2 then
            -- 底部
            _offset = view_size.height
        end

        local moveDis = (totalHeight - rowPos.y - _offset)
        local offsetY = self._unitTableTopPosY + math.max(moveDis, 0)
        if offsetY > 0 then
            offsetY = 0
        end
        -- 需要记录一下移动的变量
        self.m_offsetY = offsetY

        if scrollTime and scrollTime > 0 then
            self._unitTableView:setContentOffsetInDuration(cc.p(0, offsetY), scrollTime)
        else
            self._unitTableView:setContentOffset(cc.p(0, offsetY))
        end
    else
        -- 水平
        local totalWidth = self:_getTabletotalWidth()
        -- 总宽度没有超过view_size的宽度 不滚动
        if view_size.width >= totalWidth then
            return
        end

        -- 算差值
        local _offset = 0
        direction = direction or 0
        if direction == 0 then
            -- 坐标
            _offset = 0
        elseif direction == 1 then
            -- 居中
            _offset = (view_size.width - cell_width) / 2
        elseif direction == 2 then
            -- 右边
            _offset = view_size.width - cell_width
        end

        local moveDis = rowPos.x - _offset
        local offsetX = self._unitTableTopPosX + math.max(moveDis, 0)
        if offsetX < 0 then
            offsetX = 0
        elseif offsetX > totalWidth - view_size.width then
            offsetX = totalWidth - view_size.width
        end
        -- 需要记录一下移动的变量
        self.m_offsetX = -offsetX
        if scrollTime then
            self._unitTableView:setContentOffsetInDuration(cc.p(-offsetX, 0), scrollTime)
        else
            self._unitTableView:setContentOffset(cc.p(-offsetX, 0))
        end
    end
end

function BaseTable:scrollToBottom(scrollTime)
    local _count = self:numberOfCellsInTableView()
    self:scrollTableViewByRowIndex(_count, scrollTime)
end

function BaseTable:scrollToTop(scrollTime)
    local _count = self:numberOfCellsInTableView()
    if _count > 0 then
        self:scrollTableViewByRowIndex(1, scrollTime)
    end
end

--[[
    获取当前tableview能否向左右方向滑动
    返回值:1->只能向左,2->只能向右,3->左右均可
]]
function BaseTable:getCanScorll()
    local view_size = self._unitTableView:getViewSize()
    local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, 0)
    if self._tableDirection == 2 then
        assert(false, " !! 竖直方向目前还没有涉及到 所以逻辑暂时没有实现 !! ")
    else
        local offset_x = self._unitTableView:getContentOffset().x
        if offset_x >= 0 then
            return 1
        end
        local totalWidth = self:_getTabletotalHeight()
        if math.abs(offset_x) + view_size.width >= totalWidth then
            return 2
        end
        return 3
    end
end

--[[
    获得可视区域可以显示的cell的数量 向上取整
]]
function BaseTable:getViewRowNum()
    local view_size = self._unitTableView:getViewSize()
    local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, 0)
    if self._tableDirection == 2 then
        return math.ceil(view_size.height / cell_height)
    else
        return math.ceil(view_size.width / cell_width)
    end
end

function BaseTable:cellAtIndex(index)
    return self._unitTableView:cellAtIndex(index)
end

function BaseTable:getPosAtIndex(index)
    if not index or type(index) ~= "number" then
        return nil
    end
    return self._posList[index]
end

----------------- cell 操作 -----------------
-- 获取cellnode
function BaseTable:getCellByIndex(_idx)
    local node = self._unitTableView:cellAtIndex(_idx - 1)
    if not tolua.isnull(node) then
        return node
    end
    return nil
end

-- 更新cell
function BaseTable:updateCellAtIndex(_idx)
    self._unitTableView:updateCellAtIndex(_idx - 1)
end

--删除元素
function BaseTable:removeCellAtIndex(_idx)
    if not self._rowNumber or self._rowNumber == 0 then
        return
    end

    self._unitTableView:removeCellAtIndex(_idx - 1)
    self._rowNumber = self._rowNumber - 1
    self._unitTableView:reloadData()
end

-- 增加元素
function BaseTable:insertCellAtIndex(_idx)
    if not self._rowNumber or self._rowNumber == 0 then
        return
    end

    self._unitTableView:insertCellAtIndex(_idx - 1)
    self._rowNumber = self._rowNumber + 1
    self._unitTableView:reloadData()
end

-- 更新tableView 可显示区域
function BaseTable:setContentSize(_size)
    if type(_size) ~= "table" then
        return
    end

    self._unitTableView:setContentSize(_size)
end

----------------- cell 操作 -----------------
--[[
    @desc: 从指定的下标开始差值滚动
    author:陈思超
    time:2021-07-05 16:38:58
    --@_endPos: 滚动到的坐标
	--@direction: 方向
    @return:
]]
function BaseTable:scrollTableViewByDis(_startRowIndex, _dis, _scrollTime, direction)
    -- assert(rowIndex, " !! rowIndex is nil !! ")
    -- cclog("scrollTime==="..scrollTime)
    if not _startRowIndex or _startRowIndex <= 0 then
        return
    end

    if not self._rowNumber or self._rowNumber <= 0 then
        return
    end

    if _startRowIndex > self._rowNumber then
        _startRowIndex = self._rowNumber
    end
    local rowPos = self._posList[_startRowIndex]
    local view_size = self._unitTableView:getViewSize()
    local cell_width, cell_height = self:cellSizeForTable(self._unitTableView, _startRowIndex - 1)
    if self._tableDirection == 2 then
        -- 竖直
        local totalHeight = self:_getTabletotalHeight()
        -- 总高度没有超过view_size的高度 不滚动
        if view_size.height >= totalHeight then
            return
        end

        local _offset = 0
        direction = direction or 0
        if direction == 0 then
            _offset = cell_height
        elseif direction == 1 then
            -- 居中
            _offset = (view_size.height + cell_height) / 2
        elseif direction == 2 then
            -- 底部
            _offset = view_size.height
        end

        local moveDis = (totalHeight - rowPos.y + _dis - _offset)
        local offsetY = self._unitTableTopPosY + math.max(moveDis, 0)
        if offsetY > 0 then
            offsetY = 0
        end
        if _scrollTime and _scrollTime > 0 then
            self._unitTableView:setContentOffsetInDuration(cc.p(0, offsetY), _scrollTime)
        else
            self._unitTableView:setContentOffset(cc.p(0, offsetY))
        end
    else
        -- 水平
        local totalWidth = self:_getTabletotalWidth()
        -- 总宽度没有超过view_size的宽度 不滚动
        if view_size.width >= totalWidth then
            return
        end

        -- 算差值
        local _offset = 0
        direction = direction or 0
        if direction == 0 then
            -- 坐标
            _offset = 0
        elseif direction == 1 then
            -- 居中
            _offset = (view_size.width - cell_width) / 2
        elseif direction == 2 then
            -- 右边
            _offset = view_size.width - cell_width
        end

        local moveDis = (rowPos.x + _dis) - _offset
        local offsetX = self._unitTableTopPosX + math.max(moveDis, 0)
        if offsetX < 0 then
            offsetX = 0
        elseif offsetX > totalWidth - view_size.width then
            offsetX = totalWidth - view_size.width
        end

        if _scrollTime then
            self._unitTableView:setContentOffsetInDuration(cc.p(-offsetX, 0), _scrollTime)
        else
            self._unitTableView:setContentOffset(cc.p(-offsetX, 0))
        end
    end
end

return BaseTable
