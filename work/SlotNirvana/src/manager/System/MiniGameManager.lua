--[[
    小游戏 管理器
]]
local MiniGameManager = class("MiniGameManager")
local ShopItem = util_require("data.baseDatas.ShopItem")

-- 小游戏数据类
local MiniGameLevelFishData = require("data.miniGameData.MiniGameLevelFishData")

MiniGameManager.MINIGAME_REF = {
    MINIGAME_LEVELFISH = "levelRushGames"
}

MiniGameManager.m_instance = nil
function MiniGameManager:getInstance()
    if MiniGameManager.m_instance == nil then
        MiniGameManager.m_instance = MiniGameManager.new()
    end
    return MiniGameManager.m_instance
end

-- 构造函数
function MiniGameManager:ctor()
    self.m_miniGameRef = ""
    self.m_miniGameList = {}

    self.m_miniGameHandle = {}
    self:initMiniGameHandle()

    -- levelfish 变量 --
    self.m_gameIndex = nil
end

-- 注册小游戏对应的开启方法
function MiniGameManager:initMiniGameHandle()
    local handleList = {}
    handleList[#handleList + 1] = {handler(self, self.miniGameHandleShowLevelFish), MiniGameManager.MINIGAME_REF.MINIGAME_LEVELFISH} -- levelFish 小游戏
    self.m_miniGameHandle = handleList
end

function MiniGameManager:parseData(_miniGameData, _isLogon)
    if not _miniGameData then
        return
    end

    -- levelRush 鱼缸掉球
    if #(_miniGameData.levelRushGames or {}) > 0 then
        self.m_miniGameRef = MiniGameManager.MINIGAME_REF.MINIGAME_LEVELFISH
        self:createLevelRushGameData(_miniGameData.levelRushGames)
    end

    -- 翻牌小游戏相关
    if _miniGameData:HasField("pokerDataResult") then
        G_GetMgr(G_REF.PokerRecall):parseData(_miniGameData.pokerDataResult)
    end

    -- PickStar小游戏
    if #(_miniGameData.pickStarResults or {}) > 0 then
        G_GetMgr(G_REF.GiftPickBonus):parseData(_miniGameData.pickStarResults)
    end

    -- 打鸭子
    if #(_miniGameData.duckShotGames or {}) > 0 then
        G_GetMgr(ACTIVITY_REF.DuckShot):parseData(_miniGameData.duckShotGames, _isLogon)
    end

    -- 神庙四选一小游戏（鲨鱼游戏）
    if _miniGameData:HasField("adventureGameResult") then
        G_GetMgr(G_REF.TreasureSeeker):parseData(_miniGameData.adventureGameResult)
    end

    -- CashMoney 道具化小游戏
    if #(_miniGameData.cashMoneyResults or {}) > 0 then
        G_GetMgr(G_REF.CashMoney):parseData(_miniGameData.cashMoneyResults)
    end

    -- 弹珠小游戏
    if #(_miniGameData.pinballGoResults or {}) > 0 then
        G_GetMgr(ACTIVITY_REF.PinBallGo):parseData(_miniGameData.pinballGoResults, _isLogon)
    end

    -- 快速点击小游戏
    if #(_miniGameData.piggyClickerResult or {}) > 0 then
        G_GetMgr(ACTIVITY_REF.PiggyClicker):parseData(_miniGameData.piggyClickerResult)
    end

    if _miniGameData and _miniGameData.dartsGameResults ~= nil and #(_miniGameData.dartsGameResults) > 0 then
        G_GetMgr(ACTIVITY_REF.DartsGame):parseData(_miniGameData.dartsGameResults, _isLogon)
    end

    if _miniGameData and _miniGameData.dartsGameV2Results ~= nil and #(_miniGameData.dartsGameV2Results) > 0 then
        G_GetMgr(ACTIVITY_REF.DartsGameNew):parseData(_miniGameData.dartsGameV2Results, _isLogon)
    end

    -- LuckyFish 道具化小游戏
    if _miniGameData:HasField("luckFishGameResult") then
        G_GetMgr(G_REF.Plinko):parseData(_miniGameData.luckFishGameResult)
    end

    if _miniGameData:HasField("pearlsLinkGameResult") then
        G_GetMgr(G_REF.LeveDashLinko):parseData(_miniGameData.pearlsLinkGameResult)
    end

    -- 等级里程碑小游戏
    if _miniGameData:HasField("levelRoadGameDataResult") then
        G_GetMgr(ACTIVITY_REF.LevelRoadGame):parseData(_miniGameData.levelRoadGameDataResult)
    end
        
    -- 鲨鱼游戏道具化
    if #(_miniGameData.mythicGames or {}) > 0 then
        G_GetMgr(G_REF.MythicGame):parseData(_miniGameData.mythicGames)
    end
end

function MiniGameManager:startMiniGame(_overFunc)
    --直接触发小游戏
    self.m_overFunc = _overFunc
    local currMiniGameData = self:getMiniGameByRef(self.m_miniGameRef)
    if currMiniGameData then
        for i = 1, #self.m_miniGameHandle do
            local handleData = self.m_miniGameHandle[i]
            if handleData and #handleData >= 1 then
                if handleData[2] == self.m_miniGameRef then
                    local eventFunc = handleData[1] -- 函数
                    if eventFunc then
                        eventFunc()
                    end
                    break
                end
            end
        end
    end
end

------------------------------ 外部调用 ------------------------------
function MiniGameManager:checkHasMiniGame()
    local bHas = false
    if self:getMiniGameByRef(self.m_miniGameRef) ~= nil then
        bHas = true
    end
    return bHas
end

function MiniGameManager:getMiniGameByRef(_ref)
    return self.m_miniGameList[_ref]
end

------------------------------ LevelFish 相关方法 ------------------------------
--[[
    @desc: 判断当前序号的游戏是否结束
    无法复用 LevelRushManager 里的方法因为获取数据的地方不一样，小游戏道具可以不走活动数据
]]
function MiniGameManager:getGameOverByIndex(_index)
    local gameData = self:getLevelFishGameDataForIdx(_index)
    if gameData then
        local bPurchase = gameData:getHasPurchase()
        local bCollected = gameData:getRewardIsCollect()
        local nLeftBall = gameData:getLeftBallsCount()
        local isClickXInPayConfirm = gameData:getClickXInPayConfirm()
        local strTime, isOver = gameData:getTodayLeftTime()

        if nLeftBall == 0 and bCollected and (bPurchase or isClickXInPayConfirm) then
            return true
        elseif isOver then
            return true
        else
            return false
        end
    end

    return true
end

function MiniGameManager:checkGameInit(_nIndex)
    local gameData = self:getLevelFishGameDataForIdx(_nIndex)
    if gameData then
        return gameData:checkHasRewards()
    end
    return false
end

function MiniGameManager:showLevelFishGameView(_nIndex, _overCall)
    local gameData = self:getLevelFishGameDataForIdx(_nIndex)
    -- 未下载时弹框提示
    if gLobalLevelRushManager:isDownloadRes() then
        -- 判断当前界面是否已经加载过
        if gLobalViewManager:getViewByExtendData("LevelRush_GameView") then
            if _overCall then
                _overCall()
            end
            return
        end
        if gameData and not self:getGameOverByIndex(_nIndex) then
            -- 设置当前数据来源
            gLobalLevelRushManager:setLevelRushSource("MiniGame")
            gLobalLevelRushManager:setGameIndex(_nIndex)
            local view = util_createFindView("Activity/LevelRushSrc/LevelRush_GameView", _overCall)
            if view ~= nil then
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            else
                gLobalLevelRushManager:setLevelRushSource(nil)
            end
        end
    else
        gLobalViewManager:showDownloadTip()
    end
end

-- 根据序号获取levelfish 小游戏数据
function MiniGameManager:getLevelFishGameDataForIdx(_index)
    local gameData = nil
    local gameDatas = self:getMiniGameByRef(MiniGameManager.MINIGAME_REF.MINIGAME_LEVELFISH)
    if gameDatas and #gameDatas > 0 then
        for k, v in ipairs(gameDatas) do
            if v.gameIndex == _index then
                gameData = v.gameData
                break
            end
        end
    end
    return gameData
end

------------------------------ 内部解析 minigame 数据方法 ------------------------------
function MiniGameManager:createLevelRushGameData(_gameData)
    local dataList = {}
    for i = 1, #_gameData do
        local data = _gameData[i]
        local gameData = MiniGameLevelFishData.new()
        gameData:parseGameData(data)
        local nIndexGame = gameData:getGameIndex()
        local tempList = {
            gameData = gameData,
            gameIndex = nIndexGame
        }
        self.m_gameIndex = nIndexGame
        table.insert(dataList, tempList)
    end
    if #dataList > 0 then
        self.m_miniGameList[MiniGameManager.MINIGAME_REF.MINIGAME_LEVELFISH] = dataList
    else
        self.m_miniGameList[MiniGameManager.MINIGAME_REF.MINIGAME_LEVELFISH] = nil
    end
end

------------------------------ 内部进入 minigame 方法 ------------------------------
function MiniGameManager:miniGameHandleShowLevelFish()
    self:showLevelFishGameView(self.m_gameIndex, self.m_overFunc)
end

------------------------------ 切前后台暂停游戏 ------------------------------
function MiniGameManager:commonBackGround()
    G_GetMgr(ACTIVITY_REF.PiggyClicker):commonBackGround()
end
function MiniGameManager:commonForeGround()
    G_GetMgr(ACTIVITY_REF.PiggyClicker):commonForeGround()
end
------------------------------ 切前后台暂停游戏 ------------------------------

return MiniGameManager
