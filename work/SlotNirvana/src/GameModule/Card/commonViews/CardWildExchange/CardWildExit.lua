--
-- wild兑换面板关闭时的确认面板
--
local CardWildExit = class("CardWildExit", BaseLayer)

function CardWildExit:initDatas(closeFunc)
    self.closeFunc = closeFunc
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardWildExitRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
end

-- 初始化UI --
function CardWildExit:initUI(closeFunc)
    CardWildExit.super.initUI(self)
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end

    -- self:createCsbNode(string.format(CardResConfig.commonRes.CardWildExitRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)
    self.m_root = self:findChild("root")

    -- self.closeFunc = closeFunc
    self:initData()

    -- self:runCsbAction(
    --     "show",
    --     false,
    --     function()
    --         if self.isClose then
    --             return
    --         end
    --         self:runCsbAction("idle", true)
    --     end,
    --     60
    -- )
end

--适配方案 --
-- function CardWildExit:getUIScalePro()
--     local x = display.width / DESIGN_SIZE.width
--     local y = display.height / DESIGN_SIZE.height
--     local pro = x / y
--     if globalData.slotRunData.isPortrait == true then
--         pro = 0.8
--     end
--     return pro
-- end

-- 初始化数据 --
function CardWildExit:initData()
    self:initCountDown()
end

-- 倒计时 --
function CardWildExit:initCountDown()
    self.timeNode = self:findChild("Font_ts_time")
    local albums = CardSysManager:getWildExcMgr():getRunData():getCardExchangeYearCardsInfo()
    local finalTime = math.floor(albums.expireAt / 1000)
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local remainTime = finalTime - curTime
    self.timeNode:setString(tostring(util_count_down_str(remainTime)))

    self.m_countDownTime =
        util_schedule(
        self,
        function()
            local curTime = os.time()
            if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                curTime = globalData.userRunData.p_serverTime / 1000
            end
            remainTime = finalTime - curTime
            self.timeNode:setString(tostring(util_count_down_str(remainTime)))

            if remainTime <= 0 then
                if self.m_countDownTime ~= nil then
                    self:stopAction(self.m_countDownTime)
                end
                self.m_countDownTime = nil
                CardSysManager:getWildExcMgr():closeWildExit()
            end
        end,
        1
    )
end

-- 点击事件 --
function CardWildExit:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_close" then
        CardSysManager:getWildExcMgr():closeWildExit()
        if self.closeFunc then
            self.closeFunc()
        end
    elseif name == "Button_stay" then
        CardSysManager:getWildExcMgr():closeWildExit()
    end
end

function CardWildExit:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardWildExit.super.playShowAction(self, "show", false)
end

function CardWildExit:onShowedCallFunc()
    if self.isClose then
        return
    end
    self:runCsbAction("idle", true)
end

function CardWildExit:playHideAction()
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    CardWildExit.super.playHideAction(self, "over", false)
end

-- 关闭事件 --
function CardWildExit:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    CardWildExit.super.closeUI(self)
    -- self:runCsbAction(
    --     "over",
    --     false,
    --     function()
    --         self:removeFromParent()
    --     end,
    --     60
    -- )
end

function CardWildExit:onEnter()
    CardWildExit.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getWildExcMgr():closeWildExit()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    -- -- 新手期结束
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         CardSysManager:getWildExcMgr():closeWildExit()
    --     end,
    --     ViewEventType.CARD_NOVICE_OVER
    -- )
end

-- function CardWildExit:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

return CardWildExit
