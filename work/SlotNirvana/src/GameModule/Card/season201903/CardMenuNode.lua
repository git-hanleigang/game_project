--[[
    集卡系统 菜单
    201903赛季
--]]
local CardMenuNode = class("CardMenuNode", util_require("base.BaseView"))

-- 可重写
function CardMenuNode:getCsbName()
    return string.format(CardResConfig.seasonRes.CardMenuNodeRes, "season201903")
end

-- 可重写
function CardMenuNode:getRuleLua()
    return "GameModule.Card.season201903.CardMenuRule"
end

-- 可重写
function CardMenuNode:getPrizeLua()
    return "GameModule.Card.season201903.CardMenuPrize"
end

-- 初始化UI --
function CardMenuNode:initUI(mainClass)
    self.m_mainClass = mainClass

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(self:getCsbName(), isAutoScale)

    self.m_root = self:findChild("root")
    self.m_bg = self:findChild("Image_1")
    self.m_mask = self:findChild("Image_3")
    self:addClick(self.m_mask)

    self.m_nodeCollection = self:findChild("Button_collection")
    self.m_nodeChallenge = self:findChild("Button_challenge")

    self:initAdapt()

    self:initData()

    self:initView()
end

function CardMenuNode:initAdapt()
    local pro = self.m_mainClass:getMainClass():getUIScalePro()
    local p = self:getUIScalePro()
    pro = math.min(1, pro * p)

    local bgSize = self.m_bg:getContentSize()
    self.m_bg:setContentSize(cc.size(bgSize.width, display.height / pro))
end

function CardMenuNode:playStartAction(overCallF)
    self.m_PlayAction = true
    self:runCsbAction(
        "start",
        false,
        function()
            if overCallF then
                overCallF()
            end
            self.m_PlayAction = false
            self:runCsbAction("idle")
        end
    )
end
function CardMenuNode:playOverAction(overCallF)
    self.m_PlayAction = true
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_PlayAction = false
            if overCallF then
                overCallF()
            end
        end
    )
end
function CardMenuNode:onEnter()
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

function CardMenuNode:canClick()
    if self.m_PlayAction then
        return false
    end
    if self.m_Clicked then
        return false
    end
    return true
end

-- 点击事件 --
function CardMenuNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self:canClick() then
        return
    end
    self.m_Clicked = true

    if name == "Button_rules" then
        -- performWithDelay(
        --     self,
        --     function()
        --         CardSysManager:hideRecoverSourceUI()
        --     end,
        --     0.3
        -- )
        CardSysRuntimeMgr:setClickOtherInAlbum(true)

        performWithDelay(
            self,
            function()
                self.m_Clicked = false
            end,
            0.5
        )

        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 2 显示普通规则界面 --
        local view = util_createView(self:getRuleLua())
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    elseif name == "Button_prizes" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)

        performWithDelay(
            self,
            function()
                self.m_Clicked = false
            end,
            0.5
        )

        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 显示奖励规则界面 --
        -- 如果没有赛季数据就请求一下，如果有不请求
        -- 获取当前赛季数据
        local function showPrizeRule()
            local view = util_createView(self:getPrizeLua())
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            -- performWithDelay(
            --     self,
            --     function()
            --         CardSysManager:hideRecoverSourceUI()
            --     end,
            --     0.3
            -- )
        end
        local albumInfo = CardSysRuntimeMgr:getCardAlbumInfo()
        if not albumInfo then
            local yearID = CardSysRuntimeMgr:getCurrentYear()
            local albumId = CardSysRuntimeMgr:getCurAlbumID()
            local tExtraInfo = {["year"] = yearID, ["albumId"] = albumId}
            CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, showPrizeRule)
        else
            showPrizeRule()
        end
    elseif name == "Button_history" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)

        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 查询历史掉落数据接口 --
        CardSysManager:showCardHistoryView(
            function()
                self.m_Clicked = false
                -- performWithDelay(
                --     self,
                --     function()
                --         self.m_Clicked = false
                --     end,
                --     0.3
                -- )
                -- CardSysManager:hideRecoverSourceUI()
            end
        )
    elseif name == "Button_collection" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)
        performWithDelay(
            self,
            function()
                self.m_Clicked = false
            end,
            0.5
        )
        -- 以往赛季入口
        CardSysManager:showCardCollectionUI()
    elseif name == "Button_challenge" then
        performWithDelay(
            self,
            function()
                self.m_Clicked = false
            end,
            0.5
        )

        -- 挑战界面可见入口
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if CardSysRuntimeMgr.m_CardSeasonsInfo and CardSysRuntimeMgr.m_CardSeasonsInfo.p_collectNado then
            CardSysManager:getLinkMgr():showCardLinkProgressComplete(
                {
                    -- csb = string.format(CardResConfig.commonRes.linkProgress201903, "common" .. CardSysRuntimeMgr:getCurAlbumID()),
                    data = CardSysRuntimeMgr.m_CardSeasonsInfo.p_collectNado,
                    isDrop = false
                }
            )
        end
    elseif name == "Image_3" then
        performWithDelay(
            self,
            function()
                self.m_Clicked = false
            end,
            0.5
        )
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_MENU_CLOSE)
    end
end

function CardMenuNode:initData()
    self:updateState()
end

function CardMenuNode:initView()
    -- self:initMenuBtn()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        self.m_nodeCollection:setVisible(false)
        self.m_nodeChallenge:setVisible(false)
    end
end

function CardMenuNode:updateState()
    -- -- 红点提示为历史新获得卡片数量提示，最大提示数值为50，点击History进入后移除红点
    -- local num = CardSysRuntimeMgr:getSeasonData():getHistoryNewNum()
    -- if num and num > 0 then
    --     self.m_point:setVisible(true)
    --     self.m_num:setString(num > 99 and 99 or num)
    -- else
    --     self.m_point:setVisible(false)
    -- end
end

return CardMenuNode
