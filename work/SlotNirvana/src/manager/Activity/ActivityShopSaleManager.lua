local ActivityShopSaleManager = class("ActivityShopSaleManager",util_require("baseActivity.BaseActivityManager"))
function ActivityShopSaleManager:ctor()
    
end

function ActivityShopSaleManager:getInstance()
    if self.m_instance == nil then
        self.m_instance = ActivityShopSaleManager.new()
	end
	return self.m_instance
end

function ActivityShopSaleManager:function_name( )
    
end


return ActivityShopSaleManager