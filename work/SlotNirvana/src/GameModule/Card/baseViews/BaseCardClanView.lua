--[[
    集卡系统  指定卡组中卡片显示面板 数据来源于指定或手动选择的赛季

    tableview中的某一个界面的打开方式有以下几种：
        1 点击大厅 直接进入
        2 点击掉落link跳转 跳转进入
        3 左右切换
        4 章节选择界面点击该章节进入
--]]
local BaseCardClanView = class("BaseCardClanView", BaseLayer)

function BaseCardClanView:initDatas(index, enterFromAlbum)
    BaseCardClanView.super.initDatas(self)
    self.m_index, self.m_enterFromAlbum = index, enterFromAlbum

    self:setPauseSlotsEnabled(true)
    -- 当前是属于哪个赛季
    self.m_albumId = CardSysRuntimeMgr:getSelAlbumID()
    self.m_curPageIndex = self.m_index
    self.m_pageNum = self:getPageNum()
end

function BaseCardClanView:playShowAction()
    BaseCardClanView.super.playShowAction(self, "start", false)
end

function BaseCardClanView:onShowedCallFunc()
    CardSysManager:hideCardAlbumView()
end

-- 扩大点击区域
function BaseCardClanView:initBtnLayer()
    local layer_right = self:findChild("layer_right")
    if layer_right then
        self:addClick(layer_right)
    end
    local layer_left = self:findChild("layer_left")
    if layer_left then
        self:addClick(layer_left)
    end
end

function BaseCardClanView:initCsbNodes()
    self:initPageData()

    self.m_bg = self:findChild("book_bg")
    self.m_titleNode = self:findChild("Node_title")
    self:initBtnLayer()
end

-- 根据需求看看是否 子类需要重写
function BaseCardClanView:initPageData()
    -- 获取承载pageview的节点 --
    self.m_PageRootNode = self:findChild("Panel_logos")
    local tmpPageViewContent = self.m_PageRootNode:getContentSize()
    self.m_pageWidth = tmpPageViewContent.width
    self.m_pageHeight = tmpPageViewContent.height
    -- self.m_pageNum = self:getPageNum()
end

function BaseCardClanView:initView()
    self:initPageView()
    self:moveToPage(self.m_curPageIndex, true)
end

-- 模拟pageview --
function BaseCardClanView:initPageView()
end

-- 移动页面 ---- move left or right --
function BaseCardClanView:movePageDir(nDir)
end

-- 移动具体页面展示 --
function BaseCardClanView:moveToPage(nIndex, isInit)
end

function BaseCardClanView:updatePageInfo(nPageIndex, bAdded)
end

-- 处理当前页面其他操作 例如顶部主题等 --
function BaseCardClanView:updateOtherUI(index)
    self:updatePageBtn(index)
    self:updateTitle(index)
end

-- 更新按钮的显示
function BaseCardClanView:updatePageBtn(curPage)
    local btnLeft = self:findChild("Button_next1")
    local btnRight = self:findChild("Button_next")

    btnLeft:setVisible(curPage > 1)
    btnRight:setVisible(curPage < self.m_pageNum)
end

-- 加载标题 子类需要重写
function BaseCardClanView:updateTitle(curPage)
end

function BaseCardClanView:canClick()
    return true
end

-- 点击事件 --
function BaseCardClanView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

-- 关闭事件 --
function BaseCardClanView:closeUI(exitFunc)
    local callback = function()
        if exitFunc then
            exitFunc()
        end
    end
    BaseCardClanView.super.closeUI(self, callback)
end

-- 子类需要重写
function BaseCardClanView:getPageNum()
    -- cxc 2022年01月14日19:21:58 老赛季的数据在获取集卡信息时不返回，使用获取本赛季集卡基本信息里的数据
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    local info = CardSysRuntimeMgr:getCardAlbumInfo(albumID)
    if info and info.cardClans then
        return #info.cardClans or 0
    end
    return 0
end

function BaseCardClanView:getClanData(index)
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData[index]
end

-- 检测卡牌New操作 --
function BaseCardClanView:checkCardNewMark(nIndex)
    local clanData = self:getClanData(nIndex)
    if not clanData then
        return
    end
    local cardData = clanData.cards
    -- 更改运行时数据
    -- 客户端自己更改数据
    local bHasNewCard = false
    for i = 1, #cardData do
        local card = cardData[i]
        if card.newCard == true then
            card.newCard = false
            bHasNewCard = true
        end
    end
    if bHasNewCard == true then
        -- 请求数据
        local tExtraInfo = {["albumId"] = clanData.albumId, ["clanId"] = clanData.clanId}
        CardSysNetWorkMgr:sendCardViewRequest(tExtraInfo)

        -- 通知客户端其他界面刷新
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.NOTIFY_CHECK_CLAN_NEW, {clanId = clanData.clanId})
    end
end
return BaseCardClanView
