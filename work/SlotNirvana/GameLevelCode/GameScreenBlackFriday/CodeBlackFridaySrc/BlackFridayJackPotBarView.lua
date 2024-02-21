---
--xcyy
--2018年5月23日
--BlackFridayJackPotBarView.lua

local BlackFridayJackPotBarView = class("BlackFridayJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins"
local GrandNameGray = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 
local jackpotTipsProgress = 0 --表示tips 状态

function BlackFridayJackPotBarView:initUI(params)

    self:createCsbNode("BlackFriday_jackpot.csb")

    self:initMachine(params.machine)
    
    -- 扫光 4种jackpot
    for saoguangIndex = 1, 4 do
        local saoguangNode = util_createAnimation("BlackFriday_jackpot_sg.csb")
        self:findChild("jackpot_sg"..saoguangIndex):addChild(saoguangNode)
        saoguangNode:runCsbAction("idle",true)
    end

    -- 锁定jackpot的时候 tips
    self.m_tips = util_createAnimation("BlackFriday_jackpot_tips.csb")
    self:findChild("Node_tips"):addChild(self.m_tips)
    self.m_tips:setVisible(false)

    self:addClick(self:findChild("click_layout"))

end

function BlackFridayJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BlackFridayJackPotBarView:onEnter()

    BlackFridayJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function BlackFridayJackPotBarView:onExit()
    BlackFridayJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function BlackFridayJackPotBarView:updateJackpotInfo()
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

function BlackFridayJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label1Gray=self.m_csbOwner[GrandNameGray]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.95,sy=0.95}
    local info1Gray={label=label1Gray,sx=0.95,sy=0.95}
    local info2={label=label2,sx=0.95,sy=0.95}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.9,sy=0.9}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.9,sy=0.9}
    self:updateLabelSize(info1,304)
    self:updateLabelSize(info1Gray,304)
    self:updateLabelSize(info2,298)
    self:updateLabelSize(info3,239)
    self:updateLabelSize(info4,239)
end

function BlackFridayJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function BlackFridayJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

--默认按钮监听回调
function BlackFridayJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_layout" then 
        gLobalNoticManager:postNotification("SHOW_UNLOCK_JACKPOT")
    end
end

-- 锁定grand
function BlackFridayJackPotBarView:lockGrand()
    if self:findChild("Node_grand_suo"):isVisible() then
        self:findChild("Node_grand"):setVisible(false)
        return
    end
    -- 防止快速切换bet 显示出错
    if self.m_isClicking then
        return
    end

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_grand_lock)

    self.m_isClicking = true
    self:runCsbAction("jiesuo",false)
    self.m_machine:waitWithDelay(14/60,function()
        self:findChild("Node_grand_suo"):setVisible(true)
        self:findChild("Node_grand"):setVisible(false)
        self.m_isClicking = false
    end)

    self.m_tips:setVisible(true)
    self.m_tips:runCsbAction("start",false,function()
        self.m_tips:runCsbAction("idle",false)
    end)

    self.m_scheduleId = schedule(self, function(  )

        if self.m_scheduleId then
            self:stopAction(self.m_scheduleId)
            self.m_scheduleId = nil
        end

        jackpotTipsProgress = 1
        self.m_tips:runCsbAction("over",false,function()
            jackpotTipsProgress = 0
            self.m_tips:setVisible(false)
        end)
    end, 3)

end

-- 解锁grand
function BlackFridayJackPotBarView:unLockGrand(_isFirstComeIn)
    if _isFirstComeIn then
        self:findChild("Node_grand_suo"):setVisible(false)
        self:findChild("Node_grand"):setVisible(true)
    else
        if self:findChild("Node_grand"):isVisible() then
            return
        end

        -- 防止快速切换bet 显示出错
        if self.m_isUnLockClicking then
            return
        end

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_grand_unlock)

        self.m_isUnLockClicking = true

        self:runCsbAction("jiesuo",false)
        self.m_machine:waitWithDelay(14/60,function()
            self:findChild("Node_grand_suo"):setVisible(false)
            self:findChild("Node_grand"):setVisible(true)
            self.m_isUnLockClicking = false
        end)
    end
    if self.m_tips:isVisible() then
        if jackpotTipsProgress == 0 then
            if self.m_scheduleId then
                self:stopAction(self.m_scheduleId)
                self.m_scheduleId = nil
            end

            self.m_tips:runCsbAction("over",false,function()
                jackpotTipsProgress = 0
                self.m_tips:setVisible(false)
            end)
        end
    end
end

-- 判断特殊玩法 返回base的时候 如果是 锁定状态的话 弹出tips
function BlackFridayJackPotBarView:checkIsNeedOpenTips( )
    if self:findChild("Node_grand_suo"):isVisible() then
        self.m_tips:setVisible(true)
        jackpotTipsProgress = 1

        self.m_tips:runCsbAction("start",false,function()

            self.m_tips:runCsbAction("idle",false,function()

                self.m_tips:runCsbAction("over",false,function()

                    self.m_tips:setVisible(false)
                end)
            end)
        end)
    end 
end

return BlackFridayJackPotBarView