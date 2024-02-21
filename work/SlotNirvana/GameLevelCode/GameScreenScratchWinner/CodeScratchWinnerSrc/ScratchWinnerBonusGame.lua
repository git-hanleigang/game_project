
local ScratchWinnerBonusGame = class("ScratchWinnerBonusGame", cc.Node)
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"

ScratchWinnerBonusGame.ORDER = {
    WaitPanel = 1000,
    MainCard  = 100,
    NextCard  = 50,
}

function ScratchWinnerBonusGame:initData_(...)
    self:initUI(...)
end

--[[
    _initData = {
        bReconnect = false,         --断线后后端直接清理列表了
        index      = 1,
        machine    = machine,
        cardList   = {
            {
                index      = 1,
                name       = "",
                lines      = {},
                reels      = {},
                bingoReels = {},
            },
        },
        overFun    = function() end,
    }
]]
function ScratchWinnerBonusGame:initUI(_initData)
    self.m_initData = _initData
    self.m_machine  = _initData.machine

    -- 垫底的刮刮卡 (只在切换淡出时展示一下，不做过多的逻辑处理)
    self.m_bottomCard = nil
    self.m_bottomCardList = {}

    -- 主要的刮刮卡 (处理主要的逻辑)
    self.m_curCardName = ""
    self.m_lastCardName = ""
    self.m_mainCard = nil
    self.m_mainCardList = {}
    self.m_bAutoAllState = false


    -- addObservers
    --消息返回
    gLobalNoticManager:addObserver(self,function(self,params)
        --清理背包-立刻结束玩法
        if params.isClear then
            local sMsg = "[ScratchWinnerBonusGame:initUI] clear"
            print(sMsg)
            release_print(sMsg)
            --当前卡片飞走
            self.m_initData.index = #self.m_initData.cardList
            local nextCardIndex = self.m_initData.index +1
            self:upDateBottomCardList(self.m_initData.index)
            if nil ~= self.m_mainCard then
                self:playExportOverAnim(nextCardIndex, true, function()
                    self.m_mainCard:setVisible(false)
                    self:endBonusGame()
                end)
            end
        --领取奖励返回
        elseif params.isReward then
            -- 出首张卡片
            if not self.m_mainCard then
                self:playNextCardShowAnim(self.m_initData.index, false, false)
            else
                 --当前卡片飞走
                self:playExportOverAnim(self.m_initData.index, false, function()
                    self.m_mainCard:setVisible(false)
                    self:playNextCardShowAnim(self.m_initData.index, self.m_bAutoAllState, false)
                end)
            end
            -- self.m_mainCard:recvServerData()
        end
    end,"ScratchWinnerMachine_resultCallFun")
end

-- 玩法开始
function ScratchWinnerBonusGame:startBonusGame()
    ScratchWinnerShopManager:getInstance():sendReceiveRewardData()
end
-- 玩法结束
function ScratchWinnerBonusGame:endBonusGame()
    self.m_initData.overFun()
end


-- 出下一张卡片
function ScratchWinnerBonusGame:playNextCardShowAnim(_cardIndex, _bAuto, _bReconnect)
    -- 取数据时拿最新的，数值说方便写样本
    -- local cardData = self.m_initData.cardList[_cardIndex]
    local cardData = ScratchWinnerShopManager:getInstance():getOneCardBagData(_cardIndex)
    
    if not cardData then
        -- 玩法结束
        self:endBonusGame()
        return
    end
    --

    local nextCardIndex   = _cardIndex + 1
    --重置一下 主刮刮卡的数据,和初始化展示 
    self.m_mainCard = self:getOneCardView(cardData.name, self.m_mainCardList)
    self.m_mainCard:setLocalZOrder(100 + _cardIndex)
    self.m_mainCard:initCardData(cardData)
    self.m_mainCard:initMainCardUi()
    self.m_mainCard:setAutoState(_bAuto)
    --添加事件监听要放在所有空间初始化完毕
    self.m_mainCard:addBaseCardViewObserver()
    -- 出卡流程
    self:playExportAnim(_cardIndex, function()
        self:upDateBottomCardList(_cardIndex)
        gLobalNoticManager:postNotification("ScratchWinnerMachine_cardExport", {self.m_curCardName})
        
        -- 卡片入场
        self.m_mainCard:playCardStartAnim()
        self.m_mainCard:setVisible(true)
        --和上一张卡片不是同类型时 淡入一些控件
        local bDifferent = self.m_lastCardName ~= self.m_curCardName
        -- 开始刮卡
        self.m_mainCard:startCardGame(bDifferent, _bReconnect, function(_isAuto)
            -- 索引+1
            self.m_initData.index = nextCardIndex
            self.m_bAutoAllState  = _isAuto
            -- 下一张卡的数据
            local nextCardData = ScratchWinnerShopManager:getInstance():getOneCardBagData(self.m_initData.index)

            -- 清理背包
            if nil ~= nextCardData and self.m_mainCard.m_overClearState then
                ScratchWinnerShopManager:getInstance():sendClearBagData()
            -- 请求下一张卡片奖励
            elseif nil ~= nextCardData then
                ScratchWinnerShopManager:getInstance():sendReceiveRewardData()
            --当前卡片飞走
            else
                self:playExportOverAnim(self.m_initData.index, false, function()
                    self.m_mainCard:setVisible(false)
                    self:playNextCardShowAnim(self.m_initData.index, self.m_bAutoAllState, false)
                end)
            end
        end)
    end)
end

function ScratchWinnerBonusGame:playExportAnim(_cardIndex, _fun)
    self.m_lastCardName = self.m_curCardName

    local curCardData  = ScratchWinnerShopManager:getInstance():getOneCardBagData(_cardIndex, true)
    if self.m_curCardName == curCardData.name then
        _fun()
        return
    end

    self.m_curCardName  = curCardData.name

    local mainMachine = self.m_machine
    local cardList = {
        {curCardData}
    }
    mainMachine.m_shopList:playExportAnim(1, cardList, function()
        _fun()
        mainMachine:hideExportCardList()
    end)
end
-- 卡片结束了
function ScratchWinnerBonusGame:playExportOverAnim(_nextIndex, _bEndGame, _fun)
    local mainMachine = self.m_machine
    local animTime = 0
    local overTime = self.m_mainCard:playCardOverAnim(nil)

    -- 一种类型的卡片结束后 商店出来
    local nextData = ScratchWinnerShopManager:getInstance():getOneCardBagData(_nextIndex)
    if _bEndGame or nil == nextData or self.m_curCardName ~= nextData.name then
        self.m_mainCard:hideDifferentCardViewShow()

        animTime = mainMachine:changeBgShowState(true, true)
        mainMachine:playShopNodeMoveAction(true)
    end

    local delayTime = math.max(animTime, overTime)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        _fun()
        waitNode:removeFromParent()
    end, delayTime)
end
--[[
    主逻辑卡片界面
]]
function ScratchWinnerBonusGame:getOneCardView(_cardName, _pool)
    local card = _pool[_cardName]

    if not card then
        local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(_cardName)
        local codeName   = cardConfig.cardViewCode
        local csbName    = cardConfig.cardViewRes
        card = util_createView(codeName, cardConfig)
        self:addChild(card)
        card:initMachine(self.m_machine)
        _pool[_cardName] = card
        card:setVisible(false)
    end

    return card
end
--[[
    垫底卡片
]]
function ScratchWinnerBonusGame:upDateBottomCardList(_curCardIndex)
    for k,v in pairs(self.m_bottomCardList) do
        v:setVisible(false)
    end

    local cardTypeList = self:getBottomCardTypeList(_curCardIndex)
    for i,_cardData in ipairs(cardTypeList) do
        local bottomCard = self:getOneCardView(_cardData.name, self.m_bottomCardList)
        bottomCard:setLocalZOrder(100 - _cardData.index)
        -- 界面展示
        bottomCard:findChild("Sprite_mask"):setVisible(true)
        --一些特殊卡片的特殊展示
        if "bingo" == _cardData.name then
            bottomCard:initCardData(_cardData)
            bottomCard:upDateBingoLinesList()
            bottomCard:resetBingoLineLabel()
        end
        bottomCard:setVisible(true)
    end
end
function ScratchWinnerBonusGame:getBottomCardTypeList(_curCardIndex)
    local dataList = {}
    local cardList = self.m_initData.cardList
    local cardName = cardList[_curCardIndex].name
    for i=_curCardIndex+1,#cardList do
        local cardData = cardList[i]

        --其他类型的堆叠效果
        -- if cardName ~= cardData.name then
        --     table.insert(dataList, cardData)
        --     cardName = cardData.name
        -- end

        --不展示其他类型的堆叠效果
        if cardName == cardData.name then
            table.insert(dataList, cardData)
            break
        end
    end

    return dataList
end

return ScratchWinnerBonusGame
