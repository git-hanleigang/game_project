--[[
    网址信息
    author:{author}
    time:2021-11-07 15:33:03
]]
local URLInfo = class("URLInfo")

function URLInfo:ctor()
    self:init()
end

function URLInfo:init()
    -- 机器人头像
    self.m_robotDlUrl = ""
    -- 默认地址
    self.m_logRecordUrl = ""
    -- 入口服务器地址
    -- self.m_gateUrl = ""
    -- 数据服务器地址
    self.m_dataUrl = ""

    -- 热更地址
    self.m_hotUpdateUrl = ""
    -- 动态资源地址
    self.m_dynamicUrl = ""
    -- 关卡资源地址
    self.m_levelUrl = ""
end

function URLInfo:setDataUrl(url)
    self.m_dataUrl = url
end

function URLInfo:getDataUrl()
    return self.m_dataUrl
end

function URLInfo:getRobotUrl()
    return self.m_robotDlUrl
end

function URLInfo:getLogUrl()
    return self.m_logRecordUrl
end

-- 设置网关链接地址配置
function URLInfo:setGateUrlInfo(info)
    if not info then
        return
    end

    self.m_robotDlUrl = info.robotDlUrl
    self.m_logRecordUrl = info.logRecordUrl
    -- self.m_gateUrl = info.gateUrl
    self.m_dataUrl = info.dataUrl
end

function URLInfo:getHotResUrl()
    return self.m_hotUpdateUrl
end

function URLInfo:getDyResUrl()
    return self.m_dynamicUrl
end

function URLInfo:getLvResUrl()
    return self.m_levelUrl
end

-- 设置链接地址配置
function URLInfo:setServerUrlInfo(info)
    if not info then
        return
    end

    if info.hotUpdateURL then
        self.m_hotUpdateUrl = info.hotUpdateURL
    end
    if info.dynamicURL then
        self.m_dynamicUrl = info.dynamicURL
    end
    if info.levelUpdateURL then
        self.m_levelUrl = info.levelUpdateURL
    end
    if info.logURL then
        self.m_logRecordUrl = info.logURL
    end
end

function URLInfo:setHotResUrl(url)
    self.m_hotUpdateUrl = url or ""
end

function URLInfo:setLvResUrl(url)
    self.m_levelUrl = url or ""
end

function URLInfo:setDyResUrl(url)
    self.m_dynamicUrl = url or ""
end

return URLInfo
