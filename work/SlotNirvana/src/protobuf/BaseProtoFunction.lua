local BaseProtoInfo = {}

function BaseProtoInfo.setEnumInfo(tb,name,index,number)
	tb.name = name
	tb.index = index
	tb.number = number
end

function BaseProtoInfo.setEnumValues(tb,name,fullName,values)
	tb.name = name
	tb.full_name = fullName
	tb.values = values
end

function BaseProtoInfo.setMessageInfo(tb,name,fullName,nestedTypes,enumTypes,fields,isExtendable,extensions)
	tb.name = name
	tb.full_name = fullName
	tb.nested_types = nestedTypes
	tb.enum_types = enumTypes
	tb.fields = fields
	tb.is_extendable = isExtendable
	tb.extensions = extensions
end

function BaseProtoInfo.setFieldBaseInfo(tb,name,fullName,number,index,label,hasDefaultValue,defaultValue,types,cppType)
	tb.name = name
	tb.full_name = fullName
	tb.number = number
	tb.index = index
	tb.label = label
	tb.has_default_value = hasDefaultValue
	tb.default_value = defaultValue
	tb.type = types
	tb.cpp_type = cppType
end

function BaseProtoInfo.setFieldEnumInfo(tb,name,fullName,number,index,label,hasDefaultValue,defaultValue,enumType,types,cppType)
	BaseProtoInfo.setFieldBaseInfo(tb,name,fullName,number,index,label,hasDefaultValue,defaultValue,types,cppType)
	tb.enum_type = enumType
end

function BaseProtoInfo.setFieldMessageTypeInfo(tb,name,fullName,number,index,label,hasDefaultValue,defaultValue,messageType,types,cppType)
	BaseProtoInfo.setFieldBaseInfo(tb,name,fullName,number,index,label,hasDefaultValue,defaultValue,types,cppType)
	tb.message_type = messageType
end

return BaseProtoInfo