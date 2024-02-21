--[[
    选择档位弹板
]]
local PublicConfig = require "TripleBingoPublicConfig"
local TripleBingoChooseView = class("TripleBingoChooseView",util_require("Levels.BaseLevelDialog"))

function TripleBingoChooseView:initUI(_initData)
    self.m_machine = _initData.machine
    self.m_fnOver  = _initData.fnOver
    self.m_isOnEnter = _initData.bOnEnter
    self.m_isFirstIn = _initData.bisFirstIn
    self:createCsbNode("TripleBingo/ChooseGame.csb")
    self:initChooseItem()
    util_setCascadeColorEnabledRescursion(self, true)
    self:playChooseViewStartAnim()
    if not self.m_isFirstIn  then
        self:addClick(self:findChild("Panel_1"))
    end
end

function TripleBingoChooseView:playChooseViewStartAnim()

    local delayTime = self.m_isOnEnter and 0.5 or 0
    self.m_machine:levelPerformWithDelay(self, delayTime, function()
        self.m_bCanClick = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_48)
        self:runCsbAction("start", false, function()
            self.m_bCanClick = true
        end)
    end)
end

function TripleBingoChooseView:playChooseViewOverAnim(_bingoReelIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_50)
    self:runCsbAction("over", false, function()
        self:findChild("Node_1"):setVisible(false)
        if _bingoReelIndex then
            self.m_machine:changeBetMultiply(_bingoReelIndex, true)
        end
        performWithDelay(self,function()
            self.m_fnOver() 
        end,0)
        
    end)
  
end

--[[
    选项
]]
function TripleBingoChooseView:initChooseItem()
    self.m_chooseList = {}
    self.m_roleList  = {}

    for _index=1,3 do
        --选项
        local parent = self:findChild(string.format("Node_Choose_%d", _index))
        local chooseItem = self:createChooseItem(_index)
        parent:addChild(chooseItem)
        self.m_chooseList[_index] = chooseItem
        --间隔idle
        performWithDelay(chooseItem, function()
            chooseItem:runCsbAction("idle2", true)
        end, 9/60 * (_index - 1))
        --选项旁边的角色
        local roleAnim = util_createView("CodeTripleBingoSrc.TripleBingoRole", {spineName="TripleBingo_juese"})
        chooseItem:findChild("Node_juese"):addChild(roleAnim)
        self.m_roleList[_index] = roleAnim
        roleAnim:playChooseViewIdleAnim()
    end
end

function TripleBingoChooseView:createChooseItem(_selectIndex)
    local chooseItem = util_createAnimation("TripleBingo_Choose_0.csb")
    --索引
    local labNum = chooseItem:findChild("m_lb_num")
    labNum:setString(tostring(_selectIndex)) 
    --消耗
    local curBet         = globalData.slotRunData:getCurTotalBet()
    local betMultiply    = globalData.slotRunData:getCurBetMultiply()
    local baseBet        = curBet / betMultiply
    local bingoReelMulti = self.m_machine.m_betMultiList[_selectIndex]
    local showBet  = baseBet * bingoReelMulti
    local labCoins = chooseItem:findChild("m_lb_coins")
    labCoins:setString( util_formatCoins(showBet, 3) ) 
    --棋盘
    for _index=1,3 do
        local parent   = chooseItem:findChild(string.format("Node_Chooseqipan_%d", _index))
        local qipanCsb = util_createAnimation("TripleBingo_Chooseqipan.csb")
        parent:addChild(qipanCsb)
        --棋盘背景
        for _reelIndex=1,3 do
            local reelBg = qipanCsb:findChild( string.format("di_%d", _reelIndex) )
            reelBg:setVisible(_reelIndex == _index)
        end
        --棋盘类型
        qipanCsb:findChild("suoding_2"):setVisible(2 == _index and _selectIndex < 2)
        qipanCsb:findChild("suoding_3"):setVisible(3 == _index and _selectIndex < 3)
        self:upDateBonusList(qipanCsb, _index)
    end

    --点击事件
    local clickNode = chooseItem:findChild("Panel_click")
    clickNode:setTag(_selectIndex)
    self:addClick(clickNode)

    return chooseItem
end
function TripleBingoChooseView:upDateBonusList(_qipanCsb, _bingoReelIndex)
    local bingoReel = self.m_machine.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
    local maxCol = self.m_machine.m_iReelColumnNum
    local maxRow = self.m_machine.m_iReelRowNum
    for iCol = 1,maxCol  do
        for iRow = maxRow, 1, -1 do
            local reelPos = self.m_machine:getPosReelIdx(iRow, iCol)
            local parent = _qipanCsb:findChild(string.format("Node_choosebonus_%d", reelPos+1))
            if parent then
                local reward  = self.m_machine:getBingoSymbolReward(_bingoReelIndex, reelPos)
                if (reward.socre and reward.socre > 0) or reward.jackpot then
                    local symbolType = self.m_machine.FIXBONUS_TYPE_LEVEL1 + 1 - _bingoReelIndex
                    local symbol  = bingoReel:createBingoSymbol(symbolType, iCol, iRow)
                    parent:addChild(symbol)
                    symbol:setScale(0.25)
                    bingoReel:upDateBingoSymbolType(symbol)
                    local animNode = symbol:checkLoadCCbNode()
                    local slotNode = animNode.m_slotNode
                    slotNode:setVisible(false)
                end
            end
        end
    end

end

--默认按钮监听回调
function TripleBingoChooseView:clickFunc(sender)
    if not self.m_bCanClick then
        return
    end
    self.m_bCanClick = false
     
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_6)
    local nodeTag = sender:getTag() 
    local nodeName = sender:getName()
    if nodeName == "Panel_1" then
        self:playChooseViewOverAnim(nil)
    else

        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_49)

        --锁定时提前播放,解锁时关闭界面再播
        local newBetLevel = nodeTag - 1
        local bLock = newBetLevel < self.m_machine.m_iBetLevel
        if bLock then
            self.m_machine:changeBetMultiply(nodeTag, true)
        end  
        --选中
        local chooseItem = self.m_chooseList[nodeTag]
        chooseItem:runCsbAction("actionframe", false, function()
            if bLock then
                self:playChooseViewOverAnim(nil)
            else
                self:playChooseViewOverAnim(nodeTag)
            end
        end)
        performWithDelay(chooseItem, function()
            local roleAnim = self.m_roleList[nodeTag]
            roleAnim:playChooseViewSelectAnim()
        end, 30/60)
        --未选中
        for _index,_chooseItem in ipairs(self.m_chooseList) do
            if _index ~= nodeTag then
                _chooseItem:runCsbAction("darkstart", false)
            end
        end
    end
    
    
end


return TripleBingoChooseView