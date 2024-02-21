--[[
    
    author: 徐袁
    time: 2021-09-14 11:28:19
]]
local NewPassBuyTicketManager = class("NewPassBuyTicketManager", BaseActivityControl)

function NewPassBuyTicketManager:ctor()
    NewPassBuyTicketManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewPassBuy)
    self:addPreRef(ACTIVITY_REF.NewPass)
end

function NewPassBuyTicketManager:getPayPassTicketInfo()
    if not self:checkPreRefName() then
        return nil
    end

    local newPassData = self:getMgr(ACTIVITY_REF.NewPass):getRunningData()
    local passTicketData = newPassData:getPayPassTicketInfo()
    if passTicketData and tolua.type(passTicketData) == "table" and #passTicketData > 0 then
        return passTicketData
    else
        return nil
    end
end

function NewPassBuyTicketManager:getCurrThemeName()
    local themeName = self:getMgr(ACTIVITY_REF.NewPass):getThemeName()
    if themeName == "Activity_NewPass_New" then
        return "NewPassVegasNew"
    else
        return string.split(themename, "Activity_")[2]
    end
end

function NewPassBuyTicketManager:randomShowHall(data)
    local result_data = data
    if not self:checkPreRefName() then
        return result_data
    end
    if self:getMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
        --result_data.p_slideImage =  "Icons/" .. self:getCurrThemeName() .. "Sale_Slide_2.csb"
        --result_data.p_hallImages = {"Icons/" .. self:getCurrThemeName() .. "Sale_Hall_2.csb"} 
        result_data.p_slideImage =  "Icons/" .. self:getCurrThemeName() .. "Sale_Slide.csb"
        result_data.p_hallImages = {"Icons/" .. self:getCurrThemeName() .. "Sale_Hall.csb"} 
    end
    return result_data
end

return NewPassBuyTicketManager
