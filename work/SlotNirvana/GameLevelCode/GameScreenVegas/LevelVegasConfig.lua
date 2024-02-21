local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelVegasConfig = class("LevelVegasConfig", LevelConfigData)

function LevelVegasConfig:ctor()
    LevelConfigData.ctor(self)
end
function LevelVegasConfig:initMachine(machine)
	self.m_machine=machine
end



function LevelVegasConfig:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs == 4 then
		self[colKey] = iamgeStrs
	end
	
end


function LevelVegasConfig:parseSelfConfigData(colKey, colValue)
    
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
  end
  --[[
	time:2018-11-28 16:39:26
	@return: 返回中的倍数
  ]]
  function LevelVegasConfig:getFixSymbolPro( )
	local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	return value[1]
  end
  

return  LevelVegasConfig