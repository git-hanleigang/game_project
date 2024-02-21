--引导界面
local InvitaGuide = class("InvitaGuide",BaseLayer)
local designScale = CC_DESIGN_RESOLUTION.width / CC_DESIGN_RESOLUTION.height
local deviceScale = display.width / display.height
local ratio = math.min(deviceScale / designScale, 1)
function InvitaGuide:ctor()
    InvitaGuide.super.ctor(self)
    self:setLandscapeCsbName("Activity/GuideNode.csb")
    self:setExtendData("InvitaGuide")
    self:setMaskEnabled(false)
    self.config = G_GetMgr(G_REF.Invite):getConfig()
end

function InvitaGuide:setPosData(_type)
    if _type == 1 then
        --邀请者
        gLobalDataManager:setNumberByField(self.config.EVENT_NAME.INVITER_GUIDER, 2)
        self.step_pos = {cc.p(60*ratio,23*ratio),cc.p(60*ratio,23*ratio),cc.p(110*ratio,40*ratio)}
        self.step_node = {5,6,7}
        self.step_size = {cc.size(430*ratio,100*ratio),cc.size(430*ratio,100*ratio),cc.size(245*ratio,80*ratio)}
    elseif _type == 2 then
        --被邀请者
        gLobalDataManager:setNumberByField(self.config.EVENT_NAME.INVITEE_GUIDER, 2)
        self.step_pos = {cc.p(105*ratio,-10*ratio),cc.p(315*ratio,35*ratio)}
        self.step_node = {3,4}
        self.step_size = {cc.size(160*ratio,170*ratio),cc.size(960*ratio,170*ratio)}
    end
end

function InvitaGuide:setGuideRefNodes(nodes)
    if not nodes  then
        return
    end
    self.m_refNodes = nodes
    for k, node in pairs(nodes) do
        self.step_pos[k] = cc.p(node.x,node.y) 
    end

    self:showStep(1)
end

function InvitaGuide:setGuideRNodes(nodes)
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
end

function InvitaGuide:initView()
    self:move(display.center)
    -- 创建裁剪层
    local nodeClipping = cc.ClippingNode:create()
    nodeClipping:setInverted(true)
    nodeClipping:setAlphaThreshold(0)
    self.m_nodeClipping = nodeClipping
    self.m_nodeStencil = ccui.Scale9Sprite:create("Common/guide_stencil.png")
    self.m_nodeStencil:setContentSize(cc.size(460, 80))
    nodeClipping:setStencil(self.m_nodeStencil)
    -- 设置遮罩层
    local maskLayer = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
    maskLayer:setOpacity(190)
    nodeClipping:addChild(maskLayer)
    nodeClipping:move(0,0)
    gLobalViewManager:getViewLayer():addChild(nodeClipping, ViewZorder.ZORDER_GUIDE)
    self.m_nodeStencil:setPosition(100,100)
    

    local layer = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
    layer:setOpacity(0)
    layer:setPosition(-display.width/2, -display.height/2)
    self:addChild(layer)
    self.m_maskLayer = layer

    gLobalViewManager:getViewLayer():addChild(self, ViewZorder.ZORDER_GUIDE + 1)
    self:registerTouchEvent()
    self.m_curGuideStep = 1
end

function InvitaGuide:showStep(step)
    for i,v in ipairs(self.step_node) do
        local node = self:findChild("Node_"..v)
        node:setVisible(step == i)
    end
    self.m_nodeStencil:setContentSize(self.step_size[step])
    self.m_nodeStencil:setPosition(self.step_pos[step])
end

function InvitaGuide:registerTouchEvent()
    local function onTouchBegan(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curGuideStep = self.m_curGuideStep + 1
        if self.m_curGuideStep > #self.step_node then
            self:closeUI()
        else
            self:showStep(self.m_curGuideStep)
        end
    end
    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(true)
    listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener1:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.m_maskLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self.m_maskLayer)
end

function InvitaGuide:closeUI()
    gLobalNoticManager:postNotification(self.config.EVENT_NAME.INVITEE_GUIDER_FINSH)
    if not tolua.isnull(self.m_nodeClipping) then
        self.m_nodeClipping:removeSelf()
    end

    if not tolua.isnull(self) then
        self:removeSelf()
    end

end

function InvitaGuide:clickFunc(sender)
	local name = sender:getName()
end

return InvitaGuide