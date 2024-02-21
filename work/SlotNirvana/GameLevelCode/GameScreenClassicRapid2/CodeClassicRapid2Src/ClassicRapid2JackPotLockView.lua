---
--xcyy
--2018年5月23日
--ClassicRapid2JackPotLockView.lua

local ClassicRapid2JackPotLockView = class("ClassicRapid2JackPotLockView",util_require("base.BaseView"))
ClassicRapid2JackPotLockView.mappList = {}
function ClassicRapid2JackPotLockView:initUI(machine)

    self.m_machine = machine
    self:createCsbNode("ClassicRapid2_jackpot2_0.csb")

    self:addClick(self:findChild("click_1"))
    self:addClick(self:findChild("click_2"))
    self:addClick(self:findChild("click_3"))
    self:addClick(self:findChild("click_4"))

    for i=1,4 do
        self["lockUI"..i] = util_createAnimation("ClassicRapid2_jackpot2_lock"..i..".csb")
        self:addChild(self["lockUI"..i])
    end
    

end

function ClassicRapid2JackPotLockView:onEnter()


end

function ClassicRapid2JackPotLockView:onExit()

end


function ClassicRapid2JackPotLockView:showjackPotAction(id)
    if id < 5 then
       return 1
    end
    local result = id - 5 + 1

    if id >= 5 and id <= 10 then
        self:runCsbAction("animation"..result) 
    end


    return (id - 5 + 1)
end

function ClassicRapid2JackPotLockView:clearAnim()
    self:runCsbAction("animation0")
end

function ClassicRapid2JackPotLockView:updateLocklab(list)
    for i=1,#list do
        self["lockUI"..i]:findChild("lbs_unlockBet_"..i):setString(util_formatCoins(list[i],3))
    end
end

function ClassicRapid2JackPotLockView:updateLock(level,_isInit)


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
function ClassicRapid2JackPotLockView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_1" then
        
        print("self.m_barId    2")
        if self.m_machine then
            self.m_machine:unlockHigherBet( 2 )
        end
    elseif name == "click_2" then
        
        print("self.m_barId    3")
        if self.m_machine then
            self.m_machine:unlockHigherBet( 3 )
        end
    elseif name == "click_3" then
        
        print("self.m_barId    4")

        if self.m_machine then
            self.m_machine:unlockHigherBet( 4 )
        end
    elseif name == "click_4" then
        
        print("self.m_barId    5")
        if self.m_machine then
            self.m_machine:unlockHigherBet( 5 )
        end
    end

end



return ClassicRapid2JackPotLockView