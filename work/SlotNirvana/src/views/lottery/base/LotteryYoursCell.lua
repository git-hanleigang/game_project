--[[
Author: your name
Date: 2021-11-19 17:30:08
LastEditTime: 2021-11-19 17:30:10
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/base/LotteryYoursCell.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryYoursCell = class("LotteryYoursCell", BaseView)

function LotteryYoursCell:updateUI(_idx, _numberListStr)
    self.m_numberList = string.split(_numberListStr, "-")
    self.m_order = _idx or 1
    --取出当前lottery头奖数据
    self.m_lotteryData = G_GetMgr(G_REF.Lottery):getData()
    self.m_isGrand = self:checkTotalWin()
    self:updateView()
    self:checkCsbActionExists()
    self:runCsbAction("idle")
end

function LotteryYoursCell:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_Yoursnum.csb"
end

function LotteryYoursCell:updateView()
    for idx, number in pairs(self.m_numberList) do
        local parent = self:findChild("node_ball_" .. idx)

        if not tolua.isnull(parent) then
            local item = parent:getChildByName("node_show_ball")
            if not item then
                item = self:createBallItem(number, idx == #self.m_numberList)
                parent:addChild(item)
                util_setCascadeOpacityEnabledRescursion(parent, true)
            end
            item:updateNumberUI(number)
            item:playIdleAct()
        end

    end
end

function LotteryYoursCell:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_show_ball")
    return view
end

function LotteryYoursCell:playWinCoinAct(_coins, _bIdle, _overFunc)
    _coins = tonumber(_coins) or 0
    if _coins <= 0  then
        return
    end
    self:checkCsbActionExists()
    
    --处理自己是否中头奖
    
    local lbCoins = self:findChild("lb_coin")
    
    if self.m_isGrand then
        lbCoins:setString("GRAND")
    else 
        lbCoins:setString(util_formatCoins(_coins, 20))
        util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 290, 0.75)
    end

    local actName = "actionframe"
    if _bIdle then
        actName = "showCoinsIdle"
    end
    self:runCsbAction(actName, false, _overFunc, 60)
end
--检测自己是否中了头奖
function LotteryYoursCell:checkTotalWin()
    local totalWinList = self.m_lotteryData:getHitNumberList()
    local myNumList = {}
    local totalNumList = {}
    for i,v in ipairs(totalWinList) do
        local num = tonumber(v)
        table.insert( totalNumList, num )
    end
    for i,v in ipairs(self.m_numberList) do
        local num = tonumber(v)
        table.insert(myNumList,num)
    end
    
    if #totalNumList ~= #myNumList then
        return false
    end

    local index = 0
    --头奖最后一个号码
    local totalBigWinNum = totalNumList[#totalNumList]
    --自己选的号最后一个号码
    local myBigWinNum = myNumList[#myNumList]
    if totalBigWinNum == myBigWinNum then
        index = index + 1  
    end
    for i = 1, #totalNumList - 1 do
        for j = 1, #myNumList - 1 do
            if totalNumList[i] == myNumList[j] then
                index = index + 1
            end
        end
    end

    if index == #totalNumList then
        return true
    else
        return false
    end

end

function LotteryYoursCell:playNumberSweepAct(_actNumberList)
    -- white 
    for i=1, 5 do
        local whiteNumber = _actNumberList[i]
        if not whiteNumber then
            return
        end
        self:playBallSweepActByNumber(whiteNumber)
    end

    -- red
    local redNumber = _actNumberList[6]
    if not redNumber then
        return
    end
    self:playBallSweepActByNumber(redNumber, true)
end

function LotteryYoursCell:playBallSweepActByNumber(_number, _bRed)
    local startIdx, endIdx = 1, 5
    if _bRed then
        startIdx, endIdx = 6, 6
    end

    for idx = startIdx, endIdx do

        local parent = self:findChild("node_ball_" .. idx)

        if not tolua.isnull(parent) then

            local item = parent:getChildByName("node_show_ball")
            local ballShowNumber = self.m_numberList[idx]
            if item and tonumber(_number) == tonumber(ballShowNumber) then
                item:playSweepAct(true)
            end

        end
    end

end

function LotteryYoursCell:checkCsbActionExists()
    if tolua.isnull(self.m_csbAct) then
        self.m_csbAct = util_actCreate(self:getCsbName())
        if self.m_csbAct and self.m_csbNode then
            self.m_csbNode:runAction(self.m_csbAct)
        end
    end
end

function LotteryYoursCell:getCurOrder()
    return self.m_order
end

return LotteryYoursCell