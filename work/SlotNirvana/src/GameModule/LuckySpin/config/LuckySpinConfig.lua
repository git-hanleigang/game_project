--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-04 14:37:43
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-04 14:52:18
FilePath: /SlotNirvana/src/GameModule/LuckySpin/config/LuckySpinConfig.lua
Description: LuckySpin 配置
--]]
local LuckySpinConfig = {}

LuckySpinConfig.BUY_TYPE = {
    NORMAL = 1, -- 普通付费
    ENJOY = 2, -- 先享后付费
}

LuckySpinConfig.EVENT_NAME = {
    LUCKY_SPIN_BUY_SUCCESS = "LUCKY_SPIN_BUY_SUCCESS", --支付成功
}

return LuckySpinConfig