--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:08
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:21:54
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/config/TomorrowGiftConfig.lua
Description: 次日礼物 config 配置
--]]
local TomorrowGiftConfig = {}

TomorrowGiftConfig.EVENT_NAME = {
    ONRECIEVE_COLLECT_TOMORROW_GIFT_RQE = "ONRECIEVE_COLLECT_TOMORROW_GIFT_RQE", -- 次日礼物领取成功
    NOTICE_PLAY_TOMORROW_GIFT_SPIN_COUNT_ADD_ANI = "NOTICE_PLAY_TOMORROW_GIFT_SPIN_COUNT_ADD_ANI", -- spin 播放入口动效
    NOTICE_REMOVE_TOMORROW_GIFT_MACHINE_ENTRY = "NOTICE_REMOVE_TOMORROW_GIFT_MACHINE_ENTRY", -- 移除关卡右边条入口
    NOTICE_SHOW_TOMORROW_GIFT_MACHINE_ENTRY = "NOTICE_SHOW_TOMORROW_GIFT_MACHINE_ENTRY", --可领奖后 右边条隐藏 把它显示出来
}

return TomorrowGiftConfig