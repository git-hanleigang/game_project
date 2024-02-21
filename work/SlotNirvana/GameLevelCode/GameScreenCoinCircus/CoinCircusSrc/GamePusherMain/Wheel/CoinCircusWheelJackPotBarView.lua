---
--xcyy
--2018年5月23日
--CoinCircusJackPotBarView.lua
local Config                   = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local CoinCircusJackPotBarView = class("CoinCircusJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 


function CoinCircusJackPotBarView:initUI()

    self:createCsbNode("CoinCircus_jackpot_kuang.csb")


end

function CoinCircusJackPotBarView:onEnter()
 
    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新圆盘jackpot

            self:updateJackpotInfo(params.nIndex,params.nValue)

        end, Config.Event.GamePusherMainUI_Update_WheelJpBar
    )

end

function CoinCircusJackPotBarView:onExit()
 
    gLobalNoticManager:removeAllObservers(self)

   
    
end



-- 更新jackpot 数值信息
--
function CoinCircusJackPotBarView:updateJackpotInfo(_index,_value)

    if _index == 1 then
        self:changeNode(self:findChild(GrandName),_value)
    elseif _index == 2 then
        self:changeNode(self:findChild(MajorName),_value)
    elseif _index == 3 then
        self:changeNode(self:findChild(MinorName),_value)
    elseif _index == 4 then
        self:changeNode(self:findChild(MiniName),_value)
    end
    
    self:updateSize()
end

function CoinCircusJackPotBarView:updateSize()

    local label1 = self.m_csbOwner[GrandName]
    local info1 = {label = label1, sx = 1, sy = 1}

    local label2 = self.m_csbOwner[MajorName]
    local info2 = {label = label2, sx = 1, sy = 1}
    
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 1, sy = 1}

    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 1, sy = 1}


    self:updateLabelSize(info1,324)
    self:updateLabelSize(info2,300)
    self:updateLabelSize(info3,252)
    self:updateLabelSize(info4,225)
end

function CoinCircusJackPotBarView:changeNode(_label,_value)
    
    local value = _value
    _label:setString(util_formatCoins(value,20,nil,nil,true))

end




return CoinCircusJackPotBarView