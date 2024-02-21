local CaseVersionConfig = class("CaseVersionConfig")
--活动促销版本兼容控制
CaseVersionConfig.p_caseId = nil  --控制id 可以是活动id 商店id 等唯一值
CaseVersionConfig.p_version = nil  --最低app版本
CaseVersionConfig.p_code = nil  --最低热更新版本
CaseVersionConfig.p_description = nil --描述或类型 目前无作用字段
function CaseVersionConfig:ctor()
    
end
function CaseVersionConfig:parseData( data )
    self.p_caseId = data.caseId --控制id 可以是活动id 商店id 等唯一值
    self.p_version = data.version  --最低app版本
    self.p_code = tonumber(data.code) or 0 --最低热更新版本
    self.p_description = data.description --描述或类型 目前无作用字段
end
--是否版本不兼容
function CaseVersionConfig:checkIncompatible( id )
    if not id or id ~= self.p_caseId then
        --转化number 在判断一遍
        id = tonumber(id)
        local caseId = tonumber(self.p_caseId)
        if not id or not caseId or id ~= caseId then
            return false
        end
    end
    local code = util_getUpdateVersionCode(false)
    code = tonumber(code) or 1
    if not util_isSupportVersion(self.p_version) or code<self.p_code then
        return true
    else
        return false
    end
end
return CaseVersionConfig