---
--xcyy
--2018年5月23日
--GhostCaptainControlBetView.lua

local GhostCaptainControlBetView = class("GhostCaptainControlBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "GhostCaptainPublicConfig"

function GhostCaptainControlBetView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("GhostCaptain_collect.csb")
    self.m_itemTab = {}
    self:addClick(self:findChild("Panel_1"))
    for index = 1, 5 do
        local item = util_createAnimation("GhostCaptain_collect_jindu.csb")
        self:findChild("Node_"..index):addChild(item)
        table.insert(self.m_itemTab, item)
    end
end

function GhostCaptainControlBetView:onEnter()
 
    GhostCaptainControlBetView.super.onEnter(self)
end

function GhostCaptainControlBetView:showAdd()
    
end

function GhostCaptainControlBetView:onExit()
    GhostCaptainControlBetView.super.onExit(self)
end

function GhostCaptainControlBetView:updateColItem(_col)
    for index = 1, #self.m_itemTab do
        self.m_itemTab[index]:findChild("golden"):setVisible(index <= (_col+1))
    end
end

--[[
    更新金币显示
]]
function GhostCaptainControlBetView:updateCoins(_index)
    local strCoins = self.m_machine:getBetLevelCoins(_index+1)
    local strCoins = util_formatCoins(strCoins, 3)
    self:findChild("m_lb_coins_1"):setString(strCoins)
end

--默认按钮监听回调
function GhostCaptainControlBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_1" then
        self:setUI()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_click)
    end
end

function GhostCaptainControlBetView:setUI()
    gLobalNoticManager:postNotification("OPEN_CHOOSEVIEW")
end

--[[
    压暗
]]
function GhostCaptainControlBetView:playDarkEffect( )
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

--[[
    变亮
]]
function GhostCaptainControlBetView:playUnDarkEffect( )
    self:runCsbAction("over", false, function()
        self:playIdle2()
    end)
end

function GhostCaptainControlBetView:playIdle2( )
    self:runCsbAction("idle2", true)
end

function GhostCaptainControlBetView:playIdle3()
    self:runCsbAction("idle3", true)
end

return GhostCaptainControlBetView