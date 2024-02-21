--[[
Author: cxc
Date: 2022-04-20 11:11:54
LastEditTime: 2022-04-20 11:11:55
LastEditors: cxc
Description: 头像框 node
FilePath: /SlotNirvana/src/GameModule/Avatar/views/base/AvatarFrameNode.lua
--]]
local AvatarFrameNode = class("AvatarFrameNode", BaseView)

function AvatarFrameNode:initCsbNodes()
    self.m_nodeSpine = self:findChild("node_spineFrame")
    self.m_nodeCsb = self:findChild("node_csb")
    self.m_spFrame = self:findChild("sp_frame")
    self.m_spFrameScale = self.m_spFrame:getScale()
end

function AvatarFrameNode:getCsbName()
    return "CommonAvatar/csb/CommonAvatarFrame.csb"
end

function AvatarFrameNode:initUI(resInfo, _bAct, _size)
    AvatarFrameNode.super.initUI(self)
    
    self:updateUI(resInfo, _bAct, _size, true)
end

function AvatarFrameNode:initSpineUI()
    AvatarFrameNode.super.initSpineUI(self)
    if not self.m_spineResPath then
        return
    end

    self.m_nodeSpine:setVisible(true)
    local spineNode = util_spineCreate(self.m_spineResPath, false, true, 1)
    self.m_nodeSpine:addChild(spineNode)
    if self.m_spineBAct then
        util_spinePlay(spineNode, "start", true)
    else
        util_spinePlay(spineNode, "idle")
    end
end

function AvatarFrameNode:getContentSize()
    local size = cc.size(226, 226)
    if self.m_resType == 1 then
        local spSize = self.m_spFrame:getContentSize()
        local scale = self.m_spFrame:getScale()
        size = cc.size(spSize.width*scale, spSize.height*scale)
    elseif self.m_resType == 2 then
    elseif self.m_resType == 3 then
        local csbView = self.m_nodeCsb:getChildByName("Node_FrameCsb") or self.m_nodeCsb
        local spIdle = csbView:findChild("sp_idle") 
        if spIdle then
            local spSize = spIdle:getContentSize()
            local scale = spIdle:getScale()
            local curNode = spIdle
            local idx, limitC = 0, 10
            while idx < limitC do
                idx = idx + 1
                local parent = curNode:getParent()
                curNode = parent
                local pScale = parent:getScale()
                if parent:getName() == self.m_nodeCsb:getName() then
                    idx = limitC
                end

                scale = scale * pScale 
            end
            size = cc.size(spSize.width*scale, spSize.height*scale)
        end 
    end

    return size
end

function AvatarFrameNode:updateUI(_resInfo, _bAct, _size, _bInit)
    -- 显隐
    self:hideFrameUI()
    if not _resInfo then
        return
    end

    local resType = _resInfo.type
    local resPath = _resInfo.path
    self.m_spineResPath, self.m_spineBAct = nil, nil
    
    -- 1：静态图 -- 2：spine骨骼动画 -- 3：csb名字
    if resType == 1 then
        if _size and _size.width < 80 then
            -- 小图不需要合图逻辑上减不了啥drawcall，减少点内存
            resPath = string.gsub(resPath, "frame/idle", "frame/idle_small")
            self.m_spFrame:setScale(self.m_spFrameScale * 360/70) --原图360 小图70
        else
            self:checkLoadSpriteFrame(resPath, _resInfo.season)
            self.m_spFrame:setScale(self.m_spFrameScale)
        end
        local bSuccess = util_changeTexture(self.m_spFrame, resPath)
        self.m_spFrame:setVisible(bSuccess)
    elseif resType == 2 and resPath and util_IsFileExist(resPath .. ".skel") then
        if _bInit then
            self.m_spineResPath, self.m_spineBAct = resPath, _bAct
            return
        end
        self.m_nodeSpine:setVisible(true)
        local spineNode = util_spineCreate(resPath, false, true, 1)
        self.m_nodeSpine:addChild(spineNode)
        if _bAct then
            util_spinePlay(spineNode, "start", true)
        else
            util_spinePlay(spineNode, "idle")
        end
    elseif resType == 3 then
        self.m_nodeCsb:setVisible(true)
        local view = util_createAnimation(resPath)
        view:setName("Node_FrameCsb")
        self.m_nodeCsb:addChild(view)
        if _bAct then
            view:playAction("idle", true)
        end
    end

    self.m_resType = resType
end
function AvatarFrameNode:hideFrameUI()
    -- 显隐
    self.m_nodeSpine:setVisible(false)
    self.m_nodeCsb:setVisible(false)
    self.m_spFrame:setVisible(false)

    self.m_nodeSpine:removeAllChildren()
    self.m_nodeCsb:removeAllChildren()
end

function AvatarFrameNode:checkLoadSpriteFrame(_resPath, _season)
    if not _season or not _resPath then
        return
    end

    local SpriteFrameCache = cc.SpriteFrameCache:getInstance()
    local bgFrame = SpriteFrameCache:getSpriteFrame(_resPath)
    if bgFrame then
        return
    end

    local plistName = "avatar_frame_season_" .. _season
    display.loadSpriteFrames(string.format("CommonAvatar/ui/frame/idle/%s.plist", plistName), string.format("CommonAvatar/ui/frame/idle/%s.png", plistName))
end

return AvatarFrameNode

