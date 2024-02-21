-- 集卡排行榜 条目

local CardRankConfig = require("views.Card.CardRank202302.CardRankConfig")

-----------------------------------------------------------------
local PointsItem = class("PointsItem", BaseView)

function PointsItem:getCsbName()
    return CardRankConfig.RankHelpCellPoints
end

function PointsItem:initUI(points)
    if points and tonumber(points) > 0 then
        self.points = points
    end

    PointsItem.super.initUI(self)

    self.lb_jifen = self:findChild("lb_jifen")
    self.lb_jifen:setString(self.points)
end
-----------------------------------------------------------------

-----------------------------------------------------------------
local CardRankHelpItemUI = class("CardRankHelpItemUI", BaseView)

function CardRankHelpItemUI:initUI(index)
    assert(index, "CardRankHelpItemUI page id 不能为空")

    local csb_path
    if index == 1 then
        csb_path = CardRankConfig.RankHelpCell1
    elseif index == 2 then
        csb_path = CardRankConfig.RankHelpCell2
    end

    if csb_path then
        self:createCsbNode(csb_path)
    end

    if index == 2 then
        self:showPoints()
    end
end

function CardRankHelpItemUI:hideParticle()
    local p1 = self:findChild("Particle_1")
    if p1 then
        p1:setVisible(false)
    end
    local p2 = self:findChild("Particle_2")
    if p2 then
        p2:setVisible(false)
    end
    local p3 = self:findChild("Particle_3")
    if p3 then
        p3:setVisible(false)
    end
end

function CardRankHelpItemUI:showPoints()
    local points = {
        chip = 1,
        goldchip = 10,
        greenwild = 50,
        nadowild = 200,
        goldenwild = 500,
        commonwild = 1000
    }
    self.node_point_goldchip = self:findChild("node_point_goldchip")
    if not tolua.isnull(self.node_point_goldchip) then
        local point_goldchip = PointsItem:create()
        if point_goldchip then
            point_goldchip:initUI(points.goldchip)
            point_goldchip:addTo(self.node_point_goldchip)
        end
    end
    self.node_point_chip = self:findChild("node_point_chip")
    if not tolua.isnull(self.node_point_chip) then
        local point_chip = PointsItem:create()
        if point_chip then
            point_chip:initUI(points.chip)
            point_chip:addTo(self.node_point_chip)
        end
    end
    self.node_point_greenwild = self:findChild("node_point_greenwild")
    if not tolua.isnull(self.node_point_greenwild) then
        local point_greenwild = PointsItem:create()
        if point_greenwild then
            point_greenwild:initUI(points.greenwild)
            point_greenwild:addTo(self.node_point_greenwild)
        end
    end
    self.node_point_yellowwild = self:findChild("node_point_yellowwild") -- golden
    if not tolua.isnull(self.node_point_yellowwild) then
        local point_yellowwild = PointsItem:create()
        if point_yellowwild then
            point_yellowwild:initUI(points.goldenwild)
            point_yellowwild:addTo(self.node_point_yellowwild)
        end
    end
    self.node_point_bluewild = self:findChild("node_point_bluewild") -- nado
    if not tolua.isnull(self.node_point_bluewild) then
        local point_bluewild = PointsItem:create()
        if point_bluewild then
            point_bluewild:initUI(points.nadowild)
            point_bluewild:addTo(self.node_point_bluewild)
        end
    end
    self.node_point_fullwild = self:findChild("node_point_fullwild") -- common
    if not tolua.isnull(self.node_point_fullwild) then
        local point_fullwild = PointsItem:create()
        if point_fullwild then
            point_fullwild:initUI(points.commonwild)
            point_fullwild:addTo(self.node_point_fullwild)
        end
    end
end

-----------------------------------------------------------------

return CardRankHelpItemUI
