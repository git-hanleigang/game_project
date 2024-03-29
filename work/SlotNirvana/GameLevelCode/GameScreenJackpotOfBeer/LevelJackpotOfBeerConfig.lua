--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelJackpotOfBeerConfig = class("LevelJackpotOfBeerConfig", LevelConfigData)

LevelJackpotOfBeerConfig.m_bnBasePro1 = nil
LevelJackpotOfBeerConfig.m_bnBaseTotalWeight1 = nil
LevelJackpotOfBeerConfig.m_isDuanXianComIn = false

function LevelJackpotOfBeerConfig:setIsDuanXian(states)
    self.m_isDuanXianComIn = states
end

function LevelJackpotOfBeerConfig:parsePro( value )
    local verStrs = util_string_split(value,";")

    local proValues = {}
    local totalWeight = 0
    for i=1,#verStrs do
        local proValue = verStrs[i]
        local vecPro = util_string_split(proValue,"-" , true)

        proValues[#proValues + 1] = vecPro
        totalWeight = totalWeight + vecPro[2]
    end
    return proValues , totalWeight
end

function LevelJackpotOfBeerConfig:parseSelfConfigData(colKey, colValue)
    
    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelJackpotOfBeerConfig:getFixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues: 
    --@totalWeight: 
    @return:
]]
function LevelJackpotOfBeerConfig:getValueByPros( proValues , totalWeight )
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

---
-- 根据ccb name 获取信号图片
--
function LevelConfigData:getSymbolImageByCCBName(ccbName)
    -- 断线进来的时候 不使用图片
    if self.m_isDuanXianComIn then
        return nil
    end

    if self.p_showScoreIamge == 0 then  -- 表明不使用图片滚动的方式来代替Node创建
        return nil
    end

	if self[ccbName] == nil then
		-- do nothing
		return nil
	end

	return self[ccbName]
end

return  LevelJackpotOfBeerConfig