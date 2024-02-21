---
--xcyy
--2018年5月23日
--DazzlingDiscoJackPotBarView.lua

local DazzlingDiscoJackPotBarView = class("DazzlingDiscoJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local JACKPOT_TYPE = {
    "grand",
    "mega",
    "major",
    "minor",
    "mini",
}

local TIME_SPAN =   0.08    --刷新时间间隔
local TIME_MAX = 2          --切换间隔

function DazzlingDiscoJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("DazzlingDisco_jackpot.csb")
    self.m_curTime = 0
    self.m_curJackpotIndex = 1

    self:runCsbAction("idleframe",true)

    --刷新当前jackpot显示
    -- self:updataCurJackpotShow()
end

function DazzlingDiscoJackPotBarView:onEnter()
    DazzlingDiscoJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,TIME_SPAN)
end

function DazzlingDiscoJackPotBarView:onExit()
    DazzlingDiscoJackPotBarView.super.onExit(self)
end

function DazzlingDiscoJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function DazzlingDiscoJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    --检测是否切换显示
    -- self.m_curTime = self.m_curTime + TIME_SPAN
    -- if self.m_curTime >= TIME_MAX then
    --     self.m_curTime = 0
    --     self.m_curJackpotIndex = self.m_curJackpotIndex + 1
    --     if self.m_curJackpotIndex > #JACKPOT_TYPE then
    --         self.m_curJackpotIndex = 1
    --     end 
    --     self:updataCurJackpotShow()
    -- end

    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function DazzlingDiscoJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,330)

    local label2=self.m_csbOwner[MegaName]
    local info2={label=label2,sx=1,sy=1}
    self:updateLabelSize(info2,330)

    local label3=self.m_csbOwner[MajorName]
    local info3={label=label3,sx=1,sy=1}
    self:updateLabelSize(info3,330)
    
    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info4,330)

    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=1,sy=1}
    self:updateLabelSize(info5,330)
end

function DazzlingDiscoJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    刷新当前jackpot显示
]]
function DazzlingDiscoJackPotBarView:updataCurJackpotShow( )
    for index = 1,#JACKPOT_TYPE do
        self:findChild("Node_"..JACKPOT_TYPE[index]):setVisible(self.m_curJackpotIndex == index)
    end
end

return DazzlingDiscoJackPotBarView