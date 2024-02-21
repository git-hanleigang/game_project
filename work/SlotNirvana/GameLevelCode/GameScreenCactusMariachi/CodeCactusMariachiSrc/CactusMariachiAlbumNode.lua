---
--CactusMariachiAlbumNode.lua

local CactusMariachiAlbumNode = class("CactusMariachiAlbumNode",util_require("base.BaseView"))

CactusMariachiAlbumNode.m_curPage = 0
CactusMariachiAlbumNode.m_curIndex = 0
CactusMariachiAlbumNode.m_curCoins = 0
CactusMariachiAlbumNode.m_shopMachine = nil
CactusMariachiAlbumNode.m_machine = nil

function CactusMariachiAlbumNode:initUI(m_machine, _shopMachine, _index)

    self:createCsbNode("CactusMariachi_shop_Albums.csb")
    
    self.m_shopMachine = _shopMachine
    self.m_machine = m_machine
    self.m_curIndex = _index
    self.m_curPage = self.m_shopMachine.m_curPage

    self:runCsbAction("idle")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function CactusMariachiAlbumNode:initCutPageAlbum(_curCoins)
    self:runCsbAction("idle", true)
    self:setAlbumCoinNum()
end

-- 初始化界面和翻页时使用
function CactusMariachiAlbumNode:refreshViewData(_curCoins, _isSold, _isPickAgain, _isFree, _isLockAlbum)
    self.m_curPage = self.m_shopMachine.m_curPage
    self.m_curCoins = _curCoins
    if _isPickAgain then
        self:runCsbAction("idle2x", true)
    elseif _isFree then
        self:runCsbAction("idle3", true)
    elseif _isLockAlbum then
        if self.m_curIndex == 8 then
            gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_albumUnlock.mp3")
        end
        self:runCsbAction("jiesuo", false, function()
            if self:isEnoughCoins() then
                self:runCsbAction("idle2", true)
            else
                self:runCsbAction("idle4", true)
            end
            if self.m_curIndex == 8 then
                self.m_shopMachine:playMusicUnlockAni()
            end
        end)
    elseif self.m_shopMachine.tblFinishList[self.m_curPage] == true then
        if _isSold then
            self:runCsbAction("maichu", true)
        else
            if self:isEnoughCoins() then
                self:runCsbAction("idle2", true)
            else
                self:runCsbAction("idle4", true)
            end
        end
    else
        self:runCsbAction("idle", true)
    end
    self:setAlbumCoinNum()
end

--如果钱不够，刷新剩下的状态
function CactusMariachiAlbumNode:setCoinsNotEnoughAlbumState()
    if self.m_shopMachine:getTotalCoins() < self.m_curCoins then
        self:runCsbAction("idle4", true)
    end
end

--刷新唱碟状态(服务器返回数据刷新当前唱碟)
function CactusMariachiAlbumNode:refreshCurState(_pickResult, _isFree, _callFunc)
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopChangeCoins.mp3")
    self:playEffectRandom()
    if _isFree then
        self:findChild("Chosen1"):setVisible(false)
        self:findChild("Chosen2"):setVisible(true)
        self:runCsbAction("dianji", false, function()
            self:runCsbAction("idle2x", true)
            self.m_shopMachine:showOtherFree(_callFunc)
        end)
    else
        local rewardCoins = _pickResult[1]
        local mul = _pickResult[2]
        local totalReward = _pickResult[3]

        self:findChild("Chosen1"):setVisible(true)
        self:findChild("Chosen2"):setVisible(false)

        self:findChild("m_lb_coins"):setString(util_formatCoins(rewardCoins,3))

        self:runCsbAction("dianji", false, function ()
            if self.m_shopMachine:getLastIsPickAgain() then
                self.m_shopMachine:playPickAgainAni(totalReward, _callFunc)
            else
                local startPos = util_convertToNodeSpace(self:findChild("Node_fly"), self.m_machine)
                self:flyCoinsToBottom(totalReward, startPos, _callFunc)
            end
        end)
    end
end

function CactusMariachiAlbumNode:flyCoinsToBottom(_totalReward, _startPos, _callFunc, _isPickAgain)
    local flyText = util_createAnimation("CactusMariachi_shop_Albums.csb")
    flyText:findChild("Chosen2"):setVisible(false)
    flyText:findChild("m_lb_coins"):setString(util_formatCoins(_totalReward,3))
    flyText:setPosition(_startPos)
    self.m_machine:addChild(flyText, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)

    local delayTime = 0.2
    local m_startCoins = 0
    local m_bottomUI = self.m_machine:getBottomUi()
    local totalReward = _totalReward
    local endPos = util_convertToNodeSpace(m_bottomUI.m_normalWinLabel, self.m_machine)
    local effectIndex = _isPickAgain and 2 or 1

    local endCallFunc = function()
        --更新顶部金钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,{coins = globalData.userRunData.coinNum, isPlayEffect = true})
        if _callFunc then
            _callFunc()
        end
        if not tolua.isnull(flyText) then
            flyText:removeFromParent()
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopCollect_"..effectIndex..".mp3")
    end, 15/60)
    flyText:runCsbAction("fankui", false)
    performWithDelay(self.m_scWaitNode, function()
        util_playMoveToAction(flyText, delayTime, endPos,function()
            gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopCollectFeedBack_"..effectIndex..".mp3")
            self.m_machine:playhBottomLight(m_startCoins, totalReward, endCallFunc)
        end)
    end, 25/60)
end

function CactusMariachiAlbumNode:playPickAgainAni(_endPos, _callFunc)
    self:runCsbAction("idle2x", false)
    local startPos = util_convertToNodeSpace(self:findChild("Node_fly"), self.m_machine)
    local spPick = util_createAnimation("CactusMariachi_shop_Albums.csb")
    spPick:findChild("Chosen1"):setVisible(false)
    spPick:setPosition(startPos)
    self.m_machine:addChild(spPick, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)

    local delayTime = 0.2

    local endCallFunc = function()
        self.m_shopMachine:recoveryOtherFree()
        if _callFunc then
            _callFunc()
        end
        if not tolua.isnull(spPick) then
            spPick:removeFromParent()
        end
    end
    spPick:runCsbAction("fankui", false)
    performWithDelay(self.m_scWaitNode, function()
        util_playMoveToAction(spPick, delayTime, _endPos,function()
            if endCallFunc then
                endCallFunc()
            end
        end)
    end, 15/60)
end

function CactusMariachiAlbumNode:playPickCoins(_totalReward, _callFunc)
    self:runCsbAction("fankui2", false, function()
        local startPos = util_convertToNodeSpace(self:findChild("Node_fly"), self.m_machine)
        self:flyCoinsToBottom(_totalReward, startPos, _callFunc, true)
    end)
    performWithDelay(self.m_scWaitNode, function()
        self:findChild("m_lb_coins"):setString(util_formatCoins(_totalReward,3))
    end, 3/60)
end

--pickAgain刷新状态
function CactusMariachiAlbumNode:showOtherFree()
    self:runCsbAction("bian", false)
end

--上一个pickAgain恢复状态
function CactusMariachiAlbumNode:recoveryOtherFree(_curCost)
    self.m_curCoins = _curCost
    if self:isEnoughCoins() then
        self:runCsbAction("idle2", true)
    else
        self:runCsbAction("idle4", true)
    end
    self:setAlbumCoinNum()
end

function CactusMariachiAlbumNode:setAlbumCoinNum()
    self:findChild("m_lb_coinsSpend_1"):setString(self.m_curCoins)
    self:findChild("m_lb_coinsSpend_2"):setString(self.m_curCoins)
end

function CactusMariachiAlbumNode:onExit()
    CactusMariachiAlbumNode.super.onExit(self)
end

--默认按钮监听回调
function CactusMariachiAlbumNode:clickFunc(sender)
    local name = sender:getName()

    if name == "click" then
        if self:isCanTouch() then
            self.m_shopMachine:setClickData(self.m_curIndex)
        end
        if self.m_shopMachine:getCurShopDataIsClick(self.m_curIndex) and not self:isEnoughCoins() and not self.m_shopMachine:curPageIsHavePickAgain() then
            self.m_shopMachine:playCoinsLight()
        end
    end
end

function CactusMariachiAlbumNode:isCanTouch( )
    if (self:isEnoughCoins() or self.m_shopMachine:curPageIsHavePickAgain()) and self.m_shopMachine:getCanClick(self.m_curIndex)
    and self.m_shopMachine.tblFinishList[self.m_curPage] == true then
        return true
    end

    return false
end

function CactusMariachiAlbumNode:isEnoughCoins()
    if self.m_shopMachine:getTotalCoins() >= self.m_curCoins then
        return true
    else
        return false
    end
end

function CactusMariachiAlbumNode:playEffectRandom()
    local randomNum = math.random(1, 10)
    if randomNum >= 1 and randomNum <= 5 then
        local randomMusic = math.random(1, 2)
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_shopRandomAlbom_"..randomMusic..".mp3")
    end
end

return CactusMariachiAlbumNode
