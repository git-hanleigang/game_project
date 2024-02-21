--[[
    集卡系统  指定卡组中卡片显示面板 数据来源于指定或手动选择的赛季
    201901 201902
--]]
local BaseCardClanView = util_require("GameModule.Card.baseViews.BaseCardClanView")
local CardClanView = class("CardClanView", BaseCardClanView)

function CardClanView:initDatas(index, enterFromAlbum)
    CardClanView.super.initDatas(self, index, enterFromAlbum)
    self:setLandscapeCsbName(CardResConfig.CardClanViewRes)
end

function CardClanView:getShowType(index)
    local clanData = self:getClanData(index)
    if not clanData then
        return nil
    end
    if clanData.type == CardSysConfigs.CardClanType.puzzle_normal or clanData.type == CardSysConfigs.CardClanType.puzzle_golden or clanData.type == CardSysConfigs.CardClanType.puzzle_link then
        return 1
    elseif clanData.type == CardSysConfigs.CardClanType.normal or clanData.type == CardSysConfigs.CardClanType.special then
        return 2
    end
end

-- 模拟pageview --
function CardClanView:initPageView()
    -- 初始化page的位置列表 --
    self.m_pagePosList = {}
    for i = 1, self.m_pageNum do
        self.m_pagePosList[i] = (i - 1) * self.m_pageWidth
    end

    -- 注册滑动和点击区域 --
    self.m_pageViewEx = ccui.Layout:create()
    self.m_pageViewEx:setName("pageViewEx")
    self.m_pageViewEx:setTag(10)
    self.m_pageViewEx:setTouchEnabled(true)
    self.m_pageViewEx:setSwallowTouches(false)
    self.m_pageViewEx:setContentSize(cc.size(self.m_pageWidth, self.m_pageHeight))
    self.m_pageViewEx:setClippingEnabled(true)
    self.m_pageViewEx:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    self.m_pageViewEx:setBackGroundColor(cc.c4b(255, 255, 255))
    self.m_pageViewEx:setBackGroundColorOpacity(0)

    -- 初始化pageNode --
    self.m_pageNode = cc.Node:create()
    self.m_pageViewEx:addChild(self.m_pageNode)

    self.m_pageList = {}
    for i = 1, self.m_pageNum do
        local pageNode = cc.Node:create()
        pageNode:setPosition(self.m_pagePosList[i], 0)
        self.m_pageNode:addChild(pageNode)
        self.m_pageList[i] = pageNode
    end

    self.m_PageRootNode:addChild(self.m_pageViewEx)
    -- 添加触摸事件 --
    self:addClick(self.m_pageViewEx)
end

-- 移动页面 ---- move left or right --
function CardClanView:movePageDir(nDir)
    if not self.m_bScrolling then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.AlbumSwitchPage)
        local nDestIndex = 0
        if nDir > 0 then
            nDestIndex = math.max(1, self.m_curPageIndex - 1)
        elseif nDir < 0 then
            nDestIndex = math.min(self.m_pageNum, self.m_curPageIndex + 1)
        end

        if nDestIndex == self.m_curPageIndex then
            return
        end

        self.m_curPageIndex = nDestIndex
        self:moveToPage(nDestIndex)
        self.m_bScrolling = true
        performWithDelay(
            self,
            function()
                self.m_bScrolling = false
            end,
            0.5
        )
    end
end

-- 移动具体页面展示 --
function CardClanView:moveToPage(nIndex, isInit)
    if not nIndex or nIndex <= 0 then
        return
    end
    self.m_pageNode:setPosition(cc.p(-self.m_pagePosList[nIndex], 0))
    self:setCurrentPage(nIndex)

    self:checkCardNewMark(nIndex)
    -- 现在不是必弹出了
    performWithDelay(
        self,
        function()
            CardSysManager:closeLinkCardView(1)

            if CardSysManager.isShowLinkCardLayer then
                if CardSysManager:isShowLinkCardLayer(isInit, self.m_enterFromAlbum) then
                    CardSysManager:showLinkCard(nIndex)
                end
            end
        end,
        0.2
    )
end

-- 移动完回调 --
function CardClanView:setCurrentPage(nIndex)
    local curPage = nIndex

    -- 初始化 当前 左侧 右侧面板 --
    self:updatePageInfo(curPage, true)
    -- self:updatePageInfo( curPage - 1  ,   true)
    -- self:updatePageInfo( curPage + 1  ,   true)

    -- -- 移除 左二 右二 面板数据 --
    -- self:updatePageInfo( curPage - 2  ,   false)
    -- self:updatePageInfo( curPage + 2  ,   false)

    self:updateOtherUI(curPage)
end

function CardClanView:updatePageInfo(nPageIndex, bAdded)
    if nPageIndex < 1 or nPageIndex > self.m_pageNum then
        return
    end

    if not self.m_pageList[nPageIndex] then
        return
    end

    if bAdded == false then
        -- 如果操作是移除 --
        self.m_pageList[nPageIndex]:removeAllChildren()
    else
        -- 如果操作是添加 --
        local nChildNum = self.m_pageList[nPageIndex]:getChildrenCount()
        if nChildNum > 0 then
            local cells = self.m_pageList[nPageIndex]:getChildren()
            if cells and #cells > 0 then
                for i = 1, #cells do
                    if cells[i].updateCell then
                        cells[i]:updateCell(nPageIndex)
                    end
                end
            end
            return
        end

        -- 在此处向 cardList 中添加卡片 --
        local view = nil
        local showType = self:getShowType(nPageIndex)
        if showType ~= nil then
            if showType == 1 then
                view = util_createView("GameModule.Card.season201901.CardClanCellWild")
            else
                view = util_createView("GameModule.Card.season201901.CardClanCell")
            end
        end
        if view then
            view:setPosition(cc.p(self.m_pageWidth / 2, self.m_pageHeight / 2))
            self.m_pageList[nPageIndex]:addChild(view)
            -- 更新ui
            view:updateCell(nPageIndex)
        end
    end
end

-- 处理当前页面其他操作 例如顶部主题等 --
function CardClanView:updateOtherUI(index)
    CardClanView.super.updateOtherUI(self, index)
    self:updateBg(index)
end

-- 加载标题
function CardClanView:updateTitle(curPage)
    local clanData = self:getClanData(curPage)
    if not clanData then
        return
    end
    self.m_titleNode:removeAllChildren()
    local titleUI = nil
    -- if clanData.albumId == "201901" then
    titleUI = self.m_titleNode:getChildByName("Title2019")
    if not titleUI then
        titleUI = util_createView("GameModule.Card.season201901.CardClanTitle", CardResConfig.CardClanTitle201901Res)
        titleUI:setName("Title2019")
        self.m_titleNode:addChild(titleUI)
    end
    -- elseif clanData.albumId == "201902" then
    --     titleUI = self.m_titleNode:getChildByName("Title201902")
    --     if not titleUI then
    --         local showType = self:getShowType(curPage)
    --         if showType == 1 then
    --             titleUI = util_createView("GameModule.Card.season201902.CardClanTitle201902", CardResConfig.CardClanTitle201902WildRes)
    --         elseif showType == 2 then
    --             titleUI = util_createView("GameModule.Card.season201901.CardClanTitle201901", CardResConfig.CardClanTitle201902NormalRes)
    --         end
    --         if titleUI then
    --             titleUI:setName("Title201902")
    --             self.m_titleNode:addChild(titleUI)
    --         end
    --     end
    -- end
    if titleUI then
        titleUI:updateView(curPage, clanData)
    end
end

-- 章节背景
function CardClanView:updateBg(curPage)
    local clanData = self:getClanData(curPage)
    if not clanData then
        return
    end
    local icon = CardResConfig.getCardClanBg(clanData.clanId)
    if icon then
        util_changeTexture(self.m_bg, icon)
    end
end

-- 点击事件 --
function CardClanView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self:canClick() then
        return
    end

    if name == "Button_x" then
        -- CardSysManager:closeCardAlbumView()
        -- CardSysRuntimeMgr:setSelAlbumID(CardSysRuntimeMgr:getCurAlbumID())
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardClanView()
        CardSysManager:showCardAlbumView()
    elseif name == "Button_back" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardClanView()
        CardSysManager:showCardAlbumView()
    elseif name == "Button_next1" or name == "layer_left" then
        if self.m_bScrolling == true then
            return
        end
        if self.m_curPageIndex <= 1 then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:movePageDir(1)
    elseif name == "Button_next" or name == "layer_right" then
        if self.m_bScrolling == true then
            return
        end
        if self.m_curPageIndex >= self.m_pageNum then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:movePageDir(-1)
    end
end

return CardClanView
