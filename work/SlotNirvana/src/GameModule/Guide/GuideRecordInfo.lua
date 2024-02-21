--[[
    引导记录
    author:{author}
    time:2022-06-18 14:35:27
]]

local GuideRecordInfo = class("GuideRecordInfo")

function GuideRecordInfo:ctor(stepId, guideName, guideTheme)
    self.m_guideTheme = guideTheme or ""
    self.m_guideName = guideName or ""
    self.m_stepId = stepId
    self.m_isStepOver = false
end

function GuideRecordInfo:parseRecord(data)
    self.m_guideTheme = data.gTh
    self.m_guideName = data.gNa
    self.m_stepId = data.stId
    self.m_isStepOver = data.stRe
end

function GuideRecordInfo:getData()
    return {
        gTh = self.m_guideTheme,
        gNa = self.m_guideName,
        stId = self.m_stepId,
        stRe = self.m_isStepOver
    }
end

function GuideRecordInfo:getGuideName()
    return self.m_guideName
end

function GuideRecordInfo:getGuideTheme()
    return self.m_guideTheme
end

function GuideRecordInfo:getStepId()
    return self.m_stepId
end

function GuideRecordInfo:setStepId(stepId)
    self.m_stepId = stepId
end

function GuideRecordInfo:isStepOver()
    return self.m_isStepOver
end

function GuideRecordInfo:setStepOver(isOver)
    self.m_isStepOver = isOver or false
end



return GuideRecordInfo
