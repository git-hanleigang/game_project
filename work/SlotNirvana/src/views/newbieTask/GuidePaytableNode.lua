--GuidePaytableNode
local GuidePaytableNode = class("GuidePaytableNode", util_require("base.BaseView"))
function GuidePaytableNode:initUI(info,pos)
    self:createCsbNode("NoviceGuide/Paytable.csb")
    self:runCsbAction("idle",true)
    self:setPosition(pos)
    --遮罩
    self.m_touchLayer = util_newMaskLayer()
    self.m_touchLayer:setScale(3)
    self.m_touchLayer:setPosition(-display.width,-display.height)
    --扣洞
    local stencilNode = cc.Node:create()
    local clipNode = cc.ClippingNode:create()
    self:addChild(clipNode,-1)
    clipNode:setInverted(true)
    clipNode:setAlphaThreshold(0.95)
    clipNode:setStencil(stencilNode)
    clipNode:addChild(self.m_touchLayer)
    local sp_clip = display.newSprite("NoviceGuide/Other/zhezhao_yuan.png")
    stencilNode:addChild(sp_clip)
    local sp_mask= display.newSprite("NoviceGuide/Other/zhezhao_yuan2.png")
    self:addChild(sp_mask)
    local size = sp_clip:getContentSize()
    local infoSize = info.size
    if globalData.slotRunData.isPortrait and info.portrait then
        infoSize = info.portrait.size
    end
    local scale = infoSize[1]/size.width
    --设置缩放
    sp_clip:setScale(scale)
    sp_mask:setScale(scale)
    --0.2秒内强制引导
    local isTouch = false
    performWithDelay(self,function()
        isTouch = true
    end,0.2)
    --点击了按钮取消自动关闭
    self.m_autoClose = true
    performWithDelay(self,function()
        if not self.m_autoClose then
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_GAMEMENU_ZORDER,true)
    end,5)
    local maskR = info.size[1]
    if globalData.slotRunData.isPortrait == true then
        maskR = info.size[2]
    end
    local rect = cc.rect(pos.x - maskR * 0.5, pos.y - maskR * 0.5, maskR, maskR)
    --监听点击遮罩区域
    self.m_touchLayer:onTouch( function(event)
        local touchPos = cc.p(event.x,event.y)
        if cc.rectContainsPoint(rect,touchPos) then
            if info.id == NOVICEGUIDE_ORDER.payTable.id then
                self.m_autoClose = nil
                return false
            end
        end
        if not isTouch or event.name ~= "ended" then
            return true
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_GAMEMENU_ZORDER,true)
        return true
    end, false, true)
end
function GuidePaytableNode:removeGuide()
    if not tolua.isnull(self.m_touchLayer) then
        self.m_touchLayer:removeFromParent()
        self.m_touchLayer = nil
    end
    self:removeFromParent()
    self.m_autoClose = nil
end
function GuidePaytableNode:onEnter()
    gLobalNoticManager:addObserver(self,function(Target,params)
        if self.removeGuide then
            self:removeGuide()
        end
        if params then
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
        end
    end, ViewEventType.NOTIFY_CHANGE_GAMEMENU_ZORDER)
end
function GuidePaytableNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return GuidePaytableNode