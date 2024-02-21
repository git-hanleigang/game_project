---
--xcyy
--2018年5月23日
--GhostBlasterJackPotBarView.lua
local GhostBlasterPublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterJackPotBarView = class("GhostBlasterJackPotBarView", util_require("base.BaseView"))

local SuperName = "m_lb_coins"

function GhostBlasterJackPotBarView:initUI()
    self:createCsbNode("GhostBlaster_super.csb")
    self:runIdleAni()

    self.m_lockStatus = false

    self.m_lockAni = util_spineCreate("GhostBlaster_jackpot",true,true)
    self:findChild("Node_2"):addChild(self.m_lockAni)
    self.m_lockAni:setVisible(false)

    self.m_btn_click = self:findChild("btn_click")

    self:addClick(self.m_btn_click)
end

function GhostBlasterJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function GhostBlasterJackPotBarView:onEnter()
    GhostBlasterJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function GhostBlasterJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(SuperName), 1, true)

    self:updateSize()
end

function GhostBlasterJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[SuperName]
    local info1 = {label = label1, sx = 0.535, sy = 0.535}
    self:updateLabelSize(info1, 935)
end

function GhostBlasterJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

--[[
    变更显示
]]
function GhostBlasterJackPotBarView:changeShow(status)
    self:findChild("Node_base"):setVisible(status == "base")
    self:findChild("Node_FG"):setVisible(status == "free")
end

--[[
    idle
]]
function GhostBlasterJackPotBarView:runIdleAni()
    self:runCsbAction("idle",true)
end

--[[
    初始化锁定状态
]]
function GhostBlasterJackPotBarView:initLockStatus(isLock)
    self.m_lockStatus = isLock
    if isLock then
        self:showLockAni(isLock)
    end
    
end

--[[
    设置锁定状态
]]
function GhostBlasterJackPotBarView:setLockStatus(isLock)
    if self.m_lockStatus == isLock then
        return
    end

    self.m_lockAni:stopAllActions()
    if isLock then
        self:showLockAni()
    else
        self:unLockAni()
    end
    self.m_lockStatus = isLock
end

--[[
    显示锁
]]
function GhostBlasterJackPotBarView:showLockAni(func)
    self.m_lockAni:setVisible(true)
    util_spinePlay(self.m_lockAni,"suoding")
    util_spineEndCallFunc(self.m_lockAni,"suoding",function()
        if type(func) == "function" then
            func()
        end
    end)
    self.m_btn_click:setVisible(true)
    gLobalSoundManager:playSound(GhostBlasterPublicConfig.Music_Bet_Lock)
    
    self:runCsbAction("suoding")
end

--[[
    解锁动画
]]
function GhostBlasterJackPotBarView:unLockAni(func)
    gLobalSoundManager:playSound(GhostBlasterPublicConfig.Music_Bet_UnLock)
    self:runCsbAction("jiesuo",false,function()
        self:runIdleAni()
    end)
    self.m_btn_click:setVisible(false)
    util_spinePlay(self.m_lockAni,"jiesuo")
    util_spineEndCallFunc(self.m_lockAni,"jiesuo",function()
        self.m_lockAni:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    获得jackpot高亮动画
]]
function GhostBlasterJackPotBarView:hitJackpotLightAni()
    self:runCsbAction("actionframe2",true)
end

--默认按钮监听回调
function GhostBlasterJackPotBarView:clickFunc(sender)
    if not self.m_lockStatus or not self.m_machine:collectBarClickEnabled() then
        return
    end

    self.m_machine.m_bottomUI:changeBetCoinNumToHight()
    self.m_btn_click:setVisible(false)
end

return GhostBlasterJackPotBarView
