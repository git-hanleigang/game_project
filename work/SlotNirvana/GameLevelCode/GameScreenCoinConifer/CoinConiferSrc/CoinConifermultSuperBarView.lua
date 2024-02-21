---
--xcyy
--2018年5月23日
--CoinConifermultSuperBarView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConifermultSuperBarView = class("CoinConifermultSuperBarView",util_require("Levels.BaseLevelDialog"))


function CoinConifermultSuperBarView:initUI(machine)

    self:createCsbNode("CoinConifer_super_multbar.csb")
    self.m_machine = machine
    self.mulNode = util_createAnimation("CoinConifer_mult.csb")
    self:findChild("Node_mult"):addChild(self.mulNode)
    --成倍上的光
    self.mulNode.light = util_createView("CoinConiferSrc.CoinConifermultBarLightView")
    self.mulNode:findChild("Node_light"):addChild(self.mulNode.light)


    self.isInit = false
    self.curMul = 0

    self:initMulShow()

    self.changeMulNode = cc.Node:create()
    self:addChild(self.changeMulNode)

    self.changeMulNode1 = cc.Node:create()
    self:addChild(self.changeMulNode1)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CoinConifermultSuperBarView:initMulShow()
    self.isInit = true
    self.curMul = 0
    if not tolua.isnull(self.mulNode.light) then
        self.mulNode.light:showLightIdle2()     --无光效
    end
    self.mulNode:runCsbAction("idle")
    self.mulNode:findChild("2x"):setVisible(false)
    self.mulNode:findChild("3x"):setVisible(false)
    self.mulNode:findChild("4x"):setVisible(false)
    self.mulNode:findChild("5x"):setVisible(false)
end

function CoinConifermultSuperBarView:changeMulShow()
    local freespinExtra = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    -- 测试
    -- local numList = {2,5}
    -- self.index = math.random(1,2)
    --numList[self.index]
    local linewinmulit = freespinExtra.linewinmulit or 2
    local actName = "fankui"
    local fankuiTime = 55/60
    if linewinmulit == 5 then
        actName = "xiaoguo"
        fankuiTime = 40/60
    end
    if not tolua.isnull(self.mulNode.light) then
        self.mulNode.light:hideLight()
    end
    
    if self.isInit then
        if self.m_machine.freeType == 3 then            --super
            if linewinmulit == 5 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superFree_showFive)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_super_chengbei_show)
            end
        end
        self.isInit = false
    else
        if self.m_machine.freeType == 3 then        --super
            if linewinmulit == 5 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superFree_changeFive)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_super_chengbei_change)
            end
        end
        
    end
    if linewinmulit == 5 then
        if not tolua.isnull(self.m_machine.superFreeMulFive) then
            self.m_machine.superFreeMulFive:setVisible(true)
            local actName2 = "actionframe"
            if self.m_machine.freeType == 3 then
                actName2 = "actionframe2"
            end
            self.m_machine.superFreeMulFive:runCsbAction(actName2,false,function ()
                self.m_machine.superFreeMulFive:setVisible(false)
            end)
        end
        self.m_machine:delayCallBack(40/60,function ()
            self.mulNode:runCsbAction(actName,false,function ()
                
            end)
            performWithDelay(self.changeMulNode1,function ()
                self.mulNode:runCsbAction("idle")
            end,fankuiTime)
            
            performWithDelay(self.changeMulNode,function ()
                self.mulNode:findChild("2x"):setVisible(linewinmulit == 2)
                self.mulNode:findChild("3x"):setVisible(linewinmulit == 3)
                self.mulNode:findChild("4x"):setVisible(linewinmulit == 4)
                self.mulNode:findChild("5x"):setVisible(linewinmulit == 5)
            end,5/60)
        end)
    else
        self.mulNode:runCsbAction(actName,false,function ()
        end)
        performWithDelay(self.changeMulNode1,function ()
            self.mulNode:runCsbAction("idle")
        end,fankuiTime)
        performWithDelay(self.changeMulNode,function ()
            self.mulNode:findChild("2x"):setVisible(linewinmulit == 2)
            self.mulNode:findChild("3x"):setVisible(linewinmulit == 3)
            self.mulNode:findChild("4x"):setVisible(linewinmulit == 4)
            self.mulNode:findChild("5x"):setVisible(linewinmulit == 5)
        end,20/60)
    end
    
end

function CoinConifermultSuperBarView:showMulForWinLine()
    self.changeMulNode1:stopAllActions()
    self.mulNode:runCsbAction("idle2",true)
    if not tolua.isnull(self.mulNode.light) then
        self.mulNode.light:showLight()
    end
    
end

function CoinConifermultSuperBarView:showMulForOver(func)
    self.changeMulNode1:stopAllActions()
    self.mulNode:runCsbAction("over",false,function ()
        if func then
            func()
        end
    end)
end
return CoinConifermultSuperBarView