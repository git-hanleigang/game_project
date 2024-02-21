local NetSpriteLua = require("views.NetSprite")
local LottoPartySpot2 = class("LottoPartySpot2", util_require("base.BaseView"))

function LottoPartySpot2:initUI(data)
    self:createCsbNode("LottoParty_Spot_2.csb")
    self:updateUI(data)
end

function LottoPartySpot2:setSpotNum(_num)
end

function LottoPartySpot2:resetSpot()
    self:runCsbAction(
        "idleframe",
        false,
        function()
        end,
        60
    )
end

function LottoPartySpot2:setSpotBetCoins(_coins)
end

function LottoPartySpot2:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartySpot2:openSoptItem(func)
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

function LottoPartySpot2:updataSpotData(data)
    if data and data.udid ~= "" then
        local head = data.head or "0"
        local udid = data.udid
        if self:isMySelf(udid) then
            self:runCsbAction("idleframe3", true, nil, 60)
        end
    end
end

function LottoPartySpot2:updateUI(data)
    if data and data.udid ~= "" then
        self:runCsbAction("headIdle", false, nil, 60)
        self:updataSpotData(data)
    else
        self:runCsbAction("idleframe", false, nil, 60)
    end
end

function LottoPartySpot2:startLoadFacebookHead(fbid)
end

return LottoPartySpot2
