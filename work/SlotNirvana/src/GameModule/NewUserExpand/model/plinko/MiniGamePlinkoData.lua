--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-23 19:48:54
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-23 20:03:25
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/plinko/MiniGamePlinkoData.lua
Description: 扩圈小游戏 弹球
--]]
local MiniGameCommonData = util_require("GameModule.NewUserExpand.model.common.MiniGameCommonData")
local MiniGamePlinkoData = class("MiniGamePlinkoData", MiniGameCommonData)

function MiniGamePlinkoData:getGameDataLuaPath()
    return "GameModule.NewUserExpand.model.plinko.PlinkoTaskGameData"
end

return MiniGamePlinkoData