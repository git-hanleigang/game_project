--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-23 16:05:42
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-23 16:05:46
FilePath: /SlotNirvana/src/views/cashBonus/cashBonusMain/CashBonusConfig.lua
Description: CashBonus 
--]]
local CashBonusConfig = {}

local csbPath = "CashCommon/csd/DailyBonusAddEf/"

CashBonusConfig.commonCsb = {
    CashPickDeluxeAdd = csbPath .. "CashPickDeluxeAdd.csb",
    CashPickGameVipAdd = csbPath .. "CashPickGameVipAdd.csb",
    DailyBonusResultLayer_division = csbPath .. "DailyBonusResultLayer_division.csb",
    DailybonusRewardX = csbPath .. "DailybonusRewardX.csb",
}

return CashBonusConfig