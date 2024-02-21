---
--xcyy
--2018年5月23日
--ManicMonsterJackPotBarView.lua

local ManicMonsterJackPotBarView = class("ManicMonsterJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function ManicMonsterJackPotBarView:initUI()

    self:createCsbNode("ManicMonster_jackpot.csb")
    
    self:runCsbAction("idle2")

    self.m_grandBan = util_createAnimation("ManicMonster_jackpot_Ban.csb")
    self:findChild("ManicMonster_jackpot_grand"):addChild(self.m_grandBan)
    local posA = cc.p(self.m_grandBan:findChild("jp_node_1"):getPosition())
    local posB = cc.p(self.m_grandBan:findChild("jp_node_3"):getPosition())
    self.m_grandBan:findChild("jp_node_1"):setPosition(posB)
    self.m_grandBan:findChild("jp_node_3"):setPosition(posA)
    self.m_grandBan:findChild("Node_light_1"):setVisible(false)
    

    self.m_majorBan = util_createAnimation("ManicMonster_jackpot_Ban.csb")
    self:findChild("ManicMonster_jackpot_major"):addChild(self.m_majorBan)
    self.m_majorBan:findChild("Node_light_2"):setVisible(false)

    self.m_minorBan = util_createAnimation("ManicMonster_jackpot_Ban.csb")
    self:findChild("ManicMonster_jackpot_minor"):addChild(self.m_minorBan)
    self.m_minorBan:findChild("jp_node_1"):setPosition(posB)
    self.m_minorBan:findChild("jp_node_3"):setPosition(posA)
    self.m_minorBan:findChild("Node_light_1"):setVisible(false)

    self.m_miniBan = util_createAnimation("ManicMonster_jackpot_Ban.csb")
    self:findChild("ManicMonster_jackpot_mini"):addChild(self.m_miniBan)
    self.m_miniBan:findChild("Node_light_2"):setVisible(false)

    local imgName = {"Sprite_hong","Sprite_zi","Sprite_lan","Sprite_lv"}

    for i=1,3 do

        self.m_grandBan["jp_dian_"..i] = util_createAnimation("ManicMonster_jackpot_qiu.csb") 
        self.m_grandBan:findChild("jp_node_"..i):addChild(self.m_grandBan["jp_dian_"..i])
  
        self.m_majorBan["jp_dian_"..i] = util_createAnimation("ManicMonster_jackpot_qiu.csb") 
        self.m_majorBan:findChild("jp_node_"..i):addChild(self.m_majorBan["jp_dian_"..i])

        self.m_minorBan["jp_dian_"..i] = util_createAnimation("ManicMonster_jackpot_qiu.csb") 
        self.m_minorBan:findChild("jp_node_"..i):addChild(self.m_minorBan["jp_dian_"..i])

        self.m_miniBan["jp_dian_"..i] = util_createAnimation("ManicMonster_jackpot_qiu.csb") 
        self.m_miniBan:findChild("jp_node_"..i):addChild(self.m_miniBan["jp_dian_"..i])

        for k = 1,#imgName do
            self.m_grandBan["jp_dian_"..i]:findChild(imgName[k]):setVisible(false)
            self.m_majorBan["jp_dian_"..i]:findChild(imgName[k]):setVisible(false)
            self.m_minorBan["jp_dian_"..i]:findChild(imgName[k]):setVisible(false)
            self.m_miniBan["jp_dian_"..i]:findChild(imgName[k]):setVisible(false)


            self.m_grandBan["jp_dian_"..i]:findChild(imgName[1]):setVisible(true)
            self.m_majorBan["jp_dian_"..i]:findChild(imgName[2]):setVisible(true)
            self.m_minorBan["jp_dian_"..i]:findChild(imgName[3]):setVisible(true)
            self.m_miniBan["jp_dian_"..i]:findChild(imgName[4]):setVisible(true)

        end

    end


end

function ManicMonsterJackPotBarView:hidAllJpBan( )
    
    self.m_grandBan:runCsbAction("idle")
    self.m_majorBan:runCsbAction("idle")
    self.m_minorBan:runCsbAction("idle")
    self.m_miniBan:runCsbAction("idle")

end

function ManicMonsterJackPotBarView:hidAllJpDian( )
    
    for i=1,3 do
        local grandDian = self.m_grandBan["jp_dian_"..i] 
        grandDian:runCsbAction("idle")
        grandDian:setVisible(false)
        local majorDian = self.m_majorBan["jp_dian_"..i] 
        majorDian:runCsbAction("idle")
        majorDian:setVisible(false)
        local minorDian = self.m_minorBan["jp_dian_"..i] 
        minorDian:runCsbAction("idle")
        minorDian:setVisible(false)
        local miniDian = self.m_miniBan["jp_dian_"..i] 
        miniDian:runCsbAction("idle")
        miniDian:setVisible(false)
    end

end

function ManicMonsterJackPotBarView:onExit()
 
end

function ManicMonsterJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ManicMonsterJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function ManicMonsterJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function ManicMonsterJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1.14,sy=1.14}
    local info2={label=label2,sx=1.14,sy=1.14}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.98,sy=0.98}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.98,sy=0.98}
    self:updateLabelSize(info1,248)
    self:updateLabelSize(info2,248)
    self:updateLabelSize(info3,185)
    self:updateLabelSize(info4,185)
end

function ManicMonsterJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50,nil,nil,true))
end

function ManicMonsterJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return ManicMonsterJackPotBarView