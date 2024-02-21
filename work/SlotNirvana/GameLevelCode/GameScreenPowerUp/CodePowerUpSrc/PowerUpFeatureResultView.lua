local PowerUpFeatureResultView = class("PowerUpFeatureResultView",util_require("base.BaseView"))
PowerUpFeatureResultView.m_callback = nil
-- feature 玩法结果界面
function PowerUpFeatureResultView:initUI(data)
    if data.type == 1 then
        self:createCsbNode("PowerUp/Featureover2.csb")
    else
        self:createCsbNode("PowerUp/Featureover1.csb")
    end
    self.m_callback = data.callback
    self:findChild("ml_b_coins"):setString(util_formatCoins(data.coins,10))
    self:updateLabelSize({label=self:findChild("ml_b_coins"),sx=1.35,sy=1.6},380)

    gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_result.mp3")

    self:runCsbAction("start",false,function()
        if self.m_isClick == nil then
            self:runCsbAction("idle",true)
        end
    end)
end

function PowerUpFeatureResultView:onEnter()
    gLobalSoundManager:pauseBgMusic()

end


function PowerUpFeatureResultView:onExit()
    gLobalSoundManager:resumeBgMusic( )
    if self.m_callback then
        self.m_callback()
    end
end

--默认按钮监听回调
function PowerUpFeatureResultView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_isClick  then
        return
    end
    self.m_isClick = true
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")

    self:findChild(name):setTouchEnabled(false)
    self:runCsbAction("over",false,function()

        self:removeFromParent()

    end)
end


return PowerUpFeatureResultView