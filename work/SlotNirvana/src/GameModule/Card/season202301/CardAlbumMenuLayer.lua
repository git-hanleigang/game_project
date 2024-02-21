--[[
    集卡系统 左边滑出菜单
--]]
local CardAlbumMenuLayer = class("CardAlbumMenuLayer", BaseLayer)

function CardAlbumMenuLayer:initDatas(_startOver)
    self.m_startOver = _startOver
    self:setLandscapeCsbName("CardRes/season202301/cash_album_menu.csb")
    self.m_ruleLua = "GameModule.Card.season202301.CardMenuRule"
end

function CardAlbumMenuLayer:initCsbNodes()
    self.m_btnRule = self:findChild("Button_rules")
    self.m_btnHistory = self:findChild("Button_history")
    self.m_btnCollection = self:findChild("Button_collection")
    self.m_btnChallenge = self:findChild("Button_challenge")
    self.m_panelTouch = self:findChild("Panel_menu")
    self:addClick(self.m_panelTouch)
end

function CardAlbumMenuLayer:initView()
    self:hidePastBtn()
end

function CardAlbumMenuLayer:hidePastBtn()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        self.m_btnCollection:setVisible(false)
        self.m_btnChallenge:setVisible(false)
    end
end

function CardAlbumMenuLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardAlbumMenuLayer.super.playShowAction(self, "start")
end

function CardAlbumMenuLayer:playHideAction()
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    CardAlbumMenuLayer.super.playHideAction(self, "over")
end

function CardAlbumMenuLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    if self.m_startOver then
        self.m_startOver()
    end
end

function CardAlbumMenuLayer:canClick()
    return true
end

-- 点击事件 --
function CardAlbumMenuLayer:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end

    if name == "Button_rules" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)
        if gLobalViewManager:getViewByName("CardMenuRule" .. "season202301") ~= nil then
            return
        end
        local view = util_createView(self.m_ruleLua)
        view:setName("CardMenuRule" .. "season202301")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    elseif name == "Button_history" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)
        CardSysManager:showCardHistoryView()
    elseif name == "Button_collection" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)
        CardSysManager:showCardCollectionUI()
    elseif name == "Button_challenge" then
        CardSysRuntimeMgr:setClickOtherInAlbum(true)
        if CardSysRuntimeMgr.m_CardSeasonsInfo and CardSysRuntimeMgr.m_CardSeasonsInfo.p_collectNado then
            CardSysManager:getLinkMgr():showCardLinkProgressComplete(
                {
                    data = CardSysRuntimeMgr.m_CardSeasonsInfo.p_collectNado,
                    isDrop = false
                }
            )
        end
    elseif name == "Panel_menu" then
        local view = gLobalViewManager:getViewByName("CardAlbumView" .. "season202301")
        if view then
            view:hideMenuCloseBtn()
        end
        self:closeUI()
    end
end

return CardAlbumMenuLayer
