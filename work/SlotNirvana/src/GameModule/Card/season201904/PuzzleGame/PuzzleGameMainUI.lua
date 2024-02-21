--[[
    -- 集卡小游戏主UI
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameMainUI = class("PuzzleGameMainUI", BaseView)
local PUZZLE_PAGE_TYPES = {
    {pageType = "NORMAL", puzzleType = "NORMAL_PUZZLE", node = "Node_normalPuzzle", description = "集卡-维加斯游戏-普通wild碎片"}, 
    {pageType = "GOLDEN", puzzleType = "GOLDEN_PUZZLE", node = "Node_goldPuzzle", description = "集卡-维加斯游戏-nado wild碎片"}, 
    {pageType = "NADO", puzzleType = "NADO_PUZZLE", node = "Node_nadoPuzzle", description = "集卡-维加斯游戏-金卡 wild碎片"}, 
}
function PuzzleGameMainUI:initUI(completePageIndex)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode(CardResConfig.PuzzleGameMainRes, isAutoScale)

    self.m_completePageIndex = completePageIndex
    self:initNode()
    self:initData()
    self:initView()
    

    self.m_playStart = true
end

function PuzzleGameMainUI:canClick()
    if self.m_playStart then
        return false
    end
    if self.m_networking then
        return false
    end
    if self.m_playOpenBox then
        return false
    end
    if self.m_flyPuzzle then
        return false
    end
    if self.m_playChangeBox then
        return false
    end 
    if self.m_showPageComplete then
        return false
    end
    return true
end

function PuzzleGameMainUI:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true

    if self.m_timeAction ~= nil then
        self:stopAction(self.m_timeAction)
        self.m_timeAction = nil
    end    

    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end)
end

function PuzzleGameMainUI:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end

    if name == "btn_close" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:getPuzzleGameMgr():closeGameMainUI()
    elseif name == "btn_buyMore" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:buyMore()
    elseif name == "btn_collect" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:collectReward()
    end
end

function PuzzleGameMainUI:buyMore()
    self:showBuyMoreUI()
end

function PuzzleGameMainUI:collectReward()
    self:showGameOverUI()
end

function PuzzleGameMainUI:checkGuide()
    if self:needShowGameOverUI() then
        return false
    end
    if self:needShowBuyMoreUI() then
        return false
    end 
    return true
end

function PuzzleGameMainUI:enterLogic()
    if self:checkGuide() then
        -- 集卡小游戏引导：第二步
        local checkGuideList = {2, 3, 4, 5, 7}
        for i=1,#checkGuideList do
            self:startGuide(checkGuideList[i])
        end
    end

    if self:needShowGameOverUI() then
        -- 弹出结束面板
        self:showGameOverUI()
    elseif self:needShowBuyMoreUI() then
        -- 弹出付费询问面板        
        self:showBuyMoreUI()
    end
end

function PuzzleGameMainUI:startGuide(stepId)
    local rootScale = self.m_csbNode:getChildByName("root"):getScale()
    if stepId == 2 then
        CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(stepId, self.m_pickLeftNode, rootScale)
    elseif stepId == 3 then
        CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(stepId, self.m_boxNodes[1], rootScale)
    elseif stepId == 4 then
        CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(stepId, self.m_wildChipsNode, rootScale)
    elseif stepId == 5 then
        CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(stepId, self.m_resetNode, rootScale)
    elseif stepId == 7 then
        CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(stepId, self.m_purchaseNode, rootScale)
    end
end

function PuzzleGameMainUI:onEnter()
    self:commonShow(self:findChild("root"), function()
        self.m_playStart = false  
        if self.m_completePageIndex then
            self:startPageComplete(self.m_completePageIndex,true)
            -- self:showComplete(handler(self, self.enterLogic))
        else
            self:enterLogic()
        end
    end)
    
    gLobalNoticManager:addObserver(self,function(self,param)
        self:startGuide(param.stepId)
    end, ViewEventType.NOTIFY_CASHPUZZLE_GUIDE)

    gLobalNoticManager:addObserver(self,function(self,param)
        -- 刷新碎片界面
        self:updateUIByPuzzleFly(param.noCheckMax)
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_ITEMS)

    gLobalNoticManager:addObserver(self,function(self,param)
        -- 飞粒子特效，刷新付费相关界面
        local startWorldPos = param.startWorldPos
        self:playAddPicksAction(startWorldPos, function()
            self:updateUIByBuyPicks()
        end)
        -- 按钮状态
        self:updateButton()
        
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PURCHASE)

    gLobalNoticManager:addObserver(self,function(self,param)
        -- 刷新次数
        self:updateUIByPick()
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PICK)

    gLobalNoticManager:addObserver(self,function(self,param)
        -- 飞碎片结束 判断是否碎片集齐
        if not param.index then
            return
        end
        if self:isCompletePuzzlePage() then
            local pageIndex = self:getCompletePageIndex(param.index)
            self:startPageComplete(pageIndex)
        else
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_COLLECT_REWARD, {flag = "afterFly"})
        end
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_OVER)      
    
    gLobalNoticManager:addObserver(self, function(self,params)
        -- 刷新宝石
        -- 请求一下cardinfo刷新宝石数据
        -- CardSysManager:requestCardCollectionSysInfo(
        CardSysNetWorkMgr:sendPuzzleGameRequest(
            {status = 4},
            function()       
                if self and self.updateUIByBuyGem then
                    self:updateUIByBuyGem()
                end
                -- 通知buymore界面刷新
                gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_BUY_MORE_UPDATE)
            end
        )
    end,ViewEventType.NOTIFY_PURCHASE_SUCCESS)
    

    gLobalNoticManager:addObserver(self, function(self,params)
        if self:needShowGameOverUI() then
            -- 弹出结束面板
            self:showGameOverUI()
        elseif self:needShowBuyMoreUI() then
            -- 弹出付费询问面板
            self:showBuyMoreUI()
        end
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_OVER)
    

    gLobalNoticManager:addObserver(self, function(self, params)
        -- 领取后，更新宝箱，更新宝石
        self:updatePickBoxs()
        self:updateGem()
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_BOX)
    
    gLobalNoticManager:addObserver(self, function(self, params)
        -- 特殊判断：如果是外部掉落触发的小游戏打开后播放收集动画，那么收集结束后，要重新走正常逻辑
        if params and  params.flag == "showedPageComplete" then
            if self.m_completePageIndex then
                self:enterLogic()
                return
            end
        end
        -- 常规逻辑
        local data = CardSysRuntimeMgr:getPuzzleGameData()
        if data.pickLeft == 0 then    
            -- 领取奖励
            self:collectReward()
        elseif data.hasPurchaseBox then
            self:checkChangeBox()
        end

    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_COLLECT_REWARD)

    gLobalNoticManager:addObserver(self, function(self, params)
        local data = CardSysRuntimeMgr:getPuzzleGameData()

        if data.hasPurchaseBox then
            self:checkChangeBox()
        end
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_CHANGE_BOX)

    -- 剩余时间判断
    -- self.m_timeSchedule = schedule(
    --     self,
    --     function()
    --         local leftTime = 0
    --         local data = CardSysRuntimeMgr:getPuzzleGameData()
    --         if data then
    --             leftTime = math.max(0, util_getLeftTime(data.coolDown))
    --         end

    --         if leftTime == 0 then
    --             self:closeTimeSchedule()
    --         end

    --         if leftTime < (30 * 60) then
    --             self.m_buyMoreBtn:setVisible(false)
    --         end
    --     end,
    --     1
    -- )

end

-- function PuzzleGameMainUI:closeTimeSchedule()
--     if self.m_timeSchedule ~= nil then
--         self:stopAction(self.m_timeSchedule)
--         self.m_timeSchedule = nil
--     end    
-- end

function PuzzleGameMainUI:onExit()
    -- self:closeTimeSchedule()
    gLobalNoticManager:removeAllObservers(self)
end

-- 初始化数据 -------------------------------------------------------------------
function PuzzleGameMainUI:initData()
    self.m_isShowCollect = false
end

function PuzzleGameMainUI:setNetworking(flag)
    self.m_networking = flag
end
function PuzzleGameMainUI:getNetworking(flag)
    return self.m_networking
end

function PuzzleGameMainUI:setPlayOpenBox(flag)
    self.m_playOpenBox = flag
end
function PuzzleGameMainUI:getPlayOpenBox(flag)
    return self.m_playOpenBox
end

function PuzzleGameMainUI:setFlyPuzzle(flag)
    self.m_flyPuzzle = flag
end
function PuzzleGameMainUI:getFlyPuzzle(flag)
    return self.m_flyPuzzle
end

function PuzzleGameMainUI:setPlayChangeBox(flag)
    self.m_playChangeBox = flag
end
function PuzzleGameMainUI:getPlayChangeBox(flag)
    return self.m_playChangeBox
end

function PuzzleGameMainUI:isCompletePuzzlePage()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if data.puzzleReward and data.puzzleReward[1] and data.puzzleReward[1].coins and data.puzzleReward[1].coins ~= 0 then
        return true
    end
    return false
end

function PuzzleGameMainUI:getPuzzleUIByPuzzleType(puzzleType)
    for i=1,#self.m_puzzleUIs do
        if self.m_puzzleUIs[i]:getPuzzleType() == puzzleType then
            return self.m_puzzleUIs[i], i
        end
    end
    return
end

function PuzzleGameMainUI:getCompletePageIndex(boxIndex)
    -- 通过奖励中的碎片的类型，判断是哪个page
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local boxData = data.box[boxIndex]
    local type = self:checkRewardsTpye(boxData)
    local _, pageIndex = self:getPuzzleUIByPuzzleType(type)
    return pageIndex
end

-- 检查游戏是否已经结束
function PuzzleGameMainUI:isGameOver()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if data.pickLeft == 0 and data.purchasePicks >= data.purchasePicksLimit then
        return true
    end
    return false
end

function PuzzleGameMainUI:isNeedCheckOver()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if data.pickLeft == 0 then
        return true
    end
    return false
end

function PuzzleGameMainUI:isCollectAll()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    for i=1,#data.box do
        local boxData = data.box[i]
        -- 宝箱已打开，但是没有领取
        if boxData.pick == true and boxData.collect == false then
            return false
        end
    end
    return true
end

-- 初始化UI ---------------------------------------------------------------------
function PuzzleGameMainUI:initNode()
    self.m_pickLeftNode = self:findChild("Node_pickLeft")
    self.m_wildChipsNode = self:findChild("Node_wildChips")
    self.m_purchaseNode = self:findChild("Node_purchase")
    self.m_resetNode = self:findChild("Node_reset")

    -- 宝石
    self.m_GemNode = self:findChild("Node_gem") 

    -- 拼图
    self.m_puzzleNodes = {}
    for i=1,#PUZZLE_PAGE_TYPES do
        self.m_puzzleNodes[#self.m_puzzleNodes+1] = self:findChild(PUZZLE_PAGE_TYPES[i].node)
    end
    -- 拼图进度
    self.m_puzzleProLBs = {}
    local proNames = {"lb_ordinaryProgress", "lb_goldProgress", "lb_nadoProgress"}
    for i=1,#proNames do
        self.m_puzzleProLBs[i] = self:findChild(proNames[i])
    end
    

    -- 宝箱
    self.m_boxNodes = {}
    for i=1,16 do
        local boxNode = self:findChild("node_case_"..i)
        self.m_boxNodes[#self.m_boxNodes+1] = boxNode
    end

    -- 点击剩余次数
    self.m_leftPickLB = self:findChild("lb_pickLeft")
    self.m_spPickLeft = self:findChild("sp_pickLeft") -- 单数
    self.m_spPicksLeft = self:findChild("sp_picksLeft") -- 复数
    -- 点击购买次数
    self.m_buyPickLB = self:findChild("lb_purchasePicks") -- 进度
    -- 倒计时
    self.m_timeLB = self:findChild("lb_resetIn")

    -- 按钮
    self.m_collectBtn = self:findChild("btn_collect")
    self.m_buyMoreBtn = self:findChild("btn_buyMore")
    self.m_collectBtn:setVisible(false)
    self.m_buyMoreBtn:setVisible(false)

    -- -- 生成配置文件
    -- self.m_highNode = {
    --     {highNode = self.m_pickLeftNode},
    --     {highNode = self.m_boxNodes[1]},
    --     {highNode = self.m_wildChipsNode},
    --     {highNode = self.m_resetNode},
    --     {}, -- 站位，懒得写特殊逻辑
    --     {highNode = self.m_purchaseNode},
    -- }

end

function PuzzleGameMainUI:getGemNode()
    return self.m_GemNode
end


function PuzzleGameMainUI:initView()
    
    -- 宝石数量
    self:initGem()
    -- 倒计时
    self:initTime()
    -- 章节碎片缩略图
    self:initItems()
    -- 宝箱
    self:initBox()
    
    -- 章节碎片进度
    self:updateItemPro()
    -- 剩余点击次数
    self:updateLeftPicks()
    -- 购买次数进度
    self:updateBuyPicks()
    -- 按钮状态
    self:updateButton()
end

function PuzzleGameMainUI:initGem()
    self.m_GemUI = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainGem")
    self.m_GemNode:addChild(self.m_GemUI)
    -- 创建时刷新一下UI
    self:updateGem()
end

function PuzzleGameMainUI:initTime()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    local leftTime = util_getLeftTime(data.coolDown)
    leftTime = math.max(0, leftTime)
    self.m_timeLB:setString(util_count_down_str(leftTime))
    
    if self.m_timeAction ~= nil then
        self:stopAction(self.m_timeAction)
        self.m_timeAction = nil
    end
    self.m_timeAction = schedule(self, function()
        local data = CardSysRuntimeMgr:getPuzzleGameData()
        leftTime = math.max(0,util_getLeftTime(data.coolDown))
        self.m_timeLB:setString(util_count_down_str(leftTime))

        -- if leftTime < (30 * 60) then
        --     self.m_buyMoreBtn:setTouchEnabled(false)
        --     self.m_buyMoreBtn:setBright(false)
        -- end

        if leftTime == 0 then
            if self.m_timeAction ~= nil then
                self:stopAction(self.m_timeAction)
                self.m_timeAction = nil
            end            
        end
    end, 1)
end

function PuzzleGameMainUI:initItems()
    self.m_puzzleUIs = {}
    for i=1,#self.m_puzzleNodes do
        local ui = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainItems", PUZZLE_PAGE_TYPES[i].pageType, PUZZLE_PAGE_TYPES[i].puzzleType)
        self.m_puzzleUIs[i] = ui
        self.m_puzzleNodes[i]:addChild(ui)
        -- 创建时刷新一下UI
        if ui.updateUI then
            ui:updateUI()
        end
    end
end

function PuzzleGameMainUI:initBox()
    self.m_boxUIs = {}
    for i=1,#self.m_boxNodes do
        local ui = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainBox", self, i)
        self.m_boxUIs[i] = ui
        self.m_boxNodes[i]:addChild(ui)
        -- 创建时刷新一下UI
        if ui.updateUI then
            ui:updateUI()
        end
    end
end

-- 流程 ---------------------------------------------------------------------
function PuzzleGameMainUI:changeBox(changeOverCall)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardPuzzleGameBig1)
    performWithDelay(self, function()
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardPuzzleGameBig2)
    end, 25/30)
    self:runCsbAction("changeBox", false, function()
        if changeOverCall then
            changeOverCall()
        end
    end)
end

function PuzzleGameMainUI:needShowGameOverUI()
    if self:isNeedCheckOver() and not self:isCollectAll() then
        return true
    end
    return false
end

function PuzzleGameMainUI:showGameOverUI()
    self:setNetworking(true)
    CardSysManager:getPuzzleGameMgr():showGameOverUI(function()
        self:setNetworking(false)
    end)
end

function PuzzleGameMainUI:needShowBuyMoreUI()
    -- 如果正在展示结算界面不能弹
    if CardSysManager:getPuzzleGameMgr():isOverShowing() then
        return false
    end
    
    -- 断线重连判断
    if globalData.isPuzzleGameBuyMore == true then
        return true
    end

    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if data.pickLeft == 0 and data.purchasePicks < data.purchasePicksLimit then
        return true
    end
    return false
end

function PuzzleGameMainUI:showBuyMoreUI()
    -- local data = CardSysRuntimeMgr:getPuzzleGameData()
    -- local leftTime = 0
    -- if data then
    --     leftTime = math.max(0, util_getLeftTime(data.coolDown))
    -- end

    -- if leftTime < (30 * 60) then
    --     return
    -- end
    CardSysManager:getPuzzleGameMgr():showBuyMore(self)
end

function PuzzleGameMainUI:startPageComplete(pageIndex,noCheckMax)
    self.m_showPageComplete = true
    
    -- 展示集齐界面
    local pageCompleteUI = CardSysManager:getPuzzleGameMgr():showPageCompleteUI()
    
    local pageUI = self.m_puzzleUIs[pageIndex]
    local preParent = clone(pageUI:getParent())
    local prePosition = cc.p(pageUI:getPosition())

    local targetParentNode = pageCompleteUI:getPuzzleItemNode()
    
    local worldPos = pageUI:getParent():convertToWorldSpace(cc.p(pageUI:getPosition()))
    local localPos = targetParentNode:convertToNodeSpace(worldPos)
    util_changeNodeParent(targetParentNode, pageUI, ViewZorder.ZORDER_UI)
    pageUI:setPosition(localPos)

    pageUI:setScale(0.42)
    pageUI:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.ScaleTo:create(0.5, 1),
                cc.MoveTo:create(0.5, cc.p(0,0))
            ),
            cc.CallFunc:create(function()
                pageUI:getItemUI():crackDisappear(function()
                    pageCompleteUI:playStart()
                end)
            end),
            cc.DelayTime:create(2),
            cc.CallFunc:create(function()
                CardSysManager:getPuzzleGameMgr():closePageCompleteUI(function()
                    util_changeNodeParent(preParent, pageUI)
                    pageUI:setPosition(cc.p(prePosition.x, prePosition.y))
                    self:updateUIByPuzzleFly(noCheckMax)
                    pageUI:getItemUI():playIdle1()
                    local isOuterComplete = nil 
                    if self.m_completePageIndex then 
                        isOuterComplete = self.m_completePageIndex > 0
                    end
                    CardSysManager:getPuzzleGameMgr():showPageCompleteRewardUI(pageIndex, function()
                        if self and self.m_showPageComplete ~= nil then
                            self.m_showPageComplete = false
                        end

                        -- 将掉落加入掉落队列，等最后关闭的时候，统一调用展示
                        local data = CardSysRuntimeMgr:getPuzzleGameData()
                        if data and data.puzzleReward and data.puzzleReward[1] and data.puzzleReward[1].cardDrops and #data.puzzleReward[1].cardDrops > 0 then
                            CardSysManager:doDropCardsData(data.puzzleReward[1].cardDrops)
                        end                        
                        if CardSysManager:needDropCards("Cash Puzzle") == true then
                            CardSysManager:doDropCards("Cash Puzzle", function()
                                gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_COLLECT_REWARD, {flag = "showedPageComplete"})
                            end)
                        end
                    end, isOuterComplete)
                end)
            end)
        )
    )

end

-- 更新UI ----------------------------------------------------------------------
function PuzzleGameMainUI:updateUIByBuyGem()
    -- 刷新宝石
    self:updateGem()
end

function PuzzleGameMainUI:updateUIByBuyPicks()
    -- 刷新宝石
    self:updateGem()    
    -- 剩余点击次数
    self:updateLeftPicks()
    -- 购买次数进度
    self:updateBuyPicks()
    -- 按钮状态
    -- self:updateButton()
end

function PuzzleGameMainUI:updateUIByPick()
    -- 剩余点击次数
    self:updateLeftPicks()
    -- 按钮状态
    self:updateButton()
end

function PuzzleGameMainUI:updateUIByPuzzleFly(noCheckMax)
    -- 刷新碎片
    self:updateItems(noCheckMax)
    -- 刷新碎片进度
    self:updateItemPro(noCheckMax)
end

function PuzzleGameMainUI:updateItemPro(noCheckMax)
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    for i=1,#self.m_puzzleProLBs do
        local num = data.puzzle[i].count
        if not noCheckMax then
            num = num < 12 and num or 0
        end
        self.m_puzzleProLBs[i]:setString(num.."/12")
    end
end

function PuzzleGameMainUI:updateGem()
    if self.m_GemUI and self.m_GemUI.updateUI then
        self.m_GemUI:updateUI()
    end
end

function PuzzleGameMainUI:updateLeftPicks()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    self.m_leftPickLB:setString(data.pickLeft)
    self.m_spPickLeft:setVisible(data.pickLeft <= 1)
    self.m_spPicksLeft:setVisible(data.pickLeft > 1)
end

function PuzzleGameMainUI:updateBuyPicks()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    self.m_buyPickLB:setString(string.format("%d/%d", data.purchasePicks, data.purchasePicksLimit))
end

function PuzzleGameMainUI:updateButton()
    local data = CardSysRuntimeMgr:getPuzzleGameData()

    -- 收集按钮
    self.m_isShowCollect = false
    if data.box then
        for i = 1, #data.box do
            local boxData = data.box[i]
            if boxData and boxData.pick and not boxData.collect and boxData.type ~= "NONE" then
                self.m_isShowCollect = true
                break
            end
        end
    end

    if not data.hasPurchaseBox then
        self.m_collectBtn:setVisible(false)
        self.m_buyMoreBtn:setVisible(false)
    else
        
        self.m_collectBtn:setTouchEnabled(self.m_isShowCollect)
        self.m_collectBtn:setBright(self.m_isShowCollect)

        -- buy按钮
        local isShowBuyMore = data.purchasePicks < data.purchasePicksLimit
        self.m_buyMoreBtn:setTouchEnabled(isShowBuyMore)
        self.m_buyMoreBtn:setBright(isShowBuyMore)

        self.m_collectBtn:setVisible(true)

        -- local leftTime = 0
        -- if data then
        --     leftTime = math.max(0, util_getLeftTime(data.coolDown))
        -- end
        -- -- buy按钮
        -- if leftTime < (30 * 60) then
        --     self.m_buyMoreBtn:setTouchEnabled(false)
        --     self.m_buyMoreBtn:setBright(false)
        -- else
        --     local isShowBuyMore = data.purchasePicks < data.purchasePicksLimit
        --     self.m_buyMoreBtn:setTouchEnabled(isShowBuyMore)
        --     self.m_buyMoreBtn:setBright(isShowBuyMore)
        -- end
        self.m_buyMoreBtn:setVisible(true)
    end
end

function PuzzleGameMainUI:updateItems(noCheckMax)
    for i=1,#self.m_puzzleUIs do
        local ui = self.m_puzzleUIs[i]
        if ui and ui.updateUI then
            ui:updateUI(noCheckMax)
        end
    end
end

function PuzzleGameMainUI:updateBoxs()
    for i=1,#self.m_boxUIs do
        local ui = self.m_boxUIs[i]
        if ui and ui.updateUI then
            ui:updateUI()
        end
    end
end

function PuzzleGameMainUI:updatePickBoxs()
    for i=1,#self.m_boxUIs do
        local ui = self.m_boxUIs[i]
        if ui and ui.isPicked and ui:isPicked() and ui.updateUI then
            ui:updateUI()
        end
    end
end

-- 检查变箱子
function PuzzleGameMainUI:checkChangeBox()
    -- 判断是否变金宝箱
    if CardSysRuntimeMgr:isChangeToGoldenBox() then
        -- 发消息 未打开的银宝箱变成金宝箱
        self:setPlayChangeBox(true)
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHANGE_GOLDENBOX_START)
    else
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_OVER)
    end
end

-- 播放增加PICKS次数特效
function PuzzleGameMainUI:playAddPicksAction(startWorldPos, callback)
    local parentNode = self.m_leftPickLB:getParent()
    local startPos = parentNode:convertToNodeSpace(startWorldPos)
    local endPos = cc.p(self.m_leftPickLB:getPositionX(), self.m_leftPickLB:getPositionY())
    local flyParticle = cc.ParticleSystemQuad:create("CardRes/season201904/CashPuzzle/effects/xiaobaofei.plist")
    local boomParticle = nil
    flyParticle:setPosition(startPos)
    parentNode:addChild(flyParticle)

    performWithDelay(
        parentNode,
        function()

            local delayTime = cc.DelayTime:create(0.5)
            local callback2 =
                cc.CallFunc:create(
                function()
                    if boomParticle then
                        boomParticle:removeFromParent()
                    end
                    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardPuzzleGameAddPick)
                    local data = CardSysRuntimeMgr:getPuzzleGameData()
                    local _pickLeft = data.pickLeft
                    util_jumpNum(
                        self.m_leftPickLB,
                        (_pickLeft - 3),
                        _pickLeft,
                        1,
                        0.2,
                        nil,
                        nil,
                        nil,
                        function()
                            if callback then
                                callback()
                            end
                        end
                    )
                end
            )

            local moveToAction = cc.MoveTo:create(1, endPos)
            local callback1 =
                cc.CallFunc:create(
                function()
                    flyParticle:removeFromParent()
                    boomParticle = cc.ParticleSystemQuad:create("CardRes/season201904/CashPuzzle/effects/xiaobao.plist")
                    boomParticle:setPosition(endPos)
                    parentNode:addChild(boomParticle)
                    local sequence2 = cc.Sequence:create(delayTime, callback2)
                    parentNode:runAction(sequence2)
                end
            )
            
            local sequence = cc.Sequence:create(moveToAction, callback1, delayTime, callback2)
            flyParticle:runAction(sequence)
        end,
        0.5
    )
end

--检查类型
function PuzzleGameMainUI:checkRewardsTpye(_boxData)
        local type = nil
        if _boxData.rewards[1].p_icon == "Game_NormalPuzzle" then
            type = "NORMAL_PUZZLE"
        elseif _boxData.rewards[1].p_icon == "Game_NadoPuzzle" then
            type = "NADO_PUZZLE"
        elseif _boxData.rewards[1].p_icon == "Game_GoldenPuzzle" then
            type = "GOLDEN_PUZZLE"
        end
        return type
end

return PuzzleGameMainUI