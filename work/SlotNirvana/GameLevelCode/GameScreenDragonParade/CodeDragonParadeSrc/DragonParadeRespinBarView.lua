---
--xcyy
--2018年5月23日
--DragonParadeRespinBarView.lua

local DragonParadeRespinBarView = class("DragonParadeRespinBarView",util_require("Levels.BaseLevelDialog"))


function DragonParadeRespinBarView:initUI()

    self:createCsbNode("DragonParade_bar.csb")
    self.m_nodes = {}
    for i=1,3 do
        self.m_nodes[i] = util_createAnimation("DragonParade_bar_0.csb")
        self:findChild("Node_1_" .. i):addChild(self.m_nodes[i])
    end
    self.m_changeNode = self:findChild("Node_1")
    self.m_completeNode = self:findChild("Node_2")
end


function DragonParadeRespinBarView:onEnter()
    DragonParadeRespinBarView.super.onEnter(self)
end

function DragonParadeRespinBarView:onExit()
    DragonParadeRespinBarView.super.onExit(self)
end

function DragonParadeRespinBarView:setTimes(times)
    for i=1,3 do
        if i == times then
            self.m_nodes[i]:findChild("Node_1"):setVisible(true)
            self.m_nodes[i]:findChild("Node_2"):setVisible(false)
            for j=1,3 do
                self.m_nodes[i]:findChild("zi_" .. j):setVisible(j == i)
            end
        else
            self.m_nodes[i]:findChild("Node_1"):setVisible(false)
            self.m_nodes[i]:findChild("Node_2"):setVisible(true)

            for j=1,3 do
                self.m_nodes[i]:findChild("zi_" .. j .. "_0"):setVisible(j == i)
            end
        end
        
    end
end

function DragonParadeRespinBarView:changeRespinTimes(times, isinit)
    if times == 3 then
        if not isinit then
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinTimes_reset.mp3")

            self.m_nodes[3]:runCsbAction("actionframe")
        end
    else
        
    end
    self:setTimes(times)
    
end

function DragonParadeRespinBarView:setCompleteType()
    self.m_changeNode:setVisible(false)
    self.m_completeNode:setVisible(true)
end

function DragonParadeRespinBarView:setChangeType()
    self.m_changeNode:setVisible(true)
    self.m_completeNode:setVisible(false)
end

return DragonParadeRespinBarView