--
-- 泰山飞动画
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local TzrzanFlayAction = class("TzrzanFlayAction", util_require("base.BaseView"))


function TzrzanFlayAction:initUI(  )
    self:createCsbNode("TarzanFight/GameScreenTarzanFight_fly.csb")
    self.m_spine_node = self:findChild("spine_node")
    local symbolpath = "Spine/ZheDang"
    -- self.m_spine_action = util_spineCreate(symbolpath, true)
    -- self.m_spine_node:addChild(self.m_spine_action)  

    self:runCsbAction("show")
  
end

function TzrzanFlayAction:setRootScale(machineRootScale )
    -- self:findChild("Panel_2"):setScaleX(machineRootScale)
    -- self:findChild("Panel_2"):setScaleY(machineRootScale)

    -- local lost = 0.43
                  
end
function TzrzanFlayAction:playAction(isloop,func )
    self:runCsbAction("fly",isloop,func)
    --self:playSpinSpinAction(isloop,func)
end

function TzrzanFlayAction:playEndAction(isloop,func )
    self:runCsbAction("fly1",isloop,func)
    --self:playSpinSpinAction(isloop,func)
end
function TzrzanFlayAction:playSpinSpinAction(isloop,func)
    if self.m_spine_action then
        util_spinePlay(self.m_spine_action, "animation", isloop)
        self.m_spine_action:registerSpineEventHandler( function(event)
            if event.animation == "animation" then
                if func then
                    func()
                end
            end
        end , sp.EventType.ANIMATION_COMPLETE)
    end
end

return  TzrzanFlayAction