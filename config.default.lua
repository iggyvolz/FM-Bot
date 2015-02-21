local board={
  ["url"]="http://127.0.0.1/phpbb30",
  ["forum"]=2,
  ["topic"]=1,
  ["user"]="iggyvolz",
  ["pass"]="password",
  ["private"]="/viewforum.php?f=24", -- A page that should redirect you to a login page if not logged in, to throw an error
  ["hidewarnings"]=false -- Hides all warnings.  You REALLY shouldn't set this to true unless you know what you're doing.
}
return {["board"]=board}
