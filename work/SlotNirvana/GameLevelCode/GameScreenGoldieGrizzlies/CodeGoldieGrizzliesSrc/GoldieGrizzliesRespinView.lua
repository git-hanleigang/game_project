local GoldieGrizzliesRespinView = class("GoldieGrizzliesRespinView", util_require("Levels.RespinView"))
local PublicConfig = require "GoldieGrizzliesPublicConfig"

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 1
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

function GoldieGrizzliesRespinView:initUI(respinNodeName)
    GoldieGrizzliesRespinView.super.initUI(self,respinNodeName)
    self.m_quickRunAni = util_createAnimation("GoldieGrizzlies_bonus_tishikuang.csb")
    self.m_quickRunAni:runCsbAction("idleframe",true)
    self:addChild(self.m_quickRunAni,10000)
    self:showQuickRunAni(false)
end

---获取所有参与结算节点
function GoldieGrizzliesRespinView:getAllCleaningNode()
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
        
    end
    return cleaningNodes
end

--组织滚动信息 开始滚动
function GoldieGrizzliesRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    self.m_bonusDown = {}
    local unLockNodes = {}
    for i=1,#self.m_respinNodes do
          if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                self.m_respinNodes[i]:startMove()
                self.m_respinNodes[i]:changeRunSpeed(false)
                unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]
          end
    end

    if #unLockNodes == 1 then
        self.m_quickRunAni:setPosition(cc.p(unLockNodes[1]:getPosition()))
        self:showQuickRunAni(true)
        -- 策划说出现快滚动效时就要播放快滚和音效
        -- local totalCount = self.m_machine.m_runSpinResultData.p_reSpinsTotalCount
        -- local curCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
        -- if curCount == 1 then
            unLockNodes[1]:changeRunSpeed(true)
            self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_quick_run_single, true)
        -- end
    else
        self:showQuickRunAni(false)
    end
end

--
function GoldieGrizzliesRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then

        if endNode and endNode.p_symbolType then
            
            if not self.m_bonusDown[endNode.p_cloumnIndex] then
                self.m_bonusDown[endNode.p_cloumnIndex] = true
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_bonus_down)
            end   
            if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                  for iCol = 1,self.m_machine.m_iReelColumnNum do
                    self.m_bonusDown[iCol] = true
                    self.m_bonusDown[iCol] = true
                  end
            end    
            
            endNode:runAnim(info.runEndAnimaName, false,function()

                if self.m_machine.m_runSpinResultData.p_selfMakeData and self.m_machine.m_runSpinResultData.p_selfMakeData.full then
                    self:showQuickRunAni(false)
                end
    
                endNode:runAnim("idleframe",true)
            end)
        end


        
    else
        if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 0 then
            self:showQuickRunAni(false)
        end
    end
end

function GoldieGrizzliesRespinView:oneReelDown()
    gLobalSoundManager:playSound("GoldieGrizzliesSounds/sound_GoldieGrizzlies_reel_stop.mp3")
end

function GoldieGrizzliesRespinView:createRespinNode(symbolNode, status)
    --非bonus小块转化成空信号
    if not self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
        if symbolNode.p_symbolImage then
            symbolNode.p_symbolImage:removeFromParent()
            symbolNode.p_symbolImage = nil
        end
        symbolNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_EMPTY), self.m_machine.SYMBOL_EMPTY)
    end

    local respinNode = util_createView(self.m_respinNodeName)
    respinNode:setMachine(self.m_machine)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)

    respinNode:setPosition(cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()))
    respinNode:setReelDownCallBack(
        function(symbolType, status)
            if self.respinNodeEndCallBack ~= nil then
                self:respinNodeEndCallBack(symbolType, status)
            end
        end,
        function(symbolType)
            if self.respinNodeEndBeforeResCallBack ~= nil then
                self:respinNodeEndBeforeResCallBack(symbolType)
            end
        end
    )

    self:addChild(respinNode, VIEW_ZORDER.REPSINNODE)

    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex), 130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        respinNode.m_baseFirstNode = symbolNode
        symbolNode:runAnim("idleframe",true)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

function GoldieGrizzliesRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    for j=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
          local bFix = false 
          local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
          if repsinNode.m_isQuick then
            runLong = runLong * 3
          end
          for i=1, #storedNodeInfo do
                local stored = storedNodeInfo[i]
                if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                      repsinNode:setRunInfo(runLong, stored.type)
                      bFix = true
                end
          end
          
          for i=1,#unStoredReels do
                local data = unStoredReels[i]
                if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                      repsinNode:setRunInfo(runLong, data.type)
                end
          end
    end
end

function GoldieGrizzliesRespinView:showQuickRunAni(isShow)
    self.m_quickRunAni:setVisible(isShow)
end

--repsinNode滚动完毕后 置换层级
function GoldieGrizzliesRespinView:respinNodeEndCallBack(endNode, status)

    GoldieGrizzliesRespinView.super.respinNodeEndCallBack(self,endNode, status)
    if status == RESPIN_NODE_STATUS.LOCK then
        endNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + endNode.p_cloumnIndex * 1000)
    end
     
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function GoldieGrizzliesRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    GoldieGrizzliesRespinView.super.initRespinElement(self,machineElement, machineRow, machineColmn, startCallFun)
    local childs = self:getAllCleaningNode()
    for i=1,#childs do
        local endNode = childs[i]
        endNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + endNode.p_cloumnIndex * 1000)
    end
end

return GoldieGrizzliesRespinView
