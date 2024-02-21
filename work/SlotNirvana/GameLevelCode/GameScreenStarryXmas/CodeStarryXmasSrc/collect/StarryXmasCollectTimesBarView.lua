---
--xcyy
--2018年5月23日
--StarryXmasCollectTimesBarView.lua

local PublicConfig = require "StarryXmasPublicConfig"
local StarryXmasCollectTimesBarView = class("StarryXmasCollectTimesBarView",util_require("base.BaseView"))

function StarryXmasCollectTimesBarView:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("StarryXmas_jishu_base.csb")

    self:runCsbAction("idle",true) -- 播放时间线

    self:updateTimes("0")

    self.m_baoZhaNode = util_createAnimation("StarryXmas_jishu_base_0.csb")
    self:findChild("Node_1"):addChild(self.m_baoZhaNode) 
end


function StarryXmasCollectTimesBarView:onEnter()
 

end

function StarryXmasCollectTimesBarView:updateTimes(_leftTimes, _isChangeBet)

    for i=0,10 do
        self:findChild("shu_"..i):setVisible(false)
    end

    -- 切换bet的时候 不播放动效
    if _isChangeBet then
        self:findChild("shu_".._leftTimes):setVisible(true)
        self:runCsbAction("idle",true)
    else
        if tonumber(_leftTimes) == 10 then
            local randomNum = math.random(1, 2)
            local soundEffect = PublicConfig.Music_TenSpins_Trigger_Tbl[randomNum]
            gLobalSoundManager:playSound(soundEffect)
            self:runCsbAction("actionframe2",false,function()
                self:runCsbAction("idle",true)
            end)
            self.m_machine:waitWithDelay(30/60,function(  )
                self:findChild("shu_".._leftTimes):setVisible(true)
            end)
        elseif tonumber(_leftTimes) >= 8 then
            self.m_baoZhaNode:runCsbAction("actionframe",false,function()
                
            end)
            self.m_machine:waitWithDelay(3/60,function(  )
                self:findChild("shu_".._leftTimes):setVisible(true)
            end)
            
            self.m_machine:waitWithDelay(11/60,function(  )
                self:runCsbAction("idle",true)
            end)
        else
            self:findChild("shu_".._leftTimes):setVisible(true)
        end
    end
end

function StarryXmasCollectTimesBarView:onExit()
 
end

function StarryXmasCollectTimesBarView:setFadeIn( )
    self:runCsbAction("map_over")
end

function StarryXmasCollectTimesBarView:SetFadeOut( )
    self:runCsbAction("map_start",false,function (  )
        self:runCsbAction("idle", true)
    end)
end

--默认按钮监听回调
function StarryXmasCollectTimesBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return StarryXmasCollectTimesBarView