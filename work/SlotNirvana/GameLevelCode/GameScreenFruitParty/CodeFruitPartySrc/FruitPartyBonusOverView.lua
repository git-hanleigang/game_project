---
--island
--2018年4月12日
--FruitPartyHugeWinView.lua
local FruitPartyHugeWinView = class("FruitPartyHugeWinView", util_require("base.BaseView"))


FruitPartyHugeWinView.m_isOverAct = false
FruitPartyHugeWinView.m_isJumpOver = false

function FruitPartyHugeWinView:initUI(data)
    local resourceFilename = "FruitParty/BonusGameOver.csb"
    self:createCsbNode(resourceFilename)

    self:runCsbAction("idle")

    local Node_player = self:findChild("Node_player")
    Node_player:removeAllChildren(true)

    --第一名头像
    self.m_player_champion = util_createAnimation("FruitParty_Bonusover_champion.csb")
    
    Node_player:addChild(self.m_player_champion)
    self.m_playerItems = {}
    for index = 1,8 do
        local playerItem = util_createAnimation("FruitParty_Bonusover_player.csb")
        util_setCascadeOpacityEnabledRescursion(playerItem:findChild("sp_head"), true)
        if index % 2 == 0 then
            playerItem:setPositionY(-100)
        else
            playerItem:setPositionY(100)
        end
        Node_player:addChild(playerItem)
        self.m_playerItems[index] = playerItem
    end

    --测试代码
    -- local startIndex = 1
    -- function showNext()
    --     self:resetHeadPos(startIndex)
    --     startIndex = startIndex + 1
    --     if startIndex > 9 then
    --         startIndex = 1
    --     end
    --     performWithDelay(self,function(  )
    --         showNext()
    --     end,1)
    -- end
    -- showNext()
end

--[[
    重置头像位置
]]
function FruitPartyHugeWinView:resetHeadPos(count)
    if count > 9 then
        count = 9
    end
    --显示所需头像
    for index = 1,8 do
        local playerItem = self.m_playerItems[index]
        if index <= count - 1 then
            playerItem:setVisible(true)
        else
            playerItem:setVisible(false)
        end
    end
    local width = 320
    --计算总的区域宽度
    local areaWidth = width + (width / 2) * math.ceil((count - 1) / 2)

    self.m_player_champion:setPositionX(-areaWidth / 2 + width / 2)

    local offsetX = -areaWidth / 2 + 240
    for index = 1,count - 1 do
        local playerItem = self.m_playerItems[index]
        playerItem:setPositionX(offsetX + width / 2)
        if index % 2 == 0 then
            offsetX = offsetX + width / 2
        end
    end
end

function FruitPartyHugeWinView:onEnter()
end

function FruitPartyHugeWinView:onExit()
    
end

--[[
    设置头像信息
]]
function FruitPartyHugeWinView:setHeadInfo(rankList)
    local championData = rankList[1]
    self:refreshHead(self.m_player_champion,championData)
    local maxIndex = #rankList
    if maxIndex > 9 then
        maxIndex = 9
    end
    for index = 2,maxIndex do
        local rankData = rankList[index]
        local playerItem = self.m_playerItems[index - 1]
        self:refreshHead(playerItem,rankData)
    end
end

--[[
    刷新头像
]]
function FruitPartyHugeWinView:refreshHead(item,data)
    item:findChild("m_lb_coins"):setString(util_formatCoins(data.coins, 4))

    local playerData = self.m_allPlayers[data.udid]
    item:findChild("sp_head"):removeAllChildren(true)
    -- util_setCascadeOpacityEnabledRescursion(item:findChild("sp_head"), true)

    local fbid = playerData.facebookId
    local headName = playerData.head
    -- local isMe = data.udid == globalData.userRunData.userUdid
    -- local frameId = isMe and globalData.userRunData.avatarFrameId or playerData.frame
    -- local headSize = item:findChild("sp_head"):getContentSize()
    -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize)
    -- item:findChild("sp_head"):addChild(nodeAvatar)
    -- nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    

    local headNode = item:findChild("sp_head")
    util_setHead(headNode, fbid, headName, nil, true)
    util_setCascadeOpacityEnabledRescursion(item:findChild("sp_head"), true)
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
    -- item:findChild("Node_name"):setLocalZOrder(20)
    -- util_setCascadeOpacityEnabledRescursion(item:findChild("Node_Player"), true)

    item:findChild("sp_headFrame_me"):setVisible(data.udid == globalData.userRunData.userUdid)
    item:findChild("sp_headFrame"):setVisible(data.udid ~= globalData.userRunData.userUdid)

    local txt_name = item:findChild("Text_1")
    txt_name:setString(playerData.nickName or "")
    txt_name:stopAllActions()
    
    local clipNode = txt_name:getParent()
    local clipSize = clipNode:getContentSize()
    txt_name:setAnchorPoint(cc.p(0.5,0.5))
    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))

    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)
end

function FruitPartyHugeWinView:showView(rankList,allPlayers,func)
    self.m_callBack = func
    self.m_rankList = rankList
    self.m_allPlayers = allPlayers
    self.m_isWaitting = false

    self:setVisible(true)

    --重置头像位置
    self:resetHeadPos(#rankList)

    
    --设置头像信息
    self:setHeadInfo(rankList)
    
    local maxIndex = #rankList - 1
    if maxIndex > 8 then
        maxIndex = 8
    end

    --显示小头像
    self:showNextHead(maxIndex,maxIndex,self.m_playerItems)
    
    self:runCsbAction("start",false,function(  )

    end)
end

--[[
    显示下个头像
]]
function FruitPartyHugeWinView:showNextHead(index,maxIndex,items)
    if index <= 0 then
        gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_over_show_champion.mp3")
        self.m_player_champion:runCsbAction("show",false,function(  )
            self.m_player_champion:runCsbAction("idle",true)
            gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_show_mail.mp3")
            self:runCsbAction("start2",false,function(  )
                self:runCsbAction("idle")
            end)
        end)
        
        return
    end

    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_over_show_others_"..(maxIndex - index + 1)..".mp3")
    local playerItem = items[index]
    playerItem:runCsbAction("show",false,function(  )
        playerItem:runCsbAction("idle",true)
    end)

    performWithDelay(playerItem,function(  )
        self:showNextHead(index - 1,maxIndex,items)
    end,30 / 60)
end

function FruitPartyHugeWinView:clickFunc(sender)
    local name = sender:getName()
    if self.m_isWaitting then
        return 
    end

    self.m_isWaitting = true

    self.m_player_champion:runCsbAction("over")
    local maxIndex = #self.m_rankList - 1
    if maxIndex > 8 then
        maxIndex = 8
    end
    for index = 1,maxIndex do
        local playerItem = self.m_playerItems[index]
        playerItem:runCsbAction("over")
    end

    self:runCsbAction("over",false,function(  )
        self:setVisible(false)
        if type(self.m_callBack) == "function" then
            self.m_callBack()
        end
    end)
end


return FruitPartyHugeWinView

