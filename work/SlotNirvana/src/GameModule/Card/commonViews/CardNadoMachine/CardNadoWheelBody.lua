local CardNadoWheelBody = class("CardNadoWheelBody", util_require("base.BaseView"))

local BIG_COINS = 20000 --最大美金
function CardNadoWheelBody:initUI(node)
    self.m_nadoWheelMainUI = node
    self:createCsbNode(string.format(CardResConfig.commonRes.CardNadoWheelBodyRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))

    self:runCsbAction("idle", true)

    self:initParticle()

    self:initData()
    self:initWheel()
    self:initWheelItems()
    self:initSpinBtn()
    self:initSpinHandle()
end

function CardNadoWheelBody:initParticle()
    self.m_paperParticle1 = self:findChild("Particle_1")
    self.m_paperParticle2 = self:findChild("Particle_2")
    self.m_paperParticle3 = self:findChild("Particle_3")
    self.m_paperParticle1:setVisible(false)
    self.m_paperParticle2:setVisible(false)
    self.m_paperParticle3:setVisible(false)
end

function CardNadoWheelBody:playParticle()
    self.m_paperParticle1:setVisible(true)
    self.m_paperParticle2:setVisible(true)
    self.m_paperParticle3:setVisible(true)
    self.m_paperParticle1:stopSystem()
    self.m_paperParticle1:resetSystem()
    self.m_paperParticle2:stopSystem()
    self.m_paperParticle2:resetSystem()
    self.m_paperParticle3:stopSystem()
    self.m_paperParticle3:resetSystem()
end

function CardNadoWheelBody:initCheckPrize(enabled)
    self.m_nadoWheelMainUI:initCheckPrize(enabled)
end

function CardNadoWheelBody:showPrize(hideLater)
    self.m_nadoWheelMainUI:showPrize(hideLater)
end

function CardNadoWheelBody:getReward()
    return self.m_nadoWheelMainUI:getReward()
end

function CardNadoWheelBody:getLeftCount()
    return self.m_nadoWheelMainUI:getLeftCount()
end

function CardNadoWheelBody:initOneSpin()
    return self.m_nadoWheelMainUI:initOneSpin()
end

function CardNadoWheelBody:getOnOffSpin()
    return self.m_nadoWheelMainUI:getOnOffSpin()
end

function CardNadoWheelBody:playWheelWinAction(overFunc)
    self.m_wheelRewardItems[self.m_resultIndex]:playScaleAction(overFunc)
end

function CardNadoWheelBody:initData()
    self.m_resultIndex = nil -- 停止位置
end

function CardNadoWheelBody:initSpinBtn()
    self.m_spinUI = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelSpin", self)
    self.m_nadoWheelMainUI.m_spinNode:addChild(self.m_spinUI)
end

-- 创建把手动画
function CardNadoWheelBody:initSpinHandle()
    local res_path = string.format(CardResConfig.commonRes.CardNadoWheelSpinHandleRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
    if util_IsFileExist(res_path) then
        self.handleActNode = util_createAnimation(res_path)
        self.m_nadoWheelMainUI.m_spinHandleNode:addChild(self.handleActNode)
    end
end

function CardNadoWheelBody:getSpinUI()
    return self.m_spinUI
end

function CardNadoWheelBody:initWheel()
    --添加左右齿轮动画
    local Node_chilunL = self:findChild("Node_chilunL")
    if Node_chilunL then
        self.m_lunL = util_createAnimation(string.format(CardResConfig.commonRes.CardNadoWheelWheelRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        Node_chilunL:addChild(self.m_lunL)
    end
    local Node_chilunR = self:findChild("Node_chilunR")
    if Node_chilunR then
        self.m_lunR = util_createAnimation(string.format(CardResConfig.commonRes.CardNadoWheelWheelRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        Node_chilunR:addChild(self.m_lunR)
    end

    --添加滚动区域
    self:addWheelControl()

    --添加刚进入提示
    local node_tips = self:findChild("node_tips")
    if globalData.slotRunData.isPortrait == true then
        node_tips:setPositionX(70)
    end
    if node_tips then
        self.m_tipNode = util_createAnimation(string.format(CardResConfig.commonRes.CardNadoWheelBubbleRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        node_tips:addChild(self.m_tipNode, 1)
        local m_lb_coins = self.m_tipNode:findChild("m_lb_coins")
        m_lb_coins:setString("$" .. util_getFromatMoneyStr(globalData.constantData.CARD_NADOMACHINE_BUBBLE_DOLLOR or 0))
        self.m_tipNode:setVisible(false)

        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) and self.m_tipNode then
                    self.m_tipNode:setVisible(true)
                    self.m_tipNode:runCsbAction("show")
                end
            end,
            0.5
        )
    end
end

function CardNadoWheelBody:addWheelControl()
    local clip_node = self:findChild("clip_node")
    if clip_node then
        local linkGameData = CardSysRuntimeMgr:getLinkGameData()
        local cellCount = #linkGameData.cells --小块总数量
        self.m_wheelControl = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelControl", clip_node, cellCount, handler(self, self.stopWheel), handler(self, self.overWheel))
        self:addChild(self.m_wheelControl)
        self.m_wheelRewardNodes = self.m_wheelControl:getListNode()
    end
end
function CardNadoWheelBody:resetWheelControl()
    if not self.m_wheelControl then
        self:addWheelControl()
        return
    end
    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    local cellCount = #linkGameData.cells --小块总数量
    self.m_wheelControl:resetCell(cellCount)
    self.m_wheelRewardNodes = self.m_wheelControl:getListNode()
end

--初始化小块
function CardNadoWheelBody:initWheelItems()
    self.m_wheelRewardItems = {}
    for i = 1, #self.m_wheelRewardNodes do
        local ree = self.m_wheelRewardNodes[i]
        local view = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelItem", i)
        ree:addChild(view)
        self.m_wheelRewardItems[i] = view
    end
end

function CardNadoWheelBody:updatWheelItems()
    if self.m_wheelRewardItems and #self.m_wheelRewardItems > 0 then
        for i = 1, #self.m_wheelRewardItems do
            if self.m_wheelRewardItems[i] and self.m_wheelRewardItems[i].initView then
                self.m_wheelRewardItems[i]:initView()
            end
        end
    end
end

function CardNadoWheelBody:hideItemsParticle()
    if self.m_wheelRewardItems and #self.m_wheelRewardItems > 0 then
        for i = 1, #self.m_wheelRewardItems do
            local item = self.m_wheelRewardItems[i]
            if item then
                item:hideParticle()
            end
        end
    end
end

-- 刷新轮盘
function CardNadoWheelBody:updateWheelInfo()
    -- 当轮盘上的个数发生变化时重新生成轮盘数据
    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    if not self.m_preCellCount then
        self.m_preCellCount = #linkGameData.cells --小块总数量
    end
    if self.m_preCellCount ~= #linkGameData.cells then
        self.m_preCellCount = #linkGameData.cells
        self:resetWheelControl()
        self:initWheelItems()
    else
        self:updatWheelItems()
    end
end

--重置界面
function CardNadoWheelBody:resetView()
    self.m_resultIndex = nil
    self.m_wheelControl:resetWheel()
end

--接受服务器数据
function CardNadoWheelBody:recvData(index)
    --真实索引
    self.m_resultIndex = index
    self.m_wheelControl:recvData(self.m_resultIndex)
end

function CardNadoWheelBody:beginWheel()
    self:runCsbAction("idle", true)
    self.m_nadoWheelMainUI:initOneSpin()
    self:beginWheelAction()
    local spinSuccess = function(tInfo)
        if not tolua.isnull(self) then
            local linkGameData = CardSysRuntimeMgr:getLinkGameData()
            self:recvData(linkGameData.index + 1)
            --播放大奖动画
            local cellData = linkGameData.cells[self.m_resultIndex]
            if cellData.type == "BIG_COINS" then
                self.m_wheelControl:setAccSpeed(true)
                self:runCsbAction("run", true, nil, 30)
            end
        end
    end
    local spinFaild = function()
        gLobalViewManager:showReConnect()
    end
    local updateMainUI = function()
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_NADO_WHEEL_ROLL_OVER)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO)
        if not tolua.isnull(self) then
            if self.m_nadoWheelMainUI then
                self.m_nadoWheelMainUI:initLeftCount()
            end
        end
    end
    -- 发送spin消息 --
    CardSysNetWorkMgr:sendCardLinkPlayRequest({status = 0}, spinSuccess, spinFaild, updateMainUI)
end

function CardNadoWheelBody:beginWheelAction()
    --移除提示
    if self.m_tipNode then
        self.m_tipNode:runCsbAction(
            "over",
            false,
            function()
                self.m_tipNode:removeFromParent()
                self.m_tipNode = nil
            end,
            30
        )
    end

    --播放齿轮动画
    if self.m_lunL then
        self.m_lunL:runCsbAction("idle2", true)
    end
    if self.m_lunR then
        self.m_lunR:runCsbAction("idle2", true)
    end

    if self.handleActNode then
        self.handleActNode:playAction("start",false)
    end

    -- 后端数据更改，更新轮盘数据
    self:updateWheelInfo()

    self.m_wheelControl:setAccSpeed(false)
    self.m_wheelControl:beginWheel()
    if self.m_spinUI and self.m_spinUI.beginWheel then
        self.m_spinUI:beginWheel()
    end
end

--准备停止
function CardNadoWheelBody:stopWheel()
    if self.m_lunL then
        self.m_lunL:runCsbAction("over")
    end
    if self.m_lunR then
        self.m_lunR:runCsbAction("over")
    end
end
--播放奖励动画
function CardNadoWheelBody:overWheel()
    self:playParticle()
    if self.m_spinUI and self.m_spinUI.overWheel then
        self.m_spinUI:overWheel()
    end

    -- if self.m_rollSound ~= nil then
    --     gLobalSoundManager:stopAudio(self.m_rollSound)
    --     self.m_rollSound = nil
    -- end

    -- 播放中奖特效
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardNadoMachineWinPrize)
    self:runCsbAction("reward", true)
end

function CardNadoWheelBody:setItemTouchEnabled(_enabled)
    for i,v in ipairs(self.m_wheelRewardItems) do
        v:setItemTouchEnabled(_enabled)
    end
end

return CardNadoWheelBody
