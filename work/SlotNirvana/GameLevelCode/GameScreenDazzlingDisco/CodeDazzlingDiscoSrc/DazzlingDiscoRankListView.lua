---
--xcyy
--2018年5月23日
--DazzlingDiscoRankListView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoRankListView = class("DazzlingDiscoRankListView",util_require("Levels.BaseLevelDialog"))


function DazzlingDiscoRankListView:initUI(params)
    self.m_rankListData = clone(params.rankList) 

    --排名数据

    table.sort(self.m_rankListData,function(a,b)
        return a.coins > b.coins
    end)
    --自身排名
    local selfRank = nil
    for k,rankData in pairs(self.m_rankListData) do
        if rankData.udid == globalData.userRunData.userUdid then
            selfRank = rankData
            selfRank.rank = k
            break
        end
    end

    local coins = 0
    if not selfRank then
        selfRank = {
            coins = 0,
            multiple = 0,
            udid = globalData.userRunData.userUdid,
            rank = 9
        }
    end

    --判断自身排名
    if selfRank.rank > 8 then
        local rank = selfRank.rank
        --交换排名
        local temp = self.m_rankListData[8]
        self.m_rankListData[8] = self.m_rankListData[rank]
        self.m_rankListData[rank] = temp
        selfRank.rank = 8
    end

    self.m_collectData = params.collectData
    self.m_callBack = params.func
    self:getAllPlayers()
    self:createCsbNode("DazzlingDisco_paihangbang.csb")

    local userCount = #self.m_rankListData
    if userCount > 8 then
        userCount = 8
    end
    self.m_player_champion = util_createAnimation("DazzlingDisco_paihangbantouxiang_0.csb")
    self:findChild("root"):addChild(self.m_player_champion)
    self.m_player_champion:setPositionY(63)
    self:refreshHead(self.m_player_champion,self.m_rankListData[1])

    self.m_players = {}
    if #self.m_rankListData > 1 then
        for index = 2,userCount do
            local item = util_createAnimation("DazzlingDisco_paihangbantouxiang.csb")
            self:findChild("root"):addChild(item)
            self:refreshHead(item,self.m_rankListData[index])
            self.m_players[#self.m_players + 1] = item
            if index % 2 == 0 then
                item:setPositionY(120)
            else
                item:setPositionY(-30)
            end

        end
    end

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:resetHeadPos(userCount)

    self:runCsbAction("start")

    self.m_isClickEnable = false
    
    self.m_player_champion:runCsbAction("start",false,function(  )
        self:showNextHead(1,function(  )
            self.m_isClickEnable = true
        end)
    end) 
end

--[[
    获取所有玩家信息
]]
function DazzlingDiscoRankListView:getAllPlayers()
    self.m_allPlayers = {}
    for i,playerData in ipairs(self.m_collectData) do
        if not self.m_allPlayers[playerData.udid] then
            self.m_allPlayers[playerData.udid] = playerData
        end
    end
end

--[[
    重置头像位置
]]
function DazzlingDiscoRankListView:resetHeadPos(count)
    if count > 8 then
        count = 8
    end
    local width = 260

    --计算总的区域宽度
    local areaWidth = (width / 2) * math.ceil((count - 1) / 2)


    self.m_player_champion:setPositionX(-areaWidth / 2)
    local offsetX = -areaWidth / 2 + 80
    --显示所需头像
    for index = 1,#self.m_players do
        local playerItem = self.m_players[index]
        playerItem:setPositionX(offsetX + width / 2)
        if index % 2 == 0 then
            offsetX = offsetX + width / 2
        end
    end
end

--[[
    刷新头像
]]
function DazzlingDiscoRankListView:refreshHead(item,data)
    item:findChild("m_lb_coins"):setString(util_formatCoins(data.coins, 3))

    local playerData = self.m_allPlayers[data.udid]
    local isMe = (data.udid == globalData.userRunData.userUdid)

    local fbid = playerData.facebookId
    local headName = isMe and globalData.userRunData.HeadName or playerData.head

    local headNode --= item:findChild("sp_head")
    if isMe then
        headNode = item:findChild("sp_head_me")
    else
        headNode = item:findChild("sp_head_other")
    end
    headNode:removeAllChildren(true)
    util_setHead(headNode, fbid, headName, nil, true)
    
    if item:findChild("Node_me") then
        item:findChild("Node_me"):setVisible(isMe)
    end

    if item:findChild("Node_other") then
        item:findChild("Node_other"):setVisible(not isMe)
    end

    local txt_name = item:findChild("txt_name")
    txt_name:setString(playerData.nickName or "")
    txt_name:stopAllActions()
    
    local clipNode = txt_name:getParent()
    local clipSize = clipNode:getContentSize()
    txt_name:setAnchorPoint(cc.p(0.5,0.5))
    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))

    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)
end

--[[
    显示下个头像
]]
function DazzlingDiscoRankListView:showNextHead(index,func)
    if index > #self.m_players then
        if type(func) == "function" then
            func()
        end
        return
    end
    local playerItem = self.m_players[index]
    playerItem:runCsbAction("start",false,function(  )
        playerItem:runCsbAction("idle",true)
    end)

    performWithDelay(playerItem,function(  )
        self:showNextHead(index + 1,func)
    end,20 / 60)
end

function DazzlingDiscoRankListView:clickFunc(sender)
    local name = sender:getName()
    if not self.m_isClickEnable then
        return 
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)
    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_close_rank_view_sound)
    self.m_isClickEnable = false
    self:runCsbAction("over",false,function(  )
        if type(self.m_callBack) == "function" then
            self.m_callBack()
        end
        self:removeFromParent()
    end)
end


return DazzlingDiscoRankListView