--[[
Author: cxc
Date: 2022-04-13 14:43:38
LastEditTime: 2022-04-13 14:43:39
LastEditors: cxc
Description: 通用 头像 + 头像框
FilePath: /SlotNirvana/src/GameModule/Avatar/views/base/CommonAvatarNode.lua
--]]
local CommonAvatarNode = class("CommonAvatarNode", BaseView)

function CommonAvatarNode:initDatas()
    self.m_scale = 1
    self.m_avtarDefaultImgW = 142
    self.m_nodeDefalutScaleList = {}
    self.m_bInit = false
end

function CommonAvatarNode:initCsbNodes()
    self.m_nodeAvatar = self:findChild("node_avatar")
    self.m_nodeFrame = self:findChild("node_avatar_frame")
    self.m_nodeFrame:setVisible(false)

    for _, node in ipairs(self.m_csbNode:getChildren()) do
        self.m_nodeDefalutScaleList[node:getName()] = node:getScale()
    end
end

function CommonAvatarNode:getCsbName()
    return "CommonAvatar/csb/CommonAvatar.csb"
end

--[[
    --@_fId: facebook id 
	--@_headId: 游戏game 存储的头像id
	--@_headFrameId: 游戏game 存储的头像框 id
	--@_robotHeadName: 机器人头像名字
	--@_size:  头像限制大小
	--@_bFBFromCache: facebook头像是否从（缓存）中获取 默认true
]]
function CommonAvatarNode:updateUI(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
    -- 默认头像框
    if (not _fId or _fId == "") and (not _headId or tostring(_headId) == "0" or tostring(_headId) == "") then
        _headId = 1
    end

    if self.m_bInit then
        -- 更新头像
        self:updateAvatarNode(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
        -- 更新头像框
        self:updateFrameSprite(_headFrameId, _size)
        return
    end
    
    -- 更新头像
    self:initAvatarNode(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
    -- 更新头像框
    self:initFrameSprite(_headFrameId, _size)
    self.m_bInit = true
end

-- 更新头像
function CommonAvatarNode:initAvatarNode(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
    self.m_nodeAvatar:removeAllChildren()

    local node, sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(_fId, _headId, _robotHeadName, false, _size, _bFBFromCache)
    self.m_nodeAvatar:addChild(node)
    sprite:setRefreshParentScaleCb(function()
        self:updateScale(sprite)
    end)
    self:updateScale(sprite)
    self.m_avatarSp = sprite
end
-- 更新头像
function CommonAvatarNode:updateAvatarNode(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
    if not self.m_avatarSp then
        return
    end
    
    self.m_avatarSp:updateView(_fId, _headId, _robotHeadName, false, _size, _bFBFromCache)
end

-- 更新头像框
function CommonAvatarNode:initFrameSprite(_headFrameId, _size)
    local view = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(_headFrameId, true, _size)
    if view then
        self.m_nodeFrame:addChild(view)
        self.m_nodeFrame:setVisible(true)
        self.m_avatarFrameNode = view
    end
end
function CommonAvatarNode:updateFrameSprite(_headFrameId, _size)
    if not self.m_avatarFrameNode then
        self:initFrameSprite(_headFrameId, _size)
        return
    end

    local resInfo = G_GetMgr(G_REF.AvatarFrame):getAvatarFrameResPath(_headFrameId)
    self.m_avatarFrameNode:updateUI(resInfo, true, _size)
end

-- 更新 csb除头像外其他节点缩放值(网络头像图片大小不固定)
function CommonAvatarNode:updateScale(_sprite)
    if tolua.isnull(_sprite) then
        return
    end

    self.m_scale = _sprite:getScaleX()
    local size = _sprite:getContentSize()
    local imgScale = size.width / self.m_avtarDefaultImgW
    for _, node in ipairs(self.m_csbNode:getChildren()) do
        local name = node:getName()
        if name ~= "node_avatar" then
            node:setScale((self.m_nodeDefalutScaleList[name] or 1) * self.m_scale * imgScale)
        end
    end
end

-- 检查 头像框是否显示
function CommonAvatarNode:checkFrameNodeVisible()
    return self.m_nodeFrame:isVisible()
end

-- 注册卸载头像框事件
function CommonAvatarNode:registerTakeOffEvt()
    if not self:checkFrameNodeVisible() then
        return
    end

    gLobalNoticManager:addObserver(self, function()
        self.m_nodeFrame:removeAllChildren()
        self.m_nodeFrame:setVisible(false)
    end, ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI) --头像卡到期卸下自己的头像框
end

return CommonAvatarNode