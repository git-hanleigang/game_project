--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBunnysLockConfig = class("LevelBunnysLockConfig", LevelConfigData)

LevelBunnysLockConfig.m_bnBasePro1 = nil
LevelBunnysLockConfig.m_bnBaseTotalWeight1 = nil

function LevelBunnysLockConfig:parseSelfConfigData(colKey, colValue)
    if colKey == "BN_Base_pro" then
        self.m_bnBasePro , self.m_bnBaseTotalWeight = self:parsePro(colValue)
    elseif colKey == "reel_side" then
        self.m_side_reel = util_string_split(colValue,";",true)
    elseif colKey == "reel_mid" then
        self.m_mid_reel = util_string_split(colValue,";",true)
    elseif colKey == "reel_side_free" then
        self.m_side_reel_free = util_string_split(colValue,";",true)
    elseif colKey == "reel_mid_free" then
        self.m_mid_reel_free = util_string_split(colValue,";",true)
    elseif colKey == "reel_mid_special" then
        self.m_mid_reel_special = util_string_split(colValue,";",true)
    elseif colKey == "reel_normal" then
        self.m_normal_reel = util_string_split(colValue,";",true)
    elseif colKey == "reel_normal_free" then
        self.m_normal_reel_free = util_string_split(colValue,";",true)
    end
    
end
--[[
  time:2018-11-28 16:39:26
  @return: 返回中的倍数
]]
function LevelBunnysLockConfig:getBnBasePro()
    local value = self:getValueByPros(self.m_bnBasePro , self.m_bnBaseTotalWeight)
    return value[1]
end

--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues: 
    --@totalWeight: 
    @return:
]]
function LevelBunnysLockConfig:getValueByPros( proValues , totalWeight )
    local random = util_random(1,totalWeight)
    local preValue = 0
    local triggerValue = -1
    for i=1,#proValues do
        local value = proValues[i]
        if value[2] ~= 0 then
            if random > preValue and random <= preValue + value[2] then
                triggerValue = value
                break
            end
            preValue = preValue + value[2]
        end
    end

    return triggerValue

end

return  LevelBunnysLockConfig