local RespinNode = util_require("Levels.RespinNode")
local AChristmasCarolRespinNode = class("AChristmasCarolRespinNode", RespinNode)

function AChristmasCarolRespinNode:initRunningData()
    if self.m_machine.m_isMiniMachine then
        if self.m_machine.m_parent.m_modeType[3] == 1 then
            self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex.."_1")
        else
            self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex)
        end
    else
        if self.m_machine.m_modeType[3] == 1 then
            self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex.."_1")
        else
            self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex)
        end
    end

    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--裁切遮罩透明度
function AChristmasCarolRespinNode:initClipOpacity(opacity)

end

return AChristmasCarolRespinNode
