--[[
    引导配置
    author:{author}
    time:2022-06-18 17:07:58
]]
local GuideCfgInfo = class("GuideCfgInfo")

function GuideCfgInfo:ctor()
    self.m_id = nil
    -- 功能名
    self.m_refName = ""
    -- 引导名
    self.m_guideName = ""
    -- 起始步骤
    self.m_startStep = nil
    -- 前置完成
    self.m_preGuides = {}
end

function GuideCfgInfo:parseData(info)
    self.m_id = info.id or ""
    self.m_refName = info.refName or ""
    self.m_guideName = info.guideName or ""
    self.m_startStep = info.startStep or ""
    self:setPreGuides(info.preGuides or "")
end

-- 引导名
function GuideCfgInfo:getGuideName()
    return self.m_guideName
end

function GuideCfgInfo:getStartStep()
    return self.m_startStep
end

function GuideCfgInfo:getRefName()
    return self.m_refName
end

function GuideCfgInfo:setPreGuides(preGuide)
    preGuide = preGuide or ""
    if preGuide ~= "" then
        self.m_preGuides = string.split(preGuide, "|")
    end
end

function GuideCfgInfo:getPreGuides()
    return self.m_preGuides
end

return GuideCfgInfo
