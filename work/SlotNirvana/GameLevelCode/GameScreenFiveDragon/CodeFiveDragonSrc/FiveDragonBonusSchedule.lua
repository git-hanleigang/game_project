---
--island
--2018年4月12日
--FiveDragonBonusSchedule.lua
--
-- FiveDragonBonusSchedule top bar

local FiveDragonBonusSchedule = class("FiveDragonBonusSchedule", util_require("base.BaseView"))
FiveDragonBonusSchedule.m_vecLantern = nil
-- 构造函数
function FiveDragonBonusSchedule:initUI()
    
    local resourceFilename="FiveDragon_lower_bet.csb"
    self:createCsbNode(resourceFilename)

    self.m_vecLantern = {}
    local index = 1
    while true do
        local node = self:findChild("node_" .. index )
        if node ~= nil then
            local lantern = util_createView("CodeFiveDragonSrc.FiveDragonLantern")
            node:addChild(lantern)
            self.m_vecLantern[index] = lantern
            -- lantern:initLantern(index <= data.currID)
        else
            break
        end
        index = index + 1
    end

    self:addClick(self:findChild("btn"))
end

function FiveDragonBonusSchedule:collect(index, func)
    self.m_vecLantern[index]:collect(func)
end

function FiveDragonBonusSchedule:reset()
    for i = 1, #self.m_vecLantern, 1 do
        self.m_vecLantern[i]:reset()
    end
end

function FiveDragonBonusSchedule:lock()
    self:runCsbAction("lock", false, function()
        self:runCsbAction("animation0", true)
    end)
end

function FiveDragonBonusSchedule:unlock()
    self:runCsbAction("unlock")
    local particle = cc.ParticleSystemQuad:create("Effect_FireDragon_jiesuo_yellow.plist")
    self:findChild("Node_1"):addChild(particle)
    particle:setPosition(-30, 20)
    particle:setAutoRemoveOnFinish(true)
end

function FiveDragonBonusSchedule:initStatus(betLevel, currID)
    if betLevel == 1 then
        self:runCsbAction("idleframe")
    else
        self:lock()
    end
    for i = 1, #self.m_vecLantern, 1 do
        self.m_vecLantern[i]:initLantern(i <= currID)
    end
end

function FiveDragonBonusSchedule:getCurrLanternPos(index)
    local worldPos = self.m_vecLantern[index]:getParent():convertToWorldSpace(cc.p(self.m_vecLantern[index]:getPosition()))
    return worldPos
end

function FiveDragonBonusSchedule:onEnter()
    
end

function FiveDragonBonusSchedule:onExit()
    
end

function FiveDragonBonusSchedule:setMachine(_machine)
    self.m_machine = _machine
end

function FiveDragonBonusSchedule:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_machine:showOrHideTips()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end

return FiveDragonBonusSchedule