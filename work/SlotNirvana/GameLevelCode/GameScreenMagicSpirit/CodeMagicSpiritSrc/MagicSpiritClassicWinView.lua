local MagicSpiritClassicWinView = class("MagicSpiritClassicWinView", util_require("base.BaseView"))


function MagicSpiritClassicWinView:initUI(_machine)
    self.m_winCoin = 0
    
    self:createCsbNode("MagicSpirit/ClassicBonus.csb")
    self.m_machine = _machine -- 当前显示的 MagicSpiritClassicSlots
    self:createShowNode( )
    self:updateClassicReelBg()
    self:playChangeToRapids()
    
end

function MagicSpiritClassicWinView:onEnter()
end

function MagicSpiritClassicWinView:onExit()
end


function MagicSpiritClassicWinView:updateClassicReelBg()

    self:findChild("Node_hong"):setVisible(false)
    self:findChild("Node_jin"):setVisible(false)
    self:findChild("Node_lv"):setVisible(false)

    if self.m_machine.m_ClassicSymbolType == self.m_machine.m_parent.SYMBOL_CLASSIC1 then -- 绿
        self:findChild("Node_lv"):setVisible(true)
    elseif self.m_machine.m_ClassicSymbolType == self.m_machine.m_parent.SYMBOL_CLASSIC2 then -- 红
        self:findChild("Node_hong"):setVisible(true)
    elseif self.m_machine.m_ClassicSymbolType == self.m_machine.m_parent.SYMBOL_CLASSIC3 then -- 金
        self:findChild("Node_jin"):setVisible(true)
    end
    
end


function MagicSpiritClassicWinView:playChangeToRapids()

    local selfDate = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfDate.rapidPositions then
        for i, v in ipairs(selfDate.rapidPositions) do
            local fixPos = self.m_machine:getRowAndColByPos(v) 
            local targSp = self:findChild("sp_reel_"..fixPos.iY - 1):getChildByTag(fixPos.iY * SYMBOL_NODE_TAG + fixPos.iX)
            if targSp then

                local pos = cc.p(targSp:getPosition())
                targSp:removeFromParent()
                local node = self:createOneNode( self.m_machine.m_parent.SYMBOL_CLASSIC_SCORE_Rapid)
                node:setPosition(pos)
                self:findChild("sp_reel_"..fixPos.iY - 1):addChild(node,fixPos.iY * SYMBOL_NODE_TAG + fixPos.iX, fixPos.iY * SYMBOL_NODE_TAG + fixPos.iX)

            end
        end
    end

    local isShow = selfDate and selfDate.rapids and selfDate.rapids>=5
    self:changeFiveJackpotShow(isShow)
end

function MagicSpiritClassicWinView:createShowNode( )

    local reeldata = self.m_machine.m_runSpinResultData.p_reels 
    if  reeldata and #reeldata > 0 then
        print("-------- 正常")  
    else
        reeldata = self.m_machine.m_classicTemReelData["ClassicSlots"..self.m_machine.m_classicPlayIndex]
    end

    for colIndex=self.m_machine.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_machine.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount,rowNum,rowIndex = self.m_machine:getinitSlotRowDatatByNetData(columnData )

        while rowIndex >= 1 do

            local rowDatas = reeldata[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1

            local parentData = self.m_machine.m_slotParents[colIndex]
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:createOneNode( symbolType)
              
            self:findChild("sp_reel_"..colIndex - 1):addChild(node,colIndex * SYMBOL_NODE_TAG + changeRowIndex, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node:setPositionX(parentData.startX )
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH - (halfNodeH*3/5) )

            if self.m_machine.m_parent:checkAddMuilLab(symbolType )  then
                --根据网络数据获取停止滚动时小块倍数
                local mul = self.m_machine:getNormalSymbolMul(self.m_machine:getPosReelIdx(changeRowIndex, colIndex)) --获取分数（网络数据）
                local index = 0
                if type(mul) == "number" then
                    if mul > self.m_machine.m_parent.m_NormalSymbolMul then
                        self.m_machine.m_parent:createBaseReelMulLab(node )
                        self.m_machine.m_parent:setMulLabNum(mul,node)
                    end
                end
            end

            rowIndex = rowIndex - stepCount
        end  -- end while

    end

end

function MagicSpiritClassicWinView:createOneNode( symbolType)
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine,symbolType)
    if ccbName == nil or ccbName == "" then
        return
    end
    local hasSymbolCCB = cc.FileUtils:getInstance():isFileExist(ccbName .. ".csb")
    local hasSpine = cc.FileUtils:getInstance():isFileExist(ccbName .. ".atlas")
    local node = nil
    if hasSpine then
        node = util_spineCreate(ccbName,true,true)
        util_spinePlay(node,"idleframe")
    elseif hasSymbolCCB then
        node = util_createAnimation(ccbName .. ".csb") 
        node:runCsbAction("idleframe")
    end
    return node
end


function MagicSpiritClassicWinView:updateCoinsLab(_coins )
    _coins = _coins or 0
    --存一下
    self.m_winCoin = _coins

    for i=1,3 do
        local lab = self:findChild("m_lb_coin"..i)
        if lab then
            lab:setString(util_formatCoins(_coins,3))
            self:updateLabelSize({label = lab, sx = 1, sy = 1}, 166)
        end
    end
end

function MagicSpiritClassicWinView:changeFiveJackpotShow(isShow)
    for _index=0,2 do
        local reel_node = self:findChild(string.format("reel_0_%d", _index))
        if(reel_node)then
            reel_node:setVisible(isShow)
        end
    end
end

return MagicSpiritClassicWinView
