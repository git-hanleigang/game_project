local PBC = require "JungleJauntPublicConfig"
local JungleJauntRespinTopReel = class("JungleJauntRespinTopReel",util_require("Levels.BaseLevelDialog"))

function JungleJauntRespinTopReel:initUI(params)
    self.m_machine   = params.machine
    self.m_initData  = params
    --停轮数据
    self.m_finalData = {}
    --[[
        m_initData = {
            machine       = machine,
            buffReelIndex = 1
        }
    ]]

    self:createCsbNode("JungleJaunt_respin_zhuanlun.csb")

end

function JungleJauntRespinTopReel:removeAllReelSymbol()
    self.m_reel_horizontal:forEachRollNode(function(rollNode,bigRollNode,iRow)
        self.m_reel_horizontal:removeSymbolByRowIndex(iRow)
    end)
end



function JungleJauntRespinTopReel:initSpineUI()
    --创建横向滚轮
    self.m_reel_horizontal = self:createSpecialReelHorizontal()
    self:findChild("sp_reel1"):addChild(self.m_reel_horizontal)

    self.m_yuanPanPar = util_createAnimation("JungleJaunt_respin_zhuanlun_lvseyuanpan.csb")
    self:findChild("Node_yuanpan"):addChild(self.m_yuanPanPar)


    local width = self.m_reel_horizontal.m_parentData.reelWidth
    local height = self.m_reel_horizontal.m_parentData.reelHeight
    self.m_mask = util_createAnimation("JungleJaunt_respin_zhuanlun_mask.csb") 
    self:findChild("sp_reel1"):addChild(self.m_mask,-2)
    self.m_mask:setPosition(cc.p(width/2,height/2))
    self.m_mask:setVisible(false)
    
    self.m_yuanpan = util_spineCreate("JungleJaunt_yuanpan",true,true)
    self:findChild("sp_reel1"):addChild(self.m_yuanpan,-1)
    self.m_yuanpan:setPosition(cc.p(width/2,height/2))
    

    self.m_yuanpanTX = util_spineCreate("JungleJaunt_yuanpan_tx",true,true)
    self:findChild("Node_tx"):addChild(self.m_yuanpanTX)
    self.m_yuanpanTX:setVisible(false)

    self:findChild("putong"):setVisible(self.m_initData.buffReelIndex == 1)
    self:findChild("teshu"):setVisible(self.m_initData.buffReelIndex == 2)
    

    self.m_zLTX = util_spineCreate("JungleJaunt_respin_zhuanlun_tx",true,true)
    self:findChild("Node_tx2"):addChild(self.m_zLTX)
    self.m_zLTX:setVisible(false)

    util_spinePlay(self.m_yuanpan,"idle",true)

end



function JungleJauntRespinTopReel:playShowLockFrames(_index,_currFunc,_endFunc)
    self.m_yuanpanTX:setVisible(true)
    util_spinePlay( self.m_yuanpanTX,"shouji")
    util_spineEndCallFunc(self.m_yuanpanTX,"shouji",function()
        self.m_yuanpanTX:setVisible(false)
    end)

    if not self["m_lockFrameAnim".._index] then
        self["m_lockFrameAnim".._index] =  util_spineCreate("JungleJaunt_yuanpan_shouji_1",true,true)
        self:findChild("Node_tx"):addChild(self["m_lockFrameAnim".._index])
    end
    
    self["m_lockFrameAnim".._index]:setVisible(true)

    -- 时间线命名转换
    local animLisr = {
        1,8,15,29,22,
        2,9,16,30,23,
        3,10,17,31,24,
        4,11,18,32,25,
        5,12,19,33,26,
        6,13,20,34,27,
        7,14,21,35,28}

    util_spinePlay(self["m_lockFrameAnim".._index],"shouji"..animLisr[_index])
    util_spineEndCallFunc(self["m_lockFrameAnim".._index],"shouji"..animLisr[_index],function()
        self["m_lockFrameAnim".._index]:setVisible(false)
        if _endFunc then
            _endFunc()
        end
    end)
    performWithDelay(self["m_lockFrameAnim".._index],function()
        if _currFunc then
            _currFunc()
        end
    end,15/30)

end


function JungleJauntRespinTopReel:playSpecReelBuff2(_index,_currFunc,_endFunc)
    self.m_yuanpanTX:setVisible(true)
    util_spinePlay( self.m_yuanpanTX,"shouji")
    util_spineEndCallFunc(self.m_yuanpanTX,"shouji",function()
        self.m_yuanpanTX:setVisible(false)
    end)

    if not self["m_specBuff2Anim".._index] then
        self["m_specBuff2Anim".._index] =  util_spineCreate("JungleJaunt_yuanpan_shouji_2",true,true)
        self:findChild("Node_tx"):addChild(self["m_specBuff2Anim".._index])
    end
    
    self["m_specBuff2Anim".._index]:setVisible(true)

    -- 时间线命名转换
    local animLisr = {
        1,8,15,29,22,
        2,9,16,30,23,
        3,10,17,31,24,
        4,11,18,32,25,
        5,12,19,33,26,
        6,13,20,34,27,
        7,14,21,35,28}

    util_spinePlay(self["m_specBuff2Anim".._index],"shouji"..animLisr[_index])
    util_spineEndCallFunc(self["m_specBuff2Anim".._index],"shouji"..animLisr[_index],function()
        self["m_specBuff2Anim".._index]:setVisible(false)
        if _endFunc then
            _endFunc()
        end
    end)
    performWithDelay(self["m_specBuff2Anim".._index],function()
        if _currFunc then
            _currFunc()
        end
    end,23/30)

end



--[[
    创建特殊轮子-横向
]]
function JungleJauntRespinTopReel:createSpecialReelHorizontal()
    local sp_wheel  = self:findChild("sp_reel1")
    local wheelSize = sp_wheel:getContentSize()
    local configData = self.m_machine.m_configData 
    local reelData  = configData:getReSpinBuffReelData(self.m_initData.buffReelIndex)
    local iCol = 1
    local iRow = 5
    local reelResTime = 0.5
    local reelNode  =  util_require("JungleJauntSrc.RsTopWheel.JungleJauntRespinTopReelNode"):create({
        --列数据
        parentData  = {
            reelDatas = reelData,
            beginReelIndex = 1,
            slotNodeW = wheelSize.width / iRow,
            slotNodeH = wheelSize.height,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false
        },     
        --列配置数据 
        configData = {
            p_reelMoveSpeed = 1000,
            p_rowNum = 5,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = reelResTime,
            p_reelResDis = 15,
            p_reelRunDatas = {19}
        },      
        --创建小块      
        createSymbolFunc = function(symbolType, rowIndex, colIndex, isLastNode, _lastNodeCount)
            local symbolNode = self:createWheelNode(symbolType, rowIndex, colIndex, isLastNode, _lastNodeCount)
            return symbolNode
        end,
        --小块放回缓存池
        pushSlotNodeToPoolFunc = function(symbolType,symbolNode)
            
        end,
        --小块数据刷新回调
        updateGridFunc = function(symbolNode)
            self:upDateReelGrid(symbolNode)
        end,  
        --0纵向 1横向 默认纵向
        direction = 1,      
        colIndex = 1,
        --必传参数
        machine = self.m_machine,    
        --列停止回调
        doneFunc = function()
            local fnNext = function()
                self:endRewordAinmFunc(function()
                    if self.m_finalData.nextFun then
                        self.m_finalData.nextFun()
                    end
                    self.m_finalData.nextFun = nil
                end)
            end 
            if "function" == type(fnNext) then
                --回弹
                self.m_machine:levelPerformWithDelay(self, reelResTime, fnNext)
            end
        end,
    })
    return reelNode
end

function JungleJauntRespinTopReel:endRewordAinmFunc(_func)
    if self.m_initData.buffReelIndex == 2 then
        util_spinePlay(self.m_zLTX,"over")
        util_spineEndCallFunc(self.m_zLTX,"over",function()
            self.m_zLTX:setVisible(false) 
        end)
    end
    

    gLobalSoundManager:stopAudio(self.m_runSound)  

    
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_52)   
    self.m_reel_horizontal:resetAllRollNodeZOrder()

    self.m_mask:setVisible(true)
    self.m_mask:runCsbAction("darkstart")
    self.m_mask:setLocalZOrder( 9)


    self.m_rewordSymbol =  self.m_reel_horizontal:getSymbolByRow(3)
    self.m_rewSymbolOldParent = self.m_rewordSymbol:getParent()
    util_changeNodeParent(self.m_yuanpan, self.m_rewordSymbol)

    self.m_yuanpan:setLocalZOrder(10)

    util_playScaleToAction(self.m_rewordSymbol,20/60, 1.2)

    util_spinePlay(self.m_yuanpan,"actionframe_start")
    util_spineEndCallFunc(self.m_yuanpan,"actionframe_start",function()
        util_spinePlay(self.m_yuanpan,"actionframe",false) 
        util_spineEndCallFunc(self.m_yuanpan,"actionframe",function()
            util_spinePlay(self.m_yuanpan,"over") 
            util_spineEndCallFunc(self.m_yuanpan,"over",function()
                util_spinePlay(self.m_yuanpan,"idle",true)
                performWithDelay(self.m_yuanpan,function()
                    if _func then
                        _func()
                    end
            end,0.5)
            end)
        end)
        
    end)
end

function JungleJauntRespinTopReel:playOneEffOverAnim(_func)
    util_playFadeOutAction(self.m_rewordSymbol, 20/60) 
    self.m_mask:runCsbAction("darkover",false,function()
        self.m_mask:setVisible(false)
        self.m_yuanpan:setLocalZOrder(-1)
        util_changeNodeParent(self.m_rewSymbolOldParent, self.m_rewordSymbol)
        util_playScaleToAction(self.m_rewordSymbol,1/60,1,function()
            if _func then
                _func()
            end
        end)
    end)
end


function JungleJauntRespinTopReel:createWheelNode(symbolType, rowIndex, colIndex, isLastNode, _lastNodeCount)
    local tempSymbol = util_createAnimation("JungleJaunt_respin_zhuanlun_jiangli.csb")
    tempSymbol.p_symbolType = symbolType
    tempSymbol.p_iCol = colIndex
    tempSymbol.p_iRow = rowIndex
    tempSymbol.m_isLastSymbol  = isLastNode
    tempSymbol.m_lastNodeCount = _lastNodeCount or 6
    return tempSymbol
end

function JungleJauntRespinTopReel:upDateReelGrid(_symbolNode)
    self:reSetBuffBonusRewardVisible(_symbolNode)

end

function JungleJauntRespinTopReel:hideAllSymbolNodeUI(_symbolNode)
    _symbolNode:findChild("putong_lan"):setVisible(false)
    _symbolNode:findChild("putong_zi"):setVisible(false)
    _symbolNode:findChild("putong_hong"):setVisible(false)

    _symbolNode:findChild("putong_beishu"):setVisible(false)
    _symbolNode:findChild("shenghang"):setVisible(false)
    _symbolNode:findChild("cishu"):setVisible(false)
    _symbolNode:findChild("winall"):setVisible(false)
    _symbolNode:findChild("jiaqian"):setVisible(false)

    _symbolNode:findChild("teshu_zi"):setVisible(false)
    _symbolNode:findChild("teshu_lan"):setVisible(false)

    _symbolNode:findChild("teshu_beishu"):setVisible(false)
    _symbolNode:findChild("grand"):setVisible(false)
    _symbolNode:findChild("mega"):setVisible(false)
    _symbolNode:findChild("major"):setVisible(false)

end

function JungleJauntRespinTopReel:reSetBuffBonusRewardVisible(_symbolNode)
    local symbolType = _symbolNode.p_symbolType
    local isLastNode = _symbolNode.m_isLastSymbol
    self:hideAllSymbolNodeUI(_symbolNode)

    if symbolType == PBC.RTW_RUNDATA.baseMul then
        --   ①随机为棋盘上随机个数bonus乘倍（3-10倍）
        local mul = PBC.getRandomNorMul()
        if isLastNode and self.m_finalData.symbolType == PBC.RTW_RUNDATA.baseMul then
            -- 需要用真实数据更新
            mul = self.m_finalData.triEff 
        end
        if mul <= 5 then
            _symbolNode:findChild("putong_lan"):setVisible(true)
        elseif mul >= 6 and mul <= 8 then
            _symbolNode:findChild("putong_zi"):setVisible(true)
        else
            _symbolNode:findChild("putong_hong"):setVisible(true)
        end
        _symbolNode:findChild("putong_beishu"):setVisible(true)
        
        local lab = _symbolNode:findChild("chengbei") 
        lab:setString("X"..mul)

    elseif symbolType == PBC.RTW_RUNDATA.baseRow then
        --   ②随机升1-2行（最高可升至7行）
        local num = PBC.getRandomNorRowNum()
        if isLastNode and self.m_finalData.symbolType == PBC.RTW_RUNDATA.baseRow then
            -- 需要用真实数据更新
            num = self.m_finalData.triEff 
        end
        if num == 1 then
            _symbolNode:findChild("putong_lan"):setVisible(true)
        else
            _symbolNode:findChild("putong_zi"):setVisible(true)
        end
        _symbolNode:findChild("shenghang"):setVisible(true)
        _symbolNode:findChild("row"):setVisible(num <= 1)
        _symbolNode:findChild("rows"):setVisible(num > 1)

        local lab = _symbolNode:findChild("shenghang_jiashu") 
        lab:setString("+"..num)
    elseif symbolType == PBC.RTW_RUNDATA.baseSpinTime then
        --   ③增加2次spin次数
        _symbolNode:findChild("putong_lan"):setVisible(true)
        _symbolNode:findChild("cishu"):setVisible(true)
        local spinTime = 2
        if isLastNode and self.m_finalData.symbolType == PBC.RTW_RUNDATA.baseSpinTime then
            -- 需要用真实数据更新
            spinTime = self.m_finalData.triEff 
        end
        _symbolNode:findChild("spin"):setVisible(spinTime <= 1)
        _symbolNode:findChild("spins"):setVisible(spinTime > 1)
    elseif symbolType == PBC.RTW_RUNDATA.baseWinAll then
        --   ④棋盘上所有bonus结算一次
        _symbolNode:findChild("putong_zi"):setVisible(true)
        _symbolNode:findChild("winall"):setVisible(true)
    elseif symbolType == PBC.RTW_RUNDATA.baseJumpAll then
        --   ⑤棋盘上所有bonus金额上涨（涨0.5TB-2.5TB）
        local addCoinsMul = PBC.getRandomNorAddCoinsMul()
        if isLastNode and self.m_finalData.symbolType == PBC.RTW_RUNDATA.baseJumpAll then
            -- 需要用真实数据更新
            addCoinsMul = self.m_finalData.triEff 
        end

        if addCoinsMul <= 1.5 then
            _symbolNode:findChild("putong_lan"):setVisible(true)
        else
            _symbolNode:findChild("putong_zi"):setVisible(true)
        end
        _symbolNode:findChild("jiaqian"):setVisible(true)

        local coins = addCoinsMul * globalData.slotRunData:getCurTotalBet()
        local lab = _symbolNode:findChild("m_lb_coins") 
        lab:setString(util_formatCoinsLN(coins,3))
    elseif symbolType == PBC.RTW_RUNDATA.specMul then
        --   ①特殊格子对应的bonus2金额上涨为2倍、3倍或4倍
        _symbolNode:findChild("teshu_lan"):setVisible(true)
        _symbolNode:findChild("teshu_beishu"):setVisible(true)
        
        local mul = PBC.getRandomSpecMul()
        if isLastNode and self.m_finalData.symbolType == PBC.RTW_RUNDATA.specMul then
            -- 需要用真实数据更新
            mul = self.m_finalData.triEff 
        end
        local lab = _symbolNode:findChild("chengbeiSpc") 
        lab:setString("X"..mul)
    elseif symbolType == PBC.RTW_RUNDATA.specGrand then 
        --   ②特殊格子对应的bonus2金额变为GRAND
        _symbolNode:findChild("teshu_zi"):setVisible(true)
        _symbolNode:findChild("grand"):setVisible(true)
    elseif symbolType == PBC.RTW_RUNDATA.specMega then
        --   ④特殊格子对应的bonus2金额变为MEGA
        _symbolNode:findChild("teshu_zi"):setVisible(true)
        _symbolNode:findChild("mega"):setVisible(true)
    elseif symbolType == PBC.RTW_RUNDATA.specMajor then
        --   ⑤特殊格子对应的bonus2金额变为MAJOR
        _symbolNode:findChild("teshu_zi"):setVisible(true)
        _symbolNode:findChild("major"):setVisible(true)
    end


end

function JungleJauntRespinTopReel:initRunSymbolNode()
    self.m_reel_horizontal:initSymbolNode()
    self.m_reel_horizontal:updateRollNodePos(0)

    util_playFadeOutAction(self.m_reel_horizontal:getSymbolByRow(3), 1/30) 

end

--[[
    滚动流程
]]
function JungleJauntRespinTopReel:startMove()
    if self.m_initData.buffReelIndex == 2 then
        self.m_zLTX:setVisible(true) 
        util_spinePlay(self.m_zLTX,"start")
        util_spineEndCallFunc(self.m_zLTX,"start",function()
            util_spinePlay(self.m_zLTX,"idle",true)
        end) 
    end
    
    util_playFadeInAction(self.m_reel_horizontal:getSymbolByRow(3), 15/30) 

    self.m_runSound = gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_51)   

    self.m_reel_horizontal:startMove()
end



function JungleJauntRespinTopReel:stopMove(_finalData)
    self.m_finalData = _finalData
    --[[
        普通轮盘 or 特殊轮盘
        _finalData = {
            symbolType = PBC.RTW_RUNDATA, -- 触发类型
            triEff = 0, -- 触发效果
            nextFun    = fn,
        }
    ]]
    local lastReelData = self:getLastReelData(_finalData.symbolType)

    self.m_reel_horizontal:setSymbolList(lastReelData)
    self.m_reel_horizontal.m_needDeceler = true
    self.m_reel_horizontal.m_runTime = 0
end

function JungleJauntRespinTopReel:getLastReelData(_finalSymbol)
    local configData = self.m_machine.m_configData 
    local reelList   = configData:getReSpinBuffReelData(self.m_initData.buffReelIndex)

    --最终信号放在第三位
    local fnGetLastReelData = function(_startIndex)
        local data,reelIndex = {},_startIndex
        while true do
            local symbolType = reelList[reelIndex]
            if symbolType == _finalSymbol then
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, reelIndex-2))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, reelIndex-1))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, reelIndex))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, reelIndex+1))
                table.insert(data, self:getSymbolTypeByReelIndex(reelList, reelIndex+2))
                break
            end 
            reelIndex = reelIndex + 1
            if reelIndex > #reelList then
                reelIndex = 1
            end
        end
        return data
    end
    
    local data = fnGetLastReelData(math.random(1,#reelList))

    return data
end

function JungleJauntRespinTopReel:getSymbolTypeByReelIndex(_reelList, _reelIndex)
    if #_reelList < 1 then
       util_logDevAssert("getSymbolTypeByReelIndex !!!")
    end
    local reelIndex = _reelIndex
    if _reelIndex <= 0 then
        reelIndex = #_reelList + _reelIndex
    elseif _reelIndex > #_reelList then
        reelIndex = _reelIndex - #_reelList
    end

    return _reelList[reelIndex]
end


return JungleJauntRespinTopReel

