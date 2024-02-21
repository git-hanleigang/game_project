--[[
Author: cxc
Date: 2022-04-27 15:22:10
LastEditTime: 2022-04-27 15:22:11
LastEditors: cxc
Description: 头像框 引导
FilePath: /SlotNirvana/src/views/AvatarFrame/other/AvatarFrameGuideLayer.lua
--]]
local AvatarFrameGuideLayer = class("AvatarFrameGuideLayer", BaseLayer)

function AvatarFrameGuideLayer:ctor()
    AvatarFrameGuideLayer.super.ctor(self)

    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    self:setLandscapeCsbName("Activity/csb/Frame_guide2.csb")
end

function AvatarFrameGuideLayer:initCsbNodes()
    self.m_nodeH = self:findChild("Node_H")
    self.m_nodeV = self:findChild("Node_V")

    self.m_nodeH:setVisible(not self.m_isShownAsPortrait)
    self.m_nodeV:setVisible(self.m_isShownAsPortrait)
end

function AvatarFrameGuideLayer:initDatas(_guideNode)
    if not _guideNode then
        return
    end

    self.m_guideNode = _guideNode
    self.m_guideNodeParent = _guideNode:getParent()
end

function AvatarFrameGuideLayer:initView()
    if not self.m_guideNode then
        return
    end

    -------------------
    -- 创建裁剪层
    local nodeClipping = cc.ClippingNode:create()
    nodeClipping:setInverted(true)
    nodeClipping:setAlphaThreshold(0)
    self:addChild(nodeClipping, -1)
    self.m_nodeClipping = nodeClipping
    -- 设置 stencil node对象
    self.m_nodeStencil = ccui.Scale9Sprite:create("Common/guide_stencil.png")
    local scale = self.m_csbNode:getScale()
    self.m_nodeStencil:setContentSize(cc.size(230*scale, 250*scale))
    nodeClipping:setStencil(self.m_nodeStencil)
    -- 设置遮罩层
    local maskLayer = util_newMaskLayer()
    maskLayer:setOpacity(190)
    nodeClipping:addChild(maskLayer)
    -------------------

    local posW = self.m_guideNode:convertToWorldSpaceAR(cc.p(0,0))
    local posL = self:convertToNodeSpaceAR(posW)
    self.m_nodeStencil:setPosition(posL)

    if self.m_isShownAsPortrait then
        self.m_csbNode:move(cc.p(display.cx, posL.y))
    else
        self.m_csbNode:move(posL)
    end
end

function AvatarFrameGuideLayer:onClickMask()
    if self.m_guideNodeParent then
        util_changeNodeParent(self.m_guideNodeParent, self.m_guideNode)
        self.m_guideNode:setPosition(cc.p(0,0))
    end
    self:closeUI()
end

return AvatarFrameGuideLayer