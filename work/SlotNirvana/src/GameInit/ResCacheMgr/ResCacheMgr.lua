--[[

    author:{author}
    time:2022-01-18 12:19:06
]]
local ResCachePlist = nil
local ResCacheSpine = nil

local ResCacheMgr = class("ResCacheMgr", BaseSingleton)

function ResCacheMgr:ctor()
    ResCacheMgr.super.ctor(self)

    self:clearResLists()
end

function ResCacheMgr:isOpen()
    local verInfo = globalData.GameConfig:getVerInfo()

    return verInfo["isOpenResCache"] or false
end

-- 移除资源
function ResCacheMgr:removeRes(path)
    local resInfo = self.m_tbResList[path]
    if resInfo then
        resInfo:decRef()
    end
end

-- 清理资源
function ResCacheMgr:cleanupRes(path)
    path = path or ""
    local _value = self.m_tbResList[path]
    if _value and _value:getRef() == 0 then
        _value:cleanup()
        self.m_tbResList[path] = nil
    end
end

-- 清理plist资源列表
function ResCacheMgr:clearResLists()
    self.m_tbResList = {}
end

-- =============== 合图Plist资源相关 ===================
-- 添加plist资源信息
function ResCacheMgr:insertPlistInfo(path)
    if not self:isOpen() then
        return
    end
    
    if not path or type(path) ~= "string" or path == "" then
        return
    end

    local resInfo = self.m_tbResList[path]
    if not resInfo then
        if not ResCachePlist then
            ResCachePlist = require("GameInit.ResCacheMgr.ResCachePlist")
        end
        resInfo = ResCachePlist:create()
        resInfo:parseData(path)
        self.m_tbResList["" .. resInfo:getName()] = resInfo
    end
    resInfo:addRef()
end

-- 合并plist资源列表
function ResCacheMgr:mergePlistInfos(infos)
    if not self:isOpen() then
        return
    end

    infos = infos or {}
    for i = 1, #infos do
        self:insertPlistInfo(infos[i])
    end
end

-- ==================Spine资源========================
-- 添加spine资源信息
function ResCacheMgr:insertSpineInfo(atlas, skel, isBinary)
    if not self:isOpen() then
        return
    end

    if not atlas or type(atlas) ~= "string" or atlas == "" then
        return
    end

    if not skel or type(skel) ~= "string" or skel == "" then
        return
    end

    local resInfo = self.m_tbResList[atlas]
    if not resInfo then
        if not ResCacheSpine then
            ResCacheSpine = require("GameInit.ResCacheMgr.ResCacheSpine")
        end
        resInfo = ResCacheSpine:create()
        resInfo:parseData(atlas, skel, isBinary)
        self.m_tbResList["" .. resInfo:getName()] = resInfo
    end
    resInfo:addRef()
end
-- ==================================================

-- 清理不使用的资源内存
function ResCacheMgr:removeUnusedResCache()
    util_nextFrameFunc(
        function()
            for _key, _value in pairs(self.m_tbResList) do
                if _value and _value:getRef() == 0 then
                    _value:cleanup()
                    self.m_tbResList[_key] = nil
                end
            end

            if device.platform ~= "mac" then
                if self:isOpen() then
                    -- display.removeUnusedSpriteFrames()
                    -- 不使用的合图资源
                    cc.SpriteFrameCache:getInstance():removeUnusedPlistSpriteFrames()
                end
            end
            -- 不使用的散图
            local textureCache = cc.Director:getInstance():getTextureCache()
            textureCache:removeUnusedTextures()
        end
    )
end

return ResCacheMgr
