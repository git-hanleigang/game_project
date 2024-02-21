---
--xcyy
--2018年5月23日
--CandyPusherJackPotBarView.lua
local Config                    = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")
local CandyPusherJackPotBarView = class("CandyPusherJackPotBarView",util_require("base.BaseView"))
local GamePusherManager         = require "CandyPusherSrc.GamePusherManager"

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

CandyPusherJackPotBarView.m_AverageBet = nil
function CandyPusherJackPotBarView:initUI()
    self.m_AverageBet = nil
    self:createCsbNode("CandyPusher_jackpot_kuang.csb")
    
    self.m_pGamePusherMgr   = GamePusherManager:getInstance()

end


function CandyPusherJackPotBarView:onExit()
    CandyPusherJackPotBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end



function CandyPusherJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CandyPusherJackPotBarView:onEnter()
    
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CandyPusherJackPotBarView:updateJackpotInfo()
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

function CandyPusherJackPotBarView:updateSize()

    local label1 = self.m_csbOwner[GrandName]
    local info1 = {label = label1, sx = 1, sy = 1}

    local label2 = self.m_csbOwner[MajorName]
    local info2 = {label = label2, sx = 1, sy = 1}
    
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 1, sy = 1}

    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 1, sy = 1}


    self:updateLabelSize(info1,324)
    self:updateLabelSize(info2,300)
    self:updateLabelSize(info3,252)
    self:updateLabelSize(info4,225)
end

function CandyPusherJackPotBarView:changeNode(label,index,isJump)

    local bet = nil
    if self.m_AverageBet then
        bet = self.m_AverageBet 
    end

    local value=self.m_machine:BaseMania_updateJackpotScore(index,bet)
    label:setString(util_formatCoins(value,20,nil,nil,true))
    self.m_pGamePusherMgr:setJpCoins(index,value )
end




return CandyPusherJackPotBarView