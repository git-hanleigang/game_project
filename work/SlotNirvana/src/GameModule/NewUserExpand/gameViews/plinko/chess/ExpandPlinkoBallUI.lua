--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-24 10:25:27
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-24 10:25:44
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoBallUI.lua
Description: 扩圈小游戏 弹珠 球
--]]
local ExpandPlinkoBallUI = class("ExpandPlinkoBallUI", BaseView)

function ExpandPlinkoBallUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Coinball.csb"
end

function ExpandPlinkoBallUI:initUI()
    ExpandPlinkoBallUI.super.initUI(self)

    -- 粒子
    -- local particleNode = self:findChild("Particle")
    -- particleNode:setPositionType(0)
end

function ExpandPlinkoBallUI:reset()
    self:move(0, 0)
    self:setVisible(false)
end

return ExpandPlinkoBallUI