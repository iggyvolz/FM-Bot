local board,lfs,found=require "api",require "lfs",false

for x,i in ipairs(board.pmnums) do
  found=false
  for file in lfs.dir("./cache/pms") do
    if tostring(i)==file then
      found=true
    end
  end
  if not found then
    assert(lfs.mkdir("./cache/pms/"..i))
    local a,b,c,r=assert(io.open("./cache/pms/"..i.."/author", "w")),assert(io.open("./cache/pms/"..i.."/conts", "w")),assert(io.open("./cache/pms/"..i.."/unhandled", "w")),board:readpm(i)
    a:write(r.author)
    a:close()
    b:write(r.conts)
    b:close()
    c:write("UNHANDLED")
    c:close()
  end
end
for i=1,board.numposts do
  found=false
  for file in lfs.dir("./cache/msgs") do
    if tostring(i)==file then
      found=true
    end
  end
  if not found then
    assert(lfs.mkdir("./cache/msgs/"..i))
    local a,b,c,r=assert(io.open("./cache/msgs/"..i.."/author", "w")),assert(io.open("./cache/msgs/"..i.."/conts", "w")),assert(io.open("./cache/msgs/"..i.."/unhandled", "w")),board:read(i)
    a:write(r.author)
    a:close()
    b:write(r.conts)
    b:close()
    c:write("UNHANDLED")
    c:close()
  end
end
