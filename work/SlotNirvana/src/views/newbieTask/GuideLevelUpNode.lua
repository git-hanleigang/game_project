--npc
local GuideLevelUpNode = class("GuideLevelUpNode", util_require("base.BaseView"))
function GuideLevelUpNode:initUI()
    local offY = 0
    local offX = 0
    if globalData.slotRunData.isPortrait == true then

    else
        offX = -80
        offY = -250
    end
    self.m_npc = util_createView("views.newbieTask.GuideNpcNode")
    self:addChild(self.m_npc)
    self.m_npc:showIdle(1)
    self.m_npc:setPosition(-270+offX,350+offY)
    self.m_npc:setScale(0.6)
    self.m_npc:setOpacity(0)
    self.m_npc:runAction(cc.FadeIn:create(0.5))

    self.m_pop = util_createView("views.newbieTask.GuidePopNode")
    self:addChild(self.m_pop)
    self.m_pop:showIdle(2)
    self.m_pop:setPosition(-200+offX,550+offY)
    self.m_pop:setScale(1)
    self.m_pop:setOpacity(0)
    performWithDelay(self,function()
        self.m_pop:runAction(cc.FadeIn:create(0.5))
    end,1)

    self.m_finger = util_spineCreate("GuideNewUser/Other/DailyBonusGuide", false, true, 1)
    self:addChild(self.m_finger)
    util_spinePlay(self.m_finger, "idleframe", true)
end
return GuideLevelUpNode