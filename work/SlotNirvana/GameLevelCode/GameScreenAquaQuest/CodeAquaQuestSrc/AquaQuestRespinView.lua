
local PublicConfig = require "AquaQuestPublicConfig"
local AquaQuestRespinView = class("AquaQuestRespinView", util_require("Levels.BaseReel.BaseRespinView"))

local MOVE_SPEED = 2000     --滚动速度 像素/每秒

function AquaQuestRespinView:ctor(respinNodeName)
    AquaQuestRespinView.super.ctor(self,respinNodeName)
    self.m_isReelDown = false
    self.m_lockNodes = {}
    self.m_bigLockNodes = {}
end

--[[
    获取配置
]]
function AquaQuestRespinView:getConfigData(reelRunData)
    

    local configData = {
        p_reelMoveSpeed = MOVE_SPEED,
        p_rowNum = 1,
        p_reelBeginJumpTime = self.m_machine.m_configData.p_reelBeginJumpTime,
        p_reelBeginJumpHight = self.m_machine.m_configData.p_reelBeginJumpHight,
        p_reelResTime = self.m_machine.m_configData.p_reelResTime,
        p_reelResDis = self.m_machine.m_configData.p_reelResDis,
        p_reelRunDatas = reelRunData --停轮间隔
    }
    return configData
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function AquaQuestRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    
    self.m_machineElementData = machineElement

    --整行裁切
    if self:getClipType() == RESPIN_CLIPTYPE.COMBINE then
        self:initClipNodes(machineElement)
    end

    for index = 1,#machineElement do
        local nodeInfo = machineElement[index]
        local iCol = nodeInfo.ArrayPos.iY
        local iRow = nodeInfo.ArrayPos.iX
        
        local status = nodeInfo.status
        local respinNode = self:createRespinNode(nodeInfo)
        

        self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

        if self:getClipType() == RESPIN_CLIPTYPE.COMBINE then
            local clipNode = self.m_clipNodes[iRow]
            local pos = clipNode:convertToNodeSpace(nodeInfo.Pos)
            clipNode:addChild(respinNode)
            respinNode:setPosition(pos)
        else
            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            respinNode:setPosition(pos)
            self:addChild(respinNode)
        end

        --初始化respinNode上的小块
        local lastList = {nodeInfo.Type}
        respinNode:setSymbolList(lastList)
        respinNode:initSymbolNode(true)

        local endInfo = self:getEndTypeInfo(nodeInfo.Type)
        --锁定的respinNode
        if endInfo then
            self:changeRespinNodeStatus(respinNode,RESPIN_NODE_STATUS.LOCK)
            local symbolNode = respinNode:getLockSymbolNode()
            if not tolua.isnull(symbolNode) then
                symbolNode:runAnim("idleframe4",true)
            end
        end
    end

    self:readyMove()
end

--组织滚动信息 开始滚动
function AquaQuestRespinView:startMove()
    self:changeTouchStatus(ENUM_TOUCH_STATUS.RUN)

    local isAllDown = true
    for index = 1,#self.m_respinNodes do
        if self.m_respinNodes[index]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            isAllDown = false
            self.m_respinNodes[index]:startMove()
        end
    end

    --滚轮满了
    if isAllDown then
        --滚动停止
        self.m_isReelDown = true
        self.m_parentView:reSpinReelDown()
    end
end

--[[
    变更respinNode状态
]]
function AquaQuestRespinView:changeRespinNodeStatus(respinNode,status)
    --判断状态是否一致
    if status == respinNode:getRespinNodeStatus() then
        return
    end

    local posIndex = self.m_parentView:getPosReelIdx(respinNode.m_rowIndex,respinNode.m_colIndex)

    --锁定状态,小块提层
    if status == RESPIN_NODE_STATUS.LOCK then
        respinNode:changeDownStatus(true)
        local symbolNode = respinNode:getBaseShowSymbol()
        if symbolNode then
            local pos = util_convertToNodeSpace(symbolNode,self)
            local zOrder = self.m_machine:getBounsScatterDataZorder(symbolNode.p_symbolType)
            zOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * self.m_machineRow * 2
            util_changeNodeParent(self,symbolNode,zOrder)
            symbolNode:setPosition(pos)
            respinNode:setLockSymbolNode(symbolNode)
            self.m_lockNodes[tostring(posIndex)] = respinNode
        end
    else --普通状态,小块放回滚轴
        respinNode:putLockSymbolBack()
    end

    respinNode:setRespinNodeStatus(status)
end

--[[
    数据检测
]]
function AquaQuestRespinView:checkBigInfos(shapeList)
    for key,info in pairs(self.m_bigLockNodes) do
        local posIndex = tonumber(key)
        local isHave = false
        for index = 1,#shapeList do
            if posIndex == shapeList[index].position then
                isHave = true
            end
        end

        if not isHave then
            self.m_bigLockNodes[key] = nil
        end
    end
end

--[[
    变更为大信号
]]
function AquaQuestRespinView:changeToBigSymbol(data)
    local aniTime = 0
    local icons = data.icons
    local position = data.position
    local isSwitch = false

    local posData = self.m_parentView:getRowAndColByPos(position)
    local iCol,iRow = posData.iY,posData.iX
    local respinNode = self:getRespinNodeByRowAndCol(iCol,iRow)

    local preShapeData
    --检测本地是否已存在对应位置的大信号块数据,如已存在相同数据则直接返回
    if self.m_bigLockNodes[tostring(position)] then
        preShapeData = self.m_bigLockNodes[tostring(position)].shapeData
        if preShapeData.newshape == data.newshape then
            return aniTime,isSwitch
        end
    end
    
    if not tolua.isnull(respinNode) then
        --存储本地大信号块数据
        self.m_bigLockNodes[tostring(position)] = {
            respinNode = respinNode,
            shapeData = data
        }

        local symbolNode = respinNode:getLockSymbolNode()
        if not tolua.isnull(symbolNode) then
            --由于合图后,金币挂点发生变化,所以需要先移除老的金币label,再创建新的
            self.m_parentView:removeBindNodeOnSymbol(symbolNode)
            if symbolNode.p_symbolType ~= self.m_machine.SYMBOL_FIX_SYMBOL_1 then
                --合图的起点位置如果不是bonus图标,则需将该图标先变为bonus图标
                self.m_machine:changeSymbolType(symbolNode,self.m_machine.SYMBOL_FIX_SYMBOL_1,true)
            elseif (data.newshape == "1x1" and ((preShapeData and preShapeData.newshape == data.newshape) or not preShapeData)) then
                --已经存在的1x1图标和刚刚落地的1x1图标不需要播合图动效,只有当一个大图标拆分成多个小图标是才需要播合图动效
                return aniTime,isSwitch
            end
            isSwitch = true
            --播放合图动效
            aniTime = self:runSwitchAni(symbolNode,data)
        end
    end

    return aniTime,isSwitch
end

--[[
    转化动画
]]
function AquaQuestRespinView:runSwitchAni(symbolNode,data)
    local icons = data.icons
    local position = data.position
    local aniTime = 0
    if not tolua.isnull(symbolNode) then
        local pos = util_convertToNodeSpace(symbolNode,self)
        local zOrder = self.m_machine:getBounsScatterDataZorder(symbolNode.p_symbolType)

        --创建一个临时图标动画覆盖在上面,待切换完成后再移除
        local spine = util_spineCreate("Socre_AquaQuest_Bonus",true,true)
        self:addChild(spine,zOrder * 2)
        spine:setPosition(cc.p(symbolNode:getPosition()))
        local aniName = "switch"..data.height.."_"..data.width

        --绑定节点
        if data.width >= 2 and data.height >= 2 then
            local csbName,bindNode = self.m_parentView:getBindNodeInfo(data)
            local csbNode = util_createAnimation(csbName)
            util_spinePushBindNode(spine,bindNode,csbNode)
            local Node_coins = csbNode:findChild("Node_coins")
            if not tolua.isnull(Node_coins) then
                Node_coins:setVisible(false)
            end

            local Node_wenben = csbNode:findChild("Node_wenben")
            if not tolua.isnull(Node_wenben) then
                Node_wenben:setVisible(true)
            end
        end
        
        ----------------------------------------------

        local idleName = "idleframe"..data.height.."_"..data.width
        util_spinePlay(spine,aniName)
        util_spineEndCallFunc(spine,aniName,function()
            
            if not tolua.isnull(symbolNode) then
                symbolNode:runAnim(idleName,true)
                --重置小块层级
                zOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * self.m_machineRow * 2
                symbolNode:setLocalZOrder(zOrder)
            end
            
            
            if not tolua.isnull(spine) then
                util_spinePlay(spine,idleName,true)

                --不能先隐藏再延迟移除,会跳帧,具体原因不明
                -- spine:setVisible(false)
                performWithDelay(spine,function()
                    if not tolua.isnull(spine) then
                        spine:removeFromParent()
                    end
                end,0.1)
            end
        end)

        aniTime = spine:getAnimationDurationTime(aniName)

        self.m_machine:delayCallBack(10 / 30,function()
            --显示可获得的jackpot提示
            if data.width >= 2 and data.height >= 2 then
                local lbl_csb = self.m_parentView:setCoinsShowOnSymbol(symbolNode,0,data)
                if not tolua.isnull(lbl_csb:findChild("Node_coins")) then
                    lbl_csb:findChild("Node_coins"):setVisible(false)
                end

                if not tolua.isnull(lbl_csb:findChild("Node_wenben")) then
                    lbl_csb:findChild("Node_wenben"):setVisible(true)
                end
            end


            if not tolua.isnull(symbolNode) then
                symbolNode:runAnim(idleName,true)

                zOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * self.m_machineRow * 2
                symbolNode:setLocalZOrder(zOrder)
            end
            
            --变更大信号图标下面覆盖的小块为空信号
            self:changeUnderSymbol(icons,position)
        end)
        
    end

    return aniTime
end

--[[
    合图后将下面的小块变为空信号
]]
function AquaQuestRespinView:changeUnderSymbol(icons,position)
    for index = 1,#icons do
        local posIndex = icons[index]
        if posIndex ~= position then
            local posData = self.m_parentView:getRowAndColByPos(posIndex)
            local iCol,iRow = posData.iY,posData.iX
            local respinNode = self:getRespinNodeByRowAndCol(iCol,iRow)
            if not tolua.isnull(respinNode) then

                local symbolNode = respinNode:getLockSymbolNode()
                if not tolua.isnull(symbolNode) and symbolNode.p_symbolType ~= self.m_machine.SYMBOL_FIX_SYMBOL_EMPTY then
                    self.m_machine:changeSymbolType(symbolNode,self.m_machine.SYMBOL_FIX_SYMBOL_EMPTY,true)
                    symbolNode:setLocalZOrder(100)
                end
            end
        end
    end
end

--[[
    结算触发动画
]]
function AquaQuestRespinView:runEndTriggerAni()

    local delayTime = 0
    
    for key,lockInfo in pairs(self.m_bigLockNodes) do
        local respinNode = lockInfo.respinNode
        local shapeData = lockInfo.shapeData
        if not tolua.isnull(respinNode) then
            local symbolNode = respinNode:getLockSymbolNode()
            if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == self.m_machine.SYMBOL_FIX_SYMBOL_1 then
                local aniName = "actionframe"..shapeData.height.."_"..shapeData.width
                symbolNode:runAnim(aniName,false,function()
                    local idleName = "idleframe"..shapeData.height.."_"..shapeData.width
                    symbolNode:runAnim(idleName,true)
                end)

                local aniTime = symbolNode:getAniamDurationByName(aniName)
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end
    end

    return delayTime
end

--[[
    开始滚动前重置数据
]]
function AquaQuestRespinView:resetDataBeforeMove()
    AquaQuestRespinView.super.resetDataBeforeMove(self)
    self.m_isReelDown = false
end


function AquaQuestRespinView:setMachine(machine,parentView,machineIndex)
    self.m_machine = machine
    self.m_parentView = parentView
    self.m_machineIndex = machineIndex
end

--[[
    单格停止回调
]]
function AquaQuestRespinView:respinNodeEndCallBack(respinNode)
    if self.m_isReelDown then
        return
    end
    local symbolNode = respinNode:getBaseShowSymbol()
    if symbolNode and symbolNode.p_symbolType then
        local info = self:getEndTypeInfo(symbolNode.p_symbolType)
        --小块提层
        if info then
            self:changeRespinNodeStatus(respinNode,RESPIN_NODE_STATUS.LOCK)
            self:checkPlaySymbolDownSound(symbolNode.p_symbolType,respinNode.m_colIndex,symbolNode)
        end
        self:runNodeEnd(symbolNode,info)
        
    end

    --检测单列停止
    if self:checkOneReelDown(respinNode.m_colIndex) then
        self:slotOneReelDown(respinNode.m_colIndex)
    end

    --滚动停止
    if self:checkIsAllDown() then
        self.m_isReelDown = true
        if self.m_parentView then
            self.m_parentView:reSpinReelDown()
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
        end
    end
end

--[[
    单格停止
]]
function AquaQuestRespinView:runNodeEnd(symbolNode,info)
    if tolua.isnull(symbolNode) then
        return
    end
    if info and info.runEndAnimaName ~= nil and info.runEndAnimaName ~= "" then
        if not self.m_isBonusDown and self.m_machine then
            self.m_isBonusDown= true
            self:changeRespinCount()
        end
        
        symbolNode:runAnim(info.runEndAnimaName, false,function()
            symbolNode:runAnim(info.idleAniName,true)
        end)
    end
end

--[[
    获取结算节点
]]
function AquaQuestRespinView:getAllCleaningNode(data)
    local lines = data.lines
    local list = {}
    for key,info in pairs(self.m_bigLockNodes) do
        local posIndex = tonumber(key)
        for index = 1,#lines do
            local lineData = lines[index]
            local icons = lineData.icons
            if self:checkPosInLines(posIndex,icons) then
                list[#list + 1] = {
                    respinNode = info.respinNode,
                    shapeData = info.shapeData,
                    lineData = lineData,
                    posIndex = posIndex,
                    machineIndex = self.m_machineIndex
                }
                break
            end
        end
    end

    return list
end

--[[
    检测点位是否在连线内
]]
function AquaQuestRespinView:checkPosInLines(posIndex,icons)
    for index = 1,#icons do
        if posIndex == icons[index] then
            return true
        end
    end

    return false
end

--[[
    检测播放图标落地音效
]]
function AquaQuestRespinView:checkPlaySymbolDownSound(symbolType,colIndex,symbolNode)
    self.m_parentView:checkPlaySymbolDownSound(symbolType,colIndex,symbolNode)
end


return AquaQuestRespinView