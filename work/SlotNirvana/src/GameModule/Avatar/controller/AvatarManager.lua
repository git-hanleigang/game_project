--[[
Author: cxc
Date: 2022-04-12 16:47:44
LastEditTime: 2022-04-12 16:47:45
LastEditors: cxc
Description: 头像信息管理类
FilePath: /SlotNirvana/src/GameModule/Avatar/controller/AvatarManager.lua
--]]
local AvatarManager = class("AvatarManager", BaseGameControl)
local AvatarSprite = util_require("GameModule.Avatar.views.base.AvatarSprite")
local URLImageManager = util_require("views.URLImageManager")

function AvatarManager:ctor()
    AvatarManager.super.ctor(self)
    self:setRefName(G_REF.Avatar)

    self.m_clearDownloadImgOpen = false
    self.m_downloadImgList = {}
end

--添加头像缓存
function AvatarManager:loadSpriteFrameCache()
    display.loadSpriteFrames("userinfo/ui_head/UserHeadPlist.plist", "userinfo/ui_head/UserHeadPlist.png")
end

-- 获取 头像 资源路径
function AvatarManager:getAvatarResPath(_headId, _bSquare, _size)
    local imgPath = "UserInformation/ui_head/UserInfo_touxiang_" .. _headId .. ".png"
    if _bSquare then
        imgPath = "UserInformation/ui_head/UserInfo_touxiang_square_".. _headId ..".png"
    end
    if _size.width < 80 and G_GetMgr(G_REF.AvatarFrame):checkCommonAvatarDownload() then
        imgPath = string.gsub(imgPath, "UserInformation/ui_head/", "CommonAvatar/ui/head_small/")
    end

    return imgPath
end

--[[
    @desc: 创建头像sp
    --@_fId: facebook id 
	--@_headId: 游戏game 存储的头像id
	--@_robotHeadName: 机器人头像名字
	--@_bSquare: 是否创建 矩形的头像 默认 false
	--@_size:  头像限制大小 没有就是原始大小
	--@_bFBFromCache: facebook头像是否从（缓存）中获取 默认true
    @return: sprite
]]
function AvatarManager:_createAvatarSprite(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    self:loadSpriteFrameCache()
    
    local sprite = AvatarSprite:createWith(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    local urlType = sprite:getUrlType()
    -- fb:1, robot:2, game: 3
    if self.m_clearDownloadImgOpen and (urlType == 1 or urlType == 2) then
        table.insert(self.m_downloadImgList, sprite)
    end
    return sprite,urlType
end

-- 创建头像 不裁剪 node
function AvatarManager:createAvatarOutClipNode(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    local node = display.newNode()
    local sprite = self:_createAvatarSprite(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    node:addChild(sprite)
    return node, sprite
end

-- 创建头像 裁剪 node
function AvatarManager:createAvatarClipNode(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    if _bSquare or not _size or _size.width == 0 or _size.height == 0 then
        -- 方形或不限制长度的都不裁剪
        return self:createAvatarOutClipNode(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    end
    local sprite,urlType = self:_createAvatarSprite(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    util_CllipNode(sprite, _size, urlType ~= 3)
    return sprite, sprite
end

-- 移除下载队列
function AvatarManager:removeDownloadInfo()
    for _, node in ipairs(self.m_downloadImgList) do
        if not tolua.isnull(node) then
            URLImageManager.getInstance():removeDownloadInfoByNode(node)
        end
    end
end

function AvatarManager:release( )
    self:removeDownloadInfo()
    self.m_downloadImgList = {}
end

return AvatarManager