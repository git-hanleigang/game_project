--[[--
    页签
]]
local CardTabUI = class("CardTabUI", util_require("base.BaseView"))

function CardTabUI:initUI(_tabPosition, _tabTexts, _defaultIndex)
    self.m_tabNum = #_tabTexts
    self.m_tabTexts = _tabTexts
    self.m_tabPosition = _tabPosition
    if self.m_tabPosition == "year" then
        self:createCsbNode(string.format(CardResConfig.commonRes.CardRecoverSelTab1Res, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    elseif self.m_tabPosition == "album" then
        self:createCsbNode(string.format(CardResConfig.commonRes.CardRecoverSelTab2Res, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    end

    self.m_btnNodes = {}
    self.m_btnFonts = {}
    self.m_btnFontAns = {}
    for i = 1, math.huge do
        if self:findChild("btn_" .. i) then
            self.m_btnNodes[#self.m_btnNodes + 1] = self:findChild("btn_" .. i)
            local font = self:findChild("font_" .. i)
            local font_an = self:findChild("font_" .. i .. "_an")
            self.m_btnFonts[#self.m_btnFonts + 1] = font
            self.m_btnFontAns[#self.m_btnFontAns + 1] = font_an
            if i <= #self.m_tabTexts then
                -- font:setString("")
                -- font_an:setString("")
                font:setString(self.m_tabTexts[i].tabText)
                font_an:setString(self.m_tabTexts[i].tabText)
                self:updateLabelSize({label = font, sx = 1, sy = 1}, 185)
                self:updateLabelSize({label = font_an, sx = 1, sy = 1}, 185)
            end
        else
            break
        end
    end

    self:setBtnPressed(_defaultIndex or 1)
end

function CardTabUI:setBtnPressed(_pressedIndex)
    if self.m_pressedIndex == _pressedIndex then
        return
    end

    self.m_pressedIndex = _pressedIndex

    for i = 1, #self.m_btnNodes do
        local btn = self.m_btnNodes[i]
        local font = self.m_btnFonts[i]
        local font_an = self.m_btnFontAns[i]
        if i <= self.m_tabNum then
            font:setVisible(i == self.m_pressedIndex)
            font_an:setVisible(i ~= self.m_pressedIndex)
            btn:setVisible(true)
            btn:setTouchEnabled(i ~= self.m_pressedIndex)
            btn:setBright(i ~= self.m_pressedIndex)
        else
            btn:setVisible(false)
        end
    end
    if self.m_tabPosition == "year" then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_YEAR_TAB_UPDATE, {index = self.m_pressedIndex})
    elseif self.m_tabPosition == "album" then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_ALBUM_TAB_UPDATE, {index = self.m_pressedIndex})
    end
end

function CardTabUI:clickFunc(sender)
    local name = sender:getName()
    for i = 1, #self.m_btnNodes do
        if name == "btn_" .. i then
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
            self:setBtnPressed(i)

            break
        end
    end
end

return CardTabUI
