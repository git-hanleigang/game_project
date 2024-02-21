--[[
    弹框规则
    author:{author}
    time:2019-10-14 10:54:37
]]
local PopRule = class("PopRule")

function PopRule:getInstance()
    if not self._instance then
        self._instance = PopRule.new()
    end
    return self._instance
end

function PopRule:ctor()
    -- levelUp弹出规则
    self.m_lvUpRule = {}
end

-- 获得升级时  模块的弹出规则
function PopRule:getLvUpRuleByProgram(popUpName)
    local _rule = self.m_lvUpRule[popUpName]
    if not _rule then
        return {}
    else
        return _rule
    end
end

-- 解析升级弹出规则
function PopRule:parseLevelUpRule(tbRule)
    if not tbRule then
        return
    end

    self.m_lvUpRule = tbRule
end

-- 判断功能模块弹出属性
function PopRule:checkProgramPopRule(popUpInfo)
    local popStep = PopStep[popUpInfo:getPopupName()]
    if not popStep then
        printInfo("不存在弹板" .. popUpInfo:getPopupName())
        return
    end

    -- 无规则直接返回true
    if popStep.noRule then
        return true
    end

    if PopProgramMgr:isActivityProgram(popUpInfo) then
        local activity = G_GetActivityDataByRef(popStep.program)
        if not activity then
            return false
        end
        -- if activity:isEnd() then
        --     return false
        -- end

        if activity.checkPopRule and not activity:checkPopRule(popUpInfo:getPosId(), popStep) then
            return false
        end

        return true
    elseif popUpInfo:getPopupName() == PopStep.LevelUpExpendTip.name then
        if popUpInfo:getPosId() == PopViewPos.PopPos_LevelUp then
            -- return self:checkLvUpRule(popUpInfo.programName)
            return true
        end
        return false
    elseif popUpInfo:getPopupName() == PopStep.NormalLevelUp.name then
        -- elseif popUpInfo.programName == PopStep.NumberLevelUp.name then
        --     -- 升级下拉
        --     if popUpInfo.pos == PopViewPos.PopPos_LevelUp then
        --         return true
        --     end
        --     return false
        -- 升级弹框
        if popUpInfo:getPosId() == PopViewPos.PopPos_LevelUp then
            -- return self:checkLvUpRule(popUpInfo.programName)
            return true
        end
        return false
    elseif popUpInfo:getPopupName() == PopStep.levelUp.name then
        local pos = PopViewPos[PopStep.levelUp.popKey]
        if not pos then
            return false
        end
        if not GameRunTimeData:getLevelUp() then
            return false
        end
        return true
    else
        return true
    end
end

--[[
    @desc: 检测升级规则
    author:{author}
    time:2019-10-14 11:48:02
    --@popUpName: 
    @return:
]]
-- function PopRule:checkLvUpRule(popUpName)
--     local rules = self:getLvUpRuleByProgram(popUpName)
--     for i = 1, #rules do
--         local result = self:checkLvUpInfo(rules[i])
--         if result then
--             return true
--         end
--     end

--     return false
-- end

-- 升级规则信息判断
-- function PopRule:checkLvUpInfo(ruleInfo)
--     local curLevel = globalData.userRunData.levelNum
--     if ruleInfo.type == "1" then
--         -- 固定等级
--         local lvList = string.split(ruleInfo.fixLevel, ";")
--         for i = 1, #lvList do
--             local level = lvList[i]
--             if tonumber(level) == curLevel then
--                 return true
--             end
--         end
--     elseif ruleInfo.type == "2" then
--         -- 等级范围
--         local lvLeft = tonumber(ruleInfo.levelLeft)
--         local lvRight = tonumber(ruleInfo.levelRight)
--         local lvRepeat = tonumber(ruleInfo.levelRepeat)
--         local checkLv = lvLeft
--         while curLevel > lvLeft do
--             if lvRight > 0 and (checkLv > lvRight or curLevel > lvRight) then
--                 break
--             end

--             checkLv = checkLv + lvRepeat

--             if checkLv == curLevel then
--                 return true
--             elseif checkLv > curLevel then
--                 break
--             end
--         end
--     end

--     return false
-- end

GD.PopRule = PopRule:getInstance()
