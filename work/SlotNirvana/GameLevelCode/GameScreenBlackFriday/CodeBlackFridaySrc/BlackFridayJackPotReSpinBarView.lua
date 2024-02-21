---
--xcyy
--2018年5月23日
--BlackFridayJackPotReSpinBarView.lua

local BlackFridayJackPotReSpinBarView = class("BlackFridayJackPotReSpinBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins"
local GrandNameGray = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 
local jackpotTipsProgress = 4 --表示tips 4中状态 弹出1 idle2 消失3 ；4表示消失之后

function BlackFridayJackPotReSpinBarView:initUI(params)

    self:createCsbNode("BlackFriday_respin_jackpot.csb")

    self:initMachine(params.machine)
    
    -- 扫光 4种jackpot
    for saoguangIndex = 1, 4 do
        local saoguangNode = util_createAnimation("BlackFriday_jackpot_sg.csb")
        self:findChild("jackpot_sg"..saoguangIndex):addChild(saoguangNode)
        saoguangNode:runCsbAction("idle",true)
    end

    self.m_jackpotIdleIndex = 1
    self:playJackpot()
    -- 锁定jackpot的时候 tips
    -- self.m_tips = util_createAnimation("BlackFriday_jackpot_tips.csb")
    -- self:findChild("Node_tips"):addChild(self.m_tips)
    -- self.m_tips:setVisible(false)

    -- self:addClick(self:findChild("click_layout"))

end

-- 轮播 jackpot
function BlackFridayJackPotReSpinBarView:playJackpot()
    local jackpotIdleList = {"major","major_mini","mini","mini_minor","minor","minor_major"}

    if not self.m_machine.m_isReSpin then
        self:findChild("Node_mini"):setVisible(false)
        self:findChild("Node_minor"):setVisible(false)
        self:findChild("Node_major"):setVisible(true)
        return
    end
    self:findChild("Node_mini"):setVisible(true)
    self:findChild("Node_minor"):setVisible(true)
    self:findChild("Node_major"):setVisible(true)

    self:runCsbAction(jackpotIdleList[self.m_jackpotIdleIndex],false,function()
        if self.m_jackpotIdleIndex % 2 == 1 then
            self.m_machine:waitWithDelay(3,function()
                self.m_jackpotIdleIndex = self.m_jackpotIdleIndex + 1
                if self.m_jackpotIdleIndex > #jackpotIdleList then
                    self.m_jackpotIdleIndex = 1
                end
                self:playJackpot()
            end)

            return
        end
        self.m_jackpotIdleIndex = self.m_jackpotIdleIndex + 1
        if self.m_jackpotIdleIndex > #jackpotIdleList then
            self.m_jackpotIdleIndex = 1
        end
        self:playJackpot()
    end)
end

function BlackFridayJackPotReSpinBarView:initMachine(machine)
    self.m_machine = machine
end

function BlackFridayJackPotReSpinBarView:onEnter()

    BlackFridayJackPotReSpinBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function BlackFridayJackPotReSpinBarView:onExit()
    BlackFridayJackPotReSpinBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function BlackFridayJackPotReSpinBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(GrandNameGray),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function BlackFridayJackPotReSpinBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label1Gray=self.m_csbOwner[GrandNameGray]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.8,sy=0.8}
    local info1Gray={label=label1Gray,sx=0.8,sy=0.8}
    local info2={label=label2,sx=0.8,sy=0.8}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.75,sy=0.75}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.75,sy=0.75}
    self:updateLabelSize(info1,298)
    self:updateLabelSize(info1Gray,298)
    self:updateLabelSize(info2,298)
    self:updateLabelSize(info3,289)
    self:updateLabelSize(info4,289)
end

function BlackFridayJackPotReSpinBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function BlackFridayJackPotReSpinBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

-- --默认按钮监听回调
-- function BlackFridayJackPotReSpinBarView:clickFunc(sender)
--     local name = sender:getName()
--     local tag = sender:getTag()

--     if name == "click_layout" then 
--         gLobalNoticManager:postNotification("SHOW_UNLOCK_JACKPOT")
--     end
-- end

--锁定grand
function BlackFridayJackPotReSpinBarView:lockGrand()
    if self:findChild("Node_grand_suo"):isVisible() then
        self:findChild("Node_grand"):setVisible(false)
        return
    end

    self:findChild("Node_grand_suo"):setVisible(true)
    self:findChild("Node_grand"):setVisible(false)
end

-- 解锁grand
function BlackFridayJackPotReSpinBarView:unLockGrand(_isFirstComeIn)
    if _isFirstComeIn then
        self:findChild("Node_grand_suo"):setVisible(false)
        self:findChild("Node_grand"):setVisible(true)
    else
        if self:findChild("Node_grand"):isVisible() then
            return
        end

        self:findChild("Node_grand_suo"):setVisible(false)
        self:findChild("Node_grand"):setVisible(true)
    end
end

-- 判断 是否解锁了
function BlackFridayJackPotReSpinBarView:checkIsJieSuo( )
    return self:findChild("Node_grand_suo"):isVisible()
end

return BlackFridayJackPotReSpinBarView