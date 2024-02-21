---
--xcyy
--2018年5月23日
--PudgyPandaMapItem.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaMapItem = class("PudgyPandaMapItem",util_require("Levels.BaseLevelDialog"))
PudgyPandaMapItem.m_isClick = false

function PudgyPandaMapItem:initUI(_machine, _mapView, _index)

    self.m_machine = _machine
    self.m_mapView = _mapView
    self.m_index = _index
    self:createCsbNode("PudgyPanda_shouji_FG_Map.csb")
    
    local freeNodeTbl = {"Node_FG", "Node_superFG", "Node_megaFG"}
    for k, _nodeName in pairs(freeNodeTbl) do
        self:findChild(_nodeName):setVisible(k==self.m_index)
    end

    self:setIdle()
end

--默认按钮监听回调
function PudgyPandaMapItem:clickFunc(sender)
    local name = sender:getName()

    if name == "Button" and self:isCanTouch() then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_PudgyPanda_click)
        self:playTriggerAction()
    end
end

-- idle：未到收集进度
function PudgyPandaMapItem:setIdle()
    self:setCilckState(false)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
end

-- 当前解锁
function PudgyPandaMapItem:setUnLock(_index)
    self:setCilckState(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle2", true)
end

-- 按钮触发
function PudgyPandaMapItem:playTriggerAction()
    self:setCilckState(false)
    util_resetCsbAction(self.m_csbAct)
    self.m_mapView:setCilckState(false)
    self:runCsbAction("actionframe", false, function()
        self.m_mapView:sendFreeTypeData(self.m_index)
    end)
end

function PudgyPandaMapItem:setCilckState(_isClick)
    self.m_isClick = _isClick
end

function PudgyPandaMapItem:isCanTouch()
    return self.m_isClick
end

return PudgyPandaMapItem
