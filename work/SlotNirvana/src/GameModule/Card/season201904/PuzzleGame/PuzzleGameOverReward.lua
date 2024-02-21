local PuzzleGameOverReward = class("PuzzleGameOverReward", util_require("base.BaseView"))

function PuzzleGameOverReward:initUI(_type, _data)
    self:createCsbNode(CardResConfig.PuzzleGameCoinsRes)

    self.m_spCoins = self:findChild("Sprite_1")
    self.m_spCoins:setVisible(false)
    self.m_spPacket = self:findChild("Sprite_2")
    self.m_spPacket:setVisible(false)
    self.m_spDiamond = self:findChild("Sprite_3")
    self.m_spDiamond:setVisible(false)
    self.m_lbCoins = self:findChild("BitmapFontLabel_1")

    self.m_type = _type
    self.m_data = _data

    self:updateView()
end

function PuzzleGameOverReward:updateView()
    if self.m_type == "COINS" then
        self.m_spCoins:setVisible(true)
        self.m_lbCoins:setString(util_formatCoins(self.m_data, 3))
    elseif self.m_type == "PACKET" then
        self.m_spPacket:setVisible(true)
        if self.m_data > 1 then
            self.m_lbCoins:setString(self.m_data)
        else
            self.m_lbCoins:setString("")
        end
    elseif self.m_type == "DIAMOND" then
        self.m_spDiamond:setVisible(true)
        if self.m_data > 1 then
            self.m_lbCoins:setString(self.m_data)
        else
            self.m_lbCoins:setString("")
        end
    end
end

return PuzzleGameOverReward
