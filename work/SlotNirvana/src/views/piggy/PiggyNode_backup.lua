local PiggyNode = class("PiggyNode",util_require("base.BaseView"))

function PiggyNode:initUI(data)
    self:createCsbNode("GameNode/Piggy.csb",false)
    self.m_particleNode = self:findChild("Node_part") -- Node_particles
    self.Particle_1 = self:findChild("Particle_1")
    self.Particle_2 = self:findChild("Particle_2")
    self.Particle_1:stopSystem()
    self.Particle_2:stopSystem()
    local touchLayer = self:findChild("touch_layer")
    self:addClick(touchLayer)
    self:initPigBankData()
    
    self:findChild("touch_layer1"):setFlippedX(true)
end

function PiggyNode:initPigBankData()
    self.m_piggy_msg = self:findChild("piggy_msg")
    self.m_piggy_msg:setVisible(false)
    self.m_piggy_lock = self:findChild("suotou_1")

    local levelNum = globalData.userRunData.levelNum or 1
    local unlock = globalData.constantData.OPENLEVEL_PIGBANK or 6
    if levelNum < unlock then
        self:runCsbAction("lock",false)
        self:findChild("touch_layer1"):setBright(false)
        self.m_piggy_lock:setVisible(true)
    else
        self.m_piggy_lock:setVisible(false)
        self:findChild("touch_layer1"):setBright(true)
        self:playIdle()
    end
    self:initPiggyNoviceDiscount()
end

function PiggyNode:initPiggyNoviceDiscount()
    self.m_noviceNode = self:findChild("novice")
    local isIn = globalData.iapRunData.p_pigCoinData:checkInNoviceDiscount() 
    if isIn then
        self.m_noviceNode:setVisible(true)
        local child = self.m_noviceNode:getChildByName("novice")
        if not child then
            child = util_createView("views.piggy.PiggyNoviceBgNode")
            self.m_noviceNode:addChild(child)
        end
    else
        self.m_noviceNode:setVisible(false)
    end
end

function PiggyNode:playIdle()
    self:runCsbAction("act_2",true)
end

-- 关卡内bet变化的时候 播放动画
function PiggyNode:changeBetValue(type)
    local levelNum = globalData.userRunData.levelNum or 1
    local unlock = globalData.constantData.OPENLEVEL_PIGBANK or 6
    if levelNum < unlock then
        return
    end
    if type == "add" then
        self:runCsbAction("Bet_up")
        self:playAddBetParticle()
    elseif type == "sub" then
        self:runCsbAction("Bet_down")
    elseif type == "max" then
        self:runCsbAction("Bet_up")
        self:playMaxBetParticle()
    end
end

-- 播放bet增加时的粒子效果
function PiggyNode:playAddBetParticle()
    self.Particle_1:stopSystem()
    self.Particle_1:resetSystem()
end

function PiggyNode:playMaxBetParticle()
    self.Particle_2:stopSystem()
    self.Particle_2:resetSystem()
end


function PiggyNode:addCollectCoin(betCoin)
    --此处累计bet 用于计算spin赠备器  和 spin次数debug
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPIN,betCoin)
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_PIGBANK then
        return
    end

    self:runCsbAction("act_1",false,function()
        self:playIdle()
    end)

end

function PiggyNode:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "touch_layer" then
        if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_PIGBANK then
            self:clickTips(self.m_piggy_msg)
        else
            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen","upPigBankIcon")
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_pig)
            end

            --local view = G_GetMgr(ACTIVITY_REF.PinBallGo):showPinBallGoGameView()

            G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
                local dotEntryNode = gLobalViewManager:isLobbyView() and DotEntryType.Lobby or DotEntryType.Game
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(view,name,DotUrlType.UrlName,true,DotEntrySite.UpView,dotEntryNode)
                end
            end)            
        end
    end
end

function PiggyNode:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        self:initPigBankData()
    end,ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA)
    gLobalNoticManager:addObserver(self,function(self,params)
        --self:openPigTishi()
        self:initPigBankData()
     end,ViewEventType.NOTIFY_PIGBANK_TISHI)

     gLobalNoticManager:addObserver(self,function(self,params)
        self:changeBetValue(params.type)
    end,ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE)
end

function PiggyNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function PiggyNode:clickTips(node)
    if not node then
        return
    end
    if node:isVisible() then
        node:setVisible(false)
        return
    end
    node:setVisible(true)
    gLobalViewManager:addAutoCloseTips(node,function()
        performWithDelay(self,function()
            if not tolua.isnull(node) then
                node:setVisible(false)
            end
        end,0.1)
    end)
end

return PiggyNode
