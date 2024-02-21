

local RespinNode = util_require("Levels.RespinNode")
local Christmas2021RespinNode = class("Christmas2021RespinNode", RespinNode)
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 40

--====================重写父类

--裁切遮罩透明度
function Christmas2021RespinNode:initClipOpacity(opacity)
    -- if opacity and opacity>0 then
    --     local pos = cc.p(-self.m_slotNodeWidth*0.5-2 , -self.m_slotNodeHeight*0.5-5)
    --     local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
    --     local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
    --     local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,80,spPath)
    --     self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    -- end
end

--子类可以重写修改滚动参数
function Christmas2021RespinNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end

return Christmas2021RespinNode