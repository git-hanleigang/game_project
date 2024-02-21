--[[
    引导步骤信息
    author:{author}
    time:2022-06-18 14:26:09
]]
local GuideStepInfo = class("GuideStepInfo")

function GuideStepInfo:ctor()
    -- 当前步骤
    self.m_stepId = nil
    -- 引导名
    self.m_guideName = ""
    -- 功能名
    self.m_refName = ""
    -- 下一步
    self.m_nextStep = nil
    -- 是否强引导
    self.m_isCoerce = true
    -- 标记信号
    self.m_signIds = ""
    -- 是否存档点
    self.m_archiveStep = ""
    -- 阶段步骤
    -- self.m_stageStep = ""
    -- lua名称
    self.m_luaName = ""
    -- tip信息
    self.m_tipIds = ""
    -- 默认阻断触摸
    self.m_isSwallow = true
    -- 完成事件
    self.m_cplEvent = ""
    -- 背景透明度
    self.m_opacity = 192
end

function GuideStepInfo:parseData(info)
    self.m_stepId = info.stepId or ""
    self.m_guideName = info.guideName or ""
    self.m_refName = info.refName or ""
    self.m_nextStep = info.nextStep or ""
    self.m_archiveStep = info.archiveStep or ""
    self:setSignIds(info.signIds)
    self:setTipIds(info.tipIds)
    self:setCoerce(info.isCoerce)
    -- lua名称
    self.m_luaName = info.luaName or ""
    self:setSwallow(info.isSwallow)
    self.m_opacity = info.opacity or 192
    self.m_cplEvent = info.event or ""
end

function GuideStepInfo:getStepId()
    return self.m_stepId or ""
end

-- 完成事件
function GuideStepInfo:getCplEvent()
    return self.m_cplEvent or ""
end

-- 引导名
function GuideStepInfo:getGuideName()
    return self.m_guideName or ""
end

function GuideStepInfo:getNextStep()
    return self.m_nextStep or ""
end

-- 是否强制引导
function GuideStepInfo:isCoerce()
    return self.m_isCoerce or false
end

function GuideStepInfo:setCoerce(isCoerce)
    if type(isCoerce) == "string" then
        self.m_isCoerce = (isCoerce == "true")
    else
        self.m_isCoerce = isCoerce
    end
end

-- 是否阻断触摸
function GuideStepInfo:isSwallow()
    if self:isCoerce() then
        -- 强引导阻断
        return true
    end
    return self.m_isSwallow
end

function GuideStepInfo:setSwallow(isSwallow)
    if isSwallow == nil then
        return
    end
    self.m_isSwallow = isSwallow
end

function GuideStepInfo:getOpacity()
    return self.m_opacity
end

-- 获得存档步骤
function GuideStepInfo:getArchiveStep()
    return self.m_archiveStep or ""
end

-- 是否是最后一步
function GuideStepInfo:isFinalStep()
    local stepId = self:getStepId()
    return (stepId ~= "") and (stepId == self.m_nextStep)
end

function GuideStepInfo:getRefName()
    return self.m_refName
end

function GuideStepInfo:setSignIds(signIds)
    signIds = signIds or ""
    if signIds ~= "" then
        self.m_signIds = string.split(signIds or "", "|")
    end
end

function GuideStepInfo:getSignIds()
    return self.m_signIds
end

function GuideStepInfo:setTipIds(tipIds)
    tipIds = tipIds or ""
    if tipIds ~= "" then
        self.m_tipIds = string.split(tipIds or "", "|")
    end
end

function GuideStepInfo:getTipIds()
    return self.m_tipIds
end

function GuideStepInfo:getLuaName()
    return self.m_luaName or ""
end

return GuideStepInfo
