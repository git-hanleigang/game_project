---
--xcyy
--2018年5月23日
--AtlantisJackPotBarView.lua

local AtlantisJackPotBarView = class("AtlantisJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local NOTICE_EFFECT = {
    {csb = "JackPotBar_Atlantis_mini.csb",ani = "mini"},
    {csb = "JackPotBar_Atlantis_minor.csb",ani = "minor"},
    {csb = "JackPotBar_Atlantis_major.csb",ani = "major"},
    {csb = "JackPotBar_Atlantis_grand.csb",ani = "grand"},
}

AtlantisJackPotBarView.m_curJackpot_index = -1
function AtlantisJackPotBarView:initUI()

    self:createCsbNode("JackPotBar_Atlantis.csb")

    self:idleAni()

end

function AtlantisJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function AtlantisJackPotBarView:onExit()
 
end

function AtlantisJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function AtlantisJackPotBarView:updateJackpotInfo()
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

function AtlantisJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,305)
    self:updateLabelSize(info2,305)
    self:updateLabelSize(info3,225)
    self:updateLabelSize(info4,225)
end

function AtlantisJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    改变当前jackpot光效
]]
function AtlantisJackPotBarView:changeCurLight(index)
    local notice_node = {"mini_FX","minor_FX","major_FX","grand_FX"}
    if index > 4 or index < 1 then
        self:idleAni()
        return
    end

    if index == self.m_curJackpot_index then
        return
    end

    self.m_curJackpot_index = index
    self.m_isIdle = false
    for i=1,4 do
        self:findChild(notice_node[i]):removeAllChildren(true)
    end

    local ani = util_createAnimation(NOTICE_EFFECT[index].csb)
    ani:runCsbAction(NOTICE_EFFECT[index].ani,true)
    self:findChild(notice_node[index]):addChild(ani) 
end

--[[
    中奖光效
]]
function AtlantisJackPotBarView:prizeLight(index,func)
    -- jackpot触发短乐
    
    local notice_node = {"mini_FX","minor_FX","major_FX","grand_FX"}
    local light_node = {"grand_guang","major_guang","minor_guang","mini_guang"}
    for i=1,4 do
        self:findChild(light_node[i]):removeAllChildren(true)
    end

    local ani = util_createAnimation("JackPotBar_Atlantis_guang.csb")
    self:findChild(light_node[index]):addChild(ani)
    gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_jackpot_trigger_short_music.mp3")
    ani:runCsbAction("open",false,function(  )
        ani:runCsbAction("actionframe",true)
    end)
    performWithDelay(self,function(  )
        ani:removeFromParent(true)
        for i=1,4 do
            self:findChild(notice_node[i]):removeAllChildren(true)
        end
        if type(func) == "function" then
            func()
        end
    end,2)
    

end

--[[
    idle动画
]]
function AtlantisJackPotBarView:idleAni()
    if self.m_isIdle then
        return
    end
    self.m_isIdle = true
    self:runCsbAction("idleframe",true)
    self.m_curJackpot_index = -1
end


return AtlantisJackPotBarView