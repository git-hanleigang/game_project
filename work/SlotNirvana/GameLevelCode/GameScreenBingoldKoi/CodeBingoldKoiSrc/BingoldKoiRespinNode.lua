local BingoldKoiRespinNode = class("BingoldKoiRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 2800     --滚动速度 像素/每秒
local RES_DIS = 18

function BingoldKoiRespinNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end

--裁切遮罩透明度
function BingoldKoiRespinNode:initClipOpacity(opacity)
    
end

--子类可以重写 读取配置
function BingoldKoiRespinNode:initRunningData()
    self.m_runningData = globalData.slotRunData.levelConfigData:getNormalReelDatasByColumnIndex(self.p_colIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return BingoldKoiRespinNode