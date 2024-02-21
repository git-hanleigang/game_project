---
--xcyy
--2018年5月29日
--LightCherryJackPotBar.lua

local LightCherryJackPotBar = class("LightCherryJackPotBar", util_require("base.BaseView"))
LightCherryJackPotBar.m_cherryLogo = nil

function LightCherryJackPotBar:initUI(data)
    self.m_fsCount = 0
    self:createCsbNode("LightCherry_jackpot_bar.csb")
end

function LightCherryJackPotBar:initMachine(machine)
    self.m_machine=machine
end

function LightCherryJackPotBar:onEnter()
    -- body
    self:updateFreespinCount("")

    self:runCsbAction("idleframe", true)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    self.m_cherryLogo = util_createAnimation("LightCherry_logo.csb")
    self:findChild("ef_logo"):addChild(self.m_cherryLogo, 100000)
    self.m_cherryLogo:runCsbAction("idleframe")
    -- util_setCascadeOpacityEnabledRescursion(self.m_cherryLogo, true)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

--[[
    设置free剩余次数
]]
function LightCherryJackPotBar:setFreeSpinCount(fsCount)
    self.m_fsCount = fsCount
end

function LightCherryJackPotBar:changeFreeSpinByCount(fsCount)
    local leftFsCount = globalData.slotRunData.freeSpinCount

    self:updateFreespinCount(leftFsCount)

    local newCount = self.m_machine.m_runSpinResultData.p_freeSpinNewCount
    if leftFsCount > self.m_fsCount then
        self:runCsbAction("freespin")
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LightCherry_freenum_shanshuo)
    end
    self.m_fsCount = leftFsCount

end

function LightCherryJackPotBar:updateFreespinCount(leftCount)
    self.m_csbOwner["m_lb_fs_count"]:setString(leftCount.."")
end


---
-- 更新jackpot 数值信息
--
function LightCherryJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self.m_csbOwner["m_lb_grand_money"],1,true)
    self:changeNode(self.m_csbOwner["m_lb_major_money"],2,true)
    self:changeNode(self.m_csbOwner["m_lb_minor_money"],3)
    self:changeNode(self.m_csbOwner["m_lb_mini_money"],4)

    self:updateSize()
end

function LightCherryJackPotBar:updateSize()
    local label1 = self.m_csbOwner["m_lb_grand_money"]
    local label2 = self.m_csbOwner["m_lb_major_money"]
    local label3 = self.m_csbOwner["m_lb_minor_money"]
    local label4 = self.m_csbOwner["m_lb_mini_money"]

    self:updateLabelSize({label = label1, sx = 1, sy = 1}, 270)
    self:updateLabelSize({label = label2, sx = 1, sy = 1}, 279)
    self:updateLabelSize({label = label3, sx = 0.765, sy = 0.765}, 300)
    self:updateLabelSize({label = label4, sx = 0.765, sy = 0.765}, 300)
    
end

--jackpot算法
function LightCherryJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function LightCherryJackPotBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LightCherryJackPotBar:toAction(actionName)
    if actionName == "freespin_show" then
        self:runCsbAction("freespin_show")
        self.m_cherryLogo:setVisible(false)
    elseif actionName == "freespin_hide" then
        self:runCsbAction("freespin_hide", false, function()
            self:runCsbAction("idleframe", true)
        end)
        self.m_cherryLogo:setVisible(true)
    end

    self:runCsbAction(actionName)
end

return LightCherryJackPotBar