--[[
    拼图 - 标题
]]
local BaseView = util_require("base.BaseView")
local PuzzleTitle = class("PuzzleTitle", BaseView)

function PuzzleTitle:initUI(mainClass)

    self.m_mainClass = mainClass
    self:createCsbNode(CardResConfig.PuzzlePageTitleRes, isAutoScale)

    self.m_iconCoin = self:findChild("sp_coinIcon")
    self.m_labCoin = self:findChild("lb_coinNum")
    self.m_labAdd = self:findChild("lb_add")
    self.m_nodeChip = self:findChild("node_chip")

    self:runCsbAction("idle", true)
end

function PuzzleTitle:updateUI(pageIndex)
    local _data = CardSysRuntimeMgr:getPuzzleDataByIndex(pageIndex)
    if not _data then
        return
    end

    self.m_labCoin:setString(util_formatCoins(tonumber(_data.coins), 20))

    self.m_nodeChip:removeAllChildren()
    local path = string.format("CardRes/season201904/CashPuzzle/img/Common/CashPuzzle_RewardIcon_%d.png", pageIndex)
    local _sprite = util_createSprite(path)
    self.m_nodeChip:addChild(_sprite)

    local _iconCoin = self.m_iconCoin
    local _labCoin = self.m_labCoin
    local _labAdd = self.m_labAdd
    local _nodeChip = self.m_nodeChip
    util_alignCenter(
        {
            {node = _iconCoin, alignX = 10},
            {node = _labCoin, alignX = 10, scale = 1},
            {node = _labAdd, alignX = 10},
            {node = _nodeChip, alignX = 50, size = cc.size(80,80)}
        }
    )
end

function PuzzleTitle:clickFunc(sender)
    local name  = sender:getName()
    if name == "Button_i" then
        if self.m_showInfo then
            return
        end
        self.m_showInfo = true
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        local puzzleInfo = util_createView("GameModule.Card.season201904.PuzzlePage.PuzzleMainInfo")
        gLobalViewManager:showUI(puzzleInfo, ViewZorder.ZORDER_UI)
        puzzleInfo:setOverFunc(function()
            self.m_showInfo = false
        end)
    elseif name == "Button_x" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        -- self.m_mainClass:closeUI()
        CardSysManager:getPuzzleGameMgr():closePageMainUI()
    end    
end

return PuzzleTitle
