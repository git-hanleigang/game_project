local BaseView = util_require("base.BaseView")

local GoldenPigCollectOverView = class("GoldenPigCollectOverView",BaseView )

function GoldenPigCollectOverView:initUI(data)
	self.m_clickFlag = false
	self.m_winCoins = 0

    self:createCsbNode("GoldenPig/CollectOver.csb")

    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
    end)

    self:initViewData(data.startPrice, data.multip, data.coins, data.callBackFun)
end

function GoldenPigCollectOverView:initViewData(startPrice, multip, coins, callBackFun)
	self.m_clickFlag = false
	self.m_winCoins = coins
	self.m_callFun = callBackFun

    local labTotalCoins = self:findChild("m_lb_totalcoins")
    labTotalCoins:setString(util_formatCoins(self.m_winCoins,50))
    self:updateLabelSize({label=labTotalCoins,sx=1,sy=1},984)

	local labMultiple = self:findChild("m_lb_num")
	labMultiple:setString(util_formatCoins(startPrice, 50) .. " X " .. multip .. " = " .. util_formatCoins(coins, 50))
    self:updateLabelSize({label=labMultiple,sx=1.25,sy=1.25},669)

    self.m_bgSound = gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_collect_end.mp3")
end

function GoldenPigCollectOverView:onEnter()
    
end

function GoldenPigCollectOverView:onExit()
    if self.m_bgSound then
        gLobalSoundManager:stopAudio(self.m_bgSound)
        self.m_bgSound = nil
    end
end

function GoldenPigCollectOverView:clickFunc(sender)
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

function GoldenPigCollectOverView:closeUI()
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end

return GoldenPigCollectOverView