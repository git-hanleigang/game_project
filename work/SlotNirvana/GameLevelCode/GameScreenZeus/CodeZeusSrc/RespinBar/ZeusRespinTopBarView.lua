---
--xcyy
--2018年5月23日
--ZeusRespinTopBarView.lua

local ZeusRespinTopBarView = class("ZeusRespinTopBarView",util_require("base.BaseView"))


ZeusRespinTopBarView.m_GrandType = "Grand"
ZeusRespinTopBarView.m_MajorType = "Major"
ZeusRespinTopBarView.m_MinorType = "Minor"
ZeusRespinTopBarView.m_MiniType = "Mini"
ZeusRespinTopBarView.m_SilverType = nil

ZeusRespinTopBarView.m_SymbolSize = 130
ZeusRespinTopBarView.m_bigSymbolScale = 0.8


function ZeusRespinTopBarView:initUI(machine)

  

    self:createCsbNode("RespinView/Zeus_RespinTopBar.csb")
    
    self.m_machine = machine

    

    local actNode = util_createAnimation("RespinView/Zeus_RespinTopBar_0.csb")
    actNode:runCsbAction("idle",true)
    self:findChild("Node_2"):addChild(actNode)

    local actNode2 = util_createAnimation("RespinView/Zeus_RespinTopBar_2.csb")
    actNode2:runCsbAction("idle",true)
    self:findChild("Node_5"):addChild(actNode2)

    self:initRunSymbol( )

end


function ZeusRespinTopBarView:onEnter()
 

end


function ZeusRespinTopBarView:onExit()
 
end

--默认按钮监听回调
function ZeusRespinTopBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function ZeusRespinTopBarView:getRunSymbolCSbName( symbolType )

    if symbolType == self.m_GrandType  then
        return "Zeus_Coin_Gold_Grand"
    elseif symbolType == self.m_MajorType then
        return "Zeus_Coin_Gold_Major"
    elseif symbolType == self.m_MinorType then
        return "Zeus_Coin_Gold_Minor"
    elseif symbolType == self.m_MiniType then
        return "Zeus_Coin_Gold_Mini"
    else
        local lineBet = globalData.slotRunData:getCurTotalBet()
        return "Zeus_Coin_Silver",symbolType * lineBet
    end
end

function ZeusRespinTopBarView:getBigSymbolPos(index )

    local bigYSize = self.m_SymbolSize + 4

    return  cc.p((self.m_SymbolSize)/2,
                (bigYSize* self.m_bigSymbolScale ) * index - (bigYSize* self.m_bigSymbolScale ) / 2) 
end

function ZeusRespinTopBarView:initRunSymbol( )

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local rockets = selfdata.rockets

    self.m_bigSymbolList = {}
    for i=1,4 do
        local symbolType = i
        local csbName,coinsNum = self:getRunSymbolCSbName(rockets[i + 1])
        local symbol = util_createAnimation("RespinView/" .. csbName .. ".csb")
        self:findChild("big_panel"):addChild(symbol)
        table.insert( self.m_bigSymbolList, symbol )
        symbol:setScale(self.m_bigSymbolScale)
        symbol:setPosition(self:getBigSymbolPos(i ))

        if coinsNum then

            local lineBet = globalData.slotRunData:getCurTotalBet() or 1

            self.m_machine:findChildDealHightLowScore( symbol, coinsNum / lineBet )

            symbol:findChild("m_lb_score"):setString(util_formatCoins(coinsNum,3))
            symbol:findChild("m_lb_score_0"):setString(util_formatCoins(coinsNum,3))
        end
        
    end

    local csbSName,coinsSNum = self:getRunSymbolCSbName(rockets[1])
    self.m_smallSymbol = util_createAnimation("RespinView/" .. csbSName .. ".csb")
    self:findChild("small_panel"):addChild(self.m_smallSymbol)
    self.m_smallSymbol:setPosition(self.m_SymbolSize/2,self.m_SymbolSize/2)
    if coinsSNum then

        local lineBet = globalData.slotRunData:getCurTotalBet() or 1

        self.m_machine:findChildDealHightLowScore( self.m_smallSymbol, coinsSNum / lineBet )

        self.m_smallSymbol:findChild("m_lb_score"):setString(util_formatCoins(coinsSNum,3))
        self.m_smallSymbol:findChild("m_lb_score_0"):setString(util_formatCoins(coinsSNum,3))
    end

end
-- index 当前播放掉落位次
function ZeusRespinTopBarView:beginRunAct( func,index)
    

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local rockets = selfdata.rockets

    local time = 1
    
    for i=1,#self.m_bigSymbolList do
        local node = self.m_bigSymbolList[i]

        local endPos = self:getBigSymbolPos(i - 1 ).y
        self:runAct( node, time,endPos )
    end

    local smallSymbolEndPos = - self.m_SymbolSize/2
    self:runAct( self.m_smallSymbol  ,time,smallSymbolEndPos)
    
    
    -- 新创建的信号
    local csbBName,coinsBNum = self:getRunSymbolCSbName(rockets[index + 5])
    local newBigSymbol = util_createAnimation("RespinView/" .. csbBName .. ".csb")
    self:findChild("big_panel"):addChild(newBigSymbol)
    newBigSymbol:setScale(self.m_bigSymbolScale)
    newBigSymbol:setPosition(self:getBigSymbolPos(5 ))
    local newBigSymbolEndPos = self:getBigSymbolPos(4).y
    self:runAct( newBigSymbol  ,time,newBigSymbolEndPos)
    if coinsBNum then

        local lineBet = globalData.slotRunData:getCurTotalBet() or 1

        self.m_machine:findChildDealHightLowScore( newBigSymbol, coinsBNum / lineBet )

        newBigSymbol:findChild("m_lb_score"):setString(util_formatCoins(coinsBNum,3))
        newBigSymbol:findChild("m_lb_score_0"):setString(util_formatCoins(coinsBNum,3))
    end


    local newScsbName,newScoinsNum = self:getRunSymbolCSbName(rockets[index + 1])
    local newSmallSymbol = util_createAnimation("RespinView/" .. newScsbName .. ".csb")
    self:findChild("small_panel"):addChild(newSmallSymbol)
    newSmallSymbol:setPosition(self.m_SymbolSize/2,self.m_SymbolSize  + self.m_SymbolSize/2)
    local newSamllSymbolEndPos = self.m_SymbolSize/2
    self:runAct( newSmallSymbol  ,time,newSamllSymbolEndPos)
    if newScoinsNum then

        local lineBet = globalData.slotRunData:getCurTotalBet() or 1

        self.m_machine:findChildDealHightLowScore( newSmallSymbol, newScoinsNum / lineBet )

        newSmallSymbol:findChild("m_lb_score"):setString(util_formatCoins(newScoinsNum,3))
        newSmallSymbol:findChild("m_lb_score_0"):setString(util_formatCoins(newScoinsNum,3))
    end


    performWithDelay(self,function(  )

        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_respinbar_symbolDown.mp3")
        
        self.m_smallSymbol:removeFromParent()
        self.m_bigSymbolList[1]:removeFromParent()
        table.remove( self.m_bigSymbolList, 1 )
        table.insert( self.m_bigSymbolList, newBigSymbol )
        
        self.m_smallSymbol = newSmallSymbol

        if func then
            func()
        end
    end,time)


end

function ZeusRespinTopBarView:runAct( node,time,endPos )
    local actList = {}
    actList[#actList + 1] = cc.MoveTo:create(time,cc.p(self.m_SymbolSize/2,endPos))
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end


return ZeusRespinTopBarView