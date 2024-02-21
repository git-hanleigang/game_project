---
--xhkj
--2018年6月11日
--FortuneTreeJackpotBar.lua

local FortuneTreeJackpotBar = class("FortuneTreeJackpotBar", util_require("base.BaseView"))

function FortuneTreeJackpotBar:initUI(data)
    local resourceFilename = "FortuneTree_JackPot_small1.csb"
    if data == "freespin" then
        resourceFilename = "FortuneTree_Top.csb"
    end
    self.m_barType = data
    self:createCsbNode(resourceFilename)
    
end

function FortuneTreeJackpotBar:changeBarDisplay()
    local index = 1
    self:runCsbAction("idle"..index)
    self.m_changeBarAction = schedule(self,function()
        self:runCsbAction("change"..index, false, function()
            index = index + 1
            if index > 4 then
                index = 1
            end
            self:runCsbAction("idle"..index)
        end)
    end, 4)
end

function FortuneTreeJackpotBar:resetBarDisplay()
    if self.m_changeBarAction ~= nil then
        self:stopAction(self.m_changeBarAction)
    end
    self:runCsbAction("idle1")
end

function FortuneTreeJackpotBar:initMachine(machine)
    self.m_machine = machine
end

function FortuneTreeJackpotBar:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function FortuneTreeJackpotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand"),1,true)
    self:changeNode(self:findChild("m_lb_major"),2,true)
    self:changeNode(self:findChild("m_lb_minor"),3)
    self:changeNode(self:findChild("m_lb_mini"),4)
    self:updateSize()
end

function FortuneTreeJackpotBar:updateSize()

    local label1 = self.m_csbOwner["m_lb_grand"]
    local label2 = self.m_csbOwner["m_lb_major"]
    local label3 = self.m_csbOwner["m_lb_minor"]
    local label4 = self.m_csbOwner["m_lb_mini"]

    if self.m_barType == "freespin" then
        local info1 = {label = label1}
        local info2 = {label = label2}
        local info3 = {label = label3}
        local info4 = {label = label4}  
        self:updateLabelSize(info1, 380, {info2})
        self:updateLabelSize(info3, 380, {info4})
    else
        self:updateLabelSize({label = label1}, 380)
        self:updateLabelSize({label = label2, sx = 0.9, sy = 0.9}, 380)
        self:updateLabelSize({label = label3, sx = 0.5, sy = 0.5}, 380)
        self:updateLabelSize({label = label4, sx = 0.5, sy = 0.5}, 380)
    end
    
end

function FortuneTreeJackpotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 30))
end

function FortuneTreeJackpotBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return FortuneTreeJackpotBar