---
--xcyy
--2018年5月23日
--SpinResultData_PandaDeluxe.lua

local SpinResultData_PandaDeluxe = class("SpinResultData_PandaDeluxe",util_require("data.slotsdata.SpinResultData"))


function SpinResultData_PandaDeluxe:parseWinLines( data , lineDataPool)
    if data.lines ~= nil then
        for i = 1, #data.lines do
            local lineData = data.lines[i]

            if self.p_isAllLine == true and lineData.nums ~= nil and  #lineData.nums ~= 0 then
                self:parseAllLines(lineData , lineDataPool)
            else
                local winLineData = self:getWinLineDataWithPool(lineDataPool)
                winLineData.p_id = lineData.id
                winLineData.p_amount = lineData.amount
                winLineData.p_iconPos = lineData.icons
                winLineData.p_type = lineData.type
                winLineData.p_multiple = lineData.multiple
                self.p_winLines[#self.p_winLines + 1] = winLineData
            end

        end
    end
end

return SpinResultData_PandaDeluxe