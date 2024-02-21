local LevelConfigData = require("data.slotsdata.LevelConfigData")
local MedusaManiaConfig = class("MedusaManiaConfig", LevelConfigData)

function MedusaManiaConfig:ctor()
    LevelConfigData.ctor(self)
    ---
end

---
-- 获取freespin model 对应的reel 列数据
--
function MedusaManiaConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
    local curFreeType = fsModelID
    if not curFreeType or (curFreeType > 3 or curFreeType < 1) then
        curFreeType = 1
    end
	local colKey = string.format("freespinModeId_%d_%d",curFreeType,columnIndex)

	return self[colKey]
end

return MedusaManiaConfig
