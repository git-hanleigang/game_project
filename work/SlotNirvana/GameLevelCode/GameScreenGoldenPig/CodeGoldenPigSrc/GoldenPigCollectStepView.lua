local BaseView = util_require("base.BaseView")

local GoldenPigCollectStepView = class("GoldenPigCollectStepView",BaseView )

function GoldenPigCollectStepView:initUI(data)
	self.m_clickFlag = false
	self.m_winCoins = data.coins
    self.m_callFun = data.callBackFun

    self:createCsbNode("GoldenPig/ReSpinOver.csb")

    self.m_bgSound = gLobalSoundManager:playBgMusic("GoldenPigSounds/music_GoldenPig_collect_bg.mp3")

    local winNode = self:findChild("Sprite_19")
    if winNode then
        winNode:setPositionY(winNode:getPositionY() - 20)
    end

    local coinBgNode = self:findChild("GoldenPig_duan_kuang_20")
    if coinBgNode then
        coinBgNode:setPositionY(coinBgNode:getPositionY() - 40)
    end

    local coinNode = self:findChild("Node_8")
    if coinNode then
        coinNode:setPositionY(coinNode:getPositionY() - 40)
    end

    local coinBgLight = self:findChild("yingqiansgNode")
    if coinBgLight then
        coinBgLight:setPositionY(coinBgLight:getPositionY() - 40)
    end

    local respinNode = self:findChild("Node_9")
    if respinNode then
        respinNode:setVisible(false)
    end

    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
    end)

    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(self.m_winCoins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1},948)
end


function GoldenPigCollectStepView:onEnter()
    
end

function GoldenPigCollectStepView:onExit()
    if self.m_bgSound then
        gLobalSoundManager:stopAudio(self.m_bgSound)
        self.m_bgSound = nil
    end
end

function GoldenPigCollectStepView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
        if self.m_clickFlag == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        
        self.m_clickFlag = true
        self:closeUI()
    end
end

function GoldenPigCollectStepView:closeUI()
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end

        self:removeFromParent()
    end)
end

return GoldenPigCollectStepView