--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelAfricaRiseConfig = class("LevelAfricaRiseConfig", LevelConfigData)

function LevelAfricaRiseConfig:ctor()
    LevelConfigData.ctor(self)
end

function LevelAfricaRiseConfig:initMachine(machine)
	self.m_machine=machine
end

return  LevelAfricaRiseConfig