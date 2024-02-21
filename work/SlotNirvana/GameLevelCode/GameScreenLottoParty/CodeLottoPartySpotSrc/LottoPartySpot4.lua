local NetSpriteLua = require("views.NetSprite")
local LottoPartySpot4 = class("LottoPartySpot4", util_require("base.BaseView"))

function LottoPartySpot4:initUI(data)
    self:createCsbNode("LottoParty_Spot_4.csb")
    self:updateUI(data)
end

function LottoPartySpot4:setSpotNum(_num)
end

function LottoPartySpot4:resetSpot()
    self:runCsbAction(
        "idleframe",
        false,
        function()
        end,
        60
    )
end

function LottoPartySpot4:setSpotBetCoins(_coins)
end

function LottoPartySpot4:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartySpot4:openSoptItem(func)
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

function LottoPartySpot4:updataSpotData(data)
    if data and data.udid ~= "" then
        local head = data.head or "0"
        local udid = data.udid
        if self:isMySelf(udid) then
            self:runCsbAction("idleframe3", true, nil, 60)
        end
 
    end
end

function LottoPartySpot4:updateUI(data)
    if data and data.udid ~= "" then
        self:runCsbAction("headIdle", false, nil, 60)
        self:updataSpotData(data)
    else
        self:runCsbAction("idleframe", false, nil, 60)
    end
end

function LottoPartySpot4:startLoadFacebookHead(fbid)

end

return LottoPartySpot4
