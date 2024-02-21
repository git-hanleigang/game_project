--[[
]]

local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local AvatarGameMainLayer = class("AvatarGameMainLayer", BaseActivityMainLayer)

function AvatarGameMainLayer:getBgMusicPath()
    return "Activity/sound/game/GameBGM.mp3"
end

function AvatarGameMainLayer:ctor()
    AvatarGameMainLayer.super.ctor(self)

    self:setLandscapeCsbName("Activity/csb/Cash_dice/CashDice_mainUi.csb")
    self:setExtendData("AvatarGameMainLayer")
end

function AvatarGameMainLayer:initCsbNodes()
    self.m_node_logo = self:findChild("node_logo")
    self.m_node_winnerShow = self:findChild("node_winnerShow")
    self.m_node_jackpot = self:findChild("node_jackpot")
    self.m_node_progress = self:findChild("node_progress")
    self.m_node_dice = self:findChild("node_dice")
    self.m_node_player = self:findChild("node_player")
    self.m_node_middle = self:findChild("node_middle")
end

function AvatarGameMainLayer:initDatas(_data)
    self.m_cellList = {}
    self.m_cellCount = 16
    self.m_playTimeCount = 10
    self.m_offsetX = 1
    self.m_offsetY = 91
    -- self:insertPlistInfo("")
    self:updateData()
end

function AvatarGameMainLayer:updateData()
    self.m_gameData = globalData.avatarFrameData:getMiniGameData()
    self.m_curSeq = self.m_gameData:getCurSeq() + 1
    self.m_type = self.m_gameData:getType()

    local playTimes = self.m_gameData:getPlayTimes()
    if playTimes > 0 and playTimes % (self.m_playTimeCount + 1) == 10 then 
        self.m_isUpdateReward = true
    else
        self.m_isUpdateReward = false
    end
end

function AvatarGameMainLayer:initView()
    self:initLogo()
    -- self:initWinner()
    self:initJackpot()
    self:initProgress()
    self:initDice()
    self:initCell()
    self:initPlayer()
end

function AvatarGameMainLayer:initLogo()
    local logo = util_createView("views.AvatarGame.AvatarGameLogo")
    self.m_node_logo:addChild(logo)
end

-- function AvatarGameMainLayer:initWinner()
--     self.m_winnerShow = util_createView("views.AvatarGame.AvatarGameWinner")
--     self.m_node_winnerShow:addChild(self.m_winnerShow)
-- end

function AvatarGameMainLayer:initJackpot()
    self.m_jackpot = util_createView("views.AvatarGame.AvatarGameJackpot", self.m_isUpdateReward)
    self.m_node_jackpot:addChild(self.m_jackpot)
end

function AvatarGameMainLayer:initProgress()
    self.m_progress = util_createView("views.AvatarGame.AvatarGameProgress")
    self.m_node_progress:addChild(self.m_progress)
end

function AvatarGameMainLayer:initDice()
    self.m_dice = util_createView("views.AvatarGame.AvatarGameDice", self.m_isUpdateReward)
    self.m_node_dice:addChild(self.m_dice)
end

function AvatarGameMainLayer:initCell()
    for i = 1, self.m_cellCount do
        local cell = util_createView("views.AvatarGame.AvatarGameCell", i, self.m_isUpdateReward)
        self:findChild("node_scene" .. i):addChild(cell)
        table.insert(self.m_cellList, cell)
    end
end

function AvatarGameMainLayer:initPlayer()
    self.m_player = util_createView("views.AvatarGame.AvatarGamePlayer")
    self.m_node_player:addChild(self.m_player)
    local cell = self:findChild("node_scene" .. self.m_curSeq)
    local x, y = cell:getPosition()
    self.m_node_player:setPosition(x + self.m_offsetX, y + self.m_offsetY)
end

function AvatarGameMainLayer:playerAction()
    if self.m_moveLen <= self.m_moveCount then 
        self.m_player:Action(
            function ()
                self:playerMove()
            end,
            function ()
                self:playerAction()
            end
        )
    else
        G_GetMgr(G_REF.AvatarGame):showCollectLayer(self.m_params, self.m_dice:getAutoSpinFlag())
    end
end

function AvatarGameMainLayer:playerMove()
    local index = (self.m_curSeq + self.m_moveLen) % self.m_cellCount
    local cell = self:findChild("node_scene" .. (index == 0 and self.m_cellCount or index))
    local x, y = cell:getPosition()
    local move = cc.MoveTo:create(0.333, cc.p(x + self.m_offsetX, y + self.m_offsetY))
    self.m_node_player:runAction(move)
    self.m_moveLen = self.m_moveLen + 1
end

function AvatarGameMainLayer:checkReward()
    local type = self.m_type
    self:updateData()
    if type ~= self.m_type then 
        local smoke = util_createView("views.AvatarGame.AvatarGameSmoke")
        self.m_node_middle:addChild(smoke)
        smoke:playStart(function ()
            self.m_dice:checkAutoSpin()
        end)
        
        performWithDelay(self.m_node_dice, function ()
            for i,v in ipairs(self.m_cellList) do
                v:rewardUpdate()
            end
            self.m_jackpot:rewardUpdate()
            self.m_dice:changeIcon()
            self.m_progress:setVisible(self.m_type ~= 2)
        end, 30/60)
    else
        self.m_dice:checkAutoSpin()
    end
end

function AvatarGameMainLayer:clickFunc(_sander)
    local name = _sander:getName()
    if name == "btn_close" then 
        if self.m_dice:getTouchFlag() or self.m_dice:getSendPlayFlag() then 
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_USER_GAME_PLAY)
        self:closeUI()
    elseif name == "btn_info" then
        G_GetMgr(G_REF.AvatarGame):showInfoLayer()
    end
end

function AvatarGameMainLayer:registerListener()
    AvatarGameMainLayer.super.registerListener(self)

    -- 摇骰子
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.hitIndex then 
                local curSeq = self.m_curSeq - 1
                local count = params.hitIndex - curSeq
                if params.hitIndex < curSeq then 
                    count = self.m_cellCount - curSeq + params.hitIndex
                end
                self.m_params = params
                self.m_moveCount = count
                self.m_moveLen = 1

                self.m_dice:playStart(count, function ()
                    self:playerAction()
                    self.m_progress:updateProgress()
                    -- self.m_winnerShow:updateWinner()
                end)
            else
                self.m_dice:setTouchFlag(false)
                gLobalViewManager:showReConnect()
            end
        end,
        ViewEventType.NOTIFY_AVATAR_GAME_PLAY
    )

    -- 领取
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:checkReward()
        end,
        ViewEventType.NOTIFY_AVATAR_GAME_COLLECT
    )
end

return AvatarGameMainLayer