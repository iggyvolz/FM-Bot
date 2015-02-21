local function explode(div,str) -- credit: http://richard.warburton.it
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
local function shell(script)
  return io.popen(script):read("*a"):sub(1,-2)
end

local io,lfs,i,votecount,voters,players=require "io",require "lfs",1,{},{},{"TurdPile"}
while lfs.attributes("./cache/msgs/"..i) do
  local f=assert(io.open("./cache/msgs/"..i.."/author"))
  local author=f:read("*a")
  f:close()
  f=assert(io.open("./cache/msgs/"..i.."/conts"))
  local conts=f:read("*a")
  f:close()
  if #explode("/unvote",conts:lower())>1 and voters[author] then
    voters[author]=nil
  end
  for i=1,#players do
    if #explode("/vote "..players[i]:lower(),conts:lower())>1 and not voters[author] then
      if not votecount[players[i]] then
        votecount[players[i]]={}
      end
      voters[author]=players[i]
      table.insert(votecount[players[i]],author)
    end
  end
  if #explode("/nolynch",conts:lower())>1 and not voters[author] then
    if not votecount.nolynch then
      votecount.nolynch={}
    end
    voters[author]="nolynch"
    table.insert(votecount.nolynch,author)
  end
  i=i+1
end
