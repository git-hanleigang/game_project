---
--xcyy
--2018年5月23日
--KoiBlissRespinStartView.lua
local PublicConfig = require "KoiBlissPublicConfig"
local KoiBlissRespinStartView = class("KoiBlissRespinStartView",util_require("Levels.BaseLevelDialog"))

function KoiBlissRespinStartView:initUI(machine)
    self:createCsbNode("KoiBliss/ReSpinStart_guang.csb")
    self.m_machine = machine
    self.m_endFunc = nil
    self.m_allowClick = false
    -- self.tanbanBG = util_spineCreate("KoiBliss_juese",true,true)
    -- self:findChild("Node_guangquan"):addChild(self.tanbanBG)
    -- self.tanbanBG:setVisible(false)
    -- util_spinePlay(self.tanbanBG,"tanban_BG",true)
end

function KoiBlissRespinStartView:setCoinsNum(coins)
    self:findChild("m_lb_coins"):setString(util_formatCoins(coins, 3))
    self:updateLabelSize({label = self:findChild("m_lb_coins"),sx = 0.85,sy = 0.85},216)
end

--[[
    显示界面
]]
function KoiBlissRespinStartView:showView(winCoin)
    -- self:delayCallBack(33/30,function ()
    --     self.tanbanBG:setVisible(true)
    --     util_spinePlay(self.tanbanBG,"tanban_BG",true)
    -- end)
    
    self:setCoinsNum(winCoin)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_rsStart_show)
    self.m_machine.respinDark:runCsbAction("start")
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self.m_machine.respinDark:runCsbAction("idle",true)
        self:runCsbAction("idle",true)
    end)
end

function KoiBlissRespinStartView:setEndFunc(endFunc)
    self.m_endFunc = endFunc
end

--[[
    关闭界面
]]
function KoiBlissRespinStartView:showOver()
    self.m_allowClick = false
    self.m_machine.respinDark:runCsbAction("over")
    self.m_machine.m_gcLighting:runCsbAction("over",false,function ()
        self.m_machine.m_gcLighting:setVisible(false)
    end)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_rsStart_hide)
    self:runCsbAction("over",false,function()
        self.m_machine.respinDark:setVisible(false)
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
    end)
end


--[[
    点击按钮
]]
function KoiBlissRespinStartView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    self:showOver()
    --点击音效
    if PublicConfig.SoundConfig.click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.click)
    end

end

--[[
    延迟回调
]]
function KoiBlissRespinStartView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return KoiBlissRespinStartView