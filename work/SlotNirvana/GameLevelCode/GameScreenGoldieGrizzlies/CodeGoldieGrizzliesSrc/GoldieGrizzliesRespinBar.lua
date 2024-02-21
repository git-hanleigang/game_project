

local GoldieGrizzliesRespinBar = class("GoldieGrizzliesRespinBar", util_require("Levels.BaseLevelDialog"))


function GoldieGrizzliesRespinBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("GoldieGrizzlies_respinbar.csb")
    self:findChild("Particle_1"):setVisible(false)
end
---
-- 更新freespin 剩余次数
--
function GoldieGrizzliesRespinBar:changeRespinByCount(curCount)
    local totalCount = self.m_machine.m_runSpinResultData.p_reSpinsTotalCount
    
    self:findChild("m_lb_num_2"):setString(totalCount)
    self:findChild("m_lb_num_1"):setString(totalCount - curCount)

    self:updateLabelSize({label=self:findChild("m_lb_num_1"),sx=1,sy=1},55)
    self:updateLabelSize({label=self:findChild("m_lb_num_2"),sx=1,sy=1},55)
end

function GoldieGrizzliesRespinBar:addTimeAni()
    self:runCsbAction("actionframe")
    self:findChild("Particle_1"):setVisible(true)
    self:findChild("Particle_1"):resetSystem()
end

return GoldieGrizzliesRespinBar