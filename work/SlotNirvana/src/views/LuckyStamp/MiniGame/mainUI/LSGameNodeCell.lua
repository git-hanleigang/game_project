--2023
local LSGameNodeCell = class("LSGameNodeCell", BaseView)

function LSGameNodeCell:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_stamp_cell.csb"
end

return LSGameNodeCell
