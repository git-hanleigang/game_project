---
--xcyy
--2018年5月23日
--ColorfulCircusJackPotBarView.lua

local ColorfulCircusJackPotBarView = class("ColorfulCircusJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local jackpotTurnArray = {"major", "minor", "mini"}
local nameStr = {"grand", "major", "minor", "mini"}

function ColorfulCircusJackPotBarView:initUI(_csbPath, _machine)
    self.m_machine = _machine
    self:createCsbNode(_csbPath ..".csb")

    self.jackpotBarType = 0
    self.m_turnJackpotIdx = 1
    self.m_hitJackpotEffects = {}
    if _csbPath == "ColorfulCircus_respin_jackpot" then
        self.jackpotBarType = 1

        -- self:findChild("Node_mini"):setVisible(false)
        -- self:findChild("Node_minor"):setVisible(false)

        for i=1,4 do
            local effect = util_createAnimation("ColorfulCircus_jackpot_tx.csb")
            self:findChild(nameStr[i]):addChild(effect)
            self.m_hitJackpotEffects[i] = effect
            effect:setVisible(false)
        end

        self:runCsbAction("major", true)
        performWithDelay(self, function()
            self:turnJackpot()
        end, 2)
        
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function ColorfulCircusJackPotBarView:onEnter()

    ColorfulCircusJackPotBarView.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function ColorfulCircusJackPotBarView:onExit()
    ColorfulCircusJackPotBarView.super.onExit(self)
end

function ColorfulCircusJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function ColorfulCircusJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)
    if self.jackpotBarType == 0 then
        self:updateSize()
    else
        self:updateSize2()
    end
    
end

--用于respin
function ColorfulCircusJackPotBarView:updateSize2( )
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.8,sy=0.8}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.6,sy=0.6}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.6,sy=0.6}
    self:updateLabelSize(info1,445)
    self:updateLabelSize(info2,445)
    self:updateLabelSize(info3,445)
    self:updateLabelSize(info4,445)
end

function ColorfulCircusJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.8,sy=0.8}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.6,sy=0.6}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.6,sy=0.6}
    self:updateLabelSize(info1,444)
    self:updateLabelSize(info2,448)
    self:updateLabelSize(info3,446)
    self:updateLabelSize(info4,446)
end

function ColorfulCircusJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)

    -- if self.m_machine.m_respinMultiBar then
    --     value = value * self.m_machine.m_respinMultiBar
    -- end


    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function ColorfulCircusJackPotBarView:turnJackpot()
    if self.m_turnJackpotIdx > 3 then
        self.m_turnJackpotIdx = 1
    end
    
    -- local animNameStart = jackpotTurnArray[self.m_turnJackpotIdx] .. "_start"
    -- local animNameIdle = jackpotTurnArray[self.m_turnJackpotIdx] .. "_idle"
    -- local animNameOver = jackpotTurnArray[self.m_turnJackpotIdx] .. "_over"
    -- self:runCsbAction(animNameStart, false, function()
    --     self:runCsbAction(animNameIdle, true)
    --     performWithDelay(self, function()
    --         self:runCsbAction(animNameOver, false, function()
    --             self.m_turnJackpotIdx = self.m_turnJackpotIdx + 1
    --             self:turnJackpot()
    --         end)
    --     end, 2)
    -- end)

    local changeName = {{"major_minor", "minor"},{"minor_mini", "mini"},{"mini_major", "major"}}

    local animNameChange = changeName[self.m_turnJackpotIdx][1]
    local animNameIdle = changeName[self.m_turnJackpotIdx][2]

    self:runCsbAction(animNameChange, false, function()
        self:runCsbAction(animNameIdle, true)
        performWithDelay(self, function()
            self.m_turnJackpotIdx = self.m_turnJackpotIdx + 1
            self:turnJackpot()
        end, 2)
    end)
end

function ColorfulCircusJackPotBarView:setJackpotHitEffect(index)
    for i=1,#self.m_hitJackpotEffects do
        if i == index then
            self.m_hitJackpotEffects[i]:setVisible(true)
            self.m_hitJackpotEffects[i]:runCsbAction("actionframe", true)
        end
    end
end

function ColorfulCircusJackPotBarView:resetJackpotHitEffect()
    for i=1,#self.m_hitJackpotEffects do
        self.m_hitJackpotEffects[i]:setVisible(false)
    end
end


return ColorfulCircusJackPotBarView