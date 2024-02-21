---
--island
--2018年4月12日
--JackpotBar.lua
--
-- jackpot top bar

local JackpotBar = class("JackpotBar",util_require("base.BaseView"))
JackpotBar.m_tipIndex = nil
function JackpotBar:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Socre_Pharaoh_Special_Top.csb"
    self:createCsbNode(resourceFilename)
end

function JackpotBar:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
function JackpotBar:changeNormal()
    self:runCsbAction("normal")
end

function JackpotBar:changeFreeSpin()
    self:runCsbAction("freespin")
end
---
-- 更新jackpot 数值信息
--
function JackpotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self.m_csbOwner["m_lb_grand"],1,true)
    self:changeNode(self.m_csbOwner["m_lb_major"],2,true)
    self:changeNode(self.m_csbOwner["m_lb_minor"],3)
    self:changeNode(self.m_csbOwner["m_lb_mini"],4)
    self:updateSize()
end

function JackpotBar:updateSize()
    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local info1={label=label1,sx=0.543,sy=0.69}
    local info2={label=label2,sx=0.8,sy=0.8}
    self:updateLabelSize(info1,403,{info2})

    -- self:updateLabelSize(info2,265)

    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    local info3={label=label3,sx=0.7,sy=0.7}
    local info4={label=label4,sx=0.7,sy=0.7}
    self:updateLabelSize(info3,292,{info4})
end

--jackpot算法
function JackpotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))

end
return JackpotBar