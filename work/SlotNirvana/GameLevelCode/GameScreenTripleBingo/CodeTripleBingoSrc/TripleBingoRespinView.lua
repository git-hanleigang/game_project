local TripleBingoRespinView = class("TripleBingoRespinView", util_require("Levels.BaseReel.BaseRespinView"))
local PublicConfig = require "TripleBingoPublicConfig"

function TripleBingoRespinView:ctor(params)
    TripleBingoRespinView.super.ctor(self,params)
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function TripleBingoRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    TripleBingoRespinView.super.initRespinElement(self,machineElement, machineRow, machineColmn, startCallFun)
    
    self.m_line = util_createAnimation("Socre_TripleBingo_kuang.csb")
    --世界坐标
    local iCol,iRow = 3,3
    local pos, reelHeight, reelWidth = self.m_machine:getReelPos(iCol)
    pos.x = pos.x + reelWidth / 2 * self.m_machine.m_machineRootScale
    local columnData = self.m_machine.m_reelColDatas[iCol]
    local slotNodeH = columnData.p_showGridH
    pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machine.m_machineRootScale
    local linePos = self:convertToNodeSpace(pos)
    self.m_line:setPosition(linePos)
    self:addChild(self.m_line,1)


end

function TripleBingoRespinView:startMove()
    --解锁
    self:unLockAllSymbol()

    TripleBingoRespinView.super.startMove(self)
end
--[[
    单格停止
]]
function TripleBingoRespinView:runNodeEnd(symbolNode,info)
    TripleBingoRespinView.super.runNodeEnd(self,symbolNode,info)

    local bingoReelIndex = self.m_machine:getBingoReelIndexBySymbolType(symbolNode.p_symbolType)
    if bingoReelIndex then
        self:playBonusBulingAnim(symbolNode, bingoReelIndex)
    elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        self:playScatterBuling(symbolNode)
    end
end
function TripleBingoRespinView:playBonusBulingAnim(symbolNode, bingoReelIndex)
    local bLock = self.m_machine.m_bingoReelCtr:getBingoReelLockState(bingoReelIndex)
    if bLock then
        -- symbolNode:runAnim("darkstart", false)
    else
        local iCol  = symbolNode.p_cloumnIndex
        local iRow  = symbolNode.p_rowIndex
        local bHigh    = self.m_machine:checkNewBingoSymbolHigh(iCol, iRow)
        local animName = bHigh and "buling2" or "buling" 
        symbolNode:runAnim(animName, false, function()
            if bHigh then
                symbolNode:runAnim("idleframe2", true)
            end
        end)
    end
end
function TripleBingoRespinView:playScatterBuling(symbolNode)
    if self.m_machine:checkSymbolBulingSoundPlay(symbolNode) then
        symbolNode:runAnim("buling", false, function()
            symbolNode:runAnim("idleframe2", true)
        end)
    else
        symbolNode:runAnim("idleframe2", true)
    end
end

--[[
    播放图标落地音效
]]
function TripleBingoRespinView:playSymbolDownSound(symbolType,symbolNode)
    local isFix,isPlay =  self.m_machine:isFixSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self.m_machine:checkSymbolBulingSoundPlay(symbolNode) then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_7)
    elseif isFix and isPlay then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_12)
    end
end

---获取所有参与结算节点
function TripleBingoRespinView:getAllCleaningNode()
    local cleanNodes = TripleBingoRespinView.super.getAllCleaningNode(self)
    return cleanNodes
end

--[[
    检测锁定的小块是否需要放回去
]]
function TripleBingoRespinView:checkPutLockSymbolBack()
    for index = 1,#self.m_respinNodes do
        --默认锁定的小块需要放回去
        if self.m_respinNodes[index]:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            self:changeRespinNodeStatus(self.m_respinNodes[index],RESPIN_NODE_STATUS.IDLE)
        end
    end
end

--[[
    创建respinNode
]]
function TripleBingoRespinView:createRespinNode(nodeInfo)
    local status = nodeInfo.status
    local colIndex = nodeInfo.ArrayPos.iY
    local rowIndex = nodeInfo.ArrayPos.iX
    local parentData = self:getParentData(colIndex)
    local reelRunData = self:getReelRunData()
    local configData = self:getConfigData(reelRunData)
    local respinNode = util_require(self.m_respinNodeName):create({
        parentData = parentData,      --列数据
        configData = configData,      --列配置数据
        doneFunc = handler(self,self.respinNodeEndCallBack),        --单格停止回调
        createSymbolFunc = handler(self.m_machine,self.m_machine.getSlotNodeWithPosAndType),--创建小块
        pushSlotNodeToPoolFunc = handler(self.m_machine,self.m_machine.pushSlotNodeToPoolBySymobolType),--小块放回缓存池
        updateGridFunc = handler(self.m_machine,self.m_machine.updateReelGridNode),  --小块数据刷新回调
        direction = 0,      --0纵向 1横向 默认纵向
        colIndex = colIndex,
        rowIndex = rowIndex,
        clipType = self:getClipType(),
        parentView = self,
        machine = self.m_machine,      --必传参数

    })

    --设置假滚时使用假滚列表的方式
    respinNode:setRunType(false)

    return respinNode
end

--[[
    获取数据
]]
function TripleBingoRespinView:getParentData(colIndex)
    local reelDatas = self.m_machine.m_configData:getNormalReelDatasByColumnIndex(colIndex)
    local parentData = {
        reelDatas = reelDatas,
        beginReelIndex = math.random(1,#reelDatas),
        slotNodeW = self.m_slotNodeWidth,
        slotNodeH = self.m_slotNodeHeight,
        reelWidth = self.m_slotNodeWidth,
        reelHeight = self.m_slotNodeHeight,
        isDone = false
    }      --列数据
    return parentData
end

--[[
    获取配置
]]
function TripleBingoRespinView:getConfigData(reelRunData)
    

    local configData = {
        p_reelMoveSpeed = self.m_machine.m_configData.p_reelMoveSpeed,
        p_rowNum = 1,
        p_reelBeginJumpTime = self.m_machine.m_configData.p_reelBeginJumpTime,
        p_reelBeginJumpHight = self.m_machine.m_configData.p_reelBeginJumpHight,
        p_reelResTime = self.m_machine.m_configData.p_reelResTime,
        p_reelResDis = self.m_machine.m_configData.p_reelResDis,
        p_reelRunDatas = reelRunData --停轮间隔
    }
    return configData
end


--解除固定
function TripleBingoRespinView:unLockAllSymbol()
    local iStatus  = RESPIN_NODE_STATUS.IDLE
    for _index,_reSpinNode in ipairs(self.m_respinNodes) do
        local curStatus = _reSpinNode:getRespinNodeStatus()
        if 3 ~= _reSpinNode.m_colIndex or 3 ~= _reSpinNode.m_rowIndex then
            if iStatus ~= curStatus then
                self:changeRespinNodeStatus(_reSpinNode, iStatus)
            end
        elseif curStatus ~= RESPIN_NODE_STATUS.LOCK then
            self:changeRespinNodeStatus(_reSpinNode, RESPIN_NODE_STATUS.LOCK)
        end
    end
end



return TripleBingoRespinView 