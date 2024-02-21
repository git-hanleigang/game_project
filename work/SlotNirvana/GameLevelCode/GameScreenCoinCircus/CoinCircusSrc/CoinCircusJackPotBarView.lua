---
--xcyy
--2018年5月23日
--CoinCircusJackPotBarView.lua
local Config                   = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local CoinCircusJackPotBarView = class("CoinCircusJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 


function CoinCircusJackPotBarView:initUI()

    self:createCsbNode("CoinCircus_jackpot_kuang.csb")


end

function CoinCircusJackPotBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end



function CoinCircusJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CoinCircusJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CoinCircusJackPotBarView:updateJackpotInfo()
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

function CoinCircusJackPotBarView:updateSize()

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

function CoinCircusJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))

    local jpdata = {}
    jpdata.nIndex = index
    jpdata.nValue = value
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_Update_WheelJpBar,jpdata) 
    
end




return CoinCircusJackPotBarView