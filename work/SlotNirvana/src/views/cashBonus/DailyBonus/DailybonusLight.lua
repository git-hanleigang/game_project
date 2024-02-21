--[[
   翻倍闪电
]]
local DailybonusLight = class("DailybonusLight", util_require("base.BaseView"))

function DailybonusLight:initUI()
    self:createCsbNode("CashCommon/csd/DailyBonusAddEf/wheelRewardLight_lizi.csb")
    self.move_particle = self:findChild("Particle_1")
end

function DailybonusLight:getAngleByPos(p1, p2)
    local p = {}
    p.x = p2.x - p1.x
    p.y = p2.y - p1.y

    local r = math.atan2(p.y, p.x) * 180 / math.pi
    return r
end

function DailybonusLight:setLightInfo(startPos, endPos)
    -- local midPos = ccpMidpoint(startPos, endPos)
    self:setPosition(cc.p(startPos))
    -- local angle = self:getAngleByPos(startPos, endPos)
    -- self:setRotation(angle)
    -- self:runCsbAction("shouji", true)
    self.startPos = startPos
    self.endPos = endPos
    self.move_particle:setPositionType(0)
    self.move_particle:stopSystem()

    -- cashbonus 改版 工程里修改缩放
    -- local width = self:findChild("Sprite_2"):getContentSize().width
    -- local dis = ccpDistance(startPos, endPos)
    -- local scale = 0.8 --dis / width
    -- self:setScale(scale)
end

-- function DailybonusLight:playLightDirectAction(endFunc)
--     endFunc()
--     self:runCsbAction(
--         "shouji",
--         false,
--         function()
--             if not tolua.isnull(self) then
--                 self:removeFromParent()
--             end
--         end
--     )
-- end

function DailybonusLight:playLightAction(endFunc)
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusVipMulitipLight.mp3")

    self.move_particle:resetSystem()
    -- self.move_particle:setDuration(1)
    self:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.5, self.endPos),
            cc.CallFunc:create(
                function()
                    if endFunc then
                        endFunc()
                    end
                end
            ),
            cc.RemoveSelf:create()
        )
    )
end

return DailybonusLight
