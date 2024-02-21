---
--xcyy
--2018年5月23日
--WildGorillaFreeSpinTipView.lua
-- FIX IOS 139
local WildGorillaFreeSpinTipView = class("WildGorillaFreeSpinTipView", util_require("base.BaseView"))

function WildGorillaFreeSpinTipView:initUI()
    self:createCsbNode("WildGorilla_fs_tip.csb")
    self:runCsbAction("idle", true)
    local superNode = self:findChild("wenben")
    self.m_superCsb = util_createAnimation("WildGorilla_wenben.csb")
    superNode:addChild(self.m_superCsb)
    self:createNormalFsNode()
    self.m_superCsb:runCsbAction("saoguang1", true)
    local touch = self.m_superCsb:findChild("touch")
    self:addClick(touch)

    local chong = self:findChild("chongNode")
    self.m_chong = util_spineCreate("Socre_WildGorilla_chong", true, true)
    chong:addChild(self.m_chong)
    util_spinePlay(self.m_chong, "animation", true)

    self.m_tipsCsb = util_createAnimation("WildGorilla_wenben_1.csb")
    local tipsNode = self:findChild("tipsNode")
    tipsNode:addChild(self.m_tipsCsb)
    self.m_tipsCsb:setVisible(false)
end

function WildGorillaFreeSpinTipView:createNormalFsNode()
    self.m_normalFsCsb = {}
    for i = 1, 5 do
        local fsNode = util_createAnimation("WildGorilla_shouji.csb")
        local str = "shouji" .. i
        local Node = self:findChild(str)
        Node:addChild(fsNode)
        self.m_normalFsCsb[i] = fsNode
        fsNode:setVisible(false)
    end
end

function WildGorillaFreeSpinTipView:showFreeSpinCount(_num)
    for i = 1, _num do
        self.m_normalFsCsb[i]:setVisible(true)
        self.m_normalFsCsb[i]:runCsbAction("idle")
    end
    -- self.m_superCsb:runCsbAction("idle")
    if _num == 5 then
    -- self.m_superCsb:runCsbAction("saoguang1", true)
    end
end

function WildGorillaFreeSpinTipView:resetFreeSpinCount()
    for i = 1, 5 do
        self.m_normalFsCsb[i]:setVisible(false)
    end
    -- self.m_superCsb:runCsbAction("idle")
end

function WildGorillaFreeSpinTipView:updataFreeSpinCount(_num)
    self.m_normalFsCsb[_num]:setVisible(true)
    self.m_normalFsCsb[_num]:runCsbAction("shouji")
    local partical = self.m_normalFsCsb[_num]:findChild("Particle_1")
    partical:resetSystem()
    partical:setPositionType(0)
    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_normal_collect.mp3")
    if _num == 5 then
    -- self.m_superCsb:runCsbAction("saoguang1", true)
    -- gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_super_collect.mp3")
    end
end

--默认按钮监听回调
function WildGorillaFreeSpinTipView:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        self:showOrHideTips()
    end
end

function WildGorillaFreeSpinTipView:onEnter()
end

function WildGorillaFreeSpinTipView:onExit()
end

function WildGorillaFreeSpinTipView:showOrHideTips()
    if self.m_tipsCsb:isVisible() then
        self:hideTips()
    else
        self:showTips()
    end
end

function WildGorillaFreeSpinTipView:showTips()
    self.m_tipsCsb:setVisible(true)
    self.m_tipsCsb:runCsbAction("tanbanstar")
end

function WildGorillaFreeSpinTipView:hideTips()
    if self.m_tipsCsb:isVisible() then
        self.m_tipsCsb:runCsbAction(
            "tanbanover",
            false,
            function()
                self.m_tipsCsb:setVisible(false)
            end
        )
    end
end

return WildGorillaFreeSpinTipView
