---
--xcyy
--2018年5月23日
--BeastlyBeautyBonusGameOverView.lua

local BeastlyBeautyBonusGameOverView = class("BeastlyBeautyBonusGameOverView",util_require("base.BaseView"))


function BeastlyBeautyBonusGameOverView:initUI()

    self.m_click = false

    self:createCsbNode("BeastlyBeauty/BonusOver.csb")

    -- 弹板上的光
    local tanbanShine = util_createAnimation("BeastlyBeauty/BeastlyBeauty_tbover_shine.csb")
    self:findChild("Node_shine"):addChild(tanbanShine)
    tanbanShine:runCsbAction("idle",true)

    -- 弹板角色
    local jiaose1 = util_spineCreate("Socre_BeastlyBeauty_7", true, true)
    self:findChild("Node_juese1"):addChild(jiaose1)
    util_spinePlay(jiaose1,"actionframe2",true)

    local jiaose2 = util_spineCreate("Socre_BeastlyBeauty_9", true, true)
    self:findChild("Node_juese2"):addChild(jiaose2)
    util_spinePlay(jiaose2,"actionframe2",true)

    local guangSpine = util_spineCreate("BeastlyBeauty_tanban_guang", true, true)
    self:findChild("Node_guang1"):addChild(guangSpine)
    util_spinePlay(guangSpine,"idle",true)
end

function BeastlyBeautyBonusGameOverView:onEnter()

end

function BeastlyBeautyBonusGameOverView:initViewData(machine,coins,callBackFun)

    self.m_machine = machine

    local node1=self:findChild("m_lb_coins")

    self:runCsbAction("start")
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickJieSuanStart)

    self.m_callFun = callBackFun
    node1:setString(coins)

    self:updateLabelSize({label=node1,sx=1,sy=1},730)
    
end

function BeastlyBeautyBonusGameOverView:onExit()
 
end

function BeastlyBeautyBonusGameOverView:clickFunc(sender)
    local name = sender:getName()

    if name == "Button" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickJieSuanOver)

        self:runCsbAction("over",false,function(  )
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)


    end
end

return BeastlyBeautyBonusGameOverView