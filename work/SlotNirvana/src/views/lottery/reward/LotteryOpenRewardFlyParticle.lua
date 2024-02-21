--[[
Author: cxc
Date: 2021-12-13 15:36:54
LastEditTime: 2021-12-13 15:37:46
LastEditors: your name
Description: 乐透开奖每行金币粒子
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardFlyParticle.lua
--]]
local LotteryOpenRewardFlyParticle = class("LotteryOpenRewardFlyParticle", BaseView)

function LotteryOpenRewardFlyParticle:initUI()
    self:createCsbNode("Lottery/csd/Drawlottery/Lottery_Drawlottery_qiulizi.csb")

    local particle = self:findChild("Particle_1")
    particle:resetSystem()
    particle:setPositionType(0) 
end

return LotteryOpenRewardFlyParticle