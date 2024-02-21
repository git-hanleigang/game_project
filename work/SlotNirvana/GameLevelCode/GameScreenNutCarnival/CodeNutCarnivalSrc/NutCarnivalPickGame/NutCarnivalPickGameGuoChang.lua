--[[
    花生堆
    处理收集数量和等级
]]
local NutCarnivalPickGameGuoChang = class("NutCarnivalPickGameGuoChang", cc.Node)

function NutCarnivalPickGameGuoChang:initData_(_machine)
    self.m_machine = _machine

    self:initUI()
end
function NutCarnivalPickGameGuoChang:initUI(_machine)

    local nameList = {
        "NutCarnival_pick_shouji_guochang",
        "NutCarnival_pick_shouji_guochang1",
        "NutCarnival_pick_shouji_guochang2",
        "NutCarnival_pick_shouji_guochang3",
    }
    self.m_spineList = {}
    for _index,_spineName in ipairs(nameList) do
        local spine    = util_spineCreate(_spineName, true, true)
        self:addChild(spine, _index)
        self.m_spineList[_index] = spine
    end
end

--[[
    时间线
]]
function NutCarnivalPickGameGuoChang:playGuoChangAnim(_fun1, _fun2)
    self:setVisible(true)
    local animName = "guochang"
    for i,_spine in ipairs(self.m_spineList) do
        util_spinePlay(_spine, animName, false)
    end
    self.m_machine:levelPerformWithDelay(self, 51/30, function()
        _fun1()
        self.m_machine:levelPerformWithDelay(self, 24/30, function()
            self:setVisible(false)
            _fun2()
        end)
    end)
end

return NutCarnivalPickGameGuoChang