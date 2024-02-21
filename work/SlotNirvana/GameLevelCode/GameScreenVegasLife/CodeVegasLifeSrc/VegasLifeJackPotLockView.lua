---
--xcyy
--2018年5月23日
--VegasLifeJackPotLockView.lua

local VegasLifeJackPotLockView = class("VegasLifeJackPotLockView",util_require("base.BaseView"))
VegasLifeJackPotLockView.mappList = {}
VegasLifeJackPotLockView.cashrush = {}--触发cashrush的时候的效果
function VegasLifeJackPotLockView:initUI(machine)

    self.m_machine = machine
    self:createCsbNode("VegasLife_jackpot2_0.csb")

    self:addClick(self:findChild("click_1"))
    self:addClick(self:findChild("click_2"))
    self:addClick(self:findChild("click_3"))
    self:addClick(self:findChild("click_4"))
    
    for i=1,4 do
        self["lockUI"..i] = util_createAnimation("VegasLife_jackpot2_lock"..i..".csb")
        self:findChild("lock"..i):addChild(self["lockUI"..i])
    end
    for i=5,9 do
        self.cashrush[i] = util_spineCreate("Socre_VegasLife_rapid1", true, true) 
        self:findChild("jackpot"..i):addChild(self.cashrush[i])
        util_spinePlay(self.cashrush[i],"idleframe2",true)  
    end

    self:runCsbAction("start") 
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_7"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_7"), true)
end

function VegasLifeJackPotLockView:onEnter()


end

function VegasLifeJackPotLockView:onExit()

end

function VegasLifeJackPotLockView:showjackPotAction(id)
    if id < 5 then
       return 1
    end
    local result = id - 5 + 1

    if id >= 5 and id <= 10 then
        util_spinePlay(self.cashrush[id],"actionframe2",true)  

        -- 中5/6两档Jackpot时 播放1遍 时间3秒 ，其他档位2遍 时间6秒
        local delayTime = 6
        if id ==5 or id == 6 then
            delayTime = 3
        end
        performWithDelay(self,function(  )
            util_spinePlay(self.cashrush[id],"idleframe2",true)
        end,delayTime)

    end

    return (id - 5 + 1)
end

function VegasLifeJackPotLockView:clearAnim()
    self:runCsbAction("animation0")
end

function VegasLifeJackPotLockView:updateLocklab(list)
    for i=1,#list do
        self["lockUI"..i]:findChild("lbs_unlockBet_"..i):setString(util_formatCoins(list[i],3))
    end
end

function VegasLifeJackPotLockView:updateLock(level,_isInit)
    for i=1,4 do
        if level == 0 then
            self["lockUI"..i]:runCsbAction("jiesuo0")
            self["lockUI"..i].m_open = false
        elseif self["lockUI"..i].betLevel and self["lockUI"..i].betLevel == level then

        else
            if i <= level  then
                if not self["lockUI"..i].m_open then
                    if _isInit then 
                        self["lockUI"..i]:runCsbAction("hide")
                    else
                        self["lockUI"..i]:runCsbAction("jiesuo")
                    end
                    
                    self["lockUI"..i].m_open = true
                end
            else
                self["lockUI"..i]:runCsbAction("jiesuo0")
                self["lockUI"..i].m_open = false
            end
        end
        self["lockUI"..i].betLevel = level
    end
end

--默认按钮监听回调
function VegasLifeJackPotLockView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_1" then
        if self.m_machine then
            self.m_machine:unlockHigherBet( 2 )
        end
    elseif name == "click_2" then
        if self.m_machine then
            self.m_machine:unlockHigherBet( 3 )
        end
    elseif name == "click_3" then
        if self.m_machine then
            self.m_machine:unlockHigherBet( 4 )
        end
    elseif name == "click_4" then
        if self.m_machine then
            self.m_machine:unlockHigherBet( 5 )
        end
    end
end

return VegasLifeJackPotLockView