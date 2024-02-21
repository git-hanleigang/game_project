--[[
    集卡系统 
    规则 菜单
--]]
local CardMenuNode = class("CardMenuNode", util_require("base.BaseView"))

CardMenuNode.m_isNormalState = nil

-- 初始化UI --
function CardMenuNode:initUI()
    self:createCsbNode(CardResConfig.CardMenuNodeRes)
    self.m_longNode = self:findChild("Node_long")
    self.m_normalNode = self:findChild("Node_normal")

    self.m_point = self:findChild("point")
    self.m_num = self:findChild("number")
    self.m_bg = self:findChild("bg")
    self.m_bgShortHeight = 100
    self.m_bgLongHeight = 200

    self:initData()

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.updateState then
                self:updateState()
            end
        end,
        ViewEventType.NOTIFY_HISTORY_RED_POINT
    )
end
function CardMenuNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
-- 点击事件 --
function CardMenuNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "layer_more" then
        if self.m_isNormalState then
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
            self:changeState("more")
        end
    elseif name == "layer_up" then
        if self.m_isNormalState then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:changeState("up")
    elseif name == "layer_rules" then
        -- performWithDelay(
        --     self,
        --     function()
        --         CardSysManager:hideRecoverSourceUI()
        --     end,
        --     0.3
        -- )
        if self.m_isNormalState then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 2 显示普通规则界面 --
        local view = util_createView("GameModule.Card.season201901.CardMenuRule")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    elseif name == "layer_prizes" then
        if self.m_isNormalState then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 显示奖励规则界面 --
        -- 如果没有赛季数据就请求一下，如果有不请求
        -- 获取当前赛季数据
        local function showPrizeRule()
            CardSysRuntimeMgr:setNetPrize(false)
            local view = util_createView("GameModule.Card.season201901.CardMenuPrize")
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            -- performWithDelay(
            --     self,
            --     function()
            --         CardSysManager:hideRecoverSourceUI()
            --     end,
            --     0.3
            -- )
        end
        showPrizeRule()
    elseif name == "layer_history" then
        if self.m_isNormalState then
            return
        end
        if self.m_showHistory then
            return
        end
        self.m_showHistory = true
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 查询历史掉落数据接口 --
        CardSysManager:showCardHistoryView(
            function()
                self.m_showHistory = false
                -- performWithDelay(
                --     self,
                --     function()
                --         self.m_showHistory = false
                --         CardSysManager:hideRecoverSourceUI()
                --     end,
                --     0.3
                -- )
            end
        )
    end
end

function CardMenuNode:initData()
    self.m_isNormalState = true
    self:initTouch()
    self:updateState(true)
end

function CardMenuNode:changeState(flag)
    self.m_isNormalState = not self.m_isNormalState
    self:updateState(false, true, flag)
end

function CardMenuNode:updateState(isInit, isChange, flag)
    -- 红点提示为历史新获得卡片数量提示，最大提示数值为50，点击History进入后移除红点
    local num = CardSysRuntimeMgr:getSeasonData():getHistoryNewNum()
    if num and num > 0 then
        self.m_point:setVisible(true)
        self.m_num:setString(num > 99 and 99 or num)
    else
        self.m_point:setVisible(false)
    end
    -- self.m_point:setVisible(false)
    if self.m_isNormalState then
        if isInit then
            -- self:runBgAction(true)
            -- 走start动画
            self:runCsbAction(
                "start",
                false,
                function()
                    self:runCsbAction("idle", true)
                end
            )
        else
            -- self:runBgAction()
            if flag == "up" then
                self:runCsbAction(
                    "start3",
                    false,
                    function()
                        self:runCsbAction("idle", true)
                    end
                )
            else
                self:runCsbAction("idle", true)
            end
        end
    else
        -- self:runBgAction()
        if isChange then
            if flag == "more" then
                self:runCsbAction(
                    "start2",
                    false,
                    function()
                        self:runCsbAction("idle2", true)
                    end
                )
            end
        else
            self:runCsbAction("idle2", true)
        end
    end
end

function CardMenuNode:initTouch()
    self.m_layermore = self:findChild("layer_more")
    self:addClick(self.m_layermore)
    self.m_layerup = self:findChild("layer_up")
    self:addClick(self.m_layerup)
    self.m_layerrules = self:findChild("layer_rules")
    self:addClick(self.m_layerrules)
    self.m_layerprizes = self:findChild("layer_prizes")
    self:addClick(self.m_layerprizes)
    self.m_layerhistory = self:findChild("layer_history")
    self:addClick(self.m_layerhistory)
end

function CardMenuNode:runBgAction(isInit)
    local size = self.m_bg:getContentSize()
    local oldLength = size.height
    local newLength = nil
    if self.m_isNormalState then
        if oldLength == self.m_bgShortHeight then
            return
        end
        newLength = self.m_bgShortHeight
    else
        if oldLength == self.m_bgLongHeight then
            return
        end
        newLength = self.m_bgLongHeight
    end
    -- 如果是初始化的，直接设置大小不用展示变化
    if isInit then
        self.m_bg:setContentSize({width = size.width, height = newLength})
        return
    end

    local costTime = 0.4 -- 总花费时间
    local frameTime = 0.03 -- 一帧时间
    local frameNum = math.floor(costTime / frameTime)
    local frameLength = (newLength - oldLength) / frameNum -- 每帧变化的长度
    local tempHeight = oldLength

    if self.m_sch ~= nil then
        self:stopAction(self.m_sch)
        self.m_sch = nil
    end
    self.m_sch =
        schedule(
        self,
        function()
            tempHeight = tempHeight + frameLength
            self.m_bg:setContentSize({width = size.width, height = tempHeight})
            if frameLength > 0 then
                if tempHeight >= newLength then
                    self:stopAction(self.m_sch)
                    self.m_sch = nil
                end
            else
                if tempHeight <= newLength then
                    self:stopAction(self.m_sch)
                    self.m_sch = nil
                end
            end
        end,
        frameTime
    )
end

return CardMenuNode
