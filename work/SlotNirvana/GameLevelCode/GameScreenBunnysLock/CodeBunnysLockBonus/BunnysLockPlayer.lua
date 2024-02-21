---
--xcyy
--2018年5月23日
--BunnysLockPlayer.lua

local BunnysLockPlayer = class("BunnysLockPlayer",util_require("Levels.BaseLevelDialog"))

local DIRECTION = {
    UP =  1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4
}

local rotation = {

}

function BunnysLockPlayer:initUI(params)
    self.m_parentView = params.parentView
    self:createCsbNode("Map_tuzi.csb")

    self.m_btn_up = self:findChild("Button_shang")
    self.m_btn_down = self:findChild("Button_xia")
    self.m_btn_left = self:findChild("Button_zuo")
    self.m_btn_right = self:findChild("Button_you")

    self.m_btn_up:setTag(DIRECTION.UP)
    self.m_btn_down:setTag(DIRECTION.DOWN)
    self.m_btn_left:setTag(DIRECTION.LEFT)
    self.m_btn_right:setTag(DIRECTION.RIGHT)

    self.m_curDirection = DIRECTION.UP
    self.m_spine = util_spineCreate("Kaixiangzi_tuzi",true,true)
    util_spinePlay(self.m_spine,"idleframe",true)
    self:findChild("spine"):addChild(self.m_spine)
    self.m_spine:setRotation(0)
end

--默认按钮监听回调
function BunnysLockPlayer:clickFunc(sender)
    if self.m_isWaitting  then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()

    self.m_isWaitting = true

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")

    -- if tag == DIRECTION.UP then
    -- elseif tag == DIRECTION.DOWN then
    -- elseif tag == DIRECTION.LEFT then
    -- elseif tag == DIRECTION.RIGHT then
    -- end
    self.m_parentView:sendData(tag)
    self:fadeShowBtns(false)
end

--[[
    重置显示
]]
function BunnysLockPlayer:resetUI(pos,isHideBtn)
    self.m_isWaitting = false
    if isHideBtn then
        self:hideAllBtns()
    else
        self.m_btn_down:setVisible(true)
        self.m_btn_up:setVisible(true)
        self.m_btn_left:setVisible(true)
        self.m_btn_right:setVisible(true)

        if pos[2] == 0 then
            self.m_btn_down:setVisible(false)
        elseif pos[2] == 4 then
            self.m_btn_up:setVisible(false)
        end

        if pos[1] == 0 then
            self.m_btn_left:setVisible(false)
        elseif pos[1] == 8 then
            self.m_btn_right:setVisible(false)
        end

        self:fadeShowBtns(true)
    end
end

function BunnysLockPlayer:fadeShowBtns(isShow)
    local actionList = {}
    if isShow then
        self:runCsbAction("start",false,function()
            self:runCsbAction("idleframe",true)
            self.m_btn_down:setTouchEnabled(true)
            self.m_btn_up:setTouchEnabled(true)
            self.m_btn_left:setTouchEnabled(true)
            self.m_btn_right:setTouchEnabled(true)
        end)
    else
        self.m_btn_down:setTouchEnabled(false)
        self.m_btn_up:setTouchEnabled(false)
        self.m_btn_left:setTouchEnabled(false)
        self.m_btn_right:setTouchEnabled(false)
        self:runCsbAction("switch",false,function()
        end)
    end
end

--[[
    隐藏按钮
]]
function BunnysLockPlayer:hideAllBtns()
    self.m_btn_down:setVisible(false)
    self.m_btn_up:setVisible(false)
    self.m_btn_left:setVisible(false)
    self.m_btn_right:setVisible(false)
end

--[[
    执行移动动作
]]
function BunnysLockPlayer:runMoveAct(direction,endPos,func)
    local dir_index = {
        [DIRECTION.UP] = 0,
        [DIRECTION.RIGHT] = 90,
        [DIRECTION.DOWN] = 180,
        [DIRECTION.LEFT] = 270,
    }

    local rotation = dir_index[direction]

    local seq = {}
    if direction ~= self.m_curDirection  then
        self.m_spine:runAction(cc.RotateTo:create(0.5,rotation))
        seq[#seq + 1] = cc.DelayTime:create(0.5)
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_player_move_with_rotation.mp3")
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_player_move_without_rotation.mp3")
    end
    
    

    seq[#seq + 1] = cc.MoveTo:create(0.5,endPos)
    seq[#seq + 1] = cc.CallFunc:create(function()
        if type(func) == "function" then
            func()
        end
    end)
    self:runAction(cc.Sequence:create(seq))
    
    self.m_curDirection = direction
end

function BunnysLockPlayer:resetDirection()
    self.m_curDirection = DIRECTION.UP
    self.m_spine:setRotation(0)
end

return BunnysLockPlayer