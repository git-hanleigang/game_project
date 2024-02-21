---
--xcyy
--2018年5月23日
--FruitFarmJackPotBarView.lua

local FruitFarmJackPotBarView = class("FruitFarmJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

local lock_status = {
    normal = 1,
    open = 2,
    lock = 3
}

function FruitFarmJackPotBarView:initUI()
    self.m_level = 0
    self:createCsbNode("FruitFarm_jackpot.csb")
    self.m_lock_tab = {}
    for i=1,2 do
        local lock_node = util_createAnimation("FruitFarm_jackpot_lock.csb")
        self:findChild("lock_"..i):addChild(lock_node)
        lock_node.status = lock_status.normal
        self.m_lock_tab[i] = lock_node
    end

end


function FruitFarmJackPotBarView:onExit()
 
end

function FruitFarmJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function FruitFarmJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function FruitFarmJackPotBarView:updateJackpotInfo()
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

function FruitFarmJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1.6,sy=1.6}
    local info2={label=label2,sx=1.15,sy=1.15}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1.15,sy=1.15}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1.15,sy=1.15}
    self:updateLabelSize(info1,149)
    self:updateLabelSize(info2,148)
    self:updateLabelSize(info3,148)
    self:updateLabelSize(info4,148)
end

function FruitFarmJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function FruitFarmJackPotBarView:toAction(level, isInit)
    if level ~= self.m_level then
        local isUp = level > self.m_level
        self.m_level = level
        if isInit then
            local ani_str1 = level > 2 and "idle4" or "idle3"
            local ani_str2 = level > 1 and "idle1" or "idle2"
            self.m_lock_tab[1]:playAction(ani_str1)
            self.m_lock_tab[1].status = level > 2 and lock_status.open or lock_status.lock
            self.m_lock_tab[2]:playAction(ani_str2)
            self.m_lock_tab[2].status =  level > 1 and lock_status.open or lock_status.lock
        else
            if isUp then
                if level > 2 and self.m_lock_tab[1].status == lock_status.lock then
                    self.m_lock_tab[1].status = lock_status.open 
                    self.m_lock_tab[1]:playAction("actionframe2")
                end
                if level > 1 and self.m_lock_tab[2].status == lock_status.lock then
                    self.m_lock_tab[2].status = lock_status.open 
                    self.m_lock_tab[2]:playAction("actionframe1")
                end
            else
                if level < 3 and self.m_lock_tab[1].status == lock_status.open then
                    self.m_lock_tab[1].status = lock_status.lock 
                    self.m_lock_tab[1]:playAction("idle3")
                end
                if level < 2 and self.m_lock_tab[2].status == lock_status.open then
                    self.m_lock_tab[2].status = lock_status.lock 
                    self.m_lock_tab[2]:playAction("idle2")
                end
            end
        end
    end
end


return FruitFarmJackPotBarView