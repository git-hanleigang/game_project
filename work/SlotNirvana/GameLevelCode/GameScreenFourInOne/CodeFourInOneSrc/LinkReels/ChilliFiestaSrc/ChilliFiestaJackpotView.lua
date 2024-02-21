--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-01 16:43:57
]]
--jacpot显示界面
--ChilliFiestaJackpotView.lua

local ChilliFiestaJackpotView = class("ChilliFiestaJackpotView",util_require("base.BaseView"))

function ChilliFiestaJackpotView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("LinkReels/ChilliFiestaLink/4in1_ChilliFiesta_Jackpot.csb")

    self:runCsbAction("show",false,function()
        self:runCsbAction("idle",true)
    end)
end

function ChilliFiestaJackpotView:changeCsbAni(_str)
    self:runCsbAction(_str,true)
end

function ChilliFiestaJackpotView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("ml_b_coins4"),4,true,15)
    self:changeNode(self:findChild("ml_b_coins3"),3,true,15)
    self:changeNode(self:findChild("ml_b_coins2"),2,true,15)
    self:changeNode(self:findChild("ml_b_coins1"),1,true,15)

    self:updateLabelSize({label=self:findChild("ml_b_coins1"),sx=1,sy=1},292)
    self:updateLabelSize({label=self:findChild("ml_b_coins2"),sx=1,sy=1},253)
    self:updateLabelSize({label=self:findChild("ml_b_coins3"),sx=0.9,sy=0.9},203)
    self:updateLabelSize({label=self:findChild("ml_b_coins4"),sx=0.9,sy=0.9},203)


    self:changeNode(self:findChild("ml_b_coins42"),4,true,15)
    self:changeNode(self:findChild("ml_b_coins32"),3,true,15)
    self:changeNode(self:findChild("ml_b_coins22"),2,true,15)
    self:updateLabelSize({label=self:findChild("ml_b_coins22"),sx=1,sy=1},253)
    self:updateLabelSize({label=self:findChild("ml_b_coins32"),sx=0.9,sy=0.9},253)
    self:updateLabelSize({label=self:findChild("ml_b_coins42"),sx=0.9,sy=0.9},253)
end
--jackpot算法
function ChilliFiestaJackpotView:changeNode(label,index,isJump,count)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,count))
end

function ChilliFiestaJackpotView:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end


function ChilliFiestaJackpotView:onExit()

end

--默认按钮监听回调
function ChilliFiestaJackpotView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ChilliFiestaJackpotView