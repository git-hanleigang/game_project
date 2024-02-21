local RespinNode = util_require("Levels.RespinNode")
local JungleJauntRespinNode = class("JungleJauntRespinNode", RespinNode)

function JungleJauntRespinNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex)
    else
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_colIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--裁切遮罩透明度
function JungleJauntRespinNode:initClipOpacity(opacity)

end

return JungleJauntRespinNode
