---
--xcyy
--2018年5月23日
--FrozenJewelryModeView.lua

local FrozenJewelryModeView = class("FrozenJewelryModeView",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_HIGH      =       1001
local BTN_TAG_LOW       =       1002

function FrozenJewelryModeView:initUI(params)

    self.m_endFunc = params.callBack
    local minBet = params.minBet

    self:createCsbNode("FrozenJewelry/Mode.csb")

    self:findChild("Button_regular"):setTag(BTN_TAG_LOW)
    self:findChild("Button_fortune"):setTag(BTN_TAG_HIGH)

    self:findChild("m_lb_coins"):setString(util_formatCoins(minBet,30))
    local info={label=self:findChild("m_lb_coins"),sx=1,sy=1}
    self:updateLabelSize(info,335)

    self.m_isWaitting = true
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_mode_view.mp3")
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self.m_isWaitting = false
    end)
end

--默认按钮监听回调
function FrozenJewelryModeView:clickFunc(sender)
    if self.m_isWaitting then
        return
    end
    self.m_isWaitting = true
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_btn_click.mp3")
    local tag = sender:getTag()
    local choose = (tag == BTN_TAG_HIGH) and "high" or "low"
    
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc(choose)
        end
        self:removeFromParent()
    end)
end


return FrozenJewelryModeView