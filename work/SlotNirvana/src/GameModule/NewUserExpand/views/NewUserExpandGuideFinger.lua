--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-27 15:35:13
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-27 15:35:22
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandGuideFinger.lua
Description: 扩圈系统 引导 手指
--]]
local ExpandGameMarqueeGuideFinger = class("ExpandGameMarqueeGuideFinger", BaseView)

function ExpandGameMarqueeGuideFinger:getCsbName()
    return "NewUser_Expend/Activity/csd/Guide/NewUser_Guide_Puzzle.csb"
end

function ExpandGameMarqueeGuideFinger:initUI()
    ExpandGameMarqueeGuideFinger.super.initUI(self)

    self:playShowFinger()
end

function ExpandGameMarqueeGuideFinger:playShowFinger()
    self:runCsbAction("idle", true)
end

return ExpandGameMarqueeGuideFinger