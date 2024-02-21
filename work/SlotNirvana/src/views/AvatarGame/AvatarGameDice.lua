--[[
    
]]

local AvatarGameDice = class("AvatarGameDice", BaseView)

function AvatarGameDice:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_dice.csb"
end

function AvatarGameDice:initDatas(_isUpdateReward)
    self.m_hasUpdateReward = _isUpdateReward
end

function AvatarGameDice:initCsbNodes()
    self.m_lb_count = self:findChild("txt_diceCount")
    self.m_node_bubble = self:findChild("node_qipao")
    self.m_sp_bg = self:findChild("sp_bg")
    self.m_sp_dice_bg = self:findChild("sp_dice_bg")

    self.m_btn_play = self:findChild("btn_play")
    self.m_btn_stop = self:findChild("btn_stop")
end

function AvatarGameDice:initUI()
    AvatarGameDice.super.initUI(self)

    self:updateCount()
    self:changeIcon()
    self:setBtnState(true)
end

function AvatarGameDice:updateCount()
    local gameData = globalData.avatarFrameData:getMiniGameData()
    local count = gameData:getPropsNum()
    if count > 0 then 
        self.m_lb_count:setString(count)
        self:updateLabelSize({label = self.m_lb_count}, 26)
    else
        self.m_sp_dice_bg:setVisible(false)
    end
end

function AvatarGameDice:updateDice(_index)
    for i = 1, 6 do
        local dice1 = self:findChild("sp_dice" .. i)
        dice1:setVisible(_index == i)
        
        local dice2 = self:findChild("sp_dice_" .. i)
        dice2:setVisible(_index == i)
    end
end

function AvatarGameDice:playStart(_index, _callback)
    gLobalSoundManager:playSound("Activity/sound/game/DiceRoll.mp3")
    self:runCsbAction("start", false, function ()
        if _callback then 
            _callback()
        end
        self:updateCount()
    end, 60)

    performWithDelay(self.m_lb_count, function ()
        self:updateDice(_index)
    end, 10/60)
end

--点击监听
function AvatarGameDice:clickStartFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_play" then
        if not self:getAutoSpinFlag() and self:checkSendState() and not self:getTouchFlag() then
            performWithDelay(self.m_btn_play, function ()
                self:setTouchFlag(true)
                self:createAutoSpin()
            end, 1)
        end
    end
end

--结束监听
function AvatarGameDice:clickEndFunc(sender, eventType)
    local senderName = sender:getName()
    if senderName == "btn_play" then
        if not self:getAutoSpinFlag() then 
            self:stopAutoSpin()
        end
    end
end

function AvatarGameDice:clickFunc(_sander)
    if self:getTouchFlag() then 
        return 
    end
    self:setTouchFlag(true)

    local name = _sander:getName()
    if name == "btn_play" then 
        if self:getSendPlayFlag() then
            self:setTouchFlag(false)
            return
        end

        if not self:getAutoSpinFlag() then 
            self.m_btn_play:stopAllActions()
            self:sendPlay()
        end
    elseif name == "btn_stop" then
        self:stopAutoSpin()
        self:setBtnState(true)
        self:setTouchFlag(true)
    end
end

function AvatarGameDice:sendPlay()
    if self:checkSendState() then 
        self:setSendPlayFlag(true)
        G_GetMgr(G_REF.AvatarGame):sendPlay()
    else
        self:stopAutoSpin()
        self:setTouchFlag(true)
        self:setBtnState(true)
        self:openBubble()
    end
end

function AvatarGameDice:checkSendState()
    local gameData = globalData.avatarFrameData:getMiniGameData()
    local count = gameData:getPropsNum()
    if count <= 0 then 
        return false
    else
        return true
    end
end

function AvatarGameDice:createAutoSpin()
    self:setAutoSpinFlag(true)
    self:setBtnState(false)
    self:sendPlay()
end

function AvatarGameDice:stopAutoSpin()
    self:setAutoSpinFlag(false)
    self.m_btn_play:stopAllActions()
end

function AvatarGameDice:checkAutoSpin()
    self:setSendPlayFlag(false)
    self:setTouchFlag(false)
    if self:getAutoSpinFlag() then 
        self:sendPlay()
    end
end

function AvatarGameDice:openBubble()
    if not self.m_bubble then 
        self.m_bubble = util_createView("views.AvatarGame.AvatarGameDiceBubble")
        self.m_node_bubble:addChild(self.m_bubble)
    end
    self.m_bubble:playStart(function ()
        self:checkAutoSpin()
    end)
end

function AvatarGameDice:setTouchFlag(_flag)
    self.m_isTouch = _flag
end

function AvatarGameDice:getTouchFlag()
    return self.m_isTouch
end

function AvatarGameDice:setAutoSpinFlag(_flag)
    self.m_autoPlay = _flag
end

function AvatarGameDice:getAutoSpinFlag(_flag)
    return self.m_autoPlay
end

function AvatarGameDice:setSendPlayFlag(_flag)
    self.m_isSendPlay = _flag
end

function AvatarGameDice:getSendPlayFlag()
    return self.m_isSendPlay
end

function AvatarGameDice:changeIcon()
    if self.m_hasUpdateReward then 
        self.m_hasUpdateReward = false
        util_changeTexture(self.m_sp_bg, "Activity/img/frame_cashDice/frame_base2_jin.png")
    else
        self.m_hasUpdateReward = true
        util_changeTexture(self.m_sp_bg, "Activity/img/frame_cashDice/frame_base2.png")
    end
end

function AvatarGameDice:setBtnState(_flag)
    self.m_btn_play:setVisible(_flag)
    self.m_btn_stop:setVisible(not _flag)
end

return AvatarGameDice