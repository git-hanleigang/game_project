--[[--
    回收机 - 乐透
]]
local BaseView = util_require("base.BaseView")
local CardRecoverLettoSpin = class("CardRecoverLettoSpin", BaseView)
local CSB_FRAME = 30
function CardRecoverLettoSpin:initUI(coins,mul,func)
    self.m_isShowIdle = false
    self.m_clickFunc = func
    self:createCsbNode( string.format(CardResConfig.commonRes.CardRecoverLettoSpinRes, "common"..CardSysRuntimeMgr:getCurAlbumID()))
    
    local m_lb_mul = self:findChild("m_lb_mul")
    m_lb_mul:setString("*"..mul)
    if mul>=100 then
        m_lb_mul:setScale(m_lb_mul:getScale()*0.9)
    end
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_coins:setString(util_getFromatMoneyStr(coins))
    self:updateLabelSize({label = self.m_lb_coins,sx = 0.89,sy =0.89},325*0.89)
    local width=math.min(325*0.89,self.m_lb_coins:getContentSize().width*0.89)*0.5
    local posx,posy = self.m_lb_coins:getPosition()
    
    local sp_coins = self:findChild("sp_coins")
    sp_coins:setPosition(posx-width-40,posy)
end

function CardRecoverLettoSpin:showIdle()
    self:runCsbAction("show", false, function()
        self.m_isShowIdle = true
        self:runCsbAction("idle")
    end, CSB_FRAME)
end
function CardRecoverLettoSpin:showOver()
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end, CSB_FRAME)
end
function CardRecoverLettoSpin:clickFunc(sender)
    if not self.m_isShowIdle then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_spin" then
        sender:setTouchEnabled(false)
        if self.m_clickFunc then
            self.m_clickFunc()
        end
    end
end
return CardRecoverLettoSpin