--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-30 14:24:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-30 14:25:15
FilePath: /SlotNirvana/src/GameModule/MachineGrandShare/config/MachineGrandShareConfig.lua
Description: 关卡中大奖分享 config
--]]
local MachineGrandShareConfig = {}

-- 截屏目录
MachineGrandShareConfig.SCREENSHOT_DIR_NAME = "ScreenShot"
MachineGrandShareConfig.SCREENSHOT_DIR = device.writablePath ..  MachineGrandShareConfig.SCREENSHOT_DIR_NAME

-- 图片存储 目录名
MachineGrandShareConfig.IMG_DIRECTORY_NAME = "GrandShare"
MachineGrandShareConfig.IMG_DIRECTORY = device.writablePath .. MachineGrandShareConfig.IMG_DIRECTORY_NAME

MachineGrandShareConfig.EVENT_NAME = {
    DOWNLOAD_IMG_SUCCESS = "DOWNLOAD_GRAND_SHARE_IMG_SUCCESS", -- 下载分享图片
}

return MachineGrandShareConfig