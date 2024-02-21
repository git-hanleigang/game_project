--[[
    集卡系统
    卡册选择面板子类 201903赛季
    数据来源于年度开启的赛季
--]]
local CardAlbumViewBase = util_require("GameModule.Card.baseViews.CardAlbumViewBase")
local CardAlbumView = class("CardAlbumView", CardAlbumViewBase)

function CardAlbumView:initDatas(isPlayStart)
    isPlayStart = isPlayStart or false
    CardAlbumView.super.initDatas(self, isPlayStart)
    self:setShowActionEnabled(isPlayStart)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season201903"))
end

-- >>> 需要子类重写的函数 ------------------------------------------------------------------
function CardAlbumView:getTitleLuaPath()
    return "GameModule.Card.season201903.CardAlbumTitle"
end

function CardAlbumView:getBottomLuaPath()
    return "GameModule.Card.season201903.CardSeasonBottom"
end

function CardAlbumView:getCellLuaPath()
    return "GameModule.Card.season201903.CardAlbumCell"
end

function CardAlbumView:getAlbumListData()
    local cardClanData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return cardClanData
end
-- <<< 需要子类重写的函数 ------------------------------------------------------------------

-- 初始化UI --
function CardAlbumView:initView()
    CardSysRuntimeMgr:setRecoverSourceUI(CardSysRuntimeMgr.RecoverSourceUI.AlbumUI)
    
    self:initTitle()
    self:initBottom()
end

function CardAlbumView:updateUI(_isPlayStart)
    self.m_titleUI:updateUI(_isPlayStart)
    if self.m_bottomUI.updateUI then
        self.m_bottomUI:updateUI(_isPlayStart)
    end
end

-- function CardAlbumView:onEnterFinish()
--     CardAlbumView.super.onEnterFinish(self)
--     self:updateUI(self.m_isPlayStart)
-- end

function CardAlbumView:isPlayAlbumAct()
    return true
end

-- 检测第一次进入引导
function CardAlbumView:checkClickFirstGuide()
    
end

function CardAlbumView:onShowedCallFunc()
    CardAlbumView.super.onShowedCallFunc(self)

    self:runCsbAction("idle", true, nil, 60)
    self:initAlbumList(self:isPlayAlbumAct())
    util_nextFrameFunc(
        function()
            if not tolua.isnull(self) then
                self:checkClickFirstGuide()
            end
        end
    )

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CardAlbumView:playShowActionCustom(callFunc)
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    self:updateUI(self.m_isPlayStart)
    self:runCsbAction(
        "start",
        false,
        function()
            if callFunc then
                callFunc()
            end
            -- self:runCsbAction("idle", true)

            -- print("-----------CardAlbumView----------- start")
            -- local pro = self.m_bottomNode:getScale()
            -- local function getParentPro(node)
            --     if node then
            --         local parentNode = node:getParent()
            --         if parentNode ~= nil then
            --             local scale = parentNode:getScale()
            --             pro = pro * scale
            --             print("-------- scale ", scale)
            --             print("-------- pro ", pro)
            --             getParentPro(parentNode)
            --         end
            --     end
            -- end
            -- getParentPro(self.m_bottomNode)
            -- print("-----------CardAlbumView----------- over")
        end
    )

    -- performWithDelay(
    --     self,
    --     function()
    --         self:initAlbumList(true)
    --         util_setCascadeOpacityEnabledRescursion(self, true)
    --     end,
    --     0.65
    -- )
end

function CardAlbumView:playShowAction()
    CardAlbumView.super.playShowAction(self, handler(self, self.playShowActionCustom))
end


function CardAlbumView:initAdapt()
end

function CardAlbumView:getCurScale()
    return self.m_scale
end

function CardAlbumView:initCsbNodes()
    self.m_rootNode = self:findChild("root")
    self.m_titleNode = self:findChild("renwu_jindu")
    self.m_bottomNode = self:findChild("Node_bottom")
    self.m_albumNode = self:findChild("Node_zhangjie")
    self.m_touchLayer = self:findChild("touch")
    self.m_touchLayer:setSwallowTouches(false)
    self:addNodeClicked(self.m_touchLayer)
end

function CardAlbumView:addNodeClicked(node)
    if not node then
        return
    end
end

function CardAlbumView:initTitle(isPlayStart)
    if not self.m_titleUI then
        self.m_titleUI = util_createView(self:getTitleLuaPath(), self)
        self.m_titleNode:addChild(self.m_titleUI)
    end
    -- self.m_titleUI:updateUI(isPlayStart)
end

function CardAlbumView:initBottom(isPlayStart)
    if not self.m_bottomUI then
        self.m_bottomUI = util_createView(self:getBottomLuaPath(), CardSysRuntimeMgr.RecoverSourceUI.AlbumUI, nil, self)
        self.m_bottomNode:addChild(self.m_bottomUI)
    end
    -- if self.m_bottomUI.updateUI then
    --     self.m_bottomUI:updateUI(isPlayStart)
    -- end
end

function CardAlbumView:initAlbumList(isPlayStart)
    local cardClanData = self:getAlbumListData()
    if cardClanData ~= nil then
        if not self.uiList then
            self.uiList = {}
            for k, v in pairs(cardClanData) do
                -- 创建章节cell
                local albumCell = util_createView(self:getCellLuaPath())
                albumCell:updateCell(k, v)
                albumCell:updateTagNew()
                table.insert(self.uiList, albumCell)
            end

            local circleScrollUI = util_createView("base.CircleScrollUI")
            circleScrollUI:setMargin(0)
            circleScrollUI:setMarginXY(120, 20)
            circleScrollUI:setMaxTopYPercent(0.5)
            circleScrollUI:setTopYHeight(120)
            circleScrollUI:setMaxAngle(20)
            circleScrollUI:setRadius(2500)
            if isPlayStart then
                circleScrollUI:setPlayToLeftAnimInfo(0.2, 4)            
            end
            for i = 1, #self.uiList do
                local albumCell = self.uiList[i]
                albumCell:playAnim(isPlayStart == true)
            end
            circleScrollUI:setUIList(self.uiList)

            local scale = self:findChild("root"):getScale()
            circleScrollUI:setDisplaySize(display.width / scale, 525)
            circleScrollUI:setPosition(-display.width / scale / 2, -2270 - display.height / 2)
            self.m_albumNode:addChild(circleScrollUI)
            -- util_setCascadeOpacityEnabledRescursion(self, true)
        else
            for i = 1, #self.uiList do
                local albumCell = self.uiList[i]
                albumCell:updateCell(i, cardClanData[i])
                albumCell:updateTagNew()
                albumCell:playAnim()
            end
        end
    end
end

function CardAlbumView:onEnter()
    CardAlbumView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            for i = 1, #self.uiList do
                self.uiList[i]:updateTagNew()
            end
        end,
        CardSysConfigs.ViewEventType.NOTIFY_CHECK_CLAN_NEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 刷新界面
            -- self:initTitle()
            -- self:initBottom()
            self:updateUI()
            self:initAlbumList()
        end,
        CardSysConfigs.ViewEventType.CARD_ALBUM_LIST_UPDATE
    )
end

return CardAlbumView
