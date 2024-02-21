--[[
    服务器管理
    author:{author}
    time:2021-11-07 15:32:31
]]
local LoginConfig = require("GameLogin.LoginConfig")
local URLInfo = require("GameLogin.URLInfo")
local LoginMgr = class("LoginMgr")

function LoginMgr:ctor()
    self._instance = nil

    -- 服务器信息
    self.m_urlInfo = URLInfo:create()
    -- 链接模式
    self.m_linkMode = ""
    -- 资源版本类型
    self.m_resMode = ""

    self.m_isAdsDebug = false
end

--[[
    @desc: 获得单例对象
    author:徐袁
    time:2020-12-19 15:16:24
    @return:
]]
function LoginMgr:getInstance()
    if not self._instance then
        self._instance = self.__index:create()
    end
    return self._instance
end

function LoginMgr:init()
    self.m_urlInfo:init()

    self:loadLocalInfo()
end

-- 加载本地配置
function LoginMgr:loadLocalInfo()
    if CC_IS_RELEASE_NETWORK then
        self:setLinkModeInfo(LinkMode.Online)

        self:setResModeInfo(ResMode.Online)

        DATA_SEND_URL = self.m_urlInfo:getDataUrl()
    else
        -- 链接模式
        local _linkMode = gLobalDataManager:getStringByField("LinkServerMode", "")
        self:setLinkModeInfo(LinkMode[_linkMode])

        -- 资源更新版本
        local _resMode = gLobalDataManager:getStringByField("ResServerMode", "")
        self:setResModeInfo(ResMode[_resMode])

        -- 数据地址
        local _serverId = gLobalDataManager:getStringByField("TestServerId", "")
        -- 兼容老版本保存的地址
        if _serverId == "" then
            local testSelfUrl = gLobalDataManager:getStringByField("TestSelfUrl", "")
            if testSelfUrl ~= "" then
                _serverId = string.sub(testSelfUrl, string.find(testSelfUrl, "%d+$"))
                gLobalDataManager:setStringByField("TestSelfUrl", "")
                gLobalDataManager:setStringByField("TestServerId", _serverId)
            end
            self:setDataServer(_serverId)
        else
            local _st, _ed = string.find(tostring(_serverId), "^http")
            if not _st then
                self:setDataServer(_serverId)
            else
                DATA_SEND_URL = _serverId
            end
        end
    end
end

-- 选择链接资源模式
function LoginMgr:selResMode(modeInfo)
    if self:isSeledResMode() or not modeInfo then
        return false
    end

    self:setResModeInfo(modeInfo)

    gLobalDataManager:setStringByField("ResServerMode", modeInfo.key)

    return true
end

-- 保存链接的资源版本类型
function LoginMgr:setResModeInfo(modeInfo)
    if not modeInfo then
        return
    end

    self.m_resMode = modeInfo.key

    return true
end

-- 获得链接的资源版本类型
function LoginMgr:getResModeInfo()
    return ResMode[self.m_resMode]
end

function LoginMgr:getResMode()
    return self.m_resMode
end

-- 是否选择上线资源
function LoginMgr:isSelReleaseRes()
    if CC_IS_RELEASE_NETWORK then
        return false
    end

    if self.m_resMode == ResMode.Release.key or self.m_resMode == ResMode.ReleaseB.key then
        return true
    else
        return false
    end
end

-- 是否 支持小版本热更
function LoginMgr:isSupportLowUpdateVzip()
    if CC_IS_RELEASE_NETWORK then
        return false
    end

    if self.m_resMode == ResMode.Release.key or self.m_resMode == ResMode.ReleaseB.key or 
        self.m_resMode == ResMode.Beta.key or self.m_resMode == ResMode.Alpha.key then
        return true
    else
        return false
    end
end

-- 线上资源
function LoginMgr:isSelOnlineRes()
    if self.m_resMode == ResMode.Online.key then
        return true
    else
        return false
    end
end

-- 是否选择了资源模式
function LoginMgr:isSeledResMode()
    local _resMode = self.m_resMode or ""
    if not ResMode[_resMode] then
        return false
    else
        return true
    end
end

-- 是否选择了链接模式
function LoginMgr:isSeledLinkMode()
    local _linkMode = self.m_linkMode or ""
    if not LinkMode[_linkMode] then
        return false
    else
        return true
    end
end

-- 获得链接信息
function LoginMgr:getLinkModeInfo()
    return LinkMode[self.m_linkMode]
end

-- 获得联网类型
function LoginMgr:getLinkType()
    return self.m_linkMode or ""
end

-- 设置链接模式
function LoginMgr:setLinkModeInfo(modeInfo)
    if not modeInfo then
        return
    end

    self.m_linkMode = modeInfo.key

    self:setGateUrlInfo(modeInfo)
end

-- 选择链接模式
function LoginMgr:selLinkMode(modeInfo)
    if self:isSeledLinkMode() or not modeInfo then
        return
    end

    self:setLinkModeInfo(modeInfo)

    gLobalDataManager:setStringByField("LinkServerMode", modeInfo.key)
end

-- 设置链接入口服信息
function LoginMgr:setGateUrlInfo(linkMode)
    if not linkMode then
        return
    end

    local _key = linkMode.key or ""
    local _info = LinkConfig[_key]
    if not _info then
        return
    end

    self.m_urlInfo:setGateUrlInfo(_info)
end

-- 选中数据服务器
function LoginMgr:selDataServer(serverId)
    -- if self:setDataServer(serverId) then
    --     gLobalDataManager:setStringByField("TestServerId", tostring(serverId))
    -- end
    return self:setDataServer(serverId)
end

-- 设置数据服务器
function LoginMgr:setDataServer(serverId)
    if not serverId or serverId == "" then
        return false
    end

    local url = ""
    if not self:isSelOnlineRes() then
        local _st, _ed = string.find(tostring(serverId), "^http")
        if not _st then
            -- 默认拼个地址
            url = "http://127.0.0." .. serverId

            local _linkInfo = self:getLinkModeInfo()
            if not _linkInfo then
                return false
            end
            local _cfgInfo = LinkConfig[_linkInfo.key]
            if not _cfgInfo then
                return false
            end

            url = self:switchUrlL2W(url, _cfgInfo.dataUrl, _cfgInfo.dataPort)
        else
            url = serverId
        end
    else
        url = serverId
    end

    self:setDataUrl(url)
    DATA_SEND_URL = url

    return true
end

function LoginMgr:getDataUrl()
    return self.m_urlInfo:getDataUrl()
end

function LoginMgr:isValidUrl(url)
    return url and (url ~= "")
end

-- 设置地址信息
function LoginMgr:setServerUrlInfo(info)
    -- self.m_urlInfo:setServerUrlInfo(info)
    self:setHotResUrl(info.hotUpdateURL)

    self:setDyResUrl(info.dynamicURL)

    self:setLvResUrl(info.levelUpdateURL)

    self:setDataUrl(info.dataSendURL)

    -- 日志服地址
    LOG_RecordServer = self.m_urlInfo:getLogUrl()
    -- 热更服地址
    Android_VERSION_URL = self.m_urlInfo:getHotResUrl()
    -- 关卡下载地址
    LEVELS_ZIP_URL = self.m_urlInfo:getLvResUrl()
    -- 动态下载地址
    DYNAMIC_DOWNLOAD_URL = self.m_urlInfo:getDyResUrl()
    -- 机器人头像
    ROBOT_DOWNLOAD_URL = self.m_urlInfo:getRobotUrl()
    -- 数据服地址
    DATA_SEND_URL = self.m_urlInfo:getDataUrl()
end

-- 内网地址转外网地址
function LoginMgr:switchUrlL2W(str, wAddr, port)
    if not str or str == "" then
        return ""
    end

    -- 判断是否是线上网址
    local ft, _ = string.find(str, "https://.+%.com")
    if ft then
        return str
    end

    if not wAddr or wAddr == "" then
        return str
    end

    local st, ed = string.find(str, "%d+%.%d+%.%d+%.%d+")
    local ip = string.sub(str, st, ed)
    -- IP末尾数字
    local edNum = string.sub(ip, string.find(ip, "%d+$"))

    -- 提取IP地址
    -- local _ip = string.sub(wAddr, string.find(wAddr, "%d+%.%d+%.%d+%.%d+"))
    -- if _ip then
    --     wAddr = _ip
    -- end

    if port then
        wAddr = wAddr .. ":" .. tostring(port)
    end

    -- 判断是否有 [:数字]或[.数字] 结尾
    local st2, ed2 = string.find(wAddr, "[%.:]%d+$")
    if (ed2 - st2) > 3 then
        wAddr = string.gsub(wAddr, "%d%d%d$", string.format("%03d", tonumber(edNum)))
    else
        wAddr = string.gsub(wAddr, "%d+$", tostring(edNum))
    end

    str = string.gsub(str, "[a-z]*://%d+%.%d+%.%d+%.%d+", wAddr)
    return str
end

function LoginMgr:setDataUrl(url)
    if not self:isValidUrl(url) then
        return
    end
    self.m_urlInfo:setDataUrl(url)
end

function LoginMgr:setHotResUrl(url)
    if not self:isValidUrl(url) then
        return
    end
    if self:getLinkType() == "W2L" and not self:isSelOnlineRes() then
        local _info = LinkConfig.W2L or {}
        url = self:switchUrlL2W(url, _info.resUrl, _info.resPort)
    end
    self.m_urlInfo:setHotResUrl(url)
end

function LoginMgr:setLvResUrl(url)
    if not self:isValidUrl(url) then
        return
    end
    if self:getLinkType() == "W2L" and not self:isSelOnlineRes() then
        local _info = LinkConfig.W2L or {}
        url = self:switchUrlL2W(url, _info.resUrl, _info.resPort)
    end
    self.m_urlInfo:setLvResUrl(url)
end

function LoginMgr:setDyResUrl(url)
    if not self:isValidUrl(url) then
        return
    end
    if self:getLinkType() == "W2L" and not self:isSelOnlineRes() then
        local _info = LinkConfig.W2L or {}
        url = self:switchUrlL2W(url, _info.resUrl, _info.resPort)
    end
    self.m_urlInfo:setDyResUrl(url)
end

function LoginMgr:setTestAddress(_address)
    self.m_address = _address
end

function LoginMgr:getTestAddress()
    return self.m_address or ""
end

-- 使用线上资源验证服务器
function LoginMgr:setIsTestOnlineRes(_bValue)
    self.m_bTestOnlineRes = _bValue
end
function LoginMgr:checkIsTestOnlineRes()
    return self.m_bTestOnlineRes
end

function LoginMgr:setAdsDebug(bValue)
    self.m_isAdsDebug = bValue or false
end

function LoginMgr:isAdsDebug()
    return self.m_isAdsDebug
end

return LoginMgr
