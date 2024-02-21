---
--xcyy
--2018年5月23日
--ZeusLoadingBarView.lua

local ZeusLoadingBarView = class("ZeusLoadingBarView",util_require("base.BaseView"))


function ZeusLoadingBarView:initUI(machine)


    self:createCsbNode("Zeus_jindutiao.csb")

    self.m_machine = machine

    self.PROGRESS_WIDTH = self:findChild("Panel_10"):getContentSize().width

    for i=1,3 do     
        self["actNode"..i] = util_createAnimation("Zeus_jindutiao_resetbd.csb")
        self:findChild("Node_resetbd_"..i):addChild(self["actNode"..i])
    end

    self:runCsbAction("idleframe",true)

    self:initBonusRound( 0 )
    self:setPercent(0)

    self:addClick(self:findChild("click"))
end


function ZeusLoadingBarView:onEnter()
 

end

function ZeusLoadingBarView:onExit()
 
end

--默认按钮监听回调
function ZeusLoadingBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if "click" then
        
        if not self.m_machine.m_Zeus_jackPoTip:isVisible() then

            if self.m_machine:checkCanClickJackpotTip( ) then
                
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                
                self.m_machine.m_Zeus_jackPoTip:stopAllActions()

                self.m_machine.m_Zeus_jackPoTip:setVisible(true)
                self.m_machine.m_Zeus_jackPoTip:runCsbAction("open",false,function(  )
                    self.m_machine.m_Zeus_jackPoTip:runCsbAction("idle")
                    performWithDelay(self.m_machine.m_Zeus_jackPoTip,function(  )
                        self.m_machine.m_Zeus_jackPoTip:runCsbAction("over",false,function(  )
                            self.m_machine.m_Zeus_jackPoTip:setVisible(false)
                        end)
                    end,3)
                end)
            end
            

            
        end
        

    end

end

function ZeusLoadingBarView:setPercent(percent)
    self:findChild("Node_jindu"):setPositionX(self.PROGRESS_WIDTH * percent * 0.01)
end

function ZeusLoadingBarView:updatePercent(percent)
    self:findChild("Node_jindu"):stopAllActions()
    self:runCsbAction("full",false,function(  )
        self:runCsbAction("idleframe",true)
    end)
    self:findChild("Node_jindu"):runAction(cc.MoveTo:create(0.3, cc.p(self.PROGRESS_WIDTH * percent * 0.01, 19)))
end


function ZeusLoadingBarView:initBonusRound( round )

    for i=1,3 do
        local specImg = self:findChild("zeus_spec_img_"..i)
        if specImg then
            specImg:setVisible(false)


            if round and ((round + 1) == i) then

                self["actNode"..i]:runCsbAction("animation0")
                specImg:setVisible(true)
            end

        end

        
    end

end

return ZeusLoadingBarView