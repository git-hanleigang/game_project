---
--xcyy
--2018年5月23日
--PudgyPandaCollectItem.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaCollectItem = class("PudgyPandaCollectItem",util_require("Levels.BaseLevelDialog"))

function PudgyPandaCollectItem:initUI(_machine, _index)

    self.m_machine = _machine
    self.m_index = _index
    self:createCsbNode("PudgyPanda_shouji_FG.csb")
    
    local freeNodeTbl = {"Node_FG", "Node_superFG", "Node_megaFG"}
    for k, _nodeName in pairs(freeNodeTbl) do
        self:findChild(_nodeName):setVisible(k==self.m_index)
    end

    self:setIdle()
end

-- idle：未到收集进度
function PudgyPandaCollectItem:setIdle()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
end

-- idle2：到达收集进度
function PudgyPandaCollectItem:setSpecialIdle()
    self:runCsbAction("idle2", true)
end

-- 触发
function PudgyPandaCollectItem:playTriggerAction(_endCallFunc)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Trigger_Free_Action)
    local endCallFunc = _endCallFunc
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:setSpecialIdle()
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end)
end

return PudgyPandaCollectItem
