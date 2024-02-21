--
-- Author:zhangkankan
-- Date: 2021-07-26 15:43:54
--
local MergeMaterial = class("MergeMaterial")

MergeMaterial.p_type = nil         --材料类型
MergeMaterial.p_maxLevel = nil     --材料等级
MergeMaterial.p_num = nil          --拥有的数量
MergeMaterial.p_need = nil         --完成章节需要的数量
MergeMaterial.p_level = nil        --材料等级


function MergeMaterial:ctor()
end
function MergeMaterial:parseData(data)
    self.p_type = data.type
    self.p_maxLevel = data.maxLevel
    self.p_level = data.level
    self.p_num = data.num
    self.p_need = data.need
end

function MergeMaterial:getType()
    return self.p_type
end
function MergeMaterial:getMaxLevel()
    return self.p_maxLevel 
end
function MergeMaterial:getLevel()
    return self.p_level
end
function MergeMaterial:getNum()
    return self.p_num or 0
end
function MergeMaterial:getNeed()
    return self.p_need
end
return  MergeMaterial
