---
--xcyy
--2018年5月23日
--WallballJackPotBarView.lua

local WallballJackPotBarView = class("WallballJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"

local JACKPOT_NUM = 
{
    "Grand",
    "Major",
    "Minor"
}

function WallballJackPotBarView:initUI()

    self:createCsbNode("Wallball_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

    for i = 1, #JACKPOT_NUM, 1 do
        local key = JACKPOT_NUM[i]
        local effect, act = util_csbCreate("Wallball_jackpot_"..key..".csb")
        self[key.."_effect"] = effect
        self:findChild("Node_effect"):addChild(effect)
        util_csbPlayForKey(act, "idle", true)
        effect:setVisible(false)
    end

end


function WallballJackPotBarView:onExit()
 
end

function WallballJackPotBarView:hideJackpotLight()
    for i = 1, #JACKPOT_NUM, 1 do
        local key = JACKPOT_NUM[i]
        self[key.."_effect"]:setVisible(false)
    end
end

function WallballJackPotBarView:showJackpotLight(jackpot)
    self[jackpot.."_effect"]:setVisible(true)
end

function WallballJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WallballJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function WallballJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)

    self:updateSize()
end

function WallballJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.56,sy=0.56}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.56,sy=0.56}

    self:updateLabelSize(info1,340)
    self:updateLabelSize(info2,320)
    self:updateLabelSize(info3,320)

end

function WallballJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,30,nil,nil,true))
end

function WallballJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return WallballJackPotBarView