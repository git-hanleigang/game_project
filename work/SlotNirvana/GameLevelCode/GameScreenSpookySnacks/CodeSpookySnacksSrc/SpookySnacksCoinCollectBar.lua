---
--xcyy
--2018年5月23日
--SpookySnacksCoinCollectBar.lua
--积分收集条
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksCoinCollectBar = class("SpookySnacksCoinCollectBar",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_SHOW_SHOP         =           1001        --显示商店
local BTN_TAG_SHOW_TIP          =           1002        --显示提示

function SpookySnacksCoinCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("SpookySnacks_base_money.csb")
    
    self:findChild("click_di"):setTag(BTN_TAG_SHOW_SHOP)
    self:findChild("click_di"):setTouchEnabled(true)
    self:addClick(self:findChild("click_di"))

    --提示按钮
    self.m_tipBtn = util_createAnimation("SpookySnacks_base_money_i.csb")
    self:findChild("Node_base_i"):addChild(self.m_tipBtn)
    self:addClick(self.m_tipBtn:findChild("Button_base_i"))
    self.m_tipBtn:findChild("Button_base_i"):setTag(BTN_TAG_SHOW_TIP)

    self.m_tip = util_createAnimation("SpookySnacks_base_money_i_message.csb")
    self.m_tipBtn:findChild("Node_base_i_wenben"):addChild(self.m_tip)
    self.m_tip:setVisible(false)

    -- self:runCsbAction("idle",true)
end

function SpookySnacksCoinCollectBar:onExit()
    SpookySnacksCoinCollectBar.super.onExit(self)
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end
end


function SpookySnacksCoinCollectBar:updateCoins(score)
    self:findChild("m_lb_coins"):setString(util_formatCoins(score,11))
    self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=1,sy=1},150)
end

--默认按钮监听回调
function SpookySnacksCoinCollectBar:clickFunc(sender)
    local tag = sender:getTag()
    
    if tag == BTN_TAG_SHOW_SHOP then --显示商店
        -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
        if self.m_tip:isVisible() then
            if self.m_scheduleId then
                self:stopAction(self.m_scheduleId)
                self.m_scheduleId = nil
            end
            self.m_tip:setVisible(false)
            -- return
        end
        self.m_machine:showShopView()
    elseif tag == BTN_TAG_SHOW_TIP then --显示提示
        if self.m_machine:getCurrSpinMode() == AUTO_SPIN_MODE then
            return
        end

        -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
        if self.m_tip:isVisible() then
            self:hideTip()
        else
            if self.m_machine.getGameSpinStage() == IDLE then
                self:showTip()
            end
        end
    end
end

--[[
    显示提示
]]
function SpookySnacksCoinCollectBar:showTip()
    if self.m_machine.getGameSpinStage() == IDLE then
        self.m_tip:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_tips_show)
        self.m_tip:runCsbAction("start",false,function()
            self.m_tip:runCsbAction("idle",true)
            self.m_scheduleId = schedule(self, function(  )
                self:hideTip()
            end, 5)
        end)
    end
    
end

--[[
    显示提示
]]
function SpookySnacksCoinCollectBar:hideTip()
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    else
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_tips_hide)
    self.m_tip:runCsbAction("over",false,function()
        self.m_tip:setVisible(false)
    end)
end

function SpookySnacksCoinCollectBar:getCollectEndNode()
    return self:findChild("Node_fly")
end

function SpookySnacksCoinCollectBar:showCollectEffect()
    self:runCsbAction("actionframe")
    local particle = self:findChild("Particle_1")
    if particle then
        particle:resetSystem()
    end
end

return SpookySnacksCoinCollectBar