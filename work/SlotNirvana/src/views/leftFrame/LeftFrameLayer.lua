--游戏界面左边活动条 框架
-- ioa 111
local LeftFrameLayer = class("LeftFrameLayer", util_require("base.BaseView"))

local DirectionTag = {
    UP = 1,
    DOWN = 2,
    LEFT = "left",
    RIGHT = "right"
}

LeftFrameLayer.PAGE_MAX_NODE = 4 -- 页面最多显示几个入口
LeftFrameLayer.EXTRA_INFO = {topDis = 20, downDis = 5} --是否需要上下留边
function LeftFrameLayer:initUI()
    self:createCsbNode("LeftFrame/LeftFrameNode.csb")
    self.m_entryNode = {} -- 已经添加到上面的节点
    self.m_realEntryNodeInfo = {} -- 最大只能放 PAGE_MAX_NODE 的个数
    self.m_tablePushViews = {} -- 用来填装entrynode 的额外tips （为的是不被裁剪）

    self.m_nodeDis = 10 -- 每个 entry 之间的间隔
    self.m_layerDis = 6 -- 当前悬浮条跟边界的距离

    self.m_index = 1 --初始化下标
    self.m_maxSize = {widht = 0, height = 0} -- 九宫格大小
    self.m_firstEntryNodePos = {x = 0, y = 0} -- 第一个 entrynode 的坐标 之后依次根据 enrtynode 的大小进行排序
    self.m_fSacle = 1
    -- 全局的一个缩放变量
    self.m_bOpenProgress = false -- entry node 是否有处于展开的
    self.m_showIndex = 0
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

    self.m_buttonUp = self:findChild("Button_up")
    self.m_buttonDown = self:findChild("Button_down")
    self.m_bMoveAction = false
    self.m_currFirstNodeIndex = 1 -- 当前左边条第一个节点的 index
    -- self:addClick(self.m_buttonUp)
    -- self:addClick(self.m_buttonDown)

    -- * self.m_fSacle
    local offset = {x = 0, y = 100}
    if self:getIsSpecialScale() then -- ipad 适配相关
        if globalData.slotRunData.isPortrait == true then
            -- offset.x = offset.x
            offset.y = offset.y - 20
        else
            -- offset.x = offset.x
            offset.y = offset.y - 20
        end
        self:setScale(0.75)
        self.m_padSacle = 0.75
    end

    if globalData.slotRunData.isPortrait == true then
        -- self:setPosition(20 + padOffset.x , display.height * 6 / 7  + padOffset.y)
        self:setPosition(self.m_layerDis + offset.x, globalData.gameLobbyHomeNodePos.y - offset.y)
    else
        -- self:setPosition(20 + util_getBangScreenHeight() + padOffset.x, display.height * 6 / 7 + padOffset.y)
        self:setPosition(self.m_layerDis + util_getBangScreenHeight() + offset.x, globalData.gameLobbyHomeNodePos.y - offset.y)
    end
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle")
        end,
        60
    )

    local entryNodeMoveLeftPos = cc.p(self:getPositionX(), self:getPositionY())
    -- print("------ entryNodeMoveLeftPos x = "..entryNodeMoveLeftPos.x.." entryNodeMoveLeftPos y = "..entryNodeMoveLeftPos.y)
    -- 动态创建新的 clipnode
    self.m_clipNode = cc.ClippingRectangleNode:create({x = 0, y = 0, width = 0, height = 0})
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0.5))
    self:findChild("Node_1"):addChild(self.m_clipNode)
    self.m_clipNode:setPositionX(-2)

    self.m_clipNodeHeight = 0
    self.m_droplayerHeight = 0
end

function LeftFrameLayer:addDragFrameLayer()
    if self.m_openDrag == false then
        return
    end

    if self.m_droplayer then
        self.m_droplayer:removeFromParent()
        self.m_droplayer = nil
    end
    self.m_droplayer = util_createView("views.leftFrame.DragFrameLayer", self)
    self:addChild(self.m_droplayer)
end

function LeftFrameLayer:getIsSpecialScale()
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

function LeftFrameLayer:onEnter()
    self.m_oldZOrder = self:getZOrder()

    --升级消息
    gLobalNoticManager:addObserver(
        self,
        function(self)
            self:addNewUserDragGuide(true)
        end,
        ViewEventType.SHOW_LEVEL_UP
    )

    gLobalNoticManager:addObserver(
        self,
        function(self)
            if self.m_guideQiPao then
                self.m_guideQiPao:removeFromParent()
                self.m_guideQiPao = nil
            end
            if self.m_guideTips then
                self.m_guideTips:removeFromParent()
                self.m_guideTips = nil
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_GUIDE_REMOVE
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
end

function LeftFrameLayer:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LeftFrameLayer:updateDropFrameLayer(size)
    --2021-04-22 这里没必要 *padScale 因为是直接add到 self上的,self在pad下已经有缩放
    if self.m_droplayer then
        local newSize = {width = size.width * self.m_padSacle, height = size.height * self.m_padSacle}
        local pos = cc.p(0, -newSize.height)
        self.m_droplayer:setPosition(pos)
        self.m_droplayer:updateSize(newSize, "left_top")
        self.m_droplayer:setLayerRect(pos, newSize)
    end
end

function LeftFrameLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_up" then
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        self:moveEntryNode(DirectionTag.UP)
    elseif name == "Button_down" then
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        self:moveEntryNode(DirectionTag.DOWN)
    elseif name == "Panel_1" then
    end
end

-- 把节点添加到这里面来
function LeftFrameLayer:addEntryNode(node)
    if node == nil then
        return
    end

    local activityName = node:getName()
    print("activityName  == " .. activityName)

    self.m_clipNode:addChild(node)
    node:setZOrder(9999 - self.m_index)
    self.m_entryNode[self.m_index] = node

    node:setName(activityName)
    self.m_index = self.m_index + 1
end

function LeftFrameLayer:removeEntryNode(activityName)
    -- print("清理-------- activityName  = "..activityName)
    -- self.m_entryNode[activityName] = false
    self.m_removeFlag = true
    self.m_index = self.m_index - 1
    self.m_maxSize = {widht = 0, height = 0}

    for i = 1, #self.m_entryNode do
        if activityName == self.m_entryNode[i]:getName() then
            table.remove(self.m_entryNode, i)
            break
        end
    end

    -- 如果要删除的node 点 不是正在展开的点。 则不能重置信息
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        local node = self.m_realEntryNodeInfo[i].node:getChildByTag(10)
        local bOpen = false
        if node.getEntryNodeOpenState then
            bOpen = node:getEntryNodeOpenState()
        end

        if self.m_realEntryNodeInfo[i].node:getName() == activityName then
            if bOpen then
                self.m_bOpenProgress = false
            end
            table.remove(self.m_realEntryNodeInfo, i)
        end
    end

    -- if self.m_bOpenProgress then
    self:changeBgPanelSize(false) -- 当前有展开的情况下 删了节点要重新计算bg的长度
    -- end
    -- print("清理-------- self.m_maxSize.height  = "..self.m_maxSize.height)
end

function LeftFrameLayer:adjustMaxSizeWidth(newSize)
    if self.m_maxSize.widht < newSize.widht then
        self.m_maxSize.widht = newSize.widht
    end
end

function LeftFrameLayer:adjustMaxSize(newSize)
    -- 计算size 宽度默认用最大的入口的宽度,长度累加
    if self.m_maxSize.widht < newSize.widht then
        self.m_maxSize.widht = newSize.widht
    end

    self.m_maxSize.height = self.m_maxSize.height + newSize.height
end

function LeftFrameLayer:sortEntryNode(index, name, size)
    -- print("sortEntryNode ---- name = "..name)

    for i = 1, table.nums(self.m_entryNode) do
        if self.m_entryNode[i]:getName() == name then
            local data = {
                node = clone(self.m_entryNode[i]),
                size = size,
                pos = cc.p(0, 0),
                zorder = self.m_entryNode[i]:getZOrder()
            }
            data.node:setZOrder(9999 - index)
            self.m_realEntryNodeInfo[index] = data
            break
        end
    end

    self:changeBgStatue()
end

function LeftFrameLayer:changeBgPanelSize(changeCilp)
    self.m_maxSize = {widht = 0, height = 0}

    --2021-04-25 这里应该分两步计算
    local size = nil
    --1.先计算出背景长度
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        size = self.m_realEntryNodeInfo[i].size
        if i > self.PAGE_MAX_NODE then -- 大于一页限制个数的时候 不再计算高度了
            self:adjustMaxSizeWidth(size)
        else
            -- 1. 根据入口大小计算 九宫格大小
            self:adjustMaxSize(size)
            -- 从第二个开始需要加上入口间距
            self.m_maxSize.height = self.m_maxSize.height + (i > 1 and self.m_nodeDis or 0)
        end
    end

    --2.设置背景大小
    -- 需要考虑当前是否需要上下留边 + 当前是否超过四个节点 有按钮出现
    local downDis = self.EXTRA_INFO.downDis
    if table.nums(self.m_realEntryNodeInfo) > self.PAGE_MAX_NODE then
        downDis = self.EXTRA_INFO.downDis + self.m_buttonUp:getContentSize().height/2
    end
    -- 上下留边数值
    self.m_maxSize.height = self.m_maxSize.height + self.EXTRA_INFO.topDis + downDis

    local height = self.m_maxSize.height * self.m_fSacle
    local panelHeight = self.m_maxSize.height - self.m_buttonUp:getContentSize().height
    -- 设置大小
    self.m_bg:setContentSize(self.m_maxSize.widht, height)
    self.m_panel:setContentSize(self.m_maxSize.widht, panelHeight)
    self.m_panelBG:setContentSize(self.m_maxSize.widht, panelHeight)

    -- 如果当前需要改变拆裁切区域大小的情况
    if changeCilp then
        -- 裁切区域大小不考虑留边的情况 需要裁减掉
        local newHeight = (self.m_maxSize.height - downDis - self.EXTRA_INFO.topDis) * self.m_fSacle
        self.m_clipNodeHeight = newHeight
        self:updateClipNode(newHeight)
        self:updateGuideUI({width = self.m_maxSize.widht, height = newHeight})
        -- 拖动层需要单独计算
        self.m_droplayerHeight = height
        self:updateDropFrameLayer({width = self.m_maxSize.widht, height = self.m_droplayerHeight})
    end

    --3.计算出第一个 entry node 应该摆放在哪里
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        if i > self.PAGE_MAX_NODE then -- 大于一页限制个数的时候 不再计算了
            break
        end
        -- 2.计算出第一个 entry node 应该摆放在哪里
        -- local offset = dis -- 补充一个留底距离
        self.m_firstEntryNodePos.x = self.m_maxSize.widht / 2
        size = self.m_realEntryNodeInfo[i].size
        if i == 1 then
            local topDis = (size.height / 2) + (self.EXTRA_INFO.topDis + downDis) - self.EXTRA_INFO.topDis
            self.m_firstEntryNodePos.y = topDis * self.m_fSacle
        else
            self.m_firstEntryNodePos.y = self.m_firstEntryNodePos.y + (size.height + self.m_nodeDis) * self.m_fSacle
        end
    end
end

function LeftFrameLayer:changeNodePos()
    if table.nums(self.m_realEntryNodeInfo) > 0 then
        -- 只有在当前有节点的情况下 才创建拖拽
        self:addDragFrameLayer()
        self:addNewUserDragGuide()
    end
    self:changeBgPanelSize(true)
    self.m_showIndex = 0 -- 重置下标
    self.m_currFirstNodeIndex = 1 -- 重置下标
    -- print("++++--5555555------ self.m_bg.height  = "..self.m_bg:getContentSize().height)

    -- 3.对所有的 entry node 进行位置摆放
    local lastNodePos = nil
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local size = self.m_realEntryNodeInfo[i].size

        local node = self.m_realEntryNodeInfo[i].node
        local newPos = cc.p(self.m_firstEntryNodePos.x, self.m_firstEntryNodePos.y)
        -- newPos = cc.p(newPos.x + self.m_bg:getPositionX() ,newPos.y -  self.m_bg:getContentSize().height /2 ) -- 锚点在 (0,0.5)
        newPos = cc.p(newPos.x + self.m_bg:getPositionX(), newPos.y - self.m_bg:getContentSize().height) --锚点在 (0,1)
        if i == 1 then
            node:setPosition(newPos)
        else
            local lastSize = self.m_realEntryNodeInfo[i - 1].size
            local yPos = (lastNodePos.y - (lastSize.height / 2 + self.m_nodeDis + size.height / 2) * self.m_fSacle)
            newPos = cc.p(self.m_firstEntryNodePos.x + self.m_bg:getPositionX(), yPos)
            node:setPosition(newPos)
        end
        lastNodePos = cc.p(node:getPosition())
        self.m_realEntryNodeInfo[i].pos = newPos
        node:stopAllActions()
        node:setScale(self.m_fSacle)
        node:setVisible(true)
        if i > self.PAGE_MAX_NODE then -- 大于4个的时候 不再计算了
            node:setVisible(false)
        else
            self.m_showIndex = self.m_showIndex + 1 -- 计算当前展示了几个node
        end
        -- print("+++-- 5555 ------- newPos .x = "..newPos.x.. "  newPos . y = "..newPos.y)
    end

    self:changeArrowStatus()

    local bOpen = false
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        local node = self.m_realEntryNodeInfo[i].node
        if node:getChildByTag(10).getEntryNodeOpenState then
            bOpen = node:getChildByTag(10):getEntryNodeOpenState()
        end
        if bOpen then
            -- break
            local callShowOtherEntryNode =
                cc.CallFunc:create(
                function()
                end
            )
            if self.m_saveName and node:getName() == self.m_saveName then
                self:moveClickEntryNode(self.m_realEntryNodeInfo[i], "hide", i, self.m_saveFunc, callShowOtherEntryNode)
                self.m_saveName = nil
                self.m_saveFunc = nil
                self.m_bNeedAddMoveAction = true
                print("---------- 当前有打开的节点 需要播放一次动画")
            end
        else
            if self.m_bNeedAddMoveAction == true or (self.m_saveName and self.m_saveFunc) then
                print("---------- 当前有打开的节点 不是打开的节点需要隐藏 name = " .. node:getName())
                node:setVisible(false)
            end
        end
    end

    if bOpen == false then
        if self.m_droplayer then
            -- 发现长度节点位置改变 需要通知拖拽层进行一次位置计算
            local data = {
                node = self,
                layerSize = {width = self.m_maxSize.widht * self.m_padSacle, height = self.m_maxSize.height * self.m_fSacle * self.m_padSacle},
                newEntryNode = true
            }
            self.m_droplayer:checkOpenProgress(data)
        end
    end

    --2021-04-23 需要通知入口下的附属节点当前 入口的显示状态
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_UPDATE_ENTRY_VISIBLE)
end

function LeftFrameLayer:changeBgStatue()
    if #self.m_realEntryNodeInfo > 1 then
        self.m_bg:setVisible(true)
        self.m_bg:setOpacity(255)
    else
        self.m_bg:setVisible(false)
        self.m_bg:setOpacity(0)
    end
end

function LeftFrameLayer:changeArrowStatus()
    local pos = cc.p(self.m_bg:getPositionX() + self.m_bg:getContentSize().width / 2, -self.m_bg:getContentSize().height)
    self.m_buttonUp:setPosition(cc.p(pos.x, pos.y))
    self.m_buttonDown:setPosition(cc.p(pos.x, pos.y))
    --csc 2021-10-21 12:13:34 fixbug 刷新列表后没有把点击状态还原
    self.m_buttonUp:setEnabled(true)
    self.m_buttonDown:setEnabled(true)

    if self.m_bOpenProgress or #self.m_realEntryNodeInfo <= self.PAGE_MAX_NODE then
        self.m_buttonUp:setVisible(false)
        self.m_buttonDown:setVisible(false)
        return
    end

    -- 用来判断up行为
    if self.m_showIndex <= self.PAGE_MAX_NODE then --当前展示index 小于最大个数 证明已经回到了第一页
        self.m_buttonUp:setVisible(false)
        if table.nums(self.m_realEntryNodeInfo) > self.PAGE_MAX_NODE then -- 如果当前总数量比 一页最大个数多,则显示向下箭头
            self.m_buttonDown:setVisible(true)
        end
        return
    end

    -- 用来判断 down 行为
    -- self.m_showIndex  在调用这个方法之前 都会重新计算成最新的值
    local moveNum = table.nums(self.m_realEntryNodeInfo) - self.m_showIndex -- 得出当前应该移动的个数
    if moveNum == 0 then -- 没有需要再移动的个数了 证明已经到底了。
        self.m_buttonUp:setVisible(true)
        self.m_buttonDown:setVisible(false)
    else -- 还没到底 继续显示向下箭头
        self.m_buttonUp:setVisible(false)
        self.m_buttonDown:setVisible(true)
    end
end

function LeftFrameLayer:updateClipNode(height)
    if height then
        self.m_clipNode:setClippingRegion(
            {
                x = -display.width,
                y = -height - (self.EXTRA_INFO.topDis or 0),
                width = display.width * 2,
                height = height
            }
        )
    end
end

function LeftFrameLayer:updateEntryNodeVisible()
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        if i >= (self.m_showIndex - self.PAGE_MAX_NODE + 1) and i <= self.m_showIndex then
            self.m_realEntryNodeInfo[i].node:setVisible(true)
            -- print("updateEntryNodeVisible --- i  显示"..i)
            self.m_realEntryNodeInfo[i].node:setVisible(true)
        else
            -- print("updateEntryNodeVisible --- i  隐藏"..i)
            self.m_realEntryNodeInfo[i].node:setVisible(false)
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_UPDATE_ENTRY_VISIBLE)
end

function LeftFrameLayer:checkRealEntryNode()
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
function LeftFrameLayer:showEntryNodeProgressForName(name, func)
    print("------------LeftFrameLayer:showEntryNodeProgressForName ")
    self.m_bOpenProgress = true
    self.m_bTouchFlag = true
    self.m_panel:setSwallowTouches(true)
    self:changeArrowStatus()
    self.m_currProgressName = name
    -- local callfunC = cc.CallFunc:create(function(  )
    --     for i = 1 , table.nums(self.m_realEntryNodeInfo) do
    --         if self.m_realEntryNodeInfo[i].node:getName() ~= name then
    --             self.m_realEntryNodeInfo[i].node:setVisible(false)
    --         else
    --             self:moveClickEntryNode(self.m_realEntryNodeInfo[i],"hide",i,func)
    --         end
    --     end
    --  end )

    -- -- self.m_bg:runAction(cc.Sequence:create(cc.FadeOut:create(0.5),callfunC))
    -- -- self.m_bg:runAction(cc.FadeOut:create(0.2))
    -- self.m_bg:runAction(cc.Spawn:create(cc.FadeOut:create(0.2),callfunC))

    -- 先把其他node 和bg 消失 在上条上去

    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        if self.m_realEntryNodeInfo[i].node:getName() ~= name then
            self.m_realEntryNodeInfo[i].node:setVisible(false)
        else
            -- 2021年04月21日 如果当前节点要被展开,但是位置处于第四个以后,默认是不显示的,要再这里显示一下
            if not self.m_realEntryNodeInfo[i].node:isVisible() then
                self.m_realEntryNodeInfo[i].node:setVisible(true)
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
    -- local callShowOtherEntryNode = cc.CallFunc:create( function (  )
    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        if self.m_realEntryNodeInfo[i].node:getName() == name then
            -- util_changeNodeParent(self:findChild("Node_1"),self.m_realEntryNodeInfo[i].node,1)

            self:moveClickEntryNode(self.m_realEntryNodeInfo[i], "hide", i, func, callShowOtherEntryNode)
            break
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

    -- self.m_bg:runAction(cc.Sequence:create(callShowOtherEntryNode,1))
end

-- 根据传入的 活动入口名字 , 处理收回状态
function LeftFrameLayer:hideEntryNodeProgressForName(name, func)
    self.m_bOpenProgress = false
    self.m_currProgressName = ""
    -- local callfunC = cc.CallFunc:create(function(  )
    --     for i = 1 , table.nums(self.m_realEntryNodeInfo) do
    --         if self.m_realEntryNodeInfo[i].node:getName() ~= name then
    --             self.m_realEntryNodeInfo[i].node:setVisible(true)
    --         else
    --             self:moveClickEntryNode(self.m_realEntryNodeInfo[i],"show",i,func)
    --         end
    --         -- self.m_realEntryNodeInfo[i].node:setVisible(true)
    --         -- -- 设置回原坐标
    --         -- self:moveClickEntryNode(self.m_realEntryNodeInfo[i],"show",i,func)
    --     end
    --  end )

    -- 上去之后再让 背景和其他node显示出来

    local callShowOtherEntryNode =
        cc.CallFunc:create(
        function()
            for i = 1, table.nums(self.m_realEntryNodeInfo) do
                if self.m_realEntryNodeInfo[i].node:getName() ~= name then
                    self.m_realEntryNodeInfo[i].node:setVisible(true)
                end
            end
            self.m_bg:setOpacity(255)
            self:updateEntryNodeVisible()
            self:changeArrowStatus()
        end
    )

    for i = 1, table.nums(self.m_realEntryNodeInfo) do
        if self.m_realEntryNodeInfo[i].node:getName() == name then
            -- util_changeNodeParent(self.m_clipNode,self.m_realEntryNodeInfo[i].node,1)
            self:moveClickEntryNode(self.m_realEntryNodeInfo[i], "show", i, func, callShowOtherEntryNode)
            break
        end
    end
end

function LeftFrameLayer:delayShowEntryNode(name, func)
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
function LeftFrameLayer:moveClickEntryNode(entryNode, action, index, func, callback)
    -- 同时需要将所有的pushviews 隐藏掉
    self:hideAllPushViews()

    -- 播放动画
    self:moveClickEntryNodeV4(entryNode, action, index, func, callback)
end

function LeftFrameLayer:moveClickEntryNodeV1(entryNode, action, index, func, callback)
    local node = entryNode.node
    local sizeInfo = {widht = 120, height = 90, launchHeight = 500}
    if node:getChildByTag(10).getPanelSize ~= nil then
        sizeInfo = node:getChildByTag(10):getPanelSize()
    end
    -- v1 版本   移到中心点
    -- X = 节点展开后的总长度 一半
    -- Y = 节点本身的高度 Y + 节点本身的高度的一半
    -- Z = X - Y 节点需要偏移的距离
    if action == "hide" then
        if sizeInfo.launchHeight ~= nil and sizeInfo.launchHeight > 0 then -- 如果本身没有伸展长度 不用计算
            local nodeY = node:getPositionY()
            local offsetZ = sizeInfo.launchHeight / 2 * self.m_fSacle - nodeY - sizeInfo.height / 2
            local newPos = cc.p(node:getPositionX(), nodeY + offsetZ)
            print("偏移量---- offsetZ " .. offsetZ)
            print("新坐标---- Y  " .. nodeY + offsetZ)

            -- 两种方案  - moveTo 或者直接 setPos
            -- node:setPosition( newPos)
            node:runAction(cc.MoveTo:create(0.3, newPos))
        end
    elseif action == "show" then
        local originPos = entryNode.pos
        node:runAction(cc.MoveTo:create(0.3, originPos))
    end
end

function LeftFrameLayer:moveClickEntryNodeV2(entryNode, action, index, func, callback)
    local node = entryNode.node
    local sizeInfo = {widht = 120, height = 90, launchHeight = 500}
    if node:getChildByTag(10).getPanelSize ~= nil then
        sizeInfo = node:getChildByTag(10):getPanelSize()
    end
    -- v2 版本 展开的entrynode 移到第一格
    local firstNode = self.m_realEntryNodeInfo[1].node
    local callfunC2 =
        cc.CallFunc:create(
        function()
            self.m_panel:setSwallowTouches(false)
            printInfo("------ 设置回来 ---- -false")
            if func then
                func()
            end
        end
    )
    if action == "hide" then
        if index > 1 then -- 第一格格子的话保持不动
            local newPos = cc.p(firstNode:getPosition())
            local nodepos = cc.p(node:getPosition())
            node:setZOrder(node:getZOrder() + 100)
            node:runAction(cc.Sequence:create(cc.MoveTo:create(0.3, newPos), callfunC2))
        else
            node:runAction(callfunC2)
        end
    elseif action == "show" then
        if index > 1 then -- 第一格格子的话保持不动
            local originPos = entryNode.pos
            local callfunC =
                cc.CallFunc:create(
                function()
                    node:setZOrder(entryNode.zorder)
                end
            )
            node:runAction(cc.Sequence:create(cc.MoveTo:create(0.3, originPos), callfunC, callfunC2))
        else
            node:runAction(cc.Sequence:create(callfunC, callfunC2))
        end
    end
end

function LeftFrameLayer:moveClickEntryNodeV3(entryNode, action, index, func, callback)
    local node = entryNode.node
    local sizeInfo = {widht = 120, height = 90, launchHeight = 500}
    if node:getChildByTag(10).getPanelSize ~= nil then
        sizeInfo = node:getChildByTag(10):getPanelSize()
    end
    -- v3 版本
    -- 展开：左边条上拉  一定时间后（需要展示的entrynode 展开的时间 ）  左边条下拉
    -- 反之  entrynode 收回按钮之后 左边条直接上拉 间隔一定时
    local callfunC2 =
        cc.CallFunc:create(
        function()
            self.m_panel:setSwallowTouches(false)

            print("------ 设置回来 ---- -false")
            if func then
                func()
            end
        end
    )

    local firstNode = self.m_realEntryNodeInfo[1].node
    local offsetY = 0 --- 后续补差值
    local newPos = cc.p(firstNode:getPosition())
    if index > 1 then
        offsetY = offsetY + sizeInfo.launchHeight + (newPos.y - node:getPositionY())
    else
        offsetY = offsetY + sizeInfo.height / 2
    end

    local nodeFunc =
        cc.CallFunc:create(
        function()
            if index > 1 then -- 如果不是第一个块的话 需要先将展开的块设置到第一个块上
                if action == "hide" then
                    node:setPosition(newPos)
                elseif action == "show" then
                    local originPos = entryNode.pos
                    node:setPosition(originPos)
                end
            end
            local newHeight = self.m_clipNodeHeight
            if self.m_bOpenProgress then
                local height = sizeInfo.launchHeight
                if sizeInfo.scale then
                    height = height * sizeInfo.scale
                end
                newHeight = height * self.m_fSacle
            end
            self:updateClipNode(newHeight)
            self:updateDropFrameLayer({width = self.m_maxSize.widht, height = newHeight})
            self:updateGuideUI({width = self.m_maxSize.widht, height = newHeight})
        end
    )
    -- 左边条上升 下降高度应该为 需要展开的node长度
    local entryNodeMoveY = sizeInfo.launchHeight + offsetY
    local entryNodeMoveUpPos = cc.p(self:getPositionX(), self:getPositionY() + entryNodeMoveY)
    local actMoveUp = cc.MoveTo:create(0.3, entryNodeMoveUpPos)

    local newPosDown = cc.p(self:getPositionX(), self:getPositionY())
    local actMoveDown = cc.MoveTo:create(0.3, newPosDown)

    local delay = cc.DelayTime:create(0)
    self:runAction(cc.Sequence:create(actMoveUp, delay, nodeFunc, callback, actMoveDown, callfunC2))
end

function LeftFrameLayer:moveClickEntryNodeV4(entryNode, action, index, func, callback)
    local node = entryNode.node
    local sizeInfo = {widht = 120, height = 90, launchHeight = 500}
    if node:getChildByTag(10).getPanelSize ~= nil then
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
                self.m_droplayer:checkOpenProgress(data)
            elseif self.m_bOpenProgress == false and self.m_bNeedAddMoveAction then
                self.m_bNeedAddMoveAction = false
                data.newEntryNode = true
                self.m_droplayer:checkOpenProgress(data)
            end
            -- csc 2021-09-04 17:57:36 更新最新坐标
            self.m_currNewPos = cc.p(self:getPosition())
        end
    )
    local offsetX = 100 --- 后续补差值
    --2021年04月21日 如果当前展示的是从下方移动上来的小块,那么当前左边条的第一个节点需要重新计算
    local firstNode = self.m_realEntryNodeInfo[self.m_currFirstNodeIndex].node
    local newPos = cc.p(firstNode:getPosition())
    local nodeFunc =
        cc.CallFunc:create(
        function()
            -- 更新一些layer的大小
            if index > 1 then -- 如果不是第一个块的话 需要先将展开的块设置到第一个块上
                if action == "hide" then
                    node:setPosition(newPos)
                elseif action == "show" then
                    local originPos = entryNode.pos
                    node:setPosition(originPos)
                end
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
            self:updateGuideUI({width = self.m_maxSize.widht, height = newHeight})
            -- 拖动层需要单独计算
            self:updateDropFrameLayer({width = self.m_maxSize.widht, height = dropHeight})
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
function LeftFrameLayer:getIsOpenProgress(_entryNodeName)
    if _entryNodeName then
        if self.m_currProgressName == _entryNodeName then
            return true
        else
            return false
        end
    end
    return self.m_bOpenProgress
end

-- 移动
function LeftFrameLayer:moveEntryNode(direction)
    -- 移动的时候不允许点击
    self.m_panel:setSwallowTouches(true) 
    self.m_bMoveAction = true
    self.m_panel:setScaleY(1.2)

    -- 同时需要将所有的pushviews 隐藏掉
    self:hideAllPushViews()

    local callback =
        cc.CallFunc:create(
        function()
            self:changeArrowStatus()
            self:updateEntryNodeVisible()
            self.m_panel:setSwallowTouches(false)
            self.m_bMoveAction = false
            self.m_panel:setScaleY(1)
        end
    )

    local nodeRunAction = function(node, i, action1)
        local actionList = {}
        actionList[#actionList + 1] = action1
        if i == table.nums(self.m_realEntryNodeInfo) then
            actionList[#actionList + 1] = callback
        end
        node:runAction(cc.Sequence:create(actionList))
        node:setVisible(true)
    end

    if direction == DirectionTag.UP then
        local moveNum = self.m_showIndex - self.PAGE_MAX_NODE -- 得出当前应该移动的个数
        if moveNum > self.PAGE_MAX_NODE then
            moveNum = self.PAGE_MAX_NODE -- 如果要移动的个数超过了最大个数 。则移动最大个数
        end

        -- 移动总距离
        local moveDis = 0
        for i = 1, moveNum do
            local size = self.m_realEntryNodeInfo[self.m_showIndex + (1 - i)].size
            moveDis = moveDis + ((size.height + self.m_nodeDis) * self.m_fSacle)
        end

        self.m_showIndex = self.m_showIndex - moveNum
        self.m_currFirstNodeIndex = self.m_currFirstNodeIndex - moveNum
        for i = 1, table.nums(self.m_realEntryNodeInfo) do
            local node = self.m_realEntryNodeInfo[i].node
            local newPos = cc.p(node:getPositionX(), node:getPositionY() - moveDis)
            local move = cc.MoveTo:create(0.2 * moveNum, newPos)
            --更新pos 坐标
            self.m_realEntryNodeInfo[i].pos = newPos
            nodeRunAction(node, i, move)
        end

        self.m_buttonUp:setEnabled(false)
        self.m_buttonDown:setEnabled(true)
    elseif direction == DirectionTag.DOWN then
        -- 需要计算一下当前剩余几个没有展示。
        -- 计算当前每个块需要移动的距离
        local moveNum = table.nums(self.m_realEntryNodeInfo) - self.m_showIndex -- 得出当前应该移动的个数
        if moveNum > self.PAGE_MAX_NODE then
            moveNum = self.PAGE_MAX_NODE -- 如果要移动的个数超过了最大个数 。则移动最大个数
        end

        -- 移动总距离
        local moveDis = 0
        for i = 1, moveNum do
            local size = self.m_realEntryNodeInfo[self.m_showIndex + i].size
            moveDis = moveDis + ((size.height + self.m_nodeDis) * self.m_fSacle)
        end

        self.m_showIndex = self.m_showIndex + moveNum
        self.m_currFirstNodeIndex = self.m_currFirstNodeIndex + moveNum
        for i = 1, table.nums(self.m_realEntryNodeInfo) do
            local node = self.m_realEntryNodeInfo[i].node
            local newPos = cc.p(node:getPositionX(), node:getPositionY() + moveDis)
            local move = cc.MoveTo:create(0.2 * moveNum, newPos)
            nodeRunAction(node, i, move)
            --更新pos 坐标
            self.m_realEntryNodeInfo[i].pos = newPos
        end
        self.m_buttonUp:setEnabled(true)
        self.m_buttonDown:setEnabled(false)
    end
end

--[[
    拖拽条调用返回事件
]]
function LeftFrameLayer:getOldZOrder()
    if self.m_oldZOrder then
        return self.m_oldZOrder
    end
    return GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
end
function LeftFrameLayer:changePanleSwallow(status)
    --如果当前正在移动的话
    if self.m_bMoveAction then
        return
    end
    self.m_panel:setSwallowTouches(status)
    if status then
        performWithDelay(
            self,
            function()
                self.m_panel:setSwallowTouches(false)
            end,
            0.2
        )
    end
end

function LeftFrameLayer:changeStopDirection(direction)
    if direction then
        self.m_layerDirction = direction
        self.m_oldPos = nil

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME, direction)
    end
end

function LeftFrameLayer:checkOpenProgressResult(oldPos)
    if oldPos then
        self.m_oldPos = oldPos
    end
end

function LeftFrameLayer:getLayerDis()
    -- 返回悬浮条跟边界的距离
    return self.m_layerDis
end

--[[
    @desc: 更新拖拽之后的最新位置
]]
function LeftFrameLayer:updateMoveEndPos(_pos)
    self.m_currNewPos = _pos
end

-- 添加引导
function LeftFrameLayer:addNewUserDragGuide(levelup)
    --
    local curLevel = globalData.userRunData.levelNum
    if curLevel < globalData.constantData.NOVICE_LEFT_FRAME_GUIDE_LEVEL then
        return
    end
    -- 得到状态
    -- local bQPflag = gLobalDataManager:getBoolByField("leftFrameGuideQP", false) -- 气泡引导
    -- local bYDflag = gLobalDataManager:getBoolByField("leftFrameGuideHYD", false) -- 小手引导

    local bflag = gLobalDataManager:getBoolByField("leftFrameGuide", false) -- 引导

    -- if bflag then -- 如果在没出现之前就已经互动过 这套引导也不能出现
    --     if bQPflag == false then
    --         gLobalDataManager:setBoolByField("leftFrameGuideQP", true)
    --     end
    --     return
    -- end

    -- 小手npc 引导 （只要玩家没有拖动过,就可以无限次出现）
    -- if bYDflag == false then
    --     if self.m_guideTips == nil then
    --         self.m_guideTips = util_createView("views.leftFrame.LeftFrameGuideTips")
    --         if self.m_guideTips then
    --             self:findChild("Node_1"):addChild(self.m_guideTips)
    --             self.m_guideTips:setZOrder(1)
    --         end
    --     end
    -- end

    --气泡引导如果没弹出过的话 需要弹出(全局只展示一次)
    if bflag == false then
        if self.m_guideQiPao == nil then
            self.m_guideQiPao = util_createView("views.leftFrame.LeftFrameGuideQiPao")
            if self.m_guideQiPao then
                self:findChild("Node_1"):addChild(self.m_guideQiPao)
                self.m_guideQiPao:setZOrder(2)
            end
        end
        if self.m_guideTips == nil then
            self.m_guideTips = util_createView("views.leftFrame.LeftFrameGuideTips")
            if self.m_guideTips then
                self:findChild("Node_1"):addChild(self.m_guideTips)
                self.m_guideTips:setZOrder(1)
            end
        end
    end

    -- 只有升级的这一次才计算坐标
    if levelup and self.m_guideSizePos then
        self:updateGuideUI(self.m_guideSizePos)
    end
end

function LeftFrameLayer:updateGuideUI(size)
    self.m_guideSizePos = size

    if self.m_guideQiPao then
        local newSize = {width = size.width * self.m_padSacle, height = size.height * self.m_padSacle}
        local pos = cc.p(newSize.width / 2, -newSize.height / 2)
        self.m_guideQiPao:setPosition(pos)
    end
    if self.m_guideTips then
        local newSize = {width = size.width * self.m_padSacle, height = size.height * self.m_padSacle}
        local pos = cc.p(newSize.width / 2, -newSize.height / 2)
        self.m_guideTips:setPosition(pos)
    end
end

-- 提供外部接口 添加在遮罩层之上的气泡等不能被裁切的csb
function LeftFrameLayer:addPushViews(_entryNodeName, _pushRootPos, _createCsbPath, _pushViewName)
    if self:getPushViews(_entryNodeName, _pushViewName) then
        -- 先将节点删除
        self:removePushViews(_entryNodeName, _pushViewName)
    end
    -- 先将节点找出
    local pushNode = nil

    for i = 1, table.nums(self.m_entryNode) do
        if self.m_entryNode[i]:getName() == _entryNodeName then
            pushNode = self.m_entryNode[i]
            break
        end
    end

    if pushNode and pushNode:getChildByTag(10).getPushViewNode then
        local posForLeftFrame = self:findChild("Node_1"):convertToNodeSpace(_pushRootPos)
        util_nextFrameFunc(
            function()
                if tolua.isnull(self) then
                    -- bugly fix:[[string "views/leftFrame/LeftFrameLayer.luac"]:1117: attempt to call method 'findChild' (a nil value)]
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
function LeftFrameLayer:getPushViews(_entryNodeName, _pushViewName, _newRootPos)
    local node = self:getEntryNode(_entryNodeName)
    if not node or not node:isVisible() then -- 如果当前节点没有展示,不返回所属的pushview
        return nil
    end

    if next(self.m_tablePushViews) then
        -- 获得活动入口所有创建出来的弹窗集合
        local pushViewsTable = self.m_tablePushViews[_entryNodeName]
        if pushViewsTable ~= nil and next(pushViewsTable) then
            local pushViews = pushViewsTable[_pushViewName]
            if _newRootPos then
                --如果有新传入的坐标需要更新
                local posForLeftFrame = self:findChild("Node_1"):convertToNodeSpace(_newRootPos)
                pushViews:setPosition(posForLeftFrame)
            end
            return pushViews
        end
    end
    return nil
end

function LeftFrameLayer:removePushViews(_entryNodeName, _pushViewName)
    local pushViewsTable = self.m_tablePushViews[_entryNodeName]
    if pushViewsTable ~= nil and next(pushViewsTable) then
        local pushViews = pushViewsTable[_pushViewName]
        pushViews:removeFromParent()
        pushViewsTable[_pushViewName] = nil
    end
end

function LeftFrameLayer:hideAllPushViews()
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
function LeftFrameLayer:getIsProgressNode(_entryNodeName)
    if self.m_currProgressName == _entryNodeName then
        return true
    end
    return false
end

function LeftFrameLayer:getLeftFrameDirection()
    return self.m_layerDirction
end

-- 获得活动节点
function LeftFrameLayer:getEntryNode(activityName)
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        if self.m_realEntryNodeInfo[i].node:getName() == activityName then
            local node = self.m_realEntryNodeInfo[i].node:getChildByTag(10)
            return node
        end
    end
    return nil
end

function LeftFrameLayer:getEntryNodeVisible(_entryNodeName)
    local entryNode = nil
    for i = table.nums(self.m_realEntryNodeInfo), 1, -1 do
        if self.m_realEntryNodeInfo[i].node:getName() == _entryNodeName then
            entryNode = self.m_realEntryNodeInfo[i].node
            break
        end
    end
    return entryNode and entryNode:isVisible() or false
end

function LeftFrameLayer:getBtnDownWorldPos()
    return self.m_buttonDown:getParent():convertToWorldSpace(cc.p(self.m_buttonDown:getPosition()))
end



return LeftFrameLayer
