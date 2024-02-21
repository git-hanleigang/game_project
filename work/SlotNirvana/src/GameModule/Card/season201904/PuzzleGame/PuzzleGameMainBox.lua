--[[--
    小游戏 - 宝箱
]]
local BOX_STATUS = {
    free = "FREE",
    purchase = "PURCHASE"
}

local BaseView = util_require("base.BaseView")
local PuzzleGameMainBox = class("PuzzleGameMainBox", BaseView)
function PuzzleGameMainBox:initUI(mainClass, index)
    self:createCsbNode(CardResConfig.PuzzleGameMainBoxRes)

    self.m_mainClass = mainClass
    self.m_index = index

    self.m_contentNode = self:findChild("Node_content")

    self.m_lizi = self:findChild("playParticle")
    self.m_lizi:stopSystem()

    self.m_touch = self:findChild("touch")
    self:addClick(self.m_touch)

    self:initView()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function PuzzleGameMainBox:getMainClass()
    return self.m_mainClass
end

-- 数据 -------------------------------------------------------------
function PuzzleGameMainBox:getBoxData()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    return data.box[self.m_index]
end

-- 箱子是否空了
function PuzzleGameMainBox:isEmpty()
    local boxData = self:getBoxData()
    if not boxData then
        return true
    end

    if boxData.collect then
        -- 已经收取
        return true
    end

    -- 卡包
    if boxData.type == "PACKAGE" then
        return false
    end

    local _coins = boxData.coins or 0
    if (#boxData.rewards == 0 and _coins <= 0) then
        return true
    end

    return false
end

function PuzzleGameMainBox:getOldBoxData()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    return data.oldBox[self.m_index]
end

-- UI ------------------------------------------------------------------
function PuzzleGameMainBox:initView()
    self:initContent()
end

function PuzzleGameMainBox:initContent()
    self.m_contentUI = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainBoxContent")
    self.m_contentNode:addChild(self.m_contentUI)
end

function PuzzleGameMainBox:updateUI()
    local boxData = self:getBoxData()

    if not boxData then
        return
    end

    local idleAction = ""
    local emptyAction = ""
    local closeAction = ""
    if boxData.status == BOX_STATUS.free then
        idleAction = "open_idle_yin"
        emptyAction = "open_idle2_yin"
        closeAction = "close_idle_yin"
    elseif boxData.status == BOX_STATUS.purchase then
        idleAction = "open_idle_jin"
        emptyAction = "open_idle2_jin"
        closeAction = "close_idle_jin"
    end

    if boxData.pick then
        -- 已被翻开
        if self:isEmpty() then
            -- 领完或者没有物品，显示空箱子
            self:runCsbAction(emptyAction, false)
        else
            self:runCsbAction(idleAction, false)
        end

        if boxData.collect then
            -- 已被领取，展示空箱子
            self.m_contentUI:updateUI(boxData, true)
        else
            -- 未被领取，根据类型展示奖励
            self.m_contentUI:updateUI(boxData)
        end
    else
        -- 未被翻开
        self:runCsbAction(closeAction, true)
    end
end

-- 是否被打开
function PuzzleGameMainBox:isPicked()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local boxData = data.box[self.m_index]

    -- 宝箱是否被打开
    if boxData.pick then
        return true
    end

    return false
end

function PuzzleGameMainBox:canOpenBox()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local boxData = data.box[self.m_index]

    -- 宝箱是否被打开
    if self:isPicked() then
        return false
    end

    -- 是否已经没有次数
    if data.pickLeft == 0 then
        return false
    end

    return true
end

function PuzzleGameMainBox:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        if not self.m_mainClass:canClick() then
            return
        end

        if self:isPicked() then
            return
        end      

        if not self:canOpenBox() then
            -- 判断是否还有购买领取次数
            if not CardSysRuntimeMgr:hasPurchasePick() then
                -- 显示下次更新购买次数提示
                local _tip = self.m_mainClass:getChildByName("GameFreshTip")
                if _tip then
                    _tip:closeUI()
                    _tip = nil
                end

                _tip = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainBoxFreshTip")

                local worldPos = self:getParent():convertToWorldSpace(cc.p(self:getPositionX(), self:getPositionY()))
                local mainPos = self.m_mainClass:convertToNodeSpace(worldPos)
                _tip:setName("GameFreshTip")
                _tip:setPosition(mainPos)

                self.m_mainClass:addChild(_tip)
            else
                -- 播放摇箱子动画，并提示购买
                -- self:openBox(
                --     function()
                --         self.m_mainClass:setPlayOpenBox(false)
                --         self:updateUI()
                --         self.m_mainClass:showBuyMoreUI()
                --     end
                -- )
                self.m_mainClass:showBuyMoreUI()
            end
            return
        end
        self:clickBox()
    end
end

function PuzzleGameMainBox:clickBox()
    -- 请求数据
    self.m_mainClass:setNetworking(true)
    gLobalViewManager:addLoadingAnimaDelay()
    CardSysNetWorkMgr:sendPuzzleGameRequest(
        {status = 1, position = self.m_index},
        function()
            -- 集卡小游戏引导：结束点击宝箱的引导
            CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():stopGuide(3)

            gLobalViewManager:removeLoadingAnima()
            self.m_mainClass:setNetworking(false)
            -- 通知去刷新点击次数相关UI
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PICK)

            self:openBox(
                function()
                    self:openedShowReward()
                end
            )
        end,
        function()
            gLobalViewManager:removeLoadingAnima()
            self.m_mainClass:setNetworking(false)
            gLobalViewManager:showReConnect()
        end
    )
end

-- 开宝箱动画
function PuzzleGameMainBox:openBox(callback)
    local boxData = self:getBoxData()
    if not boxData then
        return
    end
    self.m_mainClass:setPlayOpenBox(true)
    local openAction = ""
    if boxData.status == BOX_STATUS.free then
        openAction = "open_yin"
    elseif boxData.status == BOX_STATUS.purchase then
        openAction = "open_jin"
    end

    self:runCsbAction(
        openAction,
        false,
        function()
            if callback then
                callback()
            end
        end
    )
end


-- 打开展示奖励
function PuzzleGameMainBox:openedShowReward()
    local openShowAction = ""
    local openIdleAction = ""
    local openEmptyIdleAction = ""

    -- 展示奖励
    local boxData = self:getBoxData()
    if not boxData then
        return
    end

    if boxData.status == BOX_STATUS.free then
        openShowAction = "open_yin_show"
        openIdleAction = "open_idle_yin"
        openEmptyIdleAction = "open_idle2_yin"
    elseif boxData.status == BOX_STATUS.purchase then
        openShowAction = "open_jin_show"
        openIdleAction = "open_idle_jin"
        openEmptyIdleAction = "open_idle2_jin"
    end

    self.m_contentUI:updateUI(boxData)

    -- 播放一下爆发粒子
    self.m_lizi:resetSystem()
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardPuzzleGameOpenBox)
    self:runCsbAction(
        openShowAction,
        false,
        function()
            if self:isEmpty() then
                -- 领完或者没有物品，显示空箱子
                self:runCsbAction(openEmptyIdleAction, false)
            else
                self:runCsbAction(openIdleAction, false)
            end
            self:openBoxOver()
        end
    )
end

-- 开宝箱结束
function PuzzleGameMainBox:openBoxOver()
    self.m_mainClass:setPlayOpenBox(false)

    -- 如果有碎片，碎片飞行
    if self:hasPuzzle() then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_START, {flyIndex = self.m_index})
    else
        -- 集卡小游戏引导：开始第四部引导
        self.m_mainClass:startGuide(4)

        -- 没有次数
        -- local data = CardSysRuntimeMgr:getPuzzleGameData()
        -- if data.pickLeft == 0 then
            -- 收取奖励
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_COLLECT_REWARD)
        -- else
        --     -- 判断是否变金宝箱
        --     if CardSysRuntimeMgr:isChangeToGoldenBox() then
        --         -- 发消息 未打开的银宝箱变成金宝箱
        --         self.m_mainClass:setPlayChangeBox(true)
        --         gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHANGE_GOLDENBOX_START, {flyIndex = self.m_index})
        --     else
        --         gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_OVER)
        --     end
        -- end
    end
end

-- 飞碎片
function PuzzleGameMainBox:startFlyPuzzle()
    if self.m_mainClass:getFlyPuzzle() == true then
        return
    end
    self.m_mainClass:setFlyPuzzle(true)

    local targetItem = self:getFlyTargetItemUI()
    if targetItem == nil then
        self:overFlyPuzzle()
        return
    end

    local targetNode = targetItem:getNewItem()

    local targetWorldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPosition()))
    local targetPos = gLobalViewManager:getViewLayer():convertToNodeSpace(targetWorldPos)

    local preParent = clone(self.m_contentUI:getParent())
    local prePosition = clone(cc.p(self.m_contentUI:getPosition()))

    local flyNode = self.m_contentUI:getFlyNode()

    local worldPos = flyNode:getParent():convertToWorldSpace(cc.p(flyNode:getPosition()))
    local localPos = gLobalViewManager:getViewLayer():convertToNodeSpace(worldPos)
    util_changeNodeParent(gLobalViewManager:getViewLayer(), flyNode, ViewZorder.ZORDER_UI)
    flyNode:setPosition(localPos)

    flyNode:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.5, targetPos),
            cc.CallFunc:create(
                function()
                    self:showFlyEffect(
                        targetPos,
                        function()
                            self:overFlyPuzzle()
                        end
                    )
                    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardPuzzleGameChipEnd)
                    util_changeNodeParent(gLobalViewManager:getViewLayer(), flyNode, ViewZorder.ZORDER_UI)
                    flyNode:setPosition(cc.p(prePosition))
                    flyNode:setVisible(false)

                    -- 碎片刷新界面，根据12/12显示
                    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_ITEMS, {noCheckMax = true})
                end
            )
        )
    )
end

function PuzzleGameMainBox:overFlyPuzzle()
    self.m_mainClass:setFlyPuzzle(false)
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_OVER, {index = self.m_index})

    -- 集卡小游戏引导：开始第四部引导
    self.m_mainClass:startGuide(4)

    -- if CardSysRuntimeMgr:isChangeToGoldenBox() then
    --     -- 发消息 未打开的银宝箱变成金宝箱
    --     self.m_mainClass:setPlayChangeBox(true)
    --     gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHANGE_GOLDENBOX_START, {flyIndex = self.m_index})
    -- end
end

function PuzzleGameMainBox:showFlyEffect(targetPos, overFunc)
    local ui = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainItemLight")
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    ui:setScale(0.42)
    ui:setPosition(targetPos)
    ui:playLight(overFunc)
end

-- 变化宝箱
function PuzzleGameMainBox:startChangeBox()
    local boxData = self:getOldBoxData()
    self.m_contentUI:updateUI(boxData)
    self:runCsbAction(
        "changebox_yin",
        false,
        function()
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardPuzzleGameGolden)
                    self:runCsbAction(
                        "changebox",
                        false,
                        function()
                            local boxData = self:getBoxData()
                            self.m_contentUI:updateUI(boxData)
                            self:runCsbAction(
                                "changebox_jin",
                                false,
                                function()
                                    self:runCsbAction("close_idle_jin", true)
                                    self.m_mainClass:changeBox(
                                        function()
                                            self:overChangeBox()
                                        end
                                    )
                                end
                            )
                        end
                    )
                end,
                0.3
            )
        end
    )
end

function PuzzleGameMainBox:overChangeBox()
    self.m_mainClass:setPlayChangeBox(false)
    -- gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_START, {flyIndex = self.m_flyIndex})
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_OVER)
end

function PuzzleGameMainBox:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(layer, param)
            -- 判断当前的宝箱是否要播放变化动效
            -- self.m_flyIndex = param.flyIndex
            if self:needChangeBox() then
                self:startChangeBox()
            end
        end,
        CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHANGE_GOLDENBOX_START
    )

    gLobalNoticManager:addObserver(
        self,
        function(layer, param)
            -- 你品！你细品！
            -- 接收到消息的所有宝箱，只有当次打开的宝箱才会飞
            if param.flyIndex and param.flyIndex == self.m_index then
                -- 如果有碎片，碎片飞行
                if self:hasPuzzle() then
                    self:startFlyPuzzle()
                else
                    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_OVER)
                end
            end
        end,
        CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_START
    )
end

function PuzzleGameMainBox:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function PuzzleGameMainBox:hasPuzzle()
    local boxData = self:getBoxData()
    if boxData.type == "ITEMS" then
        if boxData.rewards[1].p_icon == "Game_NormalPuzzle" then
            return true
        elseif boxData.rewards[1].p_icon == "Game_NadoPuzzle" then
            return true
        elseif boxData.rewards[1].p_icon == "Game_GoldenPuzzle" then
            return true
        end
    end
    return false
end

function PuzzleGameMainBox:getFlyTargetItemUI()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local boxData = data.box[self.m_index]
    if boxData.type == "ITEMS" then
        local type = nil
        if boxData.rewards[1].p_icon == "Game_NormalPuzzle" then
            type = "NORMAL_PUZZLE"
        elseif boxData.rewards[1].p_icon == "Game_NadoPuzzle" then
            type = "NADO_PUZZLE"
        elseif boxData.rewards[1].p_icon == "Game_GoldenPuzzle" then
            type = "GOLDEN_PUZZLE"
        end
        if type then 
            local puzzleUI = self.m_mainClass:getPuzzleUIByPuzzleType(type)
            if puzzleUI and puzzleUI.getItemUI then
                return puzzleUI:getItemUI()
            end
        end  
    end
    return
end

function PuzzleGameMainBox:needChangeBox()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local boxData = self:getBoxData()
    if not boxData.pick and not boxData.collect then
        return true
    end
    return false
end

-- function PuzzleGameMainBox:isChangeToGoldenBox()
--     local data = CardSysRuntimeMgr:getPuzzleGameData()
--     return data.changeBox
-- end

return PuzzleGameMainBox
