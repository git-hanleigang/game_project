local ThanksGivingJackPotBarView = class("ThanksGivingJackPotBarView",util_require("base.BaseView"))

function ThanksGivingJackPotBarView:initUI()
    self:createCsbNode("ThanksGiving_jackpot.csb")
    self:runCsbAction("idle1")
end

function ThanksGivingJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ThanksGivingJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    -- schedule(self,function()
    --     self:updateJackpotInfo()
    -- end,0.08)
end

function ThanksGivingJackPotBarView:setLable(isPlayAni)
    self:findChild("m_lb_coins"):unscheduleUpdate()
    local num = 0
    if self.m_machine and self.m_machine.m_runSpinResultData.p_selfMakeData and self.m_machine.m_runSpinResultData.p_selfMakeData.jackpotCoins then
        num = self.m_machine.m_runSpinResultData.p_selfMakeData.jackpotCoins
    else
        local totalBet = globalData.slotRunData:getCurTotalBet()
        num = totalBet * 200
        isPlayAni = false
    end
    if self:findChild("m_lb_coins")._newNumValue == nil then
        self:findChild("m_lb_coins")._newNumValue = 0--当前显示的值
    end
    if num > tonumber(self:findChild("m_lb_coins")._newNumValue) then
        if isPlayAni then
            local add_meta = (num - self:findChild("m_lb_coins")._newNumValue)/50
            util_jumpNumInSize(self:findChild("m_lb_coins"),self:findChild("m_lb_coins")._newNumValue,num,add_meta,0.01,497,0.7,function ()
                
            end)
        else
            self:findChild("m_lb_coins"):setString(util_formatCoins(num,20,nil,nil,true))
            self:findChild("m_lb_coins")._newNumValue = num
            local info1 = {label = self:findChild("m_lb_coins"),sx = 0.7,sy = 0.7}
            self:updateLabelSize(info1,497)
        end
    else
        self:findChild("m_lb_coins"):setString(util_formatCoins(num,20,nil,nil,true))
        self:findChild("m_lb_coins")._newNumValue = num
        local info1 = {label = self:findChild("m_lb_coins"),sx = 0.7,sy = 0.7}
        self:updateLabelSize(info1,497)
    end
end

function ThanksGivingJackPotBarView:onExit()
 
end
-- 更新jackpot 数值信息
--
function ThanksGivingJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild("m_lb_coins"),1,true)

    self:updateSize()
end

function ThanksGivingJackPotBarView:updateSize()
    local label1 = self.m_csbOwner["m_lb_coins"]
    local info1 = {label = label1,sx = 0.7,sy = 0.7}
    self:updateLabelSize(info1,497)
end

function ThanksGivingJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return ThanksGivingJackPotBarView