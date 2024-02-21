---
--xcyy
--2018年5月23日
--ClassicRapid2CollectLittleView.lua

local ClassicRapid2CollectLittleView = class("ClassicRapid2CollectLittleView",util_require("base.BaseView"))

ClassicRapid2CollectLittleView.m_index = 1
function ClassicRapid2CollectLittleView:initUI(index)

    local csbName = "ClassicRapid2_jinku"

    if index == 10 then -- 最后一个是大的
        -- csbName = "ClassicRapid2_shouji_da"
    end

    self:createCsbNode(csbName..".csb")

    self.m_index = index

    self:runCsbAction("idle",true)
end


function ClassicRapid2CollectLittleView:playShowAnimation(isAdd)
    if isAdd then
        gLobalSoundManager:pauseBgMusic()

        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_bonusCollect.mp3",false)
        self:setVisible(true)
        self:findChild("Node_1"):setVisible(false)
        local anim = util_createAnimation("ClassicRapid2_jinku_baodian.csb")
        self:addChild(anim)
        anim:playAction("actionframe",false,function()
            anim:setVisible(false)
        end)
        performWithDelay(self,function()
            self:findChild("Node_1"):setVisible(true)
        end,8/30)
    else
        self:setVisible(true)
        self:findChild("Node_1"):setVisible(true)
    end
end

function ClassicRapid2CollectLittleView:onEnter()

end


function ClassicRapid2CollectLittleView:onExit()

end




return ClassicRapid2CollectLittleView