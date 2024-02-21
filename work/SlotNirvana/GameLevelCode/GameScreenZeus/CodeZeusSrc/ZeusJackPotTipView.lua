---
--xcyy
--2018年5月23日
--ZeusJackPotTipView.lua

local ZeusJackPotTipView = class("ZeusJackPotTipView",util_require("base.BaseView"))

ZeusJackPotTipView.m_actName = nil

function ZeusJackPotTipView:initUI(machine)

    self:createCsbNode("Zeus_jackPoTip.csb")

    self.m_actName = nil

    self.m_machine = machine

     -- 获得子节点
    self:addClick(self:findChild("click")) 


   

end


function ZeusJackPotTipView:onEnter()
 

end

function ZeusJackPotTipView:onExit()
 
end

function ZeusJackPotTipView:closeTip( )
    
    if self.m_machine.m_Zeus_jackPoTip:isVisible() then

        self.m_machine.m_Zeus_jackPoTip:setVisible(false)
        self.m_machine.m_Zeus_jackPoTip:stopAllActions()
    end

end

--默认按钮监听回调
function ZeusJackPotTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        if self.m_machine.m_Zeus_jackPoTip:isVisible() then

            if self.m_actName and self.m_actName == "idle" then
                self.m_machine.m_Zeus_jackPoTip:stopAllActions()

                self.m_machine.m_Zeus_jackPoTip:runCsbAction("over",false,function(  )
                    self.m_machine.m_Zeus_jackPoTip:setVisible(false)
                end)


            end
    
        end
    end

end

--播放动画
function ZeusJackPotTipView:runCsbAction(key,loop,func,fps)
    if not fps then
        fps= 30
    end

    self.m_actName = key

    util_csbPlayForKey(self.m_csbAct,key,loop,func,fps)
end




return ZeusJackPotTipView