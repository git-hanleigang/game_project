--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBankCrazeConfig = class("LevelBankCrazeConfig", LevelConfigData)

LevelBankCrazeConfig.m_bnCoinsPro = nil
LevelBankCrazeConfig.m_bnCoinsTotalWeight = nil

LevelBankCrazeConfig.m_bnJackpotTypePro = nil
LevelBankCrazeConfig.m_bnJackpotTypeTotalWeight = nil

LevelBankCrazeConfig.m_bnFreeTimesPro = nil
LevelBankCrazeConfig.m_bnFreeTimesTotalWeight = nil

function LevelBankCrazeConfig:ctor()
	LevelBankCrazeConfig.super.ctor(self)
end

function LevelBankCrazeConfig:parseSelfConfigData(colKey, colValue)
	if colKey == "BN_Coins_pro" then
		self.m_bnCoinsPro , self.m_bnCoinsTotalWeight = self:parsePro(colValue)
	elseif colKey == "BN_JckpotType_pro" then
		self.m_bnJackpotTypePro , self.m_bnJackpotTypeTotalWeight = self:parsePro(colValue)
	elseif colKey == "BN_FreeTimes_pro" then
		self.m_bnFreeTimesPro , self.m_bnFreeTimesTotalWeight = self:parsePro(colValue)
	end
end

-- coins
-- jackpot
-- free
function LevelBankCrazeConfig:getCurBonusTypeReward(_playTypeStr)
	local playTypeStr = _playTypeStr
	local value = self:getValueByPros(self.m_bnCoinsPro, self.m_bnCoinsTotalWeight)
	if playTypeStr == "coins" then
		value = self:getValueByPros(self.m_bnCoinsPro, self.m_bnCoinsTotalWeight)
	elseif playTypeStr == "jackpot" then
		value = self:getValueByPros(self.m_bnJackpotTypePro, self.m_bnJackpotTypeTotalWeight)
	elseif playTypeStr == "free" then
		value = self:getValueByPros(self.m_bnFreeTimesPro, self.m_bnFreeTimesTotalWeight)
	end

	return value[1]
end


return LevelBankCrazeConfig
