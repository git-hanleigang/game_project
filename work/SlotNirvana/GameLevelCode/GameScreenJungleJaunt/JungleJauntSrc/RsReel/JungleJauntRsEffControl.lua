---
--xcyy
--2018年5月23日
--JungleJauntRsEffControl.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntRsEffControl = class("JungleJauntRsEffControl")

function JungleJauntRsEffControl:initData_(_machine)
    self.m_machine = _machine
end

function JungleJauntRsEffControl:getLockBonusInfos()
    -- 按照数值给的播放顺序播，要不会导致赢钱对不上
    -- 按照顺序 1,2,3,4,5,6,7... 的顺序组装数据
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local wheelkinds = rsExtraData.wheelkinds or {}
    local specialwheelkinds = rsExtraData.specialwheelkinds or {}
    local infos = {}
    infos = clone(wheelkinds)
    for i=1,#specialwheelkinds do
        local specialwheelkind = clone(specialwheelkinds[i])
        table.insert(infos,specialwheelkind)
    end

    return infos
end

function JungleJauntRsEffControl:playEffStart(_func)
    -- 每次播放游戏事件时的最开始去初始化，因为有可能多个收集，还需要用这个值去做赢钱累计显示

        self.m_rsBuff4ChomperCoins =  self.m_machine.m_lastReSpinWinCoins 


    self.m_lockBonusFunc = function()
        -- 所有玩法结束如果特殊轮子是最后一个播的需要给他变成普通轮子
        local waitTime = 0
        if not self.m_machine.m_rsTopWheelNor:isVisible() then
            
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_94)
            self.m_machine.m_rsTopWheelNor.m_zLTX:setVisible(true)
            self.m_machine.m_rsTopWheelSpec.m_zLTX:setVisible(true)
            util_spinePlay(self.m_machine.m_rsTopWheelNor.m_zLTX,"actionframe")
            util_spinePlay(self.m_machine.m_rsTopWheelSpec.m_zLTX,"actionframe")
            util_spineEndCallFunc(self.m_machine.m_rsTopWheelNor.m_zLTX,"actionframe",function()
                self.m_machine.m_rsTopWheelNor.m_zLTX:setVisible(false)
                self.m_machine.m_rsTopWheelSpec.m_zLTX:setVisible(false)
            end)
            performWithDelay(self.m_machine.m_rsTopWheelNor,function()
                self.m_machine.m_rsTopWheelNor:setVisible(true)
                self.m_machine.m_rsTopWheelSpec:setVisible(false)
            end,6/30)
            waitTime = 28/30
        end
    
        performWithDelay(
            self.m_machine.m_rsTopWheelNor,
            function()
                _func()
            end,
            waitTime
        )
    end 
    self.m_lockBonusInfos = self:getLockBonusInfos()
    self.m_lockBonusIndex = 0
    self:playRespinEffect()
end

function JungleJauntRsEffControl:playNorTopWheelRun(_infos)
    local waitTime = 0
    if not self.m_machine.m_rsTopWheelNor:isVisible() then
        self.m_machine.m_rsTopWheelNor.m_zLTX:setVisible(true)
        self.m_machine.m_rsTopWheelSpec.m_zLTX:setVisible(true)
        util_spinePlay(self.m_machine.m_rsTopWheelNor.m_zLTX,"actionframe")
        util_spinePlay(self.m_machine.m_rsTopWheelSpec.m_zLTX,"actionframe")
        util_spineEndCallFunc(self.m_machine.m_rsTopWheelNor.m_zLTX,"actionframe",function()
            self.m_machine.m_rsTopWheelNor.m_zLTX:setVisible(false)
            self.m_machine.m_rsTopWheelSpec.m_zLTX:setVisible(false)
        end)
        performWithDelay(self.m_machine.m_rsTopWheelNor,function()
            self.m_machine.m_rsTopWheelNor:setVisible(true)
            self.m_machine.m_rsTopWheelSpec:setVisible(false)
        end,6/30)
        waitTime = 28/30
    end

    performWithDelay(self.m_machine.m_rsTopWheelNor,function()
        self.m_machine.m_rsTopWheelNor:startMove()
        performWithDelay(self.m_machine.m_rsTopWheelNor,function()
            self.m_machine.m_rsTopWheelNor:stopMove(_infos)
        end,1.5)
    end,waitTime)

end

function JungleJauntRsEffControl:playSpecTopWheelRun(_infos)
    local waitTime = 0
    if not self.m_machine.m_rsTopWheelSpec:isVisible() then

        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_65)  
        self.m_machine.m_rsTopWheelNor.m_zLTX:setVisible(true)
        self.m_machine.m_rsTopWheelSpec.m_zLTX:setVisible(true)
        util_spinePlay(self.m_machine.m_rsTopWheelNor.m_zLTX,"actionframe")
        util_spinePlay(self.m_machine.m_rsTopWheelSpec.m_zLTX,"actionframe")
        util_spineEndCallFunc(self.m_machine.m_rsTopWheelNor.m_zLTX,"actionframe",function()
            self.m_machine.m_rsTopWheelNor.m_zLTX:setVisible(false)
            self.m_machine.m_rsTopWheelSpec.m_zLTX:setVisible(false)
        end)
        performWithDelay(self.m_machine.m_rsTopWheelNor,function()
            self.m_machine.m_rsTopWheelNor:setVisible(false)
            self.m_machine.m_rsTopWheelSpec:setVisible(true)
        end,6/30)
        waitTime = 28/30
    end

    performWithDelay(self.m_machine.m_rsTopWheelSpec,function()
        self.m_machine.m_rsTopWheelSpec:startMove()
        performWithDelay(self.m_machine.m_rsTopWheelSpec,function()
            self.m_machine.m_rsTopWheelSpec:stopMove(_infos)
        end,1.5)
    end,waitTime)

    
end

function JungleJauntRsEffControl:playRespinEffect()
    self.m_lockBonusIndex = self.m_lockBonusIndex + 1
    -- 需要继续写respinx中bonus玩法
    if self.m_lockBonusIndex > #self.m_lockBonusInfos  then
        if self.m_lockBonusFunc then
            self.m_lockBonusFunc()
            self.m_lockBonusFunc = nil
        end
        return
    end

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_50)  
     
    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]
    local posIndex = lockBonusInfo[1] -- 触发信号位置
    local gameType = lockBonusInfo[2] -- 触发类型
    local triEff = lockBonusInfo[3]   -- 具体效果
    local triEffPos = lockBonusInfo[4] -- 效果位置
    local fixPos = self.m_machine:getRowAndColByPos(posIndex)
    local iCol = fixPos.iY
    local iRow = fixPos.iX
    local animNode = self.m_machine.m_respinView:getRespinEndNode(iRow, iCol)
    local lockFrame = self.m_machine.m_respinView.m_lockFrames[posIndex + 1]
    util_spinePlay(lockFrame,"actionframe")
    util_spineEndCallFunc(lockFrame,"actionframe",function()
        util_spinePlay(lockFrame,"idle",true)
    end)
    local oldZOrder = animNode:getLocalZOrder()
    animNode:setLocalZOrder(oldZOrder*2)
    animNode:runAnim("actionframe",false,function()
        animNode:runAnim("idleframe2",true)
        animNode:setLocalZOrder(oldZOrder)
        if animNode.p_symbolType == self.m_machine.SYMBOL_BONUS_1  then
            local finalData = {}
            -- 普通buff
            if gameType == PBC.RS_GAME_BASE_TYPE.randomMul then
                -- 是随机一个bn乘倍，只有1有效果位置
                finalData.symbolType = PBC.RTW_RUNDATA.baseMul 
                finalData.nextFun    = function()
                    self:playNorRandomMul(function()
                        self.m_machine.m_rsTopWheelNor:playOneEffOverAnim(function()
                            lockFrame:setVisible(false)
                            lockFrame.bg:setVisible(false)
                            self:playRespinEffect()
                        end)
                        
                    end)
                end
            elseif gameType == PBC.RS_GAME_BASE_TYPE.addRow then
                --是升行
                finalData.symbolType = PBC.RTW_RUNDATA.baseRow
                finalData.nextFun    = function()
                    self:playNorAddRows(function()
                        lockFrame:setVisible(false)
                        lockFrame.bg:setVisible(false)
                        self:playRespinEffect()
                    end)
                end
            elseif gameType == PBC.RS_GAME_BASE_TYPE.addTime then
                --是增加respin次数
                finalData.symbolType = PBC.RTW_RUNDATA.baseSpinTime
                finalData.nextFun    = function()
                    self:playNorAddTimes(function()
                        lockFrame:setVisible(false)
                        lockFrame.bg:setVisible(false)
                        self:playRespinEffect()
                    end)
                end
            elseif gameType == PBC.RS_GAME_BASE_TYPE.winAll then
                --是直接赢钱
                finalData.symbolType = PBC.RTW_RUNDATA.baseWinAll
                finalData.nextFun    = function()
                    self:playNorWinAll(function()
                        lockFrame:setVisible(false)
                        lockFrame.bg:setVisible(false)
                        self:playRespinEffect()
                    end)
                end
            elseif gameType == PBC.RS_GAME_BASE_TYPE.addCoins then
                --是所有bn增加
                finalData.symbolType = PBC.RTW_RUNDATA.baseJumpAll
                finalData.nextFun    = function()
                    self:playNorAddCoinsAll(function()
                        lockFrame:setVisible(false)
                        lockFrame.bg:setVisible(false)
                        self:playRespinEffect()
                    end)
                end
            end
            finalData.triEff = triEff -- 触发效果
            finalData.triEffPos = triEffPos
            self:playNorTopWheelRun(finalData)
        elseif animNode.p_symbolType == self.m_machine.SYMBOL_BONUS_2  then
            local finalData = {}
            -- 特殊buff
            if gameType == PBC.RS_GAME_SPEC_TYPE.randomMul then
                -- 特殊格子对应的bonus2金额上涨为2倍、3倍或4倍
                finalData.symbolType = PBC.RTW_RUNDATA.specMul
                finalData.nextFun    = function()
                    self:playSpecRandomMul(function()
                        self.m_machine.m_rsTopWheelSpec:playOneEffOverAnim(function()
                            lockFrame:setVisible(false)
                            lockFrame.bg:setVisible(false)
                            self:playRespinEffect()
                        end) 
                    end)
                end
            elseif gameType == PBC.RS_GAME_SPEC_TYPE.jP then
                if triEffPos == "grand" then
                    -- ②特殊格子对应的bonus2金额变为GRAND
                    finalData.symbolType = PBC.RTW_RUNDATA.specGrand
                elseif triEffPos == "mega" then
                    -- ④特殊格子对应的bonus2金额变为MEGA
                    finalData.symbolType = PBC.RTW_RUNDATA.specMega
                elseif triEffPos == "major" then 
                    -- ⑤特殊格子对应的bonus2金额变为MAJOR
                    finalData.symbolType = PBC.RTW_RUNDATA.specMajor
                end
                finalData.nextFun = function()
                    
                    self:playSpecChange2Jp(function()
                        lockFrame:setVisible(false)
                        lockFrame.bg:setVisible(false)
                        self:playRespinEffect()
                    end)

                end
            end
            finalData.triEff = triEff -- 触发效果
            finalData.triEffPos = triEffPos
            self:playSpecTopWheelRun(finalData)
        end

    end)
    
    
end


function JungleJauntRsEffControl:playNorRandomMul(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_74)

    -- 数值已做规避，JP位置不会乘倍
    if not self.m_rsBuff1Bat then
        self.m_rsBuff1Bat = util_spineCreate("JungleJaunt_base_buff1_sp",true,true)
        self.m_machine:findChild("respin_buff1"):addChild( self.m_rsBuff1Bat)
    end

    self.m_rsBuff1Bat:setVisible(true)
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4
    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]

    util_spinePlay(self.m_rsBuff1Bat,"actionframe"..rows)
    util_spineEndCallFunc(self.m_rsBuff1Bat,"actionframe"..rows,function()
        self.m_rsBuff1Bat:setVisible(false)
    end)

    performWithDelay(self.m_rsBuff1Bat,function()
        
        local soundId = gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_75,true)

        local triEff = lockBonusInfo[3]   -- 具体效果
        local triEffPos = lockBonusInfo[4] -- 效果位置
        if type(triEffPos) == "number" then
            -- 因为特殊成倍和普通成倍数据结构不一致，做个兼容
            local list = {}
            list[1] = triEffPos
            triEffPos = list
        end
        for index=1,#triEffPos do
            local posIndex = triEffPos[index]
            local fixPos = self.m_machine:getRowAndColByPos(posIndex)
            local iCol = fixPos.iY
            local iRow = fixPos.iX
            local symbolNode = self.m_machine.m_respinView:getRespinEndNode(iRow, iCol)
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            local nodeScore = spineNode.m_nodeScore
            if nodeScore.score then

                local totalCoins = nodeScore.score * triEff
                local currCoins = nodeScore.score
                local addValue = (totalCoins - currCoins) / 60
                util_jumpNumLN(nodeScore:findChild("m_lb_coins"), currCoins, totalCoins, addValue, 1 / 60, {3}, nil, nil, function()
                    nodeScore:findChild("m_lb_coins"):setString(util_formatCoinsLN(totalCoins,3))
                    nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)  
                end,function()
                    nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
                end)
                nodeScore.score = totalCoins

                local oldZOrder = symbolNode:getLocalZOrder()
                symbolNode:setLocalZOrder(oldZOrder*2)
                symbolNode:runAnim("add",false,function()
                    symbolNode:setLocalZOrder(oldZOrder)
                    symbolNode:runAnim("idleframe2",true)
                end)
            else
                util_logDevAssert("小块上不可能没有赢钱赋值")
            end
            
        end

        performWithDelay(self.m_rsBuff1Bat,function()
            gLobalSoundManager:stopAudio(soundId)
            
            if _func then
                _func()
            end
        end,45/30)
        
    end,45/30)
 
end

function JungleJauntRsEffControl:playNorAddRows(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_64)  

    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]
    local triEff = lockBonusInfo[3]   -- 具体效果
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local rows =  self.m_machine.m_currRow + triEff -- 因为有时会触发多个升行，必须得本地存一份然后按照顺序升行
    self.m_machine.m_currRow = rows
    local moveTime = 20/60
    local animName = "switch".. (rows - 4)
    if triEff == 2 then
        if rows == 7 then
            animName = "switch2_2" 
        else
            animName = "switch1_2"
        end
        moveTime = 40/60 
    end 

    local posY = (rows - self.m_machine.m_iReelRowNum ) * (self.m_machine.m_respinView.m_slotNodeHeight + 1)
    util_playMoveToAction(self.m_machine.m_respinView, moveTime,cc.p(self.m_machine.m_respinView:getPositionX(),posY))

    self.m_machine:runCsbAction(animName,false,function()
        
        for i=1,#self.m_machine.m_respinView.m_respinNodes do
            local respinNode = self.m_machine.m_respinView.m_respinNodes[i]
            local bg = self.m_machine.m_respinView.m_rsBg[self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex)+1]
            local isShow = respinNode.p_rowIndex > (self.m_machine.m_iReelRowNum - rows)
            if isShow then
                if not bg:isVisible() then
                    util_playFadeOutAction(bg,0,function()
                        bg:setVisible(true)
                        util_playFadeInAction(bg,0.2)
                    end)
                end
                if not respinNode:isVisible() then
                    util_playFadeOutAction(respinNode,0,function()
                        respinNode:setVisible(true)
                        util_playFadeInAction(respinNode,0.2)
                    end)
                end
                if not respinNode.m_clipNode:isVisible() then
                    util_playFadeOutAction(respinNode.m_clipNode,0,function()
                        respinNode.m_clipNode:setVisible(true)
                        util_playFadeInAction(respinNode.m_clipNode,0.2)
                    end)
                end  
            end
        end

        self.m_machine.m_rsTopWheelNor:playOneEffOverAnim(function()
            if _func then
                _func()
            end
        end)

    end)

    
end

function JungleJauntRsEffControl:playNorAddTimes(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_53)   

    if not self.m_rsBuff3Monkey then
        self.m_rsBuff3Monkey = util_spineCreate("JungleJaunt_base_buff4",true,true)
        self.m_machine:findChild("base_buff4"):addChild( self.m_rsBuff3Monkey)
        self.m_rsBuff3MonkeyTx = util_spineCreate("JungleJaunt_base_buff4_xj",true,true)
        self.m_machine:findChild("base_buff4_xj"):addChild( self.m_rsBuff3MonkeyTx)
        self.m_rsBuff3MonkeyTx:setPosition(cc.p(0,0))
        self.m_rsBuff3Monkey:setVisible(false)
        self.m_rsBuff3MonkeyTx:setVisible(false)
    end

    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4
    self.m_rsBuff3Monkey:setPositionY(0)
    self.m_rsBuff3MonkeyTx:setPositionY(0)
    if rows > 5 then
        self.m_rsBuff3Monkey:setPositionY(350)
        self.m_rsBuff3MonkeyTx:setPositionY(350)
    end

    self.m_rsBuff3Monkey:setVisible(true)
    util_spinePlay(self.m_rsBuff3Monkey,"actionframe")
    util_spineEndCallFunc(self.m_rsBuff3Monkey,"actionframe",function()
        self.m_rsBuff3Monkey:setVisible(false)
    end)

    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]
    local triEff = lockBonusInfo[3]   -- 具体效果
    local triEffPos = lockBonusInfo[4] -- 效果位置

    performWithDelay(self.m_rsBuff3Monkey,function()
        self.m_rsBuff3MonkeyTx:setVisible(true)
        
        local endPos = util_convertToNodeSpace(self.m_machine.m_respinBar:findChild("Node_22"), self.m_machine:findChild("base_buff4_xj"))
        local actionList = {}
        actionList[#actionList+1] = cc.CallFunc:create(function()
            util_spinePlay(self.m_rsBuff3MonkeyTx,"start2")
            util_spineEndCallFunc(self.m_rsBuff3MonkeyTx,"start2",function()
                self.m_rsBuff3MonkeyTx:setVisible(false)
                self.m_machine.m_rsTopWheelNor:playOneEffOverAnim(function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)

        actionList[#actionList+1] = cc.MoveTo:create(7/30, cc.p(endPos.x,endPos.y))
        actionList[#actionList + 1] = cc.DelayTime:create(15/30)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            local curNum = self.m_machine.m_respinBar.m_curCount + triEff
            local totalNum = self.m_machine.m_respinBar.m_totalCount + triEff
            self.m_machine:changeReSpinUpdateUI(curNum,totalNum)
        end)
        self.m_rsBuff3MonkeyTx:runAction(cc.Sequence:create(actionList))
    end,25/30)
end

function JungleJauntRsEffControl:playNorWinAll(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_77)

    -- 已兼容FREE下触发 的赢钱累计 利用 m_lastReSpinWinCoins 统一处理
    if not self.m_rsBuff4Chomper then
        self.m_rsBuff4Chomper = util_spineCreate("JungleJaunt_base_buff3",true,true)
        self.m_machine:findChild("respin_putong_buff4"):addChild( self.m_rsBuff4Chomper)

        self.m_rsBuff4ChomperTou = util_spineCreate("JungleJaunt_base_buff3_2",true,true)
        self.m_machine:findChild("respin_putong_buff4_tou"):addChild( self.m_rsBuff4ChomperTou)

        self.m_rsBuff4ChomperLab = util_createAnimation("JungleJaunt_respin_putong_buff4_shuzi.csb")
        util_spinePushBindNode(self.m_rsBuff4Chomper, "shuzi", self.m_rsBuff4ChomperLab)

        self.m_rsBuff4Chomper:setVisible(false)
        self.m_rsBuff4ChomperTou:setVisible(false)
    end
    self.m_rsBuff4Chomper:setVisible(true)
    self.m_rsBuff4ChomperTou:setVisible(true)
    self.m_rsBuff4ChomperLab:findChild("m_lb_coins"):setString("")
    
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4

    local animStartName = "respin_start"
    local animOverName = "respin_over"
    local animIdleName = "respin_idle"

    local animCFStartName = "respine_chufa_start"
    local animCFIdleName = "respine_chufa_idle"
    local animCFOverName = "respine_chufa_over"
    if rows > 5 then
        animStartName = "respin_start2"
        animOverName = "respin_over2"
        animIdleName = "respin_idle2"

        animCFStartName = "respine_chufa2_start"
        animCFIdleName = "respine_chufa2_idle"
        animCFOverName = "respine_chufa2_over"
    end

    util_spineMix(self.m_rsBuff4ChomperTou, animCFOverName, animIdleName, 0.2)
    util_spineMix(self.m_rsBuff4Chomper, animCFOverName, animIdleName, 0.2)
    util_spineMix(self.m_rsBuff4ChomperTou, animIdleName, animOverName, 0.2)
    util_spineMix(self.m_rsBuff4Chomper, animIdleName, animOverName, 0.2)
    util_spineMix(self.m_rsBuff4ChomperTou, animStartName, animCFStartName, 0.2)
    util_spineMix(self.m_rsBuff4Chomper, animStartName, animCFStartName, 0.2)

    util_spinePlay(self.m_rsBuff4ChomperTou,animStartName)
    util_spinePlay(self.m_rsBuff4Chomper,animStartName)
    util_spineEndCallFunc(self.m_rsBuff4Chomper,animStartName,function()

            util_spinePlay(self.m_rsBuff4ChomperTou,animCFStartName)
            util_spinePlay(self.m_rsBuff4Chomper,animCFStartName)
            util_spineEndCallFunc(self.m_rsBuff4Chomper,animCFStartName,function()
                util_spinePlay(self.m_rsBuff4Chomper,animCFIdleName,true)
                util_spinePlay(self.m_rsBuff4ChomperTou,animCFIdleName,true) 
            end)
            
            
            
            
            -- 金币飞
            self.m_playWAIndex = 0
            self.m_playWAList = self.m_machine.m_respinView:getAllCleaningNode()
            local playList = {}
            while true do
                if #self.m_playWAList == 0 then
                    break
                end
                local index = math.random(1,#self.m_playWAList)
                table.insert( playList, clone(self.m_playWAList[index]) )
                table.remove(self.m_playWAList,index)
            end
            self.m_playWAList = playList

            self.m_playEndFunc = function()

                -- gLobalSoundManager:stopAudio(self.m_eatSound)
                -- self.m_eatSound = nil

                util_spinePlay(self.m_rsBuff4Chomper,animCFOverName)
                util_spinePlay(self.m_rsBuff4ChomperTou,animCFOverName)
                util_spineEndCallFunc(self.m_rsBuff4Chomper,animCFOverName,function()
                    

                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_78)

                    util_spinePlay(self.m_rsBuff4Chomper,animIdleName,true)
                    util_spinePlay(self.m_rsBuff4ChomperTou,animIdleName,true) 

                    if not self.m_mask then
                        self.m_mask = util_createAnimation("JungleJaunt_tb_mask.csb")
                        self.m_machine:findChild("respin_putong_buff3_mask"):addChild(self.m_mask)
                    end
                    
                    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
                    local rows = rsExtraData.rows or 4
                    self.m_mask:runCsbAction("idle"..rows)

                    self.m_mask:setVisible(false)
                    util_playFadeOutAction(self.m_mask,0,function()
                        self.m_mask:setVisible(true)
                        util_playFadeInAction( self.m_mask,0.2)
                    end)
    
                    local animLab = util_createAnimation("JungleJaunt_respin_putong_buff4_shuzi_fly.csb")
                    self.m_machine:addChild(animLab,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    animLab:setScale(self.m_machine.m_machineRootScale)
                    local chomperLab = self.m_rsBuff4ChomperLab:findChild("m_lb_coins")
                    animLab:findChild("m_lb_coins"):setString(chomperLab:getString())
                    chomperLab:setString("")
                    animLab:setPosition(util_convertToNodeSpace(self.m_rsBuff4ChomperLab:findChild("m_lb_coins"),self.m_machine))
                    
                    local actionList = {}
                    local control_1 = cc.p(animLab:getPositionX(),animLab:getPositionY())
                    local control_2 = cc.p(animLab:getPositionX() - 100,animLab:getPositionY() + 500)
                    local endPos = util_convertToNodeSpace(self.m_machine.m_bottomUI:findChild("font_last_win_value"),self.m_machine)
                    actionList[#actionList+1] = cc.EaseIn:create(cc.BezierTo:create(1, {control_1, control_2, endPos}),3)    
                    actionList[#actionList+1] = cc.CallFunc:create(function()

                        animLab:findChild("m_lb_coins"):setString("")
                        animLab:runCsbAction("shouji",false,function()
                            animLab:removeFromParent()
                        end)
    
                        util_playFadeOutAction(self.m_mask,0.2,function()
                            self.m_mask:setVisible(false)
                        end)
    
                        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_79)

                         -- 把赢钱更新到下UI
                        local lastCurrCoins = self.m_machine.m_lastReSpinWinCoins 
                        local currCoins = self.m_rsBuff4ChomperCoins - lastCurrCoins
                        self.m_machine:setLastWinCoin(self.m_rsBuff4ChomperCoins)
                        self.m_machine:playCoinWinEffectUI(currCoins)

                        local params = {currCoins, true, true}
                        params[self.m_machine.m_stopUpdateCoinsSoundIndex] = true
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

                        util_spinePlay(self.m_rsBuff4Chomper,animOverName)
                        util_spinePlay(self.m_rsBuff4ChomperTou,animOverName)
                        util_spineEndCallFunc(self.m_rsBuff4Chomper,animOverName,function()
                            self.m_rsBuff4ChomperTou:setVisible(false)
                            self.m_rsBuff4Chomper:setVisible(false)
                            self.m_machine.m_rsTopWheelNor:playOneEffOverAnim(function()
                                if _func then
                                    _func()
                                end
                            end)
                        end) 
                    end)
                    animLab:runAction(cc.Sequence:create(actionList))

                end)

            end


            self.m_copyNodes = {}
            for index=1,#self.m_playWAList do
                local symbolNode = self.m_playWAList[index]
                local symbolType = symbolNode.p_symbolType
                local symbol_node = symbolNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                local nodeScore = spineNode.m_nodeScore
                local coins = nodeScore.score or 0
                -- 复制一份出来
                local animSpine = util_spineCreate(self.m_machine:MachineRule_GetSelfCCBName(symbolNode.p_symbolType),true,true)
                self.m_machine:findChild("respin_putong_buff4"):addChild(animSpine,100)
                animSpine.m_nodeScore = self.m_machine:createBonusLab(symbolNode.p_symbolType, animSpine)
                local bonus3Type = nodeScore.mType
                if symbolType == self.m_machine.SYMBOL_BONUS_2 then
                    -- self.m_machine:setBonus3Type(nodeScore.mType, animSpine.m_nodeScore) -- 策划要求只飞金币
                end
                animSpine.m_nodeScore:findChild("m_lb_coins"):setString("") -- 策划要求只飞金币
                animSpine:setPosition(util_convertToNodeSpace(symbolNode, self.m_machine:findChild("respin_putong_buff4")))
                util_spinePlay(animSpine,"idleframe2",true)
                table.insert(self.m_copyNodes,animSpine)
                animSpine:setVisible(false)
            end
            self:playNorWinAllCoinsFly()

        
    end)

    
    
end



function JungleJauntRsEffControl:playNorWinAllCoinsFly()
    self.m_playWAIndex = self.m_playWAIndex + 1
    if self.m_playWAIndex > #self.m_playWAList then
        if self.m_playEndFunc then
            self.m_playEndFunc()
            self.m_playEndFunc = nil
        end
        return
    end

    local playWAIndex = self.m_playWAIndex
    local symbolNode = self.m_playWAList[self.m_playWAIndex]
    local symbolType = symbolNode.p_symbolType
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore = spineNode.m_nodeScore
    local bonus3Type = nodeScore.mType
    local coins = nodeScore.score or 0
    local animSpine = self.m_copyNodes[playWAIndex]
    local chomperLab = self.m_rsBuff4ChomperLab:findChild("m_lb_coins")

    local endNode = self.m_machine:findChild("Node_BuffZui1")
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4
    if rows > 5 then
        endNode = self.m_machine:findChild("Node_BuffZui2")
    end
    local endPos = util_convertToNodeSpace(endNode, self.m_machine:findChild("respin_putong_buff4"))

    -- 先处理钱
    local totalCoins = nil
    local currCoins = nil
    if type(bonus3Type) == "string"  then
        -- 说明是Jackpot
        local jackpotType = "mini"
        for jpType,b3Type in pairs(PBC.Bonus3MType) do
            if bonus3Type == b3Type then
                jackpotType = b3Type
            end
        end
        coins = self.m_machine:getJackpotScore(jackpotType) + coins 
        currCoins = self.m_rsBuff4ChomperCoins
        totalCoins = self.m_rsBuff4ChomperCoins + coins
        self.m_rsBuff4ChomperCoins = totalCoins
    else
        currCoins = self.m_rsBuff4ChomperCoins
        totalCoins = self.m_rsBuff4ChomperCoins + coins 
        self.m_rsBuff4ChomperCoins = totalCoins
    end

    util_spinePlay(animSpine,"shouji")
    symbolNode:runAnim("shouji")
    performWithDelay(animSpine,function()
        symbolNode:runAnim("idleframe2",true)
        animSpine:setVisible(true)
        util_playMoveToAction(animSpine,15/30,endPos,function()


            -- if not self.m_eatSound then
            --     self.m_eatSound = gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_90,true)
            -- end

            animSpine:removeFromParent()
            self.m_rsBuff4ChomperLab:runCsbAction("shouji")
            
            if type(bonus3Type) == "string"  then
               
                local addValue = (totalCoins - currCoins) / 60
                util_jumpNumLN(chomperLab, currCoins, totalCoins, addValue, 1 / 60, {3}, nil, nil, function()
                    chomperLab:setString(util_formatCoinsLN(totalCoins,3))
                    if playWAIndex == #self.m_playWAList then
                        self:playNorWinAllCoinsFly()
                    end
                end)
            else
                local addValue = (totalCoins - currCoins) / 60
                util_jumpNumLN(chomperLab, currCoins, totalCoins, addValue, 1 / 60, {3}, nil, nil, function()
                    chomperLab:setString(util_formatCoinsLN(totalCoins,3))
                    if playWAIndex == #self.m_playWAList then
                        self:playNorWinAllCoinsFly()
                    end
                end)
            end
            
        end,"easyIn")
    end,15/30)

    if playWAIndex < #self.m_playWAList then
        performWithDelay(self.m_machine,function()
            self:playNorWinAllCoinsFly() 
        end,0.1)
    end
    
    
end

function JungleJauntRsEffControl:playNorAddCoinsAll(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_80)
    
    -- JP的加钱逻辑：本次需要变成jp但是还没变的，正常以单一数字的形式加钱，已经是JP的位置使用jp+数字的表现形式
    -- 注：本次未变化为JP所加的赢钱其实是无效的，因为会以一个图标的最后一次的变化buff作为最后的真实变化
    if not self.m_buff5YP then
        self.m_buff5YP = util_spineCreate("JungleJaunt_yuanpan_bonustx",true,true)
        self.m_machine:findChild("respin_zhuanlun"):addChild(self.m_buff5YP,100)
    end
    self.m_buff5YP:setVisible(true)
    util_spinePlay(self.m_buff5YP,"actionframe")
    util_spineEndCallFunc(self.m_buff5YP,"actionframe",function()
        self.m_buff5YP:setVisible(false)
    end)

    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4
    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]
    local triEff = lockBonusInfo[3]   -- 具体效果
    local triEffPos = lockBonusInfo[4] -- 效果位置
    local allLockBonus = self.m_machine.m_respinView:getAllCleaningNode()
        for index=1,#allLockBonus do
            -- local posIndex = triEffPos[index]
            -- local fixPos = self.m_machine:getRowAndColByPos(posIndex)
            -- local iCol = fixPos.iY
            -- local iRow = fixPos.iX
            local symbolNode = allLockBonus[index]
            local oldParent = symbolNode:getParent()
            local oldPosition = cc.p(symbolNode:getPosition())
            local oldZorder = symbolNode:getLocalZOrder()
            local nowPos = util_convertToNodeSpace(symbolNode, self.m_machine:findChild("respin_zhuanlun"))
            util_changeNodeParent(self.m_machine:findChild("respin_zhuanlun"), symbolNode)
            symbolNode:setPosition(nowPos)
            symbolNode:setLocalZOrder(oldZorder)
            

            local symbolType = symbolNode.p_symbolType 
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            local nodeScore = spineNode.m_nodeScore
            -- 先判断一下加钱的位置是不是jp图标,如果是的话需要显示一下 jp+钱 的UI类型
            if symbolType == self.m_machine.SYMBOL_BONUS_2 then
                self.m_machine:updateBonus3JpVisble(self.m_machine:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex),nodeScore)
            end
            
            if nodeScore.score then


                local totalCoins = triEff * globalData.slotRunData:getCurTotalBet() + nodeScore.score
                local currCoins = nodeScore.score
                local currValue = totalCoins - currCoins
                local addValue = currValue / 60
                
                performWithDelay(nodeScore:findChild("m_lb_coins"),function()

                    local labAdd = util_createAnimation("Socre_JungleJaunt_Bonus_info_add.csb")
                    nodeScore:findChild("root"):addChild(labAdd)
                    labAdd:findChild("m_lb_coins1"):setString(util_formatCoinsLN(currValue,3) )
                    labAdd:runCsbAction("add",false,function()
                        labAdd:removeFromParent()
                    end)
                    
                    util_jumpNumLN(nodeScore:findChild("m_lb_coins"), currCoins, totalCoins, addValue, 1 / 60, {3}, nil, nil, function()
                        nodeScore:findChild("m_lb_coins"):setString(util_formatCoinsLN(totalCoins,3))
                        nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
                        util_changeNodeParent(oldParent, symbolNode)
                        symbolNode:setLocalZOrder(oldZorder)
                        symbolNode:setPosition(oldPosition)
                    end,function()
                        nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
                    end)
                    symbolNode:runAnim("add",false,function()
                        symbolNode:runAnim("idleframe2",true)
                    end)
                end,10/30)
                nodeScore.score = totalCoins
            else
                util_logDevAssert("小块上不可能没有赢钱赋值")
            end
        end

        performWithDelay(self.m_machine.m_rsTopWheelNor,function()
            self.m_machine.m_rsTopWheelNor:playOneEffOverAnim(function()
                if _func then
                    _func()
                end
            end)
        end,110/60)
        

    
end


function JungleJauntRsEffControl:playSpecRandomMul(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_76)

    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]
    local triEff = lockBonusInfo[3]   -- 具体效果
    local posIndex = lockBonusInfo[1]
    local fixPos = self.m_machine:getRowAndColByPos(posIndex)
    local iCol = fixPos.iY
    local iRow = fixPos.iX
    local symbolNode = self.m_machine.m_respinView:getRespinEndNode(iRow, iCol)
    local index = posIndex + 1
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore = spineNode.m_nodeScore

    local oldZOrder = symbolNode:getLocalZOrder()
    symbolNode:setLocalZOrder(oldZOrder*2)

    self.m_machine.m_rsTopWheelSpec:playSpecReelBuff2(index,function()
        
        if nodeScore.score then
            local totalCoins = nodeScore.score * triEff
            local currCoins = nodeScore.score
            local addValue = (totalCoins - currCoins) / 60
            util_jumpNumLN(nodeScore:findChild("m_lb_coins"), currCoins, totalCoins, addValue, 1 / 60, {3}, nil, nil, function()
                nodeScore:findChild("m_lb_coins"):setString(util_formatCoinsLN(totalCoins,3))
                nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
                symbolNode:setLocalZOrder(oldZOrder)
                    self.m_machine.m_rsTopWheelSpec:playOneEffOverAnim(function()
                        if _func then
                            _func()
                        end
                    end)
            end,function()
                nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
            end)
            nodeScore.score = totalCoins
            symbolNode:runAnim("add",false,function()
                symbolNode:setLocalZOrder(oldZOrder)
                symbolNode:runAnim("idleframe2",true)
            end)
            self.m_machine.m_respinView:playSpecBuff2ShowTx(index) 
        else
            util_logDevAssert("小块上不可能没有赢钱赋值")
        end

        

    end)
end

function JungleJauntRsEffControl:playSpecChange2Jp(_func)


    local lockBonusInfo = self.m_lockBonusInfos[self.m_lockBonusIndex]
    local triEff = lockBonusInfo[3]   -- 具体效果
    local triEffType = lockBonusInfo[4] -- 具体变成哪种JP
    local posIndex = lockBonusInfo[1]
    local fixPos = self.m_machine:getRowAndColByPos(posIndex)
    local iCol = fixPos.iY
    local iRow = fixPos.iX
    local symbolNode = self.m_machine.m_respinView:getRespinEndNode(iRow, iCol)
    local index = posIndex + 1
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore = spineNode.m_nodeScore

    local oldZOrder = symbolNode:getLocalZOrder()
    symbolNode:setLocalZOrder(oldZOrder*2)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_93)

    self.m_machine.m_rsTopWheelSpec:playSpecReelBuff2(index,function()
        
         -- 根据类型修改图标
        local mType = PBC.Bonus3MType[triEffType]
        self.m_machine:setBonus3Type(mType, nodeScore)
        nodeScore.score = 0
        self.m_machine.m_respinView:playSpecBuff2ShowTx(index,function()
            symbolNode:setLocalZOrder(oldZOrder)
            self.m_machine.m_rsTopWheelSpec:playOneEffOverAnim(function()
                
                if _func then
                    _func()
                end
            end)
        end) 

    end)
    
end



return JungleJauntRsEffControl