--[[
    集齐界面
]]

local BaseView = util_require("base.BaseView")
local PageCompleteRewardUI = class("PageCompleteRewardUI", BaseView)

function PageCompleteRewardUI:initUI(pageIndex, overCall, isOuterComplete)
    local maskUI = util_newMaskLayer()
    self:addChild(maskUI,-1)
    maskUI:setOpacity(192)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(CardResConfig.PuzzlePageCompleteRewardRes, isAutoScale)

    self.m_pageIndex = pageIndex
    self.m_overCall = overCall
    self.m_isOuterComplete = isOuterComplete

    self.m_coinLB = self:findChild("lb_coinNum")
    self.m_coinLB:setString("")
    self.m_chipNode = self:findChild("node_chip")

    self.m_collectBtn = self:findChild("btn_collectNow")
    self.m_collectBtn:setTouchEnabled(false)
    self.m_collectBtn:setBright(false)

    self:initView()
    self.m_start = true
    self:runCsbAction("start", false, function()
        self.m_start = false
        self:runCsbAction("idle", true)
    end)
end

function PageCompleteRewardUI:initView()
    self:initCoins()
    self:initItems()
end

function PageCompleteRewardUI:closeUI(closeCall)
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:runCsbAction("over", false, function()
        if closeCall then
            closeCall()
        end
        self:removeFromParent()
    end)
end

function PageCompleteRewardUI:canClick()
    if self.m_start then
        return false
    end
    if self.m_closed then
        return false
    end

    if self.m_startFly then
        return false
    end

    return true
end

function PageCompleteRewardUI:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end
    if name == "btn_collectNow" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:flyCoins()
    end
end

function PageCompleteRewardUI:flyCoins()
    self.m_startFly = true
    local data = CardSysRuntimeMgr:getPuzzleGameData()

    local rewardCoins = 0
    if data and data.puzzleReward and data.puzzleReward[1] and data.puzzleReward[1].coins then
        rewardCoins = data.puzzleReward[1].coins
    end
    -- -- 将掉落加入掉落队列，等最后关闭的时候，统一调用展示
    -- if data and data.puzzleReward and data.puzzleReward[1] and data.puzzleReward[1].cardDrops and #data.puzzleReward[1].cardDrops > 0 then
    --     CardSysManager:doDropCardsData(data.puzzleReward[1].cardDrops)
    -- end

    if rewardCoins > 0 then
        if self.m_isOuterComplete then
            -- 外部完成时，玩家身上的金币已经被同步过了
        else
            -- 集卡内部请求接口，服务器没有同步金币，需要手动添加
            globalData.userRunData:setCoins(globalData.userRunData.coinNum + rewardCoins)
        end
        local startPos = self.m_coinLB:getParent():convertToWorldSpace(cc.p(self.m_coinLB:getPosition()))    
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        gLobalViewManager:pubPlayFlyCoin( startPos,endPos,baseCoins,rewardCoins,function()
            self.m_startFly = false
            CardSysManager:getPuzzleGameMgr():closePageCompleteRewardUI(self.m_overCall)
        end)
    else
        self.m_startFly = false
        CardSysManager:getPuzzleGameMgr():closePageCompleteRewardUI(self.m_overCall)
    end


end

function PageCompleteRewardUI:initCoins()
    local data = CardSysRuntimeMgr:getPuzzleGameData()

    local coins = 0
    if data and data.puzzleReward and data.puzzleReward[1] and data.puzzleReward[1].coins > 0 then
        coins = data.puzzleReward[1].coins
    end

    if coins > 0 then
        local startValue = coins/20
        local endValue = coins
        local addValue = coins/20
    
        self.m_coinjumpSound = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.RecoverWheelCoinRaise2, true)
        util_jumpNum(self.m_coinLB, startValue, endValue, addValue, 0.05 , {30}, nil, nil, function()
            if self.m_coinjumpSound then
                gLobalSoundManager:stopAudio(self.m_coinjumpSound)
                self.m_coinjumpSound = nil
            end
            self.m_collectBtn:setTouchEnabled(true)
            self.m_collectBtn:setBright(true)            
        end)
    else
        self.m_collectBtn:setTouchEnabled(true)
        self.m_collectBtn:setBright(true)        
    end
end

function PageCompleteRewardUI:initItems()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local puzzleReward = data and data.puzzleReward
    if not puzzleReward then
        return
    end

    local path = string.format("CardRes/season201904/CashPuzzle/img/Common/CashPuzzle_RewardIcon_%d.png", self.m_pageIndex)
    local _sprite = util_createSprite(path)
    self.m_chipNode:addChild(_sprite)

end

return PageCompleteRewardUI