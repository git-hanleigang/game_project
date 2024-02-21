--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelZeusConfig = class("LevelZeusConfig", LevelConfigData)


--[[
    @desc: 解析score 分数的image图片信息
    time:2019-05-07 17:03:38
    --@imageStr: 
    @return:
]]
function LevelZeusConfig:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs == 3 or #iamgeStrs == 4 then
		self[colKey] = iamgeStrs
	end
	
end


function LevelZeusConfig:parseSelfConfigData(colKey, colValue)
    
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
  end
  --[[
	time:2018-11-28 16:39:26
	@return: 返回中的倍数
  ]]
  function LevelZeusConfig:getFixSymbolPro( )
	local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	return value[1]
  end

return  LevelZeusConfig