-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成
local URLImageManager = require("views.URLImageManager")
local NetSprite = class("NetSprite", cc.Sprite)
NetSprite.m_imageSize = nil
NetSprite.m_rul = nil
NetSprite.m_defaultSpName = nil
--根据url生成精灵
function NetSprite:ctor()

    -- self.head = sp.SkeletonAnimation:create("util_act/loadingHead.json", "util_act/loadingHead.atlas")
    -- self.head:setAnimation(0, "animation", true)
    -- self:addChild(self.head)
end

function NetSprite.create()
    local netSprite = NetSprite.new()
    return netSprite
end

function NetSprite:setSpriteSize(size)
    self.m_imageSize = size
end

function NetSprite:init(defaultSpName, size)
    self.m_defaultSpName = defaultSpName
    self.m_imageSize = size
    self:updateTexture(self.m_defaultSpName)
end

function NetSprite:getSpriteByUrl(url, isLocal)

    self.m_rul = url
    if not isLocal then
        isLocal=false
    end
    self:getUrlImage(url, isLocal)
end

function NetSprite:updateTexture(fileName)
    util_changeTexture(self,fileName)
    if self.m_imageSize then
        local size = self:getContentSize()
        if size and size.width and size.width>0 then
            local scaleX =  self.m_imageSize.width / size.width
            self:setScaleX(scaleX)
        end
        if size and size.height and size.height>0 then
            local scaleY = self.m_imageSize.height / size.height
            self:setScaleY( scaleY)
        end
        self:setPosition(cc.p(self.m_imageSize.width / 2, self.m_imageSize.height / 2))
    end
end

function NetSprite:getHeadMd5(url)
    local tempMd5 = xcyy.UrlImage:getInstance():getMd5(url)
    local path = device.writablePath .. "pub/head"
    local file = path .. "/" .. tempMd5 .. ".png"
    local isNewFile = cc.FileUtils:getInstance():isFileExist(file)
    return isNewFile, file
end

--请求网络数据
function NetSprite:getUrlImage(url, isLocal)
    local isExist, fileName
    local iamgeUrl = url
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
        if statusCode == 200 and self.updateTexture then
            self:updateTexture(fileName)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IMAGE_LOAD_COMPLETE)
    end
    URLImageManager.getInstance():pushDownloadInfo(iamgeUrl,self,HttpRequestCompleted)
end


return NetSprite
-- endregion