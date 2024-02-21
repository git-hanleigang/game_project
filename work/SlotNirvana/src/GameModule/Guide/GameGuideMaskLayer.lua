--[[
    引导遮罩
    author:{author}
    time:2022-06-16 12:10:48
]]
local GameGuideMaskLayer = class("GameGuideMaskLayer", BaseLayer)

function GameGuideMaskLayer:initDatas(ctrl)
    self:setLandscapeCsbName("Dialog/guide_layer_l.csb")
    self:setPortraitCsbName("Dialog/guide_layer_p.csb")
    -- 引导没有展示动画
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)

    self.m_ctrl = ctrl
end

function GameGuideMaskLayer:initView()
    self.m_root = self:findChild("root")
    self.m_root:setTouchEnabled(false)
    -- 创建裁剪节点
    local clip = self:createClipNode()
    self.m_nodeClip = clip
    self:addRootChild(clip)

    -- 抬升引导的节点
    self.m_nodeUplift = cc.Node:create()
    self.m_nodeUplift:setName("GuideMaskUpliftNode")
    self:addRootChild(self.m_nodeUplift, 1)
end

function GameGuideMaskLayer:maskShow(time, opacity)
    opacity = opacity or 192
    time = time or 0

    -- 创建遮罩，用于裁切，不添加触摸
    self.m_baseMaskUI = util_newMaskLayer(true)
    self.m_baseMaskUI:setName("GameGuideMask")
    if self.m_baseMaskUI then
        self.m_nodeClip:addChild(self.m_baseMaskUI, -1)
        if time > 0 then
            self.m_baseMaskUI:setOpacity(0)
            local actionList = {}
            actionList[#actionList + 1] = cc.FadeTo:create(time, opacity)
            local seq = cc.Sequence:create(actionList)
            self.m_baseMaskUI:runAction(seq)
        else
            self.m_baseMaskUI:setOpacity(opacity)
        end
    end
end

function GameGuideMaskLayer:onEnter()
    GameGuideMaskLayer.super.onEnter(self)
    -- 添加引导触摸层
    local touchLayer = self:createGuideTouchLayer()
    self:addRootChild(touchLayer, 10)
end

-- 创建裁切引导节点
function GameGuideMaskLayer:createClipNode()
    local clip = cc.ClippingNode:create()
    clip:setName("GuideMaskClipNode")
    -- 设置底板可见
    clip:setInverted(true)
    clip:setAlphaThreshold(0.1)
    self.m_nodeStencil = cc.Node:create()
    self.m_nodeStencil:setName("GuideMaskClipStencilNode")
    clip:setStencil(self.m_nodeStencil)
    return clip
end

-- 裁切引导节点
function GameGuideMaskLayer:getClipNode()
    if not tolua.isnull(self.m_nodeClip) then
        return self.m_nodeClip
    else
        return nil
    end
end

-- 裁切模版节点
function GameGuideMaskLayer:getClipStencilNode()
    if not tolua.isnull(self.m_nodeStencil) then
        return self.m_nodeStencil
    else
        return nil
    end
end

-- 抬升引导节点
function GameGuideMaskLayer:getUpliftNode()
    if not tolua.isnull(self.m_nodeUplift) then
        return self.m_nodeUplift
    else
        return nil
    end
end

-- 添加到裁切模版节点
function GameGuideMaskLayer:addToStencil(child, order)
    local _node = self:getClipStencilNode()
    if _node then
        _node:addChild(child, order or 0)
    end
end

function GameGuideMaskLayer:removeStencilChild(childNames)
    childNames = childNames or {}
    if #childNames > 0 then
        -- 移除指定子节点
    else
        local _node = self:getClipStencilNode()
        if _node then
            _node:removeAllChildren()
        end
    end
end

-- 添加到抬升节点
function GameGuideMaskLayer:addToUplift(child, order)
    local _node = self:getUpliftNode()
    if _node then
        _node:addChild(child, order or 0)
    end
end

function GameGuideMaskLayer:removeUpliftChild(childNames)
    childNames = childNames or {}
    if #childNames > 0 then
        -- 移除指定子节点
    else
        local _node = self:getUpliftNode()
        if _node then
            _node:removeAllChildren()
        end
    end
end

function GameGuideMaskLayer:getRootNode()
    return self.m_root
end

function GameGuideMaskLayer:addRootChild(child, order)
    if not child then
        return
    end

    if not tolua.isnull(self.m_root) then
        self.m_root:addChild(child, order or 0)
    end
end

function GameGuideMaskLayer:removeRootChild(childNames)
    childNames = childNames or {}
    if #childNames > 0 then
        -- 移除指定子节点
    else
        if not tolua.isnull(self.m_root) then
            self.m_root:removeAllChildren()
        end
    end
end

-- 更新步骤
function GameGuideMaskLayer:updateStepView(stepInfo)
    assert(stepInfo, "guide step info is nil!!!")
    self.m_stepInfo = stepInfo

    -- 添加步骤完成事件完成
    self:addStepCompleteEventListener(stepInfo)

    self:setShowBgOpacity(stepInfo:getOpacity())

    if self.m_baseMaskUI then
        self.m_baseMaskUI:setSwallowsTouches(false)
    end
end

-- 添加步骤完成事件监听
function GameGuideMaskLayer:addStepCompleteEventListener(stepInfo)
    if not stepInfo then
        return nil
    end

    local clpEventName = stepInfo:getCplEvent()
    if clpEventName ~= "" then
        local guideName = stepInfo:getGuideName()
        gLobalNoticManager:addObserver(
            self,
            function(params)
                gLobalNoticManager:removeObserver(self, clpEventName)
                -- 触发下一步引导
                self.m_ctrl:doNextGuideStep(guideName)
            end,
            clpEventName
        )
    end
end

-- 创建触摸层
-- 被抬升的节点不全应该响应触摸事件，所以吧遮罩和触摸层分离
function GameGuideMaskLayer:createGuideTouchLayer()
    local listen_layer = cc.Layer:create()
    listen_layer:setName("GuideTouchLayer")
    -- 注册单点触摸
    -- local dispatcher = cc.Director:getInstance():getEventDispatcher()
    local dispatcher = listen_layer:getEventDispatcher()
    --创建一个触摸监听(单点触摸）
    local listener = cc.EventListenerTouchOneByOne:create()

    -- 触摸开始
    local function onTouchBegan(touch, event)
        self:onTouchBegan(listener, touch, event)
        return true
    end

    -- 触摸移动
    local function onTouchMoved(touch, event)
        self:onTouchMoved(listener, touch, event)
    end

    -- 触摸取消
    local function onTouchCancelled(touch, event)
        self:onTouchCancelled(listener, touch, event)
    end

    -- 触摸结束
    local function onTouchEnded(touch, event)
        self:onTouchEnded(listener, touch, event)
    end

    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(onTouchCancelled, cc.Handler.EVENT_TOUCH_CANCELLED)

    -- 将listener和listen_layer绑定，放入事件委托中
    dispatcher:addEventListenerWithSceneGraphPriority(listener, listen_layer)

    return listen_layer
end

function GameGuideMaskLayer:onTouchBegan(listener, touch, event)
    -- 获取触点的位置
    local thPos = touch:getLocation()
    -- 转目标坐标系
    local pos = event:getCurrentTarget():convertToNodeSpace(thPos)

    if self.m_ctrl then
        local isSwallow = self.m_stepInfo:isSwallow()
        local isThroughPos = self.m_ctrl:checkTouchThroughRect(pos)
        if isThroughPos or (not isSwallow) then
            listener:setSwallowTouches(false)
        else
            listener:setSwallowTouches(true)
        end
        self.m_ctrl:onTouchMaskBegan(pos)
    end
    return true
end

function GameGuideMaskLayer:onTouchMoved(listener, touch, event)
end

function GameGuideMaskLayer:onTouchCancelled(listener, touch, event)
end

function GameGuideMaskLayer:onTouchEnded(listener, touch, event)
    -- 获取触点的位置
    local endPos = touch:getLocation()
    local beginPos = touch:getStartLocation()
    -- 是否是点击效果
    local isClickEff = false
    local offx = math.abs(endPos.x - beginPos.x)
    local offy = math.abs(endPos.y - beginPos.y)
    if offx < 50 and offy < 50 then
        isClickEff = true
    end

    -- 转目标坐标系
    local pos = event:getCurrentTarget():convertToNodeSpace(endPos)

    -- printInfo("GuideClick:GuideMaskLayer")
    if self.m_ctrl then
        -- 触发事件
        local cplEvent = self.m_stepInfo:getCplEvent()
        -- local isSwallow = self.m_stepInfo:isSwallow()
        -- 是否强制引导
        local isCoerce = self.m_stepInfo:isCoerce()
        -- 是否可穿透的坐标
        local isThroughPos = (not listener:isSwallowTouches()) and self.m_ctrl:checkTouchThroughRect(pos)

        if ((isThroughPos and isCoerce) or (not isCoerce)) and cplEvent == "" and isClickEff then
            printInfo("GuideClick:doNextGuideStep")
            self:doNextGuideStep()
        end
    end
end

function GameGuideMaskLayer:doNextGuideStep()
    local guideName = self.m_stepInfo:getGuideName()
    self.m_ctrl:doNextGuideStep(guideName)
end

-- 注册事件
function GameGuideMaskLayer:registerListener()
    GameGuideMaskLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, self.timeOut, ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function GameGuideMaskLayer:timeOut(_parems)
    if _parems and _parems.name == self.m_ctrl:getRefName() then
        self:closeUI()
    end
end

function GameGuideMaskLayer:clickFunc(_sender)
    local name = _sender:getName()
    printInfo("GuideClick:" .. name)
end

return GameGuideMaskLayer
