--[[
    -- 高倍场合成游戏 model
]]

local BaseNetModel = import(".BaseNetModel")
local DeluxeMergeNetModel = class("DeluxeMergeNetModel", BaseNetModel)

-- 打包body数据
function DeluxeMergeNetModel:packBody(body, tbData)
    tbData = tbData or {}
    if body and type(body) == "table" then
        for key, value in pairs(tbData) do
            if key == "data" then
                -- data字段特殊处理
                body.data.params = json.encode(value.params or {})
            else
                body[key] = value
            end
        end
    end
end

return DeluxeMergeNetModel