---
--xcyy
--2018年5月23日
--LoveShotJackPotBarView.lua
--fixios0223
local LoveShotJackPotBarView = class("LoveShotJackPotBarView",util_require("base.BaseView"))

LoveShotJackPotBarView.JP_15_NAME = "m_lb_coins_0"
LoveShotJackPotBarView.JP_14_NAME = "m_lb_coins_1"
LoveShotJackPotBarView.JP_13_NAME = "m_lb_coins_2"
LoveShotJackPotBarView.JP_12_NAME = "m_lb_coins_3"
LoveShotJackPotBarView.JP_11_NAME = "m_lb_coins_4"
LoveShotJackPotBarView.JP_10_NAME = "m_lb_coins_5"
LoveShotJackPotBarView.JP_9_NAME = "m_lb_coins_6"
LoveShotJackPotBarView.JP_8_NAME = "m_lb_coins_7"
LoveShotJackPotBarView.JP_7_NAME = "m_lb_coins_8"

LoveShotJackPotBarView.JP_RED = 1
LoveShotJackPotBarView.JP_PURPLE = 2
LoveShotJackPotBarView.JP_GOLD = 3

function LoveShotJackPotBarView:initUI()

    self:createCsbNode("LoveShot_Jackpot.csb")

    self:initJpCashRushActNode( )

    self:setCashRushVisibleStates( self.JP_RED )
end

function LoveShotJackPotBarView:initJpCashRushActNode( )

    for i=1 ,9 do
        
        self["cashrush_Act" .. i] = util_createAnimation("LoveShot_Jackpot_cashrush.csb") 
        self:findChild("LoveShot_cashrush_node_".. i-1):addChild(self["cashrush_Act" .. i])
      
        self["cashrush_LightBg" .. i] = util_createAnimation("LoveShot_Jackpot_L.csb") 
        self:findChild("LoveShot_Jackpot_L_"..i-1):addChild(self["cashrush_LightBg" .. i])
        self["cashrush_LightBg" .. i]:setVisible(false)
    end
    

end

function LoveShotJackPotBarView:setOneCashRushVisibleStates(_cashrush_Act,_staes )
    
    if _cashrush_Act then
        _cashrush_Act:findChild("R"):setVisible(false)
        _cashrush_Act:findChild("Y"):setVisible(false)
        _cashrush_Act:findChild("P"):setVisible(false)
        _cashrush_Act:runCsbAction("idleframe")
        
        if _staes == self.JP_RED then
            _cashrush_Act:findChild("R"):setVisible(true)
        elseif _staes == self.JP_PURPLE then
            _cashrush_Act:findChild("P"):setVisible(true)
        elseif _staes == self.JP_GOLD then
            _cashrush_Act:findChild("Y"):setVisible(true)
        end
    end
end

function LoveShotJackPotBarView:setCashRushVisibleStates( _staes )


    for i=1 ,9 do
        local cashrush_Act = self["cashrush_Act" .. i]

        
        self:setOneCashRushVisibleStates(cashrush_Act,_staes )
        
    end

   

end

function LoveShotJackPotBarView:showJpAct(_index )

    for i=1 ,9 do
        
        self["cashrush_LightBg" .. i]:setVisible(false)

        if _index == i then
            
            self["cashrush_Act" .. i]:setVisible(true)
            self["cashrush_Act" .. i]:runCsbAction("actionframe")
        
            self["cashrush_LightBg" .. i]:setVisible(true)
            self["cashrush_LightBg" .. i]:runCsbAction("actionframe",true)

        end
    end

   

end

function LoveShotJackPotBarView:hideJpAct( )
    
    for i=1 ,9 do
        
        self["cashrush_LightBg" .. i]:setVisible(false)
        self["cashrush_LightBg" .. i]:runCsbAction("idleframe")

    end

end

function LoveShotJackPotBarView:showCashRushActChangeAni(_pos )


    self["cashrush_Act" .. _pos]:runCsbAction("change")


end

function LoveShotJackPotBarView:onEnter()

    schedule(self,function()

        self:updateJackpotInfo()

    end,0.08)
    
end

function LoveShotJackPotBarView:onExit()
 
end

function LoveShotJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function LoveShotJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(self.JP_15_NAME),1,true)
    self:changeNode(self:findChild(self.JP_14_NAME),2,true)
    self:changeNode(self:findChild(self.JP_13_NAME),3,true)
    self:changeNode(self:findChild(self.JP_12_NAME),4,true)
    self:changeNode(self:findChild(self.JP_11_NAME),5,true)
    self:changeNode(self:findChild(self.JP_10_NAME),6,true)
    self:changeNode(self:findChild(self.JP_9_NAME),7,true)
    self:changeNode(self:findChild(self.JP_8_NAME),8,true)
    self:changeNode(self:findChild(self.JP_7_NAME),9,true)


    self:updateSize()
    
end

function LoveShotJackPotBarView:updateSize()

    local info1 = {label=self:findChild(self.JP_15_NAME),sx = 1,sy = 1}
    self:updateLabelSize(info1,348)

    local info2 = {label=self:findChild(self.JP_14_NAME),sx = 1,sy = 1}
    self:updateLabelSize(info2,315)

    local info3 = {label=self:findChild(self.JP_13_NAME),sx = 0.83,sy = 0.83}
    self:updateLabelSize(info3,291)

    local info4 = {label=self:findChild(self.JP_12_NAME),sx = 0.83,sy = 0.83}
    self:updateLabelSize(info4,267)

    local info5 = {label=self:findChild(self.JP_11_NAME),sx = 0.81,sy = 0.81}
    self:updateLabelSize(info5,258)

    local info6 = {label=self:findChild(self.JP_10_NAME),sx = 0.8,sy = 0.8}
    self:updateLabelSize(info6,234)

    local info7 = {label=self:findChild(self.JP_9_NAME),sx = 0.8,sy = 0.8}
    self:updateLabelSize(info7,210)

    local info8 = {label=self:findChild(self.JP_8_NAME),sx = 0.78,sy = 0.78}
    self:updateLabelSize(info8,210)

    local info9 = {label=self:findChild(self.JP_7_NAME),sx = 0.75,sy = 0.75}
    self:updateLabelSize(info9,210)

end

function LoveShotJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function LoveShotJackPotBarView:changeCashRushAct(_actState, _func)
    
    for i = 1 ,9 do
        
        local cashrush_Act = self["cashrush_Act" .. i]

        if cashrush_Act then
            local waitNode_1 = cc.Node:create()
            self:addChild(waitNode_1)
            performWithDelay(waitNode_1,function(  )

                local index= i

                local cashrush_Act_1 = cashrush_Act
                cashrush_Act:runCsbAction("change")

                local waitNode_2 = cc.Node:create()
                self:addChild(waitNode_2)

                performWithDelay(self,function(  )

                    self:setOneCashRushVisibleStates(cashrush_Act_1,_actState  )

                    if index == 9 then
                        if _func then
                            _func()
                        end
                    end

                    waitNode_2:removeFromParent()
                end,9/60)
                
                waitNode_1:removeFromParent()
            end,0.1 * (10 - i))
        end
        
        
    end

end

function LoveShotJackPotBarView:changeRedToYellow( _func )
    
    for i = 1 ,9 do
        
        local cashrush_Act = self["cashrush_Act" .. i]

        if cashrush_Act then
            local waitNode_1 = cc.Node:create()
            self:addChild(waitNode_1)
            performWithDelay(waitNode_1,function(  )

                local index= i

                local cashrush_Act_1 = cashrush_Act
                cashrush_Act:runCsbAction("change")

                local waitNode_2 = cc.Node:create()
                self:addChild(waitNode_2)

                performWithDelay(self,function(  )

                    self:setOneCashRushVisibleStates(cashrush_Act_1,self.JP_PURPLE )

                    if index == 9 then
                        if _func then
                            _func()
                        end
                    end

                    waitNode_2:removeFromParent()
                end,9/60)
                
                waitNode_1:removeFromParent()
            end,0.1 * (10 - i))
        end
        
        
    end

end

return LoveShotJackPotBarView