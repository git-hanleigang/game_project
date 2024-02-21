local NetSpriteLua = require("views.NetSprite")
local LottoPartySpot3 = class("LottoPartySpot3", util_require("base.BaseView"))

function LottoPartySpot3:initUI(data)
    self:createCsbNode("LottoParty_Spot_3.csb")
    self:updateUI(data)
end

function LottoPartySpot3:setSpotNum(_num)
    local numLab = self:findChild("BitmapFontLabel_1")
    if numLab then
        numLab:setString(_num)
    end
end

function LottoPartySpot3:resetSpot()
    self:runCsbAction(
        "idleframe",
        false,
        function()
        end,
        60
    )
end

function LottoPartySpot3:setSpotBetCoins(_coins)
    local betNum = self:findChild("m_lb_coins")
    if betNum then
        betNum:setString(util_formatCoins(_coins, 4))
    end
end

function LottoPartySpot3:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartySpot3:openSoptItem(func)
    self:runCsbAction(
        "actionframe2",
        false,
        function()
            self:runCsbAction("idleframe3", true, nil, 60)
            if func then
                func()
            end
        end,
        60
    )
end

function LottoPartySpot3:updataSpotData(data)
    if data and data.udid ~= "" then
        local head = data.head or "0"
        local udid = data.udid
        local coins = data.coins

        if self:isMySelf(udid) then
            self:runCsbAction("idleframe3", true, nil, 60)
        end

        self:setSpotBetCoins(coins)
    end
end

function LottoPartySpot3:updateUI(data)
    if data and data.udid ~= "" then
        self:runCsbAction("headIdle", false, nil, 60)
        self:updataSpotData(data)
    else
        self:runCsbAction("idleframe", false, nil, 60)
    end
end

function LottoPartySpot3:startLoadFacebookHead(fbid)
end

return LottoPartySpot3
