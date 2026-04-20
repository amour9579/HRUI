local _, ns = ...

function ns:CreateProfileOptions()
  local AceDBOptions = LibStub("AceDBOptions-3.0")
  local options = AceDBOptions:GetOptionsTable(ns.db)
  options.order = 99
  options.name = "프로필"
  options.type = "group"
  return options
end
