local TripleBingoRespinNode = class("TripleBingoRespinNode", util_require("Levels.BaseReel.BaseRespinNode"))

--裁切遮罩透明度
function TripleBingoRespinNode:initClipOpacity(opacity)
    
end

--[[
    初始化小块显示
]]
function TripleBingoRespinNode:initSymbolNode(hasFeature)
    TripleBingoRespinNode.super.initSymbolNode(self,hasFeature)
    --初始化显示隐藏裁切区域外的小块
    local rollNode = self:getRollNodeByRowIndex(2)
    rollNode:setVisible(false)
end

--[[
    开始滚动
]]
function TripleBingoRespinNode:startMove(func)
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            rollNode:setVisible(true)
        end
    end)
    TripleBingoRespinNode.super.startMove(self,func)
end

return TripleBingoRespinNode