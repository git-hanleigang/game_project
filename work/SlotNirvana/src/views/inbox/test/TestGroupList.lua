--[[
]]
local UIMenuList = util_require("base.UIMenuList")
local TestGroupList = class("TestGroupList", UIMenuList)

function TestGroupList:ctor( size, groupData )
    TestGroupList.super.ctor( self, size, groupData )      
end

return TestGroupList