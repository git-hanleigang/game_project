--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-25 10:59:04
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-25 15:13:21
FilePath: /SlotNirvana/src/GameModule/FirstSaleMulti/config/FirstSaleMultiConfig.lua
Description: 三档首充 config
--]]
local FirstSaleMultiConfig = {}

FirstSaleMultiConfig.EVENT_NAME = {
    FIRST_SALE_MULTI_PAY_SUCCESS = "FIRST_SALE_MULTI_PAY_SUCCESS", --支付成功
    FIRST_SALE_MULTI_PAY_FAILD = "FIRST_SALE_MULTI_PAY_FAILD", --支付失败
}
ViewEventType.NOTIFY_REMOVE_FIRST_SALE_MULTI_HALL_SLIDE = "NOTIFY_REMOVE_FIRST_SALE_MULTI_HALL_SLIDE" --移除 轮播展示
return FirstSaleMultiConfig