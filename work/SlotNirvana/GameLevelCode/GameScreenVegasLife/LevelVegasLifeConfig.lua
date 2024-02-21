--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelVegasLifeConfig = class("LevelVegasLifeConfig", LevelConfigData)

LevelVegasLifeConfig.SYMBOL_MYSTER = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
LevelVegasLifeConfig.m_MYSTER_RunSymbol = 0
LevelVegasLifeConfig.m_randomRoolIndex = 1 -- 表示随机的假滚数据id base free 等都有两组假滚数据 随机使用一组

LevelVegasLifeConfig.ccbNameTable = {
	"Socre_VegasLife_Bonus1",
	"Socre_VegasLife_Bonus2",
	"Socre_VegasLife_Bonus3",
	"Socre_VegasLife_Bonus4",
	"Socre_VegasLife_Bonus5",
}

function LevelVegasLifeConfig:ctor()
      LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelVegasLifeConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey

	-- 两组假滚数据 随机使用一组
	if self.m_randomRoolIndex == 1 then
		colKey = "reel_cloumn"..columnIndex
	else
		colKey = "reel_cloumn_1_"..columnIndex
	end
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
  function LevelVegasLifeConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	-- fsModelID等于1表示 super free，0表示普通free
	if fsModelID == 1 then
		-- 两组假滚数据 随机使用一组
		if self.m_randomRoolIndex == 1 then
			colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
		else
			colKey = string.format("freespinModeId_%d_%d",3,columnIndex)
		end
	else
		-- 两组假滚数据 随机使用一组
		if self.m_randomRoolIndex == 1 then
			colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
		else
			colKey = string.format("freespinModeId_%d_%d",2,columnIndex)
		end
	end

	for i=1,#self[colKey] do
		local symbolType =  self[colKey][i]
		if symbolType ==  self.SYMBOL_MYSTER then
		self[colKey][i] = self.m_MYSTER_RunSymbol
		end

	end

	return self[colKey]
end

function LevelVegasLifeConfig:setMysterSymbol( symbolType)
	if type(symbolType) == "number" then
		self.m_MYSTER_RunSymbol = symbolType
	end
end

function LevelVegasLifeConfig:setMysterRandomRoolIndex()
	self.m_randomRoolIndex = math.random(1,2)
end


function LevelVegasLifeConfig:getSymbolImageByCCBName(ccbName)
	if self.p_showScoreIamge == 0 then  -- 表明不使用图片滚动的方式来代替Node创建
		return nil
	end
	if self[ccbName] == nil then
		-- do nothing
		return nil
	end
	if self:checkInArray(ccbName, self.ccbNameTable) then
		return nil
	end

	return self[ccbName]
end

function LevelVegasLifeConfig:checkInArray(ccbName,array )
    local isIN = false
    for k,v in pairs(array) do
        if ccbName == v then
            isIN = true
        end
    end
    return isIN
end

return  LevelVegasLifeConfig