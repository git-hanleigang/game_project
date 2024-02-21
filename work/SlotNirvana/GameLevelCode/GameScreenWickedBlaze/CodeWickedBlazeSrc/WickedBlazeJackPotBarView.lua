

local WickedBlazeJackPotBarView = class("WickedBlazeJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4"

function WickedBlazeJackPotBarView:initUI()
    self:createCsbNode("WickedBlaze_JackPotBar.csb")
    self:runCsbAction("actionframe",true)

    self:hideEffect()
end

function WickedBlazeJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WickedBlazeJackPotBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        self:showEffect(params[1])
    end,"WickedBlazeJackPotBarView_showEffect")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:hideEffect()
    end,"WickedBlazeJackPotBarView_hideEffect")

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
function WickedBlazeJackPotBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
-- 更新jackpot 数值信息
--
function WickedBlazeJackPotBarView:updateJackpotInfo()
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

function WickedBlazeJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.74,sy=0.74}
    local info2={label=label2,sx=0.61,sy=0.61}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.42,sy=0.42}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.42,sy=0.42}
    self:updateLabelSize(info1,645)
    self:updateLabelSize(info2,611)
    self:updateLabelSize(info3,440)
    self:updateLabelSize(info4,440)
end

function WickedBlazeJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function WickedBlazeJackPotBarView:toAction(actionName)
    self:runCsbAction(actionName)
end
function WickedBlazeJackPotBarView:showEffect(showType)
    self:findChild(showType.."1"):setVisible(true)
    self:findChild(showType.."2"):setVisible(true)
end
--隐藏特效
function WickedBlazeJackPotBarView:hideEffect()
    self:findChild("Major1"):setVisible(false)
    self:findChild("Major2"):setVisible(false)
    self:findChild("Grand1"):setVisible(false)
    self:findChild("Grand2"):setVisible(false)
    self:findChild("Mini1"):setVisible(false)
    self:findChild("Mini2"):setVisible(false)
    self:findChild("Minor1"):setVisible(false)
    self:findChild("Minor2"):setVisible(false)
end

return WickedBlazeJackPotBarView