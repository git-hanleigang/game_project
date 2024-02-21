--jacpot显示界面
--PowerUpJackpotView.lua

local PowerUpJackpotView = class("PowerUpJackpotView",util_require("base.BaseView"))


function PowerUpJackpotView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("PowerUp_Jackpot1.csb")

    self:playAnimation(false)
end
function PowerUpJackpotView:playAnimation(show)
    if show then
        self:runCsbAction("show",false,function()
            self:runCsbAction("idle",true)
        end)
    else
        self:runCsbAction("idle_1",true)
    end
end
function PowerUpJackpotView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("lbs_jackpot4"),1,true)
    self:changeNode(self:findChild("lbs_jackpot3"),2,true)
    self:changeNode(self:findChild("lbs_jackpot2"),3,true)
    self:changeNode(self:findChild("lbs_jackpot1"),4,true)

    self:changeNode(self:findChild("lbs_jackpot_3"),2,true)
    self:changeNode(self:findChild("lbs_jackpot_2"),3,true)
    self:changeNode(self:findChild("lbs_jackpot_1"),4,true)


    self:updateLabelSize({label=self:findChild("lbs_jackpot4"),sx=1,sy=1},465)
    self:updateLabelSize({label=self:findChild("lbs_jackpot3"),sx=1,sy=1},465)
    self:updateLabelSize({label=self:findChild("lbs_jackpot2"),sx=0.6,sy=0.6},345)
    self:updateLabelSize({label=self:findChild("lbs_jackpot1"),sx=0.6,sy=0.6},345)

    self:updateLabelSize({label=self:findChild("lbs_jackpot_3"),sx=1,sy=1},465)
    self:updateLabelSize({label=self:findChild("lbs_jackpot_2"),sx=1,sy=1},465)
    self:updateLabelSize({label=self:findChild("lbs_jackpot_1"),sx=1,sy=1},465)

end
--jackpot算法
function PowerUpJackpotView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function PowerUpJackpotView:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end


function PowerUpJackpotView:showAdd()

end
function PowerUpJackpotView:onExit()

end

--默认按钮监听回调
function PowerUpJackpotView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return PowerUpJackpotView