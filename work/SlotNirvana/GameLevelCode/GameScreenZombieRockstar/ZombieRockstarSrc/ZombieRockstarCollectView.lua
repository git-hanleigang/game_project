---
--xcyy
--2018年5月23日
--ZombieRockstarCollectView.lua
local ZombieRockstarCollectView = class("ZombieRockstarCollectView", util_require("base.BaseView"))
local ZombieRockstarPublicConfig = require "ZombieRockstarPublicConfig"
function ZombieRockstarCollectView:initUI(params)
    self.m_machine = params.machine
    self.m_index = params.index
    self.m_collectSymbolList = {}
    self:createCsbNode("ZombieRockstar_base_collect_left.csb")

    for index = 1, 3 do
        self:findChild("juese"..index):setVisible(index == self.m_index)

        local collectSymbolNode = util_createAnimation("ZombieRockstar_base_collect_left2.csb")
        self:findChild(self.m_index.."_"..index):addChild(collectSymbolNode)
        self.m_collectSymbolList[index] = collectSymbolNode
    end
end

function ZombieRockstarCollectView:onEnter()
    ZombieRockstarCollectView.super.onEnter(self)
end

function ZombieRockstarCollectView:onExit()
    ZombieRockstarCollectView.super.onExit(self)
end

--[[
    更新收集区
]]
function ZombieRockstarCollectView:updateCollectNum(_num, _isEnter, _isChangeBet, _isShow)
    if _isEnter then
        for index = 1, 3 do
            if index <= _num then
                self.m_collectSymbolList[index]:setVisible(true)
                self.m_collectSymbolList[index]:runCsbAction("idle", true)
            else
                self.m_collectSymbolList[index]:setVisible(false)
            end
        end
        if _num == 0 then
            util_resetCsbAction(self.m_collectSymbolList[3].m_csbAct)
            util_resetCsbAction(self.m_csbAct)
            self:runCsbAction("idle1")
            if _isChangeBet then
                if not _isShow then
                    self.m_machine.m_triggerBuffEffect:setVisible(false)
                end
            end
        else
            self:runCsbAction("idle".._num, true)
            if _num == 3 then
                if _isChangeBet then
                    self.m_machine.m_triggerBuffEffect:setVisible(true)
                    self.m_machine.m_triggerBuffEffect:runCsbAction("idle", true)
                else
                    self.m_machine:playShowTriggerBuffEffect()
                end
            else
                if _isChangeBet then
                    if not _isShow then
                        self.m_machine.m_triggerBuffEffect:setVisible(false)
                    end
                end
            end
        end
    else
        gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_collect_symbol_fly_end)
        self.m_collectSymbolList[_num]:setVisible(true)
        self.m_collectSymbolList[_num]:runCsbAction("start", false, function()
            self.m_collectSymbolList[_num]:runCsbAction("idle", true)
            if _num <= 2 then
                if _num == 1 then
                    self:runCsbAction("idle".._num, true)
                else
                    self:runCsbAction("switch", false, function()
                        self:runCsbAction("idle".._num, true)
                    end)
                end
            else
                gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_collect_jiman)
                self:runCsbAction("idle3", true)
                self.m_machine:playShowTriggerBuffEffect()
            end
        end)
    end
end

return ZombieRockstarCollectView
