--[[
    小转盘
    界面右上角显示用 
]]
local CardMenuWheel = class("CardMenuWheel", util_require("base.BaseView"))
function CardMenuWheel:initUI()
    self:createCsbNode(self:getCsbName())
    self:initCsb()
    self:initCountDown()
    self:updateRedPoint()
end

function CardMenuWheel:initCsb()
    self.m_countDownLabel = self:findChild("BitmapFontLabel_1")
    self.m_redPointNode = self:findChild("Node_redPoint")
    self.m_touch = self:findChild("Panel_wheel")
    self:addClick(self.m_touch)
end

function CardMenuWheel:getCsbName()
    return CardResConfig.CardMenuWheelNodeRes
end

function CardMenuWheel:getBubbleLua()
    return "GameModule.Card.season201903.CardMenuWheelBubble"
end

function CardMenuWheel:getRedPointLua()
    assert(false, "子类必须重写")
end

function CardMenuWheel:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_wheel" then
        self:openRecoverUI()
    end
end

function CardMenuWheel:openRecoverUI()
    -- 冷却状态下，点击图标不能进入回收系统界面，且无任何反馈
    local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
    local remainTime = math.max(util_getLeftTime(finalTime), 0)
    if remainTime > 0 then
        -- 弹出气泡提示不能进入
        self:showLettoBubble()
        return
    end
    -- -- 回收机回收卡片 --
    if self.m_ClickWheel then
        return
    end
    self.m_ClickWheel = true
    CardSysRuntimeMgr:setClickOtherInAlbum(true)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)

    -- 小于第三档要求但大于第一档要求时，红点在点击入口后消失
    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    if yearData then
        local wheelCfg = yearData:getWheelConfig()
        if wheelCfg then
            local lettosData = wheelCfg:getLettos()
            if lettosData then
                local starNum = wheelCfg:getStarNum()
                local minNeedStarNum = lettosData[1].needStars
                local maxNeedStarNum = lettosData[3].needStars
                if starNum and starNum >= minNeedStarNum and starNum < maxNeedStarNum then
                    gLobalDataManager:setNumberByField("CardRecover", 1)
                end
            end
        end
    end

    CardSysManager:getRecoverMgr():showRecoverView(
        function()
            performWithDelay(
                self,
                function()
                    self.m_ClickWheel = false
                end,
                0.3
            )
            performWithDelay(
                self,
                function()
                    CardSysManager:hideRecoverSourceUI()
                end,
                0.3
            )
        end
    )
end

function CardMenuWheel:initCountDown()
    local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
    local remainTime = math.max(util_getLeftTime(finalTime), 0)
    if remainTime == 0 then
        self:runCsbAction("idle", true, nil, 60)
    elseif remainTime > 0 then
        self:runCsbAction("idle1", true, nil, 60)
        self.m_countDownLabel:setString(util_count_down_str(remainTime))
    end
end

function CardMenuWheel:updateRedPoint()
    local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
    local remainTime = math.max(util_getLeftTime(finalTime), 0)
    if remainTime == 0 and self:isComplete() then
        if self.m_redPointNode then
            if not self.m_numUI then
                self.m_numUI = util_createView(self:getRedPointLua())
                self.m_redPointNode:addChild(self.m_numUI)
            end
            self.m_numUI:updateNum(1)
        end
    else
        if self.m_numUI ~= nil then
            self.m_numUI:removeFromParent()
            self.m_numUI = nil
        end
    end
end

function CardMenuWheel:getWheelCountDown()
    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    if yearData then
        local wheelCfg = yearData:getWheelConfig()
        if wheelCfg then
            return wheelCfg:getCooldown()
        end
    end
end

function CardMenuWheel:onEnter()
    -- 每秒刷新一次的消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initCountDown()
            self:updateRedPoint()
        end,
        CardSysConfigs.ViewEventType.CARD_COUNTDOWN_UPDATE
    )
    -- -- 数据刷新后更新
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         if not tolua.isnull(self) then
    --         end
    --     end,
    --     ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO
    -- )
end

function CardMenuWheel:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 乐透气泡
function CardMenuWheel:showLettoBubble()
    if self.m_lettoBubbleUI ~= nil then
        return
    end
    local finalTime = math.floor(tonumber(self:getWheelCountDown() or 0))
    local remainTime = math.max(util_getLeftTime(finalTime), 0)
    if finalTime == 0 then
        return
    end
    local spMachine = self:findChild("sp_machine")
    local machineSize = spMachine:getContentSize()
    self.m_lettoBubbleUI = util_createView(self:getBubbleLua())
    self.m_lettoBubbleUI:setOverFunc(
        function()
            self.m_lettoBubbleUI = nil
        end
    )
    self.m_lettoBubbleUI:setPosition(cc.p(machineSize.width * 0.5, machineSize.height))
    spMachine:addChild(self.m_lettoBubbleUI)
    self.m_lettoBubbleUI:updateTime(remainTime)
end

function CardMenuWheel:isComplete()
    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    if yearData then
        local wheelCfg = yearData:getWheelConfig()
        if wheelCfg then
            local lettosData = wheelCfg:getLettos()
            if lettosData then
                local starNum = wheelCfg:getStarNum()
                local minNeedStarNum = lettosData[1].needStars
                local maxNeedStarNum = lettosData[3].needStars
                if starNum and starNum >= minNeedStarNum and starNum < maxNeedStarNum then
                    if gLobalDataManager:getNumberByField("CardRecover", 0) == 0 then
                        return true
                    end
                elseif wheelCfg:getStarNum() >= maxNeedStarNum then
                    return true
                end
            end
        end
    end
    return false
end

return CardMenuWheel
