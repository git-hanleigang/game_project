---
--smy
--2018年4月12日
--ChinoiserieLight.lua

local PharaohLight = class("PharaohLight",util_require("base.BaseView"))

function PharaohLight:initUI(data)
    local resourceFilename="Socre_Pharaoh_Shandian.csb"
    self:createCsbNode(resourceFilename)
    self:setVisible(false)
end

function PharaohLight:triggerLight(startPos,endPos)
	self:setVisible(true)
	local lightPos=cc.p(startPos.x+(endPos.x-startPos.x)/2,startPos.y+(endPos.y-startPos.y)/2)
	local anglepos=cc.pSub(endPos,startPos)
	local angle=math.atan2(anglepos.y, anglepos.x)
	angle=angle*180/math.pi
	local scale=cc.pGetDistance(startPos,endPos)/350
	-- scale=math.max(scale,0.67)
	self.m_csbNode:setRotation(-angle)
	self.m_csbNode:setPosition(lightPos)
	self.m_csbNode:setScale(scale)
	self:runCsbAction("actionframe")
end

return PharaohLight