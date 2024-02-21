--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-09 16:32:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-09 16:39:47
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/marquee/MiniGameMarqueeData.lua
Description: 扩圈小游戏 跑马灯
--]]
local MiniGameCommonData = util_require("GameModule.NewUserExpand.model.common.MiniGameCommonData")
local MiniGameMarqueeData = class("MiniGameMarqueeData", MiniGameCommonData)

function MiniGameCommonData:getGameDataLuaPath()
    return "GameModule.NewUserExpand.model.marquee.MarqueeTaskGameData"
end

return MiniGameMarqueeData