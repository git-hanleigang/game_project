--浇花
local CollectLevelData = class("CollectLevelData")

function CollectLevelData:ctor()
    self.m_list = {}
end

function CollectLevelData:parseData(data)
    if not data then
        return
    end
    self.m_list = {}
    if data.collectionLevels and #data.collectionLevels > 0 then
        self.m_list = data.collectionLevels
    end
end

function CollectLevelData:getLevelList()
    return self.m_list or {}
end


return CollectLevelData
