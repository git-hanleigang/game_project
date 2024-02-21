local VegasLifeClassicWinView = class("VegasLifeClassicWinView", util_require("base.BaseView"))


function VegasLifeClassicWinView:initUI(_machine)
    self.m_winCoin = 0
    
    self.m_machine = _machine -- 当前显示的 MagicSpiritClassicSlots

    self:createCsbNode("VegasLife_ClassicBorad" .. self.m_machine.m_bonusCol .. ".csb")
    local lizi1 =  self:findChild("Particle_5")
    local lizi2 =  self:findChild("Particle_5_0")
    local lizi3 =  self:findChild("Particle_5_0_0")
    local lizi4 =  self:findChild("Particle_5_0_0_0")
    lizi1:stopSystem()
    lizi2:stopSystem()
    lizi3:stopSystem()
    lizi4:stopSystem()

    -- 上面遮罩隐藏
    self:findChild("zhezhao_0"):setVisible(false)
    self:createShowNode( )

end

function VegasLifeClassicWinView:onEnter()
end

function VegasLifeClassicWinView:onExit()
end

function VegasLifeClassicWinView:createShowNode( )

    local reeldata = self.m_machine.m_runSpinResultData.p_reels 
    if  reeldata and #reeldata > 0 then
        print("-------- 正常")  
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

            rowIndex = rowIndex - stepCount
        end  -- end while

    end

end

function VegasLifeClassicWinView:createOneNode( symbolType)
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

return VegasLifeClassicWinView
