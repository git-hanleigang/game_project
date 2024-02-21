---
--xcyy
--2018年5月23日
--MagicianRespinView.lua
local RespinView = util_require("Levels.RespinView")
local MagicianRespinView = class("MagicianRespinView",RespinView)

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

local BASE_COL_INTERVAL = 3

function MagicianRespinView:initUI(respinNodeName)
    self.m_jackpot_sound = {}
    self.m_bonus_sound = {}
    self.m_jackpot_nodes = {}
    MagicianRespinView.super.initUI(self,respinNodeName)
end

function MagicianRespinView:createRespinNode(symbolNode, status)

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
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        respinNode.m_baseFirstNode = symbolNode
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    respinNode.m_baseFirstNode.m_curAni = ""
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
    
end

--组织滚动信息 开始滚动
function MagicianRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    self.m_jackpot_sound = {}
    self.m_bonus_sound = {}
    self.m_jackpot_nodes = {}

    for i=1,#self.m_respinNodes do

        --乘倍图标和宝箱图标解除锁定
        if self.m_respinNodes[i].m_baseFirstNode.p_symbolType == self.m_machine.SYMBOL_MULTIPLE then
            --解除锁定状态
            self.m_respinNodes[i]:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            --把图标放回去
            self.m_respinNodes[i]:setFirstSlotNode(self.m_respinNodes[i].m_baseFirstNode)
        end

        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
        end
    end
end

--[[
    刷新bonus分值
]]
function MagicianRespinView:refreshBonusScore()
    for i=1,#self.m_respinNodes do

        if self.m_respinNodes[i]:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            local symbol = self.m_respinNodes[i].m_baseFirstNode
            if symbol.p_symbolType == self.m_machine.SYMBOL_BONUS then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                local bonusStoreData = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusStoreData
                local id = self.m_machine:getPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex)
                local multiple = bonusStoreData[tostring(id)] or 1
                local score = multiple * lineBet

                symbol.m_score = score
                local lbl_score = symbol:getCcbProperty("m_lb_coins")
                if lbl_score then
                    --格式化字符串
                    score = util_formatCoins(score, 3)
                    lbl_score:setString(score)
                    self.m_machine:updateLabelSize({label = lbl_score,sx = 0.5,sy = 0.5},297)
                    
                end
            end
        end
    end
end

--[[
    中jackpot后idle
]]
function MagicianRespinView:hitJackpotIdle(symbolType)
    for k,node in pairs(self.m_respinNodes) do
        if node.m_baseFirstNode and node.m_baseFirstNode.p_symbolType == symbolType then
            if not node.m_baseFirstNode.m_curAni or node.m_baseFirstNode.m_curAni ~= "idleframe3" then
                node.m_baseFirstNode:runAnim("idleframe3",true)
            end
            
            node.m_baseFirstNode.m_curAni = "idleframe3"
        end

        local img = node.m_baseFirstNode:getCcbProperty("Score_img_0")
        if node.m_baseFirstNode.isHitSymbol then
            if img then
                img:setVisible(true)
            end
        else
            if img then
                img:setVisible(false)
            end
        end
        
    end
end

--[[
    即将中jackpot动效
]]
function MagicianRespinView:hitJackpotLeftCount(symbolType,leftCount)
    
    if leftCount <= 1 then
        for k,node in pairs(self.m_respinNodes) do
            if not node.m_baseFirstNode.m_curAni or node.m_baseFirstNode.m_curAni ~= "idleframe3" then
                if node.m_baseFirstNode and node.m_baseFirstNode.p_symbolType == symbolType then
                    node.m_baseFirstNode:runAnim("idleframe3",true)
                    node.m_baseFirstNode.m_curAni = "idleframe3"
                end
                
            end 
        end

        
    else
        for k,node in pairs(self.m_respinNodes) do
            if not node.m_baseFirstNode.m_curAni or node.m_baseFirstNode.m_curAni ~= "idleframe2" then
                if node.m_baseFirstNode and node.m_baseFirstNode.p_symbolType == symbolType then
                    node.m_baseFirstNode:runAnim("idleframe2",true)
                    node.m_baseFirstNode.m_curAni = "idleframe2"
                end
                
            end
        end
    end
end

function MagicianRespinView:runNodeEnd(endNode)
    local jackpotTypes = {
        [self.m_machine.SYMBOL_MINI] = 1,
        [self.m_machine.SYMBOL_MINOR] = 2,
        [self.m_machine.SYMBOL_MAJOR] = 3,
        [self.m_machine.SYMBOL_GRAND] = 5,
    }
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        if endNode.p_symbolType >= self.m_machine.SYMBOL_GRAND and  endNode.p_symbolType <= self.m_machine.SYMBOL_MINI then
            self.m_jackpot_nodes[#self.m_jackpot_nodes + 1] = endNode

            if not self.m_jackpot_sound[endNode.p_cloumnIndex] then
                self.m_jackpot_sound[endNode.p_cloumnIndex] = true
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_respin_jackpot_down_tip.mp3")
            end
            

            --快停落地音效处理
            if self.m_machine:getGameSpinStage() == QUICK_RUN then
                for iCol = 1,self.m_machine.m_iReelColumnNum do
                    self.m_jackpot_sound[iCol] = true
                end
            end
            
            local count = self:getJackpotSymbolCountBySymbolIndex(endNode)
            --中jackpot所需
            local needCount = jackpotTypes[endNode.p_symbolType]
            endNode.m_curAni = nil
            if count >= needCount then
                endNode:runAnim("buling2",false,function()
                    endNode:runAnim("idleframe3",true)
                end)
                endNode:getCcbProperty("Score_img_0"):setVisible(true)
                endNode.m_curAni = "idleframe3"
                endNode.isHitSymbol = true
            elseif count == needCount - 1 then
                endNode:runAnim("buling",false,function()
                    endNode:runAnim("idleframe3",true)
                end)
                endNode.m_curAni = "idleframe3"
                endNode:getCcbProperty("Score_img_0"):setVisible(false)
            else
                endNode:runAnim("buling",false,function()
                    endNode:runAnim("idleframe2",true)
                end)
                endNode.m_curAni = "idleframe2"
                endNode:getCcbProperty("Score_img_0"):setVisible(false)
            end
        else
            endNode:runAnim(info.runEndAnimaName, false)
            if endNode.p_symbolType == self.m_machine.SYMBOL_TREASURE then
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_box_down_tip.mp3")
            else
                if not self.m_bonus_sound[endNode.p_cloumnIndex] then
                    self.m_bonus_sound[endNode.p_cloumnIndex] = true
                    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_down_tip.mp3")
                end
    
                --快停落地音效处理
                if self.m_machine:getGameSpinStage() == QUICK_RUN then
                    for iCol = 1,self.m_machine.m_iReelColumnNum do
                        self.m_bonus_sound[iCol] = true
                    end
                end
            end
        end 
    end

    --全部都停下
    if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
        self:refreshBonusScore()
        self.m_machine:delayCallBack(30 / 60,function ()
            self:checkJackpotInReels()
            self.m_machine:checkJackpot()
        end)
        
    end
end

function MagicianRespinView:oneReelDown(colIndex)
    self.m_machine:playReelDownSound(colIndex, self.m_machine.m_reelDownSound)
end

--[[
    根据位置获取当前jackpot数量
]]
function MagicianRespinView:getJackpotSymbolCountBySymbolIndex(symbol,respinNode)
    local symbolType = symbol.p_symbolType
    local colIndex = symbol.p_cloumnIndex
    local rowIndex = symbol.p_rowIndex
    if rowIndex == 1 then
        rowIndex = 3
    elseif rowIndex == 3 then
        rowIndex = 1
    end

    local reels = self.m_machine.m_runSpinResultData.p_reels
    --这个是统计位置在前面的所有小块
    local count = 0
    for iCol = 1,colIndex do
        local maxRow = (iCol == colIndex) and rowIndex or self.m_machine.m_iReelRowNum
        for iRow = 1,maxRow do
            if symbolType == reels[iRow][iCol] then
                count = count + 1
            end
        end
    end

    --断线重连初始化用,非滚动过程中判断
    if not respinNode then
        --统计在后面的锁定小块
        local startIndex = rowIndex + (colIndex - 1) * self.m_machine.m_iReelRowNum + 1
        for index = startIndex,#self.m_respinNodes do
            local node = self.m_respinNodes[index]
            if node:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK and node.m_baseFirstNode.p_symbolType == symbolType then
                count = count + 1
            end
        end
    end
    

    return count
end

--[[
    检测当前轮盘上的jackpot
]]
function MagicianRespinView:checkJackpotInReels()
    local jackpotTypes = {
        [self.m_machine.SYMBOL_MINI] = 1,
        [self.m_machine.SYMBOL_MINOR] = 2,
        [self.m_machine.SYMBOL_MAJOR] = 3,
        [self.m_machine.SYMBOL_GRAND] = 5,
    }
    for symbolType,count in pairs(jackpotTypes) do
        local count = self:getJackpotSymbolCount(symbolType)
        local needCount = jackpotTypes[symbolType]

        if count >= needCount then
            self:hitJackpotIdle(symbolType)
        else
            self:hitJackpotLeftCount(symbolType,needCount - count)
        end
    end
end

function MagicianRespinView:initJackpotInReels()
    local jackpotTypes = {
        [self.m_machine.SYMBOL_MINI] = 1,
        [self.m_machine.SYMBOL_MINOR] = 2,
        [self.m_machine.SYMBOL_MAJOR] = 3,
        [self.m_machine.SYMBOL_GRAND] = 5,
    }

    for k,node in pairs(self.m_respinNodes) do
        local symbolNode = node.m_baseFirstNode
        symbolNode.isHitSymbol = false
        if symbolNode.p_symbolType >= self.m_machine.SYMBOL_GRAND and symbolNode.p_symbolType <= self.m_machine.SYMBOL_MINI then
            local count = self:getJackpotSymbolCountBySymbolIndex(symbolNode,node)
            --中jackpot所需
            local needCount = jackpotTypes[symbolNode.p_symbolType]
            if count >= needCount then
                symbolNode.isHitSymbol = true
            end
        end
        
    end
    
end

--[[
    获取轮盘上对应的jackpot数量
]]
function MagicianRespinView:getJackpotSymbolCount(symbolType)
    local reels = self.m_machine.m_runSpinResultData.p_reels
    local count = 0
    for iCol = 1, self.m_machine.m_iReelColumnNum do
        for iRow = 1, self.m_machine.m_iReelRowNum do
            if symbolType == reels[iRow][iCol] then
                count = count + 1
            end
        end
    end

    return count
end

function MagicianRespinView:createBoxSymbol()
    
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_TREASURE)
    local node = util_createAnimation(ccbName..".csb")
    return node
end

--[[
    轮盘满格出一个宝箱收集所有的bonus图标
]]
function MagicianRespinView:collectBonusOnFull(index,func)
    local pos = self.m_machine:getRowAndColByPos(tonumber(index))
    local iCol,iRow = pos.iY,pos.iX

    local targetNode,targetSymbol = nil,nil
    for k,node in pairs(self.m_respinNodes) do
        if node.p_colIndex == iCol and node.p_rowIndex == iRow then
            targetNode = node
            targetSymbol = node.m_baseFirstNode
            break
        end
    end

    --创建一个宝箱图标
    local box = self:createBoxSymbol()
    self.m_machine.m_effectNode:addChild(box)
    box:setPosition(util_convertToNodeSpace(targetNode,self.m_machine.m_effectNode))

    box:findChild("m_lb_coins"):setString(0)
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_show_box.mp3")
    box:runCsbAction("actionframe4")
    --bonus图标挑起动作
    targetSymbol:runAnim("actionframe2",false,function()
        box:runCsbAction("actionframe",false,function()
            box:removeFromParent()
            
        
            targetSymbol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_TREASURE), self.m_machine.SYMBOL_TREASURE)
            targetSymbol:runAnim("idleframe2")
            --设置宝箱分数
            local lbl_score = targetSymbol:getCcbProperty("m_lb_coins")
            lbl_score:setString(util_formatCoins(targetSymbol.m_score, 3))
            self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
            local pos = util_convertToNodeSpace(targetSymbol,self)
            util_changeNodeParent(self,targetSymbol,REEL_SYMBOL_ORDER.REEL_ORDER_2 - targetSymbol.p_rowIndex, self.REPIN_NODE_TAG)
            targetSymbol:setPosition(pos)
            lbl_score:setVisible(true)

            --收集图标分数
            self:collectBonusInBox(targetSymbol,function()
                --变成bonus图标
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_change_box_to_coins.mp3")
                targetSymbol:runAnim("actionframe2",false,function()
                    --图标变为bonus图标
                    targetSymbol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_BONUS), self.m_machine.SYMBOL_BONUS)
                    --设置宝箱分数
                    local lbl_score = targetSymbol:getCcbProperty("m_lb_coins")
                    lbl_score:setString(util_formatCoins(targetSymbol.m_score, 3))
                    self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
                    if type(func) == "function" then
                        func()
                    end
                end)
            end)
        end)

        local str = targetSymbol:getCcbProperty("m_lb_coins"):getString()
        box.m_score = targetSymbol.m_score
        --设置宝箱分数
        local lbl_score = box:findChild("m_lb_coins")
        local score = util_formatCoins(box.m_score, 3)
        lbl_score:setString(score)
        self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
    end)
end

--[[
    宝箱收集动画
]]
function MagicianRespinView:collectBonusWithBox(func)
    local boxNode,boxSymbol = nil,nil
    --查找宝箱图标
    for k,respinNode in pairs(self.m_respinNodes) do
        if respinNode.m_baseFirstNode.p_symbolType == self.m_machine.SYMBOL_TREASURE then
            boxSymbol = respinNode.m_baseFirstNode
            boxNode = respinNode
            break
        end
    end

    if not boxNode then
        release_print("MagicianRespin boxNode is nil")
        if type(func) == "function" then
            func()
        end
        return
    end

    --设定为锁定状态
    boxNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_open_box.mp3")
    boxSymbol:runAnim("actionframe5",false,function()
        --收集图标分数
        self:collectBonusInBox(boxSymbol,function()
            --变成bonus图标
            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_change_box_to_coins.mp3")
            boxSymbol:runAnim("actionframe2",false,function()
                --图标变为bonus图标
                boxSymbol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_BONUS), self.m_machine.SYMBOL_BONUS)
                --设置宝箱分数
                local lbl_score = boxSymbol:getCcbProperty("m_lb_coins")
                lbl_score:setString(util_formatCoins(boxSymbol.m_score, 3))
                self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
                if type(func) == "function" then
                    func()
                end
            end)
        end)
    end)
    
end

--[[
    触发时宝箱收集图标动画
]]
function MagicianRespinView:startCollectBonusOnTrigger(func)
    local midSymBol,midNode = nil, nil
    for key,respinNode in pairs(self.m_respinNodes) do
        --最中间出现宝箱图标
        if respinNode.p_colIndex == 3 and respinNode.p_rowIndex == 2 then
            midSymBol = respinNode.m_baseFirstNode
            midNode = respinNode
            break
        end
    end

    local reels = self.m_machine.m_runSpinResultData.p_reels

    --设定为锁定状态
    midNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    

    --创建一个宝箱图标
    local box = self:createBoxSymbol()
    self.m_machine.m_effectNode:addChild(box)
    box:setPosition(util_convertToNodeSpace(midNode,self.m_machine.m_effectNode))

    if reels[2][3] == self.m_machine.SYMBOL_BONUS then
        box:findChild("m_lb_coins"):setString(0)
        gLobalSoundManager:playSound("MagicianSounds/sound_Magician_show_box_with_coin.mp3")
        box:runCsbAction("actionframe4")
        --bonus图标挑起动作
        midSymBol:runAnim("actionframe2",false,function()
            box:runCsbAction("actionframe",false,function()
                box:removeFromParent()
                
            
                midSymBol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_TREASURE), self.m_machine.SYMBOL_TREASURE)
                midSymBol:runAnim("idleframe2")
                
                --设置宝箱分数
                local lbl_score = midSymBol:getCcbProperty("m_lb_coins")
                lbl_score:setString(util_formatCoins(midSymBol.m_score, 3))
                self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
                local pos = util_convertToNodeSpace(midSymBol,self)
                util_changeNodeParent(self,midSymBol,REEL_SYMBOL_ORDER.REEL_ORDER_2 - midSymBol.p_rowIndex, self.REPIN_NODE_TAG)
                midSymBol:setPosition(pos)
                lbl_score:setVisible(true)

                --收集图标分数
                self:collectBonusInBox(midSymBol,function()
                    --变成bonus图标
                    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_change_box_to_coins.mp3")
                    midSymBol:runAnim("actionframe2",false,function()
                        --图标变为bonus图标
                        midSymBol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_BONUS), self.m_machine.SYMBOL_BONUS)
                        --设置宝箱分数
                        local lbl_score = midSymBol:getCcbProperty("m_lb_coins")
                        lbl_score:setString(util_formatCoins(midSymBol.m_score, 3))
                        self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
                        lbl_score:setVisible(true)
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end)
            end)

            local str = midSymBol:getCcbProperty("m_lb_coins"):getString()
            box.m_score = midSymBol.m_score
            --设置宝箱分数
            local lbl_score = box:findChild("m_lb_coins")
            local score = util_formatCoins(box.m_score, 3)
            lbl_score:setString(score)
            self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
            if box.m_score == 0 then
                lbl_score:setVisible(false)
            end
        end)

    else
        gLobalSoundManager:playSound("MagicianSounds/sound_Magician_show_box.mp3")
        box:runCsbAction("actionframe4",false,function()
            box:removeFromParent()
            
            midSymBol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_TREASURE), self.m_machine.SYMBOL_TREASURE)
            midSymBol:runAnim("idleframe2")
            --设置宝箱分数
            local lbl_score = midSymBol:getCcbProperty("m_lb_coins")
            lbl_score:setString(0)
            lbl_score:setVisible(false)
            --当前宝箱的分数
            midSymBol.m_score = 0
            local pos = util_convertToNodeSpace(midSymBol,self)
            util_changeNodeParent(self,midSymBol,REEL_SYMBOL_ORDER.REEL_ORDER_2 - midSymBol.p_rowIndex, self.REPIN_NODE_TAG)
            midSymBol:setPosition(pos)

            --收集图标分数
            self:collectBonusInBox(midSymBol,function()
                --变成bonus图标
                gLobalSoundManager:playSound("MagicianSounds/sound_Magician_change_box_to_coins.mp3")
                midSymBol:runAnim("actionframe2",false,function()
                    --图标变为bonus图标
                    midSymBol:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_BONUS), self.m_machine.SYMBOL_BONUS)
                    --设置宝箱分数
                    local lbl_score = midSymBol:getCcbProperty("m_lb_coins")
                    lbl_score:setString(util_formatCoins(midSymBol.m_score, 3))
                    lbl_score:setVisible(true)
                    self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
                    if type(func) == "function" then
                        func()
                    end
                end)
            end)
        end)
    end
end

--[[
    宝箱收集图标动画
]]
function MagicianRespinView:collectBonusInBox(symbolNode,func)
    self:collectNextBonus(1,symbolNode,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    收集下个bonus图标
]]
function MagicianRespinView:collectNextBonus(index,endNode,func)
    --收集结束
    if index > #self.m_respinNodes then
        self.m_machine:delayCallBack(40 / 60,function()
            if type(func) == "function" then
                func()
            end
        end)
        
        return 
    end
    local respinNode = self.m_respinNodes[index]

    --宝箱图标不收集
    if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode.p_rowIndex == endNode.p_rowIndex then
        self:collectNextBonus(index + 1,endNode,func)
        return
    end
    --不是bonus图标跳过收集下一个
    if respinNode.m_baseFirstNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS then
        self:collectNextBonus(index + 1,endNode,func)
        return
    end

    local endPos = util_convertToNodeSpace(endNode,self.m_machine.m_effectNode)

    --创建临时图标
    local tempSymbol = util_createAnimation("Socre_Magician_Bonus.csb")
    self.m_machine.m_effectNode:addChild(tempSymbol)
    tempSymbol:setPosition(util_convertToNodeSpace(respinNode,self.m_machine.m_effectNode))

    local str = respinNode.m_baseFirstNode:getCcbProperty("m_lb_coins"):getString()
    tempSymbol:findChild("m_lb_coins"):setString(str)
    local score = respinNode.m_baseFirstNode.m_score or 0

    

    --替换原图标为空图标
    respinNode.m_baseFirstNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_EMPTY), self.m_machine.SYMBOL_EMPTY)
    --把图标放回去
    respinNode:setFirstSlotNode(respinNode.m_baseFirstNode)
    --解除锁定状态
    respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)

    
    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_fly_to_box.mp3")
    --收集图标动作
    local seq = cc.Sequence:create({
        cc.DelayTime:create(10 / 60),
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function()
            
            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_fly_to_box_feedback.mp3")
            endNode:runAnim("actionframe")

            --设置宝箱分数
            local lbl_score = endNode:getCcbProperty("m_lb_coins")
            score = util_formatCoins(endNode.m_score, 3)
            lbl_score:setString(score)
            self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)
            lbl_score:setVisible(true)

      
            

            tempSymbol:findChild("Particle_1"):stopSystem()
            tempSymbol:findChild("Node_1"):setVisible(false)
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    self.m_machine:delayCallBack(30 / 60,function()
        --累加分数
        endNode.m_score = score + endNode.m_score
        --收集下一个
        self:collectNextBonus(index + 1,endNode,func)
    end)

    tempSymbol:runAction(seq)
    tempSymbol:runCsbAction("shouji")
    tempSymbol:findChild("Particle_1"):setPositionType(0)
    tempSymbol:findChild("Particle_1"):setDuration(-1)

end

--[[
    乘倍动画
]]
function MagicianRespinView:runBonusMultipleAni(func)
    --乘倍图标数量
    local num,totalMultiples = 0,1
    local positionMultiple = self.m_machine.m_runSpinResultData.p_selfMakeData.positionMultiple
    for k,multiple in pairs(positionMultiple) do
        num = num + 1
        totalMultiples = totalMultiples * multiple
    end

    --乘倍图标
    local nodes_multiple = {}
    for index = 1 ,#self.m_respinNodes do
        local node = self.m_respinNodes[index]
        --分数乘倍
        if node.m_baseFirstNode.p_symbolType == self.m_machine.SYMBOL_BONUS then
            node.m_baseFirstNode.m_score = node.m_baseFirstNode.m_score * totalMultiples
        end
        local pos = self.m_machine:getPosReelIdx(node.p_rowIndex, node.p_colIndex)
        if positionMultiple[tostring(pos)] ~= nil then
            nodes_multiple[#nodes_multiple + 1] = node
        end
    end

    local function startAni()
        self:runNextBonusMultiples(1,nodes_multiple[1],function()
            if type(func) == "function" then
                func()
            end
        end)
    end

    

    self.m_machine:delayCallBack(60 / 60,function()
        if num > 1 then
            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_multiple_turn_round.mp3")
            for index = #nodes_multiple,2,-1 do
                local node = nodes_multiple[index]
                node.m_baseFirstNode:runAnim("actionframe")
            end
            self.m_machine:delayCallBack(1,function()
                --乘倍图标有多个先收集到一个上
                for index = #nodes_multiple,2,-1 do
                    local node = nodes_multiple[index]
                    self:runFlyLineAct(node,nodes_multiple[1])
                end

                self.m_machine:delayCallBack(30 / 60,function()
                    --设置乘倍
                    local lbl_score = nodes_multiple[1].m_baseFirstNode:getCcbProperty("m_lb_coins")
                    lbl_score:setString("X"..totalMultiples)
                    self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},330)
                    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_multiple_turn_round.mp3")
                    nodes_multiple[1].m_baseFirstNode:runAnim("actionframe")
                    self.m_machine:delayCallBack(1,function()
                        startAni()
                    end)
                    
                end)
            end)
            
    
            
        else
            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_multiple_turn_round.mp3")
            
            for k,node in pairs(nodes_multiple) do
                node.m_baseFirstNode:runAnim("actionframe")
            end
            self.m_machine:delayCallBack(1,function()
                startAni()
            end)
        end
    end)
end

--[[
    下一个bonus乘倍
]]
function MagicianRespinView:runNextBonusMultiples(index,multipleNode,func)
    --收集结束
    if index > #self.m_respinNodes then
        self.m_machine:delayCallBack(30 / 60,function()
            if type(func) == "function" then
                func()
            end
        end)
        
        return 
    end

    local respinNode = self.m_respinNodes[index]

    --不是bonus图标跳过收集下一个
    if respinNode.m_baseFirstNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS then
        self:runNextBonusMultiples(index + 1,multipleNode,func)
        return
    end
    --拖尾动画
    self:runFlyLineAct(multipleNode,respinNode,nil,function()
        --设置宝箱分数
        local lbl_score = respinNode.m_baseFirstNode:getCcbProperty("m_lb_coins")
        local score = util_formatCoins(respinNode.m_baseFirstNode.m_score, 3)
        lbl_score:setString(score)
        self.m_machine:updateLabelSize({label=lbl_score,sx=0.5,sy=0.5},297)

        respinNode.m_baseFirstNode:runAnim("actionframe3",false,function()
        end)

        
    end)

    self.m_machine:delayCallBack(20 / 60,function()
        self:runNextBonusMultiples(index + 1,multipleNode,func)
    end)
end

--[[
    飞粒子动画
]]
function MagicianRespinView:runFlyLineAct(startNode,endNode,keyFunc,endFunc)

    -- 创建粒子
    local flyNode =  util_createAnimation("Magician_chengbei_tuowei.csb")
    self.m_machine.m_effectNode:addChild(flyNode)

    local startPos = util_convertToNodeSpace(startNode,self.m_machine.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_machine.m_effectNode)
    
    flyNode:setPosition(startPos)

    

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 445 )
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = flyNode,   --执行动画节点  必传参数
        actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  ) --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

            gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_multiple_feedback.mp3")

            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_bonus_multiple.mp3")

    return flyNode

end

--获取所有最终停止信号
function MagicianRespinView:getAllEndSlotsNode()
    local endSlotNode = {}
    local childs = self:getChildren()

    for i=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[i]
          endSlotNode[#endSlotNode + 1] =  repsinNode.m_baseFirstNode
    end
    return endSlotNode
end

--[[
    显示当前的jackpot图标
]]
function MagicianRespinView:showCurJackpotSymbolAni(symbolType,func)
    local respinNodes = self.m_respinNodes
    for k,node in pairs(respinNodes) do
        if node.m_baseFirstNode and node.m_baseFirstNode.p_symbolType == symbolType then
            local symbolNode = node.m_baseFirstNode
            symbolNode:runAnim("actionframe")
        end
    end

    self.m_machine:delayCallBack(110 / 60,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function MagicianRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false 
        
        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
        -- if self.m_machine.m_isNotice then
        --     runLong = (repsinNode.p_colIndex - 1) * BASE_COL_INTERVAL
        --     if runLong == 0 then
        --         runLong = 2 
        --     end
        -- end
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


return MagicianRespinView