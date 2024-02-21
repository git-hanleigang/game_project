--jacpot结果展示
local PowerUpJackpoWinView = class("PowerUpJackpoWinView",util_require("base.BaseView"))

PowerUpJackpoWinView.m_imageList = {"PowerUp_grand1_3","PowerUp_major1_4","PowerUp_minor1_6","PowerUp_mini1_5"}
--jackpot 结果界面
function PowerUpJackpoWinView:initUI(data, _machine)
    self.m_machine = _machine
    self.m_callback = data.callback
    self:createCsbNode("PowerUp/jackpotover.csb")
    self:findChild("ml_b_coins"):setString(util_formatCoins(data.coins,10))

    self:updateLabelSize({label=self:findChild("ml_b_coins"),sx=1.35,sy=1.6},380)

    self.m_jackpotIndex = data.type
    self:createGrandShare(self.m_machine)

    for i=1,#self.m_imageList do
        if i == data.type then
            self:findChild(self.m_imageList[i]):setVisible(true)
        else
            self:findChild(self.m_imageList[i]):setVisible(false)
        end
    end
    gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_result.mp3")
    self:runCsbAction("start",false,function()
        if self.m_isClick == nil then
            self:runCsbAction("idle",true)
        end
        self:jumpCoinsFinish()
    end)
end

function PowerUpJackpoWinView:onEnter()
    gLobalSoundManager:pauseBgMusic()
end


function PowerUpJackpoWinView:onExit()
    gLobalSoundManager:resumeBgMusic( )
    if self.m_callback then
        self.m_callback()
    end
end

--默认按钮监听回调
function PowerUpJackpoWinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    if self:checkShareState() then
        return
    end

    if self.m_isClick  then
        return
    end
    self:jackpotViewOver(function()
        
        self.m_isClick = true
        self:findChild(name):setTouchEnabled(false)
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    
        self:runCsbAction("over",false,function()
            self:removeFromParent()
        end)

    end)
    
end

--[[
    自动分享 | 手动分享
]]
function PowerUpJackpoWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function PowerUpJackpoWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function PowerUpJackpoWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function PowerUpJackpoWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return PowerUpJackpoWinView