local FlamingPompeiiRespinNode = class("FlamingPompeiiRespinNode", util_require("Levels.RespinNode"))

--裁切区域
function FlamingPompeiiRespinNode:initClipNode(clipNode,opacity)
    if true or not clipNode then
        local nodeHeight = self.m_slotReelHeight / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth,nodeHeight + 1)
        local pos = cc.p(-math.ceil( self.m_slotNodeWidth / 2 ),- nodeHeight / 2)
        self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
        self:addChild(self.m_clipNode, 10)
        --设置裁切块属性
        local originalPos = cc.p(0,0)
        util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
    else
        self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)
end
--裁切遮罩透明度
function FlamingPompeiiRespinNode:initClipOpacity(opacity)
    local pos   = cc.p(self.m_clipNode:getPosition())
    local order = 5

    local miniMachine = self.m_machine
    local mainMachine = miniMachine.m_machine

    self.m_dibanCsb = util_createAnimation("FlamingPompeii_diban.csb")
    self:addChild(self.m_dibanCsb, order)
    self.m_dibanCsb:runCsbAction("idle_dark")
    self.m_dibanCsb:setPosition(pos)

    self.m_bonus1Spine = mainMachine:createFlamingPompeiiTempSymbol(mainMachine.SYMBOL_Bonus1, {})
    self.m_dibanCsb:findChild("Node_bonus1Spine"):addChild(self.m_bonus1Spine)
    self.m_bonus1Spine:setVisible(false)

    self.m_diban0Csb = util_createAnimation("FlamingPompeii_diban_0.csb")
    self.m_dibanCsb:findChild("Node_diban0"):addChild(self.m_diban0Csb)
    self.m_diban0Csb:setVisible(false)
end

--子类可以重写 读取配置
function FlamingPompeiiRespinNode:initRunningData()
    local miniMachine     = self.m_machine
    local mainMachine     = miniMachine.m_machine
    local levelConfigData = miniMachine.m_configData

    if mainMachine.m_bSpecialReSpin then
        self.m_runningData = levelConfigData:getSpecialRespinCloumnByColumnIndex(self.p_colIndex)
    else
        self.m_runningData = levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--[[
    执行buff动画
]]
function FlamingPompeiiRespinNode:playBuffBulingAnim()
    self.m_diban0Csb:setVisible(true)
    self.m_diban0Csb:runCsbAction("animation", false, function()
        self.m_diban0Csb:setVisible(false)
    end)
end
function FlamingPompeiiRespinNode:playBuffStartAnim()
    self.m_dibanCsb:runCsbAction("start", false, function()
        self:playBuffKuangIdleAnim()
    end)

    self.m_bonus1Spine:setVisible(true)
    self.m_bonus1Spine:runAnim("actionframe_shang3", false, function()
        self.m_bonus1Spine:setVisible(false)
    end)
end
function FlamingPompeiiRespinNode:getBuffStartAnimTime()
    return util_csbGetAnimTimes(self.m_dibanCsb.m_csbAct, "start")
end

function FlamingPompeiiRespinNode:playBuffKuangIdleAnim()
    self.m_dibanCsb:runCsbAction("idle_kuang", true)
end
function FlamingPompeiiRespinNode:playBuffOverAnim()
    local animTime = util_csbGetAnimTimes(self.m_dibanCsb.m_csbAct, "over_kuang")
    self.m_dibanCsb:runCsbAction("over_kuang", false)
    return animTime
end

return FlamingPompeiiRespinNode
