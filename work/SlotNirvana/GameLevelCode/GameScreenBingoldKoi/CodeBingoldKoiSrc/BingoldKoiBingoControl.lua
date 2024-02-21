---
--xcyy
--2018年5月23日
--BingoldKoiBingoControl.lua

--右侧bingo轮盘

local BingoldKoiBingoControl = class("BingoldKoiBingoControl")

local MID_ORDER = 1000      --中间位置层级
local COINS_ORDER = 1200    --字体位置层级
local MASK_ORDER = 1500     --遮罩层级
local TOP_TRIGGER_ORDER = 2000     --顶部新加触发层级

local ENUM_BONUS_TYPE = {
    NORMAL = 0,
    COINS = 1,
    JACKPOT = 2,
    DOUBLE = 3,
}

local COIN_MUL = 5

function BingoldKoiBingoControl:ctor(params)
    self.m_machine = params.machine
    
    --创建25个bonus动画加在reel条的父节点上,方便控制层级
    local parentNode = self.m_machine:findChild("sp_reel_bingo")
    local reelNode = self.m_machine:findChild("sp_reel_bingo_1")
    local reelPos = cc.p(reelNode:getPosition())
    local reelSize = reelNode:getContentSize()
    local slotWidth = reelSize.width
    local slotHeight = reelSize.height / self.m_machine.m_iReelRowNum
    --满线的配置
    self.m_allLineData = {
        [1] = {0, 5, 10, 15, 20},
        [2] = {1, 6, 11, 16, 21},
        [3] = {2, 7, 12, 17, 22},
        [4] = {3, 8, 13, 18, 23},
        [5] = {4, 9, 14, 19, 24},
        [6] = {0, 1, 2, 3, 4},
        [7] = {5, 6, 7, 8, 9},
        [8] = {10, 11, 12, 13, 14},
        [9] = {15, 16, 17, 18, 19},
        [10] = {20, 21, 22, 23, 24},
        [11] = {0, 6, 12, 18, 24},
        [12] = {4, 8, 12, 16, 20},
    }
    self.m_curBingoReels = {}     --当前bingo盘上已存在的bonus
    self.m_bonusImgs = {}         --创建bonus精灵，静帧时替换bonus-spine动画，降低GLCall
    self.m_bonusAnis = {}         --bonus上的字体动画，预先创建好
    self.m_bonusSpines = {}       --bonus-spine动画，预先创建好
    self.m_bonusAnisType = {}     --本地存储字体得类型，方便替换时间线和字体使用
    self.m_bonusLineAnis = {}     --提示框，即将连线时提示作用
    self.m_bonusTriggerAnis = {}  --触发时跟触发动画一起播放，层级在最顶层
    self.m_bonusCollectAnis = {}  --收集是在bonus下面的特效，层级在bonus下面
    self.m_bonusCollectTopAnis = {}  --收集是在bonus上面的特效，层级在bonus上面，和下面那个同时播放（很诡异，动画要求明显）
    --遮罩直接加到右边node上，省去了重复创建，控制层级
    self.darkMask = util_createAnimation("BingoldKoi_darkRight.csb")
    parentNode:addChild(self.darkMask)
    self.darkMask:setLocalZOrder(MASK_ORDER)
    self.darkMask:setVisible(false)

    for iRow = 1,self.m_machine.m_iReelRowNum do
        self.m_bonusImgs[iRow] = {}
        self.m_bonusAnis[iRow] = {}
        self.m_bonusSpines[iRow] = {}
        self.m_bonusAnisType[iRow] = {}
        self.m_bonusLineAnis[iRow] = {}
        self.m_bonusTriggerAnis[iRow] = {}
        self.m_bonusCollectAnis[iRow] = {}
        self.m_bonusCollectTopAnis[iRow] = {}
        for iCol = 1,self.m_machine.m_iReelColumnNum do
            local bonusAni, bonusSpine, bonusLineAni, bonusTriggerAni, bonusCollectAni, bonusCollectTopAni
            local zOrder = self:getBonusNormalZorder(iCol, iRow)
            local coinsZorder = self:getRightBonusCoinsZorder(iCol, iRow)
            --最中间的特殊处理
            local bonusImg = util_createSprite("BingoldKoiSymbol/BingoldKoi_Bingobonus.png")
            bonusImg:setScale(0.5)
            bonusAni = util_createAnimation("Socre_BingoldKoi_RightBingoBonus.csb")
            bonusSpine = util_spineCreate("Socre_BingoldKoi_BingoBonus",true,true)
            bonusLineAni = util_createAnimation("WinFrameBingoldKoi_tishikuang.csb")
            bonusTriggerAni = util_createAnimation("BingoldKoi_bingo_chufa.csb")
            bonusCollectAni = util_createAnimation("BingoldKoi_bingo_kuang.csb")
            bonusCollectTopAni = util_createAnimation("BingoldKoi_bingo_kuang_s.csb")
            util_spinePlay(bonusSpine,"idleframe",true)
            bonusAni.m_isMidBonus = false
            bonusSpine:setVisible(false)
            if iCol == 3 and iRow == 3 then
                bonusAni.m_isMidBonus = true
                zOrder = MID_ORDER
                coinsZorder = 1
            end
            self.m_bonusImgs[iRow][iCol] = bonusImg
            self.m_bonusAnis[iRow][iCol] = bonusAni
            self.m_bonusSpines[iRow][iCol] = bonusSpine
            self.m_bonusLineAnis[iRow][iCol] = bonusLineAni
            self.m_bonusTriggerAnis[iRow][iCol] = bonusTriggerAni
            self.m_bonusCollectAnis[iRow][iCol] = bonusCollectAni
            self.m_bonusCollectTopAnis[iRow][iCol] = bonusCollectTopAni
            bonusLineAni:setVisible(false)
            bonusTriggerAni:setVisible(false)
            bonusCollectAni:setVisible(false)
            bonusCollectTopAni:setVisible(false)

            self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.NORMAL

            bonusSpine.colIndex = iCol
            bonusSpine.rowIndex = iRow

            parentNode:addChild(bonusSpine)
            parentNode:addChild(bonusLineAni)
            parentNode:addChild(bonusAni)
            parentNode:addChild(bonusImg)
            parentNode:addChild(bonusTriggerAni)
            parentNode:addChild(bonusCollectAni)
            parentNode:addChild(bonusCollectTopAni)
            
            self:refreshBonusCoins(bonusAni, 0, 0)
            local curReel = self.m_machine:findChild("sp_reel_bingo_"..iCol)

            local posX = curReel:getPositionX() + 0.5 * slotWidth 
            local posY = curReel:getPositionY() + (iRow - 0.5) * slotHeight
            bonusImg:setPosition(cc.p(posX,posY))
            bonusSpine:setPosition(cc.p(posX,posY))
            bonusLineAni:setPosition(cc.p(posX,posY))
            bonusAni:setPosition(cc.p(posX,posY))
            bonusTriggerAni:setPosition(cc.p(posX,posY))
            bonusCollectAni:setPosition(cc.p(posX,posY))
            bonusCollectTopAni:setPosition(cc.p(posX,posY))
            --设置层级
            bonusImg:setLocalZOrder(zOrder)
            bonusSpine:setLocalZOrder(zOrder)
            bonusAni:setLocalZOrder(coinsZorder)
            bonusLineAni:setLocalZOrder(MASK_ORDER-10)
            bonusTriggerAni:setLocalZOrder(zOrder-1)
            bonusCollectTopAni:setLocalZOrder(TOP_TRIGGER_ORDER+1)

            if not bonusAni.m_isMidBonus then
                bonusAni:findChild("money"):setVisible(false)
                bonusAni:findChild("jackpot"):setVisible(false)
                bonusAni:findChild("double"):setVisible(false)
            end
            
        end  
    end

    --创建一个中间的
    self.m_midBonus = util_spineCreate("Socre_BingoldKoi_Bonus",true,true)
    util_spinePlay(self.m_midBonus,"idleframe",true)
    local midReel = self.m_machine:findChild("sp_reel_bingo_"..3)

    self.m_midCoins = util_createAnimation("Socre_BingoldKoi_MidBingoCoins.csb")
    util_spinePushBindNode(self.m_midBonus,"wenzi",self.m_midCoins)
    -- self.m_midBonus:addChild(self.m_midCoins)
    self.m_midCoins:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_midBonus,true)

    local posX = midReel:getPositionX() + 0.5 * slotWidth 
    local posY = midReel:getPositionY() + 2.5 * slotHeight
    self.m_midBonus:setPosition(cc.p(posX,posY))
    --设置层级
    self.m_midBonus:setLocalZOrder(MID_ORDER + 1)
    parentNode:addChild(self.m_midBonus)
end

--刷新即将连线的标识（只存在于super里，特殊判断）
function BingoldKoiBingoControl:refreshRightBingoLight()
    local bingoData = self.m_machine.m_superBingoData or {}
    if bingoData.bingoPositions and #bingoData.bingoPositions > 0 then
        self.m_bingoPositions = bingoData.bingoPositions
        self:refreshTipLight(bingoData.bingoPositions)
    end
end

--[[
    刷新bingo盘面
]]
function BingoldKoiBingoControl:refreshBingoReel(bonusCoins, isUseBonusData, isPlayLine, isOnEnter, isCutBet)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_isSuperFree and self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet
    end
    local betData = self.m_machine.m_betData
    local bingoData = {}
    if betData[tostring(toLongNumber(lineBet))] then
        bingoData = betData[tostring(toLongNumber(lineBet))]
    end

    if self.m_machine.m_isSuperFree then
        bingoData = self.m_machine.m_superBingoData or {}
    end

    local bingoReels = bingoData.bingoReels or {}
    if bingoData.oldBingoReels and not isCutBet then
        bingoReels = bingoData.oldBingoReels
    end

    self.m_curBingoReels = bingoReels

    --先隐藏所有的图标
    if not bonusCoins then
        for iRow = 1,self.m_machine.m_iReelRowNum do
            for iCol = 1,self.m_machine.m_iReelColumnNum do
                self.m_bonusImgs[iRow][iCol]:setVisible(false)
                self.m_bonusSpines[iRow][iCol]:setVisible(false)
                self.m_bonusAnis[iRow][iCol]:setVisible(false)
            end
        end
    else
        --判断是否直接用bonusData数据
        if isUseBonusData then
            bingoReels = bonusCoins
        else
            local tempBingoReels = {}
            for i=1, #bingoReels do
                local pos = bingoReels[i].loc
                for j=1, #bonusCoins do
                    if pos == bonusCoins[j].loc then
                        tempBingoReels[#tempBingoReels+1] = bingoReels[i]
                    end
                end
            end
            bingoReels = tempBingoReels
        end
    end

    --最中间的小块要一直显示
    self.m_midBonus:setVisible(true)
    self.m_bingoPositions = bingoData.bingoPositions
    -- self:refreshTipLight(bingoData.bingoPositions)
    if isPlayLine then
        local delayTime = 0
        if not isOnEnter then
            -- delayTime = 40/60
            delayTime = 5/60
        end
        performWithDelay(self.m_machine.m_scWaitNode, function()
            self:refreshTipLight(bingoData.bingoPositions)
        end, delayTime)
    end
    
    local isIdleRun = false
    if bonusCoins then
        for i,data in ipairs(bonusCoins) do
            local posData = self.m_machine:getRowAndColByPos(data.loc)
            local iCol,iRow = posData.iY,posData.iX
            local rightType = self.m_bonusAnisType[iRow][iCol]
            if rightType ~= ENUM_BONUS_TYPE.NORMAL then
                isIdleRun = true
                break
            end
        end
    end

    --刷新bonus图标
    for i,data in ipairs(bingoReels) do
        local posData = self.m_machine:getRowAndColByPos(data.loc)
        local iCol,iRow = posData.iY,posData.iX
        local ani = self.m_bonusAnis[iRow][iCol]
        local bonusSpine = self.m_bonusSpines[iRow][iCol]
        local bonusImg = self.m_bonusImgs[iRow][iCol]
        --刷新图标显示
        self:updateBonusCoins(bonusSpine, bonusImg, ani, data, posData, isIdleRun, isOnEnter)
    end
end

--[[
    刷新bonus上钱数显示
]]
function BingoldKoiBingoControl:updateBonusCoins(bonusSpine, bonusImg, aniNode, data, posData, isIdleRun, isOnEnter)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_isSuperFree and self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet
    end

    local iCol,iRow = posData.iY,posData.iX
    local ani = self.m_bonusAnis[iRow][iCol]
    local lastType = self.m_bonusAnisType[iRow][iCol]

    --中间的在转轮后会变为普通小块
    if data.loc == 12 then
        if data.kind ~= "wild" then
            self.m_midCoins:setVisible(true)
            util_spinePlay(self.m_midBonus,"idleframe2",true)
            self.m_midCoins:findChild("m_lb_coins"):setVisible(data.kind == "normal")
            self.m_midCoins:findChild("mini"):setVisible(data.kind == "mini")
            self.m_midCoins:findChild("minor"):setVisible(data.kind == "minor")
            self.m_midCoins:findChild("major"):setVisible(data.kind == "major")
            self.m_midCoins:findChild("mega"):setVisible(data.kind == "mega")
            self.m_midCoins:findChild("grand"):setVisible(data.kind == "grand")
        end
    else
        util_spinePlay(bonusSpine,"idleframe",true)
        bonusSpine:setVisible(false)
        bonusImg:setVisible(true)
        aniNode:setVisible(true)
    end

    local curBonusType = ENUM_BONUS_TYPE.NORMAL
    if data.kind ~= "wild" then
        local isJackpot = self.m_machine:isJackpotSymbol(data.kind)
        --计算钱数
        local multi = data.coins or 0
        local coins = multi * lineBet
        coins = util_formatCoins(coins, 3)
        if isJackpot and multi > 0 then
            curBonusType = ENUM_BONUS_TYPE.DOUBLE
        elseif isJackpot then
            curBonusType = ENUM_BONUS_TYPE.JACKPOT
        elseif multi > 0 then
            curBonusType = ENUM_BONUS_TYPE.COINS
        end

        local isRefresh = true
        local label1 = aniNode:findChild("m_lb_coins_1")
        if label1 then
            local lastCoins = label1:getString()
            if lastCoins ~= coins or lastType ~= curBonusType then
                -- isRefresh = true
            end
        end

        --中间的bonus钱数赋值
        if data.loc == 12 and not isJackpot then
            if multi >= COIN_MUL then
                self.m_midCoins:findChild("m_lb_coins"):setFntFile("BingoldKoiFont/BingoldKoi_font11.fnt")
            else
                self.m_midCoins:findChild("m_lb_coins"):setFntFile("BingoldKoiFont/BingoldKoi_font8.fnt")
            end
            self.m_midCoins:findChild("m_lb_coins"):setString(coins)
        end

        if isJackpot then
            self:setJackpotShowState(aniNode, data.kind)
        end

        --判断bonus之前的状态来播放对应的动画
        if lastType == ENUM_BONUS_TYPE.NORMAL then
            if curBonusType == ENUM_BONUS_TYPE.COINS then
                aniNode:findChild("money"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.COINS
                self:refreshBonusCoins(aniNode, coins, multi)
                if isOnEnter then
                    aniNode:runCsbAction("idle_money", true)
                else
                    if isIdleRun then
                        aniNode:runCsbAction("idleframe_money", false, function()
                            aniNode:runCsbAction("start_money", false, function()
                                aniNode:runCsbAction("idle_money", true)
                            end)
                        end)
                    else
                        aniNode:runCsbAction("start_money", false, function()
                            aniNode:runCsbAction("idle_money", true)
                        end)
                    end
                end
            elseif curBonusType == ENUM_BONUS_TYPE.JACKPOT then
                aniNode:findChild("jackpot"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.JACKPOT
                if isOnEnter then
                    aniNode:runCsbAction("idle_jackpot", true)
                else
                    if isIdleRun then
                        aniNode:runCsbAction("idleframe_jackpot", false, function()
                            aniNode:runCsbAction("start_jackpot", false, function()
                                aniNode:runCsbAction("idle_jackpot", true)
                            end)
                        end)
                    else
                        aniNode:runCsbAction("start_jackpot", false, function()
                            aniNode:runCsbAction("idle_jackpot", true)
                        end)
                    end
                end
            elseif curBonusType == ENUM_BONUS_TYPE.DOUBLE then
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.DOUBLE
                aniNode:findChild("double"):setVisible(true)
                self:refreshBonusCoins(aniNode, coins, multi)
                if isOnEnter then
                    aniNode:runCsbAction("idle_double", true)
                else
                    aniNode:runCsbAction("start_double", false, function()
                        aniNode:runCsbAction("idle_double", true)
                    end)
                end
            end
        elseif lastType == ENUM_BONUS_TYPE.COINS then
            if curBonusType == ENUM_BONUS_TYPE.COINS and isRefresh then
                aniNode:findChild("money"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.COINS
                if isOnEnter then
                    aniNode:runCsbAction("idle_money", true)
                else
                    aniNode:runCsbAction("over_money", false, function()
                        self:refreshBonusCoins(aniNode, coins, multi)
                        aniNode:runCsbAction("start_money", false, function()
                            aniNode:runCsbAction("idle_money", true)
                        end)
                    end)
                end
            elseif curBonusType == ENUM_BONUS_TYPE.JACKPOT then
                aniNode:findChild("double"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.JACKPOT
                if isOnEnter then
                    aniNode:runCsbAction("idle_double", true)
                else
                    aniNode:runCsbAction("over_money", false, function()
                        self:refreshBonusCoins(aniNode, coins, multi)
                        aniNode:runCsbAction("start_double", false, function()
                            aniNode:runCsbAction("idle_double", true)
                        end)
                    end)
                end
            elseif curBonusType == ENUM_BONUS_TYPE.DOUBLE and isRefresh then
                aniNode:findChild("double"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.DOUBLE
                if isOnEnter then
                    aniNode:runCsbAction("idle_double", true)
                else
                    aniNode:runCsbAction("over_money", false, function()
                        self:refreshBonusCoins(aniNode, coins, multi)
                        aniNode:runCsbAction("start_double", false, function()
                            aniNode:runCsbAction("idle_double", true)
                        end)
                    end)
                end
            end
        elseif lastType == ENUM_BONUS_TYPE.JACKPOT then
            if curBonusType == ENUM_BONUS_TYPE.DOUBLE and isRefresh then
                aniNode:findChild("double"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.DOUBLE
                if isOnEnter then
                    aniNode:runCsbAction("idle_double", true)
                else
                    aniNode:runCsbAction("over_jackpot", false, function()
                        self:refreshBonusCoins(aniNode, coins, multi)
                        aniNode:runCsbAction("start_double", false, function()
                            aniNode:runCsbAction("idle_double", true)
                        end)
                    end)
                end
            end
        elseif lastType == ENUM_BONUS_TYPE.DOUBLE then
            if (curBonusType == ENUM_BONUS_TYPE.COINS or curBonusType == ENUM_BONUS_TYPE.DOUBLE) and isRefresh then
                aniNode:findChild("double"):setVisible(true)
                self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.DOUBLE
                if isOnEnter then
                    aniNode:runCsbAction("idle_double", true)
                else
                    aniNode:runCsbAction("over_double", false, function()
                        self:refreshBonusCoins(aniNode, coins, multi)
                        aniNode:runCsbAction("start_double", false, function()
                            aniNode:runCsbAction("idle_double", true)
                        end)
                    end)
                end
            end
        end
    end
end

function BingoldKoiBingoControl:setJackpotShowState(aniNode, kind)
    aniNode:findChild("mini"):setVisible(kind == "mini")
    aniNode:findChild("minor"):setVisible(kind == "minor")
    aniNode:findChild("major"):setVisible(kind == "major")
    aniNode:findChild("mega"):setVisible(kind == "mega")
    aniNode:findChild("grand"):setVisible(kind == "grand")

    aniNode:findChild("mini_2"):setVisible(kind == "mini")
    aniNode:findChild("minor_2"):setVisible(kind == "minor")
    aniNode:findChild("major_2"):setVisible(kind == "major")
    aniNode:findChild("mega_2"):setVisible(kind == "mega")
    aniNode:findChild("grand_2"):setVisible(kind == "grand")
end

--bonus飞过去后在这里播放落地
function BingoldKoiBingoControl:playBonusBuLing(bonusData, func, _isSkip, _isPlayLight)
    local isSkip = _isSkip
    local isReelCollect = _isReelCollect
    if isSkip then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Quick_Bonus_BuLing)
    end
    --播放即将能连线的特效
    if _isPlayLight then
        self:playEffectBingoLine()
    end
    --刷新bonus图标
    for i,data in ipairs(bonusData) do
        local posData = self.m_machine:getRowAndColByPos(data.loc)
        local iCol,iRow = posData.iY,posData.iX
        local bonusSpine = self.m_bonusSpines[iRow][iCol]
        local bonusImg = self.m_bonusImgs[iRow][iCol]
        bonusImg:setVisible(false)
        bonusSpine:setVisible(true)
        --落地
        util_spinePlay(bonusSpine,"fly2",false)
        util_spineEndCallFunc(bonusSpine, "fly2", function()
            bonusSpine:setVisible(false)
            bonusImg:setVisible(true)
        end)
    end
    performWithDelay(self.m_machine.m_scWaitNode, function()
        if type(func) == "function" then
            func()
        end
    end, 22/30)
end

function BingoldKoiBingoControl:refreshBonusCoins(aniNode, coins, multi)
    --两个label都设置一下,保持一致
    local label1 = aniNode:findChild("m_lb_coins_1")
    if label1 then
        if multi >= COIN_MUL then
            label1:setFntFile("BingoldKoiFont/BingoldKoi_font9.fnt")
        else
            label1:setFntFile("BingoldKoiFont/BingoldKoi_font2.fnt")
        end
        label1:setString(coins)
        self.m_machine:updateLabelSize({label=label1,sx=0.82,sy=0.82},99)
    end

    local label2 = aniNode:findChild("m_lb_coins_2")
    if label2 then
        if multi >= COIN_MUL then
            label2:setFntFile("BingoldKoiFont/BingoldKoi_font9.fnt")
        else
            label2:setFntFile("BingoldKoiFont/BingoldKoi_font2.fnt")
        end
        label2:setString(coins)
        self.m_machine:updateLabelSize({label=label2,sx=0.82,sy=0.82},99)
    end
end

--转盘回来刷新后，把连线上的bonus设置为动画idle状态
function BingoldKoiBingoControl:setBonusGameOverBingoLineIdle(bingoLines)
    if bingoLines and #bingoLines > 0 then
        for index, lineData in pairs(bingoLines) do
            for i=1, #lineData do
                local pos = lineData[i].loc
                local posData = self.m_machine:getRowAndColByPos(pos)
                local iCol,iRow = posData.iY,posData.iX
                local bonusSpine = self.m_bonusSpines[iRow][iCol]
                local bonusImg = self.m_bonusImgs[iRow][iCol]

                bonusImg:setVisible(false)
                bonusSpine:setVisible(true)
                util_spinePlay(bonusSpine,"idleframe2",true)
            end
        end
    end
end

--bingo触发连线
function BingoldKoiBingoControl:playBingoLineTrigger(bingoLines, _isBonusTrigger, callFunc)
    if bingoLines and #bingoLines > 0 then
        for index, lineData in pairs(bingoLines) do
            for i=1, #lineData do
                local pos = _isBonusTrigger and lineData[i] or lineData[i].loc
                local posData = self.m_machine:getRowAndColByPos(pos)
                local iCol,iRow = posData.iY,posData.iX
                local bonusSpine = self.m_bonusSpines[iRow][iCol]
                local bonusImg = self.m_bonusImgs[iRow][iCol]
                local bonusTriggerAni = self.m_bonusTriggerAnis[iRow][iCol]
                
                bonusTriggerAni:setVisible(true)
                local particle = bonusTriggerAni:findChild("Particle_1")
                particle:resetSystem()
                bonusTriggerAni:runCsbAction("actionframe", false, function()
                    particle:stopSystem()
                    bonusTriggerAni:setVisible(false)
                end)
                if iCol == 3 and iRow == 3 then
                    util_spinePlay(self.m_midBonus,"actionframe",false)
                else
                    bonusImg:setVisible(false)
                    bonusSpine:setVisible(true)
                    util_spinePlay(bonusSpine,"actionframe",false)
                    util_spineEndCallFunc(bonusSpine, "actionframe", function()
                        util_spinePlay(bonusSpine,"idleframe2",true)
                    end)
                end
            end
        end
    end
    performWithDelay(self.m_machine.m_scWaitNode, function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, 150/60)
end

--bingo线上的下潜，其余的消失
function BingoldKoiBingoControl:setBingoSpineLineOver(bingoLines, isSuperFree, _callFunc)
    if bingoLines then
        self:hideTipLight()
        if not isSuperFree or self.m_machine:getCurIsFirstTriggrSuperFree() then
            -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_All_Bonus_Disappear)
        end
        for iRow = 1,self.m_machine.m_iReelRowNum do
            for iCol = 1,self.m_machine.m_iReelColumnNum do
                local bonusType = self.m_bonusAnisType[iRow][iCol]
                local bonusSpine = self.m_bonusSpines[iRow][iCol]
                local bonusImg = self.m_bonusImgs[iRow][iCol]
                local ani = self.m_bonusAnis[iRow][iCol]
                local isOver = false
                for index, lineData in pairs(bingoLines) do
                    for i=1, #lineData do
                        local posData = self.m_machine:getRowAndColByPos(lineData[i].loc)
                        local curCol,curRow = posData.iY,posData.iX
                        if iRow == curRow and iCol == curCol then
                            isOver = true
                            break
                        end
                    end
                    if isOver then
                        break
                    end
                end
                
                --中间bonus不变化
                if iCol ~= 3 or iRow ~= 3 then
                    --下潜
                    if isOver then
                        if bonusImg:isVisible() then
                            bonusSpine:setVisible(true)
                            bonusImg:setVisible(false)
                        end
                        util_spinePlay(bonusSpine,"over",false)
                        util_spineEndCallFunc(bonusSpine, "over", function()
                            bonusSpine:setVisible(false)
                        end)
                        --判断播放的时间线
                        self:setBonusCoinsAni(ani, bonusType)
                        self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.NORMAL
                    --渐隐
                    else
                        if not isSuperFree or self.m_machine:getCurIsFirstTriggrSuperFree() then
                            if bonusImg:isVisible() then
                                bonusSpine:setVisible(true)
                                bonusImg:setVisible(false)
                            end
                            util_spinePlay(bonusSpine,"over_xiaoshi",false)
                            util_spineEndCallFunc(bonusSpine, "over_xiaoshi", function()
                                bonusSpine:setVisible(false)
                            end)
                            --判断播放的时间线
                            self:setBonusCoinsAni(ani, bonusType)
                            self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.NORMAL
                        end
                    end
                    
                else
                    self.m_midCoins:setVisible(false)
                    util_spinePlay(self.m_midBonus,"idleframe",true)
                    -- self.m_midBonus:setLocalZOrder(MID_ORDER)
                end
            end
        end
    end
    
    self.darkMask:runCsbAction("over", false, function()
        self.darkMask:setVisible(false)
        if type(_callFunc) == "function" then
            _callFunc()
        end
    end)
    performWithDelay(self.m_machine.m_scWaitNode, function()
        if type(_callFunc) == "function" then
            -- self.darkMask:runCsbAction("over", false, function()
            --     self.darkMask:setVisible(false)
            -- end)
            -- self:recoveryBonusZorder()
            -- _callFunc()
        end
    end, 20/30)--37/30)
end

function BingoldKoiBingoControl:setBonusCoinsAni(_bonusAni, _bonusType)
    local bonusAni = _bonusAni
    local bonusType = _bonusType
    if bonusType == ENUM_BONUS_TYPE.COINS then
        bonusAni:runCsbAction("xiaoshi_money", false, function()
            self:refreshBonusCoins(bonusAni, 0, 0)
            bonusAni:setVisible(false)
        end)
    elseif bonusType == ENUM_BONUS_TYPE.JACKPOT then
        bonusAni:runCsbAction("xiaoshi_jackpot", false, function()
            self:refreshBonusCoins(bonusAni, 0, 0)
            bonusAni:setVisible(false)
        end)
    elseif bonusType == ENUM_BONUS_TYPE.DOUBLE then
        bonusAni:runCsbAction("xiaoshi_double", false, function()
            self:refreshBonusCoins(bonusAni, 0, 0)
            bonusAni:setVisible(false)
        end)
    end
end

function BingoldKoiBingoControl:setBingoLineZorder(bingoLines, _isBonusTrigger)
    if bingoLines and #bingoLines > 0 then
        for index, lineData in pairs(bingoLines) do
            for i=1, #lineData do
                local pos = _isBonusTrigger and lineData[i] or lineData[i].loc
                local posData = self.m_machine:getRowAndColByPos(pos)
                local iCol,iRow = posData.iY,posData.iX
                local bonusSpine = self.m_bonusSpines[iRow][iCol]
                local bonusImg = self.m_bonusImgs[iRow][iCol]
                local bonusAni = self.m_bonusAnis[iRow][iCol]
                local bonusCollectAni = self.m_bonusCollectAnis[iRow][iCol]
                
                local curOrder = bonusSpine:getLocalZOrder()
                local curCoinsOrder = bonusAni:getLocalZOrder()
                if iCol == 3 and iRow == 3 then
                    self.m_midBonus:setLocalZOrder(MASK_ORDER+MID_ORDER)
                    bonusAni:setLocalZOrder(MASK_ORDER+curCoinsOrder)
                else
                    bonusSpine:setLocalZOrder(MASK_ORDER+curOrder)
                    bonusImg:setLocalZOrder(MASK_ORDER+curOrder)
                    bonusAni:setLocalZOrder(MASK_ORDER+curCoinsOrder)
                    bonusCollectAni:setLocalZOrder(MASK_ORDER+curOrder-1)
                end
            end
        end
    end
    self.darkMask:setVisible(true)
    self.darkMask:runCsbAction("start", false, function()
        self.darkMask:runCsbAction("idle", true)
    end)
end

function BingoldKoiBingoControl:recoveryBonusZorder()
    for iRow = 1,self.m_machine.m_iReelRowNum do
        for iCol = 1,self.m_machine.m_iReelColumnNum do
            local bonusSpine = self.m_bonusSpines[iRow][iCol]
            local bonusImg = self.m_bonusImgs[iRow][iCol]
            local bonusAni = self.m_bonusAnis[iRow][iCol]
            local zOrder = self:getBonusNormalZorder(iCol, iRow)
            local curCoinsOrder = bonusAni:getLocalZOrder()

            local coinsZorder = self:getRightBonusCoinsZorder(iCol, iRow)
            if iCol == 3 and iRow == 3 then
                self.m_midBonus:setLocalZOrder(MID_ORDER)
                bonusAni:setLocalZOrder(coinsZorder)
            else
                bonusSpine:setLocalZOrder(zOrder)
                bonusImg:setLocalZOrder(zOrder)
                bonusAni:setLocalZOrder(coinsZorder)
            end
        end
    end
    self.m_midCoins:setVisible(false)
    util_spinePlay(self.m_midBonus,"idleframe",true)
end

function BingoldKoiBingoControl:recorveryMidBonusZoeder()
    local iCol = 3
    local iRow = 3
    local bonusAni = self.m_bonusAnis[iRow][iCol]
    local coinsZorder = self:getRightBonusCoinsZorder(iCol, iRow)
    self.m_midBonus:setLocalZOrder(MID_ORDER)
    bonusAni:setLocalZOrder(coinsZorder)
    util_spinePlay(self.m_midBonus,"idleframe2",true)
end

--[[
    刷新中奖光圈(只差一个获得bingo的时候)
]]
function BingoldKoiBingoControl:refreshTipLight(bingoPositions)
    if not bingoPositions then
        return
    end
    --刷新连线
    for i,pos in ipairs(bingoPositions) do
        local posData = self.m_machine:getRowAndColByPos(pos)
        local iCol,iRow = posData.iY,posData.iX
        local lineAni = self.m_bonusLineAnis[iRow][iCol]
        lineAni:setVisible(true)
        lineAni:runCsbAction("actionframe", true)
        self.m_machine:refreshTipLight(iRow, iCol)
    end
end

function BingoldKoiBingoControl:hideTipLight(isOnEnter)
    if not self.m_bingoPositions then
        return
    end

    for iRow = 1,self.m_machine.m_iReelRowNum do
        for iCol = 1,self.m_machine.m_iReelColumnNum do
            local lineAni = self.m_bonusLineAnis[iRow][iCol]
            local isRunOver = true
            for i,pos in ipairs(self.m_bingoPositions) do
                local posData = self.m_machine:getRowAndColByPos(pos)
                if iRow == posData.iX and iCol == posData.iY then
                    isRunOver = false
                    break
                end
            end

            if isOnEnter then
                lineAni:setVisible(false)
                self.m_machine:hideTipLight(iRow, iCol, isOnEnter)
            else
                if isRunOver then
                    lineAni:runCsbAction("over", false, function()
                        lineAni:setVisible(false)
                    end)
                    self.m_machine:hideTipLight(iRow, iCol)
                end
            end
        end
    end
end

function BingoldKoiBingoControl:resetLinePosition()
    self.m_bingoPositions = {}
end

function BingoldKoiBingoControl:resetBonusAnisType()
    for iRow = 1,self.m_machine.m_iReelRowNum do
        for iCol = 1,self.m_machine.m_iReelColumnNum do
            self.m_bonusAnisType[iRow][iCol] = ENUM_BONUS_TYPE.NORMAL
        end
    end
end

--[[
    根据行列获取小块
]]
function BingoldKoiBingoControl:getBonusAniByPos(iCol,iRow)
    return self.m_bonusAnis[iRow][iCol]
end

--获取在order
function BingoldKoiBingoControl:getBonusNormalZorder(iCol, iRow)
    local zOrder = iCol * 10 - iRow
    return zOrder
end

--获取在order
function BingoldKoiBingoControl:getRightBonusCoinsZorder(iCol, iRow)
    local zOrder = COINS_ORDER + iCol * 10 - iRow
    return zOrder
end

--[[
    bingo line 收集动效
]]
function BingoldKoiBingoControl:collectBingoLineAni(_data, _posIndex, _winCoins, _isOver, _isLastBonus, _func)
    local oneData = _data
    local posIndex = _posIndex
    local winCoins = _winCoins
    local isOver = _isOver
    local isLastBonus = _isLastBonus
    local func = _func
    local posData = self.m_machine:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX
    local ani = self.m_bonusAnis[iRow][iCol]
    local bonusSpine = self.m_bonusSpines[iRow][iCol]
    local bonusImg = self.m_bonusImgs[iRow][iCol]
    local bonusCollectAni = self.m_bonusCollectAnis[iRow][iCol]
    
    bonusCollectAni:setVisible(true)
    bonusCollectAni:runCsbAction("actionframe2", true)
    local actionFrameName = "fly5"
    if iCol == 3 and iRow == 3 then
        actionFrameName = "shouji"
        bonusSpine = self.m_midBonus
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Collect_BonusFeed)
    else
        local posX, posY = bonusSpine:getPosition()
        if isOver then
            bonusImg:setVisible(true)
            bonusSpine:setVisible(false)
            -- ani:setVisible(false)
        end
        local flyBonusAni = util_createAnimation("BingoldKoi_FlyBonus.csb")
        local flyBonusSpine = util_spineCreate("Socre_BingoldKoi_BingoBonus",true,true)
        local flyNode_X = flyBonusAni:findChild("Node_Fly_X")
        local flyNode_Y = flyBonusAni:findChild("Node_Fly_Y")
        flyNode_Y:addChild(flyBonusSpine)
        self.m_machine:addChild(flyBonusAni, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
        local worldPos = self.m_machine.m_clipParent:convertToWorldSpace(cc.p(posX, posY))
        -- local startPos = self.m_machine:convertToNodeSpace(worldPos)
        flyBonusAni:setScaleX(-self.m_machine.m_machineRootScale)
        flyBonusAni:setScaleY(self.m_machine.m_machineRootScale)
        flyBonusAni:setPosition(worldPos)

        local flyCoinsAni = util_createAnimation("Socre_BingoldKoi_RightBingoBonus.csb")
        self:setFlyCoins(flyCoinsAni, oneData, iRow, iCol)
        -- flyNode_Y:addChild(flyCoinsAni)
        util_spinePushBindNode(flyBonusSpine,"kb",flyCoinsAni)

        bonusSpine = flyBonusSpine

        local m_bottomUI = self.m_machine:getBottomUi()
        local endPos = util_convertToNodeSpace(m_bottomUI.m_normalWinLabel, self.m_machine)
        --第一阶段位移
        local offsetX = (worldPos.x - endPos.x) / self.m_machine.m_machineRootScale
        local endPos_X = cc.p(offsetX, 0)
        --第二阶段位移
        local offsetY = (endPos.y - worldPos.y) / self.m_machine.m_machineRootScale
        local endPos_Y = cc.p(0, offsetY)
        
        performWithDelay(self.m_machine.m_scWaitNode, function()
            local move_X = cc.MoveTo:create(19/30, endPos_X)--cc.EaseIn:create(moveAction, 2), nil)
            flyNode_X:runAction(move_X)
            performWithDelay(self.m_machine.m_scWaitNode, function()
                local move_Y = cc.EaseIn:create(cc.MoveTo:create(10/30, endPos_Y), 2)
                local funcAct = cc.CallFunc:create(function ()
                    -- if type(func) == "function" then
                    --     self.m_machine:playhBottomLight(winCoins)
                    --     func()
                    -- end
                    flyBonusAni:removeFromParent()
                end)
                local seq = cc.Sequence:create(move_Y,funcAct)
                flyNode_Y:runAction(seq)
            end, 9/30)
        end, 7/30)
    end
    
    util_spinePlay(bonusSpine,actionFrameName,false)
    if isLastBonus then
        util_spineEndCallFunc(bonusSpine, actionFrameName, function()
            if type(func) == "function" then
                self.m_machine:playhBottomLight(winCoins, function()
                    func()
                end)
            end
        end)
    else
        if oneData.jackpot > 0 then
            util_spineEndCallFunc(bonusSpine, actionFrameName, function()
                if type(func) == "function" then
                    self.m_machine:playhBottomLight(winCoins, function()
                        func()
                    end)
                end
            end)
        else
            performWithDelay(self.m_machine.m_scWaitNode, function()
                if type(func) == "function" then
                    func()
                end
            end, 0.6)
            util_spineEndCallFunc(bonusSpine, actionFrameName, function()
                self.m_machine:playhBottomLight(winCoins)
            end)
        end
    end
end

function BingoldKoiBingoControl:setFlyCoins(_flyCoinsAni, _oneData, _iRow, _iCol)
    local flyCoinsAni = _flyCoinsAni
    local oneData = _oneData
    local iRow = _iRow
    local iCol = _iCol
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Collect_BonusFeed)
    flyCoinsAni:findChild("money"):setVisible(false)
    flyCoinsAni:findChild("jackpot"):setVisible(false)
    flyCoinsAni:findChild("double"):setVisible(false)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_isSuperFree and self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet
    end
    if self.m_bonusAnisType[iRow][iCol] == ENUM_BONUS_TYPE.COINS then
        flyCoinsAni:findChild("money"):setVisible(true)
        local multi = oneData.amount / lineBet
        local coins = util_formatCoins(oneData.amount, 3)
        self:refreshBonusCoins(flyCoinsAni, coins, multi)
        flyCoinsAni:runCsbAction("idle_money", true)
    elseif self.m_bonusAnisType[iRow][iCol] == ENUM_BONUS_TYPE.JACKPOT then
        flyCoinsAni:findChild("jackpot"):setVisible(true)
        self:setJackpotShowState(flyCoinsAni, oneData.kind)
        flyCoinsAni:runCsbAction("idle_jackpot", true)
    elseif self.m_bonusAnisType[iRow][iCol] == ENUM_BONUS_TYPE.DOUBLE then
        flyCoinsAni:findChild("double"):setVisible(true)
        self:setJackpotShowState(flyCoinsAni, oneData.kind)
        local coinsAmount = oneData.amount - oneData.jackpot
        local multi = coinsAmount / lineBet
        local coins = util_formatCoins(coinsAmount, 3)
        self:refreshBonusCoins(flyCoinsAni, coins, multi)
        flyCoinsAni:runCsbAction("idle_double", true)
    end
end

function BingoldKoiBingoControl:showBingoBottomLight(lineData)
    for iRow = 1,self.m_machine.m_iReelRowNum do
        for iCol = 1,self.m_machine.m_iReelColumnNum do
            local bonusCollectAni = self.m_bonusCollectAnis[iRow][iCol]
            bonusCollectAni:setVisible(false)
        end
    end

    if lineData and #lineData > 0 then
        for k, v in pairs(lineData) do
            local posData = self.m_machine:getRowAndColByPos(v.loc)
            local iCol,iRow = posData.iY,posData.iX
            local bonusCollectAni = self.m_bonusCollectAnis[iRow][iCol]
            bonusCollectAni:setVisible(true)
            bonusCollectAni:runCsbAction("actionframe2", true)
        end
    end
end

--落地播完之后，播放即将可以连成线的特效
function BingoldKoiBingoControl:playEffectBingoLine()
    if not self.m_bingoPositions or #self.m_bingoPositions == 0 or #self.m_curBingoReels == 0 then
        return
    end
    --先算出所有即将bingo的线
    local tblBingoLineData = {}
    for k, bingoLine in pairs(self.m_allLineData) do
        local sameCount = 0
        for i=1, #bingoLine do
            for j=1, #self.m_curBingoReels do
                if self.m_curBingoReels[j].loc == bingoLine[i] then
                    sameCount = sameCount + 1
                end
            end
        end
        if sameCount == 4 then
            tblBingoLineData[#tblBingoLineData+1] = {}
            copyTable(bingoLine, tblBingoLineData[#tblBingoLineData])
        end
    end

    --最后需要加预告的格子位置
    local addLightBonusTbl = {}

    --根据这次收集的bonus，判断当前是否需要播放预告连线
    local curCollectBonus = self.m_machine:getCurSpinCollectBonus()

    for i=1, #curCollectBonus do
        local curBonuPos = curCollectBonus[i].loc
        local isHaveLine = false
        for j=#tblBingoLineData, 1, -1 do
            local lineData = tblBingoLineData[j]
            if lineData then
                for k, pos in pairs(lineData) do
                    if curBonuPos == pos then
                        addLightBonusTbl[#addLightBonusTbl+1] = {}
                        copyTable(lineData, addLightBonusTbl[#addLightBonusTbl])
                        isHaveLine = true
                        break
                    end
                end
                if isHaveLine then
                    tblBingoLineData[j] = false
                    break
                end
            end
        end
    end

    --添加预告的光圈
    for i=1, #addLightBonusTbl do
        local lineData = addLightBonusTbl[i]
        for k, pos in pairs(lineData) do
            local delayTime = k * 0.15
            local posData = self.m_machine:getRowAndColByPos(pos)
            local iCol,iRow = posData.iY,posData.iX
            local bonusCollectAni = self.m_bonusCollectAnis[iRow][iCol]
            local bonusCollectTopAni = self.m_bonusCollectTopAnis[iRow][iCol]
            local zOrder = self:getBonusNormalZorder(iCol, iRow) - 1
            bonusCollectAni:setLocalZOrder(zOrder)

            performWithDelay(self.m_machine.m_scWaitNode, function()
                bonusCollectAni:setVisible(true)
                bonusCollectTopAni:setVisible(true)
                bonusCollectAni:runCsbAction("actionframe", false, function()
                    bonusCollectAni:setVisible(false)
                end)
                bonusCollectTopAni:runCsbAction("actionframe", false, function()
                    bonusCollectTopAni:setVisible(false)
                end)
            end, delayTime)
        end
    end
end

return BingoldKoiBingoControl
