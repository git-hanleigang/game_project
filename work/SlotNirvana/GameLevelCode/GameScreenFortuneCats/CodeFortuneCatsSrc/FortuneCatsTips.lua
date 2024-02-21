
--FortuneCatsTips.lua

local FortuneCatsTips = class("FortuneCatsTips", util_require("base.BaseView"))

function FortuneCatsTips:initUI(_type)
    self:createCsbNode("FortuneCats_I_rim.csb")
    self.m_type = _type
    if _type == 1 then
        self:runCsbAction("show")
    else
        self:runCsbAction("show2")
    end
    self:addClick(self:findChild("Image_1"))
end

function FortuneCatsTips:setMachine(machine)
    self.m_Machine = machine
end

function FortuneCatsTips:onEnter()
end

function FortuneCatsTips:playOver(func)
    if self.m_type == 1 then
        self:runCsbAction(
            "hide",
            false,
            function()
                if func then
                    func()
                end
            end
        )
    else
        self:runCsbAction(
            "hide2",
            false,
            function()
                if func then
                    func()
                end
            end
        )
    end
end

function FortuneCatsTips:clickFunc(sender)
    local name = sender:getName()
    if name == "Image_1" then
        if  self.m_Machine then
            self.m_Machine:tipClickFunc()
        end
    end
end

function FortuneCatsTips:onExit()
end

return FortuneCatsTips
