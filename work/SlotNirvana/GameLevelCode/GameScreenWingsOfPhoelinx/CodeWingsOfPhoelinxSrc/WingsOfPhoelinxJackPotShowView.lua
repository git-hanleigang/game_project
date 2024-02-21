---
--island
--2018年4月12日
--WingsOfPhoelinxJackPotShowView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local WingsOfPhoelinxJackPotShowView = class("WingsOfPhoelinxJackPotShowView", util_require("Levels.BaseLevelDialog"))
local WingsOfPhoekinxConfig   = require "WingsOfPhoekinxConfig"

local GrandName = "m_lb_coins_GRAND"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

function WingsOfPhoelinxJackPotShowView:ctor()
    WingsOfPhoelinxJackPotShowView.super.ctor(self)
    globalMachineController.WingsOfPhoekinxConfig   = WingsOfPhoekinxConfig
end

function WingsOfPhoelinxJackPotShowView:initUI()

    local resourceFilename = "WingsOfPhoelinx_jackpotxianshi.csb"
    self:createCsbNode(resourceFilename)

    self.grandNum = 0
    self.majorNum = 0
    self.minorNum = 0
    self.miniNum = 0

    self.smallIconsList = {}

    self:initSmallIcons()
    self:initJackpotZj()
    
end

function WingsOfPhoelinxJackPotShowView:setGoldShow(node,index)
    for i=1,4 do
        if i == index then
            node:findChild("WingsOfPhoelinx_xiaoicon_"..i):setVisible(true)
        else
            node:findChild("WingsOfPhoelinx_xiaoicon_"..i):setVisible(false)
        end
    end
end

function WingsOfPhoelinxJackPotShowView:initSmallIcons( )
    --创建对应的小icons，添加到jackpot中
    for i=1,3 do
        self["xiaoicon_grand_"..i] = util_createAnimation("WingsOfPhoelinx_jackpot_littlecoins.csb")
        self:setGoldShow(self["xiaoicon_grand_"..i],1)
        self:findChild("Node_xiaoicon_grand_"..i):addChild(self["xiaoicon_grand_"..i])
        self["xiaoicon_grand_"..i]:setVisible(false)
        table.insert(self.smallIconsList,self["xiaoicon_grand_"..i])
    end
    for i=1,3 do
        self["xiaoicon_major_"..i] = util_createAnimation("WingsOfPhoelinx_jackpot_littlecoins.csb")
        self:setGoldShow(self["xiaoicon_major_"..i],2)
        self:findChild("Node_xiaoicon_major_"..i):addChild(self["xiaoicon_major_"..i])
        self["xiaoicon_major_"..i]:setVisible(false)
        table.insert(self.smallIconsList,self["xiaoicon_major_"..i])
    end
    for i=1,3 do
        self["xiaoicon_minor_"..i] = util_createAnimation("WingsOfPhoelinx_jackpot_littlecoins.csb")
        self:setGoldShow(self["xiaoicon_minor_"..i],3)
        self:findChild("Node_xiaoicon_minor_"..i):addChild(self["xiaoicon_minor_"..i])
        self["xiaoicon_minor_"..i]:setVisible(false)
        table.insert(self.smallIconsList,self["xiaoicon_minor_"..i])
    end
    for i=1,3 do
        self["xiaoicon_mini_"..i] = util_createAnimation("WingsOfPhoelinx_jackpot_littlecoins.csb")
        self:setGoldShow(self["xiaoicon_mini_"..i],4)
        self:findChild("Node_xiaoicon_mini_"..i):addChild(self["xiaoicon_mini_"..i])
        self["xiaoicon_mini_"..i]:setVisible(false)
        table.insert(self.smallIconsList,self["xiaoicon_mini_"..i])
    end
end

function WingsOfPhoelinxJackPotShowView:initJackpotZj( )
    for i=1,4 do
        self["Node_zj_"..i] = util_createAnimation("WingsOfPhoelinx_jackpot_zj.csb")
        self:findChild("Node_zj_" .. i):addChild(self["Node_zj_"..i])
        self["Node_zj_"..i]:setVisible(false)
    end
end

function WingsOfPhoelinxJackPotShowView:resetShowAct( )
    for i,v in ipairs(self.smallIconsList) do
        v.isShow = false
        v:setVisible(false)
    end
    for i=1,4 do
        self["Node_zj_"..i]:setVisible(false)
    end
    self.grandNum = 0
    self.majorNum = 0
    self.minorNum = 0
    self.miniNum = 0
end

function WingsOfPhoelinxJackPotShowView:initMachine(machine)
    self.m_machine = machine
end

function WingsOfPhoelinxJackPotShowView:onEnter()

    WingsOfPhoelinxJackPotShowView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)

    local p_wingsOfPhoekinxConfig = globalMachineController.WingsOfPhoekinxConfig

    gLobalNoticManager:addObserver(self,
        function(self,params)  
            --刷新ui显示(参数为显示的类型)
            self:updatejackpotIconNum(params)
        end,
        p_wingsOfPhoekinxConfig.EventName.JACKPOT_NUM_UPDATA)
end

function WingsOfPhoelinxJackPotShowView:onExit()

    WingsOfPhoelinxJackPotShowView.super.onExit(self)
    globalMachineController.WingsOfPhoekinxConfig   = nil
    
end

-- 更新jackpot 数值信息
--
function WingsOfPhoelinxJackPotShowView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function WingsOfPhoelinxJackPotShowView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.26,sy=0.26}
    local info2={label=label2,sx=0.26,sy=0.26}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.26,sy=0.26}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.26,sy=0.26}
    self:updateLabelSize(info1,593)
    self:updateLabelSize(info2,593 )
    self:updateLabelSize(info3,593)
    self:updateLabelSize(info4,593)
end

function WingsOfPhoelinxJackPotShowView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--展示对应jackpot的小金币显示
function WingsOfPhoelinxJackPotShowView:showEffectForIndex(num,type,isShowIcon)
    if num == 1 then
        if self["xiaoicon_"..type.."_"..1].isShow then
            
        else
            self["xiaoicon_"..type.."_"..1]:setVisible(true)
            self["xiaoicon_"..type.."_"..1].isShow = true
            self["xiaoicon_"..type.."_"..1]:runCsbAction("actionframe",false,function (  )
                self["xiaoicon_"..type.."_"..1]:runCsbAction("idleframe")
            end)
        end
        
    elseif num == 2 then
        if self["xiaoicon_"..type.."_"..2].isShow then
            
        else
            self["xiaoicon_"..type.."_"..2]:setVisible(true)
            self["xiaoicon_"..type.."_"..2].isShow = true
            self["xiaoicon_"..type.."_"..2]:runCsbAction("actionframe",false,function (  )
                self["xiaoicon_"..type.."_"..2]:runCsbAction("idleframe")
            end)
        end
        if isShowIcon then
            self["xiaoicon_"..type.."_"..3]:setVisible(false)
        else
            self["xiaoicon_"..type.."_"..3]:setVisible(true)
            self["xiaoicon_"..type.."_"..3]:runCsbAction("actionframe1",true)
        end
        
        
    elseif num == 3 then
        if self["xiaoicon_"..type.."_"..3].isShow then
            
        else
            self["xiaoicon_"..type.."_"..3]:setVisible(true)
            self["xiaoicon_"..type.."_"..3].isShow = true
            self["xiaoicon_"..type.."_"..3]:runCsbAction("actionframe",false,function (  )
                self["xiaoicon_"..type.."_"..3]:runCsbAction("idleframe")
            end)
        end
        local index = self:getNodeZiIndex(type)
        self["Node_zj_"..index]:setVisible(true)
        self["Node_zj_"..index]:runCsbAction("actionframe",true)
    end
end

function WingsOfPhoelinxJackPotShowView:getNodeZiIndex(type)
    if type == "mini" then
        return 4
    elseif type == "minor" then
        return 3
    elseif type == "major" then
        return 2
    elseif type == "grand" then
        return 1
    end
end

function WingsOfPhoelinxJackPotShowView:updatejackpotIconNum(params)
    local type = params.showType
    local isShowIcon = false
    if type == 1 then
        self.grandNum = self.grandNum + 1
    elseif type == 2 then
        self.majorNum = self.majorNum + 1
    elseif type == 4 then
        self.minorNum = self.minorNum + 1
    elseif type == 3 then
        self.miniNum = self.miniNum + 1
    elseif type == 5 then
        self.grandNum = self.grandNum + 1
        self.majorNum = self.majorNum + 1
        self.minorNum = self.minorNum + 1
        self.miniNum = self.miniNum + 1
    end
    if self.grandNum == 3 or self.majorNum == 3 or self.minorNum == 3 or self.miniNum == 3 then
        isShowIcon = true
    end
    for i=1,4 do
        if i == 1 then
            self:showEffectForIndex(self.miniNum,"mini",isShowIcon)
        elseif i == 2 then
            self:showEffectForIndex(self.minorNum,"minor",isShowIcon)
        elseif i == 3 then
            self:showEffectForIndex(self.majorNum,"major",isShowIcon)
        elseif i == 4 then
            self:showEffectForIndex(self.grandNum,"grand",isShowIcon)
        end
    end
end

return WingsOfPhoelinxJackPotShowView

