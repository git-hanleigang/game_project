local BaseActivityData = require "baseActivity.BaseActivityData"
local DIYFeatureMissionRewardBuffData = class("DIYFeatureMissionRewardBuffData", BaseActivityData)


-- message DiyFeatureBuff{
--     optional string buffType = 1; //buff类型
--     optional string desc = 2; //buff描述
--     optional string value = 3; //buff值
--     optional int32 level = 4; //buff等级
-- }

function DIYFeatureMissionRewardBuffData:parseData(data)
    DIYFeatureMissionRewardBuffData.super.parseData(self, data)
    self.m_buffType = data.buffType
    -- self.m_desc = data.desc
    -- self.m_value = data.value
    self.m_level = tonumber(data.level)
end

function DIYFeatureMissionRewardBuffData:getBuffType()
    return  self.m_buffType
end
function DIYFeatureMissionRewardBuffData:getBuffLevel()
    return  self.m_level
end

return DIYFeatureMissionRewardBuffData