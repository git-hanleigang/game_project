--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:51:34
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:51:43
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/ExpandGamePlinkoLeftTimeUI.lua
Description: 扩圈小游戏 弹珠 剩余spin次数UI
--]]
local ExpandGamePlinkoLeftTimeUI = class("ExpandGamePlinkoLeftTimeUI", BaseView)

function ExpandGamePlinkoLeftTimeUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_LeftGame.csb"
end

function ExpandGamePlinkoLeftTimeUI:initUI(_gameData) 
    ExpandGamePlinkoLeftTimeUI.super.initUI(self)

    self.m_gameData = _gameData

    -- spin剩余次数UI
    self:updateLbLeftTimeUI()
end

-- spin剩余次数UI
function ExpandGamePlinkoLeftTimeUI:updateLbLeftTimeUI()
    local leftCount = self.m_gameData:getLeftSpinCount()
    local lbCount = self:findChild("lb_leftgame")
    local str = string.format("GAME LEFT: %s", leftCount)
    lbCount:setString(str)
end

function ExpandGamePlinkoLeftTimeUI:onSpinSuccessEvt()
    self:updateLbLeftTimeUI()
    self:runCsbAction("start")
end

return ExpandGamePlinkoLeftTimeUI