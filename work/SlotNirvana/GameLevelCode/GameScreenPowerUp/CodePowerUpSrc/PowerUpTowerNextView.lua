--按钮 展示 控制类
--PowerUpTowerNextView.lua

local PowerUpTowerNextView = class("PowerUpTowerNextView",util_require("base.BaseView"))


function PowerUpTowerNextView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("PowerUp_Tips.csb")

    self.m_nodeTip = self:findChild("node_tip")
    self.m_nodeTip:setScale(1.1)
    self.m_winWheel = util_createView("CodePowerUpSrc.PowerUpTowerWInView")
    self:addChild(self.m_winWheel,-1)
    self.m_winWheel:setVisible(false)

    self:runCsbAction("idle",true)
end

function PowerUpTowerNextView:showTip()
    self.m_nodeTip:setPosition(0,-1000)
    self.m_nodeTip:setOpacity(0)
    self.m_nodeTip:setVisible(true)

    util_playFadeInAction(self.m_nodeTip,0.5,function()

    end)
    util_playMoveToAction(self.m_nodeTip,0.5,cc.p(0,0))
end

function PowerUpTowerNextView:hideAll()
    self.m_winWheel:setVisible(false)
    self.m_nodeTip:setVisible(false)
end

function PowerUpTowerNextView:showGoodLuck()
    self.m_winWheel:showGoodLucky()
    self.m_winWheel:setVisible(true)
    self.m_nodeTip:setVisible(false)

end
function PowerUpTowerNextView:resetView()
    self.m_winWheel:resetView()
    self:showGoodLuck()
end

function PowerUpTowerNextView:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        if params and params.isDirectRequest then -- 特殊需求，自动请求下一步，低bet直接转出结果
            self:showGoodLuck()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SPECIAL_SPIN)
        else
            if self.showTip then
                self:showTip()
            end
        end
    end,ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN)
end


function PowerUpTowerNextView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

--默认按钮监听回调
function PowerUpTowerNextView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_clickSpin.mp3")
        self:showGoodLuck()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SPECIAL_SPIN)
    end

end


return PowerUpTowerNextView