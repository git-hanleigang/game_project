--[[--
    小游戏主界面
    随机抽取一个奖励后获得奖励，重置除黄金奖励外全部格子的奖金。若赢得任意黄金奖励格，全部格子均进行重置
]]
local LSGameLogic = util_require("views.LuckyStamp.MiniGame.mainUI.LSGameLogic")
local LSGameMainUI = class("LSGameMainUI", LSGameLogic)

function LSGameMainUI:getBgMusicPath()
    return LuckyStampCfg.otherPath .. "music/Lucky_Stamp.mp3"
end

function LSGameMainUI:initDatas()
    LSGameMainUI.super.initDatas(self)
    self:setLandscapeCsbName(LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main.csb")
    self:setPauseSlotsEnabled(true)
    -- self:setKeyBackEnabled(true)
end

function LSGameMainUI:initCsbNodes()
    self.m_nodeCoins = {}
    for i = 1, 12 do
        local coin = self:findChild("node_coin" .. i)
        table.insert(self.m_nodeCoins, coin)
    end
    self.m_nodeRollEffect = self:findChild("node_coinEffect")

    self.m_nodeTopReward = self:findChild("node_reward")
    self.m_nodeStamp = self:findChild("node_stamp")
    self.m_nodeTime = self:findChild("node_time")
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeTitle = self:findChild("node_title") --2023

end

function LSGameMainUI:initView()
    self:initTopCoins()
    self:initRollCoins()
    self:initRollEffect()
    self:initStamps()
    self:initTime()
    self:initBtnCloseVisible()
    self:initTitle() --2023
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function LSGameMainUI:initTitle()  --2023
    self.m_title = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameTitle")
    self.m_nodeTitle:addChild(self.m_title)
end

function LSGameMainUI:initTopCoins()
    self.m_topReward = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameTopReward")
    self.m_nodeTopReward:addChild(self.m_topReward)
end

function LSGameMainUI:initRollCoins()
    self.m_boxes = {}
    self.m_rollPositions = {}
    for i = 1, #self.m_nodeCoins do
        local coin = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameBox", i)
        self.m_nodeCoins[i]:addChild(coin)
        table.insert(self.m_boxes, coin)
        table.insert(self.m_rollPositions, cc.p(self.m_nodeCoins[i]:getPosition()))
    end
    -- 控制器初始化
    local LSGameRollControl = util_require(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameRollControl")
    self.m_rollCtrl = LSGameRollControl:create()
    self.m_rollCtrl:init(#self.m_nodeCoins)
end

function LSGameMainUI:getBoxWorldPos(_index)
    if _index and self.m_boxes[_index] then
        local box = self.m_boxes[_index]
        local worldPos = box:getParent():convertToWorldSpace(cc.p(box:getPosition()))
        return worldPos
    end
    return nil
end

function LSGameMainUI:initRollEffect()
    self.m_rollEffect = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameRollEffect")
    self.m_nodeRollEffect:addChild(self.m_rollEffect)
    self.m_rollEffect:playIdle2()
    --self.m_rollEffect:setVisible(false)
    self:changeRollEffectPosition(1)
end

function LSGameMainUI:changeRollEffectPosition(_index) --2023
    if self.m_rollPositions[_index] then
        self.m_rollEffect:setPosition(self.m_rollPositions[_index])
        self.m_rollEffect:changeVisible(_index) 
    end
end

function LSGameMainUI:initStamps()
    self.m_stamp = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameStamp", handler(self, self.clickStampBack), handler(self, self.clickStampRoll))
    self.m_nodeStamp:addChild(self.m_stamp)
end

function LSGameMainUI:initTime()
    self.m_time = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameTime")
    self.m_nodeTime:addChild(self.m_time)
end

function LSGameMainUI:initBtnCloseVisible()
    local isVisible = true
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data and data:isHaveGameComing() then
        isVisible = false
    end
    self.m_btnClose:setVisible(isVisible)
end

function LSGameMainUI:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function LSGameMainUI:onShowedCallFunc()
    self:playIdle()
    -- 判断是否是断线重连
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local curProcessData = data:getCurProcessData()
        if curProcessData and curProcessData:isHaveGame() == true then
            if curProcessData:isSpin() == false then
                -- 盖戳
                local needStampCount = self:getNeedStampNum()
                print("--- onShowedCallFunc 1 needStampCount ---", needStampCount)
                if needStampCount > 0 then
                    -- 执行盖戳逻辑
                    self:doStampLogic()
                end
            elseif curProcessData:isCollect() == false then
                self:doReconnectCollectLogic()
            end
        else
            -- 盖戳
            local needStampCount = self:getNeedStampNum()
            print("--- onShowedCallFunc 2 needStampCount ---", needStampCount)
            if needStampCount > 0 then
                -- 执行盖戳逻辑
                self:doStampLogic()
            end
        end
    end
end

function LSGameMainUI:onEnter()
    LSGameMainUI.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFI_LUCKYSTAMP_TIMEOUT
    )
end

function LSGameMainUI:clickStampBack(_isPlaySound)
    if self:getStatusByKey("stamp") == true then
        return
    end
    if _isPlaySound then
        gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    end
    self:closeUI()
end

function LSGameMainUI:clickStampRoll()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    G_GetMgr(G_REF.LuckyStamp):requestRoll(
        function()
            if not tolua.isnull(self) then
                self.m_rollEffect:playIdle()
                --self.m_rollEffect:setVisible(true)
                self:doRollLogic()
            end
        end
    )
end

function LSGameMainUI:closeUI(_over)
    if self.m_rollCtrl then
        self.m_rollCtrl:stopSche()
        self.m_rollCtrl = nil
    end
    LSGameMainUI.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            G_GetMgr(G_REF.LuckyStamp):exitGame()
        end
    )
end

function LSGameMainUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_info" then
        G_GetMgr(G_REF.LuckyStamp):showInfoLayer()
    elseif name == "btn_close" then
        self:clickStampBack()
    end
end

function LSGameMainUI:getNeedStampNum()
    if LuckyStampCfg.TEST_MODE == true then
        return 2
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        return data:getNeedStampNum() or 0
    end
    return 0
end

function LSGameMainUI:getWinIndex()
    if LuckyStampCfg.TEST_MODE == true then
        return 10
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getCurProcessData()
        if processData then
            return processData:getWinIndex()
        end
    end
    return nil
end

return LSGameMainUI
