---
--island
--2018年4月12日
--ChilliFiestaLogoView.lua
local ChilliFiestaLogoView = class("ChilliFiestaLogoView", util_require("base.BaseView"))
function ChilliFiestaLogoView:initUI(data)

    local resourceFilename = "ChilliFiesta_Logo.csb"
    self:createCsbNode(resourceFilename)
    if data then
        self:runCsbAction("show",false,function()
            self:runCsbAction("idle",true)
        end)
    else
        self:runCsbAction("idle",true)
    end

end

function ChilliFiestaLogoView:showView()
    self:setVisible(true)
end

function ChilliFiestaLogoView:hideView()
    self:setVisible(false)
end

function ChilliFiestaLogoView:onEnter()
end

function ChilliFiestaLogoView:onExit()

end



return ChilliFiestaLogoView
