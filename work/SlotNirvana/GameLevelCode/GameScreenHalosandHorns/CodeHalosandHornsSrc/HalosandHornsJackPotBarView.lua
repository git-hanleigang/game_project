---
--xcyy
--2018年5月23日
--HalosandHornsJackPotBarView.lua

local HalosandHornsJackPotBarView = class("HalosandHornsJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coins"

HalosandHornsJackPotBarView.m_showReword = false

function HalosandHornsJackPotBarView:initUI(path)

    self:createCsbNode(path..".csb")
    self:runCsbAction("idleframe",true)
    
    self.m_bgShine = util_createAnimation("HalosandHorns_jcakpot_bgshine.csb")
    self:findChild("Node_bgshine"):addChild(self.m_bgShine)
    self.m_bgShine:runCsbAction("actionframe",true)

end

function HalosandHornsJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function HalosandHornsJackPotBarView:onExit()
 
end

function HalosandHornsJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function HalosandHornsJackPotBarView:updateRewordCoins(value )

    self:setBoolShowReword( true )
    self:findChild(GrandName):setString(util_formatCoins(value,20,nil,nil,true))
    self:updateSize()
end

function HalosandHornsJackPotBarView:setBoolShowReword( _isShow )
    self.m_showReword = _isShow
end

-- 更新jackpot 数值信息
--
function HalosandHornsJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    if self.m_showReword then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)

    self:updateSize()
end

function HalosandHornsJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}
    
    self:updateLabelSize(info1,405)

end

function HalosandHornsJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return HalosandHornsJackPotBarView