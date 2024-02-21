local NetSpriteLua = require("views.NetSprite")
local LottoPartySpot6 = class("LottoPartySpot6", util_require("base.BaseView"))

function LottoPartySpot6:initUI(data)
    self:createCsbNode("LottoParty_Spot_6.csb")
    self:updateUI(data)
end

function LottoPartySpot6:setSpotNum(_num)
    local numLab = self:findChild("BitmapFontLabel_1")
    if numLab then
        numLab:setString(_num)
    end
end

function LottoPartySpot6:resetSpot()
    self:runCsbAction(
        "idleframe",
        false,
        function()
        end,
        60
    )
end

function LottoPartySpot6:setSpotBetCoins(_coins)
end

function LottoPartySpot6:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartySpot6:openSoptItem(func)
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

function LottoPartySpot6:updataSpotData(data)
    if data and data.udid ~= "" then
        local head = data.head or "0"
        local udid = data.udid
        local coins = data.coins
        local index = 1
        if self:isMySelf(udid) then
            index = 1
            head = globalData.userRunData.HeadName or "0"
            self:runCsbAction("idleframe3", true, nil, 60)
        end
    end
end

function LottoPartySpot6:updateUI(data)
    if data and data.udid ~= "" then
        self:runCsbAction("headIdle", false, nil, 60)
        self:updataSpotData(data)
    else
        self:runCsbAction("idleframe", false, nil, 60)
    end
end

function LottoPartySpot6:startLoadFacebookHead(fbid)

end

return LottoPartySpot6
