---
--xcyy
--2018年5月23日
--BlackFridayCoinCollectBar.lua
--积分收集条

local BlackFridayCoinCollectBar = class("BlackFridayCoinCollectBar",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_SHOW_SHOP         =           1001        --显示商店
local BTN_TAG_SHOW_TIP          =           1002        --显示提示

function BlackFridayCoinCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("BlackFriday_shop.csb")
    
    self:findChild("click_di"):setTag(BTN_TAG_SHOW_SHOP)
    self:findChild("click_di"):setTouchEnabled(true)
    self:addClick(self:findChild("click_di"))

    --提示按钮
    self.m_tipBtn = util_createAnimation("BlackFriday_base_i.csb")
    self:findChild("Node_i"):addChild(self.m_tipBtn)
    self:addClick(self.m_tipBtn:findChild("Button_1"))
    self.m_tipBtn:findChild("Button_1"):setTag(BTN_TAG_SHOW_TIP)

    self.m_tip = util_createAnimation("BlackFriday_base_tips.csb")
    self.m_tipBtn:findChild("Node_tips"):addChild(self.m_tip)
    self.m_tip:setVisible(false)

    self:runCsbAction("idle",true)
end


function BlackFridayCoinCollectBar:updateCoins(score)
    self:findChild("m_lb_coins"):setString(util_formatCoins(score,11))
    self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=1,sy=1},150)
end

--默认按钮监听回调
function BlackFridayCoinCollectBar:clickFunc(sender)
    local tag = sender:getTag()
    
    if tag == BTN_TAG_SHOW_SHOP then --显示商店
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
        if self.m_tip:isVisible() then
            self:hideTip()
            -- return
        end
        self.m_machine:showShopView()
    elseif tag == BTN_TAG_SHOW_TIP then --显示提示
        if self.m_machine:getCurrSpinMode() == AUTO_SPIN_MODE then
            return
        end

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
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
function BlackFridayCoinCollectBar:showTip()
    self.m_tip:setVisible(true)
    self.m_tip:runCsbAction("start",false,function()
        self.m_tip:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:hideTip()
        end, 5)
    end)
end

--[[
    显示提示
]]
function BlackFridayCoinCollectBar:hideTip()
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    else
        return
    end

    self.m_tip:runCsbAction("over",false,function()
        self.m_tip:setVisible(false)
    end)
end

return BlackFridayCoinCollectBar