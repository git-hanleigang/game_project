---
local NetSpriteLua = require("views.NetSprite")
local LottoPartySpotBonusOverView = class("LottoPartySpotBonusOverView", util_require("base.BaseView"))

function LottoPartySpotBonusOverView:initUI(data)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local resourceFilename = "LottoParty/BonusGameOver.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    -- self.headIcon = self:findChild("sp_head")
    self.m_click = true
    self.m_JumpOver = nil
end

function LottoPartySpotBonusOverView:setFunc(_func)
    self.m_func = _func
end

function LottoPartySpotBonusOverView:initViewData(coins)
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
    local node1 = self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label = node1, sx = 0.75, sy = 0.75}, 692)
    self:jumpCoins(coins)
    self:initHead()
    self.m_JumpSound = gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_jump.mp3", true)
end

function LottoPartySpotBonusOverView:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (5 * 60) -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = 0

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            -- print("++++++++++++  " .. curCoins)

            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            end
        end,
        5
    )
end

function LottoPartySpotBonusOverView:onEnter()
end

function LottoPartySpotBonusOverView:onExit()
    if self.m_JumpOver then
        gLobalSoundManager:stopAudio(self.m_JumpOver)
        self.m_JumpOver = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function LottoPartySpotBonusOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle", true, nil, 60)
        else
            self.m_click = true
            self:sendCollectSpotWin()
        end
    end
end

function LottoPartySpotBonusOverView:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_func then
                self.m_func()
            end

            self:removeFromParent()
        end,
        60
    )
end

function LottoPartySpotBonusOverView:initHead()
    local node3 = self:findChild("Node_3")
    -- node3:removeAllChildren()
    -- node3:getChildByName("HeadBgPlayer"):setVisible(false)
    -- node3:getChildByName("sp_head"):setVisible(false)
    -- node3:getChildByName("HeadKuangPlayer"):setVisible(false)
    -- node3:getChildByName("Sprite_27"):setVisible(false)

    local head = globalData.userRunData.HeadName or "0"
    local fbid = globalData.userRunData.facebookBindingID
    --设置头像
    if fbid and fbid ~= "" and (tonumber(head) == 0 or head == "") then
        -- 登录了facebook 并且（没有设置过自己的头像或把自己的头像就设置为Facebook头像）
        -- self:startLoadFacebookHead()
    else
        -- 没有登录facebook 或者 设置了自己默认的头像（设置自己头像为0但是你没有登录facebook默认显示1）
        if tonumber(head) == 0 or head == "" then
            head = 1
        end
        -- local size = self.headIcon:getContentSize()
        -- util_changeTexture(self.headIcon, "UserInformation/ui_head/UserInfo_touxiang_" .. head .. ".png")
        -- self.headIcon:setContentSize(size)
    end

    -- local frameId = globalData.userRunData.avatarFrameId
    local headNode = node3:getChildByName("sp_head")
    -- local headSize = headNode:getContentSize()
    -- local nodeAvatar =  G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, head, frameId, nil, headSize)
    -- headNode:addChild(nodeAvatar)
    -- nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

    util_setHead(headNode, fbid, head, nil, false)

    -- local headRoot = headNode:getParent()
    -- local headFrameNode = headRoot:getChildByName("headFrameNode")
    -- if not headFrameNode then
    --     headFrameNode = cc.Node:create()
    --     headRoot:addChild(headFrameNode, 10)
    --     headFrameNode:setName("headFrameNode")
    --     headFrameNode:setPosition(headNode:getPosition())
    --     headFrameNode:setLocalZOrder(10)
    --     headFrameNode:setScale(headNode:getScale())
    -- else
    --     headFrameNode:removeAllChildren(true)
    -- end
    -- util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)
end

function LottoPartySpotBonusOverView:startLoadFacebookHead(fbid)
    if gLobalSendDataManager:getIsFbLogin() == true then
        local headIcon = self.headIcon
        local fbid = globalData.userRunData.facebookBindingID
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
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_IMAGE_LOAD_COMPLETE)
        end
    end
end

function LottoPartySpotBonusOverView:sendCollectSpotWin()
    local gameName = "LottoParty"
    local wins = LottoPartyManager:getWinSpots()
    local index = #wins - 1 --领取id 列表里的最后一个
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(
        gameName,
        index,
        function()
            if not tolua.isnull(self) then
                self:changeSuccess()
            end
        end,
        function(errorCode, errorData)
            print("-----LottoParty errorCode -----", errorCode)
            self:changeFailed()
        end
    )
end

function LottoPartySpotBonusOverView:changeSuccess()
    self:closeUI()
end

function LottoPartySpotBonusOverView:changeFailed()
end

return LottoPartySpotBonusOverView
