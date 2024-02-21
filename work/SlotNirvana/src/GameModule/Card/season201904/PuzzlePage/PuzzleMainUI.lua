--[[
    拼图页
]]
local BaseView = util_require("base.BaseView")
local PuzzleMainUI = class("PuzzleMainUI", BaseView)

function PuzzleMainUI:initUI(pageIndex)
    -- self.m_initPageIndex = pageIndex
    pageIndex = pageIndex or 1

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(CardResConfig.PuzzlePageMainRes, isAutoScale)

    self:initData()
    self:initNode()
    self:initView()

    -- self:moveToPage(pageIndex)
    self:setCurPage(pageIndex)
end

function PuzzleMainUI:initData()
    -- self.m_curPageIndex = self.m_initPageIndex or 1
    local gameData = CardSysRuntimeMgr:getPuzzleGameData()
    if gameData then
        self.m_pageNum = #gameData.puzzle
    end
end

function PuzzleMainUI:initNode()
    self.m_BtnX = self:findChild("Button_x")
    self.m_BtnLeft = self:findChild("Button_left")
    self.m_BtnRight = self:findChild("Button_right")
    self.m_LayerLeft = self:findChild("Layer_left")
    self.m_LayerRight = self:findChild("Layer_right")
    self.m_BtnI = self:findChild("Button_i")
    self.m_BtnPlay = self:findChild("Button_play")

    self.m_ItemNode = self:findChild("Node_item")
    self.m_TitleNode = self:findChild("Node_title")
    self.m_PuzzleGameNode = self:findChild("Node_puzzleGame")
end

function PuzzleMainUI:onEnter()

    local rootScale = self.m_csbNode:getChildByName("root"):getScale()
    CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(1, self.m_BtnPlay, rootScale)


    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(Target, params)
    --         self:setCurPage(params.pageIndex + 1)
    --     end,
    --     ViewEventType.NOTIFY_UPDATE_PUZZLE_ITEM
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            -- 刷新碎片
            self:updateItemView()
        end,
        CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_ITEMS
    )
end

function PuzzleMainUI:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function PuzzleMainUI:moveToPage(pageIndex)
    -- local nNextIndex = 0
    -- if nDir > 0 then
    --     nNextIndex = math.min(self.m_pageNum, self.m_curPageIndex + 1)
    -- elseif nDir < 0 then
    --     nNextIndex = math.max(1, self.m_curPageIndex - 1)
    -- end

    pageIndex = pageIndex or 1

    local nNextIndex = math.min(self.m_pageNum, math.max(1, pageIndex))

    if nNextIndex == self.m_curPageIndex then
        return
    end

    -- self.m_curPageIndex = nNextIndex
    self:setCurPage(nNextIndex)
    -- self:updateUI()

    -- if self.m_itemUI and self.m_itemUI.moveToPage then
    --     self.m_itemUI:moveToPage(nNextIndex - 1)
    -- end

    self.m_isMoving = true
    self.m_itemUI:moveAct(
        nNextIndex,
        function()
            self.m_isMoving = false
        end
    )

    self.m_puzzleGameUI:moveAct(nNextIndex)
end

function PuzzleMainUI:clickFunc(sender)
    local name = sender:getName()

    if name == "Button_right" or name == "layer_right" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 在移动中则不响应翻页
        if self.m_isMoving then
            return
        end
        self:moveToPage(self.m_curPageIndex + 1)
    elseif name == "Button_left" or name == "layer_left" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- 在移动中则不响应翻页
        if self.m_isMoving then
            return
        end
        self:moveToPage(self.m_curPageIndex - 1)
    elseif name == "Button_play" then        
        CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():stopGuide(1)
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        CardSysManager:getPuzzleGameMgr():enterPuzzleGame()
    end
end

-- UI 初始化 ----------------------------------------------------------------------------
function PuzzleMainUI:initView()
    self:initTitle()
    self:initPuzzleGame()
    self:initPageView()
end

function PuzzleMainUI:initTitle()
    self.m_titleUI = util_createView("GameModule.Card.season201904.PuzzlePage.PuzzleTitle", self)
    self.m_TitleNode:addChild(self.m_titleUI)

    -- 适配上UI
    local pos = cc.p(self.m_TitleNode:getPosition())
    local worldPos = self.m_TitleNode:getParent():convertToWorldSpace(cc.p(self.m_TitleNode:getPosition()))
    local localPos = self.m_TitleNode:getParent():convertToNodeSpace(cc.p(worldPos.x, display.height))

    self.m_TitleNode:setPositionY(localPos.y)
end

function PuzzleMainUI:initPuzzleGame()
    self.m_puzzleGameUI = util_createView("GameModule.Card.season201904.PuzzlePage.PuzzleGame")
    self.m_PuzzleGameNode:addChild(self.m_puzzleGameUI)
end

function PuzzleMainUI:initPageView()
    self.m_itemUI = util_createView("GameModule.Card.season201904.PuzzlePage.PuzzleItem")
    self.m_ItemNode:addChild(self.m_itemUI)
    local _pageLayout = self.m_itemUI.m_pageLayout
    if _pageLayout then
        self:addClick(_pageLayout)
        local _size = _pageLayout:getContentSize()
        self.m_DisForGoNextPage = _size.width / 3

        -- 计算触摸区域大小
        local _posX = _pageLayout:getPositionX()
        local _posY = _pageLayout:getPositionY()
        local _worldPos = _pageLayout:getParent():convertToWorldSpace(cc.p(_posX, _posY))
        local _rect = _pageLayout:getBoundingBox()
        _rect.x = _worldPos.x - _rect.width / 2
        _rect.y = _worldPos.y - _rect.height / 2
        self.m_touchRect = _rect
    end
end

-- UI 刷新 ----------------------------------------------------------------------------
function PuzzleMainUI:setCurPage(pageIndex)
    self.m_curPageIndex = pageIndex
    self:updateUI()

    if self.m_curPageIndex == 1 then
        self.m_BtnLeft:setVisible(false)
        self.m_BtnRight:setVisible(true)
    elseif self.m_curPageIndex == self.m_pageNum then
        self.m_BtnLeft:setVisible(true)
        self.m_BtnRight:setVisible(false)
    else
        self.m_BtnLeft:setVisible(true)
        self.m_BtnRight:setVisible(true)
    end
end

function PuzzleMainUI:updateUI()
    self:updateTitle()
    self:updatePuzzleGame()
end

function PuzzleMainUI:updateTitle()
    if self.m_titleUI and self.m_titleUI.updateUI then
        self.m_titleUI:updateUI(self.m_curPageIndex)
    end
end

function PuzzleMainUI:updatePuzzleGame()
    if self.m_puzzleGameUI and self.m_puzzleGameUI.updateUI then
        self.m_puzzleGameUI:updateUI(self.m_curPageIndex)
    end
end

function PuzzleMainUI:updateItemView()
    if self.m_itemUI and self.m_itemUI.updateUI then
        self.m_itemUI:updateUI()
    end
end

function PuzzleMainUI:closeUI()
    self:removeFromParent()
end

--点击监听
function PuzzleMainUI:clickStartFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        if self.m_isMoving == true then
            return
        end

        self.m_isTouched = true
        -- 记录触摸的位置
        local pos = sender:getTouchBeganPosition()
        self.m_touchPos = pos
        self.m_startPos = pos
    end
end

--移动监听
function PuzzleMainUI:clickMoveFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        if not self.m_isTouched then
            return
        end

        -- if self.m_itemPageCount <= 1 then
        --     return
        -- end
        -- 按住滑动时更新位置
        self.m_isMoving = true

        local _pos = sender:getTouchMovePosition()
        local offsetX = _pos.x - self.m_touchPos.x

        self.m_itemUI:updatePageItemPos(offsetX)
        local _size = sender:getContentSize()
        self.m_puzzleGameUI:updatePageItemPos(offsetX / _size.width)
        self.m_touchPos = _pos

        if not cc.rectContainsPoint(self.m_touchRect, _pos) then
            self:clickEndFunc(sender)
        end
    end
end

--结束监听
function PuzzleMainUI:clickEndFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        -- 处理点击释放
        if self.m_isMoving and self.m_isTouched then
            local _pos = sender:getTouchMovePosition()
            local offsetX = self.m_startPos.x - _pos.x
            if offsetX >= self.m_DisForGoNextPage and self.m_curPageIndex < self.m_pageNum then
                self:moveToPage(self.m_curPageIndex + 1)
            elseif offsetX <= -self.m_DisForGoNextPage and self.m_curPageIndex > 1 then
                self:moveToPage(self.m_curPageIndex - 1)
            else
                self.m_itemUI:moveBackAct(
                    offsetX,
                    function()
                        self.m_isMoving = false
                    end
                )
                local _size = sender:getContentSize()
                self.m_puzzleGameUI:moveBackAct(offsetX / _size.width)
            end
        end
        self.m_isTouched = false
        self.m_touchPos = nil
        self.m_startPos = nil
    end
end

return PuzzleMainUI
