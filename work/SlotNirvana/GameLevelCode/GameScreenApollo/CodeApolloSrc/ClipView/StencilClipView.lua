local StencilClipView = class("StencilClipView",util_require("base.BaseView"))

function StencilClipView:initUI()
    --切割模板
	self.m_stencil = cc.DrawNode:create()
    --切割容器
	self.m_clipNode = cc.ClippingNode:create()
    self.m_clipNode:setStencil(self.m_stencil)
    self:addChild(self.m_clipNode)
end
--给切割容器内添加一组内容
function StencilClipView:addContentTabToClip(contentNodeTab)
    for i,contentNode in ipairs(contentNodeTab) do
        self:addContentToClip(contentNode)
    end
end
--给切割容器内添加内容
function StencilClipView:addContentToClip(contentNode)
    if contentNode.m_worldPos then
        local pos = self.m_clipNode:convertToNodeSpace(contentNode.m_worldPos)
        contentNode:setPosition(pos)
    end
    self.m_clipNode:addChild(contentNode)
end
--设置模板多边形顶点坐标
function StencilClipView:stencilDrawPolygon(posTab)
    self.m_stencil:drawPolygon(posTab,#posTab,cc.c4b(0, 255, 0, 255),0,cc.c4b(0, 255, 0, 255))
end
--设置模板为圆的参数
function StencilClipView:stencilDrawSolidCircle(center,radius,segments)
    self.m_stencil:drawSolidCircle(center,radius,math.pi*2,segments,cc.c4b(0, 255, 0, 255))
end
--设置模板坐标
function StencilClipView:setStencilPos(pos)
    self.m_stencil:setPosition(pos)
end
--获取模板
function StencilClipView:getStencil()
    return self.m_stencil
end
--获取切割模板
function StencilClipView:getClipNode()
    return self.m_clipNode
end

function StencilClipView:onEnter()
    
end
function StencilClipView:onExit()
    
end
return StencilClipView