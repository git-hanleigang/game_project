--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMonsterPartyConfig = class("LevelMonsterPartyConfig", LevelConfigData)

LevelMonsterPartyConfig.SYMBOL_MYSTER = 95
LevelMonsterPartyConfig.m_MYSTER_RunSymbol = 0

function LevelMonsterPartyConfig:ctor()
      LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelMonsterPartyConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey = "reel_cloumn"..columnIndex

	for i=1,#self[colKey] do
		local symbolType =  self[colKey][i]
		if symbolType ==  self.SYMBOL_MYSTER then
			self[colKey][i] = self.m_MYSTER_RunSymbol
		end

	end


	return self[colKey]
  end

  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelMonsterPartyConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	  local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	  for i=1,#self[colKey] do
		  local symbolType =  self[colKey][i]
		  if symbolType ==  self.SYMBOL_MYSTER then
			self[colKey][i] = self.m_MYSTER_RunSymbol
		  end

	  end

	  return self[colKey]
  end

function LevelMonsterPartyConfig:setMysterSymbol( symbolType)
	if type(symbolType) == "number" then
		self.m_MYSTER_RunSymbol = symbolType
	end
end


--[[
    @desc: 解析score 分数的image图片信息
    time:2019-05-07 17:03:38
    --@imageStr: 
    @return:
]]
function LevelMonsterPartyConfig:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs == 3 or #iamgeStrs == 4 then
		self[colKey] = iamgeStrs
	end
	
end


return  LevelMonsterPartyConfig