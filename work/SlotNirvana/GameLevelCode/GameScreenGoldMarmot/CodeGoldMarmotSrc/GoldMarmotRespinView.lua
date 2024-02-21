---
--xcyy
--2018年5月23日
--GoldMarmotRespinView.lua
local PublicConfig = require "levelsGoldMarmotPublicConfig"
local RespinView = util_require("Levels.RespinView")
local GoldMarmotRespinView = class("GoldMarmotRespinView",RespinView)

local TAG_BONUS_SPINE = 1001

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

local JACKPOT_TPYE = {
    "grand",
    "major",
    "minor",
    "mini"
}

--行进方向
local DIRECTION = {
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4
}

local DEFAULT_SCALE_X   =   1.02
local CORNER_SCALE_X    =   1.05

-- 构造函数
function GoldMarmotRespinView:ctor()
    GoldMarmotRespinView.super.ctor(self)

    self.m_jackpotBg = {}
    self.m_nodeFrames = {}
    self.m_bonusDown = {}
end

function GoldMarmotRespinView:createRespinNode(symbolNode, status)

    local respinNode = util_createView(self.m_respinNodeName)
    respinNode:setMachine(self.m_machine)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)

    --设置假滚卷轴
    local reelCfg =  self.m_machine.m_configData["freespinModeId_1_"..symbolNode.p_cloumnIndex] or {100,94}
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, reelCfg)
    
    respinNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    respinNode:setReelDownCallBack(function(symbolType, status)
        if self.respinNodeEndCallBack ~= nil then
            self:respinNodeEndCallBack(symbolType, status)
        end
    end, function(symbolType)
        if self.respinNodeEndBeforeResCallBack ~= nil then
            self:respinNodeEndBeforeResCallBack(symbolType)
        end
    end)

    self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    -- respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode.m_baseFirstNode = symbolNode
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

    
    local jackpotBg = util_createAnimation("GoldMarmot_respinjackpotbg.csb")
    self:addChild(jackpotBg, VIEW_ZORDER.REPSINNODE - 100)
    jackpotBg:setVisible(false)
    jackpotBg:setPosition(cc.p(respinNode:getPosition()))

    self.m_jackpotBg[#self.m_jackpotBg + 1] = jackpotBg
    jackpotBg.m_isHit = false
    jackpotBg:setScaleX(1.015)

    self:createFramesByRespinNode(respinNode)
end

function GoldMarmotRespinView:createFramesByRespinNode(respinNode)
    local clipSize = respinNode.m_clipNode.clipSize
    local centerPos = cc.p(respinNode:getPosition())

    local frames = {}
    --创建上边界
    local frameUp = util_createAnimation("GoldMarmot_respinkuang_heng.csb")
    frameUp:setPosition(cc.p(centerPos.x,centerPos.y + clipSize.height / 2 - 3))
    self:addChild(frameUp, VIEW_ZORDER.REPSINNODE - 90)
    frames[DIRECTION.UP] = frameUp
    frameUp:setVisible(false)

    --创建下边界
    local frameDown = util_createAnimation("GoldMarmot_respinkuang_heng.csb")
    frameDown:setPosition(cc.p(centerPos.x,centerPos.y - clipSize.height / 2 + 3))
    self:addChild(frameDown, VIEW_ZORDER.REPSINNODE - 90)
    frames[DIRECTION.DOWN] = frameDown
    frameDown:setVisible(false)

    --创建左边界
    local frameLeft = util_createAnimation("GoldMarmot_respinkuang_shu.csb")
    frameLeft:setPosition(cc.p(centerPos.x - clipSize.width / 2 + 3,centerPos.y))
    self:addChild(frameLeft, VIEW_ZORDER.REPSINNODE - 90)
    frames[DIRECTION.LEFT] = frameLeft
    frameLeft:setVisible(false)

    --创建下边界
    local frameRight = util_createAnimation("GoldMarmot_respinkuang_shu.csb")
    frameRight:setPosition(cc.p(centerPos.x + clipSize.width / 2 - 3,centerPos.y))
    self:addChild(frameRight, VIEW_ZORDER.REPSINNODE - 90)
    frames[DIRECTION.RIGHT] = frameRight
    frameRight:setVisible(false)

    self.m_nodeFrames[#self.m_nodeFrames + 1] = frames
end

--[[
    边框转变为金色
]]
function GoldMarmotRespinView:changeToGoldFrame()
    for k,frames in pairs(self.m_nodeFrames) do
        for k1,frame in pairs(frames) do
            if frame:isVisible() then
                frame:runCsbAction("bian")
            end
        end
        
    end
end

function GoldMarmotRespinView:hideAllFrame()
    for k,frames in pairs(self.m_nodeFrames) do
        for k1,frame in pairs(frames) do
            frame:setVisible(false)
        end
    end
end

function GoldMarmotRespinView:hideFrameByDirct(iCol,iRow,direction)
    local respinNodeIndex = self:getRespinNodeIndex(iCol,iRow)
    local frames = self.m_nodeFrames[respinNodeIndex]
    local frame = frames[direction]
    frame:runCsbAction("xiaoshi",false,function()
        frame:setVisible(false)
    end)
end

function GoldMarmotRespinView:showAllFrame(iCol,iRow,jackpotType)
    local respinNodeIndex = self:getRespinNodeIndex(iCol,iRow)
    local frames = self.m_nodeFrames[respinNodeIndex]

    for k,frame in pairs(frames) do
        frame:setVisible(true)
        frame:runCsbAction("chuxian")
        for index = 1,4 do
            frame:findChild("Node_"..JACKPOT_TPYE[index].."kuang"):setVisible(jackpotType == index)
        end
    end
    local respinNode = self.m_respinNodes[respinNodeIndex]

    local centerPos = cc.p(respinNode:getPosition())

    frames[DIRECTION.UP]:setScaleX(DEFAULT_SCALE_X)
    frames[DIRECTION.UP]:setPositionX(centerPos.x)
    frames[DIRECTION.DOWN]:setScaleX(DEFAULT_SCALE_X)
    frames[DIRECTION.DOWN]:setPositionX(centerPos.x)
end

function GoldMarmotRespinView:showFrameByDirct(iCol,iRow,direction,jackpotType)
    local respinNodeIndex = self:getRespinNodeIndex(iCol,iRow)
    local frames = self.m_nodeFrames[respinNodeIndex]
    local frame = frames[direction]
    frame:setVisible(true)
    frame:runCsbAction("chuxian")
    for index = 1,4 do
        frame:findChild("Node_"..JACKPOT_TPYE[index].."kuang"):setVisible(jackpotType == index)
    end
    local respinNode = self.m_respinNodes[respinNodeIndex]

    local centerPos = cc.p(respinNode:getPosition())

    if direction == DIRECTION.UP or direction == DIRECTION.DOWN then
        frame:setScaleX(DEFAULT_SCALE_X)
        frame:setPositionX(centerPos.x)
    end
end

function GoldMarmotRespinView:changeFramePos(iCol,iRow,direction,offset)
    local respinNodeIndex = self:getRespinNodeIndex(iCol,iRow)
    local respinNode = self.m_respinNodes[respinNodeIndex]
    local centerPos = cc.p(respinNode:getPosition())
    local frames = self.m_nodeFrames[respinNodeIndex]
    local frame = frames[direction]
    frame:setPositionX(centerPos.x + offset)
    frame:setScaleX(CORNER_SCALE_X)
end

--[[
    改变小块的锁定状态
]]
function GoldMarmotRespinView:changeRespinNodeLockStatus(respinNode, isLock,isWinLine)
    if isLock then
          if not respinNode.isLocked then
               --锁定小块不能滚动
                respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
                --变更小块父节点
                local pos =  util_convertToNodeSpace(respinNode.m_baseFirstNode,self)
                util_changeNodeParent(self,respinNode.m_baseFirstNode)
                respinNode.m_baseFirstNode:setPosition(pos)
                respinNode.isLocked = true 
          end
    else
          --解除小块的锁定状态
          respinNode:setFirstSlotNode(respinNode.m_baseFirstNode)
          respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
          respinNode.isLocked = false

    end
end

--[[
    检测是否需要显示快滚框
]]
function GoldMarmotRespinView:checkShowQuickRunAni()
    for index = 1,#self.m_respinNodes do
        if self.m_respinNodes[index]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            local curRsCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
            if curRsCount == 0 then
                self.m_respinNodes[index]:showQuickRunAni(false)
            elseif self:isNeedQuickRun(self.m_respinNodes[index]) then
                self.m_respinNodes[index]:showQuickRunAni(true)
            end
            
        end
  end
end

--repsinNode滚动完毕后 置换层级
function GoldMarmotRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
          local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
          local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
          util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
          endNode:setTag(self.REPIN_NODE_TAG)
          endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)

    if endNode and endNode.p_symbolType then
            
        if endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS then
              if not self.m_bonusDown[endNode.p_cloumnIndex] then
                    self.m_bonusDown[endNode.p_cloumnIndex] = true
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_bonus_down)
              end
        end     
        if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
              for iCol = 1,self.m_machine.m_iReelColumnNum do
                    self.m_bonusDown[iCol] = true
                    self.m_bonusDown[iCol] = true
              end
        end       
    end

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then

        self.m_bonusDown = {}
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end

        --检测是否需要快滚框
        self:checkShowQuickRunAni()
    end
end

function GoldMarmotRespinView:oneReelDown()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_reel_stop)
end

function GoldMarmotRespinView:runNodeEnd(endNode)
    if not endNode or not endNode.p_symbolType then
        return
    end

    
    local respinNode,respinNodeIndex = self:getRespinNodeByRowAndCol(endNode.p_cloumnIndex,endNode.p_rowIndex)

    local isQuick = false
    if respinNode then
        isQuick = respinNode.m_isQuick
        respinNode:changeRunSpeed(false)
        respinNode.m_isDown = true
    end

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_isQuickRun then
        self:checkPlayQuickRunSound()
    end
    
    
    

    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
          endNode:runAnim(info.runEndAnimaName, false)
          if endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS then
            local node = endNode:getCcbProperty("node_spine")
            if node then
                local spine = node:getChildByTag(TAG_BONUS_SPINE)
                if spine then
                    if not isQuick then
                        util_spinePlay(spine,"buling")
                        util_spineEndCallFunc(spine,"buling",function()
                            util_spinePlay(spine,"idleframe",true)
                        end)
                    else
                        util_spinePlay(spine,"buling2")
                        util_spineEndCallFunc(spine,"buling2",function()
                            util_spinePlay(spine,"idleframe",true)
                        end)
                    end
                    
                end
            end

            --隐藏快滚框
            if respinNode then
                respinNode:showQuickRunAni(false)
            end
            

            --背景变亮
            local jackpotBg= self.m_jackpotBg[respinNodeIndex]
            if respinNode and jackpotBg and not jackpotBg.m_isHit then
                jackpotBg:setVisible(true)
                jackpotBg:runCsbAction("bianliang",false,function()
                    jackpotBg:findChild("sp_"..JACKPOT_TPYE[respinNode.m_curJackpotType].."_dark"):setVisible(false)
                end)
                jackpotBg.m_isHit = true

                
                jackpotBg:findChild("sp_"..JACKPOT_TPYE[respinNode.m_curJackpotType ].."_light"):setVisible(true)
            end

          end
    end
end

--[[
    获取respinNode
]]
function GoldMarmotRespinView:getRespinNodeIndex(col, row)
    return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
    根据行列获取respinNode
]]
function GoldMarmotRespinView:getRespinNodeByRowAndCol(col,row)
    local respinNodeIndex = self:getRespinNodeIndex(col,row)
    local respinNode = self.m_respinNodes[respinNodeIndex]
    return respinNode,respinNodeIndex
end


--[[
    显示jackpot底色
]]
function GoldMarmotRespinView:showJackpotColor()
    for index,respinNode in ipairs(self.m_respinNodes) do
        local jackpotBg= self.m_jackpotBg[index]
        jackpotBg:setVisible(true)
        jackpotBg.m_isHit = false
        local jackpotType = respinNode.m_curJackpotType
        if jackpotType then
            for index = 1,4 do
                jackpotBg:findChild("Node_"..JACKPOT_TPYE[index].."bg"):setVisible(index == jackpotType)
                
            end
        end

        jackpotBg:findChild("sp_"..JACKPOT_TPYE[jackpotType].."_dark"):setVisible(true)
        jackpotBg:findChild("sp_"..JACKPOT_TPYE[jackpotType].."_light"):setVisible(false)
        jackpotBg:runCsbAction("chuxian",false,function()
            if respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
                jackpotBg:findChild("sp_"..JACKPOT_TPYE[respinNode.m_curJackpotType ].."_light"):setVisible(true)
                jackpotBg:runCsbAction("bianliang",false,function()
                    jackpotBg:findChild("sp_"..JACKPOT_TPYE[jackpotType].."_dark"):setVisible(false)
                end)
                jackpotBg.m_isHit = true
            end
        end)
        self:changeToGoldFrame()
    end
end

--获取所有参与结算节点
function GoldMarmotRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType and respinNode.m_baseFirstNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS then
            cleaningNodes[#cleaningNodes + 1] = respinNode.m_baseFirstNode
        end
        
    end
    return cleaningNodes
end

function GoldMarmotRespinView:showJackpotWinAni(jackpotIndex,func)
    for index,respinNode in ipairs(self.m_respinNodes) do
        local jackpotType = respinNode.m_curJackpotType
        if jackpotType == jackpotIndex then
            respinNode:showJackpotWinAni()
            local frames = self.m_nodeFrames[index]
            for k,frame in pairs(frames) do
                if frame:isVisible() then
                    frame:runCsbAction("jiesuan",true)
                end
            end
            
        end
    end

    self.m_machine:delayCallBack(20 / 60,func)
end

--组织滚动信息 开始滚动
function GoldMarmotRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    self.m_isQuickRun = false
    for i=1,#self.m_respinNodes do
        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
            self.m_respinNodes[i].m_isDown = false
            --检测是否需要快滚
            if self:isNeedQuickRun(self.m_respinNodes[i]) then
                local curRsCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
                if curRsCount <= 1 then
                    self.m_isQuickRun = true
                    self.m_respinNodes[i]:changeRunSpeed(true)
                end
                
            end
        else
            self.m_respinNodes[i].m_isDown = true
        end
    end

    if self.m_isQuickRun then
        self:checkPlayQuickRunSound()
    end
end

function GoldMarmotRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    if self.m_isQuickRun then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
    local quickRunNodes = {}
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false 
        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL

        if repsinNode.m_isQuickRun and self.m_isQuickRun then
            quickRunNodes[#quickRunNodes + 1] = repsinNode
            runLong = math.floor(runLong * 3.5)
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

    for index = 1,#quickRunNodes do
        local respinNode = quickRunNodes[index]
        respinNode.m_runNodeNum = respinNode.m_runNodeNum + math.floor(self.m_baseRunNum * (index - 1) * 1.5) 
    end
end

function GoldMarmotRespinView:isNeedQuickRun(respinNode)
    if respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
        return false
    end
    local mapData = self.m_machine.m_runSpinResultData.p_rsExtraData.map
    if not mapData then
        return false
    end

    local jackpotType = respinNode.m_curJackpotType
    if not mapData[jackpotType] then
        return false
    end

    local list = mapData[jackpotType]
    
    --计算锁定的数量
    local count = 0
    for k,serverIndex in pairs(list) do
        local pos = self.m_machine:getRowAndColByPos(serverIndex)
        -- local iCol,iRow = pos.iY,pos.iX
        local respinNodeIndex = self:getRespinNodeIndex(pos.iY,pos.iX)

        if self.m_respinNodes[respinNodeIndex]:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            count = count + 1
        end
    end

    if count == #list - 1 then
        return true
    end

    return false  
end

function GoldMarmotRespinView:checkPlayQuickRunSound()
    --检测剩余的快滚格子数量
    local totalCount,quickCount = 0,0
    for index = 1,#self.m_respinNodes do
        local node = self.m_respinNodes[index]
        if node:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            if not node.m_isDown then
                totalCount = totalCount + 1
            end
            
            if node.m_isQuick then
                quickCount = quickCount + 1
            end
        end
    end
    if quickCount >= totalCount then
        self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_quickRun_single)
    end
end

return GoldMarmotRespinView