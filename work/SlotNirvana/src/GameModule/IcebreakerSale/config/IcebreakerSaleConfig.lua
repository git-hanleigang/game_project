--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-31 14:03:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-31 14:03:32
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/config/IcebreakerSaleConfig.lua
Description: 新版 破冰促销 config
--]]
local IcebreakerSaleConfig = {}

IcebreakerSaleConfig.EVENT_NAME = {
    ICE_BREAKER_SALE_BUY_SUCCESS = "ICE_BREAKER_SALE_BUY_SUCCESS", -- 充值成功
    ICE_BREAKER_SALE_BUY_FAILED = "ICE_BREAKER_SALE_BUY_FAILED", -- 充值失败

    ICE_BREAKER_COLLECT_SUCCESS = "ICE_BREAKER_COLLECT_SUCCESS", --领取成功
    ICE_BREAKER_COLLECT_FAILED = "ICE_BREAKER_COLLECT_FAILED", --领取失败

    ICE_BREAKER_OVER = "ICE_BREAKER_OVER", -- 促销结束
}

return IcebreakerSaleConfig