---
--xcyy
--2018年5月23日
--BingoPriatesJackPotBarView.lua

local BingoPriatesJackPotBarView = class("BingoPriatesJackPotBarView",util_require("base.BaseView"))

local GrandName = "grand_shuzi"
local MajorName = "major_shuzi"
local MiniName = "minor_shuzi" 

BingoPriatesJackPotBarView.m_GrandOldCoins = 0
BingoPriatesJackPotBarView.m_MajorOldCoins = 0
BingoPriatesJackPotBarView.m_MiniOldCoins = 0

function BingoPriatesJackPotBarView:initUI()

    self:createCsbNode("BingoPriates_jackpot.csb")

    self:runCsbAction("idle1")
    
    self.m_GrandOldCoins = 0
    self.m_MajorOldCoins = 0
    self.m_MiniOldCoins = 0

    self.m_BetLock = util_createAnimation("BingoPriates_jackpot_suo.csb")
    self:findChild("betLock"):addChild(self.m_BetLock)
    self.m_BetLock:setVisible(false)

    
    self:addClick(self:findChild("betLockClick"))

end

function BingoPriatesJackPotBarView:onExit()
 
end

function BingoPriatesJackPotBarView:initMachine(machine)
    self.m_machine = machine

    self:updateJackpotInfo()
end

function BingoPriatesJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

-- 更新jackpot 数值信息
--
function BingoPriatesJackPotBarView:updateJackpotInfo(jackpotData,Change)
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    if jackpotData == nil or jackpotData == {} then
        jackpotData = { Grand = 0, Major = 0, Minor = 0}
    end

    
   
   

    for k,v in pairs(jackpotData) do

        if k == "Grand" then
            self.m_GrandOldCoins = v
            if not Change then
                self:changeNode(self:findChild(GrandName),v)
            end
            
        elseif k == "Major" then
            self.m_MajorOldCoins = v
            if not Change then
                self:changeNode(self:findChild(MajorName),v)
            end
            
        elseif k == "Minor" then
            self.m_MiniOldCoins = v

            if not Change then
                self:changeNode(self:findChild(MiniName),v)
            end
            
        end

    end
    
    
    

    self:updateSize()
end

function BingoPriatesJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,226)
    self:updateLabelSize(info2,154)
    self:updateLabelSize(info4,134)
end

function BingoPriatesJackPotBarView:changeNode(label,value)
    label:setString(util_formatCoins(value,20))
end

function BingoPriatesJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

--默认按钮监听回调
function BingoPriatesJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "betLockClick" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
    end

end

return BingoPriatesJackPotBarView