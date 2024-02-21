--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local FindItemInfo = class("FindItemInfo")
FindItemInfo.p_itemId = nil
FindItemInfo.p_icon = nil
FindItemInfo.p_name = nil
FindItemInfo.p_newItem = nil
FindItemInfo.p_posList = nil

function FindItemInfo:ctor()
    
end

function FindItemInfo:parseData(data)
      self.p_itemId = tonumber(data.itemId)
      self.p_icon = data.icon
      self.p_name = data.name
      self.p_newItem = data.newItem
      self.p_posList = {}
      if data.pos then
            local list = util_split(data.pos,";")
            if list then
                  for i=1,#list do
                        if list[i]~="" then
                              self.p_posList[#self.p_posList+1] = list[i]
                        end
                  end
            end
      end
      
end

return  FindItemInfo