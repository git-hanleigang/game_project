
local ApolloJackPotBarView = class("ApolloJackPotBarView",util_require("base.BaseView"))

local GrandName = "grand_Num"
local MajorName = "major_Num"
local MinorName = "minor_Num"
local MiniName = "mini_Num"

function ApolloJackPotBarView:initUI()
    self:createCsbNode("Apollo_jackpot.csb")
end

function ApolloJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ApolloJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function ApolloJackPotBarView:onExit()

end

-- 更新jackpot 数值信息
function ApolloJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function ApolloJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]
    local info1 = {label = label1,sx = 1,sy = 1}
    local info2 = {label = label2,sx = 0.8,sy = 0.8}
    local info3 = {label = label3,sx = 0.5,sy = 0.5}
    local info4 = { label = label4,sx = 0.5,sy = 0.5}
    self:updateLabelSize(info1,474)
    self:updateLabelSize(info2,475)
    self:updateLabelSize(info3,437)
    self:updateLabelSize(info4,437)
end

function ApolloJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return ApolloJackPotBarView