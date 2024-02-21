--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2020-04-29 14:04:06
]]
local DailybonusRewardX = class("DailybonusRewardX", util_require("base.BaseView"))

function DailybonusRewardX:initUI()
    local bonusCfg = G_GetMgr(G_REF.CashBonus):getBonusConfig()
    if not bonusCfg or not bonusCfg.commonCsb then
        return
    end

    self:createCsbNode(bonusCfg.commonCsb.DailybonusRewardX)
    local value = 1
    local mult_data = G_GetMgr(G_REF.CashBonus):getMultipleData()
    if mult_data and mult_data.p_value then
        value = mult_data.p_value
    end
    self:findChild("lb_mult"):setString("X" .. value)

    --显示倍数
end

function DailybonusRewardX:playIdleAction()
    self:runCsbAction("idle2", true)
end

--一套播放完
function DailybonusRewardX:playCollectAction(funcLightBack, endFunc)
    self:runCsbAction(
        "actionframe",
        false,
        function()
            if funcLightBack then
                funcLightBack() --播放闪电效果
            end
            self:runCsbAction(
                "actionframe2",
                false,
                function()
                    self:runCsbAction(
                        "over",
                        false,
                        function()
                            if endFunc then
                                endFunc()
                            end
                        end
                    )
                end
            )
        end
    )
end

--一套播放完
function DailybonusRewardX:playCollectAnim(funcLightBack)
    self:runCsbAction(
        "actionframe",
        false,
        function()
            if funcLightBack then
                funcLightBack() --播放闪电效果
            end
        end
    )
end
--一套播放完
function DailybonusRewardX:playLightOver(callback)
    -- self:runCsbAction("actionframe2", false, function(  )
    self:runCsbAction(
        "over",
        false,
        function()
            if callback then
                callback()
            end
        end
    )
    -- end)
end

function DailybonusRewardX:playOverAction()
    self:runCsbAction("over")
end

function DailybonusRewardX:getflyStartPos()
    local lbs = self:findChild("LabelReward")
    local cont = lbs:getContentSize()
    local endPos = lbs:getParent():convertToWorldSpace(cc.p(lbs:getPosition()))
    return endPos
end

return DailybonusRewardX
