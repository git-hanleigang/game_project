local SpookySnacksRespinNode = class("SpookySnacksRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20          --回弹

--子类继承修改节点显示内容
function SpookySnacksRespinNode:changeNodeDisplay(node)

    -- node:setScale(0.5)
    -- if node.p_symbolType == self.m_machine.SYMBOL_BONUS1 or node.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
    --     self.m_machine:setSpecialNodeScore(node)
    -- end

end

--裁切遮罩透明度
function SpookySnacksRespinNode:initClipOpacity(opacity)
    self.m_bgNode = util_createAnimation("Socre_SpookySnacks_Blank.csb")
    self.m_clipNode:addChild(self.m_bgNode, 1)
    -- self.m_bgNode:setPosition(cc.p(self.m_reelSize.width / 2, self.m_reelSize.height / 2))
end

--根据配置随机
function SpookySnacksRespinNode:getRunningSymbolTypeByConfig()
    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    -- 挡板盖住的 直接滚空图标 不然的话 会卡的
    if self.m_machine["banzi"..self.p_rowIndex]:isVisible() then
        type = self.m_machine.SYMBOL_SCORE_BLANK
    end

    if self.m_machine.isChangeRespinBonus3 then
        if type == self.m_machine.SYMBOL_BONUS3 then
            type = self.m_machine.SYMBOL_SCORE_BLANK
        end
    end
    

    return type
end

--移除
-- function SpookySnacksRespinNode:onExit()
--     if self.m_machine.m_machine.m_isNeedChangeNode then
--         return
--     end

--     self:clearBaseData()
-- end

return SpookySnacksRespinNode
