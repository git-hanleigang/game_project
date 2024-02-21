--引导界面
local FlowerGuideLayer = class("FlowerGuideLayer",BaseView)
local designScale = CC_DESIGN_RESOLUTION.width / CC_DESIGN_RESOLUTION.height
local deviceScale = display.width / display.height
local ratio = math.min(deviceScale / designScale, 1)
function FlowerGuideLayer:ctor(_type)
    self._type = _type
    FlowerGuideLayer.super.ctor(self)
    local path = "Activity/csd/node_Guide.csb"
    if globalData.slotRunData.isPortrait then
        path = "Activity/csd/node_Guide_vertical.csb"
        ratio = 0.8
    end
    if self._type == 2 then
        path = "Activity/csd/node_Guide_operation.csb"
        if globalData.slotRunData.isPortrait then
            path = "Activity/csd/node_Goperation_vertical.csb"
        end
    end

    self:createCsbNode(path)
    self:setExtendData("FlowerGuideLayer")
    self.config = G_GetMgr(G_REF.Flower):getConfig()
end

function FlowerGuideLayer:initUI()
    self:setPosData()
    self:move(display.center)
    self:initView()
end

function FlowerGuideLayer:setPosData()
    if self._type == 1 then
        --浇花主界面
        self.step_pos = {cc.p(42,8),cc.p(42,8),cc.p(42,23),cc.p(42,23),cc.p(42,23)}
        self.step_node = {1,2}
        self.step_size = {cc.size(230*ratio,370*ratio),cc.size(230*ratio,370*ratio),cc.size(300*ratio,80*ratio),cc.size(300*ratio,80*ratio),cc.size(280*ratio,90*ratio)}
    elseif self._type == 2 then
        --浇水主界面
        self.step_pos = {cc.p(105,-10),cc.p(315,35)}
        self.step_node = {1,2}
        self.step_size = {cc.size(460*ratio,100*ratio),cc.size(730*ratio,360*ratio)}
    end
end

function FlowerGuideLayer:setGuideRefNodes(nodes)
    if not nodes  then
        return
    end
    self.m_refNodes = nodes
    for k, node in pairs(nodes) do
        local pos = node:getPosition()
        local worldPos = node:convertToWorldSpace(cc.p(0, 0))
        self.step_pos[k] = cc.pAdd(worldPos, self.step_pos[k])
    end

    self:showStep(1)
    self.guide_str = self.config.EVENT_NAME.NOTIFY_UNWATER_GUIDE
    if self._type == 2 then
        self.guide_str = self.config.EVENT_NAME.NOTIFY_WATER_GUIDE
    end
    gLobalNoticManager:postNotification(self.guide_str,self.m_curGuideStep)
end

function FlowerGuideLayer:initView()
    -- 创建裁剪层
    local nodeClipping = cc.ClippingNode:create()
    nodeClipping:setInverted(true)
    nodeClipping:setAlphaThreshold(0)
    self.m_nodeClipping = nodeClipping
    local node = cc.Node:create()
    self.m_nodeStencil = node
    --self.m_nodeStencil = ccui.Scale9Sprite:create("Activity/img/flower_duide.png")
    self.m_nodeStencil:setContentSize(cc.size(200, 80))
    nodeClipping:setStencil(self.m_nodeStencil)
    -- 设置遮罩层
    local maskLayer = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
    maskLayer:setOpacity(190)
    nodeClipping:addChild(maskLayer)
    nodeClipping:move(0,0)
    gLobalViewManager:getViewLayer():addChild(nodeClipping, ViewZorder.ZORDER_GUIDE)
    self.m_nodeStencil:setPosition(0,0)
    

    local layer = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
    layer:setOpacity(0)
    layer:setPosition(-display.width/2, -display.height/2)
    self:addChild(layer)
    self.m_maskLayer = layer

    gLobalViewManager:getViewLayer():addChild(self, ViewZorder.ZORDER_GUIDE + 1)
    self:registerTouchEvent()
    self.m_curGuideStep = 1
end

function FlowerGuideLayer:showStep(step)
    for i,v in ipairs(self.step_node) do
        local node = self:findChild("node_guide"..v)
        node:setVisible(step == i)
    end
    -- if self._type == 2 then
    --     self.m_nodeStencil:removeAllChildren()
    --     local spr1 = ccui.Scale9Sprite:create("Activity/img/guide_stencil.png")
    --     if step == 1 then
    --         spr1:setContentSize(self.step_size[1])
    --         spr1:setPosition(self.step_pos[1])
    --     else
    --         spr1:setContentSize(self.step_size[2])
    --         spr1:setPosition(self.step_pos[2])
    --     end
    --     self.m_nodeStencil:addChild(spr1)
    -- else
    --     if step == 1 then
    --         self.m_nodeStencil:removeAllChildren()
    --         local spr1 = ccui.Scale9Sprite:create("Activity/img/guide_stencil.png")
    --         spr1:setContentSize(self.step_size[1])

    --         spr1:setPosition(self.step_pos[1])
    --         local spr2 = ccui.Scale9Sprite:create("Activity/img/guide_stencil.png")
    --         spr2:setContentSize(self.step_size[2])
    --         spr2:setPosition(self.step_pos[2])
    --         self.m_nodeStencil:addChild(spr1)
    --         self.m_nodeStencil:addChild(spr2)
    --     else
    --         self.m_nodeStencil:removeAllChildren()
    --         local spr1 = ccui.Scale9Sprite:create("Activity/img/guide_stencil.png")
    --         spr1:setContentSize(self.step_size[3])
    --         spr1:setPosition(self.step_pos[3])
    --         local spr2 = ccui.Scale9Sprite:create("Activity/img/guide_stencil.png")
    --         spr2:setContentSize(self.step_size[4])
    --         spr2:setPosition(self.step_pos[4])
    --         local spr3= ccui.Scale9Sprite:create("Activity/img/guide_stencil.png")
    --         spr3:setContentSize(self.step_size[5])
    --         spr3:setPosition(self.step_pos[5])
    --         self.m_nodeStencil:addChild(spr1)
    --         self.m_nodeStencil:addChild(spr2)
    --         self.m_nodeStencil:addChild(spr3)
    --     end
    -- end
end

function FlowerGuideLayer:registerTouchEvent()
    local function onTouchBegan(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curGuideStep = self.m_curGuideStep + 1
        if self.m_curGuideStep > #self.step_node then
            gLobalNoticManager:postNotification(self.guide_str,self.m_curGuideStep)
            self:closeUI()
        else
            self:showStep(self.m_curGuideStep)
            gLobalNoticManager:postNotification(self.guide_str,self.m_curGuideStep)
        end
        
    end
    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener1:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.m_maskLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self.m_maskLayer)
end

function FlowerGuideLayer:closeUI()
    if not tolua.isnull(self.m_nodeClipping) then
        self.m_nodeClipping:removeSelf()
    end

    if not tolua.isnull(self) then
        self:removeSelf()
    end
end

function FlowerGuideLayer:clickFunc(sender)
    local name = sender:getName()
end

return FlowerGuideLayer