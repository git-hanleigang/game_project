---
--xhkj
--2018年6月11日
--HowlingMoonTopBar.lua

local HowlingMoonTopBar = class("HowlingMoonTopBar", util_require("base.BaseView"))

function HowlingMoonTopBar:initUI(data)

    local resourceFilename="Socre_HowlingMoon_top.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
    self.m_changeWith = false

    self:resetCurRefreshTime()

    self.m_light = util_createAnimation("Node_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.m_light)
    self.m_light:setVisible(false)
end

function HowlingMoonTopBar:setFadeOutAction(  )
    self.m_csbNode:runAction(cc.FadeOut:create(1)) 
end

function HowlingMoonTopBar:initMachine(machine)
    self.m_machine = machine
end

function HowlingMoonTopBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function HowlingMoonTopBar:setChangeWith(_change)
    self.m_changeWith = _change
    self:updateMegaShow()
end
-- 更新jackpot 数值信息
--
function HowlingMoonTopBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    --公共jackpot
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if status == "Normal" then
        self:changeNode(self:findChild("m_lb_grand"),1,true)
    else
        self.m_curTime = self.m_curTime + 0.08

        local time     = math.min(120, self.m_curTime)
        local addTimes = time/0.08 
        local jackpotValue = self.m_machine:getCommonJackpotValue(status, addTimes)
        local ml_b_coins_grand = self:findChild("m_lb_grand")
        ml_b_coins_grand:setString(util_formatCoins(jackpotValue,50))
    end

    self:changeNode(self:findChild("m_lb_major"),2,true)
    self:changeNode(self:findChild("m_lb_minor"),3)
    self:changeNode(self:findChild("m_lb_mini"),4)
    self:updateSize()
end

function HowlingMoonTopBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    if  self.m_changeWith then
        local info1={label=label1,sx=0.70,sy=0.70}
        local info2={label=label2,sx=0.70,sy=0.70}
        self:updateLabelSize(info1,408,{info2})
        local info3={label=label3,sx=0.48,sy=0.48}
        local info4={label=label4,sx=0.48,sy=0.48}
        self:updateLabelSize(info3,408,{info4})
    else
        local info1={label=label1}
        local info2={label=label2}
        self:updateLabelSize(info1,408)
        self:updateLabelSize(info2,365)
        local info3={label=label3,sx=0.68,sy=0.68}
        local info4={label=label4,sx=0.68,sy=0.68}
        self:updateLabelSize(info3,408,{info4})
    end
    -- self:updateLabelSize(info2,265)



end

function HowlingMoonTopBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end


function HowlingMoonTopBar:toAction(actionName)
    self:runCsbAction(actionName)
end


-- 如果本界面需要添加touch 事件，则从BaseView 获取





--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function HowlingMoonTopBar:resetCurRefreshTime()
    self.m_curTime = 0
end

function HowlingMoonTopBar:updateMegaShow()
    
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE and not self.m_changeWith then
        local icon_super = self:findChild("HowlingMoon_bonus_super")
        local icon_mega = self:findChild("HowlingMoon_bonus_mega")
        local icon_grand = self:findChild("HowlingMoon_bonus_grand")
        icon_super:setVisible(status == "Super")
        icon_mega:setVisible(status == "Mega")
        icon_grand:setVisible(status == "Normal")

        if self.m_curStatus and self.m_curStatus ~= status and (status == "Mega" or status == "Super") then
            self.m_light:setVisible(true)
            self.m_light:runCsbAction("win",false,function()
                self.m_light:setVisible(false)
            end)
            for index = 1,8 do
                self.m_light:findChild("Particle_"..index):resetSystem()
            end
        end
    
        self.m_curStatus = status

        self:hideIcons()
    else
        local icon_super = self:findChild("sp_super")
        local icon_mega = self:findChild("sp_mega")
        local icon_grand = self:findChild("sp_grand")
        icon_super:setVisible(status == "Super")
        icon_mega:setVisible(status == "Mega")
        icon_grand:setVisible(status == "Normal")
    end
end

function HowlingMoonTopBar:hideIcons()
    self:findChild("sp_super"):setVisible(false)
    self:findChild("sp_mega"):setVisible(false)
    self:findChild("sp_grand"):setVisible(false)
end
return HowlingMoonTopBar