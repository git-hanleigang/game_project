---
--xcyy
--2018年5月23日
--SpacePupReBadgedCowboyRespinViewspinView.lua

local PublicConfig = require "BadgedCowboyPublicConfig"
local BadgedCowboyRespinView = class("BadgedCowboyRespinView",util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

local TAG_LIGHT = 1001
local TAG_LIGHT_SINGLE = 1002

local LIGHT_SCALE = 1.3
local TOP_ZORDER = 10000
-- 

function BadgedCowboyRespinView:initUI(respinNodeName)
    self.m_respinNodeName = respinNodeName 
    self.m_baseRunNum = BASE_RUN_NUM

    self.quickRespinNodeTbl = {}
    self.quickRespinZorderTbl = {}
    self.quickRespinIndex = 1
    self.m_reelRespinRunSoundTag = {}
end

function BadgedCowboyRespinView:createRespinNode(symbolNode, status)

    local respinNode = util_createView(self.m_respinNodeName)
    respinNode:setMachine(self.m_machine)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
    
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
    
    respinNode:initClipNode(nil,130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--[[
      添加光效框 单个小块
]]
function BadgedCowboyRespinView:addRespinLightEffectSingle()
    local reels = self.m_machine.m_runSpinResultData.p_reels
    local last_index = -1
    local isPlaySound = true
    for rowIndex=1,self.m_machine.m_iReelRowNum do
        local bonus_count = 0
        for curColIndex=1,self.m_machine.m_iReelColumnNum do
            if self.m_machine:getCurSymbolIsBonus(reels[rowIndex][curColIndex]) then --判断是否为bonus图标
                bonus_count = bonus_count + 1
            else
                last_index = rowIndex
            end
        end

        local curRowIndex = self.m_machine.m_iReelRowNum - rowIndex + 1
        if bonus_count == self.m_machine.m_iReelColumnNum then
            self.m_machine.m_respinNodeSingle[curRowIndex]:removeAllChildren(true)
            self.m_machine.m_respinNodeLight[curRowIndex]:removeAllChildren(true)
        end
        
        if bonus_count == 5 and last_index ~= -1 then
            for key,endNode in pairs(self.m_respinNodes) do
                if endNode.m_lastNode and endNode.m_lastNode.p_rowIndex == curRowIndex and not self.m_machine:getCurSymbolIsBonus(endNode.m_lastNode.p_symbolType)
                and not self.m_machine.m_respinNodeSingle[curRowIndex]:getChildByTag(TAG_LIGHT_SINGLE) then
                    if isPlaySound then
                        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Frame_Appear)
                        isPlaySound = false
                    end
                    local light_effect = util_createAnimation("BadgedCowboy_tishi.csb")
                    light_effect:runCsbAction("start", false, function()
                        light_effect:runCsbAction("idle", true)
                    end)
                    
                    local m_zorder = endNode.m_lastNode.p_cloumnIndex * 50 - curRowIndex
                    self.m_machine.m_respinNodeSingle[curRowIndex]:removeAllChildren(true)
                    self.m_machine.m_respinNodeSingle[curRowIndex]:addChild(light_effect, m_zorder)
                    light_effect:setTag(TAG_LIGHT_SINGLE)
                    light_effect:setPosition(util_convertToNodeSpace(endNode.m_lastNode,self.m_machine.m_respinNodeSingle[curRowIndex]))
                    break
                end
            end
        end
    end
end

--[[
    添加respin光效框 整行
]]
function BadgedCowboyRespinView:addRespinLightEffect()
    -- 
    for rowIndex=1,self.m_machine.m_iReelRowNum do
        local reels = self.m_machine.m_runSpinResultData.p_reels
        --转换本地行数
        local curRow = 4-rowIndex+1
        local bonus_count = self:getBonusCount(rowIndex)
        local reelNode = self.m_machine:findChild("Node_jackpot_" .. curRow)
        if bonus_count == 5 and not self.m_machine.m_respinNodeLight[curRow]:getChildByTag(TAG_LIGHT) then
            self.m_machine.m_respinNodeLight[curRow]:removeAllChildren(true)
            local light_effect = util_createAnimation("BadgedCowboy_daijiman_sg.csb")
            light_effect:runCsbAction("idle", true)

            self.m_machine.m_respinNodeLight[curRow]:addChild(light_effect)
            light_effect:setTag(TAG_LIGHT)
            light_effect:setPosition(util_convertToNodeSpace(reelNode,self.m_machine.m_respinNodeLight[curRow]))
        end
    end
end

--[[
      结算光效
]]
function BadgedCowboyRespinView:cleanEffect(rowIndex,callBack)
    local light_effect = self.m_machine.m_respinNodeSingle[rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
    local light_effect_row = self.m_machine.m_respinNodeLight[rowIndex]:getChildByTag(TAG_LIGHT)
    if light_effect_row then
        self.m_machine.m_respinNodeLight[rowIndex]:removeAllChildren(true)
    end
    if light_effect then
        light_effect:runCsbAction("over", false, function()
            self.m_machine.m_respinNodeSingle[rowIndex]:removeAllChildren(true)
            if type(callBack) == "function" then
                callBack()
            end
        end)
    else
        self.m_machine.m_respinNodeSingle[rowIndex]:removeAllChildren(true)
        if type(callBack) == "function" then
            callBack()
        end
    end
end

--组织滚动信息 开始滚动
function BadgedCowboyRespinView:startMove()
    self.isQuickRun = false
    --添加光效
    self:addRespinLightEffectSingle()
    self:addRespinLightEffect()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    for i=1,#self.m_respinNodes do
          if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                self.m_respinNodes[i]:startMove()
                local repsinNode = self.m_respinNodes[i]
                local respinCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
                --设置快滚
                local light_effect = self.m_machine.m_respinNodeSingle[repsinNode.p_rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
                if respinCount and respinCount == 1 and light_effect and self.m_machine:judgeCurIsLastJackpot() then
                    light_effect:runAction(self:getScaleBigAni())
                    repsinNode:runAction(self:getScaleBigAni())
                    repsinNode:setLocalZOrder(TOP_ZORDER)
                    repsinNode:changeRunSpeed(true)
                end
          end
    end
end

function BadgedCowboyRespinView:quicklyStop()
    BadgedCowboyRespinView.super.quicklyStop(self)
    if self.quickRespinIndex <= #self.quickRespinNodeTbl then
        for i=1, #self.quickRespinNodeTbl do
            local respinNode = self.quickRespinNodeTbl[i]
            local lightEffect = self.m_machine.m_respinNodeSingle[respinNode.p_rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
            if not tolua.isnull(respinNode) then
                respinNode:setScale(1.0)
                local nodeZorder = self.quickRespinZorderTbl[i] or 0
                respinNode:setLocalZOrder(nodeZorder)
            end
            if not tolua.isnull(lightEffect) then
                lightEffect:setScale(1.0)
            end

            --快滚音效
            local colSoundTag = self.m_reelRespinRunSoundTag[i]
            if colSoundTag then
                gLobalSoundManager:stopAudio(colSoundTag)
                self.m_reelRespinRunSoundTag[i] = nil
            end
        end
        self.quickRespinIndex = #self.quickRespinNodeTbl + 1
        self.m_reelRespinRunSoundTag = {}
    end
    self.isQuickRun = true
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Reel_QuickStop_Sound)
end

function BadgedCowboyRespinView:oneReelDown(_Col)
    self.curColPlaySound = _Col
    if not self.isQuickRun then
        self.m_machine:slotLocalOneReelDown(_Col)
    end
end

function BadgedCowboyRespinView:runNodeEnd(endNode)
    if self.m_machine:getCurSymbolIsBonus(endNode.p_symbolType) then
        endNode:runAnim("buling", false, function()
            endNode:runAnim("idleframe1", true)
        end)
        if self.curColPlaySound then
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Bonus_Buling)
            self.curColPlaySound = nil
        end
    end

    --设置下一个快滚
    if self.quickRespinIndex <= #self.quickRespinNodeTbl then
        local lastRespinNode = self.quickRespinNodeTbl[self.quickRespinIndex]
        if lastRespinNode and endNode.p_rowIndex == lastRespinNode.p_rowIndex and endNode.p_cloumnIndex == lastRespinNode.p_colIndex then
            local last_lightEffect = self.m_machine.m_respinNodeSingle[lastRespinNode.p_rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
            last_lightEffect:runAction(self:getScaleSmallAni())
            lastRespinNode:runAction(self:getScaleSmallAni())
            local nodeZorder = self.quickRespinZorderTbl[self.quickRespinIndex] or 0
            lastRespinNode:setLocalZOrder(nodeZorder)
            local colSoundTag = self.m_reelRespinRunSoundTag[self.quickRespinIndex]
            if colSoundTag then
                gLobalSoundManager:stopAudio(colSoundTag)
                self.m_reelRespinRunSoundTag[self.quickRespinIndex] = nil
            end
            if self.quickRespinIndex < #self.quickRespinNodeTbl then
                self.quickRespinIndex = self.quickRespinIndex + 1
                local repsinNode = self.quickRespinNodeTbl[self.quickRespinIndex]
                local lightEffect = self.m_machine.m_respinNodeSingle[repsinNode.p_rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
                if repsinNode then
                    lightEffect:runAction(self:getScaleBigAni())
                    repsinNode:runAction(self:getScaleBigAni())
                    repsinNode:setLocalZOrder(TOP_ZORDER)
                    repsinNode:changeRunSpeed(true)
                    repsinNode:changeResDis(true)
                    self.m_reelRespinRunSoundTag[self.quickRespinIndex] = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Respin_QuickRun)
                end
            end
        end
    end

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
        self:addRespinLightEffectSingle()
        self:addRespinLightEffect()
    end
end

function BadgedCowboyRespinView:getRespinRunLong(_colIndex)
    local oneRunLong = self.m_baseRunNum + (_colIndex - 1) * BASE_COL_INTERVAL
    return oneRunLong
end

function BadgedCowboyRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    --判断是否有快滚
    local curSpinIsQucikRun = false
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        if self.m_machine.m_runSpinResultData.p_reSpinCurCount then
            local respinCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
            --设置快滚
            local light_effect = self.m_machine.m_respinNodeSingle[repsinNode.p_rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
            if respinCount and respinCount == 0 and light_effect and repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and self.m_machine:curRewardMini() then
                curSpinIsQucikRun = true
                break
            end
        end
    end

    local quickIndex = 0
    self.quickRespinNodeTbl = {}
    self.quickRespinIndex = 1
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false
        local oneRunLong = self:getRespinRunLong(repsinNode.p_colIndex)
        local runLong = oneRunLong
        if curSpinIsQucikRun then
            runLong = oneRunLong*2
        end
        if self.m_machine.m_runSpinResultData.p_reSpinCurCount then
            --需要快滚的列
            local respinCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
            --设置快滚
            local light_effect = self.m_machine.m_respinNodeSingle[repsinNode.p_rowIndex]:getChildByTag(TAG_LIGHT_SINGLE)
            if respinCount and respinCount == 0 and light_effect and repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and self.m_machine:curRewardMini() then
                quickIndex = quickIndex + 1
                -- runLong = quickIndex * runLong
                runLong = runLong*2
                local zorder = repsinNode:getLocalZOrder()
                if zorder ~= TOP_ZORDER then
                    self.quickRespinZorderTbl[#self.quickRespinZorderTbl+1] = zorder
                end
                if #self.quickRespinNodeTbl < 1 then
                    light_effect:runAction(self:getScaleBigAni())
                    repsinNode:runAction(self:getScaleBigAni())
                    repsinNode:setLocalZOrder(TOP_ZORDER)
                    repsinNode:changeRunSpeed(true)
                    repsinNode:changeResDis(true)
                    self.m_reelRespinRunSoundTag[1] = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Respin_QuickRun)
                end
                self.quickRespinNodeTbl[#self.quickRespinNodeTbl+1] = repsinNode
            end
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
          
        --分三种情况，快滚最多三个格子(在中mini之后才会出现)
        local quickNodeCount = #self.quickRespinNodeTbl
        for i=1,#unStoredReels do
            local data = unStoredReels[i]
            if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                if #self.quickRespinNodeTbl == 1 then
                    --先处理快滚
                    local isSetState = false
                    local m_colIndex = self.quickRespinNodeTbl[1].p_colIndex
                    local m_curRow = self.quickRespinNodeTbl[1].p_rowIndex
                    if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                        repsinNode:setRunInfo(runLong, data.type)
                        isSetState = true
                        break
                    end
                    if not isSetState then
                        if repsinNode.p_colIndex > m_colIndex then
                            repsinNode:setRunInfo(runLong, data.type)
                            -- repsinNode:setRunInfo(runLong+30, data.type)
                        else
                            repsinNode:setRunInfo(runLong, data.type)
                            -- repsinNode:setRunInfo(runLong+14, data.type)
                        end
                    end
                elseif #self.quickRespinNodeTbl == 2 then
                    --分两种情况（在一列和不在一列）
                    if self.quickRespinNodeTbl[1].p_colIndex == self.quickRespinNodeTbl[2].p_colIndex then
                        --先处理快滚
                        local isSetState = false
                        local m_colIndex = self.quickRespinNodeTbl[2].p_colIndex
                        local m_curRow = self.quickRespinNodeTbl[2].p_rowIndex
                        if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                            repsinNode:setRunInfo(runLong+oneRunLong, data.type)
                            isSetState = true
                            break
                        end
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+oneRunLong*2, data.type)
                            else
                                repsinNode:setRunInfo(runLong+oneRunLong*2, data.type)
                            end
                        end
                    else
                        --先处理快滚
                        local isSetState = false
                        local m_colIndex = self.quickRespinNodeTbl[2].p_colIndex
                        local m_curRow = self.quickRespinNodeTbl[2].p_rowIndex
                        if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                            repsinNode:setRunInfo(runLong, data.type)
                            isSetState = true
                            break
                        end
                        --第一列快滚之后的要加上快滚列的长度
                        local lastRunLong = self:getRespinRunLong(self.quickRespinNodeTbl[2].p_colIndex)
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+lastRunLong, data.type)
                            else
                                repsinNode:setRunInfo(runLong+lastRunLong, data.type)
                            end
                        end
                    end
                elseif #self.quickRespinNodeTbl == 3 then
                    --分三种情况（都在一列）
                    if self.quickRespinNodeTbl[1].p_colIndex == self.quickRespinNodeTbl[2].p_colIndex and self.quickRespinNodeTbl[1].p_colIndex == self.quickRespinNodeTbl[3].p_colIndex then
                        --先处理快滚
                        local isSetState = false
                        local m_colIndex = self.quickRespinNodeTbl[3].p_colIndex
                        local m_curRow = self.quickRespinNodeTbl[3].p_rowIndex
                        if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                            repsinNode:setRunInfo(runLong+oneRunLong*2, data.type)
                            isSetState = true
                            break
                        end
                        local lastRunLong = self:getRespinRunLong(self.quickRespinNodeTbl[3].p_colIndex)
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+lastRunLong*3, data.type)
                            else
                                repsinNode:setRunInfo(runLong+lastRunLong*3, data.type)
                            end
                        end
                    --都不在一列
                    elseif self.quickRespinNodeTbl[1].p_colIndex ~= self.quickRespinNodeTbl[2].p_colIndex and self.quickRespinNodeTbl[1].p_colIndex ~= self.quickRespinNodeTbl[3].p_colIndex
                        and self.quickRespinNodeTbl[2].p_colIndex ~= self.quickRespinNodeTbl[3].p_colIndex then
                        --先处理快滚
                        local isSetState = false
                        local m_colIndex = self.quickRespinNodeTbl[3].p_colIndex
                        local m_curRow = self.quickRespinNodeTbl[3].p_rowIndex
                        if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                            repsinNode:setRunInfo(runLong+oneRunLong, data.type)
                            isSetState = true
                            break
                        end
                        local lastRunLong_1 = self:getRespinRunLong(self.quickRespinNodeTbl[2].p_colIndex)
                        local lastRunLong_2 = self:getRespinRunLong(self.quickRespinNodeTbl[3].p_colIndex)
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+oneRunLong+lastRunLong_1+lastRunLong_2, data.type)
                            else
                                repsinNode:setRunInfo(runLong+lastRunLong_1+lastRunLong_2, data.type)
                            end
                        end
                    --前两个在一列
                    elseif self.quickRespinNodeTbl[1].p_colIndex == self.quickRespinNodeTbl[2].p_colIndex and self.quickRespinNodeTbl[1].p_colIndex ~= self.quickRespinNodeTbl[3].p_colIndex then
                        --先处理快滚
                        local isSetState = false
                        local m_colIndex = self.quickRespinNodeTbl[3].p_colIndex
                        local m_curRow = self.quickRespinNodeTbl[3].p_rowIndex
                        if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                            repsinNode:setRunInfo(runLong+oneRunLong, data.type)
                            isSetState = true
                            break
                        end
                        local lastRunLong_1 = self:getRespinRunLong(self.quickRespinNodeTbl[2].p_colIndex)
                        local lastRunLong_2 = self:getRespinRunLong(self.quickRespinNodeTbl[3].p_colIndex)
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+oneRunLong+lastRunLong_2, data.type)
                            else
                                repsinNode:setRunInfo(runLong+lastRunLong_1+lastRunLong_2, data.type)
                            end
                        end
                    --后两个在一列
                    elseif self.quickRespinNodeTbl[2].p_colIndex == self.quickRespinNodeTbl[3].p_colIndex and self.quickRespinNodeTbl[2].p_colIndex ~= self.quickRespinNodeTbl[1].p_colIndex then
                        --先处理快滚
                        local isSetState = false
                        local m_colIndex = self.quickRespinNodeTbl[3].p_colIndex
                        local m_curRow = self.quickRespinNodeTbl[3].p_rowIndex
                        local lastRunLong_1 = self:getRespinRunLong(self.quickRespinNodeTbl[1].p_colIndex)
                        local lastRunLong_2 = self:getRespinRunLong(self.quickRespinNodeTbl[3].p_colIndex)
                        if m_colIndex == repsinNode.p_colIndex and m_curRow == repsinNode.p_rowIndex then
                            repsinNode:setRunInfo(runLong+oneRunLong+lastRunLong_1, data.type)
                            isSetState = true
                            break
                        end
                        local lastRunLong_1 = self:getRespinRunLong(self.quickRespinNodeTbl[2].p_colIndex)
                        local lastRunLong_2 = self:getRespinRunLong(self.quickRespinNodeTbl[3].p_colIndex)
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+oneRunLong+lastRunLong_2, data.type)
                            else
                                repsinNode:setRunInfo(runLong+lastRunLong_2+lastRunLong_2, data.type)
                            end
                        end
                    end
                else
                    repsinNode:setRunInfo(runLong, data.type)
                end
            end
        end
    end
end

function BadgedCowboyRespinView:getScaleBigAni()
    local scaleAct = cc.ScaleTo:create(10/60, LIGHT_SCALE)
    return scaleAct
end

function BadgedCowboyRespinView:getScaleSmallAni()
    local scaleAct = cc.ScaleTo:create(10/60, 1.0)
    return scaleAct
end

--[[
      获取该列Link图标数量
]]
function BadgedCowboyRespinView:getBonusCount(rowIndex)
    local reels = self.m_machine.m_runSpinResultData.p_reels
    local bonus_count = 0
    local last_index = -1
    for colIndex=1,self.m_machine.m_iReelColumnNum do
        if self.m_machine:getCurSymbolIsBonus(reels[rowIndex][colIndex]) then --判断是否为bonus图标
            bonus_count = bonus_count + 1
        else
            last_index = colIndex
        end
    end
    return bonus_count
end

--选填配置configParams
--     configParams["clipOffsetSize"]     --裁切修正大小 默认cc.size(0,0)
--     configParams["clipType"]           --裁切类型 1.单个、2.合并行 默认1
--     configParams["clipMode"]           --裁切方式 1.矩形、2.模板 默认1
--     configParams["clipPos"]            --初始坐标 默认cc.p(-clipSize.width*0.5,-clipSize.height*0.5)
--     configParams["clipOffsetPos"]      --初始坐标 默认cc.p(0,0)
--初始化裁切节点
function BadgedCowboyRespinView:initClipNodes(machineElement,clipType,configParams)
    BadgedCowboyRespinView.super.initClipNodes(self,machineElement,RESPIN_CLIPTYPE.SINGLE,configParams)
end

return BadgedCowboyRespinView
