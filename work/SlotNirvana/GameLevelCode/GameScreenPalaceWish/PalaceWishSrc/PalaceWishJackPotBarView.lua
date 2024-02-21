---
--xcyy
--2018年5月23日
--PalaceWishJackPotBarView.lua

local PalaceWishJackPotBarView = class("PalaceWishJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "lbl_grand"
local MajorName = "lbl_major"
local MinorName = "lbl_minor"

function PalaceWishJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("PalaceWish_jackpot.csb")

    -- self:runIdle()

    self:findChild("Particle_1"):stopSystem()
    self:findChild("Particle_2"):stopSystem()
    self:findChild("Particle_3"):stopSystem()
    self:findChild("Particle_4"):stopSystem()
    self:findChild("Particle_5"):stopSystem()
    self:findChild("Particle_6"):stopSystem()
end

function PalaceWishJackPotBarView:runIdle(type)
    if type == 1 then
        self:runCsbAction("idle", true)
    else
        self:runCsbAction("idle2", true)
    end
    
end

--中jackpot时
function PalaceWishJackPotBarView:runJackpot(type, jackpotType)
    
    if type == 1 then
        self:runCsbAction("actionframe", true)
    else
        self:runCsbAction("actionframe2", true)
    end

    self:findChild("grand"):setVisible(false)
    self:findChild("major"):setVisible(false)
    self:findChild("minor"):setVisible(false)
    if jackpotType == 1 then
        --grand
        self:findChild("grand"):setVisible(true)
        self:findChild("Particle_1"):resetSystem()
        self:findChild("Particle_2"):resetSystem()
    elseif jackpotType == 2 then
        self:findChild("major"):setVisible(true)
        self:findChild("Particle_3"):resetSystem()
        self:findChild("Particle_4"):resetSystem()
    elseif jackpotType == 3 then 
        self:findChild("minor"):setVisible(true)
        self:findChild("Particle_5"):resetSystem()
        self:findChild("Particle_6"):resetSystem()
    end
end
--收集粒子到位反馈
function PalaceWishJackPotBarView:runCollect(jackpotType)
    local animName = "shouji1"
    if jackpotType == 1 then
        animName = "shouji1"
    elseif jackpotType == 2 then
        animName = "shouji2"
    elseif jackpotType == 3 then 
        animName = "shouji3"
    end
    self:runCsbAction(animName, false, function()
        self:runJackpot(2, jackpotType)
    end)
end

function PalaceWishJackPotBarView:onEnter()

    PalaceWishJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function PalaceWishJackPotBarView:onExit()
    PalaceWishJackPotBarView.super.onExit(self)
end

function PalaceWishJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function PalaceWishJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)

    self:updateSize()
end

function PalaceWishJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.77,sy=0.77}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.74,sy=0.74}
    self:updateLabelSize(info1,410)
    self:updateLabelSize(info2,360)
    self:updateLabelSize(info3,360)
end

function PalaceWishJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function PalaceWishJackPotBarView:getJackpotLabel( type )
    if type == 1 then
        return self:findChild("lbl_grand")
    elseif type == 2 then
        return self:findChild("lbl_major")
    elseif type == 3 then
        return self:findChild("lbl_minor")
    end
end


return PalaceWishJackPotBarView