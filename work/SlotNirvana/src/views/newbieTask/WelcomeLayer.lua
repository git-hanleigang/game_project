--第一次进入游戏
local WelcomeLayer = class("WelcomeLayer", BaseLayer)
WelcomeLayer.m_step = nil
WelcomeLayer.m_baseNode = nil

function WelcomeLayer:initDatas()
    local csbName = "GuideNewUser/NewUserFirstLayer.csb"
    if gLobalViewManager:isLevelView() then
        csbName = "GuideNewUser/NewUserFirstLayer_slot.csb"
    end
    self:setLandscapeCsbName(csbName)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    -- self:setShowBgOpacity(0)
end

function WelcomeLayer:onEnter()
    WelcomeLayer.super.onEnter(self)
    -- performWithDelay(self,handler(self,self.initView),0.4)
    -- self:initView()
    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.comeCust.id) then
        local _firstLvName = "GameScreenReelRocks"
        release_print("jump to fist level:" .. _firstLvName)
        gLobalNoticManager:postNotification(
            ViewEventType.NOTIFY_LOBBY_ROLLTO_LEVEL_POS,
            {
                machineName = _firstLvName
            }
        )
    end
end

function WelcomeLayer:initGuide(index)
    for i = 1, 3 do
        local baseNode = self:findChild("Node_" .. i)
        if baseNode then
            if i == index then
                baseNode:setVisible(true)
                self.m_baseNode = baseNode
                -- local _node_0 = self.m_baseNode:getChildByName("Node_" .. i .. "_0")
                local _node_0 = self:findChild("Node_" .. i .. "_0")
                if _node_0 then
                    _node_0:setVisible(true)
                    local node_npc = _node_0:getChildByName("zhichaoren")
                    if node_npc then
                        self.m_npc = util_createView("views.newbieTask.GuideNpcNode")
                        node_npc:addChild(self.m_npc)
                        util_setCascadeOpacityEnabledRescursion(node_npc, true)
                        self.m_npc:showIdle(1)
                    end
                    -- local node_arrow = _node_0:getChildByName("arrow")
                    local node_arrow = self:findChild("arrow")
                    if node_arrow then
                        -- 添加小手
                        self.m_arrow = util_createView("views.newbieTask.GuideArrowNode")
                        node_arrow:addChild(self.m_arrow)
                        self.m_arrow:showIdle(1)
                    end
                end
            else
                baseNode:setVisible(false)
                local _node_0 = self:findChild("Node_" .. i .. "_0")
                if _node_0 then
                    _node_0:setVisible(false)
                end
            end
        end
    end
end

function WelcomeLayer:initView()
    local coinsCount = math.max(globalData.constantData.NOVICE_SERVER_INIT_COINS - FIRST_LOBBY_COINS, 0)
    self:findChild("BitmapFontLabel_1"):setString(util_formatCoins(coinsCount, 20))

    -- -- TODO FOR TEST
    -- if DEBUG == 2 then
    --     globalData.userRunData.gemNum = 9990
    -- end

    local gemNum = globalData.userRunData.gemNum or 0
    self:findChild("lb_gems_num"):setString(util_formatCoins(gemNum, 20))

    self:initGuide(1)
    -- local scale = self:getUIScalePro()
    -- self:setPosition(display.cx + (0 - 876 * 0.5) * scale, 100)
    -- self:setScale(0.8)

    self.m_step = 0
    --全屏点击
    -- local mask = util_newMaskLayer()
    -- self:addChild(mask, -1)
    -- mask:setScale(3)
    -- self.m_touchMask = mask
    -- -- mask:setOpacity(0)
    -- mask:onTouch(
    --     function(event)
    --         if event.name ~= "ended" then
    --             return true
    --         end
    --         if self.onClickMask then
    --             self:onClickMask()
    --         end
    --         return true
    --     end,
    --     false,
    --     true
    -- )
    gLobalSoundManager:playSound("Sounds/guide_move_pop.mp3")
    self:runCsbAction(
        "start",
        false,
        function()
            if self.showNpc then
                self:showNpc()
            end
        end,
        30
    )

    -- 定义 3秒 和气泡
    self.m_handleHideNpc =
        performWithDelay(
        self,
        function()
            self:hideNpcAndBubble()
        end,
        4
    )

    -- 定义 10秒后自动打开宝箱
    performWithDelay(
        self,
        function()
            if self.onClickMask then
                self:onClickMask()
            end
        end,
        7
    )
end

--快速点击
function WelcomeLayer:onClickMask()
    if not self.m_step then
        return
    end
    if self.m_step == 0 or self.m_step == 1 then
        self.m_step = 2
        self:pauseForIndex(40)
    elseif self.m_step == 2 then
        self:showGift()
    end
end

function WelcomeLayer:showNpc()
    if not self.m_step or self.m_step ~= 0 then
        return
    end
    self.m_step = 1
    self:runCsbAction(
        "start2",
        false,
        function()
            if self.m_step == 1 then
                self.m_step = 2
            end
            self:runCsbAction("idle", true, nil, 60)
        end,
        30
    )
end

function WelcomeLayer:hideNpcAndBubble()
    -- local node_qipao = self:findChild("node_qipao")
    local node_qipao = self:findChild("Node_1_0")
    if node_qipao then
        node_qipao:setVisible(false)
    end
end

function WelcomeLayer:showGift()
    if not self.m_step or self.m_step ~= 2 then
        return
    end
    self.m_step = 3
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_arrow then
                self.m_arrow:removeFromParent()
                self.m_arrow = nil
            end
            --礼盒静置1秒
            -- performWithDelay(self,function()
            --     if self.openGift then
            --         self:openGift()
            --     end
            -- end,1)
            if self.openGift then
                self:openGift()
            end
        end,
        30
    )
end
--打开礼盒
function WelcomeLayer:openGift()
    if not self.m_step or self.m_step ~= 3 then
        return
    end

    self.m_step = 4
    gLobalSoundManager:playSound("Sounds/guide_open_gift.mp3")
    self:runCsbAction(
        "open",
        false,
        function()
            if self.flyCoins then
                self:flyCoins()
            end
        end,
        30
    )

    performWithDelay(
        self,
        function()
            local Particle_2 = self:findChild("Particle_2")
            if Particle_2 then
                Particle_2:stopSystem()
                Particle_2:resetSystem()
            end

            local Particle_2_0 = self:findChild("Particle_2_0")
            if Particle_2_0 then
                Particle_2_0:stopSystem()
                Particle_2_0:resetSystem()
            end
        end,
        0.3
    )
end
--飞金币
function WelcomeLayer:flyCoins()
    if not self.m_step or self.m_step ~= 4 then
        return
    end
    self.m_step = 5
    local spCoins = self:findChild("vectoring_icon_1_1")
    local coinWPos = spCoins:getParent():convertToWorldSpace(cc.p(spCoins:getPosition()))

    local spGems = self:findChild("sp_gems_icon")
    local gemWPos = spGems:getParent():convertToWorldSpace(cc.p(spGems:getPosition()))
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_LOBBYCOINS_ZORDER, true)

    -- local endPos = globalData.flyCoinsEndPos
    -- local baseCoins = globalData.topUICoinCount
    local baseCoins = 0
    local rewardCoins = globalData.userRunData.coinNum - baseCoins

    local baseGems = 0
    local rewardGems = globalData.userRunData.gemNum - baseGems

    local flyList = {}
    if toLongNumber(rewardCoins) > toLongNumber(0) then
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = rewardCoins, startPos = coinWPos})
    end
    if rewardGems > 0 then
        table.insert(flyList, {cuyType = FlyType.Gem, addValue = rewardGems, startPos = gemWPos})
    end
    if #flyList > 0 then
        G_GetMgr(G_REF.Currency):playFlyCurrency(
            flyList,
            function()
                if not tolua.isnull(self) then
                    self:flyOver()
                end
            end
        )
    else
        self:flyOver()
    end

end

function WelcomeLayer:flyOver()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_LOBBYCOINS_ZORDER, false)
    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.goToFirstSlotGame.id) then
        globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.goToFirstSlotGame)
    end
    globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.initIcons)
    self:closeUI()
end

function WelcomeLayer:closeUI()
    if not self.m_step or self.m_step ~= 5 then
        return
    end
    self.m_step = 6
    if self.m_npc then
        self.m_npc:removeFromParent()
        self.m_npc = nil
    end

    WelcomeLayer.super.closeUI(self)
end

return WelcomeLayer
