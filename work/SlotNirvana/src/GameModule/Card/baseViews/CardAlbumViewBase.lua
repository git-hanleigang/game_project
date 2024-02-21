--[[
    集卡系统  
    卡册选择面板 基类
--]]
local CardAlbumViewBase = class("CardAlbumViewBase", util_require("base.BaseRotateLayer"))

function CardAlbumViewBase:initDatas(isPlayStart)
    self.m_isPlayStart = isPlayStart
    self:setLandscapeCsbName(CardResConfig.CardAlbumViewRes)
    self:setPauseSlotsEnabled(true)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setHideLobbyEnabled(true)
    self:setName("CardAlbumView")
end

-- 流程 --
function CardAlbumViewBase:initView()
    CardSysRuntimeMgr:setRecoverSourceUI(CardSysRuntimeMgr.RecoverSourceUI.AlbumUI)

    local moveLayer = self:findChild("moveLayer") -- 做适配用的容器
    local moveLayerParentSize = moveLayer:getParent():getContentSize()
    if display.width >= 1660 then
        moveLayer:setPositionX(moveLayerParentSize.width * 0.5 + 65)
    else
        moveLayer:setPositionX(moveLayerParentSize.width * 0.5)
    end

    self:initMenu()
    self:initTitle()
    self:updateLogo()
    self:updateBg()
    self:updateTableView()

    self:initBookUI()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    if self.m_isPlayStart then
        self:runCsbAction(
            "start",
            false,
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.AlbumOpenBook)
                self:runCsbAction(
                    "start2",
                    false,
                    function()
                        self:updateCoin()
                    end,
                    60
                )
            end,
            60
        )
    else
        self:updateCoin()
    end
end

-- 是否播放显示动画 (旋转横竖屏也需要 播放动画)
function CardAlbumViewBase:isShowActionEnabled()
    return true
end

-- 子类重写
function CardAlbumViewBase:updateTableView()
end

function CardAlbumViewBase:initCsbNodes()
    self.m_coinNormal = self:findChild("Node_show1")
    self.m_coinWild = self:findChild("Node_show2")
    self.m_coinCompleted = self:findChild("Node_show3")

    self.m_cardLogo = self:findChild("album_logo")
    self.m_albumBg = self:findChild("book_bg_cut")
    self.m_albumBg2 = self:findChild("book_bg")
    self.m_rewardBg = self:findChild("reward_bg")
    self.m_caption_1_1 = self:findChild("caption_1_1")
end

-- 子类重写
function CardAlbumViewBase:initBookUI()
end

-- 点击事件 --
function CardAlbumViewBase:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_x" or name == "Button_back" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardAlbumView(
            function()
                CardSysManager:exitCardAlbum()
            end
        )
    end
end

-- 关闭事件 --
function CardAlbumViewBase:closeUI(exitFunc)
    CardAlbumViewBase.super.closeUI(self, exitFunc)
end

-- 回收机 --
function CardAlbumViewBase:initMenu()
    self.m_menuNode = self:findChild("Node_menu")
    local view = util_createView("GameModule.Card.season201901.CardMenuNode", CardSysRuntimeMgr.RecoverSourceUI.AlbumUI)
    self.m_menuNode:addChild(view)
end
-- 规则菜单 --
function CardAlbumViewBase:initRecoverWheel()
    self.m_wheelNode = self:findChild("Node_wheel")
    local view = util_createView("GameModule.Card.season201901.CardMenuNode", CardSysRuntimeMgr.RecoverSourceUI.AlbumUI)
    self.m_wheelNode:addChild(view)
end

-- title
function CardAlbumViewBase:initTitle()
end

-- logo
function CardAlbumViewBase:updateLogo()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    -- 书册赛季logo
    local seasonPath = CardResConfig.getCardSeasonFilePath(albumData.year, albumData.season)
    local bgRes, logoRes = CardResConfig.getCardSeasonBookRes()
    util_changeTexture(self.m_cardLogo, seasonPath .. "/" .. logoRes)
end

function CardAlbumViewBase:updateBg()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    local seasonPath = CardResConfig.getCardSeasonFilePath(albumData.year, albumData.season)
    local logoRes, rewardBgRes = CardResConfig.getCardAlbumRes()
    -- 书册赛季logo
    util_changeTexture(self.m_albumBg, seasonPath .. "/" .. logoRes)
    util_changeTexture(self.m_albumBg2, seasonPath .. "/" .. logoRes)
    -- 书册奖励背景条
    util_changeTexture(self.m_rewardBg, seasonPath .. "/" .. rewardBgRes)
end

-- 奖励
function CardAlbumViewBase:updateCoin()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()

    local isCompleted = albumData.current >= albumData.total
    if isCompleted then
        self:runCsbAction("idle3", true, nil, 60)
    else
        self.m_coinNormal:getChildByName("Node_coin"):getChildByName("coins"):setString(util_formatCoins(tonumber(albumData.coins), 20) .. " Coins")
        self:runCsbAction("idle1", true, nil, 60)
    end
end

return CardAlbumViewBase
