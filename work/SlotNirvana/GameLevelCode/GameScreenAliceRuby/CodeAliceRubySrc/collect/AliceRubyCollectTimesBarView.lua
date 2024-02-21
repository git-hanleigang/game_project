---
--xcyy
--2018年5月23日
--AliceRubyCollectTimesBarView.lua

local AliceRubyCollectTimesBarView = class("AliceRubyCollectTimesBarView",util_require("base.BaseView"))


function AliceRubyCollectTimesBarView:initUI()

    self:createCsbNode("AliceRuby_jishu_base.csb")

    self:runCsbAction("idle") -- 播放时间线

    self:updateTimes("0","10")
end


function AliceRubyCollectTimesBarView:onEnter()
 

end

function AliceRubyCollectTimesBarView:updateTimes(leftTimes,totalTimes)
    self.m_csbOwner["Alice_cishu_left"]:setString(leftTimes)
    self.m_csbOwner["Alcie_cishu_total"]:setString(totalTimes)
    -- self:runCsbAction("actionframe")
end

function AliceRubyCollectTimesBarView:onExit()
 
end

function AliceRubyCollectTimesBarView:setFadeIn( )
    self:runCsbAction("over")
end

function AliceRubyCollectTimesBarView:SetFadeOut( )
    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle")
    end)
end

--默认按钮监听回调
function AliceRubyCollectTimesBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceRubyCollectTimesBarView