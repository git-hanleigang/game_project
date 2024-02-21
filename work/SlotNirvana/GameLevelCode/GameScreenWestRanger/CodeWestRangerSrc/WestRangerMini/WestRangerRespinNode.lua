local WestRangerRespinNode = class("WestRangerRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20          --回弹

--子类继承修改节点显示内容
function WestRangerRespinNode:changeNodeDisplay(node)

    -- node:setScale(0.5)
    -- if node.p_symbolType == self.m_machine.SYMBOL_BONUS1 or node.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
    --     self.m_machine:setSpecialNodeScore(node)
    -- end

end

--裁切遮罩透明度
function WestRangerRespinNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
        -- local pos = cc.p(0 , 0)
        -- local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        -- local spPath = "ui/WestRanger_reel_11_1.png"
        -- opacity = 255
        -- local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
        -- colorNode:setScale(0.5)
        -- local colorNode = util_createAnimation("Socre_WestRanger_Respin_Genzi.csb")
        -- self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

--子类可以重写 读取配置
function WestRangerRespinNode:initRunningData()
        
    if self.m_machine.m_machine.m_runSpinResultData.p_rsExtraData.kind == "special" then
        self.m_runningData = self.m_machine.m_configData:getSpecialRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = self.m_machine.m_configData:getRespinCloumnByColumnIndex(self.p_rowIndex)
    end
  
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return WestRangerRespinNode
