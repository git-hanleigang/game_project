-- 鱼跃龙门底栏-处理spin按钮点击跳过流程
local BingoldKoiBottomNode = class("BingoldKoiBottomNode", util_require("views.gameviews.GameBottomNode"))

function BingoldKoiBottomNode:initUI(...)
    BingoldKoiBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBonusBtn = util_createView("CodeBingoldKoiSrc.BingoldKoiSkipSpinBtn")
        spinParent:addChild(self.m_skipBonusBtn, order)
        self.m_skipBonusBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBonusBtn:setBingoldKoiMachine(self.m_machine)
        self:setSkipBonusBtnVisible(false)
    end
end

function BingoldKoiBottomNode:setSkipBonusBtnVisible(_vis)
    if nil ~= self.m_skipBonusBtn then
        self.m_skipBonusBtn:setVisible(_vis)
    end
end

function BingoldKoiBottomNode:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end
    if self.m_machine.collectBingo then
        showTime = 0.6
    end
    return showTime
end

--获取当前Bet序号
function BingoldKoiBottomNode:getBetIndexById(betId)
    local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == betId then
            return i
        end
    end

    return 1
end


--[[
    切换至高bet
]]
function BingoldKoiBottomNode:changeBetCoinNumToUnLock()
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betId = specialBets[1].p_betId
    if globalData.slotRunData:getCurBetIndex() >= self:getBetIndexById(betId) then
        return
    end
    globalData.slotRunData.iLastBetIdx = betId
    self:postPiggy("add", betId)
    self:updateBetCoin()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AdjustBetBig)
    end
    globalNoviceGuideManager:removeNewPop(GUIDE_LEVEL_POP.MaxBet)
    if globalNoviceGuideManager.guideBubbleAddBetPopup then
        globalNoviceGuideManager.guideBubbleAddBetPopup = nil
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("guideBubbleAddBetClick", false)
        end
    end

    self:checkShowBaseTips()
    self:showBetTipsView()
    self:addCardBetChip()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE)
    gLobalSendDataManager:getLogSlots():setGameBet()
end

function BingoldKoiBottomNode:createCoinWinEffectUI()
    if self.coinBottomEffectNode ~= nil then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
    end
    if self.coinWinNode ~= nil then
        local effectCsbName = nil
        if globalData.slotRunData.isPortrait == true then
            effectCsbName = "GameNode/GameBottomNodePortrait_jiesuan.csb"
        else
            effectCsbName = "GameNode/GameBottomNode_jiesuan.csb"
        end
        if effectCsbName ~= nil then
            local coinBottomEffectNode = util_createAnimation(effectCsbName)
            self.coinBottomEffectNode = coinBottomEffectNode
            self.coinWinNode:addChild(coinBottomEffectNode)
            coinBottomEffectNode:setVisible(false)
        end
    end
end

-- 修改已创建的收集反馈效果
function BingoldKoiBottomNode:changeCoinWinEffectUI(_levelName, _csbName)
    if nil ~= self.coinBottomEffectNode and nil ~= _csbName then
        local csbPath = ""
        --找关卡资源
        csbPath = string.format("GameScreen%s/%s", _levelName, _csbName)
        if CCFileUtils:sharedFileUtils():isFileExist(csbPath) then
            self.coinBottomEffectNode:removeFromParent()
            self.coinBottomEffectNode = nil
            self.coinBottomEffectNode = util_createAnimation(csbPath)
            self.coinWinNode:addChild(self.coinBottomEffectNode)
            self.coinBottomEffectNode:setVisible(false)
            return
        end
        --找系统资源
        csbPath = string.format("GameNode/%s", _csbName)
        if CCFileUtils:sharedFileUtils():isFileExist(csbPath) then
            self.coinBottomEffectNode:removeFromParent()
            self.coinBottomEffectNode = nil
            self.coinBottomEffectNode = util_createAnimation(csbPath)
            self.coinWinNode:addChild(self.coinBottomEffectNode)
            self.coinBottomEffectNode:setVisible(false)
            return
        end
    --不修改,使用默认创建好的资源工程
    end
end

function BingoldKoiBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        coinBottomEffectNode:runCsbAction("actionframe",false,function()
            -- coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

function BingoldKoiBottomNode:getSpinUINode()
    return "CodeBingoldKoiSrc.BingoldKoiSpinBtn"
end

return BingoldKoiBottomNode
