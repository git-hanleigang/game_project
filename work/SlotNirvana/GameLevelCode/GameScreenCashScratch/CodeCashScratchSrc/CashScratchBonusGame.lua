
local CashScratchBonusGame = class("CashScratchBonusGame", util_require("base.BaseGame"))


CashScratchBonusGame.ORDER = {
    MainCard = 100,
    NextCard = 50,
}


function CashScratchBonusGame:initDatas(_initData)
    self.m_machine  = _initData.machine
end

function CashScratchBonusGame:initUI()

    -- 下一张刮刮卡 (只在切换淡出时展示一下，不做过多的逻辑处理)
    self.m_nextCard = util_createView("CodeCashScratchSrc.CashScratchBonusGameCard", self.m_machine)
    self:addChild(self.m_nextCard, self.ORDER.NextCard)
    self.m_nextCard:findChild("Node_coatingSprite"):setVisible(true)
    self.m_nextCard:setVisible(false)

    -- 主要的刮刮卡 (处理主要的逻辑)
    self.m_mainCard = util_createView("CodeCashScratchSrc.CashScratchBonusGameCard", self.m_machine)
    self:addChild(self.m_mainCard, self.ORDER.MainCard)
    self.m_mainCard:initMainCardUi()
end


--[[
    _initData = {
        -- 主轮盘
        machine = machine,

        -- 当前卡片索引 = 总次数 - 剩余次数 + 1
        cardIndex = 1,

        -- 每张卡片的 坐标、卡片类型、赢钱、赢钱信号、9个icon
        cardData = {
            {
                cardIndex       = 1,
                iPos            = 0,
                symbolType      = 0,
                winCoin         = 0,
                winSymbolType   = {0}, 
                icon            = {0,0,0 ,0,0,0 ,0,0,0},
            },
        }

        -- 玩法结束回调
        overFun = function,     
    }
]]
function CashScratchBonusGame:setInitData(_initData)
    self.m_initData = _initData
end

-- 玩法开始
function CashScratchBonusGame:startBonusGame()
    local cardIndex = self.m_initData.cardIndex
    self:playNextCardShowAnim(cardIndex)
end
-- 玩法结束
function CashScratchBonusGame:endBonusGame()

    -- 延时0.5s 来确保不会出现 两个spine弹板交替出现的情况
    self.m_machine:levelPerformWithDelay(0.5, function()


        local beiginCoins,endCoins = self:getCardLastAndCurWinCoin() 
        -- 刷新赢钱检测大赢 和顶部玩家金币
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{endCoins, GameEffect.EFFECT_BONUS})
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,false,false,true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        

        --修改顶部高亮
        self.m_machine:hideTopScreenLight()

        -- 重置一下卡片数量
        self.m_machine:resetTopScreenAllCardCount(-1)

        self.m_machine:showCashScratchBonusOverView(endCoins, function()
            self.m_initData.overFun()
        end)
    end)

end


-- 出下一张卡片
function CashScratchBonusGame:playNextCardShowAnim(_cardIndex)
    local cardData = self.m_initData.cardData[_cardIndex]
    if not cardData then
        -- 玩法结束
        self:endBonusGame()
        return
    end
    self.m_initData.cardIndex = _cardIndex

    --修改右侧paytable展示
    self.m_machine:upDateRightPaytableByType(cardData.symbolType)
    --修改顶部高亮
    self.m_machine:showTopScreenLight(cardData.symbolType)
    --重置一下 主刮刮卡的数据,和初始化展示 
    self.m_mainCard:initCardData(cardData)
    -- 刷新 最大赢钱
    local nextCardData = self.m_initData.cardData[_cardIndex+1]
    if nextCardData then
        self.m_nextCard:updateMaxWinCoins(nextCardData)
    end
    

    -- 开始刮卡
    self.m_mainCard:startCardGame(function()

        -- 淡出
        self:playCardFadeOutAnim(_cardIndex + 1, function()

            gLobalNoticManager:postNotification("CashScratch_bonusCardOver",{cardData.symbolType})


            self:playNextCardShowAnim(_cardIndex + 1)
        end)

    end)
end
function CashScratchBonusGame:playCardFadeOutAnim(_cardIndex, _fun)
    local cardData = self.m_initData.cardData[_cardIndex]
    if not cardData then
        if _fun then
            _fun()
        end
        return
    end

    self.m_nextCard:changeCardByType(cardData.symbolType)
    self.m_nextCard:setVisible(true)

    gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusGame_cardOver.mp3")

    self.m_mainCard:runCsbAction("over", false, function()
        self.m_mainCard:pauseForIndex(0)
        self.m_mainCard:updateMaxWinCoins(cardData)

        if _fun then
            _fun()
        end
        self.m_nextCard:setVisible(false)
    end)

    --切掉连线展示的 高亮格子、遮罩、paytable
    self.m_mainCard:hideLineAnim()
end

--[[
    数据接收
]]
function CashScratchBonusGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local result = spinData.result

        local userMoneyInfo = param[3]
        globalData.userRate:pushCoins(result.winAmount)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        -- print(cjson.encode(param))
        if spinData.action == "FEATURE" then
            -- 只解析bonus就行
            if spinData.result and spinData.result.bonus then
                local runSpinResultData = self.m_machine.m_runSpinResultData
                runSpinResultData.p_bonusExtra = spinData.result.bonus.extra
            end

            -- 记录下服务器返回赢钱的结果
            self.m_serverWinCoins = result.bonus.bsWinCoins 
            self.m_mainCard:recvBaseData(result)
        end
    end
end
--[[
    工具接口
]]
-- 获取上一次刮卡累计的金额 和 当前卡片刮完累计的金额
function CashScratchBonusGame:getCardLastAndCurWinCoin()
    local lastWinCoin = 0
    local curWinCoin  = 0

    local curIndex = self.m_initData.cardIndex
    for _index,_cardData in ipairs(self.m_initData.cardData) do
        curWinCoin = curWinCoin + _cardData.winCoin

        if _index == curIndex then
            break
        end

        lastWinCoin = lastWinCoin + _cardData.winCoin
    end

    return lastWinCoin,curWinCoin
end

-- 获取指定卡片的赢钱
function CashScratchBonusGame:getCardWinCoins(_cardIndex)
    local winCoins = 0

    local cardIndex = _cardIndex or self.m_initData.cardIndex
    if self.m_initData.cardData[cardIndex] then
        winCoins = self.m_initData.cardData[cardIndex].winCoin
    end
    
    return winCoins
end

return CashScratchBonusGame
