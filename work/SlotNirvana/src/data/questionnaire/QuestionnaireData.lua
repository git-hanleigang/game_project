--[[--
    调查问卷 数据
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"

local QuestionnaireData = class("QuestionnaireData", BaseActivityData)

function QuestionnaireData:parseNormalActivityData(data)
    QuestionnaireData.super.parseNormalActivityData(self, data)

    if self:getExpireAt() > 0 then
        if self:getLeftTime() > 0 then
            self.p_open = true
        end
    end
end

function QuestionnaireData:parseData(data, isNetData)
    QuestionnaireData.super.parseData(self, data, isNetData)
end

function QuestionnaireData:isRunning()
    if not QuestionnaireData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- 检查完成条件
function QuestionnaireData:checkCompleteCondition()
    if gLobalDataManager:getBoolByField(self:getClientCacheKey(), false) == true then
        return true
    end
    return false
end

function QuestionnaireData:getClientCacheKey()
    return "Questionnaire_" .. self:getExpireAt()
end

return QuestionnaireData
