---
--xcyy
--2018年5月23日
--RoaringKingLionHead.lua

local RoaringKingLionHead = class("RoaringKingLionHead",util_require("Levels.BaseLevelDialog"))

RoaringKingLionHead.m_showNum = 0
RoaringKingLionHead.m_showStates = 1 -- 1:1行   2:2行
function RoaringKingLionHead:initUI(_machine)

    self:createCsbNode("RoaringKing_shizitou.csb")

    self.m_lionHeadSpine = util_spineCreate("RoaringKing_shizi",true,true)
    self:findChild("Node_shizi"):addChild(self.m_lionHeadSpine)
    
    self.m_machine = _machine
    self.m_tishiNode = cc.Node:create()
    self:addChild(self.m_tishiNode)
    self.m_showStates = 1
    self:changeUI( )
end

function RoaringKingLionHead:resetLabNum( )

    local leftNumTop = self:findChild("m_lb_num_top")
    local leftNumDown = self:findChild("m_lb_num_down")
    leftNumTop:setString(0)
    leftNumDown:setString(0)
end

function RoaringKingLionHead:updateLab(_coinsList )


    local totalNumTop = self:findChild("m_lb_num_0_top")
    local leftNumTop = self:findChild("m_lb_num_top")
    local repCoinsTop = self:findChild("m_lb_coins_top")

    local totalNumDown = self:findChild("m_lb_num_0_down")
    local leftNumDown = self:findChild("m_lb_num_down")
    local repCoinsDown = self:findChild("m_lb_coins_down")

    if #_coinsList == 1 then
        local coins = _coinsList[1] * globalData.slotRunData:getCurTotalBet()
        repCoinsTop:setString(util_formatCoins(coins,3))
    elseif #_coinsList > 1 then
        local coins = _coinsList[1] * globalData.slotRunData:getCurTotalBet()
        repCoinsTop:setString(util_formatCoins(coins,3))
        local coins2 = _coinsList[2] * globalData.slotRunData:getCurTotalBet()
        repCoinsDown:setString(util_formatCoins(coins2,3))
    end

    local freeSpinsLeftCount = self.m_machine.m_runSpinResultData.p_freeSpinsLeftCount
    local freeSpinsTotalCount = self.m_machine.m_runSpinResultData.p_freeSpinsTotalCount
    local fsExtra = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local repeatWinList = fsExtra.repeatWinList or {}

    local leftFsCount = 0
    
    if globalData.slotRunData.freeSpinCount > freeSpinsTotalCount then
        leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
        leftFsCount = leftFsCount%10
        if leftFsCount == 0 then
            leftFsCount = 10
        end
    else
        leftFsCount = freeSpinsTotalCount - globalData.slotRunData.freeSpinCount
        if leftFsCount == 0 and #repeatWinList > 1  then
            leftFsCount = 10
        end
    end
    leftNumTop:setString(leftFsCount)
    leftNumDown:setString(0)
end

function RoaringKingLionHead:updateNodeShowIdle( _coinsList )
    self.m_showNum = #_coinsList
    if #_coinsList == 1 then
        self.m_showStates = 1
        self:runCsbAction("idle2",true)
    elseif #_coinsList > 1 then
        self.m_showStates = 2
        self:runCsbAction("idle3",true)
    end
end

function RoaringKingLionHead:updateNodeShow( _coinsList )

    self.m_tishiNode:stopAllActions()

    if self.m_showNum < #_coinsList then
        if #_coinsList == 1 then
            self:runCsbAction("actionframe")
        elseif #_coinsList == 2 then
            self:runCsbAction("actionframe1")
            performWithDelay(self.m_tishiNode,function(  )
                self:runCsbAction("tishi")
                performWithDelay(self.m_tishiNode,function(  )
                    self.m_showStates = 2
                    self:runCsbAction("idle3",true)
                end,42/60)
            end,21/60)
        end
    elseif self.m_showNum > #_coinsList then
        if #_coinsList == 1 then
            self.m_showStates = 1
            self:runCsbAction("idle2",true)
        end
    end
    
    self.m_showNum = #_coinsList
end

function RoaringKingLionHead:playFsTriggerAnim( )
    self:runCsbAction("actionframe",false,function(  )
        self.m_showStates = 1
        self:runCsbAction("idle2",true)
    end)
    util_spinePlay(self.m_lionHeadSpine,"actionframe",false)
    util_spineEndCallFunc(self.m_lionHeadSpine,"actionframe",function(  )
        util_spinePlay(self.m_lionHeadSpine,"idle2",true)
    end)
end

function RoaringKingLionHead:changeUI(_isFree )
    if _isFree then
        util_spinePlay(self.m_lionHeadSpine,"idle2",true)
    else
        self:resetLabNum( )
        util_spinePlay(self.m_lionHeadSpine,"idle",true)
        self:runCsbAction("idle",true)
        self.m_showNum = 0
    end
end


return RoaringKingLionHead