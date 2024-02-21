---
--xhkj
--2018年6月11日
--LinkFishTopBar.lua

local LinkFishTopBar = class("LinkFishTopBar", util_require("base.BaseView"))

function LinkFishTopBar:initUI(data)

    local resourceFilename="Socre_LinkFish_Top.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self:resetCurRefreshTime()

    self.m_light = util_createAnimation("Node_jackpot.csb")
    self:findChild("node_jackpot"):addChild(self.m_light)
    self.m_light:setVisible(false)
end

function LinkFishTopBar:setFadeOutAction(  )
    self.m_csbNode:runAction(cc.FadeOut:create(1)) 
end

function LinkFishTopBar:initMachine(machine)
    self.m_machine = machine
end

function LinkFishTopBar:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
    util_setCascadeOpacityEnabledRescursion(self,true)
end

-- 更新jackpot 数值信息
--
function LinkFishTopBar:updateJackpotInfo()
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

function LinkFishTopBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local info1={label=label1,sx=0.50,sy=0.50}
    local info2={label=label2,sx=0.46,sy=0.46}
    self:updateLabelSize(info1,618)
    self:updateLabelSize(info2,704)

    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    local info3={label=label3,sx=0.33,sy=0.33}
    local info4={label=label4,sx=0.33,sy=0.33}
    self:updateLabelSize(info3,439,{info4})
end

function LinkFishTopBar:changeNode(label,index,isJump)
    local avgbet = self.m_machine:getAvgbet()
    local value=self.m_machine:BaseMania_updateJackpotScore(index,avgbet)
    label:setString(util_formatCoins(value,20))
end

function LinkFishTopBar:toAction(actionName)
    self:runCsbAction(actionName)
end


-- 如果本界面需要添加touch 事件，则从BaseView 获取


--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function LinkFishTopBar:resetCurRefreshTime()
    self.m_curTime = 0
end

function LinkFishTopBar:updateMegaShow()
    local icon_super = self:findChild("ChineseStyle_Super")
    local icon_mega = self:findChild("ChineseStyle_Mega")
    local icon_grand = self:findChild("ChineseStyle_Grand")
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
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
    
end

return LinkFishTopBar