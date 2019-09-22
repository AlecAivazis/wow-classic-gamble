GambleUtils = {} 

-- return true if there is a key in the table
function GambleUtils:TableHasKeys(t)
    -- make pairs do the dirty work
    for _, __ in pairs(t) do
        return true
    end

    return false
end

-- split the provided string using the given pattern
function GambleUtils:SplitString(str, pattern)
    -- Eliminate bad cases...
    if string.find(str, pattern) == nil then
       return { str }
    end
    if maxNb == nil or maxNb < 1 then
       maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. pattern .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
       nb = nb + 1
       result[nb] = part
       lastPos = pos
       if nb == maxNb then
          break
       end
    end
    -- Handle the last field
    if nb ~= maxNb then
       result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end


local waitTable = {}
local waitFrame = nil

-- delays the execution of the provided function with the given args
function GambleUtils:Delay(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent)
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable
      local i = 1
      while(i<=count) do
        local waitRecord = tremove(waitTable,i)
        local d = tremove(waitRecord,1)
        local f = tremove(waitRecord,1)
        local p = tremove(waitRecord,1)
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p})
          i = i + 1
        else
          count = count - 1
          f(unpack(p))
        end
      end
    end)
  end
  tinsert(waitTable,{delay,func,{...}})
  return true
end