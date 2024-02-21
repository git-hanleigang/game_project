--[[
    卡片收集规则界面  一些玩法说明 --
]]
local BaseCardMenuRule = util_require("GameModule.Card.baseViews.BaseCardMenuRule")
local CardMenuRule = class("CardMenuRule", BaseCardMenuRule)

function CardMenuRule:initDatas()
    CardMenuRule.super.initDatas(self)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardRuleRes, "season201903"))
end

-- function CardMenuRule:getLeftAdaptList()
--     return {self:findChild("Button_6"), self:findChild("layer_left")}
-- end

-- function CardMenuRule:getRightAdaptList()
--     return {self:findChild("Button_4"), self:findChild("Button_7"), self:findChild("layer_right")}
-- end

function CardMenuRule:initAdapt()
    -- local offsetX = 0
    -- local ratio = display.width / display.height
    -- if ratio <= 1.34 then -- 1024x768
    --     offsetX = 0
    -- elseif ratio <= 1.5 then -- 960x640
    --     offsetX = 25
    -- elseif ratio <= 1.79 then -- 1370x768
    --     offsetX = 45
    -- elseif ratio <= 2 then -- 1280x640
    --     offsetX = 120
    -- else -- 2340x1080 -- 1170x540
    --     offsetX = 190
    -- end

    -- local lefts = self:getLeftAdaptList()
    -- if lefts and #lefts > 0 then
    --     for i = 1, #lefts do
    --         local oriX = lefts[i]:getPositionX()
    --         lefts[i]:setPositionX(oriX + offsetX)
    --     end
    -- end

    -- local rights = self:getRightAdaptList()
    -- if rights and #rights > 0 then
    --     for i = 1, #rights do
    --         local oriX = rights[i]:getPositionX()
    --         rights[i]:setPositionX(oriX - offsetX)
    --     end
    -- end
end

-- 点击事件 --
function CardMenuRule:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_4" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:clickBackBtn()
    elseif name == "Button_6" or name == "layer_left" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:showNextRule(-1)
    elseif name == "Button_7" or name == "layer_right" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:showNextRule(1)
    end
end

return CardMenuRule
