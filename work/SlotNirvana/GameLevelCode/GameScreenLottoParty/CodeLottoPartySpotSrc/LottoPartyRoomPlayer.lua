---
--xcyy
--2018年5月23日
--LottoPartyRoomPlayer.lua
local NetSpriteLua = require("views.NetSprite")
local LottoPartyRoomPlayer = class("LottoPartyRoomPlayer", util_require("base.BaseView"))

function LottoPartyRoomPlayer:initUI(data)
    self:createCsbNode("LottoParty_RoomPlayer.csb")
    self.headIcon = self:findChild("sp_head")
    self.headBg = self:findChild("BgPlayer")
    self:updateUI(data)
end

function LottoPartyRoomPlayer:onEnter()
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        if self.m_data then
            self:updateUI(self.m_data)
        end
        
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
end

function LottoPartyRoomPlayer:setSpotNum(_num)
    local numLab = self:findChild("m_lb_num")
    numLab:setString(_num)
end

function LottoPartyRoomPlayer:playBigWinAction(_winType)
    if not _winType then
        return
    end
    local bigNode = self:findChild("sp_big")
    local epicNode = self:findChild("sp_epic")
    local jackpotNode = self:findChild("sp_jackpot")
    local megaNode = self:findChild("sp_mega")

    bigNode:setVisible(false)
    epicNode:setVisible(false)
    jackpotNode:setVisible(false)
    megaNode:setVisible(false)
    if _winType == "BIG_WIN" then
        bigNode:setVisible(true)
    elseif _winType == "MAGE_WIN" then
        megaNode:setVisible(true)
    elseif _winType == "EPIC_WIN" then
        epicNode:setVisible(true)
    elseif _winType == "JACKPOT" then
        jackpotNode:setVisible(true)
    end
    self:runCsbAction("actionframe", false, nil, 60)
end

function LottoPartyRoomPlayer:playRankUp()
    self:runCsbAction("actionframe2", false, nil, 60)
end

function LottoPartyRoomPlayer:isMySelf(_udid)
    if globalData.userRunData.userUdid == _udid then
        return true
    end
    return false
end

function LottoPartyRoomPlayer:updateUI(data)
    self.m_data = data
    local head = data.head
    local udid = data.udid
    local num = data.value
    self:setSpotNum(num)
    if self:isMySelf(udid) then
        util_changeTexture(self.headBg, "ui/LottoParty_RoomMe.png")
        head = globalData.userRunData.HeadName or "0"
    else
        util_changeTexture(self.headBg, "ui/LottoParty_RoomPlayer.png")
    end
    --设置头像
    self.headIcon:removeAllChildren()
    if head then
        -- 有真实的数据再进来
        if data.facebookId and data.facebookId ~= "" and (tonumber(head) == 0 or head == "") then
            -- 登录了facebook 并且（没有设置过自己的头像或把自己的头像就设置为Facebook头像）
            -- self:startLoadFacebookHead(data.facebookId)
        else
            -- 没有登录facebook 或者 设置了自己默认的头像（设置自己头像为0但是你没有登录facebook默认显示1）
            if tonumber(head) == 0 or head == "" then
                head = 1
            end
            -- local size = self.headIcon:getContentSize()
            -- util_changeTexture(self.headIcon, "GameNode/ui/ui_facebook_touxiang/TopNode_touxiang_" .. head .. ".png")
            -- self.headIcon:setContentSize(size)
        end
        -- 改
        LottoPartyHeadManager:setAvatar(self.headIcon, data.facebookId, head, data, self:isMySelf(udid))
        -- 改

        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(self.headIcon:getContentSize())
        self:addClick(layout)
        layout:addTo(self.headIcon)
    end
end

function LottoPartyRoomPlayer:startLoadFacebookHead(fbid)
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

function LottoPartyRoomPlayer:onExit()
end


--增加头像点击看个人信息
function LottoPartyRoomPlayer:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_data then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_data.udid, "","",self.m_data.head)
    end
end

return LottoPartyRoomPlayer
