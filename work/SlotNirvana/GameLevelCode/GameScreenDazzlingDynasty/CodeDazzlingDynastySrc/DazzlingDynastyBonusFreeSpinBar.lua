--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-06 15:34:50
]]

local DazzlingDynastyBonusFreeSpinBar = class("DazzlingDynastyBonusFreeSpinBar", util_require("base.BaseView"))
local CodeGameScreenDazzlingDynastyMachine = util_require("GameScreenDazzlingDynasty.CodeGameScreenDazzlingDynastyMachine")

function DazzlingDynastyBonusFreeSpinBar:initUI()
    self:createCsbNode("DazzlingDynasty_freespin.csb")
    self.lbCount = self:findChild("nm_zi")
    self.lastSpin = self:findChild("last_spin")
    self.freeSpins = self:findChild("free_spins")
    self.freeSpin = self:findChild("free_spin")
    self.particleNode = self:findChild("particleNode")
    local collectEffect = cc.ParticleSystemQuad:create("Effect/tx_lizi_shouji_fangkuang.plist")--
    self.collectEffect = collectEffect
    collectEffect:setBlendFunc({ src = GL_ONE, dst = GL_ONE })
    collectEffect:setVisible(false)
    collectEffect:setPosition(0,0)
    self.particleNode:addChild(collectEffect)
end

function DazzlingDynastyBonusFreeSpinBar:setCount(count)
    self.lbCount:setString(count)
    if count > 0 then
        if count == 1 then
            self.lbCount:setVisible(true)
            self.lastSpin:setVisible(false)
            self.freeSpins:setVisible(false)
            self.freeSpin:setVisible(true)
        else
            self.lbCount:setVisible(true)
            self.lastSpin:setVisible(false)
            self.freeSpins:setVisible(true)
            self.freeSpin:setVisible(false)
        end
    else
        self.lbCount:setVisible(false)
        self.lastSpin:setVisible(true)
        self.freeSpins:setVisible(false)
        self.freeSpin:setVisible(false)
    end
end

function DazzlingDynastyBonusFreeSpinBar:playCollectEffect()
    local collectEffect = self.collectEffect
    collectEffect:setVisible(true)
    collectEffect:resetSystem()
    performWithDelay(collectEffect,
    function() 
        collectEffect:setVisible(false) 
    end,2)
end

return DazzlingDynastyBonusFreeSpinBar