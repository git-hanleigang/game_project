local BombPurrglarRespinNode = class("BombPurrglarRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20          --回弹

local BASE_RUN_NUM = 20     --滚动参数 滚动数量
local BASE_COL_INTERVAL = 3 --滚动参数 列间隔递增

--子类继承修改节点显示内容
function BombPurrglarRespinNode:changeNodeDisplay(node)

    self.m_machine:upDateMultiSymbolScore(node, node.p_cloumnIndex, node.p_rowIndex)
    if node.p_symbolType == self.m_machine.SYMBOL_BONUSGAME_BOMB then
        -- node:setScale(0.6)
    end
    
end

--裁切遮罩透明度
function BombPurrglarRespinNode:initClipOpacity(opacity)
    if false and opacity and opacity>0 then
        local pos = cc.p(0 , 0)
        local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        local spPath = "common/PepperBlast_RESPIN_DI.png"
        opacity = 255
        local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
        self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

return BombPurrglarRespinNode
