local JmsBaseView = util_require("base.BaseView")
local GoldenGhostBonusPopUpUI = class("GoldenGhostBonusPopUpUI", util_require("base.BaseView"))
local CodeGameScreenGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")

function GoldenGhostBonusPopUpUI:ctor()
    JmsBaseView.ctor(self)
    self.m_totalScore = 0
    self.flyScoreTimer = nil
    self.curFlyIdx = 1
    self.curSymbolNode = nil
end

function GoldenGhostBonusPopUpUI:onExit()
    self.m_machine.bonusPopUpUI = nil
end

function GoldenGhostBonusPopUpUI:initUI()
    self.mask = util_createAnimation("GoldenGhost_Choose_dark.csb")
    self:addChild(self.mask,-1)
    self.mask:playAction("start",false)

    self:createCsbNode("GoldenGhost_Choose1.csb")
    self.m_lb_score = self:findChild("m_lb_coins")
    self.itemPreUIInfoList = {}
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle1", true)
            if not self.flyScoreTimer then
                self.flyScoreTimer = schedule(self,self.flyScoreUI,1/60)
            end
        end
    )
    self:setPosition(display.width / 2,display.height / 2)
    self.m_lb_score:setString("0")

    self.parentNode = self:findChild("Node_4")
    self.collectEffect = util_createAnimation("GoldenGhost_Choose1_bao.csb")
    self.collectEffect:setPosition(cc.p(self.m_lb_score:getPosition()))
    self.parentNode:addChild(self.collectEffect,-1)
end

function GoldenGhostBonusPopUpUI:setExtraInfo(machine, callBack)
    self.m_machine = machine
    self.callBack = callBack
    self:initItemUI()
end

function GoldenGhostBonusPopUpUI:getBonusCoin()
    local machine = self.m_machine
    local storedIcons = machine.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local totalScore = 0
    for k, v in ipairs(storedIcons) do
        local score = machine:getReSpinSymbolScore(v[1]) or 0 --获取分数（网络数据）
        totalScore = totalScore + score
    end
    return totalScore
end

function GoldenGhostBonusPopUpUI:initItemUI()
    local lbScore = self.m_lb_score
    local machine = self.m_machine
    local reelRow = machine.m_iReelRowNum
    local reelCol = machine.m_iReelColumnNum
    local itemPreUIInfoList = self.itemPreUIInfoList
    local deviceMidWidth,deviceMidHeight = display.width / 2,display.height / 2
    
    local fixSymbolNodeList = {}
    self.fixSymbolNodeList = fixSymbolNodeList
    for i = 1,reelRow do
        for j = 1,reelCol do
            local symbolNode = machine:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            release_print(string.format("[GoldenGhostBonusPopUpUI:initItemUI] _iCol=(%d) _iRow=(%d)", j ,i))
            local symbolType = symbolNode.p_symbolType
            if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                symbolNode:runAnim("idleframe", true)
                table.insert(fixSymbolNodeList,symbolNode)
                local symbolPositionX,symbolPositionY = symbolNode:getPosition()
                itemPreUIInfoList[symbolNode] = {symbolNode:getParent(),symbolPositionX,symbolPositionY}
                local symbolPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolPositionX,symbolPositionY))
                symbolNode:removeFromParent(false)
                self:addChild(symbolNode,symbolNode:getLocalZOrder())
                symbolNode:setPosition(symbolPos.x - deviceMidWidth,symbolPos.y - deviceMidHeight)
            end
        end
    end
    table.sort(fixSymbolNodeList,
    function(a,b)
        local aRowIndex = a.p_rowIndex
        local bRowIndex = b.p_rowIndex
        local aColIndex = a.p_cloumnIndex
        local bColIndex = b.p_cloumnIndex
        local aSymbolType = machine:formatAddSpinSymbol(a.p_symbolType)
        local bSymbolType = machine:formatAddSpinSymbol(b.p_symbolType)
        if aSymbolType == bSymbolType then
            if aRowIndex == bRowIndex then
                return aColIndex < bColIndex
            else
                if aColIndex == bColIndex then
                    return aRowIndex > bRowIndex
                else
                    return aColIndex < bColIndex
                end
            end
        else
            return aSymbolType < bSymbolType
        end
    end)
    machine.m_bonusNum = #fixSymbolNodeList
end

function GoldenGhostBonusPopUpUI:flyScoreUI()
    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig

    local machine = self.m_machine
    local lbScore = self.m_lb_score
    local fixSymbolNodeList = self.fixSymbolNodeList
    local totalBet = globalData.slotRunData:getCurTotalBet()

    if self.curFlyIdx > #fixSymbolNodeList then
        self:stopFlyScoreTimer()
        util_performWithDelay(self, function( )
            self:returnToReelParent()
            self:runCsbAction("down",false,
                function()
                    local bonusUI = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusUI")
                    bonusUI:setExtraInfo(machine,self.callBack)
                    self:addChild(bonusUI,0)
                end)
            gLobalSoundManager:playSound(levelConfig.Sound_Bonus_EachWins_Down)
        end, 1.5)

        return
    end

    if not self.curSymbolNode then
        

        local deviceMidWidth,deviceMidHeight = display.width / 2,display.height / 2
        local scorePosX,scorePosY = lbScore:getPosition()
        self.curSymbolNode = fixSymbolNodeList[self.curFlyIdx]
        local curNode = self.curSymbolNode
        local rowIndex = curNode.p_rowIndex
        local columnIndex = curNode.p_cloumnIndex
        local symbolType = curNode.p_symbolType
        local symbolPositionX,symbolPositionY = curNode:getPosition()
        local score = machine:getScoreInfoByPos(rowIndex, columnIndex)

        local preZOrder = curNode:getLocalZOrder()
        curNode:setLocalZOrder(9999)
        -- 不播放收集动效
        -- curNode:runAnim("shouji", false,function ( ... )

            curNode:runAnim("idleframe", true)
            -- util_performWithDelay(self,function ( ... )
            --         self.curSymbolNode = nil
            --         self.curFlyIdx = self.curFlyIdx + 1
            -- end,0.1)
        -- end)
        -- 可以在上一个还没播完的时候就开始播下一个 0.5s
        util_performWithDelay(self,function ( ... )
            self.curSymbolNode = nil
            self.curFlyIdx = self.curFlyIdx + 1
        end,0.5)

        gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Collect_Start)

         -- 最低等级的延时修改为0
         local collectTime = 0--10 / 60
         if symbolType ~= CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
             collectTime = 20 / 60
         end

        util_performWithDelay(self,function ( ... )
            -- body
            curNode:setLocalZOrder(preZOrder)
            local moveActionNode, effectLabelAct = util_csbCreate("GoldenGhost_coins.csb", true)
            util_csbPauseForIndex(effectLabelAct, 30)
            local function getScoreLabel(node)
                local name = node:getName()
                if name == "m_lb_coins" then
                    return node
                else
                    for k, v in ipairs(node:getChildren()) do
                        local n = getScoreLabel(v)
                        if n ~= nil then
                            return n
                        end
                    end
                end
            end
            local lab = getScoreLabel(moveActionNode)

            local coinsStr = self.m_machine:getCoinsByScore(score)
            lab:setString(coinsStr)
            moveActionNode:setPosition(symbolPositionX,symbolPositionY)
            self:addChild(moveActionNode,curNode:getLocalZOrder() + REEL_SYMBOL_ORDER.REEL_ORDER_2_1)

            local scorePos = self:convertToNodeSpace(self.m_lb_score:getParent():convertToWorldSpace(cc.p(scorePosX,scorePosY)))
            local actionList = {}
            actionList[#actionList + 1] = cc.Spawn:create(cc.MoveTo:create(0.5, scorePos),cc.ScaleTo:create(0.5,0.5))
            actionList[#actionList + 1] = cc.CallFunc:create(function ( sender )
                sender:removeFromParent()

                self.collectEffect:runCsbAction("actionframe",false)
                self:runCsbAction("actionframe",false,function ( ... )

                end)
                self:addScore(score)
                gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Collect_End)
            end)
            local seq = cc.Sequence:create(actionList)
            moveActionNode:runAction(seq)

        end, collectTime)

    end

end

function GoldenGhostBonusPopUpUI:stopFlyScoreTimer()
    if self.flyScoreTimer ~= nil then
        self:stopAction(self.flyScoreTimer)
        self.flyScoreTimer = nil
    end
end

function GoldenGhostBonusPopUpUI:returnToReelParent()
    for k,v in pairs(self.itemPreUIInfoList) do
        k:removeFromParent(false)
        v[1]:addChild(k,k:getLocalZOrder())
        k:setPosition(v[2],v[3])
    end
end

function GoldenGhostBonusPopUpUI:addScore(score)
    if not score then
        return
    end
    local lbScore = self.m_lb_score
    self.m_totalScore = self.m_totalScore + score
    -- local totalBet = globalData.slotRunData:getCurTotalBet()
    -- local numStr = util_formatCoins(totalBet * self.m_totalScore,3)
    local numStr = self.m_machine:getCoinsByScore(self.m_totalScore)
    lbScore:setString(numStr)
end

function GoldenGhostBonusPopUpUI:playCloseAnim()
    self:removeFromParent()
end


return GoldenGhostBonusPopUpUI