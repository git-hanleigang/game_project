--[[
Author: cxc
Date: 2022-04-23 16:35:18
LastEditTime: 2022-04-23 16:35:19
LastEditors: cxc
Description: 头像 sprite
FilePath: /SlotNirvana/src/GameModule/Avatar/views/base/AvatarSprite.lua
--]]
local NetSprite = util_require("views.NetSprite")
local AvatarSprite = class("AvatarSprite", NetSprite)
local URLImageManager = util_require("views.URLImageManager")

function AvatarSprite:ctor()
    AvatarSprite.super.ctor()

    self.m_urlType = 0

    self.m_defCricleImgPath = "UserInformation/ui_head/avatar_default.png"
    self.m_defSquareImgPath = "userinfo/ui_head/UserInfo_touxiang_square_1.png"

    self.m_fid = ""
    self.m_headId = 0
    self.m_robotHeadName = ""
    self.m_bSquare = false
    self.m_bLoadFBFromCache = true
end

--[[
    @desc: 创建头像sp
    --@_fId: facebook id 
	--@_headId: 游戏game 存储的头像id
	--@_robotHeadName: 机器人头像名字
	--@_bSquare: 是否创建 矩形的头像 默认 false
	--@_size:  头像限制大小
	--@_bFBFromCache: facebook头像是否从（缓存）中获取 默认true
    @return: sprite
]]
function AvatarSprite:createWith(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    local params = {
        fid = _fId,
        headId = _headId,
        robotHeadName = _robotHeadName,
        bSquare = _bSquare,
        size = _size,
        bFBFromCache = _bFBFromCache,
    }
    local obj = self:createWithData(params)
    return obj
end

function AvatarSprite:createWithData(_params)
    local obj = self:create()

    obj.m_fid = _params.fid or "" 
    obj.m_headId = tonumber(_params.headId) or 0
    obj.m_robotHeadName = _params.robotHeadName or ""
    obj.m_bSquare = _params.bSquare
    if _params.bFBFromCache ~= nil then
        obj.m_bLoadFBFromCache = _params.bFBFromCache
    end

    -- init 
    local defImgPath = obj.m_bSquare and obj.m_defSquareImgPath or obj.m_defCricleImgPath
    obj:init(defImgPath, _params.size)

    -- 加载图片
    obj:loadSpriteTexture()

    return obj
end

function AvatarSprite:updateView(_fId, _headId, _robotHeadName, _bSquare, _size, _bFBFromCache)
    self.m_fid = _fId or "" 
    self.m_headId = tonumber(_headId) or 0
    self.m_robotHeadName = _robotHeadName or ""
    self.m_bSquare = _bSquare
    if _bFBFromCache ~= nil then
        self.m_bLoadFBFromCache = _bFBFromCache
    end

    -- 网络图片停止下载
    URLImageManager.getInstance():removeDownloadInfoByNode(self)

    local defImgPath = self.m_bSquare and self.m_defSquareImgPath or self.m_defCricleImgPath
    self:init(defImgPath, _size)
    self:loadSpriteTexture()
end

-- 加载图片
function AvatarSprite:loadSpriteTexture()
    if string.len(self.m_fid) > 0 and self.m_headId == 0 then
        self.m_urlType = 1
        self:loadFbUrlTexture()
    elseif string.len(self.m_robotHeadName) > 0 then
        self.m_urlType = 2
        self:loadRobotUrlTexture()
    else
        self.m_urlType = 3
        self:loadGameResTexture()
    end
end

-- 加载 facebook 头像
function AvatarSprite:loadFbUrlTexture()
    local url = "https://graph.facebook.com/" .. self.m_fid .. "/picture?type=large"
    self:getSpriteByUrl(url, self.m_bLoadFBFromCache)
end

-- 加载 robot 头像
function AvatarSprite:loadRobotUrlTexture()
    local url =  ROBOT_DOWNLOAD_URL .. "/head/" .. self.m_robotHeadName .. ".png"
    self:getSpriteByUrl(url, true)
end

-- 加载 game 头像
function AvatarSprite:loadGameResTexture()
    local imgPath = G_GetMgr(G_REF.Avatar):getAvatarResPath(self.m_headId, self.m_bSquare, self.m_imageSize)
    self:updateTexture(imgPath) 
end

-- 获取头像类型  fb:1, robot:2, game: 3
function AvatarSprite:getUrlType()
    return self.m_urlType
end

function AvatarSprite:updateTexture(_fileName)
    AvatarSprite.super.updateTexture(self, _fileName)

    if self.m_refreshParentScaleCb then
        self.m_refreshParentScaleCb()
    end
    self:setPosition(0, 0)

    local glProgramState = self:getGLProgramState()
    if not self.m_bSquare and not tolua.isnull(glProgramState) then
        glProgramState:setUniformInt("clipFlag", self.m_urlType ~= 3 and 1 or 0)
    end
end

-- 更新图片后刷新 缩放
function AvatarSprite:setRefreshParentScaleCb(_cb)
    self.m_refreshParentScaleCb = _cb
end

--请求网络数据 overWrite
function AvatarSprite:getUrlImage(url, isLocal)
    local isExist, fileName
    local imgUrl = url
    isExist, fileName = self:getHeadMd5(url)

    -- 这里是否使用本地文件
    if isLocal then
        if isExist then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IMAGE_LOAD_COMPLETE)
            self:updateTexture(fileName)
            return
        end
    end

    -- 如果不存在，启动http下载 status==1（保存本地） status==2 （加入缓存） status==3（ 保存本地并加入缓存）
    local function HttpRequestCompleted(statusCode, status)
        if statusCode == 200 and self.updateTexture and self.m_urlType ~= 3 then
            self:updateTexture(fileName)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IMAGE_LOAD_COMPLETE)
    end
    URLImageManager.getInstance():pushDownloadInfo(imgUrl,self,HttpRequestCompleted)
end

return AvatarSprite