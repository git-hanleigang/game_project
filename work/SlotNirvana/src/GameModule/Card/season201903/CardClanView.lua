--[[
    集卡系统  指定卡组中卡片显示面板 数据来源于指定或手动选择的赛季
    201903
--]]
local BaseCardClanView = util_require("GameModule.Card.baseViews.BaseCardClanView")
local CardClanView = class("CardClanView", BaseCardClanView)

function CardClanView:initDatas(index, enterFromAlbum)
    CardClanView.super.initDatas(self, index, enterFromAlbum)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardClanViewRes, "season201903"))
end

-- 重写
function CardClanView:getCellLua()
    return "GameModule.Card.season201903.CardClanCell"
end

-- 重写
function CardClanView:getTitleLua()
    return "GameModule.Card.season201903.CardClanTitle"
end

-- 关闭事件 --
function CardClanView:closeUI(exitFunc)
    if self.titleUI ~= nil and not tolua.isnull(self.titleUI) and self.titleUI.closeUI then
        self.titleUI:closeUI()
        self.titleUI = nil
    end
    CardClanView.super.closeUI(self, exitFunc)
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
        local pageList = self.m_pageList
        local curShowPageIndex = self.curShowPageIndex
        local movePageFlag = self.titleUI == nil or (self.titleUI.getMovePageFlag and self.titleUI:getMovePageFlag())
        if curShowPageIndex ~= nil and pageList ~= nil and pageList[curShowPageIndex] ~= nil and movePageFlag then
            for k, v in ipairs(pageList[curShowPageIndex]:getChildren()) do
                movePageFlag = v:getMovePageFlag()
                if not movePageFlag then
                    break
                end
            end
        end
        if movePageFlag then
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
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.AlbumSwitchPage)
            performWithDelay(
                self,
                function()
                    self.m_bScrolling = false
                end,
                0.5
            )
        end
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
    --释放之前打开的界面
    if self.curShowPageIndex ~= nil then
        self:updatePageInfo(self.curShowPageIndex, false)
    end
    -- 初始化 当前 左侧 右侧面板 --
    self:updatePageInfo(nIndex, true)
    self:updateOtherUI(nIndex)
    self.curShowPageIndex = nIndex
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
        -- 在此处向 cardList 中添加卡片 --
        local view = util_createView(self:getCellLua())
        if view then
            view:setPosition(cc.p(self.m_pageWidth / 2, self.m_pageHeight / 2))
            self.m_pageList[nPageIndex]:addChild(view)
            if self.curShowPageIndex == nil then
                -- 更新ui
                view:updateCell(nPageIndex, false)
            end
        end
    end
end

-- 加载标题
function CardClanView:updateTitle(curPage)
    local clanData = self:getClanData(curPage)
    if not clanData then
        return
    end

    local titleUI = self.m_titleNode:getChildByName("Title201903")

    if not titleUI then
        titleUI = util_createView(self:getTitleLua())
        titleUI:setName("Title201903")
        titleUI:setPlayChangeAnimCallBack(
            function(animIndex)
                local pageList = self.m_pageList
                if pageList ~= nil and self.m_pageList[animIndex] ~= nil then
                    for k, v in ipairs(pageList[animIndex]:getChildren()) do
                        v:updateCell(animIndex, true)
                    end
                end
            end
        )
        self.m_titleNode:addChild(titleUI)
    end

    self.titleUI = titleUI
    if titleUI then
        titleUI:updateView(curPage, clanData)
    end
end

function CardClanView:canClick()
    if self.titleUI and self.titleUI.getMovePageFlag and self.titleUI:getMovePageFlag() then
        return true
    end
    return false
end

-- 点击事件 --
function CardClanView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self:canClick() then
        return
    end

    if name == "Button_x" then
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
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:movePageDir(1)
    elseif name == "Button_next" or name == "layer_right" then
        if self.m_bScrolling == true then
            return
        end
        if self.m_curPageIndex >= self.m_pageNum then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:movePageDir(-1)
    end
end

return CardClanView
