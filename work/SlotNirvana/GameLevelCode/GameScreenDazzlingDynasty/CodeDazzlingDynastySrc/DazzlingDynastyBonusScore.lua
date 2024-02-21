--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-08-01 17:23:14
]]

local CodeGameScreenDazzlingDynastyMachine = util_require("GameScreenDazzlingDynasty.CodeGameScreenDazzlingDynastyMachine")
local DazzlingDynastyBonusScore = class("DazzlingDynastyBonusScore",util_require("base.BaseView"))

function DazzlingDynastyBonusScore:initUI()
    self:createCsbNode("bonus_fly.csb")
    self.lbRedScore = self:findChild("m_lb_score_red")
    self.lbGreenScore = self:findChild("m_lb_score_green")
    self.lbYellowScore = self:findChild("m_lb_score_yellow")
    self:__setScoreLabelVisible(false)
end

function DazzlingDynastyBonusScore:setMachineInfo(machine)
    self.machine = machine
end

--symbolType:nil:不显示
function DazzlingDynastyBonusScore:playAnimation(symbolType,score,destPos,callBack,endCallBack)
    symbolType = self.machine:formatAddSpinSymbol(symbolType)
    self.lbRedScore:setVisible(symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1)
    self.lbGreenScore:setVisible(symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2)
    self.lbYellowScore:setVisible(symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3)
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 then
        self.lbRedScore:setString(score)
    end
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 then
        self.lbGreenScore:setString(score)
    end
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 then
        self.lbYellowScore:setString(score)
    end
    self:runCsbAction("animation0",false,function()
        if endCallBack ~= nil then
            endCallBack()
        end
        self:removeFromParent()
    end)
    local function animCallBack(sender)
        self:__setScoreLabelVisible(false)
        if callBack ~= nil then
            callBack()
        end
    end
    self:runAction(cc.Sequence:create(
        cc.MoveTo:create(0.3,destPos),
        cc.CallFunc:create(animCallBack)))
end

function DazzlingDynastyBonusScore:playSmallAnimation(symbolType,score,destPos,callBack,endCallBack)
    symbolType = self.machine:formatAddSpinSymbol(symbolType)
    self.lbRedScore:setVisible(symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1)
    self.lbGreenScore:setVisible(symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2)
    self.lbYellowScore:setVisible(symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3)
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 then
        self.lbRedScore:setString(score)
    end
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 then
        self.lbGreenScore:setString(score)
    end
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 then
        self.lbYellowScore:setString(score)
    end
    self:runCsbAction("animation0",false,function()
        if endCallBack ~= nil then
            endCallBack()
        end
        self:removeFromParent()
    end)
    local function animCallBack(sender)
        self:__setScoreLabelVisible(false)
        if callBack ~= nil then
            callBack()
        end
    end
    self:runAction(cc.Spawn:create(
                    cc.Sequence:create(cc.MoveTo:create(0.3,destPos),
                                        cc.CallFunc:create(animCallBack)),
                    cc.ScaleTo:create(0.3,0.5)))
end

function DazzlingDynastyBonusScore:__setScoreLabelVisible(flag)
    self.lbRedScore:setVisible(flag)
    self.lbGreenScore:setVisible(flag)
    self.lbYellowScore:setVisible(flag)
end

return DazzlingDynastyBonusScore