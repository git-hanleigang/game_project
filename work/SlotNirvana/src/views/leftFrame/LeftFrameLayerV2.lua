--游戏界面左边活动条 框架
-- ioa 111
local LeftFrameLayerV2 = class("LeftFrameLayerV2", util_require("base.BaseView"))

local DirectionTag = {
    UP = 1,
    DOWN = 2,
    LEFT = "left",
    RIGHT = "right"
}
LeftFrameLayerV2.PAGE_MAX_NODE = 5 -- 页面最多显示几个入口
--[[
    额外参数 
    topDis，downDis - 上下留边数值
]]
LeftFrameLayerV2.EXTRA_INFO = {topDis = 15, downDis = 15, leftDis = 5, rightDis = 10}
function LeftFrameLayerV2:initUI()
    self:createCsbNode("LeftFrame/LeftFrameNodeV2.csb")
    self.m_entryNode = {} -- 已经添加到上面的节点
    self.m_realEntryNodeInfo = {} -- 最大只能放 PAGE_MAX_NODE 的个数
    self.m_tablePushViews = {} -- 用来填装entrynode 的额外tips （为的是不被裁剪）

    self.m_nodeDis = 10 -- 每个 entry 之间的间隔
    self.m_layerDis = 6 -- 当前悬浮条跟边界的距离

    -- self.m_index = 1 --初始化下标
    self.m_maxSize = {widht = 0, height = 0} -- 九宫格大小
    self.m_fSacle = 1
    -- 全局的一个缩放变量
    self.m_bOpenProgress = false -- entry node 是否有处于展开的
    self.m_removeFlag = true
    self.m_padSacle = 1.0
    self.m_layerDirction = DirectionTag.LEFT
    self.m_oldPos = nil
    self.m_currProgressName = ""
    self.m_currNewPos = nil -- csc 2021-09-04 17:56:40 用来记录每次左边条移动后的最新位置
    -- 数据缓存
    self.m_saveName = nil
    self.m_saveFunc = nil

    self.m_openDrag = true -- 是否开启拖拽
    self.m_oldZOrder = nil

    self.m_bg = self:findChild("Image_1")
    self.m_panel = self:findChild("Panel_1")
    -- self.m_panel:setScale(1.2)
    self.m_panel:setSwallowTouches(false)
    self:addClick(self.m_panel)
    self.m_panelBG = self:findChild("Panel_2")
    self:addClick(self.m_panelBG)

    self.m_panelClip = self:findChild("Panel_3")
    self.m_listView = self:findChild("ListView")
    self.m_listView:setScrollBarEnabled(false)
    self.m_listView:setBounceEnabled(false)
    self.m_listView:setItemsMargin(self.m_nodeDis)
    -- self.m_listView:onScroll(handler(self, self.udpateScrollEvt))
    -- self.m_listView:setInertiaScrollEnabled(false) -- 滑动惯性

    self.m_button_down = self:findChild("Button_down")
    self.m_button_up = self:findChild("Button_up")
    self.m_bMoveAction = false

    -- * self.m_fSacle
    local offset = {x = 0, y = 100}
    if self:getIsSpecialScale() then -- ipad 适配相关
        offset.y = offset.y - 20
        self:setScale(0.75)
        self.m_padSacle = 0.75
    end

    if globalData.slotRunData.isPortrait == true then
        self:setPosition(self.m_layerDis + offset.x, globalData.gameLobbyHomeNodePos.y - offset.y)
    else
        self:setPosition(
            self.m_layerDis + util_getBangScreenHeight() + offset.x,
            globalData.gameLobbyHomeNodePos.y - offset.y
        )
    end

    self.m_clipNodeHeight = 0
    self.m_droplayerHeight = 0

    self:runCsbAction("idle", true)

    self.m_isDevelop = true -- 左边条是否展开 or 收起
    self.m_isAnimation = false -- 是否在动画中

    if globalData.slotRunData.isPortrait then
        self.PAGE_MAX_NODE = 4
    end
end

function LeftFrameLayerV2:addDragFrameLayer()
    if self.m_openDrag == false then
        return
    end

    if self.m_droplayer then
        self.m_droplayer:removeFromParent()
        self.m_droplayer = nil
    end
    self.m_droplayer = util_createView("views.leftFrame.DragFrameLayerV2", self)
    self:addChild(self.m_droplayer)
end

function LeftFrameLayerV2:getIsSpecialScale()
    local currViewDire = globalData.slotRunData.isPortrait
    if globalData.slotRunData.machineData then
        currViewDire = globalData.slotRunData.machineData.p_portraitFlag
    end
    local glView = cc.Director:getInstance():getOpenGLView()
    local frameSize = glView:getFrameSize()
    local ratio = frameSize.width / frameSize.height
    --  竖屏
    if currViewDire then
        ratio = frameSize.height / frameSize.width
    end
    if ratio <= 1.34 then
        return true
    end
    return false
end

function LeftFrameLayerV2:onEnter()
    self.m_oldZOrder = self:getZOrder()

    if globalData.slotRunData.isPortrait == false then
        local bgSize = self.m_bg:getContentSize()
        local topUIHeight = globalData.gameRealViewsSize.topUIHeight
        local bottomUIHeight = globalData.gameRealViewsSize.bottomUIHeight
        local offY = (bottomUIHeight - topUIHeight) / 2
        local leftFramePosY = display.cy + bgSize.height * self.m_padSacle / 2 + offY
        self:setPositionY(leftFramePosY)
    end

    --升级消息
    gLobalNoticManager:addObserver(
        self,
        function(self)
        end,
        ViewEventType.SHOW_LEVEL_UP
    )

    gLobalNoticManager:addObserver(
        self,
        function(self)
            -- csc 2021-09-01 修改不需要记录当前坐标,用保留的值即可
            if not self.m_currNewPos then
                self.m_currNewPos = cc.p(self:getPosition())
            end
        end,
        ViewEventType.NOTIFY_ROTATE_SCREEN
    )
    gLobalNoticManager:addObserver(
        self,
        function(self)
            -- 横屏活动转回到竖屏之后,需要重新设置一次坐标
            if self.m_currNewPos then
                self:setPosition(self.m_currNewPos)
                self.m_currNewPos = nil
            end
        end,
        ViewEventType.NOTIFY_RESET_SCREEN
    )
    --self:addDiyFeatureGuide()
end

function LeftFrameLayerV2:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LeftFrameLayerV2:updateDropFrameLayer(size)
    --2021-04-22 这里没必要 *padScale 因为是直接add到 self上的,self在pad下已经有缩放
    if self.m_droplayer then
        local newSize = {width = size.width * self.m_padSacle, height = size.height * self.m_padSacle}
        local pos = cc.p(0, -newSize.height)
        self.m_droplayer:setPosition(pos)
        self.m_droplayer:updateSize(newSize, "left_top")
        self.m_droplayer:setLayerRect(pos, newSize)
    end
end

function LeftFrameLayerV2:updateDropFramePos()
    if self.m_droplayer then
        self.m_droplayer:caculateLayerPosInfo()
        self.m_droplayer:updatePosition(cc.p(self:getPosition()))
    end
end

function LeftFrameLayerV2:clickFunc(sender)
    if self.m_isAnimation then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_down" then
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        if not self.m_isDevelop then
            return
        end
        self:playOver()
    elseif name == "Button_up" then
        if self.m_isDevelop then
            return
        end
        self:playShow()
    end
end

function LeftFrameLayerV2:playShow()
    local num = table.nums(self.m_realEntryNodeInfo)
    if num <= 1 then
        return
    end
    self.m_panel:setSwallowTouches(false)
    self.m_isAnimation = true
    self.m_isDevelop = true
    self.m_droplayer:setIsTouch(true)
    self:setRealEntryNodeVisible(true)
    self.m_bg:setVisible(true)
    self.m_bg:setOpacity(255)
    -- 左边条向右展开
    local entryNodeMoveX = (self.m_maxSize.widht + 10) * self.m_padSacle
    if self.m_layerDirction == DirectionTag.RIGHT then
        entryNodeMoveX = entryNodeMoveX * -1
    end
    local entryNodeMoveLeftPos = cc.p(entryNodeMoveX, 0)
    local actMoveUp = cc.MoveBy:create(0.2, entryNodeMoveLeftPos)
    local callFunc =
        cc.CallFunc:create(
        function()
            self.m_droplayer:setIsTouch(false)
            self.m_isAnimation = false
            self:changeArrowStatus()
            self.m_currNewPos = cc.p(self:getPosition())
        end
    )
    local sequence = cc.Sequence:create(actMoveUp, callFunc)
    self:runAction(sequence)
end

function LeftFrameLayerV2:playOver()
    local num = table.nums(self.m_realEntryNodeInfo)
    if num <= 1 then
        return
    end
    self.m_panel:setSwallowTouches(true)
    self.m_isAnimation = true
    self.m_isDevelop = false
    self.m_droplayer:setIsTouch(true)
    -- 左边条往左回收
    local entryNodeMoveX = (-self.m_maxSize.widht - 10) * self.m_padSacle
    if self.m_layerDirction == DirectionTag.RIGHT then
        entryNodeMoveX = entryNodeMoveX * -1
    end
    local entryNodeMoveLeftPos = cc.p(entryNodeMoveX, 0)
    local actMoveUp = cc.MoveBy:create(0.2, entryNodeMoveLeftPos)
    local callFunc =
        cc.CallFunc:create(
        function()
            self.m_isAnimation = false
            self:changeArrowStatus()
            self.m_currNewPos = cc.p(self:getPosition())
            self:setRealEntryNodeVisible(false)
            self.m_bg:setVisible(false)
            self.m_bg:setOpacity(0)
        end
    )
    local sequence = cc.Sequence:create(actMoveUp, callFunc)
    self:runAction(sequence)
end

-- 节点隐藏 or 显示
function LeftFrameLayerV2:setRealEntryNodeVisible(_val)
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        self.m_realEntryNodeInfo[i].node:setVisible(_val)
    end
end

-- 根据listview的位置得到当前排在第一个位置的索引
function LeftFrameLayerV2:getIndexByListViewPos()
    local listViewSize = self.m_listView:getContentSize()
    local len = table.nums(self.m_realEntryNodeInfo)
    local innerSize = self.m_listView:getInnerContainerSize()
    local innerPos = self.m_listView:getInnerContainerPosition()
    local cellHeight = listViewSize.height / self.PAGE_MAX_NODE
    local topNum = math.floor(math.abs(innerPos.y) / cellHeight + 0.5)
    return math.max((len - topNum - self.PAGE_MAX_NODE), 0)
end

function LeftFrameLayerV2:udpateScrollEvt(event)
    if event.name == "SCROLLING" then
    elseif event.name == "CONTAINER_MOVED" then
    elseif event.eventType == 11 then -- SCROLLING_BEGAN
        print("++++++++++SCROLLING_BEGAN++++++++++", event.eventType)
    elseif event.eventType == 12 then -- SCROLLING_ENDED
        print("++++++++++SCROLLING_ENDED++++++++++", event.eventType)
    end
end

function LeftFrameLayerV2:resetOpenProgressNodePos()
    local entryNodeInfo = nil
    local index = 0
    local nLen = table.nums(self.m_realEntryNodeInfo)
    for i = nLen, 1, -1 do
        entryNodeInfo = self.m_realEntryNodeInfo[i]
        if entryNodeInfo then
            local _realNode = entryNodeInfo.node
            if _realNode and (not tolua.isnull(_realNode)) then
                local node = _realNode:getChildByTag(10)
                if _realNode:getName() == self.m_currProgressName then
                    -- entryNodeInfo = self.m_realEntryNodeInfo[i]
                    index = i
                    break
                end
            end
        end
    end
    if entryNodeInfo and index > 0 then
        local node = entryNodeInfo.node
        self.m_listView:jumpToItem((index - 1), cc.p(0.5, 1), cc.p(0.5, 1))
        -- local len = table.nums(self.m_realEntryNodeInfo)
        local posNum = nLen - index
        local pos = entryNodeInfo.pos
        local max_len = math.min(self.PAGE_MAX_NODE, nLen)
        if posNum < max_len then -- 说明节点在最后，调整listView的位置已经没有用了
            local listViewPos = cc.p(self.m_listView:getPosition())
            local topPosY = self.m_clipNodeHeight - pos.y -- 左边条顶部位置
            local worldPos = self.m_listView:convertToWorldSpace(cc.p(listViewPos.x, topPosY))
            local nodePos = node:getParent():convertToNodeSpace(worldPos)
            node:setPositionY(nodePos.y)
        end
        self.m_listView:setTouchEnabled(false)
    end
end

-- 把节点添加到这里面来
function LeftFrameLayerV2:addEntryNode(node, index, size)
    if node == nil or tolua.isnull(node) then
        return
    end

    local activityName = node:getName()
    printInfo("activityName  == " .. activityName)

    local listSize = cc.size(120, size.height)
    local listIndex = self.m_listView:getIndex(node:getParent())
    if listIndex < 0 then
        local layout = ccui.Layout:create()

        if DEBUG == 2 then
            layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
            layout:setBackGroundColor( cc.c4b(192, 192, 192 ) );
            layout:setBackGroundColorOpacity( 80 )
        end
        
        layout:addChild(node)
        layout:setContentSize(listSize)
        node:setPosition(listSize.width / 2, listSize.height / 2)
        self.m_listView:insertCustomItem(layout, (index - 1))
    end

    if self.m_bOpenProgress then
        self:resetOpenProgressNodePos()
    end

    node:setZOrder(9999 - index)
    self.m_entryNode[index] = node

    -- node:setName(activityName)
    -- self.m_index = self.m_index + 1
end

function LeftFrameLayerV2:removeEntryNode(activityName)
    -- print("清理-------- activityName  = "..activityName)
    -- self.m_entryNode[activityName] = false
    self.m_removeFlag = true
    -- self.m_index = self.m_index - 1
    self.m_maxSize = {widht = 0, height = 0}

    -- 如果要删除的node 点 不是正在展开的点。 则不能重置信息
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        local _realNode = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_realNode) then
            local node = _realNode:getChildByTag(10)
            local bOpen = false
            if node.getEntryNodeOpenState then
                bOpen = node:getEntryNodeOpenState()
            end

            if _realNode:getName() == activityName then
                if bOpen then
                    self.m_bOpenProgress = false
                    self.m_currProgressName = ""
                    self.m_listView:setTouchEnabled(true)
                    self.m_bNeedAddMoveAction = false
                end
                table.remove(self.m_realEntryNodeInfo, i)
                break
            end
        else
            util_sendToSplunkMsg("luaError", "2--find leftFrame node activityName:" .. tostring(activityName) .. " name:" .. self.m_realEntryNodeInfo[i].name .. "!!!")
        end
    end

    for i = #self.m_entryNode, 1, -1 do
        local _entryNode = self.m_entryNode[i]
        if (not tolua.isnull(_entryNode)) then
            if activityName == _entryNode:getName() then
                table.remove(self.m_entryNode, i)
                self.m_listView:removeItem((i - 1))
                break
            end
        else
            util_sendToSplunkMsg("luaError", "1--find leftFrame node " .. tostring(activityName) .. "!!!")
        end
    end

    self.m_listView:doLayout()

    -- if self.m_bOpenProgress then
    self:changeBgPanelSize(false) -- 当前有展开的情况下 删了节点要重新计算bg的长度
    -- end
    -- print("清理-------- self.m_maxSize.height  = "..self.m_maxSize.height)
    if self.m_bOpenProgress then
        self:resetOpenProgressNodePos()
    end
end

function LeftFrameLayerV2:adjustMaxSizeWidth(newSize)
    if self.m_maxSize.widht < newSize.widht then
        self.m_maxSize.widht = 130 -- newSize.widht 固定bg宽度，则箭头位置横向不会移动，不会出现收起状态下箭头位置偏移
    end
end

function LeftFrameLayerV2:adjustMaxSize(newSize)
    -- 计算size 宽度默认用最大的入口的宽度,长度累加
    if self.m_maxSize.widht < newSize.widht then
        self.m_maxSize.widht = 130 -- newSize.widht 固定bg宽度，则箭头位置横向不会移动，不会出现收起状态下箭头位置偏移
    end

    self.m_maxSize.height = self.m_maxSize.height + newSize.height
end

function LeftFrameLayerV2:sortEntryNode(index, name, size)
    -- print("sortEntryNode ---- name = "..name)
    local listSize = cc.size(120, size.height)
    for i = 1, table.nums(self.m_entryNode) do
        local _entryNode = self.m_entryNode[i]
        if not tolua.isnull(_entryNode) then
            if _entryNode:getName() == name then
                local entryNode = _entryNode:getChildByTag(10)
                self:buttonSwallowTouches(entryNode)
                local data = {
                    node = clone(_entryNode),
                    size = size,
                    pos = cc.p(listSize.width / 2, listSize.height / 2),
                    zorder = self.m_entryNode[i]:getZOrder(),
                    name = name
                }
                data.node:setZOrder(9999 - index)
                self.m_realEntryNodeInfo[index] = data
                break
            end
        else
            util_sendToSplunkMsg("luaError", "3--find leftFrame node " .. tostring(name) .. " is null!!!")
        end
    end

    self:changeBgStatue()
end

function LeftFrameLayerV2:buttonSwallowTouches(root)
    if not root then
        return
    end

    --绑定按钮监听
    if tolua.type(root) == "ccui.Button" or tolua.type(root) == "ccui.Layout" then
        root:setSwallowTouches(false)
    end

    local child_list = root:getChildren()
    for _, node in pairs(child_list) do
        self:buttonSwallowTouches(node)
    end
end

function LeftFrameLayerV2:changeBgPanelSize(changeCilp)
    self.m_maxSize = {widht = 0, height = 0}

    --2021-04-25 这里应该分两步计算
    local size = nil
    --1.先计算出背景长度
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        size = self.m_realEntryNodeInfo[i].size
        if i > self.PAGE_MAX_NODE then -- 大于一页限制个数的时候 不再计算高度了
            size.widht = size.widht + self.EXTRA_INFO.leftDis + self.EXTRA_INFO.rightDis
            self:adjustMaxSizeWidth(size)
        else
            local curSize = clone(size)
            if i == self.PAGE_MAX_NODE then
                if globalData.slotRunData.isPortrait then
                    curSize.height = curSize.height / 2
                else
                    curSize.height = curSize.height / 4
                end
            end
            -- 1. 根据入口大小计算 九宫格大小
            self:adjustMaxSize(curSize)
            -- 从第二个开始需要加上入口间距
            self.m_maxSize.height = self.m_maxSize.height + (i > 1 and self.m_nodeDis or 0)
        end
    end

    --2.设置背景大小
    -- 上下留边数值
    local topDis = self.EXTRA_INFO.topDis
    local downDis = self.EXTRA_INFO.downDis
    self.m_maxSize.height = self.m_maxSize.height + topDis + downDis

    local height = self.m_maxSize.height * self.m_fSacle
    local panelHeight = self.m_maxSize.height * self.m_fSacle
    -- 设置大小
    self.m_bg:setContentSize(self.m_maxSize.widht, height)
    self.m_panel:setContentSize(self.m_maxSize.widht, panelHeight)
    self.m_panelBG:setContentSize(self.m_maxSize.widht, panelHeight)

    -- 如果当前需要改变拆裁切区域大小的情况
    if changeCilp then
        -- 裁切区域大小不考虑留边的情况 需要裁减掉
        local newHeight = (self.m_maxSize.height - downDis - topDis) * self.m_fSacle
        self.m_clipNodeHeight = newHeight
        self:updateClipNode(newHeight)
        -- 拖动层需要单独计算
        self.m_droplayerHeight = height
        self:updateDropFrameLayer({width = self.m_maxSize.widht, height = self.m_droplayerHeight})
        -- listView
        local listViewSize = self.m_listView:getContentSize()
        self.m_listView:setContentSize(listViewSize.width, newHeight)
    end
end

function LeftFrameLayerV2:changeNodePos()
    if table.nums(self.m_realEntryNodeInfo) > 0 then
        -- 只有在当前有节点的情况下 才创建拖拽
        self:addDragFrameLayer()
    end
    self:changeBgPanelSize(true)

    -- 3.对所有的 entry node 进行位置摆放
    local isVisible = self.m_isDevelop and not self.m_saveName
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local node = self.m_realEntryNodeInfo[i].node
        node:stopAllActions()
        node:setScale(self.m_fSacle)
        node:setVisible(isVisible)
    end

    self:changeArrowStatus()

    local bOpen = false
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local _realNode = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_realNode) then
            if _realNode:getChildByTag(10).getEntryNodeOpenState then
                bOpen = _realNode:getChildByTag(10):getEntryNodeOpenState()
            end
            if bOpen then
                -- break
                local callShowOtherEntryNode =
                    cc.CallFunc:create(
                    function()
                    end
                )
                if self.m_saveName and _realNode:getName() == self.m_saveName then
                    _realNode:setVisible(true)
                    self:moveClickEntryNode(self.m_realEntryNodeInfo[i], "hide", i, self.m_saveFunc, callShowOtherEntryNode)
                    self.m_saveName = nil
                    self.m_saveFunc = nil
                    self.m_bNeedAddMoveAction = true
                    print("---------- 当前有打开的节点 需要播放一次动画")
                end
            else
                if self.m_bNeedAddMoveAction == true or (self.m_saveName and self.m_saveFunc) then
                    print("---------- 当前有打开的节点 不是打开的节点需要隐藏 name = " .. _realNode:getName())
                    _realNode:setVisible(false)
                end
            end
        else
            util_sendToSplunkMsg("luaError", "10--find leftFrame node " .. tostring(self.m_saveName) .. " is null!!!")
        end
    end

    if bOpen == false then
        if self.m_droplayer then
            -- 发现长度节点位置改变 需要通知拖拽层进行一次位置计算
            local data = {
                node = self,
                layerSize = {
                    width = self.m_maxSize.widht * self.m_padSacle,
                    height = self.m_maxSize.height * self.m_fSacle * self.m_padSacle
                },
                newEntryNode = true
            }
            if self.m_isDevelop then
                self.m_droplayer:checkOpenProgress(data)
            end
        end
    end

    --2021-04-23 需要通知入口下的附属节点当前 入口的显示状态
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_UPDATE_ENTRY_VISIBLE)
end

function LeftFrameLayerV2:changeBgStatue()
    if not self.m_isDevelop then
        return
    end
    if self.m_saveName then
        return
    end
    if #self.m_realEntryNodeInfo > 1 then
        self.m_bg:setVisible(true)
        self.m_bg:setOpacity(255)
    else
        self.m_bg:setVisible(false)
        self.m_bg:setOpacity(0)
    end
end

function LeftFrameLayerV2:changeArrowStatus(_newHeight)
    local rotation = 0
    local offsetX = self.m_bg:getContentSize().width
    if self.m_layerDirction == DirectionTag.RIGHT then
        offsetX = 0
        rotation = 180
    end
    local pos = nil
    if not self.m_bOpenProgress then
        pos = cc.p(self.m_bg:getPositionX() + offsetX, -self.m_bg:getContentSize().height / 2)
    elseif self.m_bOpenProgress and _newHeight then
        pos = cc.p(self.m_bg:getContentSize().width / 2, -_newHeight)
    end
    if pos then
        self.m_button_up:setPosition(cc.p(pos.x, pos.y))
        self.m_button_down:setPosition(cc.p(pos.x, pos.y))
    end
    --csc 2021-10-21 12:13:34 fixbug 刷新列表后没有把点击状态还原
    self.m_button_up:setEnabled(true)
    self.m_button_down:setEnabled(true)
    self.m_button_up:setRotation(-rotation)
    self.m_button_down:setRotation(rotation)

    if self.m_bOpenProgress or #self.m_realEntryNodeInfo <= 1 then
        self.m_button_up:setVisible(false)
        self.m_button_down:setVisible(false)
        return
    end

    self.m_button_up:setVisible(not self.m_isDevelop)
    self.m_button_down:setVisible(self.m_isDevelop)
end

function LeftFrameLayerV2:updateClipNode(height)
    if height then
        local panelClipSize = self.m_panelClip:getContentSize()
        self.m_panelClip:setContentSize(panelClipSize.width, height)
        self.m_panelClip:setPosition(self.m_maxSize.widht / 2, -self.EXTRA_INFO.topDis)
        self.m_listView:setPositionY(height)
    end
end

function LeftFrameLayerV2:updateEntryNodeVisible()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_UPDATE_ENTRY_VISIBLE)
end

function LeftFrameLayerV2:checkRealEntryNode()
    if self.m_removeFlag then --
        self.m_removeFlag = false
        return true
    end
    if #self.m_realEntryNodeInfo ~= #self.m_entryNode then
        return true
    else
        local same = 0
        for i = 1, #self.m_entryNode do
            for j = 1, #self.m_realEntryNodeInfo do
                if self.m_realEntryNodeInfo[j].node == self.m_entryNode[i] then
                    same = same + 1
                end
            end
        end
        if same == #self.m_entryNode then -- 如果当前新的csbnode 跟 已经产生的csb node 没有发生变化。 则不进行遍历
            return false
        end
    end

    return true
end

-- 根据传入的 活动入口名字 , 处理展开状态
function LeftFrameLayerV2:showEntryNodeProgressForName(name, func)
    print("------------LeftFrameLayerV2:showEntryNodeProgressForName ")
    self.m_bOpenProgress = true
    self.m_bTouchFlag = true
    self.m_panel:setSwallowTouches(true)
    -- self:changeArrowStatus()
    self.m_currProgressName = name

    -- 先把其他node 和bg 消失 在上条上去

    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local _realEntryNode = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_realEntryNode) then
            if _realEntryNode:getName() ~= name then
                _realEntryNode:setVisible(false)
            else
                -- 2021年04月21日 如果当前节点要被展开,但是位置处于第四个以后,默认是不显示的,要再这里显示一下
                if not _realEntryNode:isVisible() then
                    _realEntryNode:setVisible(true)
                end
            end
        end
    end
    self.m_bg:setOpacity(0)

    local callShowOtherEntryNode =
        cc.CallFunc:create(
        function()
        end
    )

    local save = false
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local _realEntryNode = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_realEntryNode) then
            if _realEntryNode:getName() == name then
                self:moveClickEntryNode(self.m_realEntryNodeInfo[i], "hide", i, func, callShowOtherEntryNode)
                break
            end
        end

        if i == table.nums(self.m_realEntryNodeInfo) then
            save = true
        end
    end
    -- end)
    if table.nums(self.m_realEntryNodeInfo) == 0 or save then
        -- 最后一个都没找到这个node 或者当前加载出来的node需要播放动画但是还没有被add到 m_realEntryNodeInfo 里的时候 记录这个回调
        self.m_saveName = name
        if func then
            self.m_saveFunc = func
        end
    end
end

-- 根据传入的 活动入口名字 , 处理收回状态
function LeftFrameLayerV2:hideEntryNodeProgressForName(name, func)
    self.m_bOpenProgress = false
    self.m_currProgressName = ""
    -- 上去之后再让 背景和其他node显示出来

    local callShowOtherEntryNode =
        cc.CallFunc:create(
        function()
            for i = 1, table.nums(self.m_realEntryNodeInfo) do
                local _realEntryNode = self.m_realEntryNodeInfo[i].node
                if not tolua.isnull(_realEntryNode) then
                    if _realEntryNode:getName() ~= name then
                        _realEntryNode:setVisible(true)
                    end
                else
                    util_sendToSplunkMsg("luaError", "4--find leftFrame node " .. tostring(name) .. " is null!!!")
                end
            end
            self.m_bg:setOpacity(255)
            self:updateEntryNodeVisible()
            -- self:changeArrowStatus()
        end
    )

    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local _realEntryNode = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_realEntryNode) then
            if _realEntryNode:getName() == name then
                self:moveClickEntryNode(self.m_realEntryNodeInfo[i], "show", i, func, callShowOtherEntryNode)
                break
            end
        else
            util_sendToSplunkMsg("luaError", "5--find leftFrame node activityName:" .. tostring(name) .. " name:" .. self.m_realEntryNodeInfo[i].name .. " is null!!!")
        end
    end
end

function LeftFrameLayerV2:delayShowEntryNode(name, func)
    performWithDelay(
        self,
        function()
            self:showEntryNodeProgressForName(name, func)
        end,
        0.1
    )
end

------- 统一的移动左边条方法 包含多个版本写法 -------
-- 移动点击的 入口点到中心位置 (预留代码  针对后期 锚点为 0，0.5 居中形式的动画使用)
function LeftFrameLayerV2:moveClickEntryNode(entryNode, action, index, func, callback)
    -- 同时需要将所有的pushviews 隐藏掉
    self:hideAllPushViews()

    -- 播放动画
    self:moveClickEntryNodeV4(entryNode, action, index, func, callback)
end

function LeftFrameLayerV2:moveClickEntryNodeV4(entryNode, action, index, func, callback)
    local node = entryNode.node
    local sizeInfo = {widht = 120, height = 90, launchHeight = 500}
    if not tolua.isnull(node) and node:getChildByTag(10).getPanelSize ~= nil then
        sizeInfo = node:getChildByTag(10):getPanelSize()
    end
    local data = nil
    -- v4 版本
    -- 展开：左边条向左回收  一定时间后（需要展示的entrynode 展开的时间 ）  左边条回来
    local callfunC2 =
        cc.CallFunc:create(
        function()
            self.m_panel:setSwallowTouches(false)
            printInfo("------ 设置回来 ---- -false")
            if func then
                func()
            end

            if self.m_bOpenProgress then
                if self.m_droplayer then
                    self.m_droplayer:checkOpenProgress(data)
                end
            elseif self.m_bOpenProgress == false and self.m_bNeedAddMoveAction then
                self.m_bNeedAddMoveAction = false
                data.newEntryNode = true
                if self.m_droplayer then
                    self.m_droplayer:checkOpenProgress(data)
                end
            end
            -- csc 2021-09-04 17:57:36 更新最新坐标
            self.m_currNewPos = cc.p(self:getPosition())
        end
    )
    local offsetX = 100 --- 后续补差值
    --2021年04月21日 如果当前展示的是从下方移动上来的小块,那么当前左边条的第一个节点需要重新计算
    local nodeFunc =
        cc.CallFunc:create(
        function()
            self.m_listView:jumpToItem((index - 1), cc.p(0.5, 1), cc.p(0.5, 1))
            local len = table.nums(self.m_realEntryNodeInfo)
            local posNum = len - index
            local pos = entryNode.pos
            local max_len = math.min(self.PAGE_MAX_NODE, len)
            if posNum < max_len then -- 说明节点在最后，调整listView的位置已经没有用了
                if action == "hide" then
                    local listViewPos = cc.p(self.m_listView:getPosition())
                    local topPosY = listViewPos.y - pos.y -- 左边条顶部位置
                    local worldPos = self.m_listView:convertToWorldSpace(cc.p(listViewPos.x, topPosY))
                    local nodePos = node:getParent():convertToNodeSpace(worldPos)
                    node:setPositionY(nodePos.y)
                elseif action == "show" then
                    node:setPositionY(pos.y)
                end
            end
            if action == "hide" then
                self.m_listView:setTouchEnabled(false)
            elseif action == "show" then
                self.m_listView:setTouchEnabled(true)
            end
            local newHeight = self.m_clipNodeHeight
            local dropHeight = self.m_droplayerHeight
            if self.m_bOpenProgress then
                local height = sizeInfo.launchHeight
                if sizeInfo.scale then
                    height = height * sizeInfo.scale
                end
                newHeight = height * self.m_fSacle
                dropHeight = height * self.m_fSacle
            end
            self:updateClipNode(newHeight)
            -- 拖动层需要单独计算
            self:updateDropFrameLayer({width = self.m_maxSize.widht, height = dropHeight})
            self:changeArrowStatus(newHeight)
            if action == "show" then
                self.m_listView:jumpToItem((index - 1), cc.p(0.5, 1), cc.p(0.5, 1))
            end
            -- 展开的时候发送通知，告诉拖动层当前是否越界
            data = {
                node = self,
                layerSize = {width = self.m_maxSize.widht * self.m_padSacle, height = newHeight * self.m_padSacle}
            }
            -- 向外抛出消息告诉界面当前已经收缩到屏幕外了
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_MOVEIN)
        end
    )
    -- 左边条往左回收
    local entryNodeMoveX = self.m_maxSize.widht + sizeInfo.widht + offsetX
    if self.m_layerDirction == DirectionTag.RIGHT then
        entryNodeMoveX = entryNodeMoveX * -1
    end
    local entryNodeMoveLeftPos = cc.p(self:getPositionX() - entryNodeMoveX, self:getPositionY())
    local actMoveUp = cc.MoveTo:create(0.1, entryNodeMoveLeftPos)

    local newPosBack = cc.p(self:getPositionX(), self:getPositionY())
    local actMoveBack = cc.MoveTo:create(0.3, newPosBack)
    local delay = cc.DelayTime:create(0.2)
    local sequence = cc.Sequence:create(actMoveUp, delay, nodeFunc, callback, actMoveBack, callfunC2)
    -- print("------ entryNodeMoveLeftPos x = "..entryNodeMoveLeftPos.x.." entryNodeMoveLeftPos y = "..entryNodeMoveLeftPos.y)
    -- print("------ newPosBack x = "..newPosBack.x.." newPosBack y = "..newPosBack.y)
    if self.m_oldPos then
        -- 组合动画，先回收，移动回原来展开之前的坐标，在回到屏幕内
        newPosBack = self.m_oldPos
        self.m_oldPos = nil

        local newPosBackOne = cc.p(entryNodeMoveLeftPos.x, newPosBack.y)
        local actMoveBackOne = cc.MoveTo:create(0.15, newPosBackOne)
        local newPosBackTwo = cc.p(newPosBack.x, newPosBack.y)
        local actMoveBackTwo = cc.MoveTo:create(0.15, newPosBackTwo)
        sequence = cc.Sequence:create(actMoveUp, delay, nodeFunc, callback, actMoveBackOne, actMoveBackTwo, callfunC2)
    end

    self:runAction(sequence)
end
------- 统一的移动左边条方法 包含多个版本写法  end -------

-- 判断当前是否处于展开状态
-- _entryNodeName 如果当前指定判断为某个入口是否展开，需要进行判断
function LeftFrameLayerV2:getIsOpenProgress(_entryNodeName)
    if _entryNodeName then
        if self.m_currProgressName == _entryNodeName then
            return true
        else
            return false
        end
    end
    return self.m_bOpenProgress
end

--[[
    拖拽条调用返回事件
]]
function LeftFrameLayerV2:getOldZOrder()
    if self.m_oldZOrder then
        return self.m_oldZOrder
    end
    return GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
end
function LeftFrameLayerV2:changePanleSwallow(status, isAutoRecover)
    --如果当前正在移动的话
    if self.m_bMoveAction then
        return
    end
    if self.m_isDevelop then
        self.m_panel:setSwallowTouches(status)
    end
    if isAutoRecover then
        self.m_isAnimation = true
        performWithDelay(
            self,
            function()
                if self.m_isDevelop then
                    self.m_panel:setSwallowTouches(false)
                end
                self.m_isAnimation = false
            end,
            0.2
        )
    end
end

function LeftFrameLayerV2:changeStopDirection(direction)
    if direction then
        self.m_layerDirction = direction
        self.m_oldPos = nil
        self:changeArrowStatus()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME, direction)
    end
end

function LeftFrameLayerV2:checkOpenProgressResult(oldPos)
    if oldPos then
        self.m_oldPos = oldPos
    end
end

function LeftFrameLayerV2:getLayerDis()
    -- 返回悬浮条跟边界的距离
    return self.m_layerDis
end

--[[
    @desc: 更新拖拽之后的最新位置
]]
function LeftFrameLayerV2:updateMoveEndPos(_pos)
    self.m_currNewPos = _pos
end

-- 提供外部接口 添加在遮罩层之上的气泡等不能被裁切的csb
function LeftFrameLayerV2:addPushViews(_entryNodeName, _pushRootPos, _createCsbPath, _pushViewName)
    if self:getPushViews(_entryNodeName, _pushViewName) then
        -- 先将节点删除
        self:removePushViews(_entryNodeName, _pushViewName)
    end
    -- 先将节点找出
    local pushNode = nil

    for i = 1, table.nums(self.m_entryNode) do
        local _entryNode = self.m_entryNode[i]
        if not tolua.isnull(_entryNode) then
            if _entryNode:getName() == _entryNodeName then
                pushNode = self.m_entryNode[i]
                break
            end
        else
            util_sendToSplunkMsg("luaError", "6--find leftFrame node " .. tostring(_entryNodeName) .. " is null!!!")
        end
    end

    if not tolua.isnull(pushNode) and pushNode:getChildByTag(10).getPushViewNode then
        local posForLeftFrame = self:findChild("Node_1"):convertToNodeSpace(_pushRootPos)
        util_nextFrameFunc(
            function()
                if tolua.isnull(self) then
                    -- bugly fix:[[string "views/leftFrame/LeftFrameLayerV2.luac"]:1117: attempt to call method 'findChild' (a nil value)]
                    return
                end
                local pushView = nil
                if string.find(_createCsbPath, ".csb") then
                    pushView = util_createAnimation(_createCsbPath)
                else
                    pushView = util_createView(_createCsbPath)
                end
                if pushView == nil then
                    return
                end
                self:findChild("Node_1"):addChild(pushView)
                pushView:setPosition(posForLeftFrame)
                if _pushViewName then
                    local pushViewsTable = self.m_tablePushViews[_entryNodeName]
                    if pushViewsTable == nil then
                        pushViewsTable = {}
                        pushViewsTable[_pushViewName] = pushView
                    else
                        pushViewsTable[_pushViewName] = pushView
                    end
                    self.m_tablePushViews[_entryNodeName] = pushViewsTable
                end
            end
        )
    end
end

-- 通过活动名,节点名获取到对应的弹窗
function LeftFrameLayerV2:getPushViews(_entryNodeName, _pushViewName, _newRootPos)
    local node = self:getEntryNode(_entryNodeName)
    if not node or not node:isVisible() then -- 如果当前节点没有展示,不返回所属的pushview
        return nil
    end

    local isVisible = self:getEntryNodeVisible(_entryNodeName)
    if not isVisible then
        return nil
    end

    if next(self.m_tablePushViews) then
        -- 获得活动入口所有创建出来的弹窗集合
        local pushViewsTable = self.m_tablePushViews[_entryNodeName]
        if pushViewsTable ~= nil and next(pushViewsTable) then
            local pushViews = pushViewsTable[_pushViewName]
            if _newRootPos and pushViews then
                --如果有新传入的坐标需要更新
                local posForLeftFrame = self:findChild("Node_1"):convertToNodeSpace(_newRootPos)
                pushViews:setPosition(posForLeftFrame)
            end
            return pushViews
        end
    end
    return nil
end

function LeftFrameLayerV2:removePushViews(_entryNodeName, _pushViewName)
    local pushViewsTable = self.m_tablePushViews[_entryNodeName]
    if pushViewsTable ~= nil and next(pushViewsTable) then
        local pushViews = pushViewsTable[_pushViewName]
        if not tolua.isnull(pushViews) then
            pushViews:removeFromParent()
        end
        pushViewsTable[_pushViewName] = nil
    end
end

function LeftFrameLayerV2:hideAllPushViews()
    if next(self.m_tablePushViews) then
        for key, value in pairs(self.m_tablePushViews) do
            if value ~= nil then
                for k, v in pairs(value) do
                    v:setVisible(false)
                end
            end
        end
    end
end

-- 获取当前展开的节点是否为传入的节点
function LeftFrameLayerV2:getIsProgressNode(_entryNodeName)
    if self.m_currProgressName == _entryNodeName then
        return true
    end
    return false
end

function LeftFrameLayerV2:getLeftFrameDirection()
    return self.m_layerDirction
end

-- 获得活动节点
function LeftFrameLayerV2:getEntryNode(activityName)
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        local _node = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_node) then
            if _node:getName() == activityName then
                local node = _node:getChildByTag(10)
                return node
            end
        else
            util_sendToSplunkMsg("luaError", "7--find leftFrame node activityName:" .. tostring(activityName) .. " name:" .. self.m_realEntryNodeInfo[i].name .. " is null!!!")
        end
    end
    return nil
end

function LeftFrameLayerV2:getEntryNodeVisible(_entryNodeName)
    local entryNode = nil
    local entrySize = cc.size(0, 0)
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        local _realEntryInfo = self.m_realEntryNodeInfo[i]
        local _realEntryNode = _realEntryInfo.node
        if not tolua.isnull(_realEntryNode) then
            if _realEntryNode:getName() == _entryNodeName then
                entryNode = _realEntryNode
                entrySize = _realEntryInfo.size
                break
            end
        else
            util_sendToSplunkMsg("luaError", "8--find leftFrame node activityName:" .. tostring(_entryNodeName) .. " name:" .. self.m_realEntryNodeInfo[i].name .. " is null!!!")
        end
    end
    local isVis = entryNode and entryNode:isVisible() or false
    local isInView = self:isInCurrentView(entryNode, entrySize)
    if not isInView then
        isVis = false
    end
    if not self.m_isDevelop then
        isVis = false
    end
    return isVis
end

function LeftFrameLayerV2:getEntryNodeIndex(_entryNodeName)
    local index = 0
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        local _realEntryNode = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_realEntryNode) then
            if _realEntryNode:getName() == _entryNodeName then
                index = i
                break
            end
        else
            util_sendToSplunkMsg("luaError", "9--find leftFrame node activityName:" .. tostring(_entryNodeName) .. " name:" .. self.m_realEntryNodeInfo[i].name .. "!!!")
        end
    end
    return index
end

-- 判断节点是否在当前界面显示
function LeftFrameLayerV2:isInCurrentView(_entryNode, _entrySize)
    if not _entryNode then
        return false
    end

    local posParent = self.m_listView:convertToWorldSpace(cc.p(0, 0))
    local sizeParent = self.m_listView:getContentSize()
    sizeParent = cc.size(sizeParent.width * self.m_padSacle, sizeParent.height * self.m_padSacle)

    local sizeSelf = _entrySize
    sizeSelf = cc.size(sizeSelf.widht * self.m_padSacle, sizeSelf.height / 2 * self.m_padSacle)
    local posSelf = _entryNode:convertToWorldSpace(cc.p(-sizeSelf.width / 2, 0))

    local isInCurrentView =
        cc.rectIntersectsRect(
        cc.rect(posParent.x, posParent.y, sizeParent.width, sizeParent.height),
        cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height)
    )
    return isInCurrentView
end

function LeftFrameLayerV2:getBtnDownWorldPos()
    return self.m_button_down:getParent():convertToWorldSpace(cc.p(self.m_button_down:getPosition()))
end

function LeftFrameLayerV2:getEntryRootNode()
    return self:findChild("Node_1")
end

function LeftFrameLayerV2:addDiyFeatureGuide()
    self.data = {}
    local node = self:getGuideEntryNode(ACTIVITY_REF.DiyFeature)
    self.data.node = node
    self.data.zorder = node:getZOrder()
    self.data.parent = node:getParent()
    self.data.pos = cc.p(node:getPosition())
    local innerPos = self.m_listView:getInnerContainerPosition()
    local listViewPos = cc.p(self.m_listView:getPosition())
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    node:setPosition(cc.p(worldPos.x+15,worldPos.y))
    self:changeGuideNodeZorder(node, ViewZorder.ZORDER_GUIDE + 3)
    self.m_newbieMask = util_newMaskLayer()
    gLobalViewManager.p_ViewLayer:addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE)
end

function LeftFrameLayerV2:changeGuideNodeZorder(node, zorder)
    local newZorder = zorder and zorder or ViewZorder.ZORDER_GUIDE + 1
    util_changeNodeParent(gLobalViewManager.p_ViewLayer, node, newZorder)
end

-- 获得活动节点
function LeftFrameLayerV2:getGuideEntryNode(activityName)
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        local _node = self.m_realEntryNodeInfo[i].node
        if not tolua.isnull(_node) then
            if _node:getName() == activityName then
                return _node
            end
        end
    end
    return nil
end

return LeftFrameLayerV2
