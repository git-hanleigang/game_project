
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFruitFarmConfig = class("LevelFruitFarmConfig", LevelConfigData)
local FruitFarmBaseData = require "CodeFruitFarmSrc.FruitFarmBaseData"

LevelFruitFarmConfig.m_bnBasePro1 = nil
LevelFruitFarmConfig.m_bnBaseTotalWeight1 = nil

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelFruitFarmConfig:ctor()
      LevelConfigData.ctor(self)
end

function LevelFruitFarmConfig:parseSelfConfigData(colKey,colValue)
	if colKey == "BN_Base1_pro"  then
		self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelFruitFarmConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local spin_num = FruitFarmBaseData:getInstance():getDataByKey("spin_num")
    local betLevel = FruitFarmBaseData:getInstance():getDataByKey("betLevel")
    local key = 0
    if spin_num == 10 then  -- 10且高倍  key = 2
        key = 1
        if betLevel == 2 then
            key = 2
        end
    end
    local colKey = string.format("reel_cloumn_%d_%d", key, columnIndex)
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelFruitFarmConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
    --低倍 1 2  高倍 3 4
    local betLevel = FruitFarmBaseData:getInstance():getDataByKey("betLevel")
    local bet = betLevel == 2 and 2 or 0  -- 高倍为2
    local row_max = FruitFarmBaseData:getInstance():getDataByKey("row_max")
    local max_num = row_max[columnIndex] and 1 or 0
    fsModelID = bet + max_num

    local   colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	return self[colKey]
end

function LevelFruitFarmConfig:getFixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

  
return  LevelFruitFarmConfig