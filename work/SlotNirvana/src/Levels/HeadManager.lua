local URLImageManager = require("views.URLImageManager")
local HeadManager = class("HeadManager")
local NetSpriteLua = require("views.NetSprite")

-- ctor
function HeadManager:ctor()
    self.m_headInfoList = {}
    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
end

-- get Instance --
function HeadManager:getInstance()
    if not self._instance then
        self._instance = HeadManager.new()
    end
    return self._instance
end

function HeadManager:addPlayerHeadInfo(_url)
    local bDownload = self:isHaveDownloadByUrl(_url)
    if not bDownload then
        table.insert(self.m_headInfoList, {url = _url})
    end
end

--判断这个图片是否在下载列表
function HeadManager:isHaveDownloadByUrl(_url)
    for k, v in ipairs(self.m_headInfoList) do
        if v.url == _url then
            return true
        end
    end
    return false
end
--切换房间 删除所有正在下载的
function HeadManager:removeAllHeadInfo()
    local m_headInfoList = self.m_headInfoList
    while #m_headInfoList > 0 do
        local downloadInfo = m_headInfoList[1]
        URLImageManager.getInstance():removeDownloadInfo(downloadInfo.url)
        table.remove(m_headInfoList,1)
    end
end

--[[
    获取facebook头像
]]
function HeadManager:getFacebookHead(fbid,headSize,isSquare)
    if fbid ~= nil and fbid ~= "" and headSize then
        local netSprite = NetSpriteLua:create()
        if isSquare then
            --给一个初始头像,加载好后会替换
            netSprite:init("UserInformation/ui_head/UserInfo_touxiang_square_1.png",headSize)
        else
            --给一个初始头像,加载好后会替换
            netSprite:init("UserInformation/ui_head/UserInfo_touxiang_1.png",headSize)
        end
        

        local urlPath = "https://graph.facebook.com/" .. fbid .. "/picture?type=large"
        netSprite:getSpriteByUrl(urlPath, true)
        local isExist, fileName = netSprite:getHeadMd5(urlPath)
        --添加到下载队列
        if not isExist then
            self:addPlayerHeadInfo(urlPath)
        end
        return netSprite
    else
        local fbHead = NetSpriteLua:create()
        if isSquare then
            fbHead:init("userinfo/ui_head/UserInfo_touxiang_square_1.png", headSize)
        else
            fbHead:init("userinfo/ui_head/UserInfo_touxiang_1.png", headSize)
        end
        
        return fbHead
    end
end

--[[
    获取机器人头像
]]
function HeadManager:getRobotHead(robotName,headSize,isSquare)
    if robotName ~= nil and robotName ~= "" and headSize then
        local netSprite = NetSpriteLua:create()
        if isSquare then
            --给一个初始头像,加载好后会替换
            netSprite:init("UserInformation/ui_head/UserInfo_touxiang_square_1.png",headSize)
        else
            --给一个初始头像,加载好后会替换
            netSprite:init("UserInformation/ui_head/UserInfo_touxiang_1.png",headSize)
        end
        

        local urlPath =  ROBOT_DOWNLOAD_URL .. "/head/" .. robotName .. ".png"
        netSprite:getSpriteByUrl(urlPath, true)
        local isExist, fileName = netSprite:getHeadMd5(urlPath)
        --添加到下载队列
        if not isExist then
            self:addPlayerHeadInfo(urlPath)
        end
        return netSprite
    else
        local rbHead = NetSpriteLua:create()
        if isSquare then
            rbHead:init("UserInformation/ui_head/UserInfo_touxiang_square_1.png", headSize)
        else
            rbHead:init("UserInformation/ui_head/UserInfo_touxiang_1.png", headSize)
        end
        
        return rbHead
    end
end

--[[
    裁切头像
]]
function HeadManager:clipHeadNode(parentNode,head,isSquare)
    if parentNode then
        local headSize = parentNode:getContentSize()

        -- 头像切图
        local clip_node = cc.ClippingNode:create()
        local mask = NetSpriteLua:create()
        mask:init("Common/Other/fbmask.png", headSize)
        clip_node:setStencil(mask)
        clip_node:setAlphaThreshold(0)
        clip_node:addChild(head)
        parentNode:addChild(clip_node)
        clip_node:setPosition(cc.p(0,0))
    end
end

--[[
    获取裁切头像
]]
function HeadManager:getClipHead(parentNode,fbid,head,isSquare,robotName)

    local fbHead
    if fbid and fbid ~= "" and (tonumber(head) == 0 or head == "") then
        fbHead = self:getFacebookHead(fbid,parentNode:getContentSize(),isSquare)
    elseif robotName then 
        fbHead = self:getRobotHead(robotName,parentNode:getContentSize(),isSquare)
    else
        -- 没有登录facebook 或者 设置了自己默认的头像（设置自己头像为0但是你没有登录facebook默认显示1）
        if not head or tonumber(head) == 0 or head == "" then
            head = 1
        end
        fbHead = NetSpriteLua:create()
        if isSquare then
            fbHead:init("UserInformation/ui_head/UserInfo_touxiang_square_"..head..".png", parentNode:getContentSize())
        else  
            fbHead:init("UserInformation/ui_head/UserInfo_touxiang_" .. head .. ".png", parentNode:getContentSize())
        end
        
    end

    if fbHead then
        if isSquare then
            parentNode:addChild(fbHead)
        else  
            self:clipHeadNode(parentNode,fbHead,isSquare)
        end
    end

    return fbHead
end

--[[
    获取头像(不裁切)
]]
function HeadManager:getHeadWithOutClip(parentNode,fbid,head,isSquare,robotName)
    local fbHead
    if fbid and fbid ~= "" and (tonumber(head) == 0 or head == "") then
        fbHead = self:getFacebookHead(fbid,parentNode:getContentSize(),isSquare)
    elseif robotName then 
        fbHead = self:getRobotHead(robotName,parentNode:getContentSize(),isSquare)
    else
        -- 没有登录facebook 或者 设置了自己默认的头像（设置自己头像为0但是你没有登录facebook默认显示1）
        if not head or tonumber(head) == 0 or head == "" then
            head = 1
        end
        fbHead = NetSpriteLua:create()
        if isSquare then
            fbHead:init("UserInformation/ui_head/UserInfo_touxiang_square_"..head..".png", parentNode:getContentSize())
        else  
            fbHead:init("UserInformation/ui_head/UserInfo_touxiang_" .. head .. ".png", parentNode:getContentSize())
        end
        
    end

    if fbHead then
        parentNode:addChild(fbHead)
    end

    return fbHead
end


function HeadManager:release( )
    self:removeAllHeadInfo()
    self.m_headInfoList = {}
end

return HeadManager
