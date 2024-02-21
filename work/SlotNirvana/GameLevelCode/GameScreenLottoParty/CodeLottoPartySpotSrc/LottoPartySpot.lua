local NetSpriteLua = require("views.NetSprite")
local LottoPartySpot = class("LottoPartySpot", util_require("base.BaseView"))

local imageMap = {
    {headBg = "ui/LottoParty_HeadBgMe.png", headFrame = "ui/LottoParty_HeadKuangMe.png"},
    {headBg = "ui/LottoParty_HeadBgPlayer.png", headFrame = "ui/LottoParty_HeadKuangPlayer.png"}
}

function LottoPartySpot:initUI(data)
    self:createCsbNode("LottoParty_Spot.csb")
    self.headIcon = self:findChild("sp_head")
    self.headBg = self:findChild("sp_headBg")
    self.headFrame = self:findChild("sp_headFrame")
    self:updateUI(data)
end

function LottoPartySpot:setSpotNum(_num)
    local numLab = self:findChild("BitmapFontLabel_1")
    if numLab then
        numLab:setString(_num)
    end
end

function LottoPartySpot:resetSpot()
    self:runCsbAction(
        "idleframe",
        false,
        function()
        end,
        60
    )
end

function LottoPartySpot:setSpotBetCoins(_coins)
    local betNum = self:findChild("m_lb_coins")
    betNum:setString(util_formatCoins(_coins, 4))
end

function LottoPartySpot:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartySpot:openSoptItem(data, func)
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

function LottoPartySpot:updataSpotData(data)
    if self.headIcon then
        if data and data.udid ~= "" then
            local head = data.head or "0"
            local udid = data.udid
            local coins = data.coins
            local index = 1
            if self:isMySelf(udid) then
                index = 1
                head = globalData.userRunData.HeadName or "0"
                self:runCsbAction("idleframe3", true, nil, 60)
            else
                index = 2
            end
            local imageInfo = imageMap[index]
            if imageInfo ~= nil then
                util_changeTexture(self.headBg, imageInfo.headBg)
                util_changeTexture(self.headFrame, imageInfo.headFrame)
            end
            self:setSpotBetCoins(coins)
            --设置头像
            self.headIcon:removeAllChildren()
            if head then
                -- 有真实的数据再进来
                if data.facebookId and data.facebookId ~= "" and (tonumber(head) == 0 or head == "") then
                    -- 登录了facebook 并且（没有设置过自己的头像或把自己的头像就设置为Facebook头像）
                    self:startLoadFacebookHead(data.facebookId)
                else
                    -- 没有登录facebook 或者 设置了自己默认的头像（设置自己头像为0但是你没有登录facebook默认显示1）
                    if tonumber(head) == 0 or head == "" then
                        head = 1
                    end
                    local size = self.headIcon:getContentSize()
                    util_changeTexture(self.headIcon, "UserInformation/ui_head/UserInfo_touxiang_" .. head .. ".png")
                    -- util_changeTexture(self.headIcon, "GameNode/ui/ui_facebook_touxiang/TopNode_touxiang_" .. head .. ".png")
                    self.headIcon:setContentSize(size)
                end
            end
        end
    end
end

function LottoPartySpot:updateUI(data)
    if data and data.udid ~= "" then
        self:runCsbAction("headIdle", false, nil, 60)
        self:updataSpotData(data)
    else
        self:runCsbAction("idleframe", false, nil, 60)
    end
end

function LottoPartySpot:startLoadFacebookHead(fbid)
    if self.headIcon then
        local headIcon = self.headIcon
        if fbid ~= nil and fbid ~= "" then
            local fbSize = headIcon:getContentSize()

            -- 头像切图
            local clip_node = cc.ClippingNode:create()

            local netSprite = NetSpriteLua:create()
            local mask = NetSpriteLua:create()
            mask:init("Common/Other/fbmask.png", fbSize)
            clip_node:setStencil(mask)
            clip_node:setAlphaThreshold(0)

            netSprite:init(nil, fbSize)
            clip_node:addChild(netSprite)
            headIcon:addChild(clip_node)
            clip_node:setPosition(0, 0)

            local urlPath = "https://graph.facebook.com/" .. fbid .. "/picture?type=large"
            netSprite:getSpriteByUrl(urlPath, true)

            local isExist, fileName = netSprite:getHeadMd5(urlPath)
            if not isExist then
                LottoPartyHeadManager:addPlayerHeadInfo(urlPath)
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IMAGE_LOAD_COMPLETE)
        end
    end
end

return LottoPartySpot
