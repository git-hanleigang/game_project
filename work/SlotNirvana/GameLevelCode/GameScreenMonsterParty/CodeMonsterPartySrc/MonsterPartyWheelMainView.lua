---
--xcyy
--2018年5月23日
--MonsterPartyWheelMainView.lua

local MonsterPartyWheelMainView = class("MonsterPartyWheelMainView",util_require("base.BaseView"))
MonsterPartyWheelMainView.m_clicked = false

function MonsterPartyWheelMainView:initUI(machine)

    self:createCsbNode("MonsterParty/GameScreenMonsterParty_Choose.csb")

    self.m_clicked = false

    self.m_machine = machine

    self:initRunView()

    self.m_Point = util_createAnimation("MonsterParty_Choose_jiantou.csb")
    self:findChild("MonsterParty_jiantou"):addChild(self.m_Point)
    self.m_Point:setVisible(false)
    self.m_Point:runCsbAction("idle3",true)
    

    self:findChild("Panel_1_0"):setVisible(false)
    self:findChild("Panel_1"):setVisible(false)
    self:findChild("MonsterParty_up"):setVisible(false)
    self:findChild("MonsterParty_down"):setVisible(false)

    self:changeTopDownImgSizePos( )

    self:findChild("root"):setVisible(false)
    performWithDelay(self,function(  )
        self.m_Point:setVisible(true)
        self:findChild("root"):setVisible(true)
        self:findChild("MonsterParty_up"):setVisible(true)
        self:findChild("MonsterParty_down"):setVisible(true)

    end,50/30)

    gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_GuoChang.mp3")

    performWithDelay(self,function(  )
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Open_Door.mp3")
    end,1)
    

    self:runCsbAction("animation1",false,function(  )

        

        self.m_machine:findChild("BaseReel"):setVisible(false)


        self.m_aniSpinTip = util_createAnimation("MonsterParty_Choose_anniu.csb")
        self:findChild("Node_25"):addChild(self.m_aniSpinTip)

        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_taptospin_Show.mp3")

        self.m_aniSpinTip:runCsbAction("show",false,function(  )

            self.m_aniSpinTip:runCsbAction("idleframe",true)

            self:addClick(self:findChild("click"))
        end)
    
    end)
  
    
end

function MonsterPartyWheelMainView:changeTopDownImgSizePos( )
    local uiW, uiH = self.m_machine.m_topUI:getUISize()
    local uiBW, uiBH = self.m_machine.m_bottomUI:getUISize()

    local posDownY = - display.height / 2 + uiBH - 50  
    self:findChild("MonsterParty_down"):setPositionY((posDownY / self.m_machine.m_machineRootScale) - self.m_machine.m_mainUiChangePos  ) 


    local posTopY = display.height / 2 - uiH/3 + 20
    self:findChild("MonsterParty_up"):setPositionY((posTopY / self.m_machine.m_machineRootScale) - self.m_machine.m_mainUiChangePos )
    

    local scaleX = 768 / display.width / self.m_machine.m_machineRootScale
    if scaleX > 1 then
        self:findChild("MonsterParty_up"):setScaleX( 2 + scaleX)
        self:findChild("MonsterParty_down"):setScaleX( 2 + scaleX)
    else
        self:findChild("MonsterParty_up"):setScaleX( 2 - scaleX)
        self:findChild("MonsterParty_down"):setScaleX( 2 - scaleX)
    end
    

    self:findChild("root"):setScaleX(scaleX)
    self:findChild("root"):setScaleY(scaleX)

    self:findChild("Node_27"):setScaleX(scaleX)
    self:findChild("Node_27"):setScaleY(scaleX)

    self:findChild("MonsterParty_jiantou"):setScaleX(scaleX)
    self:findChild("MonsterParty_jiantou"):setScaleY(scaleX)

    
    

end


function MonsterPartyWheelMainView:onEnter()
 

end

function MonsterPartyWheelMainView:initRunView()

    local wheeldata1 = {}
    wheeldata1.imgSize = {width = 390, height = 1554}
    wheeldata1.symbolHeight = 222
    wheeldata1.machine = self.m_machine
    wheeldata1.wheelsData =  {0,1,2,3,0,2,1,3,2,0,1,3}
    wheeldata1.csbPath = "MonsterParty_ChooseWheel_1.csb"
    self.m_Wheel_1 = util_createView("CodeMonsterPartySrc.MonsterPartyWheelRunView",wheeldata1)
    self:findChild("wheel1"):addChild(self.m_Wheel_1)
    -- self.m_Wheel_1.m_FeatureNode:beginMove()


    local wheeldata2 = {}
    wheeldata2.imgSize = {width = 240, height = 1554}
    wheeldata2.symbolHeight = 222
    wheeldata2.machine = self.m_machine
    wheeldata2.wheelsData =  {5,8,10,12,5,8,10,12,5,8,10,12,5,8,10,12}
    wheeldata2.isAnit =  true
    wheeldata2.csbPath = "MonsterParty_ChooseWheel_2.csb"
    self.m_Wheel_2 = util_createView("CodeMonsterPartySrc.MonsterPartyWheelRunView",wheeldata2)
    self:findChild("wheel2"):addChild(self.m_Wheel_2)
    -- self.m_Wheel_1.m_FeatureNode:beginMove()
    
end
function MonsterPartyWheelMainView:onExit()
 
end


function MonsterPartyWheelMainView:beginWheel_1_run( )

    self.m_Point:runCsbAction("idle2",true)


    self.m_Wheel_1:setOverCallBackFun(function(  )

        

    end)

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType =  selfData.freeSpinType or 0

    -- 滚动停止
    local endData = {}
    endData.type = freeSpinType
    self.m_Wheel_1:setEndValue(endData)
    self.m_Wheel_1.m_FeatureNode.m_isPlaySound = true

    -- performWithDelay(self,function(  )
        self:beginWheel_2_run( )
    -- end,1)

    
end


function MonsterPartyWheelMainView:beginWheel_2_run( )
    

    self.m_Wheel_2:setOverCallBackFun(function(  )

        print("轮子2 滚动结束")
        gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_Wheel_stop.mp3")
        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_Wheel_Choose.mp3")

            self:findChild("Panel_1_0"):setVisible(true)
            self:findChild("Panel_1"):setVisible(true)

            self.m_Point:setVisible(true)
            self.m_Point:runCsbAction("shandian_show",false,function(  )
                
                self.m_Point:runCsbAction("shandian_idle",true)

                performWithDelay(self,function(  )

                    -- self:findChild("Panel_1_0"):setVisible(false)
                    -- self:findChild("Panel_1"):setVisible(false)
                    -- self.m_Point:setVisible(false)

                    if self.m_RunEndCallBackFun then
                        self.m_RunEndCallBackFun()
                    end 
          
                        

                end,1.5)
            end)
        end,1)
        


    end)


    local freeSpinsTotalCount = self.m_machine.m_runSpinResultData.p_freeSpinsTotalCount or 5

    -- 滚动停止
    local endData = {}
    endData.type = freeSpinsTotalCount

    self.m_Wheel_2:setEndValue(endData)

    self.m_Wheel_2.m_FeatureNode.m_isPlaySound = true

end

--默认按钮监听回调
function MonsterPartyWheelMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if  self.m_clicked then
        return
    end

    self.m_clicked = true

    if name == "click" then
        
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_taptospin_Click.mp3")

        self.m_aniSpinTip:runCsbAction("over")

        self:beginWheel_1_run( )

        
    end

end

function MonsterPartyWheelMainView:setRunEndCallBackFun( func )
    self.m_RunEndCallBackFun = function(  )

        if func then
            func()
        end

    end
end


return MonsterPartyWheelMainView