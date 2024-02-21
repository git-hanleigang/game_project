--[[
    des:卡牌描述
    author:{author}
    time:2019-07-08 14:28:18
]]
local LongCardUnitCell = class(LongCardUnitCell, util_require("base.BaseView"))

-- 初始化UI --
function LongCardUnitCell:initUI()
    self:createCsbNode(CardResConfig.LongCardUnitCellRes)
end

function LongCardUnitCell:updateCell(pageIndex, cellData)

    self.normalNode = self:findChild("normal")
    self.linkNode = self:findChild("link")

    local sources = string.split(cellData.source, ";")
    local sourceId = tonumber(sources[pageIndex])

    if cellData.type == CardSysConfigs.CardType.link then
        self.normalNode:setVisible(false)
        self.linkNode:setVisible(true)

        -- 标题 --
        local title = self.linkNode:getChildByName("title")
        title:setString("Get a "..cellData.star.." Star Tornado by:")
        title:setScale(0.85)
        -- 描述 --
        local desNode = self.linkNode:getChildByName("des")
        desNode:setString(CardSysConfigs.DropFromDes201902[sourceId])

    else
        self.normalNode:setVisible(true)
        self.linkNode:setVisible(false)

        -- 标题 --
        local title = self.normalNode:getChildByName("title")
        if cellData.type == CardSysConfigs.CardType.golden then
            title:setString("Get a "..cellData.star.." Star Golden Card by:")
        else
            title:setString("Get a "..cellData.star.." Star Card by:")
        end


        -- 图片 --
        local iconName = CardSysConfigs.DropFromIconDes[sourceId]
        if iconName then
            local iconNode = self.normalNode:getChildByName("icon")
            util_changeTexture(iconNode, CardResConfig.CardUnitOtherResPath..iconName)
        end

        -- 描述 --
        local desNode = self.normalNode:getChildByName("des")
        desNode:setString(CardSysConfigs.DropFromDes201902[sourceId])
        -- 描述位置调整 --
        -- local parent = desNode:getParent()
        -- local pSize = parent:getContentSize()
        -- if iconName then
        --     desNode:setPositionY(pSize.height*0.7)
        -- else
        --     desNode:setPositionY(pSize.height*0.5)
        -- end
    end

end

-- 移动到中间位置的动作特效
function LongCardUnitCell:moveInCenter()

end

-- 移动出中间位置的动效
function LongCardUnitCell:moveOutCenter()

end



return LongCardUnitCell