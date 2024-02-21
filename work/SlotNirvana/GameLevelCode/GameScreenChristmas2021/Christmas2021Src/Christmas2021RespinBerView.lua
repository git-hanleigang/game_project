---
--island
--2018年6月5日
--Christmas2021RespinBerView.lua

local Christmas2021RespinBerView = class("Christmas2021RespinBerView", util_require("base.BaseView"))

function Christmas2021RespinBerView:initUI(data)

    local resourceFilename="Christmas2021_freeandrespincishu.csb"
    self:createCsbNode(resourceFilename)

    self:findChild("Node_free"):setVisible(false)
    self:findChild("Node_respin"):setVisible(true)
end

-- 更新respin次数
function Christmas2021RespinBerView:updateLeftCount(num)
    if num <= 1 then
        self:findChild("Christmas2021_zi1_2"):setVisible(false)
        self:findChild("Christmas2021_zi2_3"):setVisible(true)
    else
        self:findChild("Christmas2021_zi1_2"):setVisible(true)
        self:findChild("Christmas2021_zi2_3"):setVisible(false)
    end
    self:findChild("m_lb_num_1_0"):setString(num)
end

function Christmas2021RespinBerView:onEnter()

end

function Christmas2021RespinBerView:onExit()

end


return Christmas2021RespinBerView