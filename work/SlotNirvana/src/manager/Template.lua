--[[
lua的list安全扩展，支持一边迭代一边添加删除
author:JohnnyFred
]]

local Template = class("SafeList")

Template.m_instance = nil

function Template:ctor()
	
end

function Template:getInstance()
	if Template.m_instance == nil then
		Template.m_instance = Template.new()
	end
	return Template.m_instance
  end
  

return Template