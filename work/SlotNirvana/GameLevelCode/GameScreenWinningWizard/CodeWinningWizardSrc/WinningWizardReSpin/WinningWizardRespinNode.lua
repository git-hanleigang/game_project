local WinningWizardRespinNode = class("WinningWizardRespinNode", util_require("Levels.RespinNode"))

--裁切区域
function WinningWizardRespinNode:initClipNode(clipNode,opacity)
    if true or not clipNode then
        self.m_clipNode = cc.ClippingNode:create()
        self:addChild(self.m_clipNode, 10)
        self.m_clipNode:setPositionY(3)
        local stencil = display.newSprite("#WinningWizardCommon/WinningWizard_free_yuan.png")
        self.m_clipNode:setStencil(stencil)
        self.m_clipNode:setInverted(false)
        self.m_clipNode:setAlphaThreshold(0)
    else
        self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)
end
--裁切遮罩透明度
function WinningWizardRespinNode:initClipOpacity(opacity)
    local pos   = cc.p(self.m_clipNode:getPosition())
end

--子类可以重写 读取配置
function WinningWizardRespinNode:initRunningData()
    local mainMachine     = self.m_machine
    local levelConfigData = mainMachine.m_configData

    self.m_runningData = levelConfigData:getNormalRespinCloumnByColumnIndex(1)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return WinningWizardRespinNode
