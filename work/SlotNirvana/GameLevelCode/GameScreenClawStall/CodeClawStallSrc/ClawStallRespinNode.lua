local ClawStallRespinNode = class("ClawStallRespinNode", util_require("Levels.RespinNode"))

--裁切遮罩透明度
function ClawStallRespinNode:initClipOpacity(opacity)
    local respinBg = util_createAnimation("ClawStall_Respin_ReelBG.csb")
    self.m_clipNode:addChild(respinBg, SHOW_ZORDER.SHADE_LAYER_ORDER) 
end

--子类可以重写 读取配置
function ClawStallRespinNode:initRunningData()
    self.m_runningData = globalData.slotRunData.levelConfigData:getFsReelDatasByColumnIndex(1,self.p_colIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return ClawStallRespinNode