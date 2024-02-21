--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-13 10:32:42
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-13 10:32:55
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/machine/MarqueeBigStartAniUI.lua
Description: 扩圈游戏 跑马灯 开始ani
--]]
local MarqueeBigStartAniUI = class("MarqueeBigStartAniUI", BaseView)

function MarqueeBigStartAniUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Show_logo.csb"
end

-- 策划要求播两遍
function MarqueeBigStartAniUI:playStarAni(_cb)
    -- local cb = function()
    --     self:runCsbAction("idle", false, _cb, 60)
    -- end
    -- self:runCsbAction("idle", false, cb, 60)
    self:runCsbAction("idle", true)
end

return MarqueeBigStartAniUI