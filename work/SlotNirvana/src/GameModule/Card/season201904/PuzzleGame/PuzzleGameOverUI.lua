--[[
    集卡小游戏结算UI
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameOverUI = class("PuzzleGameOverUI", BaseView)

function PuzzleGameOverUI:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode(CardResConfig.PuzzleGameOverRes, isAutoScale)

    -- self.m_coinLB = self:findChild("lb_coinNum")
    -- self.m_coinLB:setString("")
    self.m_rewardNode = self:findChild("node_reward")

    self.m_collectBtn = self:findChild("btn_collectNow")
    -- self.m_collectBtn:setTouchEnabled(false)
    -- self.m_collectBtn:setBright(false)

    self.m_nodeCoins = nil

    self:initView()

    self.m_startAction = true
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_startAction = false
            self:runCsbAction("idle", true)
        end
    )
end

function PuzzleGameOverUI:initView()
    self:initItems()
end

function PuzzleGameOverUI:initItems()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local puzzleReward = data and data.reward[1]
    if not puzzleReward then
        return
    end

    -- local itemList = {}
    self.m_rewardItems = {}

    local coins = 0
    if data and data.reward and data.reward[1] and data.reward[1].coins > 0 then
        coins = data.reward[1].coins
    end
    if coins > 0 then
        self.m_nodeCoins = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameOverReward", "COINS", coins)
        self.m_rewardNode:addChild(self.m_nodeCoins)
        -- table.insert(itemList, {node = self.m_nodeCoins})
        table.insert(self.m_rewardItems, self.m_nodeCoins)
    end

    if puzzleReward.cardDrops and #puzzleReward.cardDrops > 0 then
        local sp = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameOverReward", "PACKET", #puzzleReward.cardDrops)

        self.m_rewardNode:addChild(sp)
        -- table.insert(itemList, {node = sp, alignX = 220})
        table.insert(self.m_rewardItems, sp)
    end

    if puzzleReward.rewards and #puzzleReward.rewards > 0 then
        for i = 1, #puzzleReward.rewards do
            local reward = puzzleReward.rewards[i]
            local sp = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameOverReward", "DIAMOND", reward.p_num)

            self.m_rewardNode:addChild(sp)
            -- table.insert(itemList, {node = sp, alignX = 220})
            table.insert(self.m_rewardItems, sp)
        end
    end

    -- if #itemList > 0 then
    --     util_alignCenter(itemList)
    -- end
    self:initRewardIcon()
end

function PuzzleGameOverUI:initRewardIcon()
    local showNum = #self.m_rewardItems

    local intervalDis = 250

    local iconPosList = {}
    if showNum > 3 then
        if showNum == 4 then
            -- 两行 3+1
            for i=1,4 do
                if i <= 3 then
                    iconPosList[i] = {-intervalDis + intervalDis*(i-1), intervalDis/2}
                else
                    iconPosList[i] = {intervalDis*((i-3)-1), -intervalDis/2}
                end
            end
        elseif showNum == 5 then
            -- 两行 3+2
            for i=1,5 do
                if i <= 3 then
                    iconPosList[i] = {-intervalDis + intervalDis*(i-1), intervalDis/2}
                else
                    iconPosList[i] = {-intervalDis/2 + intervalDis*((i-3)-1), -intervalDis/2}
                end
            end
        elseif showNum == 6 then
            -- 两行 3+3
            for i=1,6 do
                if i <= 3 then
                    iconPosList[i] = {-intervalDis + intervalDis*(i-1), intervalDis/2}
                else
                    iconPosList[i] = {-intervalDis + intervalDis*((i-3)-1), -intervalDis/2}
                end
            end            
        end
    else
        -- 一行
        if showNum == 1 then
            iconPosList[1] = {0,0}
        elseif showNum == 2 then
            iconPosList[1] = {-intervalDis/2, 0}
            iconPosList[2] = {intervalDis/2, 0}
        elseif showNum == 3 then
            iconPosList[1] = {-intervalDis, 0}
            iconPosList[2] = {0, 0}
            iconPosList[3] = {intervalDis, 0}
        end
    end

    for index = 1, #self.m_rewardItems do
        local _node = self.m_rewardItems[index]
        _node:setPosition(cc.p(iconPosList[index][1], iconPosList[index][2]))
    end
end

function PuzzleGameOverUI:createNum(sp, num)
    local size = sp:getContentSize()
    local numObj = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameNum")
    numObj:setPosition(cc.p(size.width * 0.5, size.height * 0.5 - 32))
    numObj:updateNum(num)
    sp:addChild(numObj)
end

function PuzzleGameOverUI:closeUI(overCall)
    if self.closed then
        return
    end
    self.closed = true
    self:runCsbAction(
        "over",
        false,
        function()
            if overCall then
                overCall()
            end
            self:removeFromParent()
        end
    )
end

function PuzzleGameOverUI:canClick()
    if self.m_startAction then
        return false
    end
    if self.m_flyAction then
        return false
    end
    if self.closed then
        return false
    end
    return true
end

function PuzzleGameOverUI:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end
    if name == "btn_collectNow" then
        self:flyCoins()
    end
end

function PuzzleGameOverUI:flyCoins()
    self.m_flyAction = true

    -- 刷新小游戏主界面上UI
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_BOX)

    local data = CardSysRuntimeMgr:getPuzzleGameData()

    local rewardCoins = 0
    if data and data.reward and data.reward[1] then
        local rewardData = data.reward[1]
        if rewardData.coins then
            rewardCoins = rewardData.coins
        end
        if rewardData.cardDrops and #rewardData.cardDrops > 0 then
            CardSysManager:doDropCardsData(rewardData.cardDrops)
        end
    end

    local callback = function()
        -- 掉落
        if CardSysManager:needDropCards("Cash Puzzle") == true then
            CardSysManager:doDropCards("Cash Puzzle", function()
                gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_CHANGE_BOX)
            end)
        else
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_CHANGE_BOX)
        end        
    end

    if rewardCoins > 0 then
        globalData.userRunData:setCoins(globalData.userRunData.coinNum + rewardCoins)
        local startPos = self.m_nodeCoins:getParent():convertToWorldSpace(cc.p(self.m_nodeCoins:getPosition()))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        gLobalViewManager:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                self.m_flyAction = false
                CardSysManager:getPuzzleGameMgr():closeGameOverUI(callback)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {isPlayEffect = false})
            end
        )
    else
        self.m_flyAction = false
        CardSysManager:getPuzzleGameMgr():closeGameOverUI(callback)
    end
end

return PuzzleGameOverUI
