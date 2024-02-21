--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-17 12:10:23
--
local MultipleConfig = class("MultipleConfig")


MultipleConfig.p_value = nil  --增倍器的倍数
MultipleConfig.p_exp = nil  --当前经验
MultipleConfig.p_maxExp = nil  --经验上限
MultipleConfig.p_addExp = nil  --增加经验


function MultipleConfig:parseData( data )
      self.p_value = data.value    
      self.p_exp = tonumber(data.exp)
      self.p_maxExp = tonumber(data.maxExp)
      self.p_addExp = tonumber(data.addExp)
end
--[[
    @desc: 获得当前增倍器的经验进度
    time:2019-04-20 11:46:39
    @return:
]]
function MultipleConfig:getMultiplePrenct( )
      return self.p_exp / self.p_maxExp
end

return  MultipleConfig