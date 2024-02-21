--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 17:20:35
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 17:43:16
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoArrowAniUI.lua
Description: 扩圈小游戏 弹珠 箭头动画UI
--]]
local ExpandPlinkoArrowAniUI = class("ExpandPlinkoArrowAniUI", BaseView)

function ExpandPlinkoArrowAniUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Arrowhead.csb"
end

function ExpandPlinkoArrowAniUI:initUI()
    ExpandPlinkoArrowAniUI.super.initUI(self)

    self:runCsbAction("idle", true)
end

return ExpandPlinkoArrowAniUI