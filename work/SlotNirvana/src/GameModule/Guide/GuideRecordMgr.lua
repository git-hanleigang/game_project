--[[
    引导记录管理
    author:{author}
    time:2022-06-18 14:49:34
]]
local GuideRecordInfo = import(".GuideRecordInfo")
local GuideRecordMgr = class("GuideRecordMgr", BaseSingleton)

function GuideRecordMgr:ctor()
    GuideRecordMgr.super.ctor(self)
    self.m_recordInfos = {}
end

-- 解析保存的引导记录数据
function GuideRecordMgr:parseRecordData(infos, theme)
    theme = theme or ""
    if theme == "" then
        return
    end
    self.m_recordInfos["" .. theme] = {}
    for i = 1, #infos do
        local info = infos[i]
        if info then
            local _recInfo = GuideRecordInfo:create()
            _recInfo:parseRecord(info)
            if _recInfo:getGuideTheme() == theme then
                self:insertRecordInfo(_recInfo)
            end
        end
    end
end

function GuideRecordMgr:checkValid(guideName, guideTheme)
    guideName = guideName or ""
    guideTheme = guideTheme or ""
    if guideName == "" or guideTheme == "" then
        return false
    end
    return true
end

-- 添加引导记录信息
function GuideRecordMgr:insertRecordInfo(info)
    if not info then
        return
    end

    local guideTheme = info:getGuideTheme()
    local guideName = info:getGuideName()
    if not self:checkValid(guideName, guideTheme) then
        return
    end

    local infos = self.m_recordInfos[guideTheme]
    if not infos then
        self.m_recordInfos[guideTheme] = {}
    end

    self.m_recordInfos[guideTheme][guideName] = info
end
-- ===================================
-- 获得记录的引导步骤
function GuideRecordMgr:getGuideRecordStepId(guideName, guideTheme)
    local recordInfo = self:getGuideRecordInfo(guideName, guideTheme)
    if not recordInfo then
        -- 引导记录不存在
        return false, nil
    else
        return recordInfo:isStepOver(), recordInfo:getStepId()
    end
end

-- 设置引导记录
function GuideRecordMgr:setGuideRecordInfo(stepId, guideName, guideTheme)
    stepId = stepId or ""
    if stepId == "" then
        return
    end

    local _info = self:getGuideRecordInfo(guideName, guideTheme)
    if not _info then
        _info = GuideRecordInfo:create(stepId, guideName, guideTheme)
        self:insertRecordInfo(_info)
    else
        if not self:checkValid(guideName, guideTheme) then
            return
        end

        _info:setStepId(stepId)
    end
end

-- 获得引导记录信息
function GuideRecordMgr:getGuideRecordInfo(guideName, guideTheme)
    if not self:checkValid(guideName, guideTheme) then
        return nil
    end

    local _recordInfos = self.m_recordInfos[guideTheme]
    if not _recordInfos then
        return nil
    end
    return _recordInfos[guideName]
end

function GuideRecordMgr:getGuideRecords(guideTheme)
    guideTheme = guideTheme or ""
    return self.m_recordInfos[guideTheme]
end

-- 更新引导记录数据
function GuideRecordMgr:updateGuideRecord(stepInfo, guideName, guideTheme)
    if not stepInfo then
        return
    end

    local recordInfo = self:getGuideRecordInfo(guideName, guideTheme)
    if not recordInfo then
        return
    end

    -- 判断存档步骤
    local _archiveStep = stepInfo:getArchiveStep()
    if _archiveStep == "" then
        -- 保存下一步骤
        _archiveStep = stepInfo:getNextStep()
    end

    if recordInfo:getStepId() ~= _archiveStep then
        -- 更新引导步骤
        recordInfo:setStepId(_archiveStep)
    end
end

-- 设置引导结束
function GuideRecordMgr:setGuideStepOver(guideName, guideTheme)
    local recordInfo = self:getGuideRecordInfo(guideName, guideTheme)
    if not recordInfo then
        return
    end
    recordInfo:setStepOver(true)
end

-- 引导记录数据转字符串
function GuideRecordMgr:getGuideRecord2Str(guideTheme)
    local recordInfos = self:getGuideRecords(guideTheme)
    if not recordInfos then
        return
    end

    -- 存本地
    local tbData = {}
    for _, _value in pairs(recordInfos) do
        local _data = _value:getData()
        table.insert(tbData, _data)
    end
    local strRecords = cjson.encode(tbData)
    return strRecords
end

return GuideRecordMgr
