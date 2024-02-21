---
--xcyy
--2018年5月23日
--FourInOneJPBarView.lua

local FourInOneJPBarView = class("FourInOneJPBarView",util_require("base.BaseView"))

FourInOneJPBarView.m_isBig = false

function FourInOneJPBarView:initUI()

    self.m_isBig = false

    local csbPath = "4in1_jackpot"

    if display.height > 1535 then
        self.m_isBig = true
        csbPath = "4in1_jackpot_1660" 
    end

    self:createCsbNode(csbPath ..".csb")
 
end



function FourInOneJPBarView:onExit()
 
end



function FourInOneJPBarView:initMachine(machine)
    self.m_machine = machine
end

function FourInOneJPBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end



-- 更新jackpot 数值信息
--
function FourInOneJPBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("ml_b_coins1"),1,true)
    self:changeNode(self:findChild("ml_b_coins2"),2,true)
    self:changeNode(self:findChild("ml_b_coins3"),3)
    self:changeNode(self:findChild("ml_b_coins4"),4)

    if self.m_isBig then
        self:updateSize()
    else
        self:updateSmallSize()
    end
    
end

function FourInOneJPBarView:updateSmallSize()

    local label1=self.m_csbOwner["ml_b_coins1"]
    local label2=self.m_csbOwner["ml_b_coins2"]
    local label3=self.m_csbOwner["ml_b_coins3"]
    local label4=self.m_csbOwner["ml_b_coins4"]


    local info1={label=label1,sx = 0.85,sy = 0.85}
    local info2={label=label2,sx = 0.85,sy = 0.85}
    local info3={label=label3,sx = 0.65,sy = 0.65}
    local info4={label=label4,sx = 0.65,sy = 0.65}


    self:updateLabelSize(info1,288)
    self:updateLabelSize(info2,292)
    self:updateLabelSize(info3,234)
    self:updateLabelSize(info4,234)

end

function FourInOneJPBarView:updateSize()

    local label1=self.m_csbOwner["ml_b_coins1"]
    local label2=self.m_csbOwner["ml_b_coins2"]
    local label3=self.m_csbOwner["ml_b_coins3"]
    local label4=self.m_csbOwner["ml_b_coins4"]


    local info1={label=label1,sx = 1.08,sy = 1}
    local info2={label=label2,sx = 0.85,sy = 0.85}
    local info3={label=label3,sx = 0.65,sy = 0.65}
    local info4={label=label4,sx = 0.65,sy = 0.65}


    self:updateLabelSize(info1,316)
    self:updateLabelSize(info2,292)
    self:updateLabelSize(info3,234)
    self:updateLabelSize(info4,234)

end


function FourInOneJPBarView:changeNode(label,index,isJump)

        local value=self.m_machine:BaseMania_updateJackpotScore(index)

        label:setString(util_formatCoins(value,20))

    
end



return FourInOneJPBarView