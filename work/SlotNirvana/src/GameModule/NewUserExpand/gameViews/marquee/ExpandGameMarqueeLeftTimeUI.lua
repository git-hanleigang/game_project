--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 15:12:26
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 15:12:42
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/ExpandGameMarqueeLeftTimeUI.lua
Description: 扩圈小游戏 跑马灯 剩余spin次数UI
--]]
local ExpandGameMarqueeLeftTimeUI = class("ExpandGameMarqueeLeftTimeUI", BaseView)

function ExpandGameMarqueeLeftTimeUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Leftgame.csb"
end

function ExpandGameMarqueeLeftTimeUI:initUI(_gameData) 
    ExpandGameMarqueeLeftTimeUI.super.initUI(self)

    self.m_gameData = _gameData

    -- spin剩余次数UI
    self:updateLbLeftTimeUI()
end

-- spin剩余次数UI
function ExpandGameMarqueeLeftTimeUI:updateLbLeftTimeUI()
    local leftCount = self.m_gameData:getLeftSpinCount()
    local lbCount = self:findChild("lb_leftgame")
    local str = string.format("GAME LEFT: %s", leftCount)
    lbCount:setString(str)
end

function ExpandGameMarqueeLeftTimeUI:onSpinSuccessEvt()
    self:updateLbLeftTimeUI()
    self:runCsbAction("start")
end

return ExpandGameMarqueeLeftTimeUI