---
--xcyy
--2018年5月23日
--BingoPriatesChestGameJackPotBarView.lua

local BingoPriatesChestGameJackPotBarView = class("BingoPriatesChestGameJackPotBarView",util_require("base.BaseView"))

local GrandName = "grand_shuzi"
local MajorName = "major_shuzi"
local MiniName = "mini_shuzi" 

function BingoPriatesChestGameJackPotBarView:initUI()

    self:createCsbNode("BingoPriates_jackpot_1.csb")


end

function BingoPriatesChestGameJackPotBarView:onExit()
 
end

function BingoPriatesChestGameJackPotBarView:initMachine(machine)
    self.m_machine = machine

    self:updateJackpotInfo()
end

function BingoPriatesChestGameJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

-- 更新jackpot 数值信息
--
function BingoPriatesChestGameJackPotBarView:updateJackpotInfo(jackpotData)
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    if jackpotData == nil or jackpotData == {} then
        jackpotData = { Grand = 0, Major = 0, Minor = 0}
    end

    for k,v in pairs(jackpotData) do

        if k == "Grand" then
            self:changeNode(self:findChild(GrandName),v)
        elseif k == "Major" then
            self:changeNode(self:findChild(MajorName),v)
        elseif k == "Minor" then
            self:changeNode(self:findChild(MiniName),v)
        end

    end
    
    
    

    self:updateSize()
end

function BingoPriatesChestGameJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,242)
    self:updateLabelSize(info2,154)
    self:updateLabelSize(info4,134)
end

function BingoPriatesChestGameJackPotBarView:changeNode(label,value)
    label:setString(util_formatCoins(value,20))
end

function BingoPriatesChestGameJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return BingoPriatesChestGameJackPotBarView