--[[
    引导系统管理类
    author:{author}
    time:2022-06-18 14:26:20
]]
local GuideCfgInfo = import(".GuideCfgInfo")
local GuideStepInfo = import(".GuideStepInfo")
local GuideSignInfo = import(".GuideSignInfo")
local GuideTipInfo = import(".GuideTipInfo")
local GuideMgr = class("GuideMgr", BaseSingleton)

function GuideMgr:ctor()
    GuideMgr.super.ctor(self)
    self.m_guideCfg = {}
    -- 引导步骤信息列表
    self.m_stepInfos = {}
    -- 引导标记信号列表
    self.m_signInfos = {}
    -- 引导提示列表
    self.m_tipInfos = {}
end

-- =======引导配置=============
-- 解析引导配置
function GuideMgr:parseGuideCfgs(infos, theme)
    for i = 1, #infos do
        local info = infos[i]
        if info then
            -- local _refName = info.refName
            local _guideName = info.guideName
            local _guideCfg = self:getGuideCfgInfo(_guideName, theme)
            if not _guideCfg then
                _guideCfg = GuideCfgInfo:create()
                _guideCfg:parseData(info)
                self:insertGuideCfg(_guideCfg, theme)
            else
                _guideCfg:parseData(info)
            end
        end
    end
end

-- 插入引导配置信息
function GuideMgr:insertGuideCfg(_guideCfg, theme)
    if not _guideCfg then
        return
    end

    -- local _refName = _guideCfg:getRefName()
    local _guideName = _guideCfg:getGuideName()

    local cfgInfos = self.m_guideCfg[theme]
    if not cfgInfos then
        self.m_guideCfg[theme] = {}
    end

    self.m_guideCfg[theme][_guideName] = _guideCfg
end

-- 获得引导配置
function GuideMgr:getGuideCfgInfo(guideName, theme)
    theme = theme or ""
    guideName = guideName or ""
    local cfgInfos = self:getGuideCfgInfos(theme)
    if cfgInfos then
        return cfgInfos[guideName]
    else
        for key, value in pairs(self.m_guideCfg) do
            local cfgInfo = value[guideName]
            if cfgInfo then
                return cfgInfo
            end
        end
    end

    return nil
end

function GuideMgr:getGuideCfgInfos(theme)
    theme = theme or ""
    return self.m_guideCfg[theme]
end

-- ============引导信息相关===============
-- 解析引导数据
function GuideMgr:parseGuideStepInfos(infos, theme)
    for i = 1, #infos do
        local info = infos[i]
        if info then
            local _guideName = info.guideName
            local _stepId = info.stepId
            local _guideInfo = self:getGuideStepInfo(_stepId, theme)
            if not _guideInfo then
                _guideInfo = GuideStepInfo:create()
                _guideInfo:parseData(info)
                self:insertGuideStepInfo(_guideInfo, theme)
            else
                _guideInfo:parseData(info)
            end
        end
    end
end

-- 添加引导步骤信息
function GuideMgr:insertGuideStepInfo(info, theme)
    theme = theme or ""
    if not info or theme == "" then
        return
    end

    local _stepId = info:getStepId()
    -- local _guideName = guideName or info:getGuideName()
    local infos = self.m_stepInfos[theme]
    if not infos then
        self.m_stepInfos[theme] = {}
    end

    self.m_stepInfos[theme]["" .. _stepId] = info
end

-- 获得引导步骤信息
function GuideMgr:getGuideStepInfo(stepId, theme)
    if not stepId then
        return nil
    end

    local infos = self:getGuideStepInfosByRef(theme)
    if infos then
        return infos["" .. stepId]
    else
        -- 遍历所有模块的列表数据
        for _key, _value in pairs(self.m_stepInfos) do
            local _info = _value["" .. stepId]
            if _info then
                return _info
            end
        end
    end

    return nil
end

-- 获得模块引导信息列表
function GuideMgr:getGuideStepInfosByRef(theme)
    theme = theme or ""
    return self.m_stepInfos[theme]
end

-- ================ 引导标记信号 =====================
function GuideMgr:parseGuideSignInfos(infos, theme)
    for i = 1, #infos do
        local info = infos[i]
        if info then
            -- local _guideName = info.guideName
            local _signId = info.signId
            local _signInfo = self:getGuideSignInfo(_signId, theme)
            if not _signInfo then
                _signInfo = GuideSignInfo:create()
                _signInfo:parseData(info)
                self:insertGuideSignInfo(_signInfo, theme)
            else
                _signInfo:parseData(info)
            end
        end
    end
end

-- 添加引导标记信息
function GuideMgr:insertGuideSignInfo(info, theme)
    if not info then
        return
    end

    local _signId = info:getSignId()
    local infos = self.m_signInfos["" .. theme]
    if not infos then
        self.m_signInfos["" .. theme] = {}
    end

    self.m_signInfos["" .. theme]["" .. _signId] = info
end

-- 获得引导标记信号信息
function GuideMgr:getGuideSignInfo(signId, theme)
    if not signId then
        return nil
    end

    local _infos = self.m_signInfos["" .. theme]
    if not _infos then
        return nil
    else
        return _infos["" .. signId]
    end
end

-- ================ 引导提示Tip =====================
function GuideMgr:parseGuideTipInfos(infos, theme)
    for i = 1, #infos do
        local info = infos[i]
        if info then
            -- local _guideName = info.guideName
            local _tipId = info.tipId
            local _tipInfo = self:getGuideTipInfo(_tipId, theme)
            if not _tipInfo then
                _tipInfo = GuideTipInfo:create()
                _tipInfo:parseData(info)
                self:insertGuideTipInfo(_tipInfo, theme)
            else
                _tipInfo:parseData(info)
            end
        end
    end
end

-- 添加引导标记信息
function GuideMgr:insertGuideTipInfo(info, theme)
    if not info then
        return
    end

    local _tipId = info:getTipId()

    local infos = self.m_tipInfos["" .. theme]
    if not infos then
        self.m_tipInfos["" .. theme] = {}
    end

    self.m_tipInfos["" .. theme]["" .. _tipId] = info
end

-- 获得引导标记信号信息
function GuideMgr:getGuideTipInfo(tipId, theme)
    if not tipId then
        return nil
    end

    local _infos = self.m_tipInfos["" .. theme]
    if not _infos then
        return nil
    else
        return _infos["" .. tipId]
    end
end

return GuideMgr
