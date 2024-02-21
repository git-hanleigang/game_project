---
--xcyy
--2018年5月23日
--MermaidJackPotBarView.lua

local MermaidJackPotBarView = class("MermaidJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function MermaidJackPotBarView:initUI()

    self:createCsbNode("Mermaid_jackpot.csb")

    self:resetCurRefreshTime()
    -- self:runCsbAction("idleframe",true)

    self.m_light = util_createAnimation("Node_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.m_light)
    self.m_light:setVisible(false)

end

function MermaidJackPotBarView:onExit()
 
end

function MermaidJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MermaidJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function MermaidJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    --公共jackpot
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if status == "Normal" then
        self:changeNode(self:findChild(GrandName),1,true)
    else
        self.m_curTime = self.m_curTime + 0.08

        local time     = math.min(120, self.m_curTime)
        local addTimes = time/0.08 
        local jackpotValue = self.m_machine:getCommonJackpotValue(status, addTimes)
        local ml_b_coins_grand = self:findChild(GrandName)
        ml_b_coins_grand:setString(util_formatCoins(jackpotValue,50))
    end

    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function MermaidJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1.1,sy=1.1}
    local info2={label=label2,sx=0.85,sy=0.85}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.6,sy=0.6}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.6,sy=0.6}
    self:updateLabelSize(info1,383)
    self:updateLabelSize(info2,383)
    self:updateLabelSize(info3,321)
    self:updateLabelSize(info4,276)
end

function MermaidJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function MermaidJackPotBarView:resetCurRefreshTime()
    self.m_curTime = 0
end

function MermaidJackPotBarView:updateMegaShow()
    local icon_super = self:findChild("Mermaid_j_super")
    local icon_mega = self:findChild("Mermaid_j_mega")
    local icon_grand = self:findChild("Mermaid_j_grand")
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    icon_super:setVisible(status == "Super")
    icon_mega:setVisible(status == "Mega")
    icon_grand:setVisible(status == "Normal")

    if self.m_curStatus and self.m_curStatus ~= status and (status == "Mega" or status == "Super") then
        self.m_light:setVisible(true)
        self.m_light:runCsbAction("win",false,function()
            self.m_light:setVisible(false)
        end)
        for index = 1,8 do
            self.m_light:findChild("Particle_"..index):resetSystem()
        end
    end

    self.m_curStatus = status
    
end


return MermaidJackPotBarView