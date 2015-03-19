clearscreen.
Set startTime to Time.
print "Started at: "+Time:Clock.
set slat to ship:latitude.	//start lat.
set slng to mod(ship:longitude+360,360).	//start lng.

set flat to -90.	//finish lat.
set flng to mod(0+360,360).		//finish lng.

if body = kerbin or body = eve or body = laythe {
 set water to 1.
}
else {
 set water to 0.
}.

Set dx to 1.
set dy to 1.
set samplerate to 100.
set slopefactor to 800.
set traversefactor to 1. //not yet used

//=====Vertex info list=======
// 0 - geolocation.
// 1 - checked connections.
// 2 - grid pos x
// 3 - grid pos y
// 4 - vertex cost.
// 5 - x of previous vertex in shortest path.
// 6 - y of previous vertex in shortest path.


//====Set up grid sphere=======      This will be replaced with a cube projection when i get round to it.
set grid to list().		//x coordinate on grid
set x to 0.
set y to -90.
until x = 360 {
 grid:add(list()).		//y coordiante on grid
 until y >= 90-dy {
  set y to round(y+dy,1). //rounding to remove floating point error that creeps in (dont know how it gets there)
  grid[grid:length-1]:add(list()). //vertex info
  grid[grid:length-1][grid[grid:length-1]:length-1]:add(latlng(y,x)).
  grid[grid:length-1][grid[grid:length-1]:length-1]:add(0).
  grid[grid:length-1][grid[grid:length-1]:length-1]:add((grid:length-1)).
  grid[grid:length-1][grid[grid:length-1]:length-1]:add((grid[grid:length-1]:length-1)).
 }.
 set y to -90.
 set x to x + dx.
}.
set vertextotal to grid:length*grid[0]:length.
Print "Grid setup complete.".
run gs_distance(grid[0][round(grid[0]:length/2)][0],grid[1][round(grid[1]:length/2)][0],body:radius).
set startlimit to 1.5*result.
//==============================

//=====Set up start/finish======
set start to list().
start:add(latlng(slat,slng)).
start:add(0).
start:add(-1).
start:add(-1).

set finish to list().
finish:add(latlng(flat,flng)).
finish:add(0).
finish:add(-2).
finish:add(-2).
finish:add(0).
//==============================

//==Set up neighbors / visited==
set neighbors to list().
set visited to list().
visited:add(finish).
if finish[0]:lat < (dy - 90) {
 set pos to 0.
 until pos >= grid:length-1 {
  neighbors:add(grid[pos][0]).
  set pos to pos +1.
 }.
} 
else if finish[0]:lat > (90 - dy) {
 set pos to 0.
 until pos >= grid:length -1 {
  neighbors:add(grid[pos:index][grid[pos]:length - 1]).
  set pos to pos +1.
 }.
}
else {
 set x to floor(finish[0]:lng)/dx.
 set y to (floor(finish[0]:lat)+90) / dy.
 neighbors:add(grid[x][y]).
 neighbors:add(grid[x+1][y]).
 neighbors:add(grid[x+1][y+1]).
 neighbors:add(grid[x][y+1]).
}.
neighbors:add(start).
//==============================

//======Pathfinding=============
set activeVertex to finish.
set vertexcount to 0.
until activeVertex = start {
Print "Checking vertex at" +activeVertex[0].
 
//calculate weighting.
 for vertex in neighbors {
  if vertex[0]:terrainheight < 0 and water = 1 {
   set vertex[1] to 8.
  }
  else {
   set cost to 0.
   set swimming to false.
   run gs_distance(activevertex[0],vertex[0],body:radius).
   set gsdist to result.
   print "Distance to "+vertex[0]+" is "+gsdist.
   log "Distance to "+vertex[0]+" is "+gsdist to debug.
   set floorgsdist to floor(gsdist/samplerate).
   set count to 0.
   set p1 to activevertex[0].
   until count >= floorgsdist or swimming = true {
    run gs_bearing(p1,vertex[0]).
    set gsbear to result.
    run gs_destination(p1,gsbear,samplerate,body:radius).
    set p2 to latlng(round(result:lat,5),round(result:lng,5)).
    if p2:terrainheight < 0 {
     set swimming to true.
     print "Can't cross water at "+p2.
    }
    else {
     set cost to cost + samplerate + (slopefactor*abs(p1:terrainheight-p2:terrainheight)/samplerate).
    }.
    set p1 to p2.
    set count to count + 1.
   }.
   if swimming = false {
    run gs_distance(p1,vertex[0],body:radius).
    set gsdist to result.
    set cost to cost + gsdist + (slopefactor*abs(p1:terrainheight-vertex[0]:terrainheight)/gsdist).
    if vertex:length < 5 {
     set vertex[1] to vertex[1]+1.
     vertex:add(round(activevertex[4]+cost,5)).
     vertex:add(activevertex[2]).
     vertex:add(activevertex[3]).
     Set listmax to visited:length-1.
     set listmin to 0.
     until listmin > listmax {
      set listmid to floor((listmax+listmin)/2).
      if vertex[4] > visited[listmid][4] {
       set listmin to listmid+1.
      }
      else if vertex[4] < visited[listmid][4] {
       set listmax to listmid-1.
      }
      else {
       set listmin to listmid.
       set listmax to listmid-1.
      }.
     }.
     if listmin = visited:length {
      visited:add(vertex).
     }
     else {
      visited:insert(listmin,vertex).
     }.
    }
    else if activevertex[4]+cost < vertex[4] {
     set listmax to visited:length-1.
     set listmin to 0.
     until listmin > listmax {
      set listmid to floor((listmax+listmin)/2).
      if vertex[4] > visited[listmid][4] {
       set listmin to listmid+1.
      }
      else if vertex[4] < visited[listmid][4] {
       set listmax to listmid-1.
      }
      else {
       set listmin to listmid.
       set listmax to listmid-1.
      }.
     }.
     if vertex[0] = visited[listmin][0]{
      visited:remove(listmin).
     }.
     set vertex[1] to vertex[1]+1.
     set vertex[4] to round(activevertex[4]+cost,5).
     set vertex[5] to activevertex[2].
     set vertex[6] to activevertex[3].
     Set listdmax to visited:length-1.
     set listmin to 0.
     until listmin > listmax {
      set listmid to floor((listmax+listmin)/2).
      if vertex[4] > visited[listmid][4] {
       set listmin to listmid+1.
      }
      else if vertex[4] < visited[listmid][4] {
       set listmax to listmid-1.
      }
      else {
       set listmin to listmid.
       set listmax to listmid-1.
      }.
     }.
     if listmin = visited:length {
      visited:add(vertex).
     }
     else {
      visited:insert(listmin,vertex).
     }.
    }
    else {
     set vertex[1] to vertex[1]+1.
    }.
   }
   else {
    set vertex[1] to vertex[1]+1.
   }.
   if vertex[2] = -1 {
    set start to vertex.
   }
   else {
    set x to vertex[2].
    set y to vertex[3].
    set grid[x][y] to vertex.
   }.
  }.
 }.
 print "remove active vertex from visited list".
 visited:remove(0).
 print "select new active vertex".
 set activevertex to visited[0].
 if activevertex = start {}
 else {
  print "create new neighbors list".
  set neighbors to list().
  run gs_distance(start[0],activevertex[0],body:radius).
  if result < startlimit {
   neighbors:add(start).
  }.
  set nx to -1.
  until nx > 1 {
   if nx = 0 {
    set z to 2.
   }
   else {
    set z to 1.
   }.
   set ny to -1.
   until ny > 1 {
    set vx to activevertex[2]+nx.
    if vx < 0 {
     set vx to grid:length-1.
    }
    else if vx > grid:length-1 {
     set vx to 0.
    }.
    set vy to activevertex[3]+ny.
    if vy < 0 or vy > grid[activevertex[2]]:length-1 {
     set vy to activevertex[3].
     if vx < grid:length / 2 {
      set vx to vx + (grid:length / 2).
     }
     else {
      set vx to vx - (grid:length / 2).
     }.
    }.
    if grid[vx][vy][1] < 8 {
     neighbors:add(grid[vx][vy]).
    }.
    set ny to ny + z.
   }.
   set nx to nx + 1.
  }.
 }.
}.
print "rout calculated".
//==============================

//=====Save waypoint list=======
set rout to list().
set activevertex to start.
Until activevertex = finish {
 if activevertex[5] = -2 {
  set activevertex to finish.
 }
 else {
  set activevertex to grid[activevertex[5]][activevertex[6]].
 }.
 rout:add(activevertex[0]).
}.
Log "Set rout to list()." to waypoints.
For Waypoint in rout {
Log "rout:add("+waypoint+")." to waypoints.
}.
//==============================


//====Driving===================
