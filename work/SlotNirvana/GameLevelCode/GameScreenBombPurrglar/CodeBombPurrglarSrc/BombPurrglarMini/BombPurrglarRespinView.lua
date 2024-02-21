local BombPurrglarRespinView = class("BombPurrglarRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 1
}

--组织滚动信息 开始滚动
function BombPurrglarRespinView:startMove()
    -- 重置一下mini轮盘的落地音效
    self.m_machine:resetsymbolBulingSoundArray()

    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    for i=1,#self.m_respinNodes do
        --!!!金钥匙后面的格子不用再滚动了
        local reSpinNode = self.m_respinNodes[i]
        local multipleReel = self.m_machine.m_userMultipleReel[reSpinNode.p_colIndex]
        

        if reSpinNode.p_rowIndex <= #multipleReel and reSpinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            reSpinNode:startMove()
        end
    end
end

--repsinNode滚动完毕后 置换层级
function BombPurrglarRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
          local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
          local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
          util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
          endNode:setTag(self.REPIN_NODE_TAG)
          endNode:setPosition(pos)
    end

    --!!! 将炸弹提层到裁切区域外
    self:changeBonus3Order(endNode)

    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
       gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    end
end

function BombPurrglarRespinView:changeBonus3Order(_endNode)
    if _endNode.p_symbolType == self.m_machine.m_machine.SYMBOL_BONUS_3 then
        local worldPos = _endNode:getParent():convertToWorldSpace(cc.p(_endNode:getPositionX(), _endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        _endNode:removeFromParent()
        local bonus3Order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 10* (self.m_machineColmn - _endNode.p_cloumnIndex) - _endNode.p_rowIndex
        self:addChild(_endNode , bonus3Order, self.REPIN_NODE_TAG)
        _endNode:setPosition(pos)
    end
end

--结束滚动播放落地
function BombPurrglarRespinView:runNodeEnd(endNode)


    if  endNode.p_symbolType == self.m_machine.m_machine.SYMBOL_BONUS_3  then
        endNode:runAnim("buling")
        local mainMachine = self.m_machine.m_machine
        local mainMachineConfig = mainMachine.m_configData
        self.m_machine:playBulingSymbolSounds(endNode.p_cloumnIndex, mainMachineConfig.Sound_Bonus1_buling)
    end

    --
end

function BombPurrglarRespinView:oneReelDown()
    gLobalSoundManager:playSound("Sounds/CommonReelDown_6.mp3")
end


--[[
    其他工具
]]
-- 获取信号小块
function BombPurrglarRespinView:getBombPurrglarSymbolNode(iX, iY)
    local symbolNode = nil

    local childs = self:getChildren()

    for i=1,#childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG  then
            if iX == node.p_rowIndex and iY == node.p_cloumnIndex then
                return node
            end
        end
    end

    local reSpinNode = self:getRespinNode(iX, iY)
    if reSpinNode and reSpinNode.m_lastNode then
        return reSpinNode.m_lastNode
    end

    print("[BombPurrglarRespinView:getBombPurrglarSymbolNode] error ",iY,iX)
    return nil
end

--
function BombPurrglarRespinView:getSymbolList(_symbolType)
    local list = {}

    local childs = self:getChildren()

    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local symbol = self:getBombPurrglarSymbolNode(iRow, iCol)
            if symbol and _symbolType == symbol.p_symbolType then
                list[#list + 1] =  symbol
            end
        end
        
    end

    return list
end


return BombPurrglarRespinView
