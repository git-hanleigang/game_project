--[[
    新手期功能配置
    author:{author}
    time:2023-02-01 19:34:52
]]
local ActivityItemConfig = require("data.baseDatas.ActivityItemConfig")
local NoviceActivityItemConfig = class("NoviceActivityItemConfig", ActivityItemConfig)

function NoviceActivityItemConfig:parseData(data, ...)
    NoviceActivityItemConfig.super.parseData(self, data, ...)
    self.p_registerDays = tonumber(data.registerDays or 0)
    self.p_themeRes = data.activityTheme
    self.p_reference = data.activityName
    -- self.p_activityType = data.bigType
    self:parseABparams(data.clientParams)
end

-- 解析功能分组信息
function NoviceActivityItemConfig:parseABparams(params)
    self.p_abParams = {}
    params = params or ""
    if params ~= "" then
        local list1 = string.split(params, "|")
        for i = 1, #list1 do
            local list2 = string.split(list1[i], ":")
            self.p_abParams["" .. list2[1]] = list2[2]
        end
    end
end

-- 获得分组值
function NoviceActivityItemConfig:getABValue(posKey)
    return self.p_abParams["" .. posKey]
end

return NoviceActivityItemConfig
